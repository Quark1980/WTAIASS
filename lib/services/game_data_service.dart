import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/map_object.dart';

class GameDataService extends ChangeNotifier {
  String _ip = '192.168.0.61'; // Default IP for testing
  dynamic mapObjJson;
  dynamic stateJson;
  dynamic mapInfoJson;
  Timer? _timer;

  // --- Live Map API ---
  // TODO: Implementeer deze correct met echte data/mapping
  Uint8List? get mapImage => null; // Voeg hier de echte image bytes toe

  List<MapObject> get mapObjects {
    if (mapObjJson is List) {
      return (mapObjJson as List)
          .whereType<Map<String, dynamic>>()
          .map((obj) => MapObject(
                id: obj['id']?.toString() ?? '',
                x: (obj['x'] as num?)?.toDouble() ?? 0.0,
                y: (obj['y'] as num?)?.toDouble() ?? 0.0,
                icon: obj['icon']?.toString() ?? '',
                type: obj['type']?.toString() ?? '',
                color: _parseColor(obj['color']),
                heading: (obj['heading'] as num?)?.toDouble(),
                isPlayer: obj['isPlayer'] == true,
              ))
          .toList();
    }
    return [];
  }

  Color? _parseColor(dynamic color) {
    if (color is int) {
      return Color(color);
    } else if (color is String) {
      // Verwacht hex string als '#RRGGBB' of 'RRGGBB'
      String hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    return null;
  }
  Map<String, dynamic>? get mapInfo => mapInfoJson is Map<String, dynamic> ? mapInfoJson as Map<String, dynamic> : null;
  Map<String, Offset>? get previousPositions => null;

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
      _fetchJson('/map_obj.json').then((v) => mapObjJson = v),
      _fetchJson('/state').then((v) => stateJson = v),
      _fetchJson('/map_info.json').then((v) => mapInfoJson = v),
    ]);
    notifyListeners();
  }

  Future<dynamic> _fetchJson(String endpoint) async {
    try {
      final url = Uri.parse('http://$_ip:8111$endpoint');
      final response = await http.get(url).timeout(const Duration(milliseconds: 800));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
