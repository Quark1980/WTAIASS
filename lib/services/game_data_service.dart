import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';




/// Service voor ophalen en cachen van War Thunder map- en unitdata via de localhost API.
class GameDataService extends ChangeNotifier {
  String _ip = '192.168.0.61'; // Default IP voor testen
  List<dynamic> _mapObjects = [];
  Map<String, dynamic>? _mapInfo;
  Timer? _timer;

  /// Publieke lijst van mapobjecten (zoals ontvangen van /map_obj.json)
  List<dynamic> get mapObjects => _mapObjects;

  /// Publieke mapinfo (zoals ontvangen van /map_info.json)
  Map<String, dynamic>? get mapInfo => _mapInfo;

  /// Publieke getter voor de mapafbeelding-URL (zoals gebruikt door MapPage)
  String get mapImageUrl => 'http://$_ip:8111/map.img?gen=1';

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
    ]);
    notifyListeners();
  }

  Future<void> _fetchMapObjects() async {
    try {
      final response = await http.get(Uri.parse('http://$_ip:8111/map_obj.json'));
      if (response.statusCode == 200) {
        _mapObjects = json.decode(response.body) as List<dynamic>;
      } else {
        _mapObjects = [];
      }
    } catch (_) {
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
