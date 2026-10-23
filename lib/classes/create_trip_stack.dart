import 'dart:async';
import 'dart:core';
import 'dart:developer' as developer;
import 'dart:math';
import '/constants.dart';
import '/classes/classes.dart' hide Position;
import 'package:flutter/foundation.dart';
import '/screens/screens.dart';
import '/services/services.dart' hide getPosition;
import '/models/models.dart';
import '/helpers/helpers.dart';
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '/routes/routes.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:maplibre_gl/maplibre_gl.dart'; // hide LatLng;

class CreateTripStackController {
  _CreateTripStackState? _createTripStackState;
  void _addState(_CreateTripStackState createTripStackState) {
    _createTripStackState = createTripStackState;
  }

  bool get isAttached => _createTripStackState != null;

  void refresh() {
    if (isAttached) {
      _createTripStackState?.refresh();
    }
  }

  void changeRoute() {
    if (isAttached) {
      _createTripStackState?.changeRoute();
    }
  }

  void warn(int index) {
    if (isAttached) {
      _createTripStackState?.warn(index);
    }
  }
}

class CreateTripStack extends StatefulWidget {
  final CreateTripStackController? controller;
  const CreateTripStack({super.key, this.controller});
  @override
  State<CreateTripStack> createState() => _CreateTripStackState();
}

class _CreateTripStackState extends State<CreateTripStack>
    with TickerProviderStateMixin {
  late Future<bool> _dataLoaded;
  final DirectionTileController _directionTileController =
      DirectionTileController();

  StreamSubscription<Position>? _positionStream;
  late final FollowRoute _debugRoute;
  CurrentPosition _userPosition = CurrentPosition();
  final List<Follower> _following = [];
  int _directionsIndex = 0;
  final bool _debugging = false; //true; //false; //true;

  int positionUpdates = 0;

  final MessageBox _messageBox =
      MessageBox(controller: MapService().messageBoxController);

  StreamSocket streamSocket = StreamSocket();
  sio.Socket socket = sio.io(urlBase, <String, dynamic>{
    // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
    'transports': ['websocket'], // Specify WebSocket transport
    'autoConnect': false, // Prevent auto-connection
  });

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
    _dataLoaded = dataFromDatabase();
    if (CurrentTripItem().routes.isNotEmpty) {
      CurrentTripItem().mapUpdates = MapUpdates.updateAll;
    } else {
      CurrentTripItem().clearAll(newTripState: TripState.none);
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void refresh() {
    setState(() => {});
  }

  void warn(int index) async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 15));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _dataLoaded,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasError) {
          developer.log('CreateTrip().build() snapshot.hasError',
              name: 'error');
        } else if (snapshot.hasData) {
          try {
            Widget body = _getPortraitBody();
            return body;
          } catch (e) {
            developer.log('CreateTrip().build() error:${e.toString()}',
                name: 'error');
          }
        } else {
          return const SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _getPortraitBody() {
    Future<bool>;
    developer.log(
        'TripState: ${TripState.editing} CurrentTripItem().tripValues.showTarget: ${CurrentTripItem().tripValues.showTarget} CurrentTripItem().tripValues.showProgress: ${CurrentTripItem().tripValues.showProgress}',
        name: 'error');
    return Stack(
      children: [
        //   if (MapService().controller != null)
        Positioned(
          left: 0,
          right: 0,
          top: 110,
          child: Align(
            // <-- Only do editing in "Explore" mode
            alignment: Alignment.topRight,
            child: FutureBuilder(
              future: MapService().mapFuture, // <-- From Completer
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Map not ready',
                      style: (TextStyle(fontSize: 22, color: Colors.red)),
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          ),
        ),

        if (NavigationService().page == 2) ...[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _messageBox,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              // <-- Only do editing in "Explore" mode
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 35),
                child: Padding(
                  padding:
                      EdgeInsetsGeometry.fromLTRB(kIsWeb ? 30 : 0, 0, 0, 0),
                  child: CreateTripChips(
                    createTripController: MapService().createTripController,
                    onUpdate: (_) {},
                  ),
                ),
              ),
            ),
          ),
          if ((CurrentTripItem().tripState == TripState.editing ||
                  CurrentTripItem().tripValues.showTarget) &&
              !CurrentTripItem().tripValues.showProgress) ...[
            CustomPaint(
              painter: TargetPainter(
                  top: MapService()
                      .mapMiddle
                      .y
                      .toDouble(), //mapMiddle().y.toDouble(),
                  left: MapService()
                      .mapMiddle
                      .x
                      .toDouble(), //mapMiddle().x.toDouble(),
                  color: CurrentTripItem().isGoodRoad
                      // The user's great road colour, like the route
                      ? colourList[Setup().goodRouteColour]
                      : Colors.black),
            )
          ],
          // The position marker is a map layer - MapService().showLocation()
          // Speed while moving when tracking or following - PositionService
          // sets it, and the stack is rebuilt on each position
          if ([TripState.tracking, TripState.following]
                  .contains(CurrentTripItem().tripState) &&
              CurrentTripItem().tripValues.speed > 0) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 0, 150),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.red,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.black,
                    child: Text(CurrentTripItem().tripValues.speed.toString(),
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
          if (NavigationService().page == 1) ...[
            CustomPaint(
              painter: HighlightPainter(
                boundary: MapService().mapSize(),
                proportion: 0.6,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ],

        /// getDirections shows the turn-by-turn navigation details
        getDirections(_directionsIndex),
        if (kIsWeb) ...[]
      ],
    );
  }

  Point chipPosition() {
    try {
      return Point(MapService().controller!.cameraPosition!.target.latitude,
          MapService().controller!.cameraPosition!.target.longitude);
    } catch (e) {
      return Point(0, 0);
    }
  }

  Future<bool> dataFromDatabase() async {
    // Setup is loaded from Hive at startup (main.dart initialise())
    return true;
  }

  /// callback for BottomDrawer object. Is fired when the BottomDrawer.AnimatedContainer has finished its animation.
  /// Value of open is true if the drawer is currently open.
  /// This callback is used to update the map when the user has completed adding data like the trip heading, points of
  /// interest etc.
  Future<void> onOpened(bool open) async {
    if (!open) {
      CurrentTripItem().tripActions = TripActions.none;
      if (MapService().controller != null &&
          CurrentTripItem().mapUpdates != MapUpdates.none) {
        MapService().controller!.animateCamera(
              CameraUpdate.zoomBy(0.000001),
            );
      }
      if ([TripState.manualStart, TripState.goodRoadStart]
          .contains(CurrentTripItem().tripState)) {
        CurrentTripItem().tripState = CurrentTripItem().tripValues.isEditing
            ? TripState.editing
            : TripState.manual;
      }

      if (MapService().sideDrawerController!.content ==
              BottomDrawerItems.settings &&
          MapService().sideDrawerController!.changed) {
        Setup().save(); // <-- Writes the setup changes to api
      }
    }
    setState(() {});
  }

  void update(bool complete) {
    if (complete) {
      MapService().bottomDrawerController!.close();
    }
  }

  Align getDirections(int index) {
    if (CurrentTripItem().tripState == TripState.following &&
        CurrentTripItem().maneuvers.isNotEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: DirectionTile(
          controller: _directionTileController,
          onTap: (index, routeIndex, pointIndex) => changeRoute(
              lastManeuverIndex: index,
              routeIndex: routeIndex,
              pointIndex: pointIndex),
        ),
      );
    } else {
      return const Align(
        alignment: Alignment.topLeft,
      );
    }
  }

  void updatePosition(Position position) async {
    _userPosition = CurrentPosition(position: position);
    CurrentTripItem().tripValues.position = _userPosition.point;
    position.speed * metersPerSecondToMPH; //* 3.6 / 8 * 5; // M/S -> MPH

    LatLng pos = _userPosition.latLng;

    if (_debugging) {
      handleDebugStream(position, _debugRoute, _following);
    }

    if (CurrentTripItem().tripState == TripState.tracking &&
        CurrentTripItem().tripValues.lastPosition.y != 0) {
      double distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          CurrentTripItem().tripValues.lastPosition.y.toDouble(),
          CurrentTripItem().tripValues.lastPosition.x.toDouble());
      if (distance > 5) {
        try {
          if (distance > 1000) {
            CurrentTripItem().routes.last.waypoints.add(Waypoint(
                value: CurrentTripItem().routes.last.waypoints.length + 1));
            if (CurrentTripItem().isGoodRoad) {
              CurrentTripItem().goodRoads.last.waypoints.add(Waypoint(
                  value:
                      CurrentTripItem().goodRoads.last.waypoints.length + 1));
            }
          }
          CurrentTripItem()
              .routes
              .last
              .lines
              .add([pos.longitude, pos.latitude]);

          await MapService().controller!.setGeoJsonSource('route-data', {
            "type": "FeatureCollection",
            "features": routesToGeoJson(),
          });

          if (CurrentTripItem().isGoodRoad) {
            CurrentTripItem()
                .goodRoads
                .last
                .lines
                .add([pos.longitude, pos.latitude]);
            await MapService().controller!.setGeoJsonSource('good-road-data', {
              "type": "FeatureCollection",
              "features": goodRoadsToGeoJson(),
            });
          }
        } catch (e) {
          developer.log('Error updatePosition() error: ${e.toString()}',
              name: 'error');
        }
        CurrentTripItem().tripValues.lastPosition =
            Point(pos.longitude, pos.latitude);
      }
    }

    CurrentTripItem().tripValues.heading = position.heading;
    CurrentTripItem().mapUpdates = MapUpdates.followers;

    MapService().controller!.animateCamera(CameraUpdate.newLatLng(pos));

    setState(() => getDirectionsIndex());
    if (Setup().rotateMap) {
      MapService()
          .controller!
          .animateCamera(CameraUpdate.bearingTo(position.heading));
    }
  }

  int getDirectionsIndex() {
    int idx = -1;
    double distance = 99999;
    double temp;
    if (CurrentTripItem().tripState == TripState.following) {
      for (int i = _directionsIndex;
          i < CurrentTripItem().maneuvers.length;
          i++) {
        temp = Geolocator.distanceBetween(
            CurrentTripItem().tripValues.position.y.toDouble(),
            CurrentTripItem().tripValues.position.x.toDouble(),
            CurrentTripItem().maneuvers[i].point.y.toDouble(),
            CurrentTripItem().maneuvers[i].point.x.toDouble());
        if (temp < distance) {
          distance = temp;
          idx = i;
        }
      }
    }
    return idx;
  }

  void updateUserPosition(CurrentPosition position) async {
    if (_userPosition.point.y > 0 &&
        position.point.y > 0 &&
        CurrentTripItem().tripState == TripState.tracking) {
      double travelled = getDistanceBetween(
          startXY: _userPosition.point, endXY: position.point);
      if (travelled > 1000) {
        CurrentTripItem().newWaypoint(point: position.point);
      }
    }

    /// Update the map without animation
    MapService()
        .controller!
        .moveCamera(CameraUpdate.newLatLng(position.latLng));
    setState(() => _userPosition = position);
  }

  Future<void> changeRoute(
      {int lastManeuverIndex = 0,
      int routeIndex = 0,
      int pointIndex = 0}) async {
    bool update = await CurrentTripItem().changeRoute(
        lastManeuverIndex: lastManeuverIndex,
        position: CurrentTripItem().tripValues.position,
        routeIndex: routeIndex,
        pointIndex: pointIndex);
    if (update) {
      _directionTileController.updateRoute();
    }
  }

  void handleDebugStream(
      Position position, FollowRoute debugRoute, List<Follower> following) {
    LatLng pos = LatLng(position.latitude, position.longitude);
    CurrentTripItem().tripValues.heading = angleFromPoints(point1: [
      CurrentTripItem().tripValues.lastPosition.x.toDouble(),
      CurrentTripItem().tripValues.lastPosition.y.toDouble()
    ], point2: [
      pos.longitude,
      pos.latitude
    ]).toDouble();
    if (_following.isNotEmpty) {
      try {
        int index = _debugRoute.getIndex;
        int jump = 12;
        for (int i = 0; i < _following.length; i++) {
          if (index > jump * (i + 1)) {
            following[i] = following[i].moveFollower(
              newPosition: debugRoute.getPositionAt(index - (jump * (i + 1))),
            );
          } else {
            break;
          }
        }
      } catch (e) {
        debugPrint('Error setting followin ${e.toString()}');
      }
    }
    updateGroupOnMap(position);
  }

  void updateGroupOnMap(Position position) {
    if (CurrentTripItem().groupDriveId.isNotEmpty) {
      if (!socket.connected) {
        socket.connect();
        for (Follower follower in _following) {
          if (follower.email == Setup().user.email) {
            socket.emit('trip_join', {
              'token': Setup().jwt,
              'trip': CurrentTripItem().groupDriveId,
              'message': '',
              'make': follower.manufacturer,
              'model': follower.model,
              'colour': follower.carColour,
              'reg': follower.registration,
              'phone': follower.phoneNumber,
              'lat': position.latitude,
              'lng': position.longitude,
            });
          }
        }
      }

      if (socket.connected) {
        socket.emit(
          'trip_message',
          {
            'message': '',
            'lat': position.latitude,
            'lng': position.longitude,
          },
        );
      }
    }
  }
}
