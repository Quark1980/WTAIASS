import 'package:wt_ai_assistant/services/wt_api_service.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'widgets/map_painter.dart';

void main() {
  runApp(const WtAiAssistantApp());
}

class WtAiAssistantApp extends StatelessWidget {
  const WtAiAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WT AI Assistant',
      theme: ThemeData.dark(),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
        // Traject-tracking: unitId -> lijst van Offset (max 5 min)
        final Map<String, List<Map<String, dynamic>>> _liveTrails = {};
        // Death notifications: unitId -> {x, y, color, timestamp}
        final Map<String, Map<String, dynamic>> _deadUnits = {};
        // Laatste bekende units voor death detection
        Set<String> _lastUnitIds = {};
        // Database logging helper
        final _dbHelper = DatabaseHelper();
      void _showDebugUnitsSheet() async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            final units = _apiService?.mapObjects ?? [];
            final mapInfo = _apiService?.mapInfo;
            final mapMaxX = mapInfo != null ? mapInfo['maxX'] ?? '?' : '?';
            final mapMaxY = mapInfo != null ? mapInfo['maxY'] ?? '?' : '?';
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'mapMaxX: $mapMaxX   mapMaxY: $mapMaxY',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          onPressed: () async {
                            await _apiService?.refreshAll();
                            if (mounted) setState(() {});
                            Navigator.pop(context);
                            _showDebugUnitsSheet();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: units.isEmpty
                          ? const Center(child: Text('Geen units gevonden.'))
                          : ListView.builder(
                              itemCount: units.length,
                              itemBuilder: (context, idx) {
                                final unit = units[idx];
                                final type = unit['type']?.toString() ?? '';
                                final isSteerable = type == 'steerable';
                                final color = isSteerable ? Colors.blue : Colors.red;
                                return ListTile(
                                  title: Text(
                                    'Type: $type',
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('X: ${unit['x']}, Y: ${unit['y']}, Angle: ${unit['angle']}'),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    final TransformationController _transformationController = TransformationController();
  String? _ip;
  WTApiService? _apiService;
  bool _connected = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _apiService = WTApiService(ip: _ip);
    _apiService?.onImageLoaded = () {
      if (mounted) setState(() {});
    };
    _apiService?.startPolling(
      onUpdate: () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final mapName = _apiService?.mapInfo?['map_name']?.toString() ?? '';
        final units = _apiService?.mapObjects ?? [];
        final Set<String> newUnitIds = {};
        // Death detection: units die verdwenen zijn
        for (final id in _lastUnitIds.difference(units.map((u) => u['id']?.toString() ?? '').toSet())) {
          final lastTrail = _liveTrails[id]?.isNotEmpty == true ? _liveTrails[id]!.last : null;
          if (lastTrail != null) {
            _deadUnits[id] = {
              'pos': lastTrail['pos'],
              'color': lastTrail['color'],
              'timestamp': now,
            };
          }
        }
        // Update trails en database logging
        for (final unit in units) {
          final id = unit['id']?.toString() ?? unit['name']?.toString() ?? unit['type']?.toString() ?? '';
          newUnitIds.add(id);
          final x = (unit['x'] as num?)?.toDouble() ?? 0.0;
          final y = (unit['y'] as num?)?.toDouble() ?? 0.0;
          final type = unit['type']?.toString() ?? '';
          final side = unit['side']?.toString() ?? '';
          // Kleur
          Color color;
          if (type == 'steerable' || type == 'player') {
            color = Colors.blue;
          } else if (side == 'friend') {
            color = Colors.green;
          } else {
            color = Colors.red;
          }
          // Traject
          _liveTrails.putIfAbsent(id, () => []);
          _liveTrails[id]!.add({'pos': Offset(x, y), 'timestamp': now, 'color': color});
          // Max 5 min historie
          _liveTrails[id] = _liveTrails[id]!.where((e) => now - (e['timestamp'] as int) < 5 * 60 * 1000).toList();
          // Heading/turret_angle alleen loggen voor speler/steerable
          double? heading;
          double? turretAngle;
          if (type == 'steerable' || type == 'player') {
            heading = _apiService?.heading;
            turretAngle = _apiService?.turretAngle;
          }
          // Async database logging
          unawaited(_dbHelper.insertHistory(
            mapName: mapName,
            unitType: type,
            side: side,
            x: x,
            y: y,
            heading: heading,
            turretAngle: turretAngle,
            timestamp: now,
          ));
        }
        // Verwijder trails van units die langer dan 5 min niet meer bestaan
        for (final id in _liveTrails.keys.toList()) {
          if (!newUnitIds.contains(id) && (_liveTrails[id]?.isNotEmpty ?? false)) {
            final last = _liveTrails[id]!.last;
            if (now - (last['timestamp'] as int) > 5 * 60 * 1000) {
              _liveTrails.remove(id);
            }
          }
        }
        _lastUnitIds = newUnitIds;
        setState(() {
          _connected = _apiService?.lastConnectionOk ?? false;
          _lastError = _apiService?.lastError;
        });
      },
    );
    _ip = _apiService?.ip;
    _connected = _apiService?.lastConnectionOk ?? false;
    _lastError = _apiService?.lastError;
  }

  @override
  void dispose() {
    _apiService?.stopPolling();
    // Optionally disable wakelock when leaving the screen
    WakelockPlus.disable();
    super.dispose();
  }

  void _showIpDialog() async {
    final controller = TextEditingController(text: _apiService?.ip ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set PC IP Address'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'IP:PORT'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                setState(() {
                  _ip = ip;
                  _apiService = WTApiService(ip: _ip);
                  _apiService?.onImageLoaded = () {
                    if (mounted) setState(() {});
                  };
                  _apiService?.startPolling(
                    onUpdate: () {
                      setState(() {
                        _connected = _apiService?.lastConnectionOk ?? false;
                        _lastError = _apiService?.lastError;
                      });
                    },
                  );
                });
              }
              Navigator.pop(context, ip);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _ip = result;
        _apiService = WTApiService(ip: _ip);
        _apiService?.onImageLoaded = () {
          if (mounted) setState(() {});
        };
        _apiService?.startPolling(
          onUpdate: () {
            setState(() {
              _connected = _apiService?.lastConnectionOk ?? false;
              _lastError = _apiService?.lastError;
            });
          },
        );
      });
    }
  }
// Duplicate/broken _showIpDialog removed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WT AI Assistant'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('IP: ${_apiService?.ip ?? ''}')),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Units',
            onPressed: _showDebugUnitsSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.1,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            onInteractionUpdate: (details) => setState(() {}),
            child: CustomPaint(
              painter: TacticalMapPainter(
                mapImage: _apiService?.mapImage,
                mapInfo: _apiService?.mapInfo,
                mapObj: _apiService?.mapObjects != null ? { 'units': _apiService!.mapObjects } : null,
                transform: _transformationController.value,
                liveTrails: _liveTrails,
                deadUnits: _deadUnits,
                playerHeading: _apiService?.heading,
                playerTurretAngle: _apiService?.turretAngle,
              ),
              child: Container(),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: _connected ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _connected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _connected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_lastError != null && !_connected)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha((0.9 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'HTTP Error: $_lastError',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showIpDialog,
        tooltip: 'Settings',
        child: const Icon(Icons.settings),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final Map<String, dynamic>? mapInfo;
  final List<dynamic>? mapObjects;
  MapPainter(this.mapInfo, this.mapObjects);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    // Example: draw units if mapObjects is not null
    if (mapObjects != null) {
      for (final unit in mapObjects!) {
        final x = (unit['x'] as num?)?.toDouble() ?? 0;
        final y = (unit['y'] as num?)?.toDouble() ?? 0;
        final color = (unit['team'] == 'red') ? Colors.red : Colors.blue;
        canvas.drawCircle(Offset(x, y), 8, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
