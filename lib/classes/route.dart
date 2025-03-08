import 'dart:math';
// import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A polyline with an id
class Route extends Polyline {
  final int id;
  final int key;
  final int driveKey;
  final LatLng markerPosition;
  final int pointOfInterestIndex;
  String pointOfInterestUri;
  double rating;
  List<Offset> offsets = [];

  // Color colour;
  // Color borderColour;
  @override
  Color color;
  @override
  Color borderColor;

  Route({
    required super.points,
    super.strokeWidth = 1.0,
    // this.colour = const Color(0xFF00FF00),
    this.color = const Color(0xFF00FF00),
    super.borderStrokeWidth = 0.0,
    // this.borderColour = const Color(0xFFFFFF00),
    this.borderColor = const Color(0xFFFFFF00),
    super.gradientColors,
    super.colorsStop,
    super.isDotted = false,
    this.id = -1,
    this.key = -1,
    this.driveKey = -1,
    this.markerPosition = const LatLng(0, 0),
    this.pointOfInterestIndex = -1,
    this.rating = 1,
    this.pointOfInterestUri = '',
  }); // : super(borderColor: borderColour, color: colour);

  void setColour({required Color colour}) {
    color = colour;
  }
}

/// Class RouteAtCenter
/// This is a really neat way of allowing control of a stateless widget.
/// The problem faced was that I wanted to know when the polyline is under the
/// target. It needs the use of the MapCamera.of(context) to convert LatLngs to
/// screen positions etc, and that can only be used within a Map object or descendant
/// ie PolyLineLayer. Being stateless PolyLineLayer can't use a controller as there is no state to
/// extend. The solution was to create an object - RouteAtCenter that is passed to the
/// extended PolyLineLayer - RouteLayer through its constructor. RouteAtCenter is instatiated
/// outside the RouteLayer. RouteLayer sets both RouteAtCenter's context and the PolyLines that
/// have been modified by adding the offsets from the camera origin. RouteAtCenter's
/// getPolyLineNearestCenter() method can then be called externally to calculate the polyline's
/// positions.

class RouteAtCenter {
  BuildContext? _context;
  List<Route> _routes = [];
  int _routeIndex = -1;
  int _pointIndex = -1;

  LatLng _pointOnRoute = const LatLng(0, 0);

  LatLng get pointOnRoute => _pointOnRoute;

  int get routeIndex => _routeIndex;
  int get pointIndex => _pointIndex;

  set context(BuildContext context) {
    _context = context;
  }

  set routes(List<Route> routes) {
    _routes = routes;
  }

  int getPolyLineNearestCenter(
      {int pointerDistanceTolerance = 15, int pointIndex = -1}) {
    double maxValue = 9999999.0;
    int idx = -1;

    if (_context != null) {
      final mapState = MapCamera.of(_context!);

      // var tap = mapState.pixelOrigin.toOffset();
      final mapController = MapController.of(_context!);

      Offset center = mapState.project(mapController.camera.center).toOffset();
      center = (center * mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
          mapState.pixelOrigin.toOffset();
      //   debugPrint('getPolyLineNearestCente() context is NOT null');
      if (_routes.isNotEmpty) {
        //  debugPrint('getPolyLineNearestCente() _routes.isNotEmpty');
        Route currentPolyline = _routes[0];
        for (int i = 0; i < _routes.length; i++) {
          currentPolyline = _routes[i];
          for (var j = 1; j < currentPolyline.offsets.length; j++) {
            // We consider the points point1, point2 and tap points in a triangle
            var point1 = currentPolyline.offsets[j - 1];
            var point2 = currentPolyline.offsets[j];
            // To determine if target is in between two points, we
            // calculate the length from the tapped point to the line
            // created by point1, point2. If this distance is shorter
            // than the specified threshold, we have detected a tap
            // between two points.
            //
            // We start by calculating the length of all the sides using pythagoras.
            var a = _distanceBetween(point1, point2);
            var b = _distanceBetween(point1, center);
            var c = _distanceBetween(point2, center);

            // To find the height when we only know the lengths of the sides, we can use Heron's formula to get the Area.
            var semiPerimeter = (a + b + c) / 2.0;
            var triangleArea = sqrt(semiPerimeter *
                (semiPerimeter - a) *
                (semiPerimeter - b) *
                (semiPerimeter - c));

            // We can then finally calculate the length from the tapped point onto the line created by point1, point2.
            // Area of triangles is half the area of a rectangle
            // area = 1/2 base * height -> height = (2 * area) / base

            var height = (2 * triangleArea) / a;

            // We're not there yet - We need to satisfy the edge case
            // where the perpendicular line from the tapped point onto
            // the line created by point1, point2 (called point D) is
            // outside of the segment point1, point2. We need
            // to check if the length from D to the original segment
            // (point1, point2) is less than the threshold.

            var hypotenus = max(b, c);
            var newTriangleBase =
                sqrt((hypotenus * hypotenus) - (height * height));
            var lengthDToOriginalSegment = newTriangleBase - a;

            if (height < pointerDistanceTolerance &&
                lengthDToOriginalSegment < pointerDistanceTolerance) {
              var minimum = min(height, lengthDToOriginalSegment);
              if (minimum < maxValue) {
                idx = i;
                _routeIndex = i;
                _pointIndex = j;

                _pointOnRoute = currentPolyline.points[j];
                maxValue = minimum;
              }
            }
          }
        }

        if (idx > -1) {
          //    debugPrint(
          //        'Polyline index: $idx  points length: ${currentPolyline.points.length} ${currentPolyline.offsets.length}');
        }
      }

      // debugPrint('Polyline index $idx');
    } else {
      //  debugPrint('getPolyLineNearestCente() context is null');
    }
    return idx;
  }

  double _distanceBetween(Offset point1, Offset point2) {
    var distancex = (point1.dx - point2.dx).abs();
    var distancey = (point1.dy - point2.dy).abs();

    var distance = sqrt((distancex * distancex) + (distancey * distancey));

    return distance;
  }
}

class RouteLayer extends PolylineLayer {
  /// The list of [Route] which could be tapped
  @override
  final List<Route> polylines;

  /// The tolerated distance between pointer and user tap to trigger the [onTap] callback
  final double pointerDistanceTolerance;

  /// The callback to call when a polyline was hit by the tap
  final void Function(List<Route>, TapUpDetails tapPosition)? onTap;

  /// The optional callback to call when no polyline was hit by the tap
  final void Function(TapUpDetails tapPosition)? onMiss;

  ///
  final RouteAtCenter? routeAtCenter;

  const RouteLayer({
    this.polylines = const [],
    this.onTap,
    this.onMiss,
    this.pointerDistanceTolerance = 15,
    super.polylineCulling = false,
    this.routeAtCenter,
    super.key,
  }) : super(polylines: polylines); // Have to have a this.polylines

  @override
  Widget build(BuildContext context) {
    final mapCamera = MapCamera.of(context);

    return _build(
      context,
      Size(mapCamera.size.x, mapCamera.size.y),
      polylineCulling
          ? polylines
              .where(
                  (p) => p.boundingBox.isOverlapping(mapCamera.visibleBounds))
              .toList()
          : polylines,
    );
  }

  Widget _build(BuildContext context, Size size, List<Route> lines) {
    final mapState = MapCamera.of(context);

    //  double rotation = mapState.rotation;
    // debugPrint('Camera rotation: $rotation');

    for (Route polyline in lines) {
      polyline.offsets.clear();
      var i = 0;

      for (var point in polyline.points) {
        var pos = mapState.project(point);
        pos = (pos * mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
            mapState.pixelOrigin.toDoublePoint();

        // final mapCenter = crs.latLngToPoint(center, zoom);
        // pos = mapState.rotatePoint(mapState.center   mapCenter, point)
        //  polyline.offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
        if (i > 0 && i < polyline.points.length) {
          polyline.offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
        }
        i++;
      }
    }

    if (routeAtCenter != null) {
      routeAtCenter?.context = context;
      routeAtCenter?.routes = polylines;
    }

    // _handlePolylineTap(noTap, onTap, onMiss);

    return GestureDetector(
      /* 
      onDoubleTap: () {
        // For some strange reason i have to add this callback for the onDoubleTapDown callback to be called.
      },
      onDoubleTapDown: (TapDownDetails details) {
        _zoomMap(details, context);
      },
   */

      behavior: HitTestBehavior.translucent,
      child: AbsorbPointer(
          child: MobileLayerTransformer(
        child: Stack(
          children: [
            CustomPaint(
              painter: PolylinePainter(lines, mapState),
              size: size,
            ),
          ],
        ),
      )),
      onTapUp: (TapUpDetails details) {
        _forwardCallToMapOptions(details, context);
        _handlePolylineTap(details, onTap, onMiss);
      },
      /*
      onPanUpdate: (DragUpdateDetails details) {
        _handlePolylineTap(details, onTap, onMiss);
      },
      */
    );
  }

  void _handlePolylineTap(
      TapUpDetails details, Function? onTap, Function? onMiss) {
    // We might hit close to multiple polylines. We will therefore keep a reference to these in this map.
    Map<double, List<Route>> candidates = {};
    // var mapState = MapCamera.of(context);
    // Calculating taps in between points on the polyline. We
    // iterate over all the segments in the polyline to find any
    // matches with the tapped point within the
    // pointerDistanceTolerance.
    for (Route currentPolyline in polylines) {
      for (var j = 0; j < currentPolyline.offsets.length - 1; j++) {
        // We consider the points point1, point2 and tap points in a triangle
        var point1 = currentPolyline.offsets[j];
        var point2 = currentPolyline.offsets[j + 1];
        var tap = details.localPosition;
        // To determine if we have tapped in between two points, we
        // calculate the length from the tapped point to the line
        // created by point1, point2. If this distance is shorter
        // than the specified threshold, we have detected a tap
        // between two points.
        //
        // We start by calculating the length of all the sides using pythagoras.
        var a = _distance(point1, point2);
        var b = _distance(point1, tap);
        var c = _distance(point2, tap);

        // To find the height when we only know the lengths of the sides, we can use Herons formula to get the Area.
        var semiPerimeter = (a + b + c) / 2.0;
        var triangleArea = sqrt(semiPerimeter *
            (semiPerimeter - a) *
            (semiPerimeter - b) *
            (semiPerimeter - c));

        // We can then finally calculate the length from the tapped point onto the line created by point1, point2.
        // Area of triangles is half the area of a rectangle
        // area = 1/2 base * height -> height = (2 * area) / base
        var height = (2 * triangleArea) / a;

        // We're not there yet - We need to satisfy the edge case
        // where the perpendicular line from the tapped point onto
        // the line created by point1, point2 (called point D) is
        // outside of the segment point1, point2. We need
        // to check if the length from D to the original segment
        // (point1, point2) is less than the threshold.

        var hypotenus = max(b, c);
        var newTriangleBase = sqrt((hypotenus * hypotenus) - (height * height));
        var lengthDToOriginalSegment = newTriangleBase - a;

        if (height < pointerDistanceTolerance &&
            lengthDToOriginalSegment < pointerDistanceTolerance) {
          var minimum = min(height, lengthDToOriginalSegment);
          candidates[minimum] ??= <Route>[];
          candidates[minimum]!.add(currentPolyline);
        }
      }
    }

    if (candidates.isEmpty) return onMiss?.call(details);

    // We look up in the map of distances to the tap, and choose the shortest one.
    var closestToTapKey = candidates.keys.reduce(min);
    onTap!(candidates[closestToTapKey], details);
  }

  void _forwardCallToMapOptions(TapUpDetails details, BuildContext context) {
    final latlng = _offsetToLatLng(details.localPosition, context.size!.width,
        context.size!.height, context);

    final mapOptions = MapOptions.of(context);

    final tapPosition =
        TapPosition(details.globalPosition, details.localPosition);
    // Forward the onTap call to map.options so that we won't break onTap
    mapOptions.onTap?.call(tapPosition, latlng);
  }

  double _distance(Offset point1, Offset point2) {
    var distancex = (point1.dx - point2.dx).abs();
    var distancey = (point1.dy - point2.dy).abs();

    var distance = sqrt((distancex * distancex) + (distancey * distancey));

    return distance;
  }

  void _zoomMap(TapDownDetails details, BuildContext context) {
    final mapCamera = MapCamera.of(context);
    final mapController = MapController.of(context);

    var newCenter = _offsetToLatLng(details.localPosition, context.size!.width,
        context.size!.height, context);
    mapController.move(newCenter, mapCamera.zoom + 0.5);
  }

  LatLng _offsetToLatLng(
      Offset offset, double width, double height, BuildContext context) {
    final mapCamera = MapCamera.of(context);
    var localPoint = Point(offset.dx, offset.dy);
    var localPointCenterDistance =
        Point((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    var mapCenter = mapCamera.project(mapCamera.center);
    var point = mapCenter - localPointCenterDistance;
    return mapCamera.unproject(point);
  }
}
