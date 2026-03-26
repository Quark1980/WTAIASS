import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverlayMenu extends StatelessWidget {
  final VoidCallback onShowSettings;
  final VoidCallback onShowDebug;

  const OverlayMenu({
    super.key,
    required this.onShowSettings,
    required this.onShowDebug,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 96, // extra hoog zodat menu niet onder navbar valt
      child: FloatingActionButton(
        child: const Icon(Icons.menu),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Start Live Map'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushNamed('/map');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onShowSettings();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Raw Data View'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onShowDebug();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> showSettingsDialog(BuildContext context, String currentIp, void Function(String) onSave) async {
  final controller = TextEditingController(text: currentIp);
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Configure PC IP'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'PC IP Address'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pc_ip', controller.text);
            onSave(controller.text);
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
