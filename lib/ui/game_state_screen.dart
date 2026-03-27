import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/wt_api_service.dart';
import '../services/database_helper.dart';
import 'widgets/overlay_menu.dart';
import '../services/game_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameStateScreen extends StatelessWidget {
  const GameStateScreen({Key? key}) : super(key: key);


  String prettyJson(Object? data) {
    try {
      return JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game State'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) async {
              switch (value) {
                case 'settings':
                  final prefs = await SharedPreferences.getInstance();
                  final currentIp = prefs.getString('pc_ip') ?? '';
                  await showSettingsDialog(context, currentIp, (ip) {});
                  break;
                case 'live_map':
                  Navigator.of(context).pushNamed('/map');
                  break;
                case 'about':
                  showAboutDialog(
                    context: context,
                    applicationName: 'MeshcoreGRID',
                    applicationVersion: '1.0.0',
                    children: [
                      const Text('War Thunder Tactical Assistant'),
                    ],
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Text('Settings'),
                ),
                const PopupMenuItem<String>(
                  value: 'live_map',
                  child: Text('Live Map'),
                ),
                const PopupMenuItem<String>(
                  value: 'about',
                  child: Text('About'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Consumer<GameDataService>(
        builder: (context, GameDataService gameData, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Dashboard',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Live /state:'),
                      SelectableText(prettyJson(gameData.stateJson)),
                      const SizedBox(height: 12),
                      Text('Live /map_info.json:'),
                      SelectableText(prettyJson(gameData.mapInfo)),
                      const SizedBox(height: 12),
                      Text('Live /map_obj.json:'),
                      SelectableText(prettyJson(gameData.mapObjects)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
