import 'dart:async';
import 'dart:core';
import '../main.dart';
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
import 'package:flutter/rendering.dart';
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
      _createTripStackState!.refresh();
    }
  }

  void setBottomNav(int index) {
    if (isAttached) {
      _createTripStackState!.setBottomNav(index);
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
  Point _pointAtCentre = Point(0, 0);
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
  int _navIndex = 0;
  int positionUpdates = 0;

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

  void refresh() => setState(() => {});

  void setBottomNav(int index) {
    setState(() => _navIndex = index);
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
            developer.log('CreateTrip().build() snapshot.hasData',
                name: '_map_');
            Widget body = _getPortraitBody();
            return body;
          } catch (e) {
            developer.log('CreateTrip().build() error:${e.toString()}',
                name: '_map_');
            debugPrint('error getting portraitBody ${e.toString()}');
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

        return const SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Align(
            alignment: Alignment.center,
            child: Text('Error getting data -\nCheck your Internet connection',
                style: TextStyle(fontSize: 22, color: Colors.white)),
          ),
        );
        // throw ('Error - FutureBuilder in create_trips.dart');
      },
    );
  }

  Widget _getPortraitBody() {
    // _tripArguments ??=
    //     TripArguments(activeChip: 2, appState: AppState.createTrip);
    Future<bool>;
    // Widget chips = Text('');
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 110,
          child: Material(
            child: Overlay(
              // <-- has to be added because outside Navigation
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Material(
                    type: MaterialType.transparency,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: StackAppBar()),
                  ),
                ),
              ],
            ),
          ),
        ),

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
                  return AnimatedScale(
                    scale: ready ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: ready
                        ? HandleCTFabs(
                            controller: MapService().controller!,
                            sbController: MapService().statusBarController,
                            zfController: MapService().zoomFabController,
                            update: (update) => update ? setState(() {}) : null,
                          )
                        : SizedBox.shrink(),
                  );
                }
              },
            ),
          ),
        ),
        if (NavigationService().page == 2) ...[
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
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
                      setState(() => UIStateService().notify());
                    },
                  ),
                ),
              ),
            ),
          ),
          if (CurrentTripItem().tripValues.showTarget &&
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
                  color:
                      CurrentTripItem().isGoodRoad ? Colors.red : Colors.black),
            )
          ],
          if (CurrentTripItem().tripState == TripState.following) ...[
            Positioned(
              top: _pointAtCentre.y.toDouble() - 20,
              left: _pointAtCentre.x.toDouble() - 20,
              child: RotationTransition(
                turns: AlwaysStoppedAnimation(0 / 360),
                child: Icon(
                  size: 40,
                  Icons.navigation,
                  // Icons.assistant_navigation,
                  color: Colors.blueAccent,
                ),
              ),
            )
          ],
          if (_userPosition.speed > 0.01) ...[
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
                    child: Text(_userPosition.speed.toString(),
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
        if (!kIsWeb)
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            //  height: 110,
            child: BottomDrawer(
              context: context,
              maxHeight: 500,
              controller: MapService().bottomDrawerController,
              content: CurrentTripItem(),
              imageRepository: _imageRepository,
              onOpened: onOpened,
              onUpdate: update,
            ),
          ),

        /// getDirections shows the turn-by-turn navigation details
        getDirections(_directionsIndex),

        /// The StatusBar allows the showing of messages and the KeyScale.
        /// At the moment the KeyScale is always right justified.
        /// There is only one BarMessage widget catered for
        /// ToDo: Allow more flexible status bar messages
        ///S
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 105,
          child: Material(
            child: Overlay(
              // <-- has to be added because outside Navigation
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Material(
                    type: MaterialType.transparency,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: StackNavBar(index: _navIndex)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (kIsWeb) ...[]
      ],
    );
  }

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
  onOpened(open) async {
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
        Setup().setupToDb(); // <-- Writes the setup changes to api
      }
    }
    setState(() {});
  }

  update(complete) {
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

  _saveTrip() async {
    if (CurrentTripItem().headerComplete() != 7) {
      _getTripDescriptions();
      return;
    }
    if (CurrentTripItem().uri.isEmpty) {
      CurrentTripItem().uri = getUuid();
    }
    await _createMapImage();
    CurrentTripItem().imageRepository ??= _imageRepository;
    await CurrentTripItem().savePrivate();
    CurrentTripItem().tripState = TripState.loaded;
    setState(() => CurrentTripItem().tripValues.editing());
  }

  _getTripDescriptions() async {
    MapService()
        .bottomDrawerController!
        .setContent(content: BottomDrawerItems.trip);
    MapService().bottomDrawerController!.open(height: 500);
    await Future.delayed(Duration(milliseconds: 500));
    MapService().bottomDrawerController!.dockOpenTile();
    //   }
    CurrentTripItem().tripActions = TripActions.none;
  }

  Future<void> _createMapImage({int delay = 1}) async {
    if (CurrentTripItem().mapImage == null) {
      setState(() {
        CurrentTripItem().tripActions = TripActions.saving;
        CurrentTripItem().highliteActions = HighliteActions.none;
        CurrentTripItem().tripValues.showProgress = true;
        MapService().bottomDrawerController!.close();
      });
      int tries = 0;
      while (_resized == false && ++tries < 5) {
        await Future.delayed(Duration(milliseconds: delay * 500));
      }

      // final Uint8List? imageBytes =
      //     await _mapController!.takeSnapShot(width: 200, height: 200);

      //  await _mapController!.takeSnapshot();
      //  Uint8List? bytes = await _mapController!.takeSnapshot();
      //  await _mapLibreMap.takeSnapshot();
      try {
        Uint8List mapBytes = await MapService().controller!.takeSnapshot();

        if (CurrentTripItem().mapImage == null) {
          CurrentTripItem().mapImage ??= ImageInMemory(
              name: 'map', imageBytes: mapBytes.buffer.asUint8List());
        } else {
          CurrentTripItem().mapImage!.imageBytes =
              mapBytes.buffer.asUint8List();
        }
      } catch (e) {
        developer.log(
            'Error CreateTrip().createMapImage() saving map screenshot: "{eo.toString()',
            name: 'error');
      }
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
          MapService().bottomDrawerController!.open(height: 500);
        }
      }
      if (dock) {
        if (kIsWeb) {
          MapService().sideDrawerController!.scrollTo(index: 0);
        } else {
          MapService().bottomDrawerController!.dockOpenTile();
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
    String debugString = 'updatePosition()  called x ${positionUpdates++} ';
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
      // setState(() => _directionTileController.updateRoute());
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

  getChips() {
    //   List<String> chipNames = [];
    // CreateTripCurrentTripItem().values CurrentTripItem().tripValues = CreateTripCurrentTripItem().values();
    MyTripItem tripItem = CurrentTripItem();
    List<ActionChip> chips = [];
    try {
      if (CurrentTripItem().tripState == TripState.startFollowing) {
        () => MapService()
            .createTripController
            .updateValues(values: CurrentTripItem().tripValues);
      }
      if (CurrentTripItem().tripState == TripState.none) {
        CurrentTripItem().tripActions = TripActions.none;
        CurrentTripItem().isSaved = false;
        CurrentTripItem().isTracking = false;
        CurrentTripItem().highliteActions = HighliteActions.none;
      }
      final List<Map> chipDetails = [
        {
          'label': 'Extend start',
          'method': extendStart, //extendStart,
          'icon': Icons.pin_drop,
          'states': [TripState.editing],
          'actions': [],
          'waypointState': WaypointState.extendStart,
          'highlight': [HighliteActions.none],
          'loaded': true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Waypoint',
          'method': waypoint,
          'icon': Icons.pin_drop,
          'actions': [],
          'states': [
            TripState.manual,
            TripState.manualStart,
            TripState.goodRoadStart,
          ],
          // 'waypointState': [WaypointState.none],
          'highlight': [HighliteActions.none, HighliteActions.greatRoadStarted],
          'waypointState': WaypointState.none,
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().goodRouteColour]
              : colourList[Setup().routeColour],
          'loaded': null,
          'saved': null,
          'goodRoad': null,
          'group': false
        },
        {
          'label': 'Insert waypoint',
          'method': waypoint,
          'icon': Icons.pin_drop,
          'states': [TripState.editing],
          'actions': [],
          'waypointState': WaypointState.insert,
          'highlight': [HighliteActions.none, HighliteActions.greatRoadStarted],
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().goodRouteColour]
              : colourList[Setup().routeColour],
          'loaded': null,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Extend end',
          'method': extendEnd, // extendEnd,
          'icon': Icons.pin_drop,
          'states': [TripState.editing],
          'waypointState': WaypointState.extendEnd,
          'actions': [],
          'highlight': [HighliteActions.none],
          'loaded': true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Remove waypoint',
          'method': removeWaypoint,
          'icon': Icons.wrong_location,
          'states': [TripState.manual, TripState.editing],
          'actions': [],
          'waypointState': WaypointState.remove,
          'highlight': [],
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().goodRouteColour]
              : colourList[Setup().routeColour],
          'loaded': null,
          'saved': null,
          'group': false
        },
        {
          'label': 'Revisit waypoint',
          'method': revisitWaypoint,
          'icon': Icons.wrong_location,
          'states': [TripState.manual, TripState.editing],
          'actions': [],
          'waypointState': WaypointState.revisit,
          'highlight': [],
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().goodRouteColour]
              : colourList[Setup().routeColour],
          'loaded': null, //true,
          'saved': null,
          'group': false
        },
        {
          'label': 'Reverse trip',
          'method': reverseTrip,
          'icon': Icons.autorenew_outlined,
          'states': [TripState.editing],
          'actions': [],
          'highlight': [HighliteActions.waypointHighlited],
          'loaded': true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Point of interest',
          'method': pointOfInterest,
          'icon': Icons.add_photo_alternate,
          'states': [
            TripState.manual,
            TripState.editing,
            //   TripState.tracking,
            //   TripState.pausedTracking,
            //   TripState.stoppedTracking
          ],
          'actions': [],
          'highlight': [HighliteActions.none, HighliteActions.routeHighlited],
          'loaded': null, //true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Create manually',
          'method': addManually,
          'icon': Icons.touch_app,
          'states': [TripState.none],
          'actions': [],
          'highlight': [],
          'loaded': false,
          'saved': null,
          'group': false
        },
        {
          'label': 'Edit route',
          'method': editing,
          'icon': Icons.edit,
          'states': [TripState.none, TripState.loaded, TripState.notFollowing],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': false
        },
        {
          'label': 'Save route',
          'method': saveTrip,
          'icon': Icons.save,
          'states': [
            TripState.manual,
            TripState.stoppedTracking,
            TripState.editing
          ],
          'actions': [],
          'highlight': [HighliteActions.none],
          'loaded': true,
          'saved': false,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Clear route',
          'method': clear,
          'icon': Icons.delete,
          'states': [
            TripState.editing,
            TripState.loaded,
            TripState.none,
            TripState.notFollowing,
            TripState.stoppedFollowing,
            TripState.stoppedTracking,
            TripState.manual,
            TripState.manualStart,
          ],
          'actions': [],
          'highlight': [HighliteActions.none],
          'loaded': true,
          'saved': null,
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Add great road',
          'method': greatRoad,
          'icon': Icons.add_road,
          'states': [
            // TripState.tracking,
            TripState.manual,
            TripState.editing,
          ],
          'actions': [],
          'highlight': [HighliteActions.none],
          'loaded': null,
          'saved': null,
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().routeColour]
              : colourList[Setup().goodRouteColour],
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Edit great road',
          'method': editGreatRoad,
          'icon': Icons.edit,
          'states': [TripState.tracking, TripState.manual, TripState.editing],
          'actions': [],
          'highlight': [HighliteActions.greatRoadHighlighted],
          'loaded': null,
          'saved': null,
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().routeColour]
              : colourList[Setup().goodRouteColour],
          'group': false,
          'goodRoad': false,
        },
        {
          'label': 'Plan drive',
          'method': greatRoadEnd,
          'icon': Icons.add_road,
          'states': [TripState.manual, TripState.editing],
          'actions': [],
          'highlight': [],
          'loaded': null,
          'saved': false,
          'group': false,
          'colour': CurrentTripItem().isGoodRoad
              ? colourList[Setup().routeColour]
              : colourList[Setup().goodRouteColour],
          'goodRoad': true
        },
        {
          'label': 'Great road end',
          'method': greatRoadEnd,
          'icon': Icons.add_road,
          'states': [TripState.editing, TripState.manual],
          'actions': [],
          'highlight': [],
          'loaded': null,
          'saved': false,
          'group': false,
          'colour': colourList[Setup().routeColour],
          'goodRoad': true
        },
        {
          'label': 'Track drive',
          'method': addAutomatically,
          'icon': Icons.directions_car,
          'states': [TripState.none],
          'actions': [],
          'highlight': [],
          'loaded': false,
          'saved': null,
          'group': false
        },
        {
          'label': 'Continue tracking',
          'method': trackRoute,
          'icon': Icons.play_arrow,
          'states': [TripState.pausedTracking],
          'actions': [],
          'highlight': [],
          'loaded': null,
          'saved': null,
          'group': false
        },
        {
          'label': 'Pause tracking',
          'method': pauseTracking,
          'icon': Icons.pause,
          'states': [TripState.tracking],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': false
        },
        {
          'label': 'End tracking',
          'method': endTracking,
          'icon': Icons.stop,
          'states': [TripState.tracking, TripState.pausedTracking],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': false
        },
        {
          'label': 'Follow drive',
          'method': followRoute,
          'icon': Icons.play_arrow,
          'states': [
            TripState.loaded,
            TripState.stoppedFollowing,
            TripState.notFollowing,
          ],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': null
        },
        {
          'label': 'Stop following',
          'method': stopFollowing,
          'icon': Icons.stop,
          'states': [TripState.following],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': null
        },
        {
          'label': 'Steps',
          'method': steps,
          'icon': Icons.timeline,
          'states': [
            TripState.following,
            TripState.stoppedFollowing,
            TripState.notFollowing,
            TripState.loaded,
            TripState.manual,
            TripState.editing
          ],
          'actions': [], // [TripActions.none],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': null,
          'goodRoad': false,
        },
        {
          'label': 'Group',
          'method': group,
          'icon': Icons.directions_car,
          'states': [
            TripState.following,
            TripState.stoppedFollowing,
            TripState.notFollowing,
            TripState.loaded
          ],
          'actions': [], // [TripActions.none],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': true
        },
        /*
      {
        'label': 'Drive info',
        'method': tripData,
        'icon': Icons.map,
        'states': [],
        'actions': [
          TripActions.showGroup,
          TripActions.showMessages,
          TripActions.showSteps
        ],
        'highlight': [],
        'loaded': true,
        'saved': null,
        'group': false
      },
    */
        {
          'label': 'Messages',
          'method': messages,
          'icon': Icons.chat_outlined,
          'states': [
            TripState.following,
            TripState.stoppedFollowing,
            TripState.notFollowing,
            TripState.loaded
          ],
          'actions': [],
          'highlight': [],
          'loaded': true,
          'saved': null,
          'group': true
        },
      ];

      String failure = '';
      bool actionsOk(int i) {
        bool ok = chipDetails[i]['actions'].isEmpty ||
            chipDetails[i]['actions'].contains(CurrentTripItem().tripActions);
        failure = ok ? failure : '$failure, ACTIONS';
        return ok;
      }

      bool statesOk(int i) {
        /// CurrentTripItem().tripState is an Enum
        bool ok = (chipDetails[i]['states'].isEmpty ||
            chipDetails[i]['states'].contains(CurrentTripItem().tripState));
        failure = ok ? failure : '$failure, STATES';
        return ok;
      }

      bool waypointOk2(int i) {
        return false;
      }

      bool waypointOk(int i) {
        return chipDetails[i]['waypointState'] == null ||
            chipDetails[i]['waypointState'] == CurrentTripItem().waypointState;
      }

      bool highlightsOk(int i) {
        bool ok = ((chipDetails[i]['highlight'].isEmpty ||
                chipDetails[i]['highlight']
                    .contains(CurrentTripItem().highliteActions)) &&
            chipDetails[i]['highlight'] != HighliteActions.none);
        failure = ok ? failure : '$failure, HIGHLIGHTS';
        return ok;
      }

      /// loaded is a tri-value flag true, false either (null)
      /// Have to include the null test twice as Dart evaluates both sides of the || and
      /// errors if the RHS does a non null save evaluation even though the LHS satisfies the test.
      bool loadedOk(int i) {
        bool ok = chipDetails[i]['loaded'] == null ||
            (chipDetails[i]['loaded'] != null && chipDetails[i]['loaded']
                ? CurrentTripItem().routes.isNotEmpty
                : CurrentTripItem().routes.isEmpty);
        return ok;
      }

      bool savedOk(int i) {
        bool ok = chipDetails[i]['saved'] == null ||
            CurrentTripItem().isSaved == chipDetails[i]['saved'];
        failure = ok ? failure : '$failure, SAVED';
        return ok;
      }

      bool groupOk(int i) {
        bool ok = chipDetails[i]['group'] == null ||
            (chipDetails[i]['group'] ==
                CurrentTripItem().groupDriveId.isNotEmpty);
        failure = ok ? failure : '$failure, GROUP';
        return ok;
      }

      bool goodRoadOk(int i) {
        bool ok = chipDetails[i]['goodRoad'] == null ||
            CurrentTripItem().isGoodRoad == chipDetails[i]['goodRoad'];
        failure = ok ? failure : '$failure, GOODROAD';
        return ok;
      }

      bool isValid(int i) {
        return actionsOk(i) &&
            statesOk(i) &&
            highlightsOk(i) &&
            waypointOk(i) &&
            loadedOk(i) &&
            savedOk(i) &&
            groupOk(i) &&
            goodRoadOk(i);
      }

      try {
        for (int i = 0; i < chipDetails.length; i++) {
          failure = '';

          Color colour = CurrentTripItem().isGoodRoad &&
                  ['Waypoint'].contains(chipDetails[i]['label'])
              ? colourList[Setup().goodRouteColour]
              : Colors.white;
          Color wpColour = CurrentTripItem().isGoodRoad &&
                  ['Waypoint', 'Plan drive', 'Add great road']
                      .contains(chipDetails[i]['label'])
              ? colourList[Setup().goodRouteColour]
              : Colors.white;

          if (isValid(i)) {
            chips.add(ActionChip(
                visualDensity:
                    const VisualDensity(horizontal: 0.0, vertical: 0.5),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                label: Text(chipDetails[i]['label'],
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                elevation: 10,
                shadowColor: Colors.black,
                onPressed: () => chipDetails[i]['method'](),
                avatar: Icon(chipDetails[i]['icon'],
                    size: 20,
                    color: chipDetails[i]['colour'] ?? Colors.white)));
          } else {
            //  Code below very useful - don't remove
            developer.log(
                '$i - [${chipDetails[i]['label']}] failed => ${actionsOk(i) ? '' : 'actions '}${statesOk(i) ? '' : 'states '}${highlightsOk(i) ? '' : 'highlights '}${waypointOk(i) ? '' : 'waypoints '}${loadedOk(i) ? '' : 'loaded '}${savedOk(i) ? '' : 'saved '}${groupOk(i) ? '' : 'group '}${goodRoadOk(i) ? '' : 'goodRoad'}',
                name: '_actionChips_');
          }
        }
      } catch (e) {
        debugPrint('error: &{e.toString()}');
      }
    } catch (e) {
      developer.log('Error creating ActionChips: ${e.toString()}',
          name: '_nav_');
    }
    return chips;
  }

  void addAutomatically() {
    CurrentTripItem().requestAddAutomatically();
    MapService().leadingWidgetController.changeWidget(1);
    CurrentTripItem().tripState = TripState.tracking;
    onUpdate!(MyTripActions.beginTracking);
  }

  void addManually() {
    try {
      MapService().leadingWidgetController.changeWidget(1);
    } catch (e) {
      developer.log(
          'Error CreateTripChips().addManually() error: ${e.toString()}',
          name: 'error');
    }
    CurrentTripItem().requestAddManually();
    onUpdate!(MyTripActions.startManual);
  }

  void clear() {
    // CurrentTripItem().requestClear();
    CurrentTripItem().requestClear();
    MapService().leadingWidgetController.changeWidget(0);
    CurrentTripItem().tripState = TripState.none;
    CurrentTripItem().mapUpdates = MapUpdates.updateAll;
    onUpdate!(MyTripActions.clearTrip);
  }

  void editing() {
    CurrentTripItem().requestEditing();
    MapService().leadingWidgetController.changeWidget(1);
    onUpdate!(MyTripActions.editTrip);
  }

  void extendStart() async {
    CurrentTripItem().requestExtendStart();
    onUpdate!(MyTripActions.addWaypoint);
  }

  void waypoint() async {
    CurrentTripItem().requestWaypoint();
    if (CurrentTripItem().tripValues.addGoodRoadDetail) {
      onUpdate!(MyTripActions.addGoodRoadDetails);
    } else {
      onUpdate!(MyTripActions.addWaypoint);
    }
  }

  void revisitWaypoint() async {
    CurrentTripItem().requestRevisitWaypoint();
    onUpdate!(MyTripActions.revisitWaypoint);
  }

  void extendEnd() async {
    CurrentTripItem().requestExtendEnd();
    onUpdate!(MyTripActions.addWaypoint);
  }

  saveTrip() async {
    onUpdate!(MyTripActions.saveTrip);
    return;
  }

  void removeWaypoint() async {
    CurrentTripItem().requestRemoveWaypoint();
    onUpdate!(MyTripActions.deleteWaypoint);
  }

  void pauseTracking() {
    CurrentTripItem().requestPauseTracking();
    onUpdate!(MyTripActions.none);
    // createTripController.updateValues(values: CurrentTripItem().tripValues);
  }

  void endTracking() {
    CurrentTripItem().requestEndTracking();
    onUpdate!(MyTripActions.stopTracking);
  }

  void greatRoad() {
    CurrentTripItem().requestGreatRoad();
    onUpdate!(MyTripActions.addGoodRoad);
  }

  void editGreatRoad() {
    CurrentTripItem().requestEditGreatRoad();
    onUpdate!(MyTripActions.saveGoodRoad);
  }

  void greatRoadEnd() {
    CurrentTripItem().requestGreatRoadEnd();
    onUpdate!(MyTripActions.addGoodRoadDetails);
    //  onUpdate(MyTripActions.addGoodRoad);
  }

  void reverseTrip() async {
    await CurrentTripItem().reverseRoute();
    onUpdate!(MyTripActions.reverseTrip);
    return;
  }

  void pointOfInterest() {
    CurrentTripItem().requestPointOfInterest();
    onUpdate!(MyTripActions.addPointOfInterest);
    return;
  }

  void steps() {
    onUpdate!(MyTripActions.showSteps);
  }

  void group() {
    CurrentTripItem().requestGroup();
    onUpdate!(MyTripActions.showGroup);
  }

  void messages() {
    CurrentTripItem().requestMessages();
    onUpdate!(MyTripActions.message);
  }

  void tripData() {
    CurrentTripItem().tripActions = TripActions.none;
    CurrentTripItem().tripValues.setState = true;
    MapService()
        .createTripController
        .updateValues(values: CurrentTripItem().tripValues);
  }

  void trackRoute() {
    CurrentTripItem().requestTrackRoute();
    onUpdate!(MyTripActions.track);
    return;
  }

  void followRoute() {
    CurrentTripItem().requestFollowRoute();
    onUpdate!(MyTripActions.follow);
    return;
  }

  void stopFollowing() {
    CurrentTripItem().requestStopFollowing;
    onUpdate!(MyTripActions.stopFollowing);
  }

  onUpdate(MyTripActions tripActions) {}

  ///
  ///
}

class StackNavBar extends StatelessWidget {
  final RoutesBottomNavController? _controller;
  int index;
  StackNavBar(
      {super.key, RoutesBottomNavController? controller, this.index = 0})
      : _controller = controller ?? RoutesBottomNavController();

//  void setIndex({required int index}) {
//    index = index;
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: kIsWeb
          ? null
          : RoutesBottomNav(
              key: Key('bsnb1'),
              controller: _controller!,
              //    initialValue: index,
              onMenuTap: (_) => {}),
    );
  }
}

class StackAppBar extends StatelessWidget {
  final LeadingWidgetController? _controller;
  final BottomDrawerController? _bdController;
  StackAppBar(
      {super.key,
      LeadingWidgetController? controller,
      BottomDrawerController? bottomDrawerController})
      : _controller = controller ?? LeadingWidgetController(),
        _bdController = bottomDrawerController ?? BottomDrawerController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(
              key: Key('sab1'),
              automaticallyImplyLeading: false,
              toolbarHeight: 80,
              leading: LeadingWidget(
                controller: _controller!,
                initialValue: 0,

                value: CurrentTripItem()
                    .tripValues
                    .leadingWidget, //   initialLeadingWidgetValue,
                onMenuTap: (index) {
                  if (index == 0) {
                    // _leadingWidget(_scaffoldKey.currentState);
                  } else {
                    CurrentTripItem().onBackPressed();
                    _controller.changeWidget(0);
                    _bdController!.setContent(content: BottomDrawerItems.none);
                    _bdController.close();
                    // setState(() {});
                  }
                },
              ),
              title: Text(CurrentTripItem().getTripTitle(),
                  style: headlineStyle(context: context, size: 2)),
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: Colors.blue,
              actions: CurrentTripItem().getActions(
                context: context,
                //  onUpdate: () =>  async {await _mapController!.animateCamera(CameraUpdate.zoomBy(0.000001))},
                onUpdate: (_) => null,
              ),
            ),
    );
  }
}
