import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../logger.dart';

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

class WTApiService extends ChangeNotifier {
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
  Map<String, dynamic>? mapInfo;
  List<dynamic>? mapObjects;
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
      logger.i('[MAP IMAGE] Bytes received: ${response.bodyBytes.length}');
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final bytes = response.bodyBytes;
        if (_lastImageBytes == null || !_listEquals(_lastImageBytes!, bytes)) {
          _lastImageBytes = List<int>.from(bytes);
          ui.decodeImageFromList(bytes, (ui.Image img) {
            mapImage = img;
            logger.i(
              'Kaart succesvol gedecodeerd: \u001b[32m${img.width}x${img.height}\u001b[0m',
            );
            notifyListeners();
            if (onImageLoaded != null) onImageLoaded!();
          });
        }
      } else if (response.bodyBytes.isEmpty) {
        logger.w('[MAP IMAGE] No image data received.');
      }
    } catch (e) {
      logger.e('[MAP IMAGE] Error: $e');
    }
  }

  Future<void> _fetchAll() async {
    bool ok = true;
    String? error;
    state = await _fetchJson(
      'state',
      onError: (e) {
        ok = false;
        error = e.toString();
      },
    );
    mapInfo = await _fetchJson(
      'map_info.json',
      onError: (e) {
        ok = false;
        error = e.toString();
      },
    );
    final obj = await _fetchList(
      'map_obj.json',
      onError: (e) {
        ok = false;
        error = e.toString();
      },
    );
    mapObjects = obj;
    if (mapObjects != null) {
      logger.i(
        'Aantal units gevonden: \u001b[32m${mapObjects!.length}\u001b[0m',
      );
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
      logger.e('API fetch error for $endpoint: $e');
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
      logger.e('API fetch error for $endpoint: $e');
    }
    return null;
  }
}
