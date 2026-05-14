import 'dart:math';
import '/classes/classes.dart';
import '/helpers/create_trip_helpers.dart';
import 'package:flutter/material.dart';
import '/models/other_models.dart';
// import '/classes/other_classes.dart';
import '/tiles/maneuver_tile.dart';
import '/services/web_helper.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';
// import '/classes/route.dart' as mt;
import 'package:audioplayers/audioplayers.dart';
import '/helpers/edit_helpers.dart';
import 'dart:developer' as developer;
import 'package:universal_io/universal_io.dart';

/// DirectionTile sits at the top of the screen and shows the turn-by-turn information
/// it uses the DirectionsDescriptor class to prepare the raw maneuvers data for display
/// and for text-to-sound translation which it does through the speechPrompt() method

class DirectionTileController {
  _DirectionTileState? _directionTileState;
  void _addState(_DirectionTileState directionTileState) {
    _directionTileState = directionTileState;
  }

  bool get isAttached => _directionTileState != null;

  void updateRoute() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _directionTileState?.updateRoute();
    } catch (e) {
      debugPrint('error with directionTile controller: ${e.toString()}');
    }
  }

  void updatePosition() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _directionTileState?.updatePosition();
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
  final Function(int)? currentIndex;
  final Function(int, int, int)? onTap;
  final DirectionTileController controller;
  final CurrentTripItem? tripItem;

  const DirectionTile({
    super.key,
    this.tripItem,
    this.currentIndex,
    this.onTap,
    required this.controller,
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
  // List<double> _lastLatLng = [0, 0];
  Point _lastLatLng = Point(0, 0);
  int _lastManeuver = 0;
  int _errorCount = 0;
  int _error = 0;
  late Future<List<String>> mp3s;
  late DirectionDescriptors _descriptors;
  late CurrentTripItem tripItem;

  Map<String, dynamic> _prompts = {'heading': '', 'subheading': ''};
  // late String _driveId;

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    tripItem = widget.tripItem ?? CurrentTripItem();
    _descriptors = DirectionDescriptors(
        maneuvers: tripItem.maneuvers,
        driveId: tripItem.driveUri,
        routes: tripItem.routes);
  }

  @override
  Widget build(BuildContext context) {
    // Map<String, dynamic> prompts = updatePrompts();
    try {
      if (_nextManeuverIndex >= 0) {
        if (tripItem.maneuvers[_nextManeuverIndex].type
            .contains('roundabout')) {
          _sweepAngle = getRoundaboutAngle(
            maneuvers: tripItem.maneuvers,
            index: _nextManeuverIndex,
            routes: tripItem.routes,
          );
        }
      }
    } catch (e) {
      developer.log('Error building DirectionsTile: ${e.toString()}',
          name: '_error_');
    }

    return Material(
      color:
          _error == 0 ? Colors.white.withAlpha(200) : Colors.red.withAlpha(200),
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
                          maneuvers: tripItem.maneuvers,
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
                      _prompts['heading'] ?? '',
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
                        _prompts['subheading'] ?? '',
                        style: textStyle(
                          context: context,
                          size: 3,
                          color: _error == 0 ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const Expanded(flex: 3, child: SizedBox(width: 1)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  void updatePosition() {
    try {
      if (tripItem.tripValues.position != _lastLatLng) {
        if (_nextManeuverIndex > 1) {
          if (_metersToRoute > 20) {
            if (++_errorCount > 3) {
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
        /// https://www.ashfordstpeters.nhs.uk/urology-contacts
        /// 01932 72 6450 Suzanne prostate coordinator      01932 72 6930 MRI

        _prompts = _descriptors.getDirections(
            maneuverIndex: _nextManeuverIndex,
            metersToManeuver: _metersToManeuver,
            position: tripItem.tripValues.position,
            error: _error);

        String speech = _prompts['speech']['sound'] ?? '';
        String file = _prompts['speech']['file'] ?? '';

        if (speech.isNotEmpty) {
          speechPrompt(text: speech, fileName: file);
        }

        if (_error > 0) {
          getClosestPoint(route: _routeIndex, point: _pointIndex, full: false);

          /// More than 1Km away then offer re-routing
          if (_metersToRoute > 1000) {
            _error = _error < 3 ? 3 : 4;
            _nextManeuverIndex = -2;
          } else {
            /// Close to route - assume rejoined
            _error = 2;
            getClosestManeuver();
            _nextManeuverIndex = CurrentTripItem().nextManeuverIndex;
          }
        }

        double distance = 9999999999;

        /// Look for very first maneuver - the closest to the current position

        if (_lastLatLng == Point(0, 0)) {
          getClosestManeuver();
          _nextManeuverIndex = CurrentTripItem().nextManeuverIndex;
          getClosestPoint();
        } else {
          /// Check distance away from next maneuver

          distance = Geolocator.distanceBetween(
              tripItem.tripValues.position.y.toDouble(),
              tripItem.tripValues.position.x.toDouble(),
              tripItem.maneuvers[_nextManeuverIndex].point.y.toDouble(),
              tripItem.maneuvers[_nextManeuverIndex].point.x.toDouble());

          /// Ensure that the target maneuver only gets incremented once we have passed the current target
          /// Allows a margin of error of 3 meters

          if (distance - _metersToManeuver > 3) {
            if (_nextManeuverIndex < tripItem.maneuvers.length - 1) {
              _lastManeuver = _nextManeuverIndex;
              _nextManeuverIndex = _nextManeuverIndex + 1;
              distance = Geolocator.distanceBetween(
                  tripItem.tripValues.position.y.toDouble(),
                  tripItem.tripValues.position.x.toDouble(),
                  tripItem.maneuvers[_nextManeuverIndex].point.y.toDouble(),
                  tripItem.maneuvers[_nextManeuverIndex].point.x.toDouble());
            }
          }
          getClosestPoint(route: _routeIndex, point: _pointIndex, full: false);
          _metersToManeuver = distance;
        }
        setState(() => _lastLatLng = tripItem.tripValues.position);
      }
    } catch (e) {
      developer.log('Error updating directionsTile.position ${e.toString}',
          name: '_error_');
    }
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
    for (int i = route; i < tripItem.routes.length; i++) {
      for (int j = point; j < tripItem.routes[i].lines.length; j++) {
        double distance = Geolocator.distanceBetween(
            tripItem.tripValues.position.y.toDouble(),
            tripItem.tripValues.position.x.toDouble(),
            tripItem.routes[i].lines[j][1],
            tripItem.routes[i].lines[j][0]);
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
    for (int i = 0; i < tripItem.maneuvers.length; i++) {
      distance = Geolocator.distanceBetween(
          tripItem.tripValues.position.y.toDouble(),
          tripItem.tripValues.position.x.toDouble(),
          tripItem.maneuvers[i].point.y.toDouble(),
          tripItem.maneuvers[i].point.x.toDouble());
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
