import 'package:flutter/material.dart';

import 'map_grid_geometry.dart';

class MapViewportGridLabelsOverlay extends StatelessWidget {
  final Map<String, dynamic>? mapInfo;
  final TransformationController transformationController;

  const MapViewportGridLabelsOverlay({
    super.key,
    required this.mapInfo,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: transformationController,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ViewportGridLabelsPainter(
              mapInfo: mapInfo,
              transformationController: transformationController,
            ),
          );
        },
      ),
    );
  }
}

class _ViewportGridLabelsPainter extends CustomPainter {
  final Map<String, dynamic>? mapInfo;
  final TransformationController transformationController;

  _ViewportGridLabelsPainter({
    required this.mapInfo,
    required this.transformationController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridGeometry = buildMapGridGeometry(mapInfo, size);
    if (gridGeometry == null) return;

    final effectiveMatrix = Matrix4.copy(transformationController.value)
      ..multiply(transformationController.value);
    final inverseMatrix = Matrix4.inverted(effectiveMatrix);

    final visibleTopLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
    final visibleBottomRight = MatrixUtils.transformPoint(
      inverseMatrix,
      Offset(size.width, size.height),
    );
    final visibleLeft = visibleTopLeft.dx < visibleBottomRight.dx ? visibleTopLeft.dx : visibleBottomRight.dx;
    final visibleRight = visibleTopLeft.dx > visibleBottomRight.dx ? visibleTopLeft.dx : visibleBottomRight.dx;
    final visibleTop = visibleTopLeft.dy < visibleBottomRight.dy ? visibleTopLeft.dy : visibleBottomRight.dy;
    final visibleBottom = visibleTopLeft.dy > visibleBottomRight.dy ? visibleTopLeft.dy : visibleBottomRight.dy;

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.9),
      fontSize: 13,
      fontWeight: FontWeight.bold,
      shadows: const [Shadow(blurRadius: 3, color: Colors.black, offset: Offset(0.8, 0.8))],
    );

    final topStripPaint = Paint()..color = Colors.black.withOpacity(0.18);
    final sideStripPaint = Paint()..color = Colors.black.withOpacity(0.18);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 24), topStripPaint);
    canvas.drawRect(Rect.fromLTWH(0, 0, 24, size.height), sideStripPaint);

    for (int col = 0; col < gridGeometry.columnCount; col++) {
      final centerX = gridGeometry.gridRect.left + ((col + 0.5) * gridGeometry.cellWidth);
      if (centerX < visibleLeft - gridGeometry.cellWidth || centerX > visibleRight + gridGeometry.cellWidth) {
        continue;
      }

      final screenCenter = MatrixUtils.transformPoint(
        effectiveMatrix,
        Offset(centerX, gridGeometry.gridRect.top),
      );
      if (screenCenter.dx < -gridGeometry.cellWidth || screenCenter.dx > size.width + gridGeometry.cellWidth) {
        continue;
      }

      final label = (col + 1).toString();
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final dx = (screenCenter.dx - (tp.width / 2)).clamp(24.0, size.width - tp.width - 4.0);
      tp.paint(canvas, Offset(dx, 4));
    }

    for (int row = 0; row < gridGeometry.rowCount; row++) {
      final centerY = gridGeometry.gridRect.top + ((row + 0.5) * gridGeometry.cellHeight);
      if (centerY < visibleTop - gridGeometry.cellHeight || centerY > visibleBottom + gridGeometry.cellHeight) {
        continue;
      }

      final screenCenter = MatrixUtils.transformPoint(
        effectiveMatrix,
        Offset(gridGeometry.gridRect.left, centerY),
      );
      if (screenCenter.dy < -gridGeometry.cellHeight || screenCenter.dy > size.height + gridGeometry.cellHeight) {
        continue;
      }

      final label = String.fromCharCode(65 + row);
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final dy = (screenCenter.dy - (tp.height / 2)).clamp(24.0, size.height - tp.height - 4.0);
      tp.paint(canvas, Offset(4, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _ViewportGridLabelsPainter oldDelegate) {
    return oldDelegate.mapInfo != mapInfo ||
        oldDelegate.transformationController != transformationController ||
        oldDelegate.transformationController.value != transformationController.value;
  }
}