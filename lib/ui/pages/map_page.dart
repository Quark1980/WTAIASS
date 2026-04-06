import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/game_data_service.dart';
import '../../services/unit_history_provider.dart';
import '../widgets/map_painter.dart';
import '../widgets/map_filter_menu.dart';
import '../widgets/map_display.dart';
import '../widgets/map_grid_flash_overlay.dart';
import '../widgets/map_overlay_trails.dart';
import '../widgets/settings_grid_flash_duration_dialog.dart';
import '../widgets/settings_trail_buffer_dialog.dart';
import '../../logic/tracker_service.dart';
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
    void _showDebugSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => const _LiveDebugDataSheet(),
      );
    }
  final UnitHistoryProvider _unitHistoryProvider = UnitHistoryProvider();
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  final UnitTrackingService _tracker = UnitTrackingService();
  Set<String> selectedTypes = {};
  bool _filtersLoaded = false;
  Set<String> knownTypes = {};
  String? lastMapId;
  int? lastMapGeneration;
  String? lastMapImageKey;
  @override
  void initState() {
    super.initState();
    _loadFilterPrefs();
    _unitHistoryProvider.startAutoRefresh();

    // Start chat & HUD polling met Provider WTApiService
    Future.microtask(() async {
      final api = Provider.of<WTApiService>(context, listen: false);
      final matchId = DateTime.now().millisecondsSinceEpoch.toString();
      api.setCurrentMatchId(matchId);
      await api.syncEventIds();
      api.startChatHudPolling();
      api.startPolling(); // Start polling for map objects and state
    });
  }

  // WTApiService wordt nu via Provider gebruikt, deze helper is niet meer nodig.

  Future<void> _loadFilterPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('selectedTypes');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        selectedTypes = saved.toSet();
        _filtersLoaded = true;
      });
    } else {
      setState(() {
        _filtersLoaded = true;
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
    final apiService = context.watch<WTApiService>();
    if (!_filtersLoaded) {
      // Wait for filter preferences to load before building UI
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
    if (apiService.mapImage != null && apiService.mapImage!.height > 0) {
      aspect = apiService.mapImage!.width / apiService.mapImage!.height;
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
    // Init: als nog geen selectie, alles aan, maar alleen als filters nog niet geladen zijn (eerste keer)
    // (No longer needed, handled in _loadFilterPrefs)
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onSelected: (value) async {
              if (value == 'settings') {
                final prefs = await SharedPreferences.getInstance();
                final currentIp = prefs.getString('pc_ip') ?? '192.168.0.61';
                await showDialog(
                  context: context,
                  builder: (ctx) {
                    final controller = TextEditingController(text: currentIp);
                    return AlertDialog(
                      title: const Text('Connection Settings'),
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
                            final ip = controller.text;
                            await prefs.setString('pc_ip', ip);
                            // Update all services that use the IP
                            if (mounted) setState(() {});
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
              } else if (value == 'trail_buffer') {
                final prefs = await SharedPreferences.getInstance();
                final initial = prefs.getInt('trail_buffer_seconds') ?? 60;
                await showDialog(
                  context: context,
                  builder: (ctx2) => SettingsTrailBufferDialog(
                    initialSeconds: initial,
                    onSave: (val) {
                      context.read<WTApiService>().loadBufferSettings();
                    },
                  ),
                );
              } else if (value == 'flash_duration') {
                final apiService = context.read<WTApiService>();
                await showDialog(
                  context: context,
                  builder: (ctx2) => SettingsGridFlashDurationDialog(
                    initialDurationMs: apiService.gridFlashDurationMs,
                    onSave: (val) {
                      apiService.loadGridFlashSettings();
                    },
                  ),
                );
              } else if (value == 'debug') {
                _showDebugSheet();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Connection Settings'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'trail_buffer',
                child: ListTile(
                  leading: Icon(Icons.timeline),
                  title: Text('Trail Buffer Settings'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'flash_duration',
                child: ListTile(
                  leading: Icon(Icons.flash_on),
                  title: Text('Grid Flash Duration'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'debug',
                child: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Raw Data Debug'),
                ),
              ),
            ],
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
                      child: Transform(
                        transform: _transformationController.value,
                        alignment: Alignment.topLeft,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MapDisplay(
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
                            // Draw tactical overlay trails ON TOP of map and live units
                            Consumer<WTApiService>(
                              builder: (context, apiService, _) => MapOverlayTrails(
                                apiService: apiService,
                                mapInfo: gameData.mapInfo,
                                zoomScale: _currentScale,
                              ),
                            ),
                            Consumer<WTApiService>(
                              builder: (context, apiService, _) => MapGridFlashOverlay(
                                apiService: apiService,
                                mapInfo: gameData.mapInfo,
                                zoomScale: _currentScale,
                              ),
                            ),
                          ],
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
      // No floatingActionButton (debug now in menu)
    );
  }
}

// Bottom sheet widget for live debug data
class _LiveDebugDataSheet extends StatefulWidget {
  const _LiveDebugDataSheet();

  @override
  State<_LiveDebugDataSheet> createState() => _LiveDebugDataSheetState();
}

class _LiveDebugDataSheetState extends State<_LiveDebugDataSheet> {
  String? chatJson;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _fetchChat();
  }

  Future<void> _fetchChat() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('pc_ip') ?? '192.168.0.61';
      final url = Uri.parse('http://$ip:8111/gamechat?lastId=0');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        setState(() => chatJson = resp.body);
      } else {
        setState(() => chatJson = 'HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
      }
    } catch (e) {
      setState(() => chatJson = 'Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameDataService>();
    String prettyJson(Object? data) {
      try {
        return JsonEncoder.withIndent('  ').convert(data);
      } catch (_) {
        return data?.toString() ?? '';
      }
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Raw Data Debug', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchChat,
                  tooltip: 'Herlaad chat feed',
                ),
              ],
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
            const SizedBox(height: 12),
            Text('Live /gamechat?lastId=0:'),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              )
            else
              SelectableText(chatJson ?? 'No data'),
          ],
        ),
      ),
    );
  }
}
