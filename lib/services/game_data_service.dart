import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GameDataService extends ChangeNotifier {
  String _ip = '192.168.1.100';
  dynamic mapObjJson;
  dynamic stateJson;
  dynamic mapInfoJson;
  Timer? _timer;

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
