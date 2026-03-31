// Stub for non-mobile platforms
class JsonHistoryLogger {
  static Future<JsonHistoryLogger> getInstance() async => JsonHistoryLogger();
  Future<void> appendJson(Map<String, dynamic> json) async {}
  Future<List<Map<String, dynamic>>> readAll() async => [];
}
