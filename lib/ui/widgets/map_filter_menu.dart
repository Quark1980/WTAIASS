import 'package:flutter/material.dart';

class MapFilterMenu extends StatelessWidget {
  final Set<String> allTypes;
  final Set<String> selectedTypes;
  final void Function(Set<String>) onChanged;

  const MapFilterMenu({
    super.key,
    required this.allTypes,
    required this.selectedTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = allTypes.toList()..sort();
    return AlertDialog(
      title: const Text('Filter units op type'),
      content: SizedBox(
        width: 300,
        child: ListView(
          shrinkWrap: true,
          children: types.map((type) {
            return CheckboxListTile(
              value: selectedTypes.contains(type),
              title: Text(type),
              onChanged: (val) {
                final newSet = Set<String>.from(selectedTypes);
                if (val == true) {
                  newSet.add(type);
                } else {
                  newSet.remove(type);
                }
                onChanged(newSet);
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
      ],
    );
  }
}
