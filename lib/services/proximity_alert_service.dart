import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Standalone proximity alert module.
/// Compares each poll snapshot against the player position & heading,
/// fires a ding + TTS clock-position callout when a NEW enemy ground
/// unit enters the configured radius.
class ProximityAlertService {
  // --- configurable state ---
  double alertRadiusMeters = 300.0; // 0 = off
  double dingVolume = 0.8; // 0.0–1.0
  double ttsVolume = 0.8; // 0.0–1.0
  double circleOpacity = 0.25; // 0.0–1.0
  String ttsLanguage = 'en-US';
  String? ttsVoiceName; // null = system default

  // --- internals ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  /// Units currently known to be inside the radius (by stable key).
  final Set<String> _insideRadius = {};
  bool _isSpeaking = false;
  final List<String> _ttsQueue = [];

  // Ground unit icon values
  static const Set<String> _groundIcons = {
    'MediumTank',
    'HeavyTank',
    'LightTank',
    'TankDestroyer',
    'SPAA',
  };

  // Ground unit type values
  static const Set<String> _groundTypes = {
    'ground_model',
  };

  /// Returns true if the hex color is "red" (enemy).
  /// Enemy colors from the WT API are #fa3200, #fa0000, etc.
  static bool _isEnemyColor(String hex) {
    if (!hex.startsWith('#') || hex.length != 7) return false;
    final r = int.tryParse(hex.substring(1, 3), radix: 16) ?? 0;
    final g = int.tryParse(hex.substring(3, 5), radix: 16) ?? 0;
    final b = int.tryParse(hex.substring(5, 7), radix: 16) ?? 0;
    // Red-dominant: R > 180 and G < 100 and B < 100
    return r > 180 && g < 100 && b < 100;
  }

  ProximityAlertService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(ttsLanguage);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(0.8); // military radio feel
    await _tts.setVolume(ttsVolume);
    if (ttsVoiceName != null) {
      await _tts.setVoice({'name': ttsVoiceName!, 'locale': ttsLanguage});
    }
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
  }

  /// Load persisted settings.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    alertRadiusMeters = prefs.getDouble('proximity_radius_meters') ?? 300.0;
    dingVolume = prefs.getDouble('proximity_ding_volume') ?? 0.8;
    ttsVolume = prefs.getDouble('proximity_tts_volume') ?? 0.8;
    circleOpacity = prefs.getDouble('proximity_circle_opacity') ?? 0.25;
    ttsLanguage = prefs.getString('proximity_tts_language') ?? 'en-US';
    ttsVoiceName = prefs.getString('proximity_tts_voice');
    await _applyTtsSettings();
  }

  /// Save current settings.
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('proximity_radius_meters', alertRadiusMeters);
    await prefs.setDouble('proximity_ding_volume', dingVolume);
    await prefs.setDouble('proximity_tts_volume', ttsVolume);
    await prefs.setDouble('proximity_circle_opacity', circleOpacity);
    await prefs.setString('proximity_tts_language', ttsLanguage);
    if (ttsVoiceName != null) {
      await prefs.setString('proximity_tts_voice', ttsVoiceName!);
    } else {
      await prefs.remove('proximity_tts_voice');
    }
  }

  /// Apply TTS voice/language settings.
  Future<void> _applyTtsSettings() async {
    await _tts.setLanguage(ttsLanguage);
    await _tts.setVolume(ttsVolume);
    if (ttsVoiceName != null) {
      await _tts.setVoice({'name': ttsVoiceName!, 'locale': ttsLanguage});
    }
  }

  /// Get available languages from the TTS engine.
  Future<List<String>> getAvailableLanguages() async {
    final langs = await _tts.getLanguages;
    if (langs is List) {
      return langs.map((e) => e.toString()).toList()..sort();
    }
    return ['en-US'];
  }

  /// Get available voices from the TTS engine.
  Future<List<Map<String, String>>> getAvailableVoices() async {
    final voices = await _tts.getVoices;
    if (voices is List) {
      return voices
          .map((v) => Map<String, String>.from(v as Map))
          .toList();
    }
    return [];
  }

  /// Preview TTS with current settings.
  Future<void> previewTts() async {
    await _applyTtsSettings();
    await _tts.speak("enemy spotted, 12 o'clock");
  }

  /// Call this every poll cycle with the latest map objects and map info.
  /// [mapObjects] — raw list from the API / GameDataService.
  /// [mapInfo] — map_info with map_min / map_max.
  void evaluate(List<dynamic> mapObjects, Map<String, dynamic>? mapInfo) {
    if (alertRadiusMeters <= 0) return;
    if (mapObjects.isEmpty || mapInfo == null) return;

    // --- resolve coordinate system ---
    double mapWidth = 1.0;
    double mapHeight = 1.0;
    const double metersPerUnit = 200.0 / 225.0;

    final mapMax = mapInfo['map_max'];
    final mapMin = mapInfo['map_min'];
    if (mapMax is List && mapMin is List && mapMax.length == 2 && mapMin.length == 2) {
      mapWidth = ((mapMax[0] as num).toDouble() - (mapMin[0] as num).toDouble());
      mapHeight = ((mapMax[1] as num).toDouble() - (mapMin[1] as num).toDouble());
    }

    // --- find the player ---
    Map<String, dynamic>? player;
    for (final obj in mapObjects) {
      if ((obj['icon'] ?? '') == 'Player') {
        player = obj as Map<String, dynamic>;
        break;
      }
    }
    if (player == null) return;

    final double playerX = (player['x'] as num?)?.toDouble() ?? 0;
    final double playerY = (player['y'] as num?)?.toDouble() ?? 0;
    final double playerDx = (player['dx'] as num?)?.toDouble() ?? 0;
    final double playerDy = (player['dy'] as num?)?.toDouble() ?? 0;
    final String? playerColor = player['color'] as String?;

    // Player heading angle (radians, 0 = right, increases counter-clockwise)
    // dx/dy in the WT coordinate system: dx = east, dy = south on screen
    final double playerHeadingRad = atan2(playerDy, playerDx);

    // Track which units are still in range this tick
    final Set<String> currentInRange = {};

    for (final obj in mapObjects) {
      final String icon = (obj['icon'] ?? '').toString();
      final String type = (obj['type'] ?? '').toString();

      // Only ground units
      if (!_groundIcons.contains(icon) && !_groundTypes.contains(type)) continue;
      // Only enemy units — enemy color is red (#fa3200 / #fa0000 variants)
      final String? objColor = obj['color'] as String?;
      if (objColor == null || !_isEnemyColor(objColor)) continue;

      final double ox = (obj['x'] as num?)?.toDouble() ?? 0;
      final double oy = (obj['y'] as num?)?.toDouble() ?? 0;

      // Distance in normalized coords → map units → meters
      final double dnx = ox - playerX;
      final double dny = oy - playerY;
      final double distUnitsX = dnx * mapWidth;
      final double distUnitsY = dny * mapHeight;
      final double distMeters = sqrt(distUnitsX * distUnitsX + distUnitsY * distUnitsY) * metersPerUnit;

      // Build a stable id for this unit (use unit_id from GameDataService if available)
      final String unitId = (obj['unit_id'] ?? '${icon}_$objColor').toString();

      if (distMeters <= alertRadiusMeters) {
        currentInRange.add(unitId);

        // Only alert on the transition from outside → inside
        if (!_insideRadius.contains(unitId)) {

          // --- Clock position relative to hull heading ---
          // Bearing from player to enemy (screen coords: +x right, +y down)
          final double bearingRad = atan2(dny, dnx);
          // Relative angle (enemy bearing minus player heading)
          double relAngle = bearingRad - playerHeadingRad;
          // Normalize to 0..2π
          while (relAngle < 0) {
            relAngle += 2 * pi;
          }
          while (relAngle >= 2 * pi) {
            relAngle -= 2 * pi;
          }
          final int clockPos = _angleToClock(relAngle);
          final String callout = "enemy spotted, $clockPos o'clock";

          _playDing();
          _speak(callout);
        }
      }
    }

    // Sync: units that left the radius can re-trigger when they return
    _insideRadius.removeWhere((id) => !currentInRange.contains(id));
    _insideRadius.addAll(currentInRange);
  }

  /// Convert a relative angle (0..2π, 0 = forward/12 o'clock direction of hull)
  /// to a clock position 1–12.
  int _angleToClock(double radians) {
    // 0 rad = direction the hull is pointing = 12 o'clock
    // We need to map: 0 → 12, π/6 → 1, π/3 → 2, … 11π/6 → 11
    int clock = ((radians / (2 * pi)) * 12).round();
    if (clock <= 0) clock = 12;
    if (clock > 12) clock = 12;
    return clock;
  }

  Future<void> _playDing() async {
    if (dingVolume <= 0) return;
    await _audioPlayer.setVolume(dingVolume);
    await _audioPlayer.play(AssetSource('sounds/ding.wav'));
  }

  void _speak(String text) {
    _ttsQueue.add(text);
    if (!_isSpeaking) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_ttsQueue.isEmpty) return;
    _isSpeaking = true;
    final text = _ttsQueue.removeAt(0);
    await _tts.setVolume(ttsVolume);
    await _tts.speak(text);
  }

  /// Reset tracked units (e.g. on match change).
  void reset() {
    _insideRadius.clear();
    _ttsQueue.clear();
    _isSpeaking = false;
  }

  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
  }
}
