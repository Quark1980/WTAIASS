import 'package:flutter/material.dart';

class MapPainter extends CustomPainter {
  final List<dynamic> mapObjects;
  final Map<String, dynamic>? mapInfo;

  MapPainter({required this.mapObjects, this.mapInfo});

  @override
  void paint(Canvas canvas, Size size) {
    if (mapObjects.isEmpty) return;

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
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

      // Capture point: vierkant met letter
      if ((obj['type'] == 'capture_zone' || obj['type'] == 'zone') && obj['icon'] is String && (obj['icon'] as String).isNotEmpty) {
        const double sizeSq = 12;
        final rect = Rect.fromCenter(center: pos, width: sizeSq, height: sizeSq);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        // Letter in het midden
        final String letter = (obj['icon'] as String).substring(0, 1).toUpperCase();
        final textSpan = TextSpan(
          text: letter,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
        );
        final tp = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      } else {
        // Normale unit: klein bolletje
        canvas.drawCircle(pos, 5, fillPaint);
        canvas.drawCircle(pos, 5, strokePaint);
      }

      // Richtingspijl indien dx/dy aanwezig
      if (obj['dx'] != null && obj['dy'] != null) {
        final dx = (obj['dx'] as num).toDouble();
        final dy = (obj['dy'] as num).toDouble();
        if (dx.abs() > 0.01 || dy.abs() > 0.01) {
          final endPos = pos + Offset(dx * 15, dy * 15);
          final arrowPaint = Paint()
            ..color = teamColor
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;
          canvas.drawLine(pos, endPos, arrowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
