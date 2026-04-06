import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/wt_api_service.dart';
import 'map_grid_geometry.dart';

class MapGridFlashOverlay extends StatefulWidget {
  final WTApiService apiService;
  final Map<String, dynamic>? mapInfo;
  final double zoomScale;

  const MapGridFlashOverlay({
    super.key,
    required this.apiService,
    required this.mapInfo,
    required this.zoomScale,
  });

  @override
  State<MapGridFlashOverlay> createState() => _MapGridFlashOverlayState();
}

class _MapGridFlashOverlayState extends State<MapGridFlashOverlay> {
  @override
  void initState() {
    super.initState();
    widget.apiService.addListener(_onApiUpdate);
  }

  @override
  void didUpdateWidget(covariant MapGridFlashOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiService != widget.apiService) {
      oldWidget.apiService.removeListener(_onApiUpdate);
      widget.apiService.addListener(_onApiUpdate);
    }
  }

  @override
  void dispose() {
    widget.apiService.removeListener(_onApiUpdate);
    super.dispose();
  }

  void _onApiUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridFlashPainter(
          mapInfo: widget.mapInfo,
          zoomScale: widget.zoomScale,
          flashEvents: widget.apiService.activeGridFlashEvents,
        ),
      ),
    );
  }
}

class _GridFlashPainter extends CustomPainter {
  final Map<String, dynamic>? mapInfo;
  final double zoomScale;
  final List<GridFlashEvent> flashEvents;

  _GridFlashPainter({
    required this.mapInfo,
    required this.zoomScale,
    required this.flashEvents,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (flashEvents.isEmpty) return;
    final gridGeometry = buildMapGridGeometry(mapInfo, size);
    if (gridGeometry == null) return;
    final DateTime now = DateTime.now();
    int drawnCount = 0;

    for (final event in flashEvents) {
      final rect = gridGeometry.rectForCellRef(event.cellRef);
      if (rect == null) continue;

      final elapsedMs = now.difference(event.startedAt).inMilliseconds.clamp(0, event.durationMs);
      final progress = event.durationMs == 0 ? 1.0 : elapsedMs / event.durationMs;
      final pulse = 0.55 + (0.45 * math.sin(progress * math.pi * 6));
      final alpha = ((1.0 - progress) * pulse).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      final glowPaint = Paint()
        ..color = Colors.amberAccent.withOpacity(alpha * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0 / zoomScale;

      final borderPaint = Paint()
        ..color = Colors.amberAccent.withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 / zoomScale;

      canvas.drawRect(rect.inflate(2.0 / zoomScale), glowPaint);
      canvas.drawRect(rect, borderPaint);
      drawnCount++;
      if (drawnCount <= 3) {
        debugPrint('[GridFlashOverlay] Drawing ${event.cellRef} rect=$rect alpha=${alpha.toStringAsFixed(2)}');
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridFlashPainter oldDelegate) {
    return oldDelegate.mapInfo != mapInfo ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.flashEvents != flashEvents;
  }
}