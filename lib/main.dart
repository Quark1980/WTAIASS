import 'package:flutter/material.dart';
import 'widgets/map_painter.dart';
import 'services/wt_api_service.dart';

void main() {
  runApp(WtAiAssistantApp());
}

class WtAiAssistantApp extends StatefulWidget {
  WtAiAssistantApp({super.key});

  @override
  State<WtAiAssistantApp> createState() => _WtAiAssistantAppState();
}

class _WtAiAssistantAppState extends State<WtAiAssistantApp> {
  WTApiService? _apiService;
  String? _ip;
  bool _connected = false;
  String? _lastError;
  final TransformationController _transformationController = TransformationController();
  Map<String, List<Map<String, dynamic>>> _liveTrails = {};
  Map<String, Map<String, dynamic>> _deadUnits = {};

  @override
  void initState() {
    super.initState();
    // Init API service if needed
    // _apiService = WTApiService(ip: _ip); // Optionally set default IP
    // _apiService?.startPolling(onUpdate: _onApiUpdate);
  }

  void _onApiUpdate() {
    setState(() {
      _connected = _apiService?.lastConnectionOk ?? false;
      _lastError = _apiService?.lastError;
    });
  }

  @override
  void dispose() {
    _apiService?.stopPolling();
    _transformationController.dispose();
    super.dispose();
  }

  // (Laat slechts één _showIpDialog bestaan)

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
// ...existing code...
      return Scaffold(
        appBar: AppBar(
          title: Text('WT AI Assistant'),
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: Text('IP: ${_apiService?.ip ?? ''}')),
            ),
          ],
        ),
        body: Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.1,
              maxScale: 5.0,
              boundaryMargin: EdgeInsets.all(double.infinity),
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
                  SizedBox(width: 4),
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((0.9 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'HTTP Error: $_lastError',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showIpDialog,
          tooltip: 'Settings',
          child: Icon(Icons.settings),
        ),
      );
  }
}
