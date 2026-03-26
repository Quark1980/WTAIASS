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
      final double x = (obj['x'] ?? 0).toDouble();
      final double y = (obj['y'] ?? 0).toDouble();
      final int colorVal = obj['color'] ?? 0;
      final String icon = (obj['icon'] ?? 'none').toString();

      Color teamColor = Colors.grey;
      if (colorVal == 1) teamColor = Colors.blue;
      if (colorVal == 2) teamColor = Colors.red;
      if (icon == 'Player') teamColor = Colors.yellow;

      fillPaint.color = teamColor;

      final double drawX = (x + 32768) / 65536 * size.width;
      final double drawY = (32768 - y) / 65536 * size.height;

      final Offset pos = Offset(drawX, drawY);

      canvas.drawCircle(pos, 7.5, fillPaint);
      canvas.drawCircle(pos, 7.5, strokePaint);

      if (obj['dx'] != null && obj['dy'] != null) {
        final dx = (obj['dx'] as num).toDouble();
        final dy = (obj['dy'] as num).toDouble();
        if (dx.abs() > 0.01 || dy.abs() > 0.01) {
          final endPos = pos + Offset(dx * 22, dy * 22);
          final arrowPaint = Paint()
            ..color = teamColor
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke;
          canvas.drawLine(pos, endPos, arrowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
