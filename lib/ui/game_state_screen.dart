import 'package:flutter/material.dart';
import '../services/war_thunder_api_service.dart';
import '../models/game_state.dart';

import '../services/war_thunder_api_service.dart';
import '../models/game_state.dart';
import 'package:provider/provider.dart';
import '../services/game_data_service.dart';
import 'widgets/overlay_menu.dart';
import 'pages/debug_data_page.dart';
import 'pages/map_page.dart';
class GameStateScreen extends StatefulWidget {
  const GameStateScreen({super.key});

  @override
  State<GameStateScreen> createState() => _GameStateScreenState();
}

class _GameStateScreenState extends State<GameStateScreen> {
  void _showSettings() async {
    final service = Provider.of<GameDataService>(context, listen: false);
    await showSettingsDialog(
      context,
      service.ip,
      (ip) => service.setIp(ip),
    );
    setState(() {});
  }

  void _showDebug() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DebugDataPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('War Thunder Game State')),
          body: Consumer<GameDataService>(
            builder: (context, service, _) {
              // Geen state property meer beschikbaar
              return const Center(child: Text('Geen state data beschikbaar'));
            },
          ),
        ),
        OverlayMenu(
          onShowSettings: _showSettings,
          onShowDebug: _showDebug,
        ),
      ],
    );
  }
}
