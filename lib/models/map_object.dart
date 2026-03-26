import 'package:flutter/material.dart';

class MapObject {
  final String id;
  final double x;
  final double y;
  final String icon;
  final String type;
  final Color? color;
  final double? heading;
  final bool isPlayer;

  MapObject({
    required this.id,
    required this.x,
    required this.y,
    required this.icon,
    required this.type,
    this.color,
    this.heading,
    this.isPlayer = false,
  });
}
