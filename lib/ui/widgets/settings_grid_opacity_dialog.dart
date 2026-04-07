import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsGridOpacityDialog extends StatefulWidget {
  final double initialOpacity;
  final void Function(double) onSave;

  const SettingsGridOpacityDialog({
    super.key,
    required this.initialOpacity,
    required this.onSave,
  });

  @override
  State<SettingsGridOpacityDialog> createState() => _SettingsGridOpacityDialogState();
}

class _SettingsGridOpacityDialogState extends State<SettingsGridOpacityDialog> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.initialOpacity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grid Opacity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Adjust the opacity of the map grid lines.'),
          Slider(
            min: 0.0,
            max: 1.0,
            divisions: 20,
            value: _sliderValue,
            label: '${(_sliderValue * 100).round()}%',
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
              });
            },
          ),
          Text('Opacity: ${(_sliderValue * 100).round()}%'),
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
            await prefs.setDouble('grid_opacity', _sliderValue);
            widget.onSave(_sliderValue);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
