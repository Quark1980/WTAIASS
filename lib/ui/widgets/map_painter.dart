import 'package:flutter/material.dart';
import 'dart:math';

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
    if (mapInfo != null && mapInfo!['map_max'] != null && mapInfo!['map_min'] != null && mapInfo!['grid_steps'] != null) {
      final List<dynamic> mapMax = mapInfo!['map_max'];
      final List<dynamic> mapMin = mapInfo!['map_min'];
      final List<dynamic> gridSteps = mapInfo!['grid_steps'];
      if (mapMax.length == 2 && mapMin.length == 2 && gridSteps.length == 2) {
        final double minX = (mapMin[0] as num).toDouble();
        final double minY = (mapMin[1] as num).toDouble();
        final double maxX = (mapMax[0] as num).toDouble();
        final double maxY = (mapMax[1] as num).toDouble();
        final double cellSizeX = (gridSteps[0] as num).toDouble();
        final double cellSizeY = (gridSteps[1] as num).toDouble();
        final int cols = ((maxX - minX) / cellSizeX).floor();
        final int rows = ((maxY - minY) / cellSizeY).floor();
        final double cellW = size.width / cols;
        final double cellH = size.height / rows;
        final Paint gridPaint = Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..strokeWidth = 1.0;
        // Verticale lijnen
        for (int c = 0; c <= cols; c++) {
          final x = c * cellW;
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        }
        // Horizontale lijnen
        for (int r = 0; r <= rows; r++) {
          final y = r * cellH;
          canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
        }
        // Labels (A, B, C... en 1, 2, 3...)
        final labelStyle = TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12 / zoomScale, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(0.5, 0.5))]);
        // Kolomlabels bovenaan
        for (int c = 0; c < cols; c++) {
          final label = (c + 1).toString();
          final tp = TextPainter(text: TextSpan(text: label, style: labelStyle), textAlign: TextAlign.center, textDirection: TextDirection.ltr);
          tp.layout();
          final x = c * cellW + cellW / 2 - tp.width / 2;
          tp.paint(canvas, Offset(x, 2));
        }
        // Rijlabels links
        for (int r = 0; r < rows; r++) {
          final label = String.fromCharCode(65 + r); // A=65
          final tp = TextPainter(text: TextSpan(text: label, style: labelStyle), textAlign: TextAlign.center, textDirection: TextDirection.ltr);
          tp.layout();
          final y = r * cellH + cellH / 2 - tp.height / 2;
          tp.paint(canvas, Offset(2, y));
        }

        // --- Grid size in meters linksonder ---
        double metersPerUnit = 200.0 / 225.0;
        String gridInfo = 'Gridcel: ${cellSizeX.toStringAsFixed(0)}x${cellSizeY.toStringAsFixed(0)} units = ${(cellSizeX*metersPerUnit).toStringAsFixed(0)}x${(cellSizeY*metersPerUnit).toStringAsFixed(0)} m';
        final gridInfoStyle = TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 14 / zoomScale,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))],
        );
        final gridInfoPainter = TextPainter(
          text: TextSpan(text: gridInfo, style: gridInfoStyle),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        gridInfoPainter.layout();
        // 8px margin from left and bottom
        final double margin = 8.0;
        final Offset infoPos = Offset(margin, size.height - gridInfoPainter.height - margin);
        gridInfoPainter.paint(canvas, infoPos);
      }
    }
    if (mapObjects.isEmpty) return;

    // Draw fading route tails for each unit
    if (unitHistory != null && mapInfo != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fadeDuration = 300000; // 5 min in ms
      for (final entry in unitHistory!.entries) {
        final points = entry.value;
        if (points.length < 2) continue;
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
              ..color = Colors.white.withOpacity(alpha)
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
      if (hex != null && hex.startsWith('#') && hex.length == 7) {
        teamColor = Color(int.parse('FF${hex.substring(1)}', radix: 16));
      }
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
        final distText = distMeters.toStringAsFixed(0) + ' m';
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
      final double strokeW = 1.0 / zoomScale;
      final Paint outline = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW;
      final Paint fill = Paint()
        ..color = teamColor
        ..style = PaintingStyle.fill;

      void drawCaptureZone() {
        canvas.drawCircle(pos, baseSize / 2, fill);
        canvas.drawCircle(pos, baseSize / 2, outline);
        String letter = '?';
        final iconVal = obj['icon'];
        if (iconVal is String && iconVal.isNotEmpty) {
          letter = iconVal.substring(0, 1).toUpperCase();
        }
        final textSpan = TextSpan(
          text: letter,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10 / zoomScale),
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
        // Romp: pijl
        final path = Path();
        path.moveTo(pos.dx, pos.dy - baseSize / 2);
        path.lineTo(pos.dx - baseSize / 3, pos.dy + baseSize / 2);
        path.lineTo(pos.dx + baseSize / 3, pos.dy + baseSize / 2);
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, outline);
        // Koepel: cirkel
        canvas.drawCircle(pos, baseSize * 0.2, fill);
        canvas.drawCircle(pos, baseSize * 0.2, outline);
        // Loop: lijn omhoog (meeschalen)
        final loopPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = strokeW;
        canvas.drawLine(pos, Offset(pos.dx, pos.dy - baseSize * 0.9), loopPaint);
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
