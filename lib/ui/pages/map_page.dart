import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/game_data_service.dart';
import '../widgets/map_painter.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameDataService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tactical Map - WTAIASS'),
        backgroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.3,
          maxScale: 10.0,
          child: Container(
            color: Colors.black,
            child: gameData.mapObjects.isNotEmpty
                ? Stack(
                    children: [
                      if (gameData.mapImageUrl.isNotEmpty)
                        Image.network(
                          gameData.mapImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('Minimap niet geladen', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                      CustomPaint(
                        size: Size.infinite,
                        painter: MapPainter(
                          mapObjects: gameData.mapObjects,
                          mapInfo: gameData.mapInfo,
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blue),
                        SizedBox(height: 20),
                        Text(
                          'Wachten op War Thunder data...\n\n'
                          '• Zorg dat je in een match zit\n'
                          '• Localhost server (poort 8111) staat aan\n'
                          '• Juist IP-adres ingesteld',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
