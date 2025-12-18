import '/classes/classes.dart';
import '/helpers/create_trip_helpers.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/tiles/maneuver_tile.dart';
import '/services/web_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '/classes/route.dart' as mt;
import 'package:audioplayers/audioplayers.dart';
import '/helpers/edit_helpers.dart';
import 'dart:developer' as developer;
import 'package:universal_io/universal_io.dart';

/// DirectionTile sits at the top of the screen and shows the turn-by-turn information
/// it uses the DirectionsDescriptor class to prepare the raw maneuvers data for display
/// and for text-to-sound translation which it does through the speechPrompt() method

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
  /*
    void setFirstManeuver() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      __directionTileState?.updateRoute();
    } catch (e) {
      debugPrint('error with directionTile controller: ${e.toString()}');
    }
  }
  */
}

class DirectionTile extends StatefulWidget {
  final List<mt.Route> routes;
  final List<Maneuver> maneuvers;
  final Function(int) currentIndex;
  final Function(int, int, int)? onTap;
  final LatLng currentPosition;
  final DirectionTileController controller;
  final String driveId;

  const DirectionTile({
    super.key,
    required this.routes,
    required this.maneuvers,
    required this.currentIndex,
    this.onTap,
    required this.currentPosition,
    required this.controller,
    required this.driveId,
  });

  @override
  State<DirectionTile> createState() => _DirectionTileState();
}

class _DirectionTileState extends State<DirectionTile> {
  // String _roadFrom = '';
  // String _roadTo = '';
  int _sweepAngle = 0;
  int _nextManeuverIndex = 0;
  double _metersToManeuver = 99999999;
  int _routeIndex = 0;
  int _pointIndex = 0;
  double _metersToRoute = 99999999;
  LatLng _lastLatLng = LatLng(0, 0);
  int _lastManeuver = 0;
  int _errorCount = 0;
  int _error = 0;
  late Future<List<String>> mp3s;
  late DirectionDescriptors _descriptors;
  // late String _driveId;

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    _descriptors = DirectionDescriptors(
        maneuvers: widget.maneuvers,
        driveId: widget.driveId,
        routes: widget.routes);
    //   _driveId = widget.driveId.isEmpty ? 'unpublised' : widget.driveId;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> prompts = updatePosition();
    if (_nextManeuverIndex >= 0) {
      if (widget.maneuvers[_nextManeuverIndex].type.contains('roundabout')) {
        _sweepAngle = getRoundaboutAngle(
            maneuvers: widget.maneuvers,
            index: _nextManeuverIndex,
            routes: widget.routes);
      }
    }
    return Material(
        color: _error == 0
            ? Colors.white.withAlpha(200)
            : Colors.red.withAlpha(200),
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
                            index: [1, 2].contains(_error)
                                ? -1
                                : [3, 4].contains(_error)
                                    ? -2
                                    : _nextManeuverIndex,
                            angle: _sweepAngle),
                      ),
                    ),
                    Expanded(
                      flex: 20,
                      child: Text(
                        prompts['heading'] ?? '',
                        style: titleStyle(
                            context: context,
                            size: 2,
                            color: _error == 0 ? Colors.black : Colors.white),
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
                            prompts['subheading'] ?? '',
                            style: textStyle(
                              context: context,
                              size: 3,
                              color: _error == 0 ? Colors.black : Colors.white,
                            ),
                          )),
                      const Expanded(flex: 3, child: SizedBox(width: 1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void reRoute() async {
    if (_nextManeuverIndex == -2 && widget.onTap != null) {
      await speechPrompt(
          text: 'calculating a new root', fileName: 'reroute.mp3');
      widget.onTap!(_lastManeuver, _routeIndex, _pointIndex);

      /// _nextManeuver has to be defined by the rerouting in currentTripItem.changeRoutes() it
      /// has to be fed back using the controller;
      //   setState(() => _nextManeuverIndex = _lastManeuver);
    }
  }

  void updateRoute() {
    getClosestManeuver();
    getClosestPoint();
  }

  Map<String, dynamic> updatePosition() {
    Map<String, dynamic> prompts = {};
    if (widget.currentPosition != _lastLatLng) {
      if (_nextManeuverIndex > 1) {
        if (_metersToRoute > 20) {
          if (++_errorCount > 3) {
            developer.log('errorCount > 3 left route ', name: '_maneuver');
            _error = 1;
          }
        } else {
          _errorCount = 0;
        }
      }

      /// Handling leaving the route -
      /// Warn once when deviation detected
      /// If deviated
      ///   Warn once when deviation > n meters
      ///   Check if route is re-joined
      ///   If rejoined find the next possible waypoint - want to try and avoid router - internet availability
      ///     Prompt to next waypoint
      ///

      developer.log(
          'DirectionTile.updatePosition().nextManeuverIndex: $_nextManeuverIndex',
          name: '_maneuver');

      prompts = _descriptors.getDirections(
          maneuverIndex: _nextManeuverIndex,
          metersToManeuver: _metersToManeuver,
          position: widget.currentPosition,
          error: _error);

      String speech = prompts['speech']['sound'] ?? '';
      String file = prompts['speech']['file'] ?? '';

      if (speech.isNotEmpty) {
        speechPrompt(text: speech, fileName: file);
      }

      if (_error > 0) {
        getClosestPoint(route: _routeIndex, point: _pointIndex, full: false);

        /// More than 1Km away then offer re-routing
        if (_metersToRoute > 1000) {
          _error = _error < 3 ? 3 : 4;
        } else {
          /// Close to route - assume rejoined
          _error = 2;
          getClosestManeuver();
          _nextManeuverIndex = CurrentTripItem().nextManeuverIndex;
        }
        developer.log(
            'DirectionTile _metersToRoute - distance from route: $_metersToRoute',
            name: '_maneuver');
        return prompts;
      }

      double distance = 9999999999;

      /// Look for very first maneuver - the closest to the current position

      if (_lastLatLng == LatLng(0, 0)) {
        getClosestManeuver();
        _nextManeuverIndex = CurrentTripItem().nextManeuverIndex;
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
            //  developer.log(
            //      '${_descriptors.getDirections(maneuverIndex: _nextManeuverIndex + 1, metersToManeuver: _metersToManeuver)[0]} - maneuverIndex: $_nextManeuverIndex',
            //      name: '_prompt');
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
    return prompts;
  }

  Future<String> speechPrompt(
      {required String text,
      required String fileName,
      bool delete = false}) async {
    String soundDir = '${Setup().appDocumentDirectory}/sounds';
    if (!Directory(soundDir).existsSync()) {
      Directory(soundDir).createSync();
    }

    String filePath = '$soundDir/$fileName';
    if (fileName.isNotEmpty) {
      if (!File(filePath).existsSync()) {
        filePath = await getSpeech(text: text, fileName: fileName);
        developer.log('speech file $filePath not found', name: '_sound');
      } else {
        developer.log('speech file $filePath found', name: '_sound');
      }
      DeviceFileSource source = DeviceFileSource(filePath);
      try {
        final player = AudioPlayer();
        await player.play(source);
        if (delete) {
          File(filePath).delete();
        }
      } catch (e) {
        debugPrint('Error : ${e.toString()}');
      }
    }
    return filePath;
  }

  getClosestPoint({int route = 0, int point = 0, bool full = true}) {
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
          full = distance < 10 ? false : full;
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
