import 'package:flutter/material.dart';
import '../../services/database_service.dart';

import 'dart:async';
class UnitHistoryProvider extends ChangeNotifier {
  final UnitHistoryDatabase _db = UnitHistoryDatabase();
  Map<String, List<Map<String, dynamic>>> _recentHistory = {};
  Timer? _timer;

  Map<String, List<Map<String, dynamic>>> get recentHistory => _recentHistory;

  void startAutoRefresh({int durationMs = 300000, int intervalMs = 1000}) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) => loadRecentHistory(durationMs: durationMs));
    loadRecentHistory(durationMs: durationMs);
  }

  Future<void> loadRecentHistory({int durationMs = 300000}) async {
    _recentHistory = await _db.getRecentUnitPositions(durationMs: durationMs);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
