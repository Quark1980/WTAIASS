import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class UnitHistoryProvider extends ChangeNotifier {
  final UnitHistoryDatabase _db = UnitHistoryDatabase();
  Map<String, List<Map<String, dynamic>>> _recentHistory = {};

  Map<String, List<Map<String, dynamic>>> get recentHistory => _recentHistory;

  Future<void> loadRecentHistory({int durationMs = 300000}) async {
    _recentHistory = await _db.getRecentUnitPositions(durationMs: durationMs);
    notifyListeners();
  }
}
