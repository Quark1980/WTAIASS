import 'package:flutter/material.dart';


class MapFilterMenu extends StatefulWidget {
  final Set<String> allTypes;
  final Set<String> selectedTypes;

  const MapFilterMenu({
    super.key,
    required this.allTypes,
    required this.selectedTypes,
  });

  @override
  State<MapFilterMenu> createState() => _MapFilterMenuState();
}

class _MapFilterMenuState extends State<MapFilterMenu> {
  late Set<String> _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = Set<String>.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    final types = widget.allTypes.toList()..sort();
    return AlertDialog(
      title: const Text('Filter units op type'),
      content: SizedBox(
        width: 300,
        child: ListView(
          shrinkWrap: true,
          children: types.map((type) {
            return CheckboxListTile(
              value: _currentSelection.contains(type),
              title: Text(type),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _currentSelection.add(type);
                  } else {
                    _currentSelection.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Sluiten'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _currentSelection),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
