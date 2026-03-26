import 'package:flutter/material.dart';
import '../widgets/map_painter.dart';
import 'package:provider/provider.dart';
import '../../services/game_data_service.dart';

class MapPage extends StatelessWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tactical Map')),
      body: Consumer<GameDataService>(
        builder: (context, gameData, _) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Stack(
              children: [
                // Map image as background
                if (gameData.mapImage != null)
                  Positioned.fill(
                    child: Image.memory(
                      gameData.mapImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
                // Map painter overlay
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: MapPainter(
                        mapObjects: gameData.mapObjects,
                        mapInfo: gameData.mapInfo,
                        previousPositions: gameData.previousPositions,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
