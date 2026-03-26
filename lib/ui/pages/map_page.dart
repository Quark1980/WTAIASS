import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/game_data_service.dart';
import '../widgets/map_painter.dart';
import '../widgets/map_filter_menu.dart';
import '../widgets/hudmsg_bar.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _MapPageWithFilter();
  }
}

class _MapPageWithFilter extends StatefulWidget {
  @override
  State<_MapPageWithFilter> createState() => _MapPageWithFilterState();
}

class _MapPageWithFilterState extends State<_MapPageWithFilter> {
    bool wasMapObjectsEmpty = true;
  Set<String> selectedTypes = {};
  Set<String> knownTypes = {};
  String? lastMapId;
  String? lastMapImageKey;
    @override
    void initState() {
      super.initState();
      _loadFilterPrefs();
    }

    Future<void> _loadFilterPrefs() async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('selectedTypes');
      if (saved != null && saved.isNotEmpty) {
        setState(() {
          selectedTypes = saved.toSet();
        });
      }
    }

    Future<void> _saveFilterPrefs() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selectedTypes', selectedTypes.toList());
    }
  // Fallback types uit MapObjects.md
  static const Set<String> fallbackTypes = {
    'airfield',
    'aircraft',
    'ground_model',
    'defending_point',
    'bombing_point',
    'respawn_base_fighter',
    'respawn_base_bomber',
  };

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameDataService>();
    final mapInfo = gameData.mapInfo;
    double aspect = 1.0;
    String? mapId;
    if (mapInfo != null) {
      if (mapInfo['width'] != null && mapInfo['height'] != null) {
        final w = (mapInfo['width'] as num).toDouble();
        final h = (mapInfo['height'] as num).toDouble();
        if (w > 0 && h > 0) aspect = w / h;
      }
      // Gebruik mapInfo['id'] of ['name'] als unieke map-id
      mapId = mapInfo['id']?.toString() ?? mapInfo['name']?.toString();
    }

    // Forceer refresh van map image bij nieuwe match (nieuwe mapId)
    if (mapId != null && mapId != lastMapId) {
      lastMapId = mapId;
      // Unieke key voor Image.network zodat deze geforceerd ververst
      lastMapImageKey = DateTime.now().millisecondsSinceEpoch.toString();
    }

    // Verzamel alle types uit de huidige mapObjects
    final allTypes = gameData.mapObjects.map((e) => e['type']?.toString() ?? '').where((t) => t.isNotEmpty).toSet();
    // Onthoud alle bekende types (ook tussen matches)
    if (allTypes.isNotEmpty) {
      knownTypes.addAll(allTypes);
    }
    // Forceer refresh van map image zodra er weer data binnenkomt na een lege periode
    final isNowNotEmpty = gameData.mapObjects.isNotEmpty;
    if (wasMapObjectsEmpty && isNowNotEmpty) {
      lastMapImageKey = DateTime.now().millisecondsSinceEpoch.toString();
    }
    wasMapObjectsEmpty = !isNowNotEmpty ? true : false;
    // Gebruik fallbackTypes als er geen bekende types zijn
    final typesForFilter = knownTypes.isNotEmpty
        ? knownTypes
        : (allTypes.isNotEmpty ? allTypes : fallbackTypes);
    // Init: als nog geen selectie, alles aan
    if (selectedTypes.isEmpty && typesForFilter.isNotEmpty) {
      selectedTypes = Set<String>.from(typesForFilter);
      // Sla default selectie ook meteen op
      _saveFilterPrefs();
    }
    // Filter mapObjects
    final filteredObjects = gameData.mapObjects.where((e) => selectedTypes.contains(e['type']?.toString() ?? '')).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tactical Map - WTAIASS'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filter units',
            onPressed: () async {
              final newTypes = await showDialog<Set<String>>(
                context: context,
                builder: (ctx) => MapFilterMenu(
                  allTypes: typesForFilter,
                  selectedTypes: selectedTypes,
                  onChanged: (types) {
                    Navigator.of(ctx).pop(types);
                  },
                ),
              );
              if (newTypes != null) {
                setState(() {
                  selectedTypes = newTypes;
                });
                _saveFilterPrefs();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                minScale: 0.3,
                maxScale: 10.0,
                child: Container(
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (gameData.mapImageUrl.isNotEmpty)
                          Image.network(
                            gameData.mapImageUrl,
                            key: ValueKey(lastMapImageKey ?? (gameData.mapInfo != null ? (gameData.mapInfo!['name'] ?? gameData.mapInfo!['id'] ?? DateTime.now().millisecondsSinceEpoch) : DateTime.now().millisecondsSinceEpoch)),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Minimap niet geladen', style: TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  Text('URL: \n${gameData.mapImageUrl}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                ],
                              ),
                            ),
                          ),
                        CustomPaint(
                          size: Size.infinite,
                          painter: MapPainter(
                            mapObjects: filteredObjects,
                            mapInfo: gameData.mapInfo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const HudmsgBar(),
          ],
        ),
      ),
    );
  }
}
