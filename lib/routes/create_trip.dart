import 'dart:async';
import 'dart:core';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'dart:math';
import '/constants.dart';
import '/classes/classes.dart' hide Position;
import '/screens/screens.dart';
import '/services/services.dart' hide getPosition;
import '/models/models.dart';
import '/helpers/helpers.dart';
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:maplibre_gl/maplibre_gl.dart'; // hide LatLng;

MapLibreMapController? _mapController;
BottomDrawerController _bottomDrawerController = BottomDrawerController();

/*
This might well be a good pat to follow as it uses Flutter_maps

https://www.reddit.com/r/openstreetmap/comments/1ew60cw/how_i_learned_to_create_custom_maps_for_my_mobile/
https://openmaptiles.org/docs/generate/create-custom-extract/
https://github.com/maplibre/maputnik/wiki <- map styling

https://docs.maptiler.com/flutter/

https://project-osrm.org/docs/v5.5.1/api/#trip-service
https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames

creating vector tiles from osm
https://osmand.net/docs/technical/map-creation/create-offline-maps-yourself/
https://wiki.openstreetmap.org/wiki/Osmator

https://openmaptiles.org/osm2vectortiles/ -AndMapCre creating vector tiles from osm
https://openmaptiles.org/docs/

TILE CACHING objectbox looks really useful it stores Dart objects and is really fast
https://pub.dev/packages/objectbox - looks really neat with cross-device synchronisation
https://github.com/JaffaKetchup/flutter_map_tile_caching/blob/main/lib/src/backend/impls/objectbox/models/src/tile.dart

Vector tiles from osrm data:
Look at Tilemaker that creates vector tiles from
*/

int testInt = 0;

enum MessageActions { none, read, write, writing, reply, send, delete }

enum ApiActions { none, pointOfInterest, waypoint, goodRoad }

class CreateTripController {
  _CreateTripState? _createTripState;
  void _addState(_CreateTripState createTripState) {
    _createTripState = createTripState;
  }

  bool get isAttached => _createTripState != null;

  Future<ui.Image?> getMapImage() async {
    try {
      //  return _createTripState?._createMapImage();
    } catch (e) {
      debugPrint("Can't get the map image");
    }
    return null;
  }

  void updateValues({required CreateTripValues values}) {
    try {
      //    _createTripState?.updateValues(values: values);
    } catch (e) {
      debugPrint("Can't update CreateTrip state values");
    }
  }

  bool? getTripInfo({bool prompt = false}) {
    try {
      //  return _createTripState?.getTripDetails(prompt: prompt);
    } catch (e) {
      debugPrint("Can't stop following");
    }
    return false;
  }

  void drive({bool follow = false}) {
    try {
      //     _createTripState?.setLocationUpdates();
    } catch (e) {
      debugPrint('Controller error: ${e.toString()}');
    }
  }
/*
  void editing() {
  setLocationUpdates()
    try {
      _createTripState?.editing();
    } catch (e) {
      debugPrint("Can't stop following");
    }
  }

  void waypoint() {
    try {
      _createTripState?.waypoint();
    } catch (e) {
      debugPrint("Can't stop following");
    }
  }
  */
}

class CreateTrip extends StatefulWidget {
  final CreateTripController? controller;
  const CreateTrip({super.key, this.controller});
  @override
  State<CreateTrip> createState() => _CreateTripState();
}

class _CreateTripState extends State<CreateTrip> with TickerProviderStateMixin {
  final GlobalKey mapKey = GlobalKey();
  final GlobalKey _scaffoldKey = GlobalKey();
  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _bottomNavKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scrollKey = GlobalKey();

  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
  List<double> mapHeights = [0, 0, 0, 0];

  final start = TextEditingController();
  final end = TextEditingController();

  late final RoutesBottomNavController _bottomNavController; // =
  final GroupMessagesController groupMessagesController =
      GroupMessagesController();
  bool isVisible = false;
  PopupValue popValue = PopupValue(-1, '', '');
  final navigatorKey = GlobalKey<NavigatorState>();
  List<TripItem> tripItems = [];
  int id = -1;
  int userId = -1;
  int type = -1;
  int _directionsIndex = 0;
  double iconSize = 35;
  double _mapRotation = 0;
  StreamSubscription<Position>? _positionStream;
  late Future<bool> _loadedOK;
  // late Future<bool> _groupChecked;
  bool _showMask = false;
  bool _osmIncludingChange = false;
  late FocusNode fn1;
  late ui.Size screenSize;
  late ui.Size appBarSize;
  double mapHeight = 250;
  double listHeight = 0;
  final TripPreferences _preferences = TripPreferences();
  // int CurrentTripItem().tripValues.pointOfInterestIndex = -1;
  late Position _currentPosition;
  bool _resized = false;
//  bool _repainted = false;
  // DateTime _start = DateTime.now();
  double _speed = 0.0;
  int insertAfter = -1;
  int _poiDetailIndex = -1;
  var moveDelay = const Duration(seconds: 2);
  int highlightedIndex = -1;
  final List<Follower> _following = [];
  late LocationSettings _locationSettings;
  late final StreamController<double?> _alignPositionStreamController;
  late final StreamController<void> _alignDirectionStreamController;
  late final LeadingWidgetController _leadingWidgetController;
  late final DirectionTileController _directionTileController;
  late final StreamController<Position> _debugPositionController;
  late final FollowRoute _debugRoute;
  int initialLeadingWidgetValue = 0;
  final List<Place> _places = [];
  String wpId = '';
  String grId = '';
  MLMap? mapLibreMap;
  String images = '';
  final bool _debugging = true; //false; //true;
  final String _debuggingRoute = ''; //'Debug';

  StreamSocket streamSocket = StreamSocket();
  sio.Socket socket = sio.io(urlBase, <String, dynamic>{
    // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
    'transports': ['websocket'], // Specify WebSocket transport
    'autoConnect': false, // Prevent auto-connection
  });

  // final List<GlobalKey> _scrollToKeys = <GlobalKey>[];
  // final GlobalKey _mapKey = GlobalKey();
  TripRequest? _tripRequest;
  // List<Card> _tripCards = [];
  Point _mapMiddle = Point(0, 0);
  Size _mapSize = Size(0, 0);

  bool _opened = false;

  Map<String, dynamic> linesMap = {};
  // late MLMap mapLibreMap;
  // Widget? _cardList;

  ImageRepository _imageRepository = ImageRepository();

  /// Routine to add point of interest
  /// Identified as a point

  _addPointOfInterest(int id, int userId, int iconIdx, String desc, String hint,
      double size, List<double> lngLat, String audio) {
    try {
      /*   CurrentTripItem().addPointOfInterest(
        PointOfInterest(
          id: id,
          driveId: CurrentTripItem().driveId,
          type: iconIdx,
          name: desc,
          description: hint,
          images: images,
          point: lngLat,
          sounds: audio,
        ),
      );
      */
      setState(() {
        _showMask = false;
      });
    } catch (e) {
      String err = e.toString();
      debugPrint('Error: $err');
    }
  }

  Future<String> getPoiName({required latLng, name = ''}) async {
    dynamic jsonResponse;

    var url = Uri.parse(
        'https://photon.komoot.io//reverse?lon=${latLng.longitude}&lat=${latLng.latitude}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 2),
          onTimeout: () {
        return name;
      });
      if (response.statusCode == 200) {
        jsonResponse = jsonDecode(response.body);
        if (jsonResponse['features'][0]['properties']['name'] != null) {
          name = jsonResponse['features'][0]['properties']['name'];
        }
        return name;
      } else {
        return name;
      }
    } catch (e) {
      return name;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._addState(this);
    _leadingWidgetController = LeadingWidgetController();

    // CurrentTripItem().clearAll(); // debug

    // NetworkState().initialise();

    /// Have to have a controller instance for each Widget
    /// being controlled, as the controller shares the widgets state
    /// A single controller would then share the state of
    /// all the widgets it controls - not good.

    _bottomNavController = RoutesBottomNavController();
    _directionTileController = DirectionTileController();
    // _expandNotifier = ExpandNotifier(-1);
    _bottomDrawerController.close();

    // _mapController = MapLibreMapController(maplibrePlatform: maplibrePlatform, initialCameraPosition: initialCameraPosition, annotationOrder: annotationOrder, annotationConsumeTapEvents: annotationConsumeTapEvents)
    _locationSettings = getGeolocatorSettings(
        defaultTargetPlatform: TargetPlatform.android, distanceFilter: 5);

    if (_debugging) {
      _debugPositionController = StreamController<Position>();
      _debugRoute = FollowRoute(controller: _debugPositionController);
    }

    try {
      _loadedOK = dataFromDatabase();
      if (CurrentTripItem().routes.isNotEmpty) {
        CurrentTripItem().mapUpdates = MapUpdates.updateAll;
        developer.log(
            'create_trip.dart initState() setting  setting CurrentTripItem().mapUpdates = MapUpdates.updateAll',
            name: '_mapUpdates_');
      } else {
        CurrentTripItem().clearAll(newTripState: TripState.none);
        // CurrentTripItem.reset();
        developer.log('initState CurrentTripItem().routes.isEmpty',
            name: '_resume_');
      }
      _alignPositionStreamController = StreamController<double?>.broadcast();
      _alignDirectionStreamController = StreamController<void>.broadcast();
      fn1 = FocusNode();
      listHeight = -1;
      socket.onConnectError((_) => debugPrint('connect error'));
      socket.onError((data) => debugPrint('Error: ${data.toString()}'));
      // _hasRepainted = false;
      socket.on(
        'message_from_trip',
        (data) {
          TripMessage tripMessage = TripMessage.fromSocketMap(data);
          if (tripMessage.message.isNotEmpty) {
            debugPrint('message: ${tripMessage.message}');
          }

          if (tripMessage.email != Setup().user.email &&
              (tripMessage.message.isNotEmpty ||
                  ['p', 's'].contains(tripMessage.type))) {
            try {
              if (['p', 's'].contains(tripMessage.type) &&
                  tripMessage.lat != 0 &&
                  tripMessage.lng != 0) {
                for (int i = 0; i < _following.length; i++) {
                  //for (Follower follower in _following) {

                  if (_following[i].email == tripMessage.email &&
                      _following[i].email != Setup().user.email) {
                    _following[i] = _following[i].moveFollower(
                        newPosition: [tripMessage.lng, tripMessage.lat]);
                    if (tripMessage.type == 's') {
                      _following[i].manufacturer = tripMessage.manufacturer;
                      _following[i].model = tripMessage.model;
                      _following[i].carColour = tripMessage.carColour;
                      _following[i].registration = tripMessage.registration;
                      _following[i].phoneNumber = tripMessage.phoneNumber;
                      _following[i].position = [
                        tripMessage.lng,
                        tripMessage.lat
                      ];
                      _following[i].accepted = tripMessage.accepted;
                    }
                    if (_following[i].track) {
                      /*    if (_following[i].routeIndex == -1) {
                        _following[i].routeIndex =
                            CurrentTripItem().routes.length;
                        CurrentTripItem()
                            .routes
                            .last
                            .add([tripMessage.lng, tripMessage.lat]);
                      } else {
                        CurrentTripItem()
                            .routes[_following[i].routeIndex]
                            .add([tripMessage.lng, tripMessage.lat]);
                      }
                    */
                    }
                  }
                }
              } else {
                for (int i = 0; i < _following.length; i++) {
                  if (_following[i].email == tripMessage.email) {
                    tripMessage.manufacturer = _following[i].manufacturer;
                    tripMessage.model = _following[i].model;
                    tripMessage.carColour = _following[i].carColour;
                    tripMessage.registration = _following[i].registration;
                    break;
                  }
                }

                CurrentTripItem().tripMessages.add(tripMessage);
                //   showMessages(message: tripMessage);
              }
              setState(() {});
            } catch (e) {
              debugPrint('Error: ${e.toString()}');
            }
          }
        },
      );
      /*
      socket.onConnect((_) {
        socket.emit('trip_join',
            {'token': Setup().jwt, 'trip': CurrentTripItem().groupDriveId});
      });
      */

      if (socket.connected) {
//        socket.emit('trip_join',
//            {'token': Setup().jwt, 'trip': CurrentTripItem().groupDriveId});
      }
    } catch (e) {
      debugPrint('Error initialising Drives: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    if (_positionStream != null) {
      _positionStream!.cancel();
    }
    _alignPositionStreamController.close();
    _alignDirectionStreamController.close();
    _debugPositionController.close();
    fn1.dispose();
    if (socket.connected) {
      socket.close;
    }

    streamSocket.dispose();
    super.dispose();
  }

  ///
  /// Returns the routepoints and the waypoint data for the added waypoint
  /// _SimpleUri (http://10.101.1.150:5000/route/v1/driving/-0.0237985,52.9776561;-0.0237985,52.9776561?steps=true&annotations=true&geometries=geojson&overview=full&exclude=motorway&exclude=trunk&exclude=primary)

  @override
  Widget build(BuildContext context) {
    int initialNavBarValue = 2;

    // micro-nudge to ensure MapLibre refreshes
    // await _mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));

    initialLeadingWidgetValue = [TripState.manual, TripState.editing]
            .contains(CurrentTripItem().tripState)
        ? 1
        : 0;

    return Scaffold(
      backgroundColor: Colors.blue,
      // resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: AppBar(
          key: _appBarKey,
          automaticallyImplyLeading: false,
          leading: LeadingWidget(
            controller: _leadingWidgetController,
            initialValue: initialLeadingWidgetValue,
            value: CurrentTripItem()
                .tripValues
                .leadingWidget, //   initialLeadingWidgetValue,
            onMenuTap: (index) {
              if (index == 0) {
                _leadingWidget(_scaffoldKey.currentState);
              } else {
                CurrentTripItem().onBackPressed();
                _leadingWidgetController.changeWidget(0);
                _bottomDrawerController.setContent(
                    content: BottomDrawerItems.none);
                _bottomDrawerController.close();
                setState(() => ());
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
              onUpdate: (_) =>
                  null)), //(val) => val ? setState(() => ()) : () => ())),
      bottomNavigationBar: RoutesBottomNav(
          key: _bottomNavKey,
          controller: _bottomNavController,
          initialValue: initialNavBarValue,
          onMenuTap: (_) => {}),
      body: FutureBuilder<bool>(
        future: _loadedOK,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            // _building = false;
            return _getPortraitBody();
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
          throw ('Error - FutureBuilder in create_trips.dart');
        },
      ),
      drawerEnableOpenDragGesture: false,
    );
  }

/*
          MLMap(
            key: _mapKey,
            onUpdate: _onMapUpdate,
            onTap: (_, __) => (), //_onTap,
            onIdle: _onIdle,
          ),
{this.onIdle, this.onTap, this.onUpdate, this.mapController
{onIdle, onTap, onUpdate, mapController
*/

// https://drives.motatek.com/static/tiles/{z}/{x}/{y}.pbf
  Future<bool> dataFromDatabase() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      //   mapSingleton = MapSingleton(
      //       onIdle: _onIdle, onUpdate: _onMapUpdate, onTap: (_, __) => ());

      if (Setup().hasLoggedIn) {
        var setupRecords = await getPrivateRepository().recordCount('setup');
        //  _myTripItems = await tripItemFromDb();
        _preferences.avoidMotorways = Setup().avoidMotorways;
        _preferences.avoidFerries = Setup().avoidFerries;
        _preferences.avoidTollRoads = Setup().avoidTollRoads;
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

  double appBarHeight() {
    double abHeight = 200;
    final abKeyContext = _appBarKey.currentContext;
    if (abKeyContext != null) {
      final box = abKeyContext.findRenderObject() as RenderBox;
      abHeight = box.size.height;
      // box.size.bottomRight(origin)
    }
    return abHeight;
  }

  Widget _getPortraitBody() {
    return _handleMap();
    // return Text("hi");
  }

  detailClose() {
    //  debugPrint('resetting _poiDetailIndex');
    if (_poiDetailIndex > -1) {
      _poiDetailIndex = -1;
      setState(() {});
    }
  }

  onPlaceSelect(var position) async {
    CurrentTripItem().tripValues.autoCentre = false;
    getDropdownItems(String query) async {
      _places.clear();
      _places.addAll(await getPlaces(value: query));
      setState(() {});
    }
  }

  /// MapLibre port changes
  ///

  double getMapHeight() {
    double height = 0;
    final bnKeyContext = MapService().mapKey.currentContext;
    // _mapKey.currentContext;
    if (bnKeyContext != null) {
      RenderBox box = bnKeyContext.findRenderObject() as RenderBox;
      height = box.size.height;
    }
    return height;
  }

  Point mapMiddle() {
    Point middle = Point(0, 0);
    Size mSize = mapSize();
    middle = Point(mSize.width / 2, mSize.height / 2);
    return middle;
  }

  Size mapSize() {
    Size mapSize = Size(0, 0);
    final bnKeyContext = MapService().mapKey.currentContext;
    if (bnKeyContext != null) {
      RenderBox box = bnKeyContext.findRenderObject() as RenderBox;
      mapSize = Size(box.size.width, box.size.height);
    }
    return mapSize;
  }

  Widget _handleMap() {
    return RepaintBoundary(
      key: mapKey,
      child: Stack(
        children: [
          mapLibreMap ??
              MLMap(
                //  key: _mapKey,
                onUpdate: _onMapUpdate,
                onTap: (tap, pos) => _onTap(tap, pos), //_onTap,
                onIdle: _onIdle,
                debug: _debugging,
                onMove: _onMove,
              ),
          if (_mapController != null &&
              !CurrentTripItem().tripValues.showProgress)
            Positioned(
              right: 20,
              top: 22,
              child: HandleCTFabs(
                  controller: _mapController!,
                  update: (update) =>
                      update ? setState(() => ()) : null), //_debugUpdate),
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 35),
              child: CurrentTripItem().tripValues.showProgress
                  ? LinearProgressIndicator(
                      minHeight: 10,
                    )
                  : CreateTripChips(
                      tripItem: CurrentTripItem(),
                      createTripController: widget.controller!,
                      leadingWidgetController: _leadingWidgetController,
                      position:
                          chipPosition(), // gets either stream or mapController position
                      onUpdate: (value) =>
                          _executeChipActions(tripActions: value)),
            ),
          ),
          if (CurrentTripItem().tripValues.showTarget &&
              !CurrentTripItem().tripValues.showProgress) ...[
            CustomPaint(
              painter: TargetPainter(
                  top: _mapMiddle.y.toDouble(), //mapMiddle().y.toDouble(),
                  left: _mapMiddle.x.toDouble(), //mapMiddle().x.toDouble(),
                  color:
                      CurrentTripItem().isGoodRoad ? Colors.red : Colors.black),
            )
          ],
          CustomPaint(
            painter: HighlightPainter(
              boundary: _mapSize, // mapSize(),
              proportion: 0.6,
              color: Colors.blueGrey,
            ),
          ),
          BottomDrawer(
            context: context,
            maxHeight: 200,
            //  content: _tripCards,
            globalKey: _scrollKey,
            controller: _bottomDrawerController,
            //  requestClose: closeAndUpdateDrawer,
            imageRepository: _imageRepository,
            onOpened: onOpened,
          ),
          getDirections(_directionsIndex),
        ],
      ),
    );
  }

  /// callback for BottomDrawer object. Is fired when the BottomDrawer.AnimatedContainer has finished its animation.
  /// Value of open is true if the drawer is currently open.
  /// This callback is used to update the map when the user has completed adding data like the trip heading, points of
  /// interest etc.
  onOpened(open) async {
    if (!open) {
      CurrentTripItem().tripActions = TripActions.none;
      developer.log(
          'Bottom drawer closed with mapUpdates: ${CurrentTripItem().mapUpdates}',
          name: '_refresh_');
      if (_mapController != null &&
          CurrentTripItem().mapUpdates != MapUpdates.none) {
        _mapController!.animateCamera(
          CameraUpdate.zoomBy(0.000001),
        );
      }
      if ([TripState.manualStart, TripState.goodRoadStart]
          .contains(CurrentTripItem().tripState)) {
        setState(() => CurrentTripItem().tripState =
            CurrentTripItem().tripValues.isEditing
                ? TripState.editing
                : TripState.manual);
      }
    }
  }

  /// closeAndUpdateDrawer() closes the drawer and refreshes its contents with
  /// the new CurrentTripItem(). This ensures all completed tiles are contracted
  void closeAndUpdateDrawer(bool closed) {
    // _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
    _bottomDrawerController.close();
    // setState(() => _mapMiddle = mapMiddle());
  }

  /// _onMapUpdate() is called by MapLibre, and it defines the controller
  _onMapUpdate(LatLng pos, MapLibreMapController mapController) async {
    developer.log('create_trip.dart _onMapUpdate() called ',
        name: '_mapUpdates_');

    _mapController = mapController;
    // MapService().controller;

    // _mapController ??= mapController;
    CurrentTripItem().mapController = _mapController;
    setState(() {
      _mapSize = mapSize();
      _mapMiddle = mapMiddle();
    });
  }

  _onMove(CameraPosition position) async {
    try {
      _directionTileController.updatePosition();
      if (_following.isNotEmpty) {
        await _mapController!.setGeoJsonSource(
          'streamed-data',
          {
            "type": "FeatureCollection",
            "features": followersToGeoJson(
              followers: _following,
              location: Point(
                position.target.longitude,
                position.target.latitude,
              ),
              debugging: _debugging,
            ),
          },
        );
      }
    } catch (e) {
      developer.log('create_trip.dart error _onMove() : ${e.toString()}',
          name: '_error_');
    }
  }

  onGetDetails(index) {}

  Future<Point> pointAtCentre() async {
    LatLng latLng = _mapController!.cameraPosition!.target;
    Point centre = await _mapController!.toScreenLocation(latLng);
    return centre;
  }

  _onTap(Point tap, LatLng pos) async {
    var foundFeatures;
    try {
      foundFeatures = await _mapController!.queryRenderedFeatures(
          tap as Point<double>, ["planned_routes", "location-icon"], null);
      if (foundFeatures.isNotEmpty) {
        developer.log(
            'create_trip.dart _onTap() features found name: ${foundFeatures.map((f) => 'id: ${f["id"]}  group: ${f["properties"]["group"]}')}',
            name: '_onTap_');
      }
    } catch (e) {
      developer.log('create_trip.dart _onTap() error: ${e.toString()}',
          name: '_onTap_');
    }
  }

  /// Saves the Drive data privately
  /// 1. Ensures description is complete
  /// 2. Saves the map image
  /// 3. Saves the trip data as private Web -> api  Device -> SQLite

  _saveTrip() async {
    if (CurrentTripItem().headerComplete() != 7) {
      _getTripDescriptions();
      developer.log(
          'create_trip.dart _save_trip() CurrentTripItem().headerComplete(): ${CurrentTripItem().headerComplete()}',
          name: '_save_trip_');
      return;
    }
    if (CurrentTripItem().uri.isEmpty) {
      CurrentTripItem().uri = getUuid();
    }
    await _createMapImage();
    await CurrentTripItem().savePrivate();
    CurrentTripItem().tripState = TripState.loaded;
    setState(() => CurrentTripItem().tripValues.editing());
  }

  Future<int> waypointTargetted({required Point point}) async {
    final rect = Rect.fromCenter(
        center: Offset(point.x.toDouble(), point.y.toDouble()),
        width: 10,
        height: 10);
    String layer = CurrentTripItem().isGoodRoad
        ? 'good-road-marker-layer'
        : 'way-marker-layer';

    // _mapController!.queryRenderedFeaturesInRect(rect, layerIds, filter)
    var features =
        await _mapController!.queryRenderedFeaturesInRect(rect, [layer], null);
    if (features.isNotEmpty) {
      debugPrint('feature found!');
      for (int i = 0; i < features.length; i++) {
        if (features[i]['geometry']['type'] == 'Point') {
          return int.parse(features[i]['id']);
        }
      }
    }
    return -1;
  }

  Future<String> goodRoadTargetted({required Point point}) async {
    final rect = Rect.fromCenter(
        center: Offset(point.x.toDouble(), point.y.toDouble()),
        width: 15,
        height: 15);
    // String layer = CurrentTripItem().isGoodRoad ? 'planned_routes' : 'good_roads';
    var features = await _mapController!
        .queryRenderedFeaturesInRect(rect, ['good_roads'], null);
    if (features.isNotEmpty) {
      debugPrint('feature found!');
      for (int i = 0; i < features.length; i++) {
        if (features[i]['geometry']['type'] == 'LineString') {
          return features[i]['id'];
        }
      }
    }
    return '';
  }

  /// updateHighlightedZone() uses MapLibre's setFilter() method to change the filter conditions
  /// on a layer. This avoids having to identify all the visible features, and the decide if they
  /// should be visible.
  /// In this case the objects to be highlighted will be made visible:
  /// The route and good road highlight layer, and their associated shields.
  /// The geoJson objects have to have a min_lat min_lon etc that is calculated by
  /// Mariadb.
  /// It makes sense to put all the highlight-able features under a single layer

  _getTripDescriptions() async {
    _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
    _bottomDrawerController.open(height: 300);
    await Future.delayed(Duration(milliseconds: 500));
    _bottomDrawerController.dockOpenTile();
    //   }
    CurrentTripItem().tripActions = TripActions.none;
  }

  /// Opens the bottomDrawer to add the details of the last added CurrentTripItem().PointOfInterest
  /// _executeChipActions controls the behaviour of the bottom drawer through its controller
  /// The instruction to change the BottomDrawer come from CreateTripChips.onUpdate()
  /// The controller options are:
  ///   Control the open / close state of the drawer
  ///   Change the content of the drawer
  ///
  /// If the trip descriptions or point of interest descriptions are incomplete
  /// the bottom drawer shows the incomplete Expand Tile opened ready for the user to complete
  /// the data.
  /// The data options are:
  ///   1: Tap or drag divider bar: Trip details + points of interest
  ///   2: Point of Interest chip add a point of interest into list above & expand tile for details
  ///   3: Complete trip descriptions

  void _executeChipActions(
      {MyTripActions tripActions = MyTripActions.none}) async {
    //   if (tripActions == MyTripActions.none) {
    //     setState(() => ());
    //     return;
    //   }
    switch (tripActions) {
      case MyTripActions.none || MyTripActions.addWaypoint:
        setState(() => ());
        return;

      case MyTripActions.editTrip:
        setState(() => CurrentTripItem().tripState = TripState.editing);
        return;

      case MyTripActions.saveTrip:
        _saveTrip();
        return;

      case MyTripActions.clearTrip:
        // setState(() => (CurrentTripItem().tripState = TripState.none));
        // CurrentTripItem().mapUpdates = MapUpdates.updateAll;
        // micro-nudge to ensure MapLibre refreshes
        // await _mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
        return;

      case MyTripActions.startManual:
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
        CurrentTripItem().tripActions = TripActions.none;
        CurrentTripItem().tripState = TripState.manualStart;
        return;

      case MyTripActions.addPointOfInterest:
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
        return;

      case MyTripActions.addGoodRoad:
        setState(() => (CurrentTripItem().isGoodRoad = true));
        return;

      /// May be able to combine this with .addPointOfInterest
      case MyTripActions.addGoodRoadDetails:
        _bottomDrawerController.setContent(content: BottomDrawerItems.goodRoad);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
        setState(() => ());
        return;

      case MyTripActions.showSteps:
        _bottomDrawerController.setContent(
            content: BottomDrawerItems.maneuvers);
        _bottomDrawerController.open(height: 300);
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

      case MyTripActions.startTracking:
        await _mapController!.animateCamera(CameraUpdate.zoomTo(14.2));
        setLocationUpdates();
        setState(() => ());
        return;

      case MyTripActions.track:
        setLocationUpdates();
        setState(() => ());
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

  /// _onIdle() updates the LibreMap with any added geoJSON data
  /// The important consideration in structuring the datasources is that
  /// all the data in a datasource has to be updated at the same time so having
  /// separate sources into:
  ///   1 published data from the api
  ///   2 Data the user is adding / editing
  ///   3 Data coming from the streaming of location changes
  /// The data comes from three sources:
  ///   1 CurrentTripItem() - data that is currently being added / edited
  ///     For points of interest the mapUpdates flag is set in the PointOfInterestTile when
  ///     the user has entered sufficient data.
  ///   2 Data  from the cache - api data that's been published - Good Roads Points Of Interest
  ///      i The bounding box is breached - both Good Roads and Points Of Interest
  ///     ii The zoom level changes - Only the Good Roads to ensure correct quality data
  ///   3 The streamed data as a trip is being driven - this will be in conjunction with cache data

  _onIdle() async {
    if (_mapController != null) {
      LatLngBounds bounds = await _mapController!.getVisibleRegion();
      developer.log(
          '_onIdle visibleRegion bounds NE: ${bounds.northeast}  SW: ${bounds.northeast}',
          name: '_bounds');
      double zoom = _mapController!.cameraPosition!.zoom;
      CurrentTripItem().mapController ??= _mapController;
      LatLngBounds? bounds2;
      try {
        bounds2 = await _mapController!.getVisibleRegion();
        developer.log('Bounds: $bounds2', name: "_mapUpdates_");
      } catch (e) {
        developer.log('Bounds: $bounds2', name: "_mapUpdates_");
      }
      try {
        /// STAGE 1
        /// incorporate any published data - has to be got from the cache / api
        _tripRequest ??= TripRequest(
            onUpdated: onUpdated,
            onGetDetails: onGetDetails,
            imageRepository: _imageRepository);
        Map<String, dynamic> geoJson =
            await _tripRequest!.update(bounds: bounds, zoom: zoom);
        if (geoJson['features'].isNotEmpty) {
          await _mapController!.setGeoJsonSource("published-data", geoJson);
        }
        //  _executeChipActions();

        /// STAGE 2
        /// Look for any changes during the creating / editing of the drive
        // Point centre = Point(0, 0);
        developer.log(
            '****  _onIdle() called CurrentTripItem().tripState: ${CurrentTripItem().tripState.name}  CurrentTripItem().mapUpdates: ${CurrentTripItem().mapUpdates.name} ****',
            name: '_mapUpdates_');
        if ([
          TripState.editing,
          TripState.manual,
          TripState.loaded,
          TripState.clearing,
          TripState.goodRoadStart,
        ].contains(CurrentTripItem().tripState)) {
          if (CurrentTripItem().tripState == TripState.editing) {
            // Handle any highlighted features identified by the user.
            // Have to get the mapMiddle in screen coordinates so have to convert the camera.taget LatLng() -> Point()
            Point mapMiddle = await _mapController!
                .toScreenLocation(_mapController!.cameraPosition!.target);
            CurrentTripItem().waypointIndex =
                await waypointTargetted(point: mapMiddle);

            if (CurrentTripItem().waypointIndex > -1) {
              CurrentTripItem().waypointState = WaypointState.remove;
            }
          }
          await CurrentTripItem().updateMapGeoJson();
        } else {
          developer.log(
              'Failed state test for updateMapGeoJson() CurrentTripItem().tripState: ${CurrentTripItem().tripState.name}',
              name: '_mapUpdates_');
        }
        if (CurrentTripItem().tripState == TripState.clearing) {
          setState(() => CurrentTripItem().tripState = TripState.none);
        }

        if (CurrentTripItem().tripActions != TripActions.none) {
          //  _executeChipActions();
          //  CurrentTripItem().tripActions = TripActions.none;
        }

        /// Update the published features that are within the "select fence",
        /// Shows the highlight background for roads + their shields
        /// The factor in fenceFilter is the same as used to generate fence box HighlightPainter()
        /// testFenceFilter(bounds: bounds, jsonData: _geoJson); <-- Very useful

        var filter = fenceFilter(bounds: bounds, proportion: 0.6);
        _mapController!.setFilter("good_roads_highlighted", filter);
        _mapController!.setFilter("route-marker-layer", filter);

        /// Filter waypoints for TripStates manual, editing or goodRoadStart
        filter = tripStateFilter(tripState: CurrentTripItem().tripState);
        _mapController!.setFilter("way-marker-layer", filter);
        _mapController!.setFilter("good-road-way-marker-layer", filter);
      } catch (e) {
        developer.log('_onIdle() error: ${e.toString()}', name: 'error');
      }
      CurrentTripItem().tripValues.position = Point(
          _mapController!.cameraPosition!.target.longitude,
          _mapController!.cameraPosition!.target.latitude);
    }
  }

  Widget cardsList(
      {required List<Card> cards, required ScrollController controller}) {
    Widget scrollList = Text('');
    try {
      if (cards.isNotEmpty) {
        scrollList = ListView.builder(
          controller: controller,
          itemCount: cards.length,
          itemBuilder: (context, index) =>
              cards[index < cards.length ? index : cards.length - 1],
        );
      }
    } catch (e) {
      debugPrint('Error building scrollList ${e.toString()}');
    }
    return scrollList;
  }

  onUpdated(zoom) {
    setState(() => ());
  }

  Point chipPosition() {
    try {
      return Point(_mapController!.cameraPosition!.target.latitude,
          _mapController!.cameraPosition!.target.longitude);
      // _animatedMapController.mapController.camera.center;
    } catch (e) {
      return Point(0, 0);
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

  dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<bool> loadGroup({required String groupDriveId, int status = 2}) async {
    List<Follower> participants = [];
    Follower? myCarInfo;
    try {
      participants = await getDrivers(groupDriveId: groupDriveId, accepted: 2);
    } catch (e) {
      debugPrint('error getting drivers: ${e.toString()}');
    }
    int cIndex = 2;
    _following.clear;

    for (int i = 0; i < participants.length; i++) {
      Follower follower = participants[i];
      cIndex = cIndex < 16 ? ++cIndex : 2;
      if (Setup().user.email == follower.email) {
        myCarInfo = follower;
      }
      try {
        _following.add(
          Follower(
            uri: follower.uri,
            iconColour: cIndex,
            driveId: follower.driveId,
            forename: follower.forename,
            surname: follower.surname,
            phoneNumber: follower.phoneNumber,
            manufacturer: follower.manufacturer,
            model: follower.model,
            carColour: follower.carColour,
            registration: follower.registration,
            email: follower.email,
            position: follower.position,
          ),
        );
        // }
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    }
    if (myCarInfo == null) {
      cIndex = cIndex < 16 ? ++cIndex : 2;
      myCarInfo = Follower(
        forename: Setup().user.forename,
        surname: Setup().user.surname,
        email: Setup().user.email,
        phoneNumber: Setup().user.phone,
        driveName: ' ', // CurrentTripItem().heading,
        iconColour: cIndex,
        position: [_currentPosition.longitude, _currentPosition.latitude],
      );
      _following.add(myCarInfo);
    }
    await carInfo(myCarInfo);

    return true;
  }

  /// _setBottomDrawerDetails() determines what is shown in the bottom drawer
  /// enum TripActions {
  ///  none,            Returns an empty SizedBox
  ///  readOnly,        Returns everything, but in readonly for when driving
  ///  saving,          Used to make the screen-shot work
  ///  saved,
  ///  headingDetail,   Shows just the TripHeading tile in edit mode
  ///  pointOfInterest, Shows the PointOfInterest tile of the just added point of interest in edit mode
  ///  showGroup,       Shows all the group members of a group drive
  ///  showSteps,       Shows all the maneuvers in the current drive
  /// }

  /// closeDrawerCallback() called from trip_header_tile. As it's a simple 3 text-box
  /// entry tile the keyboard.action.done triggers the drawer to close if all 2 fields
  /// are completed

  void closeDrawerCallback(bool close) {
    if (close) {
      _bottomDrawerController.close();
      CurrentTripItem().drawerClosed();
    }
  }

  messageGroup(int index) async {
    return contactDiolog(context: context, socket: socket);
  }

  Future<String> showMessages({required TripMessage message}) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 20),
              child: const Text('Group Drive Message')),
          content: SizedBox(
            width: 150,
            height: 300,
            child: Align(
              alignment: Alignment.topLeft,
              child: TripMessageTile(
                index: -1,
                message: message,
                onEdit: (_) => (),
                onSelect: (_) => (),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Dismiss', style: TextStyle(fontSize: 22)),
              onPressed: () {
                Navigator.pop(context, '');
              },
            ),
          ],
        );
      },
    );
    return '';
  }

  Future<String> carInfo(Follower driver) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        //  Map<String, dynamic> carData = {};
        return AlertDialog(
          title: Text('Drive - ${driver.driveName}',
              style: textStyle(context: context, color: Colors.black, size: 2)),
          titlePadding: EdgeInsets.fromLTRB(30, 30, 0, 0),
          content: SizedBox(
            width: 400,
            height: 300,
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            autofocus: true,
                            initialValue: driver.manufacturer,
                            style: textStyle(
                                context: context, color: Colors.black),
                            decoration: InputDecoration(
                                label: Text('Vehicle manufacturer'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Manufacturer',
                                hintStyle: hintStyle(context: context)),
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.manufacturer = value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: driver.model,
                            decoration: InputDecoration(
                                label: Text('Vehicle model'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Model',
                                hintStyle: hintStyle(context: context)),
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.model = value,
                            style: textStyle(
                                context: context, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: driver.carColour,
                            decoration: InputDecoration(
                                label: Text('Colour'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Colour',
                                hintStyle: hintStyle(context: context)),
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.carColour = value,
                            style: textStyle(
                                context: context, color: Colors.black),
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: driver.registration,
                            decoration: InputDecoration(
                                label: Text('Registration'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Reg No',
                                hintStyle: hintStyle(context: context)),
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.registration = value,
                            style: textStyle(
                                context: context, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            style: textStyle(
                                context: context, color: Colors.black),
                            initialValue: driver.phoneNumber,
                            decoration: InputDecoration(
                                label: Text('Mobile'),
                                labelStyle: labelStyle(context: context),
                                border: OutlineInputBorder(),
                                hintText: 'Mobile phone number',
                                hintStyle: hintStyle(context: context)),
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) => driver.phoneNumber = value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok', style: TextStyle(fontSize: 22)),
              onPressed: () async {
                _currentPosition = await Geolocator.getCurrentPosition();
                driver.position = [
                  _currentPosition.longitude,
                  _currentPosition.latitude
                ];
                await sendDriverDetails(driver);
                if (!socket.connected) {
                  socket.connect();
                }
                if (socket.connected) {
                  socket.emit('trip_join', {
                    'token': Setup().jwt,
                    'trip': ' ', // CurrentTripItem().groupDriveId,
                    'message': '',
                    'make': driver.manufacturer,
                    'model': driver.model,
                    'colour': driver.carColour,
                    'reg': driver.registration,
                    'phone': driver.phoneNumber,
                    'lat': _currentPosition.latitude,
                    'lng': _currentPosition.longitude,
                  });
                } else {
                  debugPrint('Socket not connected');
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(fontSize: 22)),
              onPressed: () {
                Navigator.pop(context, '');
              },
            ),
          ],
        );
      },
    );
    return '';
  }

  Future<void> deleteTrip(int index) async {
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage:
            ' ', // CurrentTripItem().heading, // _myTripItems[index].heading,
        okValue: index,
        callback: onConfirmDeleteTrip);
  }

  void onConfirmDeleteTrip(int value) {
    debugPrint('Returned value: ${value.toString()}');
    if (value > -1) {
      // int driveId = _myTripItems[value].driveId;
      //   int driveId = CurrentTripItem().driveId;
      //   getPrivateRepository().deleteDriveLocal(driveId: driveId);
      CurrentTripItem().clearAll();
      // setState(() => _myTripItems.removeAt(value));
    }
  }

  Future getImage(ImageSource source, PointOfInterest poi) async {
    // XFile _image;
    final picker = ImagePicker();

    await picker.pickImage(source: source, imageQuality: 10).then((pickedFile) {
      setState(
        () {
          if (pickedFile != null) {
            poi.images =
                "${poi.images},{'url': ${pickedFile.path}, 'caption':}";
          }
        },
      );
    });
  }

  /// _trackingState
  /// Sets tracking on if off
  /// Clears down the CurrentTripItem().routes

  /// Uses Geolocator.getPositionStream to get a stream of locations. Triggers posotion update
  /// every 10M
  /// must use _positionStream.cancel() to cancel stream when no longer reading from it

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
                .loadMyTripItem(name: _debuggingRoute);
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
          _positionStream =
              Geolocator.getPositionStream(locationSettings: _locationSettings)
                  .listen(updatePosition);
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
      developer.log('Stream error: ${e.toString()}', name: '_stream_');
    }
  }

  void updatePosition(position) async {
    _currentPosition = position;
    _speed = position.speed * 3.6 / 8 * 5; // M/S -> MPH

    LatLng pos = LatLng(position.latitude, position.longitude);

    if (_debugging) {
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
              _following[i] = _following[i].moveFollower(
                newPosition:
                    _debugRoute.getPositionAt(index - (jump * (i + 1))),
              );
            } else {
              break;
            }
          }
        } catch (e) {
          debugPrint('Error setting followin ${e.toString()}');
        }
      }
    }

// /*
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
    } else if (CurrentTripItem().tripState == TripState.tracking &&
        CurrentTripItem().tripValues.lastPosition.y != 0) {
      try {
        double distance = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            CurrentTripItem().tripValues.lastPosition.y.toDouble(),
            CurrentTripItem().tripValues.lastPosition.x.toDouble());
        if (distance > 1000) {
          CurrentTripItem().routes.last.waypoints.add(Waypoint(
              value: CurrentTripItem().routes.last.waypoints.length + 1));
          if (CurrentTripItem().isGoodRoad) {
            CurrentTripItem().goodRoads.last.waypoints.add(Waypoint(
                value: CurrentTripItem().goodRoads.last.waypoints.length + 1));
          }
        }
        CurrentTripItem().routes.last.lines.add([pos.longitude, pos.latitude]);

        await _mapController!.setGeoJsonSource('route-data', {
          "type": "FeatureCollection",
          "features": routesToGeoJson(),
        });

        if (CurrentTripItem().isGoodRoad) {
          CurrentTripItem()
              .goodRoads
              .last
              .lines
              .add([pos.longitude, pos.latitude]);
          await _mapController!.setGeoJsonSource('good-road-data', {
            "type": "FeatureCollection",
            "features": goodRoadsToGeoJson(),
          });
        }

        developer.log(
            'Distance from start point in CreateTrip: ${distance * metersToMiles}',
            name: '_tracking');
      } catch (e) {
        developer.log('Error: ${e.toString()}', name: '_tracking_');
      }
    }

    CurrentTripItem().tripValues.lastPosition =
        Point(pos.longitude, pos.latitude);
    CurrentTripItem().tripValues.heading = position.heading;
    CurrentTripItem().mapUpdates = MapUpdates.followers;
    _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
    setState(() => getDirectionsIndex());
    /*
    if (CurrentTripItem().tripState == TripState.following &&
        maneuverIndex != _directionsIndex) {
      developer.log(
          '_directionsIndex: {_directionsIndex}  maneuverIndex: $maneuverIndex',
          name: '_maneuvers_');
    }
    */
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

  locationLatLng(pos) {
    setState(() {});
  }

  routeTapped(routes, details) {
    if (details != null) {
      setState(() {});
    }
  }

  expandChange(var details) {
    if (details != null) {
      setState(
        () {
          CurrentTripItem().tripValues.pointOfInterestIndex = details;
        },
      );
    }
  }

  iconButtonTapped(var details) {
    /*
    if (CurrentTripItem().tripValues.pointOfInterestIndex > -1) {
      _animatedMapController.animateTo(
          dest: CurrentTripItem()
              .pointsOfInterest[
                  CurrentTripItem().tripValues.pointOfInterestIndex]
              .point);
    }
    */
  }

  removePointOfInterest(var details) {
    /*
    if (CurrentTripItem().tripValues.pointOfInterestIndex > -1) {
      CurrentTripItem().removePointOfInterestAt(
          CurrentTripItem().tripValues.pointOfInterestIndex);
    }
  */
  }

  routeMissed(var details) {
    if (details != null) {
      setState(() {
        debugPrint('Route missed');
      });
    }
  }

  /// getMapImage()
  /// Removes the ActionChips
  /// Takes map image
  /// Saves map image
  /// Sets the_CreateTripState to TripState.editing

  _createMapImage({int delay = 1}) async {
    if (CurrentTripItem().mapImage == null) {
      try {
        developer.log('create_trip.dart 2798 calling setState()',
            name: '_keyboard_');
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
        final mapBoundary =
            mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        CurrentTripItem().mapImage = await mapBoundary.toImage();
        await Future.delayed(Duration(seconds: 1));
        String url = await getPrivateRepository().saveImageLocal(
            image: CurrentTripItem().mapImage as ui.Image,
            driveUri: CurrentTripItem().uri);
        CurrentTripItem().tripValues.showProgress = false;
        CurrentTripItem().images = addImageToJSONString(
            currentJSONString: CurrentTripItem().images, newUrl: url);
      } catch (e) {
        developer.log('Error _createMapImage: ${e.toString()}');
      }
    }
    return CurrentTripItem().mapImage;
  }

  bool getTripDetails({bool prompt = false}) {
    if (CurrentTripItem().title.isEmpty) {
      if (prompt) {
        Utility().showConfirmDialog(context, "Can't save - more info needed",
            "Please enter what you'd like to call this trip.");
      }
      developer.log('Drawer.open(height: 300) called @ 2598', name: '_d_open');
      _bottomDrawerController.open(height: 300); // height of opened ExpandTile
      _opened = false;
      CurrentTripItem().tripActions = TripActions.headingDetail;
      fn1.requestFocus();
      //  });
    }
    return false;
  }
}

/// Example of how to incorporate State into a function outside the main class
/// the important part is passing the BuildContext and setState to lower functions...

Future openDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Route waypoints'),
          content: const TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: 'Enter text'),
          ),
          actions: [
            TextButton(
              onPressed: submit(context, setState),
              child: const Text('Submit'),
            )
          ],
        ),
      ),
    );

submit(BuildContext context, setState) {
  Navigator.of(context).pop();
  setState(() {});
}

_leadingWidget(context) {
  return context?.openDrawer();
}
