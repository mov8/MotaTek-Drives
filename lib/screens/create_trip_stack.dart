import 'dart:async';
import 'dart:core';
import '../main.dart';
// import 'dart:js_interop_unsafe';
import 'dart:ui' as ui;
// import 'dart:js' as js; //_interop' as js1;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
// import 'dart:typed_data';
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
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '/routes/routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:maplibre_gl/maplibre_gl.dart'; // hide LatLng;

class CreateTripStackController {
  _CreateTripStackState? _createTripStackState;
  void _addState(_CreateTripStackState createTripStackState) {
    _createTripStackState = createTripStackState;
  }

  bool get isAttached => _createTripStackState != null;
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
  TripArguments? _tripArguments;
  final LeadingWidgetController _leadingWidgetController =
      LeadingWidgetController();
  final CreateTripController _createTripController = CreateTripController();
  final BottomDrawerController _bottomDrawerController =
      BottomDrawerController();
  final DirectionTileController _directionTileController =
      DirectionTileController();
  final RoutesBottomNavController _bottomNavController =
      RoutesBottomNavController();

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _dataLoaded,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Snapshot error: ${snapshot.error}');
          developer.log('CreateTrip().build() snapshot.hasError',
              name: '_map_');
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
    _tripArguments ??=
        TripArguments(activeChip: 2, appState: AppState.createTrip);
    // double start = 0;
    Future<bool>;

    return //IgnorePointer(
        //ignoring: false,
        // child:
        //    Container(
        //  color: Colors.red.withOpacity(0.3),
        //  child:

        Stack(
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

        if (MapService().controller != null)
          Positioned(
            left: 0,
            right: 0,
            top: 110,
            child: Align(
              // <-- Only do editing in "Explore" mode
              alignment: Alignment.topRight,
              child: HandleCTFabs(
                  controller: MapService().controller!,
                  sbController: MapService().statusBarController,
                  zfController: MapService().zoomFabController,
                  update: (update) => update ? setState(() {}) : null),
            ),
          ), //_debugUpdate),

        if (_tripArguments!.activeChip == 2) ...[
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
                    tripItem: CurrentTripItem(),
                    createTripController:
                        _createTripController ?? CreateTripController(),
                    leadingWidgetController: _leadingWidgetController,
                    position:
                        chipPosition(), // gets either stream or mapController position
                    onUpdate: (value) =>
                        _executeChipActions(tripActions: value),
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
          if (_tripArguments!.activeChip == 1) ...[
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
              maxHeight: 200,
              content: CurrentTripItem(),
              //  globalKey: _scrollKey,
              controller: _bottomDrawerController,
              //  requestClose: closeAndUpdateDrawer,
              imageRepository: _imageRepository,
              onOpened: onOpened,
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
                        child: StackNavBar()),
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

  void _executeChipActions(
      {MyTripActions tripActions = MyTripActions.none}) async {
    developer.log(
        '** CreateTrip().executeChipActions() tripActions: ${tripActions.toString()} **',
        name: '_goodRoad_');
    switch (tripActions) {
      case MyTripActions.beginTracking:
        await MapService().controller!.animateCamera(CameraUpdate.zoomTo(14.2));
        CurrentTripItem().tripState = TripState.tracking;
        setLocationUpdates();
        setState(() {});
        return;

      case MyTripActions.none || MyTripActions.addWaypoint:
        setState(() {});
        return;

      case MyTripActions.editTrip:
        setState(() => CurrentTripItem().tripState = TripState.editing);
        return;

      case MyTripActions.saveTrip:
        _saveTrip();
        return;

      case MyTripActions.clearTrip:
        setState(() => (CurrentTripItem().tripState = TripState.none));
        CurrentTripItem().mapUpdates = MapUpdates.updateAll;
        // micro-nudge to ensure MapLibre refreshes
        await MapService()
            .controller!
            .animateCamera(CameraUpdate.zoomBy(0.000001));
        return;

      case MyTripActions.startManual:
        /*
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
      */
        try {
          updateControllers(
              items: BottomDrawerItems.trip, open: true, dock: true);
          CurrentTripItem().tripValues.showTarget = true;
          CurrentTripItem().tripActions = TripActions.none;
          CurrentTripItem().tripState = TripState.manualStart;
          setState(() {});
        } catch (e) {
          developer.log('Error _executeTripActions() ${e.toString()}',
              name: '_chips_');
        }
        return;

      case MyTripActions.addPointOfInterest:
        /*
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
      */
        setState(
          () => updateControllers(
            items: BottomDrawerItems.trip,
            open: true,
            dock: true,
          ),
        );

        return;

      case MyTripActions.addGoodRoad:
        setState(() => (CurrentTripItem().isGoodRoad = true));
        return;

      /// May be able to combine this with .addPointOfInterest
      case MyTripActions.addGoodRoadDetails:
        /*
        _bottomDrawerController.setContent(content: BottomDrawerItems.goodRoad);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
        */
        updateControllers(
            items: BottomDrawerItems.goodRoad, open: true, dock: true);
        setState(() {});
        return;

      case MyTripActions.showSteps:
        /*
        _bottomDrawerController.setContent(content: BottomDrawerItems.maneuvers);
        _bottomDrawerController.open(height: 300);
        */
        updateControllers(
            items: BottomDrawerItems.maneuvers, open: true, dock: true);
        CurrentTripItem().tripActions = TripActions.none;
        return;

      case MyTripActions.showMessages:
        _bottomDrawerController.setContent(
            content: BottomDrawerItems.maneuvers);
        _bottomDrawerController.open(height: 300);
        CurrentTripItem().tripActions = TripActions.none;
        return;

      case MyTripActions.showGroup:
        _bottomDrawerController.setContent(
            content: BottomDrawerItems.group, drawerItems: _following);
        _bottomDrawerController.open(height: 300);
        CurrentTripItem().tripActions = TripActions.none;
        return;

      case MyTripActions.follow:
        _bottomDrawerController.setContent(
            content: BottomDrawerItems.maneuvers);
        setState(() => CurrentTripItem().tripActions = TripActions.none);
        setLocationUpdates();

        return;

      case MyTripActions.stopFollowing:
        CurrentTripItem().tripValues.pauseStream = true;
        setState(
            () => CurrentTripItem().tripState = TripState.stoppedFollowing);
        setLocationUpdates();
        return;

      case MyTripActions.track:
        setLocationUpdates();
        setState(() {});
        return;

      case MyTripActions.stopTracking:
        CurrentTripItem().tripValues.stopStream = true;
        setState(() => CurrentTripItem().tripState = TripState.stoppedTracking);
        setLocationUpdates();
        return;

      default:
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        //  _bottomDrawerController.open(height: 300);
        CurrentTripItem().tripActions = TripActions.none;
    }
    return;
  }

  void setLocationUpdates() async {
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
    _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
    _bottomDrawerController.open(height: 300);
    await Future.delayed(Duration(milliseconds: 500));
    _bottomDrawerController.dockOpenTile();
    //   }
    CurrentTripItem().tripActions = TripActions.none;
  }

  Future<void> _createMapImage({int delay = 1}) async {
    if (CurrentTripItem().mapImage == null) {
      setState(() {
        CurrentTripItem().tripActions = TripActions.saving;
        CurrentTripItem().highliteActions = HighliteActions.none;
        CurrentTripItem().tripValues.showProgress = true;
        _bottomDrawerController.close();
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
          _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        }
      }
      if (open) {
        if (kIsWeb) {
          MapService().sideDrawerController!.open(width: 0.4);
        } else {
          _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
          _bottomDrawerController.open(height: 300);
        }
      }
      if (dock) {
        if (kIsWeb) {
          MapService().sideDrawerController!.scrollTo(index: 0);
        } else {
          _bottomDrawerController.dockOpenTile();
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
}

class StackNavBar extends StatelessWidget {
  final RoutesBottomNavController? _controller;
  StackNavBar({super.key, RoutesBottomNavController? controller})
      : _controller = controller ?? RoutesBottomNavController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: kIsWeb
          ? null
          : RoutesBottomNav(
              key: Key('bnb1'),
              controller: _controller!,
              initialValue: 0,
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

class StackNavBar2 extends StatelessWidget {
  const StackNavBar2({super.key});
  @override
  Widget build(BuildContext context) {
    int _index = 0;
    List<int> badgeValues = [0, 0, 0, 0, 0, 0];
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 105,
      child: Material(
        elevation: 8,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            // 1. Force the height to 60 (default is 80)
            height: 60,
            // 2. Reduce the label font size so it fits the smaller bar
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
            // 3. Optional: Make the "pill" indicator smaller or remove it if it feels too tight
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: NavigationBar(
            elevation: 5,
            height: 60,
            surfaceTintColor: Colors.blue,
            onDestinationSelected: (int index) {
              MapService().setPage(page: index);
              //  setState(() => widget.onMenuTap(index));
              if ([1, 2].contains(index)) {
                UIStateService()
                    .setPage(0); //setMode(AppDisplayMode.navigator);
              }
              _index = index;
              MapService().setPage(page: index);
              Navigator.pushNamedAndRemoveUntil(
                  context, routes[index], (route) => false);
            },
            indicatorColor: Colors.lightBlue,
            selectedIndex: _index,
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (Set<WidgetState> states) {
                // If the tab is currently selected:
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  );
                }
                // Default style for unselected tabs:
                return const TextStyle(
                  fontSize: 10,
                  color: Colors.deepPurple,
                );
              },
            ),
            destinations: List<Widget>.generate(
                6,
                (index) => _navigationDestination(
                    index: index, badgeValue: badgeValues[index])),
          ), /* BottomNavigationBar(
          // The M2 version is shorter
          type: BottomNavigationBarType.fixed,
          currentIndex: 0,
          onTap: (_) => (),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
          ],
        ), */
        ),
      ),
    );
  }

  NavigationDestination _navigationDestination(
      {required int index, badgeValue = 0}) {
    if (badgeValue == 0) {
      return NavigationDestination(
        selectedIcon: Icon(routeNavIconsSelected[index]),
        icon: Icon(routeNavIcons[index]),
        label: routeNavLabels[index],
      );
    } else {
      return NavigationDestination(
        icon: Badge(
          label: Text(badgeValue
              .toString()), // _messages.isEmpty ? null : Text(_messages.length.toString()),
          child: Icon(routeNavIcons[index]),
        ),
        selectedIcon: Badge(
          label: Text(
            badgeValue.toString(),
          ),
          child: Icon(routeNavIconsSelected[index]),
        ),
        label: routeNavLabels[index],
      );
    }
  }
}
