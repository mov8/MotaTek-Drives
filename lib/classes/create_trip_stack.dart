import 'dart:async';
import 'dart:core';
// import '../main.dart';
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
// import 'package:flutter/rendering.dart';
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
      //   _createTripStackState?.showTopSnackBar(
      //       _createTripStackState!.context, index);
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
  // TripArguments? _tripArguments;
  final LeadingWidgetController _leadingWidgetController =
      LeadingWidgetController();
  // final CreateTripController _createTripController = CreateTripController();
  final DirectionTileController _directionTileController =
      DirectionTileController();
  // final RoutesBottomNavController _bottomNavController =
  //    RoutesBottomNavController();

  final ImageRepository _imageRepository = ImageRepository();
  StreamSubscription<Position>? _positionStream;
  late final FollowRoute _debugRoute;
  CurrentPosition _userPosition = CurrentPosition();
  late final StreamController<Position> _debugPositionController;
  late Position _currentPosition;
  PositionUpdate _positionUpdate = PositionUpdate();
  List tripItems = [];
  final List<Follower> _following = [];
  int _directionsIndex = 0;
  bool _resized = false;
  final bool _debugging = false; //true; //false; //true;
  final String _debuggingRoute = '';
  double _speed = 0.0;

  int positionUpdates = 0;

  late int _warningIndex;

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
    //if (index < 0) {
    //  MapService().fabsController?.show();
    //} else {
    setState(() => _warningIndex = index);
    //  setState(() => MapService().fabsController?.hide());
    await Future.delayed(const Duration(seconds: 15));
    setState(() => _warningIndex = -1);
    //  setState(() => MapService().fabsController?.show);
    //}
  }

/*
  void showTopSnackBar(
    BuildContext context,
    int index, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        dismissDirection: DismissDirection.up,
        duration: duration ?? const Duration(milliseconds: 1000),
        backgroundColor: Colors.grey,
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 120,
            left: 10,
            right: 10),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Expanded(flex: 2, child: warnings[index]['icon']),
            Expanded(
              flex: 10,
              child: Text(
                warnings[index]['message'],
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
*/
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
          // return body; //_getPortraitBody();
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
        /*  width: double.infinity,
          height: double.infinity,
          child: Align(
            alignment: Alignment.center,
            child: Text('Error getting data -\nCheck your Internet connection',
                style: TextStyle(fontSize: 22, color: Colors.white)),
          ),
          */

        // throw ('Error - FutureBuilder in create_trips.dart');
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
                  bool ready = snapshot.hasData;
                  return SizedBox.shrink();
                }
              },
            ),
          ),
        ),

        // if (_warningIndex > -1) MessageBox(index: 1), //_warningIndex),
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
            // height: 110,
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
                    onUpdate: (_) {
                      // setState(() => UIStateService().notify());
                    },
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
        //   MessageBox(
        //     index: _warningIndex,
        //   ),
        if (kIsWeb) ...[]
      ],
    );
  }

/*
  void setLocationUpdates2() async {
    try {
      if (CurrentTripItem().tripValues.pauseStream) {
        _positionStream!.pause();
        CurrentTripItem().tripValues.resumeStream = true;
        CurrentTripItem().tripValues.pauseStream = false;
      } else if (CurrentTripItem().tripValues.resumeStream) {
        _positionStream!.resume();
        CurrentTripItem().tripValues.resumeStream = false;
      } else {
        if (CurrentTripItem().tripValues.streamFinished) {
          _positionStream!.cancel();
        }
        if (_debugging) {
          if (_debuggingRoute.isEmpty) {
            _debugRoute.follow(routes: CurrentTripItem().routes);
            _positionStream = _debugPositionController.stream.listen(
              (Position position) {
                updatePosition(position);
              },
            );
          } else {
            MyTripItem debugMyTripItem = await getPrivateRepository()
                    .loadMyTripItem(name: _debuggingRoute) ??
                MyTripItem();
            if (debugMyTripItem.routes.isNotEmpty) {
              _debugRoute.follow(routes: debugMyTripItem.routes);
              _positionStream = _debugPositionController.stream
                  .listen((Position position) => updatePosition(position));
            }
          }
          if (CurrentTripItem().tripState == TripState.following) {
            _following.add(Follower(
                forename: 'One',
                surname: 'One',
                registration: 'CAR 001',
                position: [0, 0],
                track: true,
                carColour: 'red',
                iconColour: 1));
            _following.add(Follower(
              forename: 'Two',
              surname: 'Two',
              registration: 'CAR 002',
              position: [0, 0],
              track: true,
              carColour: 'blue',
              iconColour: 2,
            ));
            setState(() => CurrentTripItem().groupDriveId = 'gdDebug1');
          }

          // _positionStream.
        } else {
          const LocationSettings locationSettings = LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5, // 10 meters
          );
          try {
            _positionStream =
                Geolocator.getPositionStream(locationSettings: locationSettings)
                    .listen((position) {
              _currentPosition = position;
              _speed = _currentPosition.speed * 3.6 / 8 * 5; // M/S -> MPH
              if (CurrentTripItem().tripState == TripState.tracking) {
                updateUserPosition(CurrentPosition(position: position));
              }
            });
          } catch (e) {
            debugPrint('Error getting stream ${e.toString()}');
          }
        }
        CurrentTripItem().tripValues.streamStarted = true;
        CurrentTripItem().tripValues.streamFinished = false;
        CurrentTripItem().tripValues.lastPosition = Point(0, 0);
        CurrentTripItem().tripValues.startPosition = Point(0, 0);
        CurrentTripItem().tripValues.position = Point(0, 0);

        if (_positionStream != null) {
          _positionStream!
              .onDone(() => CurrentTripItem().tripValues.streamFinished = true);
        }
      }
    } catch (e) {
      developer.log('Error Stream error: ${e.toString()}', name: 'error');
    }
  }
*/
  Point chipPosition() {
    try {
      return Point(MapService().controller!.cameraPosition!.target.latitude,
          MapService().controller!.cameraPosition!.target.longitude);
      // _animatedMapController.mapController.camera.center;
    } catch (e) {
      return Point(0, 0);
    }
  }

  Future<bool> dataFromDatabase() async {
    try {
      if (Setup().hasLoggedIn) {
        var setupRecords = await getPrivateRepository().recordCount('setup');
        if (setupRecords > 0) {
          try {
            Setup().loaded;
          } catch (e) {
            debugPrint('Error starting local database: ${e.toString()}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting features data: ${e.toString()}');
    }
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

      /// Put the default values back into the drawer after other is viewed and drawer is closed
      if (tripItems.isNotEmpty) {
        MapService().sideDrawerController!.setContent(
            content: BottomDrawerItems.favourites,
            drawerItems: tripItems as List<Widget>);
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

  void updateControllers(
      {BottomDrawerItems? items, bool open = false, bool dock = false}) {
    try {
      if (items != null) {
        if (kIsWeb) {
          MapService()
              .sideDrawerController!
              .setContent(content: BottomDrawerItems.trip);
        } else {
          MapService()
              .bottomDrawerController!
              .setContent(content: BottomDrawerItems.trip);
        }
      }
      if (open) {
        if (kIsWeb) {
          MapService().sideDrawerController!.open(width: 0.4);
        } else {
          MapService()
              .bottomDrawerController!
              .setContent(content: BottomDrawerItems.trip);
          MapService().bottomDrawerController!.open();
        }
      }
      if (dock) {
        if (kIsWeb) {
          MapService().sideDrawerController!.scrollTo(index: 0);
          //  } else {
          //    MapService().bottomDrawerController!.dockOpenTile();
        }
      }
    } catch (e) {
      developer.log('Error in updateControllers(): ${e.toString()}',
          name: 'error');
    }
  }

  void updatePosition(Position position) async {
    _currentPosition = position;
    _userPosition = CurrentPosition(position: position);
    CurrentTripItem().tripValues.position = _userPosition.point;
    position.speed * metersPerSecondToMPH; //* 3.6 / 8 * 5; // M/S -> MPH

    LatLng pos = _userPosition.latLng;
    // LatLng(position.latitude, position.longitude);

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
      _speed = position.speed.toDouble();
      _positionUpdate = PositionUpdate(
        controller: MapService().controller!, // as MapLibreMapController,
        routePoint: position.list,
      );
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
    _speed = 43.0;
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
