import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/map_object.dart';

class MapPainter extends CustomPainter {
  final List<MapObject> mapObjects;
  final Map<String, dynamic>? mapInfo;
  final Map<String, Offset>? previousPositions;

  MapPainter({
    required this.mapObjects,
    this.mapInfo,
    this.previousPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mapInfo == null) return;
    final double mapMaxX = (mapInfo!['mapMaxX'] as num?)?.toDouble() ?? 1.0;
    final double mapMaxY = (mapInfo!['mapMaxY'] as num?)?.toDouble() ?? 1.0;
    final dstRect = Offset.zero & size;

    for (final obj in mapObjects) {
      // Project coordinates
      final double ux = obj.x;
      final double uy = obj.y;
      double xRatio = (ux + mapMaxX / 2) / mapMaxX;
      double yRatio = 1.0 - ((uy + mapMaxY / 2) / mapMaxY);
      double drawX = dstRect.left + (xRatio * dstRect.width);
      double drawY = dstRect.top + (yRatio * dstRect.height);
      final Offset pos = Offset(drawX, drawY);

      // Determine color
      Color color = obj.isPlayer
          ? Colors.blue
          : (obj.color ?? Colors.grey);

      // Draw unit icon
      _drawUnitIcon(canvas, pos, obj.icon, color);

      // Draw direction arrow
      double? heading = obj.heading;
      if (heading == null && previousPositions != null && previousPositions![obj.id] != null) {
        final prev = previousPositions![obj.id]!;
        final dx = pos.dx - prev.dx;
        final dy = pos.dy - prev.dy;
        if (dx.abs() > 0.01 || dy.abs() > 0.01) {
          heading = (180 / 3.141592653589793) * (dy == 0 ? 0 : -atan2(dx, dy));
        }
      }
      if (heading != null) {
        _drawDirectionArrow(canvas, pos, heading, color);
      }
    }
  }


  void _drawUnitIcon(Canvas canvas, Offset pos, String icon, Color color) {
    const double size = 10.0;
    const double stroke = 1.2;
    final Paint fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    switch (icon) {
      case 'MediumTank':
        // Vierkant
        final rect = Rect.fromCenter(center: pos, width: size, height: size);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        break;
      case 'HeavyTank':
        // Vierkant + verticale lijn
        final rect = Rect.fromCenter(center: pos, width: size, height: size);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        canvas.drawLine(
          Offset(pos.dx, pos.dy - size / 2),
          Offset(pos.dx, pos.dy + size / 2),
          strokePaint..strokeWidth = stroke,
        );
        break;
      case 'LightTank':
        // Vierkant + diagonale lijn
        final rect = Rect.fromCenter(center: pos, width: size, height: size);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        canvas.drawLine(
          Offset(rect.left, rect.bottom),
          Offset(rect.right, rect.top),
          strokePaint..strokeWidth = stroke,
        );
        break;
      case 'TankDestroyer':
        // Omgekeerde driehoek
        final path = Path();
        path.moveTo(pos.dx - size / 2, pos.dy - size / 2);
        path.lineTo(pos.dx + size / 2, pos.dy - size / 2);
        path.lineTo(pos.dx, pos.dy + size / 2);
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
      case 'SPAA':
        // Cirkel + 2 antennes
        canvas.drawCircle(pos, size * 0.5, fillPaint);
        canvas.drawCircle(pos, size * 0.5, strokePaint);
        for (final dx in [-1.0, 1.0]) {
          canvas.drawLine(
            pos + Offset(dx * size * 0.3, -size * 0.5),
            pos + Offset(dx * size * 0.3, -size * 0.9),
            strokePaint,
          );
        }
        break;
      case 'Fighter':
        // V-vorm
        final path = Path();
        path.moveTo(pos.dx, pos.dy - size / 2);
        path.lineTo(pos.dx - size / 2, pos.dy + size / 2);
        path.lineTo(pos.dx + size / 2, pos.dy + size / 2);
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
      case 'Bomber':
        // Brede T-vorm
        final double w = size * 1.2;
        final double h = size * 0.5;
        final rect = Rect.fromCenter(center: pos, width: w, height: h);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        canvas.drawLine(
          Offset(rect.left, pos.dy),
          Offset(rect.right, pos.dy),
          strokePaint..strokeWidth = stroke,
        );
        break;
      case 'Player':
        // Romp (pijl) + Koepel (cirkel) + Loop (lijn)
        final double hullLen = size * 0.7;
        final double hullWidth = size * 0.3;
        final double turretRadius = size * 0.3;
        final double angle = -90.0; // standaard omhoog
        final double rad = angle * 3.141592653589793 / 180.0;
        final Offset tip = pos + Offset(hullLen * 0.5 * cos(rad), hullLen * 0.5 * sin(rad));
        final Offset baseL = pos + Offset(-hullLen * 0.5 * cos(rad) - hullWidth * sin(rad), -hullLen * 0.5 * sin(rad) + hullWidth * cos(rad));
        final Offset baseR = pos + Offset(-hullLen * 0.5 * cos(rad) + hullWidth * sin(rad), -hullLen * 0.5 * sin(rad) - hullWidth * cos(rad));
        final path = Path();
        path.moveTo(tip.dx, tip.dy);
        path.lineTo(baseL.dx, baseL.dy);
        path.lineTo(baseR.dx, baseR.dy);
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        // Koepel
        canvas.drawCircle(pos, turretRadius, fillPaint);
        canvas.drawCircle(pos, turretRadius, strokePaint);
        // Loop
        canvas.drawLine(pos, pos + Offset(0, -size * 0.7), strokePaint..strokeWidth = stroke);
        break;
      case 'capture_zone':
        // Cirkel met letter
        canvas.drawCircle(pos, size * 0.6, fillPaint);
        canvas.drawCircle(pos, size * 0.6, strokePaint);
        // Letter (optioneel, afhankelijk van data)
        break;
      default:
        // fallback: bolletje
        canvas.drawCircle(pos, size * 0.5, fillPaint);
        canvas.drawCircle(pos, size * 0.5, strokePaint);
    }
  }

  void _drawDirectionArrow(Canvas canvas, Offset pos, double heading, Color color) {
    // Richtingspijl tekenen vanaf het midden van het bolletje
    const double arrowLen = 18.0;
    const double arrowWidth = 4.0;
    final double rad = (heading - 90) * 3.141592653589793 / 180.0;
    final Offset tip = pos + Offset(arrowLen * cos(rad), arrowLen * sin(rad));
    final Offset left = pos + Offset(arrowWidth * cos(rad + 2.5), arrowWidth * sin(rad + 2.5));
    final Offset right = pos + Offset(arrowWidth * cos(rad - 2.5), arrowWidth * sin(rad - 2.5));
    final Paint arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(pos, tip, arrowPaint);
    // Arrowhead
    canvas.drawLine(tip, left, arrowPaint);
    canvas.drawLine(tip, right, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
