import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;


class TacticalMapPainter extends CustomPainter {
  final ui.Image? mapImage;
  final Map<String, dynamic>? mapInfo;
  final Map<String, dynamic>? mapObj;
  final Matrix4 transform;

  TacticalMapPainter({this.mapImage, this.mapInfo, this.mapObj, required this.transform});

  @override
  void paint(Canvas canvas, Size size) {
    final double zoomScale = transform.getMaxScaleOnAxis();
    canvas.save();
    canvas.transform(transform.storage);
    // 1. Achtergrond en Debug Border
    final borderPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Offset.zero & size, borderPaint);

    if (mapImage == null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
      canvas.restore();
      return;
    }

    // 2. Bereken de schaling van de kaart (BoxFit.contain logica)
    final imgW = mapImage!.width.toDouble();
    final imgH = mapImage!.height.toDouble();
    final scale = math.min(size.width / imgW, size.height / imgH);
    final displayW = imgW * scale;
    final displayH = imgH * scale;

    // De offsets (dx, dy) bepalen waar de kaart begint binnen de widget
    final mapOffsetDx = (size.width - displayW) / 2;
    final mapOffsetDy = (size.height - displayH) / 2;
    final dstRect = Rect.fromLTWH(mapOffsetDx, mapOffsetDy, displayW, displayH);

    // Teken de kaart
    canvas.drawImageRect(
      mapImage!,
      Rect.fromLTWH(0, 0, imgW, imgH),
      dstRect,
      Paint(),
    );

    // 3. Units tekenen met dynamische schaling
    if (mapObj == null) {
      canvas.restore();
      return;
    }
    final units = mapObj!['units'] as List<dynamic>? ?? [];

    // Dynamische mapMax schaal uit map_info.json
    double mapMaxX = 4096.0;
    double mapMaxY = 4096.0;
    if (mapInfo != null && mapInfo!['map_max'] is List && mapInfo!['map_max'].length >= 2) {
      mapMaxX = (mapInfo!['map_max'][0] as num?)?.toDouble() ?? 4096.0;
      mapMaxY = (mapInfo!['map_max'][1] as num?)?.toDouble() ?? 4096.0;
    }

    for (final unit in units) {
      final ux = (unit['x'] as num?)?.toDouble() ?? 0.0;
      final uy = (unit['y'] as num?)?.toDouble() ?? 0.0;
      final type = unit['type'] as String? ?? '';
      // Projectie: linksboven-oorsprong
      double xRatio = ux / mapMaxX;
      double yRatio = uy / mapMaxY;
      double drawX = dstRect.left + (xRatio * displayW);
      double drawY = dstRect.top + (yRatio * displayH);
      final double angle = (unit['angle'] as num?)?.toDouble() ?? 0.0;
      final color = (type == 'steerable' || type == 'player') ? Colors.blue : Colors.red;
      _drawUnit(canvas, Offset(drawX, drawY), angle, color, effectiveScale: 1.0 / zoomScale);
    }
    canvas.restore();
  }

  void _drawUnit(Canvas canvas, Offset pos, double direction, Color color, {double effectiveScale = 1.0}) {
    final double size = 12.0 * effectiveScale;
    final double strokeWidth = 2.0 * effectiveScale;
    final double arrowLength = 18.0 * effectiveScale;
    final double arrowWidth = 10.0 * effectiveScale;
    final angleRad = (direction - 90) * math.pi / 180.0;
    final path = Path();
    path.moveTo(
      pos.dx + arrowLength * math.cos(angleRad),
      pos.dy + arrowLength * math.sin(angleRad),
    );
    path.lineTo(
      pos.dx + arrowWidth * math.cos(angleRad + 2.5),
      pos.dy + arrowWidth * math.sin(angleRad + 2.5),
    );
    path.lineTo(
      pos.dx + arrowWidth * math.cos(angleRad - 2.5),
      pos.dy + arrowWidth * math.sin(angleRad - 2.5),
    );
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawArrow(Canvas canvas, Offset pos, double direction, Color color, {double scale = 1.0}) {
    final arrowLength = 18.0 * scale;
    final arrowWidth = 10.0 * scale;
    // War Thunder angles naar radialen (correctie voor orientatie indien nodig)
    final angleRad = (direction - 90) * math.pi / 180.0; 

    final path = Path();
    path.moveTo(
      pos.dx + arrowLength * math.cos(angleRad),
      pos.dy + arrowLength * math.sin(angleRad),
    );
    path.lineTo(
      pos.dx + arrowWidth * math.cos(angleRad + 2.5),
      pos.dy + arrowWidth * math.sin(angleRad + 2.5),
    );
    path.lineTo(
      pos.dx + arrowWidth * math.cos(angleRad - 2.5),
      pos.dy + arrowWidth * math.sin(angleRad - 2.5),
    );
    path.close();

    // Teken een randje om het pijltje voor betere zichtbaarheid
    canvas.drawPath(path, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant TacticalMapPainter oldDelegate) => true;
}