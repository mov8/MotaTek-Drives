import 'dart:core';
// import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
//import 'package:flutter_map/src/layer/general/mobile_layer_transformer.dart';
//import 'package:flutter_map/src/map/camera/camera.dart';
//import 'package:latlong2/latlong.dart';

class CacheablePolyline extends Polyline {
  int key;
  int driveKey;
  CacheablePolyline({
    required super.points,
    super.strokeWidth = 1.0,
    super.color = const Color(0xFF00FF00),
    super.borderStrokeWidth = 0.0,
    super.borderColor = const Color(0xFFFFFF00),
    super.gradientColors,
    super.colorsStop,
    super.isDotted = false,
    super.strokeCap = StrokeCap.round,
    super.strokeJoin = StrokeJoin.round,
    super.useStrokeWidthInMeter = false,
    this.key = -1,
    this.driveKey = -1,
  });
}
