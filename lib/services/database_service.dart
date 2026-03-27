import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UnitHistoryDatabase {
    /// Get all unit positions for the last [durationMs] milliseconds, grouped by unit_id
    Future<Map<String, List<Map<String, dynamic>>>> getRecentUnitPositions({int durationMs = 300000}) async {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final since = now - durationMs;
      final rows = await db.query(
        'unit_history',
        where: 'timestamp >= ?',
        whereArgs: [since],
        orderBy: 'timestamp ASC',
      );
      final Map<String, List<Map<String, dynamic>>> result = {};
      for (final row in rows) {
        final unitId = row['unit_id']?.toString() ?? '';
        if (unitId.isEmpty) continue;
        result.putIfAbsent(unitId, () => []).add(row);
      }
      return result;
    }
  static final UnitHistoryDatabase _instance = UnitHistoryDatabase._internal();
  factory UnitHistoryDatabase() => _instance;
  UnitHistoryDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'unit_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE unit_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            unit_id TEXT,
            icon TEXT,
            type TEXT,
            x REAL,
            y REAL,
            dx REAL,
            dy REAL,
            color TEXT,
            timestamp INTEGER
          )
        ''');
      },
    );
  }

  Future<void> insertUnitHistory(Map<String, dynamic> unit) async {
    final db = await database;
    await db.insert('unit_history', unit);
  }

  Future<List<Map<String, dynamic>>> getUnitHistory(String unitId) async {
    final db = await database;
    return await db.query('unit_history', where: 'unit_id = ?', whereArgs: [unitId], orderBy: 'timestamp DESC');
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('unit_history');
  }
}
