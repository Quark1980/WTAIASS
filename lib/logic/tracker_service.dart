import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/tracked_unit.dart';
import 'dart:ui';

class UnitTrackingService extends ChangeNotifier {
  final List<TrackedUnit> _units = [];
  final List<TrackedUnit> _historicalLosses = [];
  final Uuid _uuid = const Uuid();

  List<TrackedUnit> get units => List.unmodifiable(_units);
  List<TrackedUnit> get historicalLosses => List.unmodifiable(_historicalLosses);

  // Call this with the latest map_obj.json data and (optionally) state/indicators
  void updateUnits(List<Map<String, dynamic>> newData, {Map<String, dynamic>? state, Map<String, dynamic>? indicators}) {
    final now = DateTime.now();
    final List<TrackedUnit> updated = [];
    final Set<String> matchedOldIds = {};

    for (final obj in newData) {
      final String iconType = obj['icon']?.toString() ?? obj['type']?.toString() ?? '';
      final String colorStr = obj['color']?.toString() ?? '#ffffff';
      final Color color = _parseHexColor(colorStr);
      final double x = (obj['x'] as num?)?.toDouble() ?? 0.0;
      final double y = (obj['y'] as num?)?.toDouble() ?? 0.0;
      final Offset pos = Offset(x, y);
      final bool isPlayer = iconType.toLowerCase() == 'player';
      // Matching: find previous unit of same iconType/color within radius
      TrackedUnit? match;
      for (final old in _units) {
        if (old.iconType == iconType && old.color == color && (old.position - pos).distance < 0.01) {
          match = old;
          break;
        }
      }
      if (match != null) {
        // Update existing
        match.lastPosition = match.position;
        match.position = pos;
        match.lastSeen = now;
        match.addTrailPoint();
        // Heading
        if (isPlayer && state != null && indicators != null) {
          match.heading = (indicators['heading'] as num?)?.toDouble() ?? 0.0;
          match.turretAngle = (state['cannon_direction_azimuth'] as num?)?.toDouble() ??
                             (state['gunner_view_h'] as num?)?.toDouble() ?? 0.0;
        } else {
          match.updateHeading();
        }
        updated.add(match);
        matchedOldIds.add(match.id);
      } else {
        // New unit
        final unit = TrackedUnit(
          id: _uuid.v4(),
          iconType: iconType,
          color: color,
          position: pos,
          heading: 0.0,
          turretAngle: 0.0,
          lastSeen: now,
          isPlayer: isPlayer,
        );
        unit.addTrailPoint();
        updated.add(unit);
      }
    }
    // Death detection: units not matched are considered lost
    // (optioneel: implementatie afhankelijk van requirements)
    _units
      ..clear()
      ..addAll(updated);
    notifyListeners();
  }

  static Color _parseHexColor(String hex) {
    String hexColor = hex.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  /// Returns a map of unitId -> (unit, trail) for the last [lastSeconds] seconds
  Map<String, ({TrackedUnit unit, List<TrackedUnitTrailPoint> trail})> getTrailsForAllUnits({int lastSeconds = 300}) {
    final now = DateTime.now();
    final Map<String, ({TrackedUnit unit, List<TrackedUnitTrailPoint> trail})> result = {};
    for (final unit in _units) {
      final trail = unit.trail.where((p) => now.difference(p.timestamp).inSeconds <= lastSeconds).toList();
      if (trail.isNotEmpty) {
        result[unit.id] = (unit: unit, trail: trail);
      }
    }
    return result;
  }

  static double _distance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
  }

  static double _calcHeading(double prevX, double prevY, double x, double y) {
    final dx = x - prevX;
    final dy = y - prevY;
    if (dx == 0 && dy == 0) return 0.0;
    return atan2(dy, dx) * 180 / pi;
  }
}
