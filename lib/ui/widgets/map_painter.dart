import 'package:flutter/material.dart';
import 'dart:math';

import 'map_grid_geometry.dart';

class MapPainter extends CustomPainter {
  final List<dynamic> mapObjects;
  final Map<String, dynamic>? mapInfo;
  final double zoomScale;
  final Map<String, List<Map<String, dynamic>>>? unitHistory;

  MapPainter({
    required this.mapObjects,
    this.mapInfo,
    this.zoomScale = 1.0,
    this.unitHistory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Grid overlay ---
    final gridGeometry = buildMapGridGeometry(mapInfo, size);
    if (gridGeometry != null) {
      final Paint extendedGridPaint = Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..strokeWidth = 0.8;
      for (double x = gridGeometry.gridRect.left;
          x >= -gridGeometry.cellWidth;
          x -= gridGeometry.cellWidth) {
        _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height), extendedGridPaint);
      }
      for (double x = gridGeometry.gridRect.left + gridGeometry.cellWidth;
          x <= size.width + gridGeometry.cellWidth;
          x += gridGeometry.cellWidth) {
        _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height), extendedGridPaint);
      }
      for (double y = gridGeometry.gridRect.top;
          y >= -gridGeometry.cellHeight;
          y -= gridGeometry.cellHeight) {
        _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), extendedGridPaint);
      }
      for (double y = gridGeometry.gridRect.top + gridGeometry.cellHeight;
          y <= size.height + gridGeometry.cellHeight;
          y += gridGeometry.cellHeight) {
        _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), extendedGridPaint);
      }

      final Paint gridPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 1.0;
      for (int c = 0; c <= gridGeometry.columnCount; c++) {
        final x = gridGeometry.gridRect.left + (c * gridGeometry.cellWidth);
        canvas.drawLine(
          Offset(x, gridGeometry.gridRect.top),
          Offset(x, gridGeometry.gridRect.bottom),
          gridPaint,
        );
      }
      for (int r = 0; r <= gridGeometry.rowCount; r++) {
        final y = gridGeometry.gridRect.top + (r * gridGeometry.cellHeight);
        canvas.drawLine(
          Offset(gridGeometry.gridRect.left, y),
          Offset(gridGeometry.gridRect.right, y),
          gridPaint,
        );
      }

      const double metersPerUnit = 200.0 / 225.0;
      final gridInfo = 'Gridcel: ${gridGeometry.cellSizeX.toStringAsFixed(0)}x${gridGeometry.cellSizeY.toStringAsFixed(0)} units = ${(gridGeometry.cellSizeX * metersPerUnit).toStringAsFixed(0)}x${(gridGeometry.cellSizeY * metersPerUnit).toStringAsFixed(0)} m';
      final gridInfoStyle = TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 14 / zoomScale,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))],
      );
      final gridInfoPainter = TextPainter(
        text: TextSpan(text: gridInfo, style: gridInfoStyle),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      gridInfoPainter.layout();
      const double margin = 8.0;
      final infoPos = Offset(margin, size.height - gridInfoPainter.height - margin);
      gridInfoPainter.paint(canvas, infoPos);
    }
    if (mapObjects.isEmpty) return;

    // Draw fading route tails for each unit
    if (unitHistory != null && mapInfo != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fadeDuration = 300000; // 5 min in ms
      for (final entry in unitHistory!.entries) {
        final points = entry.value;
        if (points.length < 2) continue;
        // Try to get the team color from the first point (should be consistent for the unit)
        Color teamColor = Colors.grey;
        final String? hex = points.first['color'] as String?;
        if (hex != null && hex.startsWith('#') && hex.length == 7) {
          teamColor = Color(int.parse('FF${hex.substring(1)}', radix: 16));
        }
        Offset? last;
        for (int i = 0; i < points.length; i++) {
          final p = points[i];
          final double? x = (p['x'] as num?)?.toDouble();
          final double? y = (p['y'] as num?)?.toDouble();
          if (x == null || y == null) continue;
          final drawX = x * size.width;
          final drawY = y * size.height;
          final pos = Offset(drawX, drawY);
          if (last != null) {
            // Fade: newer segments more opaque
            final t = (p['timestamp'] as int?) ?? now;
            final age = now - t;
            double alpha = 1.0 - (age / fadeDuration);
            if (alpha < 0.05) alpha = 0.05;
            if (alpha > 1.0) alpha = 1.0;
            final paint = Paint()
              ..color = teamColor.withOpacity(alpha)
              ..strokeWidth = 2.0 / zoomScale
              ..style = PaintingStyle.stroke;
            canvas.drawLine(last, pos, paint);
          }
          last = pos;
        }
      }
    }

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / zoomScale
      ..color = Colors.black;

    // Find player position (normalized)
    Offset? playerPos;
    if (mapObjects.isNotEmpty) {
      for (final obj in mapObjects) {
        final String icon = (obj['icon'] ?? '').toString();
        if (icon == 'Player') {
          final double? px = (obj['x'] as num?)?.toDouble();
          final double? py = (obj['y'] as num?)?.toDouble();
          if (px != null && py != null) {
            playerPos = Offset(px, py);
            break;
          }
        }
      }
    }

    double mapWidth = 1.0;
    double mapHeight = 1.0;
    double minX = 0.0, minY = 0.0, maxX = 1.0, maxY = 1.0;
    double metersPerUnit = 200.0 / 225.0;
    if (mapInfo != null && mapInfo!['map_max'] != null && mapInfo!['map_min'] != null) {
      final List<dynamic> max = mapInfo!['map_max'];
      final List<dynamic> min = mapInfo!['map_min'];
      if (max.length == 2 && min.length == 2) {
        minX = (min[0] as num).toDouble();
        minY = (min[1] as num).toDouble();
        maxX = (max[0] as num).toDouble();
        maxY = (max[1] as num).toDouble();
        mapWidth = maxX - minX;
        mapHeight = maxY - minY;
      }
    }

    for (var obj in mapObjects) {
      // Gebruik direct de genormaliseerde x/y (0..1) uit de JSON
      final double? x = (obj['x'] as num?)?.toDouble();
      final double? y = (obj['y'] as num?)?.toDouble();
      if (x == null || y == null) continue;

      // Kleur uit hex-string

      Color teamColor = Colors.grey;
      final String? hex = obj['color'] as String?;
      // Debug print for color
      // ignore: avoid_print
      print('[MapPainter] obj color field: $hex for icon: ${obj['icon']}');
      if (hex != null && hex.startsWith('#') && hex.length == 7) {
        teamColor = Color(int.parse('FF${hex.substring(1)}', radix: 16));
      }
      // Debug print for actual teamColor value
      // ignore: avoid_print
      print('[MapPainter] using teamColor: $teamColor for icon: ${obj['icon']}');
      fillPaint.color = teamColor;

      final double drawX = x * size.width;
      final double drawY = y * size.height;
      final Offset pos = Offset(drawX, drawY);

      // Compenseer voor zoom: radius delen door de schaal van de canvas t.o.v. de originele map
      double scale = 1.0;
      if (size.width > 0 && size.height > 0 && mapInfo != null) {
        final widthVal = mapInfo!['width'];
        final heightVal = mapInfo!['height'];
        if (widthVal != null && heightVal != null) {
          final double baseW = (widthVal as num).toDouble();
          final double baseH = (heightVal as num).toDouble();
          final double scaleW = size.width / baseW;
          final double scaleH = size.height / baseH;
          scale = (scaleW + scaleH) / 2.0;
        }
      }

      // --- Distance label logic ---
      if (playerPos != null && (obj['icon'] ?? '') != 'Player') {
        // playerPos is ook genormaliseerd
        final dxNorm = x - playerPos.dx;
        final dyNorm = y - playerPos.dy;
        // Omrekenen naar mapunits (afstand in 0..1 * mapWidth) en dan naar meters
        final distUnits = sqrt(dxNorm * dxNorm + dyNorm * dyNorm) * mapWidth;
        final distMeters = distUnits * metersPerUnit;
        final distText = '${distMeters.toStringAsFixed(0)} m';
        final textSpan = TextSpan(
          text: distText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 8 / zoomScale,
            fontWeight: FontWeight.w500,
            shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(0.5, 0.5))],
          ),
        );
        final tp = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, pos - Offset(tp.width / 2, 14 / zoomScale));
      }

      // Tactical icon rendering
      final String icon = (obj['icon'] ?? '').toString();
      final String type = (obj['type'] ?? '').toString();
      final double baseSize = 6.0 / zoomScale;
      final double captureZoneSize = baseSize * 2;
      final double strokeW = 1.0 / zoomScale;
      final Paint outline = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW;
      final Paint fill = Paint()
        ..color = teamColor
        ..style = PaintingStyle.fill;

      void drawCaptureZone() {
        canvas.drawCircle(pos, captureZoneSize / 2, fill);
        canvas.drawCircle(pos, captureZoneSize / 2, outline);
        String letter = '?';
        final iconVal = obj['icon'];
        if (iconVal is String && iconVal.isNotEmpty) {
          letter = iconVal.substring(0, 1).toUpperCase();
        }
        final textSpan = TextSpan(
          text: letter,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14 / zoomScale),
        );
        final tp = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }

      void drawMediumTank() {
        final rect = Rect.fromCenter(center: pos, width: baseSize, height: baseSize);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, outline);
      }

      void drawHeavyTank() {
        final rect = Rect.fromCenter(center: pos, width: baseSize, height: baseSize);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, outline);
        // Dikke verticale lijn
        final p1 = Offset(pos.dx, pos.dy - baseSize / 2);
        final p2 = Offset(pos.dx, pos.dy + baseSize / 2);
        final thick = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0 / zoomScale;
        canvas.drawLine(p1, p2, thick);
      }

      void drawLightTank() {
        final rect = Rect.fromCenter(center: pos, width: baseSize, height: baseSize);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, outline);
        // Diagonale lijn
        final p1 = Offset(pos.dx - baseSize / 2, pos.dy + baseSize / 2);
        final p2 = Offset(pos.dx + baseSize / 2, pos.dy - baseSize / 2);
        final diag = Paint()
          ..color = Colors.white
          ..strokeWidth = strokeW;
        canvas.drawLine(p1, p2, diag);
      }

      void drawTankDestroyer() {
        final path = Path();
        path.moveTo(pos.dx - baseSize / 2, pos.dy - baseSize / 2);
        path.lineTo(pos.dx + baseSize / 2, pos.dy - baseSize / 2);
        path.lineTo(pos.dx, pos.dy + baseSize / 2);
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, outline);
      }

      void drawSPAA() {
        canvas.drawCircle(pos, baseSize / 2, fill);
        canvas.drawCircle(pos, baseSize / 2, outline);
        // Twee antennes
        final ant1 = Offset(pos.dx - baseSize * 0.2, pos.dy - baseSize / 2);
        final ant2 = Offset(pos.dx + baseSize * 0.2, pos.dy - baseSize / 2);
        final top = Offset(pos.dx, pos.dy - baseSize / 2 - baseSize * 0.2);
        final antPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = strokeW;
        canvas.drawLine(ant1, top, antPaint);
        canvas.drawLine(ant2, top, antPaint);
      }

      void drawFighter() {
        final path = Path();
        path.moveTo(pos.dx, pos.dy - baseSize / 2);
        path.lineTo(pos.dx - baseSize / 2, pos.dy + baseSize / 2);
        path.lineTo(pos.dx + baseSize / 2, pos.dy + baseSize / 2);
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, outline);
      }

      void drawBomber() {
        final path = Path();
        path.moveTo(pos.dx - baseSize / 2, pos.dy);
        path.lineTo(pos.dx, pos.dy - baseSize / 2);
        path.lineTo(pos.dx + baseSize / 2, pos.dy);
        path.lineTo(pos.dx, pos.dy + baseSize / 2);
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, outline);
      }

      void drawPlayer() {
        // Player as a filled circle with outline
        canvas.drawCircle(pos, baseSize / 2, fill);
        canvas.drawCircle(pos, baseSize / 2, outline);
      }

      // Icon logic
      if (type == 'capture_zone' || type == 'zone') {
        drawCaptureZone();
      } else if (icon == 'MediumTank') {
        drawMediumTank();
      } else if (icon == 'HeavyTank') {
        drawHeavyTank();
      } else if (icon == 'LightTank') {
        drawLightTank();
      } else if (icon == 'TankDestroyer') {
        drawTankDestroyer();
      } else if (icon == 'SPAA') {
        drawSPAA();
      } else if (icon == 'Fighter') {
        drawFighter();
      } else if (icon == 'Bomber') {
        drawBomber();
      } else if (icon == 'Player') {
        drawPlayer();
      } else {
        // fallback: cirkel
        final double r = 5 / zoomScale;
        canvas.drawCircle(pos, r, fill);
        canvas.drawCircle(pos, r, outline);
      }

      // Richtingspijl indien dx/dy aanwezig (meeschalen met baseSize)
      if (obj['dx'] != null && obj['dy'] != null) {
        final dx = (obj['dx'] as num).toDouble();
        final dy = (obj['dy'] as num).toDouble();
        if (dx.abs() > 0.01 || dy.abs() > 0.01) {
          final arrowLength = baseSize * 2.5; // Schaalbaar met icoon
          final endPos = pos + Offset(dx * arrowLength, dy * arrowLength);
          final arrowPaint = Paint()
            ..color = teamColor
            ..strokeWidth = 1.5 / zoomScale
            ..style = PaintingStyle.stroke;
          canvas.drawLine(pos, endPos, arrowPaint);
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashLength = 8.0;
    const double gapLength = 6.0;
    final totalLength = (end - start).distance;
    if (totalLength == 0) return;

    final direction = (end - start) / totalLength;
    double distance = 0.0;
    while (distance < totalLength) {
      final dashStart = start + (direction * distance);
      final dashEnd = start + (direction * (distance + dashLength).clamp(0.0, totalLength));
      canvas.drawLine(dashStart, dashEnd, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
