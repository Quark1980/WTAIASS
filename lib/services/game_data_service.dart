import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';




/// Service voor ophalen en cachen van War Thunder map- en unitdata via de localhost API.
class GameDataService extends ChangeNotifier {
    // Icon mapping for unit types
    static const Map<String, String> iconTypeMap = {
      // Tanks
      'tank': 'Medium Tank / MBT',
      'heavy_tank': 'Heavy Tank',
      'light_tank': 'Light Tank / IFV',
      'tank_destroyer': 'TD / SPG',
      'spaa': 'Anti-Aircraft',
      // Aircraft
      'fighter': 'Fighter',
      'attacker': 'Attacker',
      'bomber': 'Bomber',
      'helicopter': 'Helicopter',
    };

    final UnitHistoryDatabase _historyDb = UnitHistoryDatabase();
  String _ip = '192.168.0.61'; // Default IP voor testen
  List<dynamic> _mapObjects = [];
  Map<String, dynamic>? _mapInfo;
  Timer? _timer;
  Map<String, dynamic>? _stateJson;

  /// Publieke lijst van mapobjecten (zoals ontvangen van /map_obj.json)
  List<dynamic> get mapObjects => _mapObjects;

  /// Publieke mapinfo (zoals ontvangen van /map_info.json)
  Map<String, dynamic>? get mapInfo => _mapInfo;

  /// Publieke getter voor de mapafbeelding-URL (zoals gebruikt door MapPage)
  /// Geeft een cache-busting URL met mapGeneration of timestamp
  String get mapImageUrl => getMapImageUrl();

  /// Geeft de huidige map generatie (indien beschikbaar)
  int get mapGeneration {
    if (_mapInfo != null && _mapInfo!.containsKey('map_generation')) {
      final gen = _mapInfo!['map_generation'];
      if (gen is int) return gen;
      if (gen is String) return int.tryParse(gen) ?? 1;
    }
    return 1;
  }

  /// Genereer een cache-busting map image URL
  String getMapImageUrl({bool unique = false}) {
    final base = 'http://$_ip:8111/map.img?gen=$mapGeneration';
    if (unique) {
      // Voeg timestamp toe voor geforceerde refresh
      return '$base&cb=${DateTime.now().millisecondsSinceEpoch}';
    }
    return base;
  }

  /// Publieke getter voor de state data (zoals ontvangen van /state)
  Map<String, dynamic>? get stateJson => _stateJson;

  GameDataService() {
    _loadIp();
    _startPolling();
  }

  String get ip => _ip;

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    _ip = prefs.getString('pc_ip') ?? _ip;
    notifyListeners();
  }

  Future<void> setIp(String ip) async {
    _ip = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pc_ip', ip);
    notifyListeners();
    _fetchAll();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchAll());
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchMapObjects(),
      _fetchMapInfo(),
      _fetchStateJson(),
    ]);
    notifyListeners();
  }

  Future<void> _fetchStateJson() async {
    try {
      final response = await http.get(Uri.parse('http://$_ip:8111/state'));
      if (response.statusCode == 200) {
        _stateJson = json.decode(response.body) as Map<String, dynamic>?;
      } else {
        _stateJson = null;
      }
    } catch (_) {
      _stateJson = null;
    }
  }

  Future<void> _fetchMapObjects() async {
    try {
      final response = await http.get(Uri.parse('http://$_ip:8111/map_obj.json'));
      if (response.statusCode == 200) {
        final List<dynamic> rawList = json.decode(response.body) as List<dynamic>;
        final now = DateTime.now().millisecondsSinceEpoch;
        // Store all fields, categorize by icon, and save to DB
        _mapObjects = rawList.map((obj) {
          final map = Map<String, dynamic>.from(obj as Map);
          // Categorize by icon
          final icon = map['icon']?.toString() ?? '';
          final typeName = iconTypeMap[icon] ?? icon;
          map['unit_type'] = typeName;
          // Fallback for unit_id
          String unitId = map['id']?.toString() ?? '';
          if (unitId.isEmpty) {
            final type = map['type']?.toString() ?? '';
            final name = map['name']?.toString() ?? '';
            final x = map['x']?.toString() ?? '';
            final y = map['y']?.toString() ?? '';
            unitId = '$type|$icon|$name|$x|$y';
          }
          // Save to DB with timestamp
          final dbEntry = {
            'unit_id': unitId,
            'icon': icon,
            'type': typeName,
            'x': map['x'],
            'y': map['y'],
            'dx': map['dx'],
            'dy': map['dy'],
            'color': map['color'],
            'timestamp': now,
          };
          _historyDb.insertUnitHistory(dbEntry);
          return map;
        }).toList();
      } else {
        _mapObjects = [];
      }
    } catch (e) {
      _mapObjects = [];
    }
  }

  Future<void> _fetchMapInfo() async {
    try {
      final response = await http.get(Uri.parse('http://$_ip:8111/map_info.json'));
      if (response.statusCode == 200) {
        _mapInfo = json.decode(response.body) as Map<String, dynamic>?;
      } else {
        _mapInfo = null;
      }
    } catch (_) {
      _mapInfo = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

}
