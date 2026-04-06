import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsGridFlashDurationDialog extends StatefulWidget {
  final int initialDurationMs;
  final void Function(int) onSave;

  const SettingsGridFlashDurationDialog({
    super.key,
    required this.initialDurationMs,
    required this.onSave,
  });

  @override
  State<SettingsGridFlashDurationDialog> createState() => _SettingsGridFlashDurationDialogState();
}

class _SettingsGridFlashDurationDialogState extends State<SettingsGridFlashDurationDialog> {
  late double _sliderValueSeconds;

  @override
  void initState() {
    super.initState();
    _sliderValueSeconds = widget.initialDurationMs / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grid Flash Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Adjust how long chat-triggered grid-square highlights stay visible.'),
          Slider(
            min: 1,
            max: 10,
            divisions: 9,
            value: _sliderValueSeconds,
            label: '${_sliderValueSeconds.round()} seconds',
            onChanged: (value) {
              setState(() {
                _sliderValueSeconds = value;
              });
            },
          ),
          Text('Flash duration: ${_sliderValueSeconds.round()} seconds'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            final durationMs = _sliderValueSeconds.round() * 1000;
            await prefs.setInt('grid_flash_duration_ms', durationMs);
            widget.onSave(durationMs);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}