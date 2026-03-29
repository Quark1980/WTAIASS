import 'package:flutter/material.dart';
import '../../services/wt_api_service.dart';
import 'dart:math' as math;

/// Overlay widget for drawing historical movement trails and death markers on the minimap.
class MapOverlayTrails extends StatefulWidget {
  final WTApiService apiService;
  final Map<String, dynamic>? mapInfo;
  final Matrix4 transform;
  final double zoomScale;

  const MapOverlayTrails({
    super.key,
    required this.apiService,
    required this.mapInfo,
    required this.transform,
    required this.zoomScale,
  });

  @override
  State<MapOverlayTrails> createState() => _MapOverlayTrailsState();
}

class _MapOverlayTrailsState extends State<MapOverlayTrails> {
  @override
  void initState() {
    super.initState();
    widget.apiService.addListener(_onApiUpdate);
  }

  @override
  void dispose() {
    widget.apiService.removeListener(_onApiUpdate);
    super.dispose();
  }

  void _onApiUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bufferLen = widget.apiService.historicalBuffer.length;
    debugPrint('[OverlayWidget] build: bufferLen=$bufferLen');
    return CustomPaint(
      size: Size.infinite,
      painter: _TrailsPainter(
        apiService: widget.apiService,
        mapInfo: widget.mapInfo,
        transform: widget.transform,
        zoomScale: widget.zoomScale,
        showDebugDot: true,
      ),
    );
  }
}

class _TrailsPainter extends CustomPainter {
  final WTApiService apiService;
  final Map<String, dynamic>? mapInfo;
  final Matrix4 transform;
  final double zoomScale;
  final bool showDebugDot;

  _TrailsPainter({
    required this.apiService,
    required this.mapInfo,
    required this.transform,
    required this.zoomScale,
    this.showDebugDot = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mapInfo == null) return;
    canvas.save();
    canvas.transform(transform.storage);

    // Debug dot removed as requested

    // Draw historical trails as ultra-small, zoom-scaled dots (aligned with live units)
    final buffer = apiService.historicalBuffer;
    debugPrint('[Overlay] Drawing buffer with ${buffer.length} snapshots');
    int dotCount = 0;
    for (final snapshot in buffer) {
      for (final unit in snapshot) {
        final Offset pos = Offset(unit.x * size.width, unit.y * size.height);
        final Color color = _teamColor(unit.team);
        if (dotCount < 5) {
          debugPrint('[Overlay] Trail unit x=${unit.x} y=${unit.y} → pos=$pos color=$color');
          dotCount++;
        }
        double radius = 0.4 / zoomScale; // ultra small
        double border = 0.5 / zoomScale;
        canvas.drawCircle(pos, radius + border, Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = border);
        canvas.drawCircle(pos, radius, Paint()
          ..color = color
          ..style = PaintingStyle.fill);
      }
    }

    // Draw recent deaths as faded X markers (aligned with live units, use tracked color)
    final deaths = apiService.recentDeaths;
    debugPrint('[Overlay] Drawing ${deaths.length} recent deaths');
    final now = DateTime.now();
    int deathCount = 0;
    for (final death in deaths) {
      final Offset pos = Offset(death.x * size.width, death.y * size.height);
      final Color color = _teamColor(death.team); // Use tracked color
      if (deathCount < 5) {
        debugPrint('[Overlay] Death x=${death.x} y=${death.y} → pos=$pos color=$color');
        deathCount++;
      }
      final double t = (now.difference(death.timestamp).inMilliseconds / 4000.0).clamp(0.0, 1.0);
      final double alpha = 1.0 - t;
      if (alpha > 0.01) {
        _drawDeathX(canvas, pos, color.withOpacity(alpha), effectiveScale: 1.0 / zoomScale);
      }
    }
    canvas.restore();
  }

  // Project normalized (0..1) coordinates to minimap pixel positions.
  Offset _projectToMap(double ux, double uy, double mapMaxX, double mapMaxY, Rect dstRect) {
    // Trail dots and deaths use normalized (0..1) coordinates:
    //  - x: 0 (left) to 1 (right)
    //  - y: 0 (top) to 1 (bottom)
    // Project directly to map image using ratios, no y-flip.
    double xRatio = ux.clamp(0.0, 1.0);
    double yRatio = uy.clamp(0.0, 1.0); // Y=0 top, Y=1 bottom
    double drawX = dstRect.left + (xRatio * dstRect.width);
    double drawY = dstRect.top + (yRatio * dstRect.height);
    return Offset(drawX, drawY);
  }

  Color _teamColor(String team) {
    switch (team) {
      case 'red':
        return Colors.redAccent;
      case 'blue':
        return Colors.blueAccent;
      case 'green':
        return Colors.greenAccent;
      case 'yellow':
        return Colors.yellowAccent;
      default:
        return Colors.grey;
    }
  }

  // Draw a death marker as an X, scaled and faded (same size as live unit icon)
  void _drawDeathX(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
    final double r = 6.0 / effectiveScale; // match live icon size
    final double stroke = 2.0 / effectiveScale;
    canvas.drawLine(pos + Offset(-r, -r), pos + Offset(r, r), Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke);
    canvas.drawLine(pos + Offset(-r, r), pos + Offset(r, -r), Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
