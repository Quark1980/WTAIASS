import 'package:flutter/material.dart';

class MapGridGeometry {
  final Rect gridRect;
  final double cellWidth;
  final double cellHeight;
  final int columnCount;
  final int rowCount;
  final double cellSizeX;
  final double cellSizeY;

  const MapGridGeometry({
    required this.gridRect,
    required this.cellWidth,
    required this.cellHeight,
    required this.columnCount,
    required this.rowCount,
    required this.cellSizeX,
    required this.cellSizeY,
  });

  Rect? rectForCellRef(String cellRef) {
    if (cellRef.length < 2) return null;

    final rowLabel = cellRef.substring(0, 1).toUpperCase();
    final colNumber = int.tryParse(cellRef.substring(1));
    if (colNumber == null) return null;

    final rowIndex = rowLabel.codeUnitAt(0) - 65;
    final colIndex = colNumber - 1;
    if (rowIndex < 0 || rowIndex >= rowCount || colIndex < 0 || colIndex >= columnCount) {
      return null;
    }

    return Rect.fromLTWH(
      gridRect.left + (colIndex * cellWidth),
      gridRect.top + (rowIndex * cellHeight),
      cellWidth,
      cellHeight,
    );
  }

  Offset columnLabelOffset(int colIndex, double labelWidth) {
    return Offset(
      gridRect.left + (colIndex * cellWidth) + (cellWidth / 2) - (labelWidth / 2),
      gridRect.top + 2,
    );
  }

  Offset rowLabelOffset(int rowIndex, double labelHeight) {
    return Offset(
      2,
      gridRect.top + (rowIndex * cellHeight) + (cellHeight / 2) - (labelHeight / 2),
    );
  }
}

MapGridGeometry? buildMapGridGeometry(Map<String, dynamic>? mapInfo, Size size) {
  if (mapInfo == null ||
      mapInfo['map_max'] == null ||
      mapInfo['map_min'] == null ||
      mapInfo['grid_steps'] == null) {
    return null;
  }

  final mapMax = mapInfo['map_max'];
  final mapMin = mapInfo['map_min'];
  final gridSteps = mapInfo['grid_steps'];
  if (mapMax is! List || mapMin is! List || gridSteps is! List) {
    return null;
  }
  if (mapMax.length != 2 || mapMin.length != 2 || gridSteps.length != 2) {
    return null;
  }

  final minX = _toDouble(mapMin[0]);
  final minY = _toDouble(mapMin[1]);
  final maxX = _toDouble(mapMax[0]);
  final maxY = _toDouble(mapMax[1]);
  final cellSizeX = _toDouble(gridSteps[0]);
  final cellSizeY = _toDouble(gridSteps[1]);
  if (minX == null ||
      minY == null ||
      maxX == null ||
      maxY == null ||
      cellSizeX == null ||
      cellSizeY == null ||
      cellSizeX <= 0 ||
      cellSizeY <= 0) {
    return null;
  }

  final rangeX = maxX - minX;
  final rangeY = maxY - minY;
  if (rangeX <= 0 || rangeY <= 0) {
    return null;
  }

  final gridZero = mapInfo['grid_zero'];
  final originWorldX = (gridZero is List && gridZero.length == 2)
      ? (_toDouble(gridZero[0]) ?? minX)
      : minX;
  final originWorldY = (gridZero is List && gridZero.length == 2)
      ? (_toDouble(gridZero[1]) ?? maxY)
      : maxY;

  final originXRatio = ((originWorldX - minX) / rangeX).clamp(0.0, 1.0);
  final originYRatio = ((maxY - originWorldY) / rangeY).clamp(0.0, 1.0);
  final cellWidth = size.width * (cellSizeX / rangeX);
  final cellHeight = size.height * (cellSizeY / rangeY);
  if (cellWidth <= 0 || cellHeight <= 0) {
    return null;
  }

  final columnCount = ((maxX - originWorldX) / cellSizeX).floor();
  final rowCount = ((originWorldY - minY) / cellSizeY).floor();
  if (columnCount <= 0 || rowCount <= 0) {
    return null;
  }

  final gridRect = Rect.fromLTWH(
    size.width * originXRatio,
    size.height * originYRatio,
    cellWidth * columnCount,
    cellHeight * rowCount,
  );

  return MapGridGeometry(
    gridRect: gridRect,
    cellWidth: cellWidth,
    cellHeight: cellHeight,
    columnCount: columnCount,
    rowCount: rowCount,
    cellSizeX: cellSizeX,
    cellSizeY: cellSizeY,
  );
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}