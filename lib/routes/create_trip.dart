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
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:maplibre_gl/maplibre_gl.dart'; // hide LatLng;

// MapLibreMapController? _mapController;
BottomDrawerController _bottomDrawerController = BottomDrawerController();

/*
This might well be a good path to follow as it uses Flutter_maps

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

class CurrentPosition {
  UserLocation? location;
  Position? position;
  late double latitude;
  late double longitude;
  late double heading;
  late int speed;

  CurrentPosition(
      {this.location,
      this.position,
      this.latitude = 0,
      this.longitude = 0,
      this.heading = 0,
      this.speed = 0}) {
    if (location != null) {
      latitude = location!.position.latitude;
      longitude = location!.position.longitude;
      speed = (location!.speed! * metersToMiles * 60 * 60).toInt();
      if (location!.heading != null) {
        heading = location!.heading!.trueHeading ?? 0;
      }
    } else if (position != null) {
      latitude = position!.latitude;
      longitude = position!.longitude;
      speed = (position!.speed * metersToMiles * 60 * 60).toInt();
      heading = position!.heading;
    }
  }
  LatLng get latLng => LatLng(latitude, longitude);
  Point get point => Point(longitude, latitude);
  List<double> get list => [longitude, latitude];
  //int get speed => speed ?? 0;
}

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
      debugPrint("Can't update CreateTrip state values: ${e.toString()}");
    }
  }

  void updateArguements({required TripArguments arguments}) {
    try {
      _createTripState?.updateArguments(arguments: arguments);
    } catch (e) {
      debugPrint("Can't update the arguments: ${e.toString()}");
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

/// OVERALL STRUCTURE
/// 1 CurrentTripItem - singleton that looks after the persistent data - routes, waypoints etc
///   CurrentTripItem is changed first as many of the map updates depend on previously entered
///   data - Clear Trip Extend Start etc.
///
/// 2 MapService - singleton that looks after the map display. Requests for the map to change
///   - are effected by posting MapRequests into the updateRequest() method. These requests
///     are initiated by the ActionChips
///
///
///     ActionChip -> CurrentTripItem() -> MapService()
///   MapService is also controlled by the FABS which change the MapCenter, Zoom etc.
///
///   the MapRequest is actioned on the onIdle and are changes mage to the geoJson
///   MapService also actions any immediate requests like changing position and zoom
///
///
///
/// CreateTripChips()
///   Displays the appropriate chips for the options the user needs based on the tripStates held in CurrentTripItem
///   Updates the map CurrentTripItem() singleton based on the chip just pressed
///   Returns to CreateTrip() page the action just taken through the MyTripAction Enum
///
///   CreateTripChip().onChipTap() ->
///       update CurrentTripItem() -> CreateTripChips().onUpdate ->
///       _executeChipActions(MyTripActions) -> update Drawers()
///
///

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
  //late final SideDrawerController
  //    _sideDrawerController; // = SideDrawerController();
  final GroupMessagesController groupMessagesController =
      GroupMessagesController();
  bool isVisible = false;
  PopupValue popValue = PopupValue(-1, '', '');
  final navigatorKey = GlobalKey<NavigatorState>();
  List tripItems = [];
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
  CurrentPosition _userPosition = CurrentPosition();
  int positionUpdates = 0;
  PositionUpdate _positionUpdate = PositionUpdate();
  bool _resized = false;
  bool _styleLoaded = false;
//  bool _repainted = false;
  // DateTime _start = DateTime.now();
  double _speed = 0.0;
  int insertAfter = -1;
  int _poiDetailIndex = -1;
  var moveDelay = const Duration(seconds: 2);
  int highlightedIndex = -1;
  final List<Follower> _following = [];
  final List<MyTripItem> _myTripItems = [];
  // late LocationSettings _locationSettings;
  late final StreamController<double?> _alignPositionStreamController;
  late final StreamController<void> _alignDirectionStreamController;
  late final LeadingWidgetController _leadingWidgetController;
  late final DirectionTileController _directionTileController;
  late final StreamController<Position> _debugPositionController;
  late final FollowRoute _debugRoute;
  // late final SideDrawer _sideDrawer;
  int initialLeadingWidgetValue = 0;
  final List<Place> _places = [];
  String wpId = '';
  String grId = '';
  // late final MLMap _mapLibreMap;
  String images = '';

  int _triggered = 0;
  int _onIdleCalled = 0;
  int _webAppBarSelected = 0;
  final bool _debugging = false; //true; //false; //true;
  final String _debuggingRoute = ''; // 'Debug'; // ''; //'Debug';

  UserLocation? useLocation;
  TripArguments? _tripArguments;
  DrivesRequest? _drivesRequest;

  StreamSocket streamSocket = StreamSocket();
  sio.Socket socket = sio.io(urlBase, <String, dynamic>{
    // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
    'transports': ['websocket'], // Specify WebSocket transport
    'autoConnect': false, // Prevent auto-connection
  });

  TripRequest? _tripRequest;
  Point _mapMiddle = Point(0, 0);
  Size _mapSize = Size(0, 0);
  bool _idleCalled = false;
  Point _pointAtCentre = Point(0, 0);

  final ImageRepository _imageRepository = ImageRepository();

/*
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
*/
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
    //   _locationSettings = getGeolocatorSettings(
    //       defaultTargetPlatform: TargetPlatform.android,
    //       distanceFilter: 5,
//        kIsWeb: kIsWeb);

    if (_debugging) {
      _debugPositionController = StreamController<Position>();
      _debugRoute = FollowRoute(controller: _debugPositionController);
    }

    try {
      _loadedOK = dataFromDatabase();
      if (CurrentTripItem().routes.isNotEmpty) {
        CurrentTripItem().mapUpdates = MapUpdates.updateAll;
      } else {
        CurrentTripItem().clearAll(newTripState: TripState.none);
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
      developer.log(
          'Error CreateTrip().initState() called error: ${e.toString()}',
          name: 'error');
    }
  }

  updateArguments({required TripArguments arguments}) async {
    if (_tripArguments != arguments) {
      if (kIsWeb) {
        MapService().sideDrawerController!.close();
      }
      _tripArguments = arguments; // <--
      await updateTripArguments();
    }
  }
/*
  _onMapIsIdle() {
    if (_tripArguments!.activeChip == 1) {
      _onIdleTrips(forceUpdate: false);
    } else {
      // _onIdle();
    }
  }
*/

/*
  _onIdleTrips({bool forceUpdate = false}) async {
    if (_styleLoaded && !_idleCalled) {
      Map<String, dynamic> geoJson = {};
      try {
        LatLngBounds bounds = await MapService().controller!.getVisibleRegion();
        double zoom = MapService().controller!.cameraPosition!.zoom;
        /*  Map geoJson = await _drivesRequest!.update(
            bounds: bounds,
            zoom: zoom,
            force: forceUpdate); //  _bottomDrawerController.itemsCount() == 0);
        _idleCalled = true;
      */
        /*
        if (geoJson.isNotEmpty) {
          tripItems = _drivesRequest!.getDrivesData();
          if (kIsWeb) {
            try {
              MapService().sideDrawerController!.setContent(
                  content: BottomDrawerItems.drives,
                  drawerItems: tripItems as List<Widget>);
              MapService().sideDrawerController!.close();
            } catch (e) {
              developer.log('Error setting SideDrawer data: ${e.toString()}',
                  name: '_map_');
            }
          } else {
            _bottomDrawerController.setContent(
                content: BottomDrawerItems.drives, drawerItems: tripItems);
          }
        }
        */
        if (geoJson.isNotEmpty) {
          if (geoJson['features'] != null) {
            await MapService().controller!.setGeoJsonSource(
                "published-data",
                Map<String, dynamic>.from(
                    geoJson)); //"published-data", geoJson);
          }
        }

/*
        var filter = fenceFilter(bounds: bounds, proportion: 0.6);
        _mapController!.setFilter("route-marker-layer", filter);
        _mapController!.setFilter("good_roads_highlighted", filter);
        // _mapController!.setFilter("good-road-marker-layer", filter);
        _mapController!.setFilter("roads_highlighted", filter);
        */
        await MapService()
            .controller!
            .animateCamera(CameraUpdate.zoomBy(0.000001));
      } catch (e) {
        developer.log(
            '_onIdleTrips() error: ${e.toString()} ${geoJson.toString()}',
            name: 'error');
      }
    }
    // _idleCalled = false;
    return;
  }
*/
  @override
  void dispose() {
    // if (_positionStream != null) {
    _positionStream?.cancel();
    //  }
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

    /// When the create_trip widget is called the caller can pass arguments from my_trips.dart and group_drives.dart
    /// This allows the map to be positioned and zoomed correctly
    /// The activeChip is to set the WebAppBar route button correctly. If the form is built without any arguments
    /// then the user has clicked the Explore button so the Explore ActionChip is active. If the have clicked
    /// Published or Favourites then the Explore route is navigated to, but the chips should reflect Published and
    /// Favourites respectively, which is handed over with the Navigate arguments.

    if (ModalRoute.of(context)!.settings.arguments != null) {
      TripArguments args =
          ModalRoute.of(context)!.settings.arguments as TripArguments;
      if (args.changedScreen) {
        updateArguments(arguments: args);
        args.changedScreen =
            false; // <-- ensure future repaints show the updated activeChip value
      }
    }

    initialLeadingWidgetValue = [TripState.manual, TripState.editing]
            .contains(CurrentTripItem().tripState)
        ? 1
        : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      /*   appBar: kIsWeb
          ? null
          : AppBar(
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
                    setState(() {});
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
            */
      //(val) => val ? setState(()  {}) : () {})),
      /*
      bottomNavigationBar: kIsWeb
          ? null
          : RoutesBottomNav(
              key: _bottomNavKey,
              controller: _bottomNavController,
              initialValue: initialNavBarValue,
              onMenuTap: (_) => {}),
      */
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        behavior: HitTestBehavior
            .translucent, // 4. Tell Flutter to pass touches through
        child: Text('Debug'),
      ),

      /*FutureBuilder<bool>(
        future: _loadedOK,
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
          throw ('Error - FutureBuilder in create_trips.dart');
        },
      ),
*/
      //     drawerEnableOpenDragGesture: false,
    );
  }

// https://drives.motatek.com/static/tiles/{z}/{x}/{y}.pbf

  Future<bool> dataFromDatabase() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();

      if (Setup().hasLoggedIn) {
        var setupRecords = await getPrivateRepository().recordCount('setup');
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

  detailClose() {
    if (_poiDetailIndex > -1) {
      _poiDetailIndex = -1;
      setState(() {});
    }
  }

/*
  onPlaceSelect(var position) async {
    CurrentTripItem().tripValues.autoCentre = false;
    getDropdownItems(String query) async {
      _places.clear();
      _places.addAll(await getPlaces(value: query));
      setState(() {});
    }
  }*/
  /// MapLibre port changes
  ///

  updateTripArguments() async {
    try {
      switch (_tripArguments!.appState) {
        case AppState.myTrips:
          {
            // _onIdle();
            _myTripItems.clear();
            _myTripItems.addAll(await getPrivateRepository().loadMyTripItems());
            try {
              await MapService().sideDrawerController!.setContent(
                  content: BottomDrawerItems.favourites,
                  drawerItems: _myTripItems as List<Widget>);
              Future.delayed(Duration(milliseconds: 200));
              setState(
                  () => MapService().sideDrawerController!.open(width: 0.4));
            } catch (e) {
              developer.log(
                  'Error setting sideDrawer contents: ${e.toString()}',
                  name: 'error');
            }
          }
        case AppState.trips:
          {
            _drivesRequest ??= DrivesRequest(onUpdated: (_) {});
            _idleCalled = false;
            //    await _onIdleTrips(forceUpdate: true);
          }
        default:
          {
            if (Setup().hasLoggedIn) {
              var setupRecords =
                  await getPrivateRepository().recordCount('setup');
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
          }
      }
    } catch (e) {
      developer.log('Error calling updateArguments()  ${e.toString()}',
          name: 'error');
    }
    return;
  }

  Widget _getPortraitBody() {
    _mapSize = MapService().mapSize();
    _mapMiddle = MapService().mapMiddle;
    _tripArguments ??=
        TripArguments(activeChip: 2, appState: AppState.createTrip);
    // double start = 0;
    Future<bool>;
    try {
      return Text('Hi');
      /* Stack(children: [
         if (MapService().controller != null)
                 Align(
              // <-- Only do editing in "Explore" mode
              alignment: Alignment.topRight,
              child: HandleCTFabs(
                  controller: MapService().controller!,
                  sbController: MapService().statusBarController,
                  zfController: MapService().zoomFabController,
                  update: (update) => update ? setState(() {}) : null),
            ), //_debugUpdate),

            if (_tripArguments!.activeChip == 2) ...[
              Align(
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
                          widget.controller ?? CreateTripController(),
                      leadingWidgetController: _leadingWidgetController,
                      position:
                          chipPosition(), // gets either stream or mapController position
                      onUpdate: (value) =>
                          _executeChipActions(tripActions: value),
                    ),
                  ),
                ),
              ),
              if (CurrentTripItem().tripValues.showTarget &&
                  !CurrentTripItem().tripValues.showProgress) ...[
                CustomPaint(
                  painter: TargetPainter(
                      top: _mapMiddle.y.toDouble(), //mapMiddle().y.toDouble(),
                      left: _mapMiddle.x.toDouble(), //mapMiddle().x.toDouble(),
                      color: CurrentTripItem().isGoodRoad
                          ? Colors.red
                          : Colors.black),
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
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
              if (_tripArguments!.activeChip == 1) ...[
                CustomPaint(
                  painter: HighlightPainter(
                    boundary: _mapSize, // mapSize(),
                    proportion: 0.6,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ],
          if (!kIsWeb)
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

          /// getDirections shows the turn-by-turn navigation details
          getDirections(_directionsIndex),

          /// The StatusBar allows the showing of messages and the KeyScale.
          /// At the moment the KeyScale is always right justified.
          /// There is only one BarMessage widget catered for
          /// ToDo: Allow more flexible status bar messages

          if (kIsWeb) ...[]
          
        ],
      );
      
      */
    } catch (e) {
      return Center(child: Text('Bugger: ${e.toString()}'));
    }
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

  /// _onStyleLoaded() is triggered after _onMapUpdate() so the _mapController should be instantiated
  ///

/*
  _onStyleLoaded() async {
    _styleLoaded = true;
    double zoom = 12;
    if (MapService().controller != null) {
      if (_tripArguments != null) {
        zoom = _tripArguments!.appState == AppState.trips ? 8 : zoom;
      }
      await MapService().controller!.moveCamera(
            CameraUpdate.newLatLngZoom(MapService().currentPosition, zoom),
          );
      _idleCalled = false;
      _onIdleTrips(forceUpdate: true);
    }

    // _onIdleTrips();
  }
*/
  /// closeAndUpdateDrawer() closes the drawer and refreshes its contents with
  /// the new CurrentTripItem(). This ensures all completed tiles are contracted
  void closeAndUpdateDrawer(bool closed) {
    _bottomDrawerController.close();
  }

  /// _onMapUpdate() is called by MapLibre, and it defines the controller
  /// It is called before the style has been loaded.
/*
  _onMapUpdate(LatLng pos) async {
    CurrentTripItem().mapController = MapService().controller;
    //  MapService().sideDrawer?.mapController =
    //     MapService().controller!;

// Published data required
    if (_tripArguments!.activeChip == 1) {
    } else if (_tripArguments != null) {
      if (_tripArguments!.origin == 'db') {
        Point start = CurrentTripItem().maneuvers.first.point;
        LatLng pos = LatLng(start.y.toDouble(), start.x.toDouble());
        MapService().setPosition(latLng: pos);
        await MapService().controller!.animateCamera(
              CameraUpdate.newLatLngZoom(
                MapService().currentPosition,
                15.0,
              ),
            );
        switch (_tripArguments!.appState) {
          case AppState.myTrips:
            {
              MapService()
                  .sideDrawerController!
                  .setContent(content: BottomDrawerItems.trip);
            }
          case AppState.trips:
            {
              _idleCalled = false;
              _onIdleTrips();
              //_sideDrawerController.setContent(content: BottomDrawerItems.trip);
            }
          default:
            {
              MapService()
                  .sideDrawerController!
                  .setContent(content: BottomDrawerItems.trip);
            }
        }

        //  await _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
        //  await _mapController!.animateCamera(CameraUpdate.zoomTo(13));
      } else if (![AppState.createTrip] //, AppState.myTrips]
          .contains(_tripArguments!.appState)) {
        await updateTripArguments();
      }
    }

    setState(() {
      _mapSize = MapService().mapSize();
      _mapMiddle = MapService().mapMiddle;
    });
  }
  */
/*
  _updateLocation(UserLocation location) async {
    if ([TripState.following, TripState.tracking]
        .contains(CurrentTripItem().tripState)) {
      //  _currentPosition = await Geolocator.getCurrentPosition();
      //  CurrentPosition position = CurrentPosition(position: _currentPosition);
      // Position
      // updateUserPosition(position);
    }
  }

  _onMove(CameraPosition position) async {
    try {
      if (CurrentTripItem().tripState == TripState.following) {
        _directionTileController.updatePosition();
      }
      if (_following.isNotEmpty) {
        await MapService().controller!.setGeoJsonSource(
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
          name: 'error');
    }
    setState(()  {});
  }
*/
  onGetDetails(index) {}

  Future<Point> pointAtCentre() async {
    LatLng latLng = MapService().controller!.cameraPosition!.target;
    Point centre = await MapService().controller!.toScreenLocation(latLng);
    return centre;
  }
/*
  _onTap(Point tap, LatLng pos) async {
    var foundFeatures;
    try {
      foundFeatures = await MapService().controller!.queryRenderedFeatures(
          tap as Point<double>, ["planned_routes", "location-icon"], null);
    } catch (e) {
      developer.log('create_trip.dart _onTap() error: ${e.toString()}',
          name: 'error');
    }
  }
*/
  /// Saves the Drive data privately
  /// 1. Ensures description is complete
  /// 2. Saves the map image
  /// 3. Saves the trip data as private Web -> api  Device -> SQLite

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

  Future<int> waypointTargetted({required Point point}) async {
    final rect = Rect.fromCenter(
        center: Offset(point.x.toDouble(), point.y.toDouble()),
        width: 10,
        height: 10);
    String layer = CurrentTripItem().isGoodRoad
        ? 'good-road-marker-layer'
        : 'way-marker-layer';

    // _mapController!.queryRenderedFeaturesInRect(rect, layerIds, filter)
    var features = await MapService()
        .controller!
        .queryRenderedFeaturesInRect(rect, [layer], null);
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
    var features = await MapService()
        .controller!
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

  /// This carries out the requests from CreateTripActionChips()
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

/*
  _onIdle() async {
    if (MapService().controller != null) {
// handle Published state
      if (_tripArguments!.activeChip == 1) {
        try {
          LatLngBounds bounds =
              await MapService().controller!.getVisibleRegion();
          double zoom = MapService().controller!.cameraPosition!.zoom;
          /*   Map geoJson = await _drivesRequest!
              .update(bounds: bounds, zoom: zoom, force: !_idleCalled);
          _idleCalled = true;
      
          if (geoJson.isNotEmpty) {
            developer.log('Rendering geoJson for published data',
                name: '_content_');
            await MapService().controller!.setGeoJsonSource(
                'published-data', Map<String, dynamic>.from(geoJson));
          } else {
            developer.log('Missing _drivesRequest.geoJson for published data',
                name: '_content_');
          }
        */
          /*
          List tripItems = _drivesRequest!.getDrivesData();
          developer.log('Setting bottom drawer items 1498', name: '_drawer_');
          MapService().sideDrawerController!.setContent(
              content: BottomDrawerItems.drives,
              drawerItems: tripItems as List<Widget>);
        */
        } catch (e) {
          developer.log('Error setting published data: ${e.toString()}',
              name: 'error');
        }
// handle Explore and Favourites
      } else
      // When tracking or following don't need any published or favourites data
      if (_tripArguments!.activeChip == 2 &&
          [TripState.tracking, TripState.following]
              .contains(CurrentTripItem().tripState)) {
        await _positionUpdate.update();
      } else {
        LatLngBounds bounds = await MapService().bounds;
        String debugString = '_onIdle() called x ${_onIdleCalled++}';
        MapService().statusBarController!.refresh();
        double zoom = MapService().controller!.cameraPosition!.zoom;
        Point centrePoint = await pointAtCentre();
        CurrentTripItem().mapController ??= MapService().controller;
        LatLngBounds? bounds2;
        try {
          bounds2 = await MapService().controller!.getVisibleRegion();
        } catch (e) {
          developer.log('Error _onIdle() Bounds: $bounds2', name: 'error');
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
            await MapService()
                .controller!
                .setGeoJsonSource("published-data", geoJson);
          }
          //  _executeChipActions();

          /// STAGE 2
          /// Look for any changes during the creating / editing of the drive
          /// Point centre = Point(0, 0);
          if ([
            TripState.editing,
            TripState.manual,
            TripState.tracking,
            TripState.loaded,
            TripState.clearing,
            TripState.goodRoadStart,
          ].contains(CurrentTripItem().tripState)) {
            if (CurrentTripItem().tripState == TripState.editing) {
              // Handle any highlighted features identified by the user.
              // Have to get the mapMiddle in screen coordinates so have to convert the camera.taget LatLng() -> Point()
              Point mapMiddle = await MapService().controller!.toScreenLocation(
                  MapService().controller!.cameraPosition!.target);
              CurrentTripItem().waypointIndex =
                  await waypointTargetted(point: mapMiddle);

              if (CurrentTripItem().waypointIndex > -1) {
                CurrentTripItem().waypointState = WaypointState.remove;
              }
            }
            await CurrentTripItem().updateMapGeoJson();
          }
          if (CurrentTripItem().tripState == TripState.clearing) {
            _pointAtCentre = centrePoint;
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
          MapService().controller!.setFilter("good_roads_highlighted", filter);
          MapService().controller!.setFilter("route-marker-layer", filter);

          /// Filter waypoints for TripStates manual, editing or goodRoadStart but only in Explore mode
          /// which is set when _CreateTripState is built
          if (_tripArguments!.activeChip == 2) {
            filter = tripStateFilter(tripState: CurrentTripItem().tripState);
            MapService().controller!.setFilter("way-marker-layer", filter);
            MapService()
                .controller!
                .setFilter("good-road-way-marker-layer", filter);
          }
        } catch (e) {
          developer.log('_onIdle() error: ${e.toString()}', name: 'error');
        }
        CurrentTripItem().tripValues.position = Point(
            MapService().controller!.cameraPosition!.target.longitude,
            MapService().controller!.cameraPosition!.target.latitude);
        if (centrePoint != _pointAtCentre) {
          setState(() => _pointAtCentre = centrePoint);
        }
      }
      setState(()  {});
    }
    return;
  }
*/
/*
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
    setState(()  {});
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
                onEdit: (_) {},
                onSelect: (_) {},
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

  /// Prostate PSA test Dr/Mr Halsburough 1.7 from 21

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

  Future<void> _createMapImage({int delay = 1}) async {
    if (CurrentTripItem().mapImage == null) {
      try {
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
/*
        if (kIsWeb) {
          sBytes = await _mapController!.takeSnapshot();
          developer.log('${mapBytes.length} bytes returned', name: '_map_');

          //   CurrentTripItem().mapImage!.imageBytes =
          //       await _mapController!.takeSnapshot();
          /*
          String? base64Image = await js.context.callMethod('getMapSnapshot');
          if (base64Image != null) {
            try {
              Uint8List bytes = base64Decode(base64Image.split(',').last);
              bool valid = await isImageValid(uInt8List: bytes);
              developer.log('valid uint8List: $valid', name: '_map_');

              CurrentTripItem().mapImage =
                  ImageInMemory(name: 'map', imageBytes: bytes);
              //   Image temp = Image.network(base64Image);
              //   double? width = temp.width;
              //   developer.log('image width: $width', name: '_map_');
              //  base64Image = base64Image.split(',').last;

              //  ImageInMemory tempImage = ImageInMemory(
              //     name: 'map', imageBytes: base64Decode(base64Image));

              //       CurrentTripItem().mapImage = ImageInMemory(
              //           name: 'map',
              //           imageBytes: base64Decode(base64Image.split(',').last));

              developer.log('got past saving the image', name: '_map_');
/*
              ui.Image? imageMap =
                  ui.Image()   memory(base64Decode(base64Image.split(',').last))
                      as ui.Image;
              if (imageMap != null) {
                ByteData? bytes =
                    await imageMap.toByteData(format: ui.ImageByteFormat.png);

                if (bytes != null) {
                  if (CurrentTripItem().mapImage == null) {
                    CurrentTripItem().mapImage ??= ImageInMemory(
                        name: 'map', imageBytes: bytes.buffer.asUint8List());
                  } else {
                    CurrentTripItem().mapImage!.imageBytes =
                        bytes.buffer.asUint8List();
                  }
                }
              }
              */

              //     Uint8List bytes = base64Decode(base64Image);
              // var bytes = Uint8List.fromList(encoded);

              //   base64Image = base64Image.split(',').last;
              //   var bytes = base64Decode(base64Image);
              //  developer.log('${bytes.length} bytes OK  ??', name: '_map_');
              /*
              if (CurrentTripItem().mapImage == null) {
                ImageInMemory tempImage = ImageInMemory(
                    name: 'map', imageBytes: base64Decode(base64Image));
                CurrentTripItem().mapImage =
                    tempImage; //ImageInMemory(name: 'map');
                //  CurrentTripItem().mapImage!.imageBytes = bytes;
                //  CurrentTripItem().mapImage ??= ImageInMemory(
                //      name: 'map',
                //      imageBytes: bytes); //  utf8.encode(base64Image));
              } else {
                CurrentTripItem().mapImage!.imageBytes = bytes;
              }
              */
              // CurrentTripItem().mapImage!.imageBytes = utf8.encode(base64Image);
            } catch (e) {
              developer.log('Web image capture problem: ${e.toString()}',
                  name: '_map_');
            }
          }
          */
          //globalContext.callMethod('getMapSnapshot');     .context.callMethod('getMapSnapshot');
        } else {
          final mapBoundary = mapKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

          ui.Image? imageMap = await mapBoundary.toImage();
          if (imageMap != null) {
            ByteData? bytes =
                await imageMap.toByteData(format: ui.ImageByteFormat.png);

            if (bytes != null) {
              if (CurrentTripItem().mapImage == null) {
                CurrentTripItem().mapImage ??= ImageInMemory(
                    name: 'map', imageBytes: bytes.buffer.asUint8List());
              } else {
                CurrentTripItem().mapImage!.imageBytes =
                    bytes.buffer.asUint8List();
              }
            }
          }
        } */
      } catch (e) {
        developer.log('Error _createMapImage: ${e.toString()}', name: 'error');
      }
    }
    setState(() => CurrentTripItem().tripValues.showProgress = false);
    return; // CurrentTripItem().mapImage;
  }

  bool getTripDetails({bool prompt = false}) {
    if (CurrentTripItem().title.isEmpty) {
      if (prompt) {
        Utility().showConfirmDialog(context, "Can't save - more info needed",
            "Please enter what you'd like to call this trip.");
      }
      _bottomDrawerController.open(height: 300); // height of opened ExpandTile

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

class PositionUpdate {
  List<double>? routePoint;
  MapLibreMapController? controller;
  PositionUpdate({this.controller, List<double>? routePoint})
      : routePoint = routePoint ?? [];

  Future<void> update() async {
    routePoint ??= [];
    if (routePoint!.isNotEmpty && controller != null) {
      CurrentTripItem().routes.last.lines.add(routePoint!);
      // CurrentTripItem().mapUpdates.add(MapUpdates.routes);
      await controller!.setGeoJsonSource('route-data', {
        "type": "FeatureCollection",
        "features": routesToGeoJson(),
      });
      if (CurrentTripItem().isGoodRoad) {
        CurrentTripItem().goodRoads.last.lines.add(routePoint!);
        await controller!.setGeoJsonSource('good-road-data', {
          "type": "FeatureCollection",
          "features": goodRoadsToGeoJson(),
        });
      }
      routePoint = [];
    }
  }
}
