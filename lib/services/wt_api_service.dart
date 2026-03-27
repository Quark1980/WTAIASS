library wt_api_service;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';


class WTApiService extends ChangeNotifier {
  // For chat & HUD polling
  int _lastChatId = 0;
  int _lastHudId = 0;
  int _lastDmgId = 0;
  String? _currentMatchId;
  Timer? _chatHudTimer;

  void setCurrentMatchId(String matchId) {
    _currentMatchId = matchId;
  }

  /// Sync de hoogste event/chat/damage id's bij match start zodat je geen oude logs krijgt
  Future<void> syncEventIds() async {
    try {
      // Sync chat
      final chatUrl = Uri.parse('http://$_ip:$_defaultPort/gamechat');
      final chatResp = await http.get(chatUrl);
      if (chatResp.statusCode == 200) {
        final List<dynamic> data = json.decode(chatResp.body);
        if (data.isNotEmpty) {
          final maxId = data.map((e) => e['id'] ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
          _lastChatId = maxId;
          print('[SYNC] _lastChatId set to $maxId');
        }
      }
    } catch (e) {
      print('[SYNC] Error syncing chat ids: $e');
    }
    try {
      // Sync HUD
      final hudUrl = Uri.parse('http://$_ip:$_defaultPort/hudmsg');
      final hudResp = await http.get(hudUrl);
      if (hudResp.statusCode == 200) {
        final data = json.decode(hudResp.body);
        final List<dynamic> huds = data['damage'] ?? [];
        if (huds.isNotEmpty) {
          final maxEvt = huds.map((e) => e['id'] ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
          _lastHudId = maxEvt;
          _lastDmgId = maxEvt;
          print('[SYNC] _lastHudId/_lastDmgId set to $maxEvt');
        }
      }
    } catch (e) {
      print('[SYNC] Error syncing hud ids: $e');
    }
  }

  void startChatHudPolling() {
    _chatHudTimer?.cancel();
    _chatHudTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) async {
      await fetchChat();
      await fetchHud();
    });
  }

  void stopChatHudPolling() {
    _chatHudTimer?.cancel();
    _chatHudTimer = null;
  }

  Future<void> fetchChat() async {
    try {
      final url = Uri.parse('http://$_ip:$_defaultPort/gamechat?lastId=$_lastChatId');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        if (data.isNotEmpty) {
          int maxId = _lastChatId;
          for (final msg in data) {
            final id = msg['id'] ?? 0;
            if (id > maxId) maxId = id;
            final message = msg['msg'] ?? '';
            final sender = msg['sender'] ?? '';
            print('CHAT: $message');
            // Asynchroon loggen, blokkeer UI niet
            Future(() => DatabaseHelper().insertLog('CHAT', message, matchId: _currentMatchId, sender: sender));
          }
          _lastChatId = maxId;
        }
      } else if (resp.statusCode == 500) {
        print('Server 500 error on gamechat, skipping this poll.');
      }
    } catch (e) {
      print('Error fetching chat: $e');
    }
  }

  Future<void> fetchHud() async {
    try {
      final url = Uri.parse('http://$_ip:$_defaultPort/hudmsg?lastEvt=$_lastHudId&lastDmg=$_lastDmgId');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final List<dynamic> huds = data['damage'] ?? [];
        if (huds.isNotEmpty) {
          int maxId = _lastHudId;
          int maxDmg = _lastDmgId;
          for (final msg in huds) {
            final id = msg['id'] ?? 0;
            if (id > maxId) maxId = id;
            if (id > maxDmg) maxDmg = id;
            final message = msg['msg'] ?? '';
            print('HUD: $message');
            // Asynchroon loggen, blokkeer UI niet
            Future(() => DatabaseHelper().insertLog('HUD', message, matchId: _currentMatchId));
          }
          _lastHudId = maxId;
          _lastDmgId = maxDmg;
        }
      } else if (resp.statusCode == 500) {
        print('Server 500 error on hudmsg, skipping this poll.');
      }
    } catch (e) {
      print('Error fetching hud: $e');
    }
  }

    /// Publieke helper om alle data opnieuw op te halen (voor debug refresh)
    Future<void> refreshAll() async {
      await _fetchAll();
      await fetchMapImage();
      notifyListeners();
    }
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  static const String _defaultIp =
      '192.168.0.61'; // Default for physical device
  static const int _defaultPort = 8111;
  static const String _prefsKey = 'wt_api_ip';
  String _ip = _defaultIp;
  Timer? _pollingTimer;
  Map<String, dynamic>? state;
  Map<String, dynamic>? indicators;
  Map<String, dynamic>? mapInfo;
  List<dynamic>? mapObjects;
  double? heading; // uit /indicators
  double? turretAngle; // uit /state
  bool lastConnectionOk = false;
  String? lastError;
  ui.Image? mapImage;
  List<int>? _lastImageBytes;
  final int _lastGen = 1;
  VoidCallback? onImageLoaded;

  WTApiService({String? ip}) {
    if (ip != null) {
      _ip = ip;
    } else {
      _loadIp();
    }
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    _ip = prefs.getString(_prefsKey) ?? _defaultIp;
  }

  Future<void> setIp(String ip) async {
    _ip = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, ip);
  }

  String get ip => _ip;

  void startPolling({void Function()? onUpdate}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) async {
      await _fetchAll();
      await fetchMapImage();
      if (onUpdate != null) onUpdate();
    });
  }

  Future<void> fetchMapImage() async {
    try {
      final url = Uri.parse('http://$_ip:$_defaultPort/map.img?gen=$_lastGen');
      final response = await http.get(url);
      print('[MAP IMAGE] Bytes received: ${response.bodyBytes.length}');
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final bytes = response.bodyBytes;
        if (_lastImageBytes == null || !_listEquals(_lastImageBytes!, bytes)) {
          _lastImageBytes = List<int>.from(bytes);
          ui.decodeImageFromList(bytes, (ui.Image img) {
            mapImage = img;
            print('Kaart succesvol gedecodeerd: ${img.width}x${img.height}');
            notifyListeners();
            if (onImageLoaded != null) onImageLoaded!();
          });
        }
      } else if (response.bodyBytes.isEmpty) {
        print('[MAP IMAGE] No image data received.');
      }
    } catch (e) {
      print('[MAP IMAGE] Error: $e');
    }
  }

  Future<void> _fetchAll() async {
    bool ok = true;
    String? error;
    // Haal /state op
    state = await _fetchJson(
      'state',
      onError: (e) {
        ok = false;
        error = e.toString();
      },
    );
    // Haal /indicators op
    indicators = await _fetchJson(
      'indicators',
      onError: (e) {
        ok = false;
        error = e.toString();
      },
    );
    // Haal map_info.json op
    mapInfo = await _fetchJson(
      'map_info.json',
      onError: (e) {
        ok = false;
        error = e.toString();
      },
    );
    // Haal map_obj.json op
    final obj = await _fetchList(
      'map_obj.json',
      onError: (e) {
        ok = false;
        error = e.toString();
      },
    );
    mapObjects = obj;
    // Extract heading (indicators) en turret_angle (state)
    if (indicators != null && indicators!['heading'] != null) {
      heading = (indicators!['heading'] as num).toDouble();
    } else {
      heading = null;
    }
    if (state != null && state!['turret_angle'] != null) {
      turretAngle = (state!['turret_angle'] as num).toDouble();
    } else {
      turretAngle = null;
    }
    if (mapObjects != null) {
      print('Aantal units gevonden: ${mapObjects!.length}');
    }
    lastConnectionOk = ok;
    lastError = ok ? null : error;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<Map<String, dynamic>?> _fetchJson(
    String endpoint, {
    void Function(Object error)? onError,
  }) async {
    try {
      final uri = Uri.parse('http://$_ip:$_defaultPort/$endpoint');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (onError != null) onError(e);
      print('API fetch error for $endpoint: $e');
    }
    return null;
  }

  Future<List<dynamic>?> _fetchList(
    String endpoint, {
    void Function(Object error)? onError,
  }) async {
    try {
      final uri = Uri.parse('http://$_ip:$_defaultPort/$endpoint');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (onError != null) onError(e);
      print('API fetch error for $endpoint: $e');
    }
    return null;
  }
}
