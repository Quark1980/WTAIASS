import 'package:flutter/material.dart';
import '../../services/proximity_alert_service.dart';

class SettingsProximityAlertDialog extends StatefulWidget {
  final ProximityAlertService service;
  final VoidCallback onSave;

  const SettingsProximityAlertDialog({
    super.key,
    required this.service,
    required this.onSave,
  });

  @override
  State<SettingsProximityAlertDialog> createState() =>
      _SettingsProximityAlertDialogState();
}

class _SettingsProximityAlertDialogState
    extends State<SettingsProximityAlertDialog> {
  late double _radius;
  late double _dingVolume;
  late double _ttsVolume;
  late double _circleOpacity;
  late String _ttsLanguage;
  String? _ttsVoiceName;

  List<String> _availableLanguages = [];
  List<Map<String, String>> _availableVoices = [];
  List<Map<String, String>> _filteredVoices = [];

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _radius = s.alertRadiusMeters;
    _dingVolume = s.dingVolume;
    _ttsVolume = s.ttsVolume;
    _circleOpacity = s.circleOpacity;
    _ttsLanguage = s.ttsLanguage;
    _ttsVoiceName = s.ttsVoiceName;
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    final langs = await widget.service.getAvailableLanguages();
    final voices = await widget.service.getAvailableVoices();
    if (mounted) {
      setState(() {
        _availableLanguages = langs;
        _availableVoices = voices;
        _filterVoicesForLanguage();
      });
    }
  }

  void _filterVoicesForLanguage() {
    _filteredVoices = _availableVoices
        .where((v) =>
            (v['locale'] ?? '').toLowerCase().startsWith(_ttsLanguage.toLowerCase().split('-').first))
        .toList();
    // Reset voice if not in filtered list
    if (_ttsVoiceName != null &&
        !_filteredVoices.any((v) => v['name'] == _ttsVoiceName)) {
      _ttsVoiceName = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Proximity Alert'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Radius ---
              Text(
                _radius == 0
                    ? 'Alert radius: OFF'
                    : 'Alert radius: ${_radius.round()} m',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                min: 0, max: 500, divisions: 50, value: _radius,
                label: _radius == 0 ? 'OFF' : '${_radius.round()} m',
                onChanged: (v) => setState(() => _radius = v),
              ),

              // --- Circle opacity ---
              const SizedBox(height: 8),
              Text('Circle opacity: ${(_circleOpacity * 100).round()}%'),
              Slider(
                min: 0, max: 1, divisions: 20, value: _circleOpacity,
                label: '${(_circleOpacity * 100).round()}%',
                onChanged: (v) => setState(() => _circleOpacity = v),
              ),

              // --- Ding volume ---
              const SizedBox(height: 8),
              Text('Ding volume: ${(_dingVolume * 100).round()}%'),
              Slider(
                min: 0, max: 1, divisions: 20, value: _dingVolume,
                label: '${(_dingVolume * 100).round()}%',
                onChanged: (v) => setState(() => _dingVolume = v),
              ),

              // --- TTS volume ---
              const SizedBox(height: 8),
              Text('Voice volume: ${(_ttsVolume * 100).round()}%'),
              Slider(
                min: 0, max: 1, divisions: 20, value: _ttsVolume,
                label: '${(_ttsVolume * 100).round()}%',
                onChanged: (v) => setState(() => _ttsVolume = v),
              ),

              // --- TTS Language ---
              const SizedBox(height: 12),
              const Text('Voice language', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: _availableLanguages.contains(_ttsLanguage) ? _ttsLanguage : null,
                hint: Text(_ttsLanguage),
                items: _availableLanguages
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _ttsLanguage = v;
                      _filterVoicesForLanguage();
                    });
                  }
                },
              ),

              // --- TTS Voice ---
              const SizedBox(height: 8),
              const Text('Voice', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: _ttsVoiceName,
                hint: const Text('System default'),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('System default')),
                  ..._filteredVoices.map((v) => DropdownMenuItem(
                        value: v['name'],
                        child: Text(v['name'] ?? '?'),
                      )),
                ],
                onChanged: (v) => setState(() => _ttsVoiceName = v),
              ),

              // --- Preview button ---
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Preview voice'),
                  onPressed: () {
                    final s = widget.service;
                    s.ttsVolume = _ttsVolume;
                    s.ttsLanguage = _ttsLanguage;
                    s.ttsVoiceName = _ttsVoiceName;
                    s.previewTts();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final s = widget.service;
            s.alertRadiusMeters = _radius;
            s.dingVolume = _dingVolume;
            s.ttsVolume = _ttsVolume;
            s.circleOpacity = _circleOpacity;
            s.ttsLanguage = _ttsLanguage;
            s.ttsVoiceName = _ttsVoiceName;
            s.saveSettings();
            widget.onSave();
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
