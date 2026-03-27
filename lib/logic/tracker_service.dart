import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/tracked_unit.dart';

class UnitTrackingService extends ChangeNotifier {
  final List<TrackedUnit> _units = [];
  final List<TrackedUnit> _historicalLosses = [];
  final Uuid _uuid = const Uuid();

  List<TrackedUnit> get units => List.unmodifiable(_units);
  List<TrackedUnit> get historicalLosses => List.unmodifiable(_historicalLosses);

  // Call this with the latest map_obj.json data and (optionally) state/indicators
  void updateUnits(List<Map<String, dynamic>> newData, {Map<String, dynamic>? state, Map<String, dynamic>? indicators}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<TrackedUnit> updated = [];
    final Set<String> matchedOldIds = {};

    for (final obj in newData) {
      final String type = obj['type']?.toString() ?? '';
      final String color = obj['color']?.toString() ?? '';
      final double x = (obj['x'] as num?)?.toDouble() ?? 0.0;
      final double y = (obj['y'] as num?)?.toDouble() ?? 0.0;
      // Matching: find previous unit of same type/color within radius
      TrackedUnit? match;
      for (final old in _units) {
        if (old.type == type && old.color == color && _distance(x, y, old.x, old.y) < 0.01) {
          match = old;
          break;
        }
      }
      if (match != null) {
        // Update existing
        match.x = x;
        match.y = y;
        match.lastSeen = now;
        // Add to trail
        match.trail.add(TrackedUnitPosition(x: x, y: y, timestamp: now));
        // Prune trail older than 5 min
        match.trail.removeWhere((p) => now - p.timestamp > 300000);
        // Heading
        if (type == 'Player' && state != null && indicators != null) {
          match.heading = (indicators['heading'] as num?)?.toDouble() ?? 0.0;
          match.turret = (state['cannon_direction_azimuth'] as num?)?.toDouble() ??
                         (state['gunner_view_h'] as num?)?.toDouble() ?? 0.0;
        } else {
          match.heading = _calcHeading(match.prevX, match.prevY, x, y);
        }
        match.prevX = match.x;
        match.prevY = match.y;
        updated.add(match);
        matchedOldIds.add(match.id);
      } else {
        // New unit
        final unit = TrackedUnit(
          id: _uuid.v4(),
          type: type,
          color: color,
          x: x,
          y: y,
          heading: 0.0,
          turret: 0.0,
          lastSeen: now,
          trail: [TrackedUnitPosition(x: x, y: y, timestamp: now)],
        );
        updated.add(unit);
      }
    }
    // Death detection: units not matched are considered lost
    for (final old in _units) {
      if (!matchedOldIds.contains(old.id)) {
        old.lostAt = now;
        _historicalLosses.add(old);
      }
    }
    // Clean up old losses (older than 5 min)
    _historicalLosses.removeWhere((u) => now - (u.lostAt ?? now) > 300000);
    _units
      ..clear()
      ..addAll(updated);
    notifyListeners();
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
