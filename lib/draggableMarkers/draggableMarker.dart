// import 'dart:math';

// import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DraggableMarker {
  LatLng point;

  final Key? key;

  // final DraggableMarkerWidgetBuilder builder;
  final Size size;
  final Offset offset;
  final Offset? dragOffset;
  final bool useLongPress;

  final void Function(DragStartDetails deatils, LatLng latLng)? onDragStart;

  final void Function(DragUpdateDetails details, LatLng latLng)? onDragUpdate;

  final void Function(DragEndDetails details, LatLng latLng)? onDragEnd;

  final void Function(LongPressStartDetails details, LatLng latLng)?
      onLongDragStart;

  final void Function(LongPressMoveUpdateDetails details, LatLng latLng)?
      onLongDragUpdate;

  final void Function(LongPressEndDetails details, LatLng latLng)?
      onLongDragEnd;

  final void Function(LatLng latLng)? onTap;

  final void Function(LatLng latLng)? onLongPress;

  final bool scrollMapNearEdge;

  final double scrollNearEdgeRatio;

  final double scrollNearEdgeSpeed;

  final bool rotateMarker;

  final Alignment? alignment;

  DraggableMarker({
    required this.point,
    this.key,
    //  required this.builder,
    required this.size,
    this.offset = const Offset(0, 0),
    this.dragOffset,
    this.useLongPress = false,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onLongDragStart,
    this.onLongDragUpdate,
    this.onLongDragEnd,
    this.onTap,
    this.onLongPress,
    this.scrollMapNearEdge = false,
    this.scrollNearEdgeRatio = 1.5,
    this.scrollNearEdgeSpeed = 1.0,
    this.rotateMarker = true,
    this.alignment,
  });
/*
  bool inMapBounds({
    required final MapCamera mapCamera,
    required final Alignment markerWidgetAlignment,


  }){
    var pxPoint = mapCamera.poject(point);

    final left = 0.5 * size.width * ((alignment ?? markerWidgetAlignment).x + 1);
    final top = 0.5 * size.height * ((alignment ?? markerWidgetAlignment).y + 1);
    final right = size.width - left;
    final bottom = size.height - top;

    final bounds = ui.Bounds(
      Point(pxPoint.x + left, pxPoint.y - bottom),
      Point(pxPoint.x - right, pxPoint.y + top),
    );

  }
  */
}
