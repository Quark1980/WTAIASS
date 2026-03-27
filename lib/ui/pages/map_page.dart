import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/game_data_service.dart';
import '../../services/unit_history_provider.dart';
import '../widgets/map_painter.dart';
import '../widgets/map_filter_menu.dart';
import '../widgets/map_display.dart';

import '../../logic/tracker_service.dart';
import '../../services/database_helper.dart';
import '../../services/wt_api_service.dart';
import '../widgets/log_feed_box.dart';

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
  final UnitHistoryProvider _unitHistoryProvider = UnitHistoryProvider();
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  final UnitTrackingService _tracker = UnitTrackingService();
  Set<String> selectedTypes = {};
  Set<String> knownTypes = {};
  String? lastMapId;
  int? lastMapGeneration;
  String? lastMapImageKey;
  @override
  void initState() {
    super.initState();
    _loadFilterPrefs();
    _unitHistoryProvider.startAutoRefresh();

    // Start chat & HUD polling with unique match ID
    Future.microtask(() async {
      // Import WTApiService here to avoid breaking existing providers
      // (Assume you have a singleton or global instance, or use Provider if available)
      final WTApiService? api = _findApiService(context);
      if (api != null) {
        final matchId = DateTime.now().millisecondsSinceEpoch.toString();
        api.setCurrentMatchId(matchId);
        api.startChatHudPolling();
      }
    });
  }

  WTApiService? _findApiService(BuildContext context) {
    try {
      // If you use Provider for WTApiService, use this:
      // return Provider.of<WTApiService>(context, listen: false);
      // Otherwise, return your singleton/global instance here:
      return WTApiService();
    } catch (_) {
      return null;
    }
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
    int? mapGeneration;
    if (mapInfo != null) {
      if (mapInfo['width'] != null && mapInfo['height'] != null) {
        final w = (mapInfo['width'] as num).toDouble();
        final h = (mapInfo['height'] as num).toDouble();
        if (w > 0 && h > 0) aspect = w / h;
      }
      mapId = mapInfo['id']?.toString() ?? mapInfo['name']?.toString();
      mapGeneration = gameData.mapGeneration;
    }

    // Forceer refresh van map image bij nieuwe match (nieuwe mapId of mapGeneration)
    if (mapId != null &&
        (mapId != lastMapId || mapGeneration != lastMapGeneration)) {
      lastMapId = mapId;
      lastMapGeneration = mapGeneration;
      // Unieke key voor MapDisplay zodat deze geforceerd ververst
      lastMapImageKey = DateTime.now().millisecondsSinceEpoch.toString();
    }

    // Verzamel alle types uit de huidige mapObjects
    final allTypes = gameData.mapObjects
        .map((e) => e['type']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toSet();
    // Onthoud alle bekende types (ook tussen matches)
    if (allTypes.isNotEmpty) {
      knownTypes.addAll(allTypes);
    }
    // Toon altijd alle bekende types én fallback types (uniek)
    final typesForFilter = <String>{
      ...knownTypes,
      ...allTypes,
      ...fallbackTypes,
    };
    // Init: als nog geen selectie, alles aan
    if (selectedTypes.isEmpty && typesForFilter.isNotEmpty) {
      selectedTypes = Set<String>.from(typesForFilter);
      // Sla default selectie ook meteen op
      _saveFilterPrefs();
    }
    // Filter mapObjects
    final filteredObjects = gameData.mapObjects
        .where((e) => selectedTypes.contains(e['type']?.toString() ?? ''))
        .toList();

      // Update tracker with latest map objects
      _tracker.updateUnits(gameData.mapObjects.cast<Map<String, dynamic>>());

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
            // Kaart max 60% van het scherm
            Flexible(
              flex: 6,
              child: AnimatedBuilder(
                animation: _unitHistoryProvider,
                builder: (context, _) {
                  return InteractiveViewer(
                    minScale: 0.3,
                    maxScale: 10.0,
                    transformationController: _transformationController,
                    onInteractionUpdate: (details) {
                      final matrix = _transformationController.value;
                      final scale = (matrix.storage[0] + matrix.storage[5]) / 2.0;
                      setState(() {
                        _currentScale = scale;
                      });
                    },
                    child: Container(
                      color: Colors.black,
                      child: MapDisplay(
                        key: ValueKey(lastMapImageKey ??
                            (gameData.mapInfo != null
                                ? (gameData.mapInfo!['name'] ??
                                    gameData.mapInfo!['id'] ??
                                    DateTime.now().millisecondsSinceEpoch)
                                : DateTime.now().millisecondsSinceEpoch)),
                        imageUrl: gameData.getMapImageUrl(),
                        aspectRatio: aspect,
                        placeholderText: 'Minimap niet geladen',
                        onReload: () {
                          setState(() {
                            lastMapImageKey =
                                DateTime.now().millisecondsSinceEpoch.toString();
                          });
                        },
                        overlay: CustomPaint(
                          size: Size.infinite,
                          painter: MapPainter(
                            mapObjects: filteredObjects,
                            mapInfo: gameData.mapInfo,
                            zoomScale: _currentScale,
                            unitHistory: _unitHistoryProvider.recentHistory,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Laatste 5 logs onder de kaart, 40% van het scherm
            Flexible(
              flex: 4,
              child: LogFeedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
