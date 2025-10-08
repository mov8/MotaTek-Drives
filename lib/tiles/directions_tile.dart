import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/tiles/maneuver_tile.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:drives/classes/route.dart' as mt;
// import 'dart:developer' as developer;

class DirectionTileController {
  _DirectionTileState? __directionTileState;
  void _addState(_DirectionTileState directionTileState) {
    __directionTileState = directionTileState;
  }

  bool get isAttached => __directionTileState != null;

  void updateRoute() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      __directionTileState?.updateRoute();
    } catch (e) {
      debugPrint('error with directionTile controller: ${e.toString()}');
    }
  }
}

class DirectionTile extends StatefulWidget {
  final List<mt.Route> routes;
  final List<Maneuver> maneuvers;
  final Function(int) currentIndex;
  final Function(int, int, int)? onTap;
  final LatLng currentPosition;
  final DirectionTileController controller;

  const DirectionTile({
    super.key,
    required this.routes,
    required this.maneuvers,
    required this.currentIndex,
    this.onTap,
    required this.currentPosition,
    required this.controller,
  });

  @override
  State<DirectionTile> createState() => _DirectionTileState();
}

class _DirectionTileState extends State<DirectionTile> {
  String _roadFrom = '';
  String _roadTo = '';
  int _sweepAngle = 0;
  int _nextManeuverIndex = 0;
  double _metersToManeuver = 99999999;
  int _routeIndex = 0;
  int _pointIndex = 0;
  double _metersToRoute = 99999999;
  LatLng _lastLatLng = LatLng(0, 0);
  int _lastManeuver = 0;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
  }

  @override
  Widget build(BuildContext context) {
    updatePosition();
    if (_nextManeuverIndex >= 0) {
      if (widget.maneuvers[_nextManeuverIndex].type.contains('roundabout')) {
        _sweepAngle = widget.maneuvers[_nextManeuverIndex].bearingAfter -
            widget.maneuvers[_nextManeuverIndex].bearingBefore;
        _sweepAngle = _sweepAngle < -90 ? 360 + _sweepAngle : _sweepAngle;
        _sweepAngle = _sweepAngle > 180 ? 180 : _sweepAngle;
      }
    }
    return Material(
        child: InkWell(
      onTap: () => reRoute(),
      child: SizedBox(
        height: 130,
        width: MediaQuery.of(context).size.width, // - 100,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsetsGeometry.fromLTRB(0, 10, 0, 0),
                    child: getNavIcon(
                        maneuvers: widget.maneuvers,
                        index: _nextManeuverIndex,
                        angle: _sweepAngle),
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Text(
                    getDirections(maneuverIndex: _nextManeuverIndex)[0],
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(flex: 3, child: SizedBox(width: 1)),
              ]),
              Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox(width: 1)),
                  Expanded(
                      flex: 20,
                      child: Text(
                          getDirections(maneuverIndex: _nextManeuverIndex)[1],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.normal))),
                  const Expanded(flex: 3, child: SizedBox(width: 1)),
                ],
              ),
              Row(
                children: [
                  Text(
                      'Distance from route ${_metersToRoute.toStringAsFixed(0)}m route: $_routeIndex  point: $_pointIndex'),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }

  void reRoute() {
    if (_nextManeuverIndex == -2 && widget.onTap != null) {
      widget.onTap!(_lastManeuver, _routeIndex, _pointIndex);
      setState(() => _nextManeuverIndex = _lastManeuver);
    }
  }

  void updateRoute() {
    getClosestManeuver();
    getClosestPoint();
  }

  List<String> getDirections({int maneuverIndex = 0}) {
    List<String> directions = ['', ''];

    /// When the _nextManeuverIndex changes it's then pointing to the next waypoint
    /// so the next waypoint's road_from is our next destination
    ///
    Maneuver? maneuver;
    if (maneuverIndex >= 0) {
      maneuver = widget.maneuvers[maneuverIndex];
    }
    if (maneuver != null) {
      if (_roadTo.isEmpty) {
        _roadTo = maneuver.roadTo;
      }
      if (_roadFrom.isEmpty) {
        _roadFrom = maneuver.roadFrom;
      }
      if (_roadTo != maneuver.roadFrom) {
        _roadFrom = _roadTo;
        _roadTo = maneuver.roadFrom;
      }
    }
    if (maneuverIndex == -2) {
      directions[0] = 'tap here to re-route';
      directions[1] = 're-join the route at the next waypoint';
    } else if (maneuverIndex == -1) {
      directions[0] = 'you have left the route - turn around';
      directions[1] = 'turn around and rejoin the route';
    } else if (maneuverIndex == 0 || maneuver!.modifier == 'depart') {
      String direction =
          maneuver!.modifier.isNotEmpty ? ' (${maneuver.modifier})' : '';
      directions[0] = 'depart from ${maneuver!.roadFrom}$direction';
      directions[1] = 'start the drive towards ${maneuver.roadTo}';
    } else if (maneuver.modifier.contains('arrive') ||
        maneuver.type.contains('arrive')) {
      directions[0] = 'arrived at destination';
      directions[1] = 'arrived at ${maneuver.roadFrom}';
    } else {
      if (maneuver.type.contains('roundabout')) {
        if (maneuver.type.contains('exit')) {
          directions[0] = 'Exit the roundabout';
          directions[1] =
              'Take the  ${exitName(widget.maneuvers[_nextManeuverIndex].exit)}';
        } else {
          directions[0] =
              'in ${modifyDistance(_metersToManeuver)} take the ${exitName(widget.maneuvers[_nextManeuverIndex].exit)}';
          directions[1] =
              'at roundabout ${exitDescriptor(sweepAngle: _sweepAngle)}';
        }
      } else if (maneuver.modifier.contains('right') ||
          maneuver.modifier.contains('left')) {
        if (_metersToManeuver > 0) {
          directions[0] =
              'in ${modifyDistance(_metersToManeuver)} turn ${maneuver.modifier}';
        } else {
          directions[0] = 'turn ${maneuver!.modifier}';
        }
        directions[1] =
            "turn ${maneuver.modifier} ${maneuver.roadTo.isNotEmpty ? ' into ${maneuver.roadFrom}' : ''}";
      }
    }
    if (maneuverIndex >= 0) {
      if (maneuver!.modifier.contains('straight') ||
          maneuver.modifier.isEmpty) {
        if (_metersToManeuver > 0) {
          directions[0] = 'continue for ${modifyDistance(_metersToManeuver)}';
          directions[1] = 'continue on $_roadFrom towards $_roadTo';
        } else {
          directions[0] = 'continue along $_roadFrom';
          directions[1] = 'continue on $_roadFrom towards $_roadTo';
        }
      }
    }

    if (directions[0].isEmpty) {
      debugPrint('Emty data');
    }
    return directions;
  }

  void updatePosition() {
    if (widget.currentPosition != _lastLatLng) {
      if (_nextManeuverIndex > 1) {
        if (_metersToRoute > 10) {
          if (++_errorCount > 3) {
            _nextManeuverIndex = -1;
          }
        } else {
          _errorCount = 0;
        }
      }

      if (_nextManeuverIndex < 0) {
        getClosestPoint(route: _routeIndex, point: _pointIndex, full: false);
        if (_metersToRoute > 1000) {
          _nextManeuverIndex = -2;
        }
        return;
      }

      double distance = 9999999999;

      /// Look for very first maneuver - the closest to the current position
      if (_lastLatLng == LatLng(0, 0)) {
        getClosestManeuver();
        getClosestPoint();
      } else {
        /// Check distance away from next maneuver
        distance = Geolocator.distanceBetween(
            widget.currentPosition.latitude,
            widget.currentPosition.longitude,
            widget.maneuvers[_nextManeuverIndex].location.latitude,
            widget.maneuvers[_nextManeuverIndex].location.longitude);

        /// Ensure that the target maneuver only gets incremented once we have passed the current target
        /// Allows a margin of error of 3 meters
        if (distance - _metersToManeuver > 3) {
          if (_nextManeuverIndex < widget.maneuvers.length - 1) {
            /// Can't just use _nextManeuverIndex - 1  because may leave route before
            /// passing _nextManeuverIndex
            _lastManeuver = _nextManeuverIndex;
            _nextManeuverIndex = _nextManeuverIndex + 1;
            distance = Geolocator.distanceBetween(
                widget.currentPosition.latitude,
                widget.currentPosition.longitude,
                widget.maneuvers[_nextManeuverIndex].location.latitude,
                widget.maneuvers[_nextManeuverIndex].location.longitude);
          }
        }
        getClosestPoint(route: _routeIndex, point: _pointIndex, full: false);
        _metersToManeuver = distance;
      }
    }
    setState(() => _lastLatLng = widget.currentPosition);
  }

  void getClosestPoint({int route = 0, int point = 0, bool full = true}) {
    _metersToRoute = 999999999;
    int further = 0;
    for (int i = route; i < widget.routes.length; i++) {
      for (int j = point; j < widget.routes[i].points.length; j++) {
        double distance = Geolocator.distanceBetween(
            widget.currentPosition.latitude,
            widget.currentPosition.longitude,
            widget.routes[i].points[j].latitude,
            widget.routes[i].points[j].longitude);
        if (distance < _metersToRoute) {
          _routeIndex = i;
          _pointIndex = j;
          _metersToRoute = distance;
          further = 0;
        } else {
          if (further++ > 10 && !full) {
            break;
          }
        }
      }
    }
    _metersToRoute = _metersToRoute == 999999999 ? 0 : _metersToRoute;
  }

  void getClosestManeuver() {
    double distance = 999999999;
    for (int i = 0; i < widget.maneuvers.length; i++) {
      distance = Geolocator.distanceBetween(
          widget.currentPosition.latitude,
          widget.currentPosition.longitude,
          widget.maneuvers[i].location.latitude,
          widget.maneuvers[i].location.longitude);
      if (distance < _metersToManeuver) {
        _nextManeuverIndex = i;
        _metersToManeuver = distance;
      }
    }
  }

  String exitName(int exit) {
    switch (exit) {
      case 1:
        return 'first exit';
      case 2:
        return 'second exit';
      case 3:
        return 'third exit';
      case 4:
        return 'fourth exit';
      case 5:
        return 'fifth exit';
      case 6:
        return 'sixth exit';
      default:
        return 'exit';
    }
  }

  String exitDescriptor({required int sweepAngle}) {
    String direction = _sweepAngle < 0 ? 'left' : 'right';
    int testAngle = _sweepAngle.abs();
    String adverb = '';
    if (testAngle < 10) {
      return 'straight on';
    } else if (testAngle < 45) {
      adverb = 'slightly ';
    } else if (testAngle < 135) {
      adverb = 'sharp ';
    } else {
      adverb = 'go right around';
      direction = '';
    }
    return '$adverb$direction';
  }
}
