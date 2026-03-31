import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class JsonHistoryLogger {
  static JsonHistoryLogger? _instance;
  late final File _logFile;

  JsonHistoryLogger._internal();

  static Future<JsonHistoryLogger> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = JsonHistoryLogger._internal();
    final dir = await getApplicationDocumentsDirectory();
    _instance!._logFile = File('${dir.path}/meshcore_history.jsonl');
    if (!await _instance!._logFile.exists()) {
      await _instance!._logFile.create(recursive: true);
    }
    return _instance!;
  }

  Future<void> appendJson(Map<String, dynamic> json) async {
    final line = jsonEncode(json);
    await _logFile.writeAsString('$line\n', mode: FileMode.append);
  }

  Future<List<Map<String, dynamic>>> readAll() async {
    if (!await _logFile.exists()) return [];
    final lines = await _logFile.readAsLines();
    return lines.map((l) => jsonDecode(l) as Map<String, dynamic>).toList();
  }
}
