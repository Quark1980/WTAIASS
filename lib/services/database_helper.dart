import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
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
      version: 2,
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
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE map_history ADD COLUMN heading REAL;');
          await db.execute('ALTER TABLE map_history ADD COLUMN turret_angle REAL;');
        }
      },
    );
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
