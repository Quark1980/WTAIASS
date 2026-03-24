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
      onUpdate: () {
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
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            child: CustomPaint(
              painter: TacticalMapPainter(
                mapImage: _apiService?.mapImage,
                mapInfo: _apiService?.mapInfo,
                mapObj: _apiService?.mapObjects != null ? { 'units': _apiService!.mapObjects } : null,
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
              bottom: 24,
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
