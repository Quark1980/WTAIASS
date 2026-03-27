import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ui/game_state_screen.dart';
import 'ui/pages/map_page.dart';
import 'services/game_data_service.dart';
import 'services/wt_api_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameDataService()),
        ChangeNotifierProvider(create: (_) => WTApiService()),
      ],
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
    final borderRadius = BorderRadius.circular(5);
    return MaterialApp(
      title: 'Modular AI Wingman',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: borderRadius),
          enabledBorder: OutlineInputBorder(borderRadius: borderRadius),
          focusedBorder: OutlineInputBorder(borderRadius: borderRadius),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[950],
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(5))),
        ),
      ),
      home: const MapPage(),
      routes: {
        '/map': (context) => const MapPage(),
      },
    );
  }
}
