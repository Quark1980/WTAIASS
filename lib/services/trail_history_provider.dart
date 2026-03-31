import 'dart:async';
import 'package:flutter/material.dart';
import 'json_history_logger.dart';

class TrailHistoryProvider extends ChangeNotifier {
  Map<String, List<_TrailDot>> _trails = {};
  bool _loaded = false;

  Map<String, List<_TrailDot>> get trails => _trails;
  bool get loaded => _loaded;

  Future<void> loadFromHistory({int? timeoutSec}) async {
    final logger = await JsonHistoryLogger.getInstance();
    final entries = await logger.readAll();
    final now = DateTime.now();
    final Map<String, List<_TrailDot>> newTrails = {};
    for (final entry in entries) {
      if (entry['type'] != 'map_obj') continue;
      final timestamp = DateTime.tryParse(entry['timestamp'] ?? '') ?? now;
      final List<dynamic> units = entry['data'] ?? [];
      for (final unit in units) {
        final id = unit['id']?.toString() ?? '';
        final x = (unit['x'] ?? 0).toDouble();
        final y = (unit['y'] ?? 0).toDouble();
        final team = unit['team']?.toString() ?? 'unknown';
        final colorStr = unit['color']?.toString() ?? '#cccccc';
        final color = _parseHexColor(colorStr);
        if (timeoutSec != null && now.difference(timestamp).inSeconds > timeoutSec) continue;
        newTrails.putIfAbsent(id, () => []).add(_TrailDot(
          id: id,
          x: x,
          y: y,
          team: team,
          timestamp: timestamp,
          color: color,
        ));
      }
    }
    _trails = newTrails;
    _loaded = true;
    notifyListeners();
  }
}

class _TrailDot {
  final String id;
  final double x;
  final double y;
  final String team;
  final DateTime timestamp;
  final Color color;
  _TrailDot({required this.id, required this.x, required this.y, required this.team, required this.timestamp, required this.color});
}

Color _parseHexColor(String hex) {
  String hexColor = hex.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}
