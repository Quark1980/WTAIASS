import 'package:flutter/material.dart';

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

    for (var obj in mapObjects) {
      // Genormaliseerde x/y (0..1) naar canvas
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

      // Tactical icon rendering
      final String icon = (obj['icon'] ?? '').toString();
      final String type = (obj['type'] ?? '').toString();
      final double baseSize = 12.0 / zoomScale;
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
        final String letter = (obj['icon'] as String?)?.substring(0, 1).toUpperCase();
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
        // Loop: lijn omhoog
        final loopPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = strokeW;
        canvas.drawLine(pos, Offset(pos.dx, pos.dy - baseSize / 2), loopPaint);
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

      // Richtingspijl indien dx/dy aanwezig
      if (obj['dx'] != null && obj['dy'] != null) {
        final dx = (obj['dx'] as num).toDouble();
        final dy = (obj['dy'] as num).toDouble();
        if (dx.abs() > 0.01 || dy.abs() > 0.01) {
          final endPos = pos + Offset(dx * 15, dy * 15);
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
