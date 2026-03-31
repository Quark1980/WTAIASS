import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsTrailBufferDialog extends StatefulWidget {
  final int initialSeconds;
  final void Function(int) onSave;

  const SettingsTrailBufferDialog({
    super.key,
    required this.initialSeconds,
    required this.onSave,
  });

  @override
  State<SettingsTrailBufferDialog> createState() => _SettingsTrailBufferDialogState();
}

class _SettingsTrailBufferDialogState extends State<SettingsTrailBufferDialog> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.initialSeconds.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trail History Buffer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Adjust how much historical data is stored for dotted trails. (Affects performance)'),
          Slider(
            min: 5,
            max: 300,
            divisions: 59,
            value: _sliderValue,
            label: '${_sliderValue.round()} seconds',
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
              });
            },
          ),
          Text('Buffer: ${_sliderValue.round()} seconds'),
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
            await prefs.setInt('trail_buffer_seconds', _sliderValue.round());
            widget.onSave(_sliderValue.round());
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
