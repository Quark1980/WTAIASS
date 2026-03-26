import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ui/game_state_screen.dart';
import 'services/game_data_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameDataService(),
      child: const ModularAiWingmanApp(),
    ),
  );
}

class ModularAiWingmanApp extends StatelessWidget {
  const ModularAiWingmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Zet scherm altijd aan zolang app draait
    WakelockPlus.enable();
    return MaterialApp(
      title: 'Modular AI Wingman',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GameStateScreen(),
    );
  }
}
