import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {

    Future<void> insertLog(String type, String message, {String? matchId, String? sender}) async {
      final dbClient = await db;
      await dbClient.insert('match_logs', {
        'match_id': matchId,
        'type': type,
        'sender': sender,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'map_history.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE map_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            map_name TEXT,
            unit_type TEXT,
            side TEXT,
            x REAL,
            y REAL,
            heading REAL,
            turret_angle REAL,
            timestamp INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE match_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            match_id TEXT,
            type TEXT,
            sender TEXT,
            message TEXT,
            timestamp INTEGER
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE map_history ADD COLUMN heading REAL;');
          await db.execute('ALTER TABLE map_history ADD COLUMN turret_angle REAL;');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS match_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              match_id TEXT,
              type TEXT,
              sender TEXT,
              message TEXT,
              timestamp INTEGER
            )
          ''');
        }
      },
    );
  }
  Future<void> insertMatchLog({
    required String matchId,
    required String type,
    String? sender,
    required String message,
    required int timestamp,
  }) async {
    final dbClient = await db;
    await dbClient.insert('match_logs', {
      'match_id': matchId,
      'type': type,
      'sender': sender,
      'message': message,
      'timestamp': timestamp,
    });
  }

  Future<List<Map<String, dynamic>>> getLastMatchLogs({int limit = 5, String? matchId}) async {
    final dbClient = await db;
    final where = matchId != null ? 'WHERE match_id = ?' : '';
    final args = matchId != null ? [matchId] : [];
    final result = await dbClient.rawQuery(
      'SELECT * FROM match_logs $where ORDER BY timestamp DESC LIMIT ?',
      [...args, limit],
    );
    return result;
  }

  Future<void> cleanupOldMatches({int keep = 30}) async {
    final dbClient = await db;
    // Vind de laatste N match_id's
    final matches = await dbClient.rawQuery(
      'SELECT DISTINCT match_id FROM match_logs ORDER BY timestamp DESC LIMIT ?',
      [keep],
    );
    final keepIds = matches.map((e) => e['match_id']).toSet();
    // Verwijder alles wat niet in de laatste N zit
    if (keepIds.isNotEmpty) {
      final placeholders = List.filled(keepIds.length, '?').join(',');
      await dbClient.delete(
        'match_logs',
        where: 'match_id NOT IN ($placeholders)',
        whereArgs: keepIds.toList(),
      );
    }
  }

  Future<void> insertHistory({
    required String mapName,
    required String unitType,
    required String side,
    required double x,
    required double y,
    double? heading,
    double? turretAngle,
    required int timestamp,
  }) async {
    final dbClient = await db;
    await dbClient.insert('map_history', {
      'map_name': mapName,
      'unit_type': unitType,
      'side': side,
      'x': x,
      'y': y,
      'heading': heading,
      'turret_angle': turretAngle,
      'timestamp': timestamp,
    });
  }
}
