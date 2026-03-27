
import '../../logic/tracker_service.dart';
import '../../models/tracked_unit_position.dart';


  final ui.Image? mapImage;
  final Map<String, dynamic>? mapInfo;
  final Map<String, dynamic>? mapObj;
  final Matrix4 transform;
  final Map<String, List<Map<String, dynamic>>>? liveTrails;
  final Map<String, Map<String, dynamic>>? deadUnits;
  final double? playerHeading;
  final double? playerTurretAngle;
  final UnitTrackingService? tracker;

  MapPainter({
    this.mapImage,
    this.mapInfo,
    this.mapObj,
    required this.transform,
    this.liveTrails,
    this.deadUnits,
    this.playerHeading,
    this.playerTurretAngle,
    this.tracker,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Local helpers at the top ---
    /// Project War Thunder map coordinates (ux, uy) to screen coordinates (pixel-perfect, y-flip)
    Offset _projectToMap(Offset pos, Rect dstRect) {
      // Requires mapInfo with mapMaxX and mapMaxY
      if (mapInfo == null) return Offset.zero;
      final double ux = pos.dx;
      final double uy = pos.dy;
      final double mapMaxX = (mapInfo!['mapMaxX'] as num?)?.toDouble() ?? 1.0;
      final double mapMaxY = (mapInfo!['mapMaxY'] as num?)?.toDouble() ?? 1.0;
      double xRatio = (ux + mapMaxX / 2) / mapMaxX;
      double yRatio = 1.0 - ((uy + mapMaxY / 2) / mapMaxY); // Y-flip!
      double drawX = dstRect.left + (xRatio * dstRect.width);
      double drawY = dstRect.top + (yRatio * dstRect.height);
      return Offset(drawX, drawY);
    }
    void _drawSkull(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
      final double r = 4.5 * effectiveScale;
      final double stroke = 1.1 * effectiveScale;
      canvas.drawCircle(pos, r, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke);
      canvas.drawLine(pos + Offset(-r * 0.7, -r * 0.7), pos + Offset(r * 0.7, r * 0.7), Paint()
        ..color = color
        ..strokeWidth = stroke);
      canvas.drawLine(pos + Offset(-r * 0.7, r * 0.7), pos + Offset(r * 0.7, -r * 0.7), Paint()
        ..color = color
        ..strokeWidth = stroke);
    }
    void _drawMediumTank(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
      final double size = 5.0 * effectiveScale;
      final double stroke = 1.0 * effectiveScale;
      final rect = Rect.fromCenter(center: pos, width: size, height: size);
      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawRect(rect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = stroke);
    }
    void _drawHeavyTank(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
      final double size = 5.0 * effectiveScale;
      final double stroke = 1.0 * effectiveScale;
      final rect = Rect.fromCenter(center: pos, width: size, height: size);
      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawRect(rect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = stroke);
      canvas.drawLine(
        Offset(pos.dx, pos.dy - size / 2),
        Offset(pos.dx, pos.dy + size / 2),
        Paint()..color = Colors.black..strokeWidth = stroke * 1.2,
      );
    }
    void _drawLightTank(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
      final double size = 5.0 * effectiveScale;
      final double stroke = 1.0 * effectiveScale;
      final rect = Rect.fromCenter(center: pos, width: size, height: size);
      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawRect(rect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = stroke);
      canvas.drawLine(
        Offset(rect.left, rect.bottom),
        Offset(rect.right, rect.top),
        Paint()..color = Colors.black..strokeWidth = stroke,
      );
    }
    void _drawTankDestroyer(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
      final double size = 5.0 * effectiveScale;
      final double stroke = 1.0 * effectiveScale;
      final path = Path();
      path.moveTo(pos.dx - size / 2, pos.dy - size / 2);
      path.lineTo(pos.dx + size / 2, pos.dy - size / 2);
      path.lineTo(pos.dx, pos.dy + size / 2);
      path.close();
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = stroke);
    }
    void _drawSPAA(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
      final double r = 3.5 * effectiveScale;
      final double stroke = 1.0 * effectiveScale;
      canvas.drawCircle(pos, r, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawCircle(pos, r, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = stroke);
      final double antLen = 4.5 * effectiveScale;
      for (final dx in [-1.0, 1.0]) {
        canvas.drawLine(
          pos + Offset(dx * r * 0.6, -r),
          pos + Offset(dx * r * 0.6, -r - antLen),
          Paint()..color = Colors.black..strokeWidth = stroke * 0.7,
        );
      }
    }
    void _drawFighter(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
      final double size = 6.0 * effectiveScale;
      final double stroke = 1.0 * effectiveScale;
      final path = Path();
      path.moveTo(pos.dx, pos.dy - size / 2);
      path.lineTo(pos.dx - size / 2, pos.dy + size / 2);
      path.lineTo(pos.dx + size / 2, pos.dy + size / 2);
      path.close();
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = stroke);
    }
    void _drawBomber(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
      final double w = 8.0 * effectiveScale;
      final double h = 3.0 * effectiveScale;
      final double stroke = 1.0 * effectiveScale;
      final rect = Rect.fromCenter(center: pos, width: w, height: h);
      canvas.drawLine(Offset(rect.left, pos.dy), Offset(rect.right, pos.dy), Paint()..color = color..strokeWidth = stroke * 1.2);
      canvas.drawLine(pos, Offset(pos.dx, pos.dy - h / 2), Paint()..color = color..strokeWidth = stroke);
      canvas.drawLine(Offset(rect.left, pos.dy), Offset(rect.right, pos.dy), Paint()..color = Colors.black..strokeWidth = stroke * 1.2);
      canvas.drawLine(pos, Offset(pos.dx, pos.dy - h / 2), Paint()..color = Colors.black..strokeWidth = stroke);
    }
    void _drawCaptureZone(Canvas canvas, Offset pos, String label, Color color, {double effectiveScale = 1.0}) {
      final double r = 6.0 * effectiveScale;
      final double stroke = 1.0 * effectiveScale;
      canvas.drawCircle(pos, r, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label.isNotEmpty ? label.substring(0, 1) : '',
          style: TextStyle(
            color: color,
            fontSize: 8.0 * effectiveScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
      canvas.drawCircle(pos, r, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = stroke * 0.7);
    }
    void _drawAirfield(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
      final double w = 10.0 * effectiveScale;
      final double h = 3.0 * effectiveScale;
      final double stroke = 1.0 * effectiveScale;
      final rect = Rect.fromCenter(center: pos, width: w, height: h);
      canvas.drawRect(rect, Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.fill);
      canvas.drawRect(rect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = stroke);
    }
    Color _parseHexColor(String hex) {
      String hexColor = hex.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    }
    void _drawTurret(Canvas canvas, Offset pos, double heading, double turretAngle, {double effectiveScale = 1.0}) {
      final double turretRadius = 3.5 * effectiveScale;
      final double strokeWidth = 0.7 * effectiveScale;
      canvas.drawCircle(pos, turretRadius, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth);
      final double loopLen = 8.0 * effectiveScale;
      final double angleRad = ((heading + turretAngle) - 90) * math.pi / 180.0;
      final Offset end = Offset(
        pos.dx + loopLen * math.cos(angleRad),
        pos.dy + loopLen * math.sin(angleRad),
      );
      canvas.drawLine(pos, end, Paint()
        ..color = Colors.white
        ..strokeWidth = strokeWidth * 1.2);
    }
    // --- End helpers ---
    final double zoomScale = transform.getMaxScaleOnAxis();
    canvas.save();
    canvas.transform(transform.storage);
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
    final imgW = mapImage!.width.toDouble();
    final imgH = mapImage!.height.toDouble();
    final scale = math.min(size.width / imgW, size.height / imgH);
    final displayW = imgW * scale;
    final displayH = imgH * scale;
    final mapOffsetDx = (size.width - displayW) / 2;
    final mapOffsetDy = (size.height - displayH) / 2;
    final dstRect = Rect.fromLTWH(mapOffsetDx, mapOffsetDy, displayW, displayH);
    canvas.drawImageRect(
      mapImage!,
      Rect.fromLTWH(0, 0, imgW, imgH),
      dstRect,
      Paint(),
    );
    if (mapObj == null) {
      canvas.restore();
      return;
    }
    final units = mapObj!['units'] as List<dynamic>? ?? [];
    // 4. Trails tekenen (tracker_service)
    if (tracker != null) {
      final trails = tracker!.getTrailsForAllUnits();
      for (final entry in trails.values) {
        final unit = entry.unit;
        final trail = entry.trail;
        if (trail.length < 2) continue;
        final path = Path();
        for (int i = 0; i < trail.length; i++) {
          final p = trail[i];
          final Offset pos = _projectToMap(p.position, dstRect);
          if (i == 0) {
            path.moveTo(pos.dx, pos.dy);
          } else {
            path.lineTo(pos.dx, pos.dy);
          }
        }
        final double effectiveScale = 1.0 / zoomScale;
        canvas.drawPath(
          path,
          Paint()
            ..color = unit.color.withOpacity(0.35)
            ..strokeWidth = 2.0 * effectiveScale
            ..style = PaintingStyle.stroke,
        );
      }
    }
    // 5. Death-skulls tekenen (fade-out)
    if (deadUnits != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final entry in deadUnits!.entries) {
        final data = entry.value;
        final Offset pos = _projectToMap(data['pos'], dstRect);
        final Color color = (data['color'] as Color?) ?? Colors.white;
        final int timestamp = data['timestamp'] as int? ?? 0;
        final double t = ((now - timestamp) / 4000.0).clamp(0.0, 1.0);
        final double alpha = 1.0 - t;
        if (alpha <= 0.01) continue;
        _drawSkull(canvas, pos, color.withOpacity(alpha), effectiveScale: 1.0 / zoomScale);
      }
    }
    // 6. Afstandstekst tonen bij units (behalve speler)
    Offset? playerPos;
    for (final unit in units) {
      final String type = unit['type']?.toString() ?? '';
      final String icon = unit['icon']?.toString() ?? '';
      if (type == 'steerable' || type == 'player' || icon == 'Player') {
        playerPos = _projectToMap(Offset((unit['x'] as num?)?.toDouble() ?? 0.0, (unit['y'] as num?)?.toDouble() ?? 0.0), dstRect);
        break;
      }
    }
    if (playerPos != null) {
      for (final unit in units) {
        final String type = unit['type']?.toString() ?? '';
        final String icon = unit['icon']?.toString() ?? '';
        if (type == 'steerable' || type == 'player' || icon == 'Player') continue;
        final Offset pos = _projectToMap(Offset((unit['x'] as num?)?.toDouble() ?? 0.0, (unit['y'] as num?)?.toDouble() ?? 0.0), dstRect);
        final double dist = (playerPos - pos).distance;
        final double effectiveScale = 1.0 / zoomScale;
        final String distText = dist.toStringAsFixed(0) + 'm';
        final textPainter = TextPainter(
          text: TextSpan(
            text: distText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.5 * effectiveScale,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(0.5, 0.5))],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, pos + Offset(7 * effectiveScale, -7 * effectiveScale));
      }
    }
    // 7. Draw all units
    for (final unit in units) {
      final double xRatio = (unit['x'] as num?)?.toDouble() ?? 0.0;
      final double yRatio = (unit['y'] as num?)?.toDouble() ?? 0.0;
      final String type = unit['type'] as String? ?? '';
      final String icon = unit['icon']?.toString() ?? '';
      final String side = unit['side'] as String? ?? '';
      final double drawX = dstRect.left + (xRatio * dstRect.width);
      final double drawY = dstRect.top + (yRatio * dstRect.height);
      final angleRaw = unit['angle'];
      final double? angle = (angleRaw is num) ? angleRaw.toDouble() : null;
      Color color;
      if (type == 'steerable' || type == 'player' || icon == 'Player') {
        color = Colors.blue;
      } else if (unit['color'] != null && unit['color'] is String && (unit['color'] as String).startsWith('#')) {
        color = _parseHexColor(unit['color'] as String);
      } else if (side == 'friend') {
        color = Colors.green;
      } else {
        color = Colors.red;
      }
      final Offset pos = Offset(drawX, drawY);
      final double effectiveScale = 1.0 / zoomScale;
      if (type == 'steerable' || type == 'player' || icon == 'Player') {
        final double hullAngle = playerHeading ?? angle ?? 0.0;
        _drawArrow(canvas, pos, hullAngle, color, effectiveScale: effectiveScale);
        if (playerTurretAngle != null && playerHeading != null) {
          _drawTurret(canvas, pos, playerHeading!, playerTurretAngle!, effectiveScale: effectiveScale);
        }
      } else if (icon == 'MediumTank') {
        _drawMediumTank(canvas, pos, color, effectiveScale: effectiveScale);
      } else if (icon == 'HeavyTank') {
        _drawHeavyTank(canvas, pos, color, effectiveScale: effectiveScale);
      } else if (icon == 'LightTank') {
        _drawLightTank(canvas, pos, color, effectiveScale: effectiveScale);
      } else if (icon == 'TankDestroyer') {
        _drawTankDestroyer(canvas, pos, color, effectiveScale: effectiveScale);
      } else if (icon == 'SPAA') {
        _drawSPAA(canvas, pos, color, effectiveScale: effectiveScale);
      } else if (icon == 'Fighter') {
        _drawFighter(canvas, pos, color, effectiveScale: effectiveScale);
      } else if (icon == 'Bomber') {
        _drawBomber(canvas, pos, color, effectiveScale: effectiveScale);
      } else if (icon == 'capture_zone') {
        _drawCaptureZone(canvas, pos, unit['name']?.toString() ?? '', color, effectiveScale: effectiveScale);
      } else if (icon == 'none') {
        if (type == 'airfield') {
          _drawAirfield(canvas, pos, color, effectiveScale: effectiveScale);
        } else {
          _drawUnitCircle(canvas, pos, color, effectiveScale: effectiveScale);
        }
      } else {
        _drawUnitCircle(canvas, pos, color, effectiveScale: effectiveScale);
      }
    }
    canvas.restore();
  }


  void _drawUnitCircle(Canvas canvas, Offset pos, Color color, {double effectiveScale = 1.0}) {
    final double size = 4.5 * effectiveScale;
    final double strokeWidth = 0.8 * effectiveScale;
    // Zwarte rand
    canvas.drawCircle(pos, size, Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth);
    // Gekleurde vulling
    canvas.drawCircle(pos, size, Paint()
      ..color = color
      ..style = PaintingStyle.fill);
  }

  void _drawArrow(Canvas canvas, Offset pos, double direction, Color color, {double effectiveScale = 1.0}) {
    final double arrowLength = 5.0 * effectiveScale;
    final double arrowWidth = 2.0 * effectiveScale;
    final double strokeWidth = 0.8 * effectiveScale;
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
    // Zwarte rand
    canvas.drawPath(path, Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth);
    // Gekleurde vulling
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.fill);
  }


  @override
  bool shouldRepaint(MapPainter oldDelegate) => true;
}