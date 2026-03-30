library;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';



import 'package:flutter/material.dart';

class UnitSnapshot {
  final String id;
  final double x;
  final double y;
  final String team;
  final DateTime timestamp;
  final Color color;

  UnitSnapshot({
    required this.id,
    required this.x,
    required this.y,
    required this.team,
    required this.timestamp,
    required this.color,
  });
}

class DeathEvent {
  final String id;
  final double x;
  final double y;
  final String team;
  final DateTime timestamp;
  bool confirmed;

  DeathEvent({
    required this.id,
    required this.x,
    required this.y,
    required this.team,
    required this.timestamp,
    this.confirmed = false,
  });
}

class WTApiService extends ChangeNotifier {
    /// Returns a list of (x, y, team, timestamp) for the given unit id, ordered oldest to newest
    List<UnitSnapshot> getUnitTrail(String unitId) {
      final List<UnitSnapshot> trail = [];
      for (final snapshot in _historicalBuffer) {
        for (final unit in snapshot) {
          if (unit.id == unitId) {
            trail.add(unit);
            break;
          }
        }
      }
      return trail;
    }
  // For chat & HUD polling
  int _lastChatId = -1;
  int _lastHudId = -1;
  int _lastDmgId = -1;
  String? _currentMatchId;
  Timer? _pollTimer;

  String? _savedIp;

  // Historical buffer for unit positions (5 minutes at 500ms = 600 entries)
  final int _bufferMaxLength = 600;
  final List<List<UnitSnapshot>> _historicalBuffer = [];
  List<List<UnitSnapshot>> get historicalBuffer => List.unmodifiable(_historicalBuffer);

  // List of recently detected deaths (for overlay)
  final List<DeathEvent> _recentDeaths = [];
  List<DeathEvent> get recentDeaths => List.unmodifiable(_recentDeaths);


  void setCurrentMatchId(String matchId) {
    _currentMatchId = matchId;
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    _savedIp = prefs.getString('pc_ip') ?? _defaultIp;
  }

  /// Sync de hoogste event/chat/damage id's bij match start zodat je geen oude logs krijgt
  Future<void> syncEventIds() async {
    await _loadSavedIp();
    try {
      // Sync chat
      final chatUrl = Uri.parse('http://${_savedIp ?? _ip}:$_defaultPort/gamechat');
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
      final hudUrl = Uri.parse('http://${_savedIp ?? _ip}:$_defaultPort/hudmsg');
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
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      await fetchChatMessages();
      await fetchHudMessages();
      // _updateHistoricalBuffer() is now called at the end of _fetchAll
    });
  }

  // Call this every polling tick to update the buffer
  void _updateHistoricalBuffer() {
    debugPrint('[Buffer] _updateHistoricalBuffer called');
    if (mapObjects == null) {
      debugPrint('[Buffer] mapObjects is null');
      return;
    }
    debugPrint('[Buffer] mapObjects length: \\${mapObjects!.length}');
    final now = DateTime.now();
    final List<UnitSnapshot> snapshot = [];
    for (final obj in mapObjects!) {
      // Expecting obj to have 'id', 'x', 'y', 'team', 'color' fields
      final id = obj['id']?.toString() ?? '';
      final x = (obj['x'] ?? 0).toDouble();
      final y = (obj['y'] ?? 0).toDouble();
      final team = obj['team']?.toString() ?? 'unknown';
      final colorStr = obj['color']?.toString() ?? '#cccccc';
      final color = _parseHexColor(colorStr);
      snapshot.add(UnitSnapshot(id: id, x: x, y: y, team: team, timestamp: now, color: color));
    }
    debugPrint('[Buffer] Adding snapshot with \\${snapshot.length} units');
    _historicalBuffer.add(snapshot);
    if (_historicalBuffer.length > _bufferMaxLength) {
      _historicalBuffer.removeAt(0);
    }
    debugPrint('[Buffer] Buffer now has \\${_historicalBuffer.length} snapshots');
    _detectDeaths();
  }

  static Color _parseHexColor(String hex) {
    String hexColor = hex.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Detect units that disappeared between the last two snapshots
  void _detectDeaths() {
    if (_historicalBuffer.length < 2) return;
    final now = DateTime.now();
    final prev = _historicalBuffer[_historicalBuffer.length - 2];
    final curr = _historicalBuffer.last;
    final currIds = curr.map((u) => u.id).toSet();
    for (final unit in prev) {
      if (!currIds.contains(unit.id)) {
        // Only add if not already in recent deaths (avoid duplicates)
        final already = _recentDeaths.any((d) => d.id == unit.id && (now.difference(d.timestamp).inSeconds < 300));
        if (!already) {
          _recentDeaths.add(DeathEvent(
            id: unit.id,
            x: unit.x,
            y: unit.y,
            team: unit.team,
            timestamp: unit.timestamp,
          ));
        }
      }
    }
    // Remove deaths older than 5 minutes
    _recentDeaths.removeWhere((d) => now.difference(d.timestamp).inSeconds > 300);
  }

  void stopChatHudPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> fetchChatMessages() async {
    await _loadSavedIp();
    final url = Uri.parse('http://${_savedIp ?? _ip}:$_defaultPort/gamechat?lastId=${_lastChatId < 0 ? 0 : _lastChatId}');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        if (data.isNotEmpty) {
          int maxId = _lastChatId < 0 ? 0 : _lastChatId;
          bool newMsg = false;
          for (final msg in data) {
            final id = msg['id'] ?? 0;
            if (id > maxId) maxId = id;
            if (_lastChatId < 0) continue; // skip on first sync
            final message = msg['msg'] ?? '';
            final sender = msg['sender'] ?? '';
            await DatabaseHelper().insertLog('CHAT', message, matchId: _currentMatchId, sender: sender);
            newMsg = true;
          }
          _lastChatId = maxId;
          if (newMsg) notifyListeners();
        }
      }
    } catch (e) {
      print('Error fetching chat: $e');
    }
  }

  Future<void> fetchHudMessages() async {
    await _loadSavedIp();
    final url = Uri.parse('http://${_savedIp ?? _ip}:$_defaultPort/hudmsg?lastEvt=${_lastHudId < 0 ? 0 : _lastHudId}&lastDmg=${_lastDmgId < 0 ? 0 : _lastDmgId}');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final List<dynamic> events = data['events'] ?? [];
        final List<dynamic> damage = data['damage'] ?? [];
        bool newMsg = false;
        int maxEvtId = _lastHudId < 0 ? 0 : _lastHudId;
        int maxDmgId = _lastDmgId < 0 ? 0 : _lastDmgId;
        for (final msg in events) {
          final id = msg['id'] ?? 0;
          if (id > maxEvtId) maxEvtId = id;
          if (_lastHudId < 0) continue; // skip on first sync
          final message = msg['msg'] ?? '';
          await DatabaseHelper().insertLog('HUD', message, matchId: _currentMatchId);
          newMsg = true;
        }
        for (final msg in damage) {
          final id = msg['id'] ?? 0;
          if (id > maxDmgId) maxDmgId = id;
          if (_lastDmgId < 0) continue; // skip on first sync
          final message = msg['msg'] ?? '';
          await DatabaseHelper().insertLog('HUD', message, matchId: _currentMatchId);
          newMsg = true;
        }
        _lastHudId = maxEvtId;
        _lastDmgId = maxDmgId;
        if (newMsg) notifyListeners();
      }
    } catch (e) {
      print('Error fetching hud: $e');
    }
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
    debugPrint('[Buffer] _fetchAll called');
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
    debugPrint('[Buffer] mapObjects set: ${mapObjects != null ? mapObjects!.length : 'null'}');
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
    // Update historical buffer after mapObjects is set
    _updateHistoricalBuffer();
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
