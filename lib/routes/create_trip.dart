import 'dart:async';
import 'dart:core';
import 'dart:ui' as ui;
import 'package:universal_io/universal_io.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'dart:math';
import '/constants.dart';
import '/classes/classes.dart' hide Position;
import 'package:audioplayers/audioplayers.dart';
import '/screens/screens.dart';
// import '/services/services.dart';
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
//  if (dart.library.html) 'private_storage_api.dart'; // <--- THE MAGIC LINE

MapLibreMapController? _mapController;

BottomDrawerController _bottomDrawerController = BottomDrawerController();

/*
"line-color": "#da2dc28f",  # "#ec5656",
https://techblog.geekyants.com/implementing-flutter-maps-with-osm     /// Shows how to implement markers and group them
https://stackoverflow.com/questions/76090873/how-to-set-location-marker-size-depend-on-zoom-in-flutter-map      
https://pub.dev/packages/flutter_map_location_marker
https://github.com/tlserver/flutter_map_location_marker
https://www.appsdeveloperblog.com/alert-dialog-with-a-text-field-in-flutter/   /// Shows text input dialog
https://fabricesumsa2000.medium.com/openstreetmaps-osm-maps-and-flutter-daeb23f67620  /// tapableRouteLayer  
https://github.com/OwnWeb/flutter_map_tappable_Route/blob/master/lib/flutter_map_tappable_Route.dart
https://pub.dev/packages/flutter_map_animations/example  shows how to animate markers too
https://medium.com/cf-tech/mastering-offline-maps-in-flutter-a-deep-dive-part-2-flutter-map-fmtc-c3c153ecd3c7

VECTOR MAP TILES
The obvious big advantage of vector tiles is that the labels will rotate with the map when navigating
However there appear to be speed issues with vector rendering. One of the
approaches to investigate is the rasterisation of the vector map apart
from any text. Then the text could remain as a vector layer to be correctly
rotated over the rotated raster layer - getting the best of both worlds.
There appear to be moves to improve the vector performance - flutter-gpu 
that implements Impeller - the vector-map-tiles/issues/120 gives an overview

Stadia Maps: https://client.stadiamaps.com/dashboard/#/property/40497/
Joined as a free user just to get vector maps going. It is a chargeable API about £20 / a month
API Key ea533710-31bd-4144-b31b-5cc0578c74d7 
email used james@motatek.com pw rubberduck
Property MotaTrip - object for usage figures


This might well be a good pat to follow as it uses Flutter_maps

https://www.reddit.com/r/openstreetmap/comments/1ew60cw/how_i_learned_to_create_custom_maps_for_my_mobile/
https://openmaptiles.org/docs/generate/create-custom-extract/
https://github.com/maplibre/maputnik/wiki <- map styling


https://docs.maptiler.com/flutter/

https://project-osrm.org/docs/v5.5.1/api/#trip-service
https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames

https://pub.dev/packages/vector_map_tiles

VectorTileLayer(tileProviders: TileProviders(
                    {'openmaptiles': _tileProvider() },
                    ...)
                )

VectorTileProvider _tileProvider() => NetworkVectorTileProvider(
            urlTemplate: 'https://tiles.example.com/openmaptiles/{z}/{x}/{y}.pbf?api_key=$myApiKey',
            // this is the maximum zoom of the provider, not the
            // maximum of the map. vector tiles are rendered
            // to larger sizes to support higher zoom levels
            maximumZoom: 14),


https://github.com/greensopinion/flutter-vector-map-tiles
https://github.com/organicmaps/organicmaps/tree/master/search/pysearch
https://github.com/greensopinion/flutter-vector-map-tiles?tab=readme-ov-file
https://project-osrm.org/docs/v5.5.1/api/#general-options
https://github.com/greensopinion/flutter-vector-map-tiles/issues/120
https://medium.com/flutter/getting-started-with-flutter-gpu-f33d497b7c11

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

/*
  void automatic() {
    try {
      _createTripState?.automatic();
    } catch (e) {
      debugPrint("Can't stop following");
    }
  }
*/

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
      //     _createTripState?.getLocationUpdates();
    } catch (e) {
      debugPrint('Controller error: ${e.toString()}');
    }
  }
/*
  void editing() {
  getLocationUpdates()
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

/* 
class CreateCurrentTripItem().tripValues {
  bool showMask = false;
  bool showTarget = false;
  bool autoCentre = false;
  int leadingWidget = 0;
  String title = '';
  MapHeights mapHeight = MapHeights.full;
  GoodRoad goodRoad = GoodRoad();
  LatLng lastLatLng = LatLng(0, 0);
  LatLng startLatLng = LatLng(0, 0);
  bool setState = true;
}
*/

  final start = TextEditingController();
  final end = TextEditingController();
  // final mapController = MapController();
  late final RoutesBottomNavController _bottomNavController; // =
  final GroupMessagesController groupMessagesController =
      GroupMessagesController();
  bool isVisible = false;
  PopupValue popValue = PopupValue(-1, '', '');
  final navigatorKey = GlobalKey<NavigatorState>();
  // List<Marker> markers = [];
  // List<MyTripItem> _myTripItems = [];
  List<TripItem> tripItems = [];
  int id = -1;
  int userId = -1;
  int type = -1;
  int _directionsIndex = 0;
  double iconSize = 35;
  double _mapRotation = 0;
  late StreamSubscription<Position> _positionStream;
  late Future<bool> _loadedOK;
  // late Future<bool> _groupChecked;
  bool _showMask = false;
  bool _osmIncludingChange = false;
  late FocusNode fn1;
  // CreateCurrentTripItem().tripValues CurrentTripItem().tripValues = CreateCurrentTripItem().tripValues();
  late ui.Size screenSize;
  late ui.Size appBarSize;
  double mapHeight = 250;
  double listHeight = 0;
  final TripPreferences _preferences = TripPreferences();
  // int CurrentTripItem().tripValues.pointOfInterestIndex = -1;
  late Position _currentPosition;
  late CachedVectorTileProvider _cachedProvider; //(delegate: _style.providers);
  int _resizeDelay = 0;
  bool _resized = false;
//  bool _repainted = false;
  // DateTime _start = DateTime.now();
  double _speed = 0.0;
  int insertAfter = -1;
  int _poiDetailIndex = -1;
  //int _poiHighlighted = -1;
  var moveDelay = const Duration(seconds: 2);
  // double _travelled = 0.0;
  int highlightedIndex = -1;
  final List<Follower> _following = [];
  late LocationSettings _locationSettings;
  final _cacheFence = Fence.create();
  //LatLng topRight = const LatLng(0, 0);
  // LatLng bottomLeft = const LatLng(0, 0);
  //LatLng testPos = LatLng(0, 0);
  bool _updateOverlays = true;
  late final ExpandNotifier _expandNotifier;
  // final ScrollController _scrollController = ScrollController();
  TripHeaderController _tripHeaderController = TripHeaderController();
  // final mt.RouteAtCenter _routeAtCenter = mt.RouteAtCenter();
  bool _tripStarted = false;

  late final StreamController<double?> _allignPositionStreamController;
  late final StreamController<void> _allignDirectionStreamController;
  late final LeadingWidgetController _leadingWidgetController;
  late final FloatingTextEditController _floatingTextEditController1;
  late final FloatingTextEditController _floatingTextEditController2;
  late final DirectionTileController _directionTileController;
  //late TileProviders _cachedProviders;
  late final StreamController<Position> _debugPositionController;
  late final FollowRoute _debugRoute;
  int initialLeadingWidgetValue = 0;
  // late AlignOnUpdate _alignPositionOnUpdate;
  //late AlignOnUpdate _alignDirectionOnUpdate;
  final List<Place> _places = [];
  // Map<String, dynamic> _waypointPositions = {};
  String wpId = '';
  String grId = '';

  double _zoom = 13;
//  final _dividerHeight = 35.0;
  // List<LatLng> routePoints = const [LatLng(51.478815, -0.611477)];

  String images = '';
  //  String stadiaMapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';
  //late Style _style;

  // final OsmFeatures _osmFeatures = OsmFeatures(amenities: []);
  // List<PointOfInterest> _pointsOfInterest = [];
  // final List<Marker> _debugMarkers = [];
  final bool _debugging = false; //true;
  final String _debuggingRoute = 'Debug';
  final Directions _directions = Directions();
  ApiActions _apiActions = ApiActions.none;

  Map<String, dynamic> _geoJson = {};

  double _width = 56.0;
  final double _height = 56.0;
  bool _expanded = false;
  bool _pubUpdate = true;
  late bool _hasRepainted;
  StreamSocket streamSocket = StreamSocket();
  sio.Socket socket = sio.io(urlBase, <String, dynamic>{
    // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
    'transports': ['websocket'], // Specify WebSocket transport
    'autoConnect': false, // Prevent auto-connection
  });

  final List<GlobalKey> _scrollToKeys = <GlobalKey>[];
  final GlobalKey _mapKey = GlobalKey();
  TripRequest? _tripRequest;
  List<Card> _tripCards = [];
  Point _mapMiddle = Point(0, 0);
  Size _mapSize = Size(0, 0);

  bool _opened = false;

  Map<String, dynamic> linesMap = {};
  // late MLMap mapLibreMap;
  Widget? _cardList;

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

    _floatingTextEditController1 = FloatingTextEditController();
    _floatingTextEditController2 = FloatingTextEditController();
    _bottomNavController = RoutesBottomNavController();
    _directionTileController = DirectionTileController();
    _expandNotifier = ExpandNotifier(-1);
    _bottomDrawerController.close();

    // _mapController = MapLibreMapController(maplibrePlatform: maplibrePlatform, initialCameraPosition: initialCameraPosition, annotationOrder: annotationOrder, annotationConsumeTapEvents: annotationConsumeTapEvents)
    _locationSettings = getGeolocatorSettings(
        defaultTargetPlatform: TargetPlatform.android, distanceFilter: 5);

    if (_debugging) {
      // _debugPositionController = StreamController<Position>();
      // _debugRoute = FollowRoute(controller: _debugPositionController);
/*
      _debugMarkers.add(
        Marker(
          child: Icon(
            Icons.adb,
            size: 30,
            color: Colors.redAccent,
          ),
          point: LatLng(0, 0),
        ),
      );
*/
    }

    try {
      _loadedOK = dataFromDatabase();
      if (CurrentTripItem().routes.isNotEmpty) {
        CurrentTripItem().mapUpdates = MapUpdates.updateAll;
        developer.log(
            'create_trip.dart initState() setting  setting CurrentTripItem().mapUpdates = MapUpdates.updateAll',
            name: '_mapUpdates_');
      } else {
        CurrentTripItem().clearAll();
        // CurrentTripItem.reset();
        developer.log('initState CurrentTripItem().routes.isEmpty',
            name: '_resume_');
      }
      _allignPositionStreamController = StreamController<double?>.broadcast();
      _allignDirectionStreamController = StreamController<void>.broadcast();
      fn1 = FocusNode();
      listHeight = -1;
      socket.onConnectError((_) => debugPrint('connect error'));
      socket.onError((data) => debugPrint('Error: ${data.toString()}'));
      _hasRepainted = false;
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
                    /*   _following[i] = Follower.moveFollower(
                        follower: _following[i],
                        marker: _following[i].marker,
                        position: LatLng(tripMessage.lat, tripMessage.lng));
                */
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

      socket.onConnect((_) {
        //    socket.emit('trip_join',
        //        {'token': Setup().jwt, 'trip': CurrentTripItem().groupDriveId});
      });

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
    _positionStream.cancel();
    _allignPositionStreamController.close();
    _allignDirectionStreamController.close();
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
    /*
    if (ModalRoute.of(context)?.settings.arguments != null &&
        listHeight == -1) {
      final args = ModalRoute.of(context)!.settings.arguments as TripArguments;
      // CurrentTripItem().load(arguments: args);
      // CurrentTripItem().downloadTiles(style: _style);
      // CurrentTripItem().tripValues.mapHeight = MapHeights.full;
      // CurrentTripItem().redrawMap();

      _tripStarted = false;
      /*
      if (_debugging) {
        for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
          _debugMarkers.add(
            Marker(
              point: CurrentTripItem().maneuvers[i].location,
              child: Icon(Icons.bug_report, color: Colors.pink, size: 15),
            ),
          );
        }
      }
      */

      initialLeadingWidgetValue = CurrentTripItem().tripValues.leadingWidget;
      initialNavBarValue = 2;
    }
    */
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
              onUpdate:
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

// https://drives.motatek.com/static/tiles/{z}/{x}/{y}.pbf
  Future<bool> dataFromDatabase() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();

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
/*
  List<String> getTitles(int i) {
    List<String> result = [];
    if (CurrentTripItem().pointsOfInterest[i].type < 12) {
      result.add(CurrentTripItem().pointsOfInterest[i].description == ''
          ? 'Point of interest - ${poiTypes[CurrentTripItem().pointsOfInterest[i].type]["name"]}'
          : CurrentTripItem().pointsOfInterest[i].description);
      result.add(CurrentTripItem().pointsOfInterest[i].description);
    } else {
      result.add(
          'Waypoint ${i + 1} -  ${CurrentTripItem().pointsOfInterest[i].name}');
      result.add(CurrentTripItem().pointsOfInterest[i].description);
    }
    return result;
  }

  */

  ///
  /// _handleFabs()
  /// Controls the Loading Action Button behavious
  ///

  Column _handleFabs() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (listHeight == 0) ...[
          SizedBox(
            height: appBarHeight() +
                (CurrentTripItem().tripState == TripState.following
                    ? 250
                    : 130),
          ),
          PlaceFinder(
            height: _height,
            width: _width,
            onSelect: (position) => onPlaceSelect(position),
          ),
          const SizedBox(
            height: 10,
          ),
          FloatingChecklist(
            choices: [
              {'Avoid motorways': Setup().avoidMotorways},
              {'Avoid main roads': Setup().avoidAroads},
              {'Avoid ferries': Setup().avoidFerries},
              {'Avoid toll roads': Setup().avoidTollRoads},
              {'Show pubs and bars': Setup().osmPubs},
              {'Show cafes and restaurants': Setup().osmRestaurants},
              {'Show fuel and charging stations': Setup().osmFuel},
              {'Show toilets': Setup().osmToilets},
              {'Show ATMs': Setup().osmAtms},
              {'Show historic sites': Setup().osmHistorical}
            ],
            maxWidth: MediaQuery.of(context).size.width - 40,
            onCheck: (index, value) {
              //         debugPrint('Oncheck index: $index value: $value');
              switch (index) {
                case 0:
                  Setup().avoidMotorways = value;
                  break;
                case 1:
                  Setup().avoidAroads = value;
                  break;
                case 2:
                  Setup().avoidFerries = value;
                  break;
                case 3:
                  Setup().avoidTollRoads = value;
                  break;
                case 4:
                  Setup().osmPubs = value;
                  break;
                case 5:
                  Setup().osmRestaurants = value;
                  break;
                case 6:
                  Setup().osmFuel = value;
                  break;
                case 7:
                  Setup().osmToilets = value;
                  break;
                case 8:
                  Setup().osmAtms = value;
                  break;
                case 9:
                  Setup().osmHistorical = value;
                  break;
              }
              _osmIncludingChange = true;
            },
            onClose: (_) async {
              if (_osmIncludingChange) {
                setState(() => ());
                _osmIncludingChange = false;
              }
            },
          ),
          const SizedBox(
            height: 10,
          ),
          if ([TripState.recording, TripState.following]
              .contains(CurrentTripItem().tripState)) ...[
            const SizedBox(height: 10),
            FloatingTextEdit(
              key: Key('ftegr'),
              focusNode: FocusNode(),
              keyboardType: TextInputType.name,
              controller: _floatingTextEditController2,
              closedIcon: Icons.add_location_alt_outlined,
              openIcon: Icons.add_task_outlined,
              onOpen: (_) => CurrentTripItem().saveState(),
              onClose: (description, audio) => setState(() {
                _addPointOfInterest(
                  -1,
                  -1,
                  15,
                  description,
                  '',
                  30,
                  [_currentPosition.longitude, _currentPosition.latitude],
                  audio,
                );
                CurrentTripItem().tripValues.pointOfInterestIndex =
                    CurrentTripItem().pointsOfInterest.length - 1;
              }),
              fillColor: Colors.white,
              inputBorder: _width > _height ? OutlineInputBorder() : null,
              hint: 'Description to edit later...',
              suffix: IconButton(onPressed: (() => ()), icon: Icon(Icons.mic)),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
          FloatingActionButton(
            onPressed: () async {
              CurrentTripItem().tripValues.autoCentre =
                  !CurrentTripItem().tripValues.autoCentre;
              if (CurrentTripItem().tripValues.autoCentre) {
                if (CurrentTripItem().tripState != TripState.following) {
                  _currentPosition = await Geolocator.getCurrentPosition();
                }
              }
            },
            heroTag: 'mapCentre',
            backgroundColor: Colors.blue,
            shape: const CircleBorder(),
            child: Icon(Icons.my_location,
                color: CurrentTripItem().isTracking
                    ? CurrentTripItem().tripValues.autoCentre
                        ? Colors.white
                        : Colors.grey
                    : Colors.white),
          ),
        ],
      ],
    );
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
    final bnKeyContext = _mapKey.currentContext;
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
    final bnKeyContext = _mapKey.currentContext;
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
          CurrentTripItem().getMap(
            key: _mapKey,
            onUpdate: _onMapUpdate,
            onTap: (_, __) => (), //_onTap,
            onIdle: _onIdle,
          ),
          /*
          MLMap(
            key: _mapKey,
            onUpdate: _onMapUpdate,
            onTap: (_, __) => (), //_onTap,
            onIdle: _onIdle,
          ),
          */
          if (_mapController != null &&
              !CurrentTripItem().tripValues.showProgress)
            Positioned(
              right: 20,
              top: 22,
              child: HandleCTFabs(
                  controller: _mapController!, callback: null), //_debugUpdate),
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
            content: _tripCards,
            globalKey: _scrollKey,
            controller: _bottomDrawerController,
            requestClose: closeAndUpdateDrawer,
            imageRepository: _imageRepository,
            onOpened: onOpened,
          )
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
    // _bottomDrawerController.close();
    // setState(() => _mapMiddle = mapMiddle());
  }

  /// _onMapUpdate() is called by MapLibre, and it defines the controller
  _onMapUpdate(LatLng pos, MapLibreMapController mapController) async {
    developer.log('create_trip.dart _onMapUpdate() called ',
        name: '_mapUpdates_');
    _mapController ??= mapController;
    CurrentTripItem().mapController = _mapController;
    setState(() {
      _mapSize = mapSize();
      _mapMiddle = mapMiddle();
    });

    //  if (CurrentTripItem().mapUpdates != MapUpdates.none) {
    //    await _mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    //  }
  }

  onGetDetails(index) {}

  Future<Point> pointAtCentre() async {
    LatLng latLng = _mapController!.cameraPosition!.target;
    Point centre = await _mapController!.toScreenLocation(latLng);
    return centre;
  }
/*
  _onTap(var tap, LatLng pos) async {
    var foundFeatures;
    try {
      // var point = Point(tap.x.toDouble(), tap.y.toDouble());

      //developer.log(
      // var point = Point(tap.x.toDouble(), tap.y.toDouble());
      // var point = Point(tap.x.toDouble(), tap.y.toDouble());
      //  '_mapMiddle x:${_mapMiddle.x} y:${_mapMiddle.y} tap x:${tap.x} y:${tap.y}  Centre x:${centre.x} y:${centre.y}  MediaQuery x:${MediaQuery.of(context).size.width} y:${MediaQuery.of(context).size.height}',
      //    name: '_center');
      foundFeatures = await _mapController!
          .queryRenderedFeatures(tap, ["planned_routes"], null);
      // .queryRenderedFeatures(tap, ["route-marker-layer"], null);
      if (foundFeatures.isNotEmpty) {
        var tappedFeature = foundFeatures.first;
        var name = tappedFeature['properties']['name'];
        String uri = tappedFeature['id'].substring(0, 32);
        //  _executeChipActions(uri: uri);
      }
    } catch (e) {}
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
/*

  Future<String> routeTargetted({required Point point}) async {
    String id = '';
    final rect = Rect.fromCenter(
        center: Offset(point.x.toDouble(), point.y.toDouble()),
        width: 40,
        height: 40);
    var features = await _mapController!
        .queryRenderedFeaturesInRect(rect, ["planned_routes"], null);
    if (features.isNotEmpty) {
      debugPrint('feature found!');
      for (int i = 0; i < features.length; i++) {
        if (features[i]['geometry']['type'] == 'LineString') {
          return features[i]['id'];
        }
      }
    }
    return id;
  }

  */

  /// updateHighlightedZone() uses MapLibre's setFilter() method to change the filter conditions
  /// on a layer. This avoids having to identify all the visible features, and the decide if they
  /// should be visible.
  /// In this case the objects to be highlighted will be made visible:
  /// The route and good road highlight layer, and their associated shields.
  /// The geoJson objects have to have a min_lat min_lon etc that is calculated by
  /// Mariadb.
  /// It makes sense to put all the highlight-able features under a single layer

/*

  Future<List<Map<String, dynamic>>> featuresTargetted() async {
    List<Map<String, dynamic>> features = [];
    Size fence = mapSize();
    Point middle = mapMiddle();
    final rect = Rect.fromCenter(
        center: Offset(middle.x.toDouble(), middle.y.toDouble()),
        width: fence.width,
        height: fence.height);
    developer.log("Searching for Features ", name: "_features_");

    List<dynamic> renderedFeatures =
        await _mapController!.queryRenderedFeaturesInRect(
            rect,
            [
              "route-marker-layer",
              "good_roads_published",
              "published_routes",
              "good_roads_published_highlighted"
            ],
            null);
    if (renderedFeatures.isNotEmpty) {
      developer.log("Features found", name: "_features_");
      for (int i = 0; i < features.length; i++) {
        features[i]['properties']['highlighted'] = true;
      }
    }

    return features;
  }*/
  _getTripDescriptions() async {
    _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
    _bottomDrawerController.open(height: 300);
    await Future.delayed(Duration(milliseconds: 500));
    _bottomDrawerController.dockOpenTile();
    //   }
    CurrentTripItem().tripActions = TripActions.none;
  }

  /// Opens the bottomDrawer to add the details of the last added CurrentTripItem().PointOfInterest
  /*
  _getPointOfInterest() {
    _scrollToKeys.add(GlobalKey());
    developer.log(
        '_scrollToKeys.add(GlobalKey()): ${_scrollToKeys.last} line 1111',
        name: '_global_key');
    List<Card> cards = [];

    if (_tripRequest != null ||
        CurrentTripItem().bottomDrawerData.isRequested) {
      cards = _tripRequest!.getTripTiles(
          key: _scrollToKeys.last,
          dataRequired: BottomDrawerData.pointOfInterest,
          callback: closeDrawerCallback,
          //   onSave: updateMap,
          newPointOfInterest: CurrentTripItem().pointsOfInterest.last,
          tripHeaderController: _tripHeaderController);
      _opened = false;
      _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
      CurrentTripItem().bottomDrawerData =
          BottomDrawerData.pointOfInterestRequested;
      _bottomDrawerController.open(height: 350);
      _bottomDrawerController.dockOpenTile();
    }
  }


*/
  /// Opens the bottomDrawer to add the details of the last added CurrentTripItem().PointOfInterest
/*

  _getPointOfInterestOnly() {
    _scrollToKeys.add(GlobalKey());
    List<Card> cards = [];

    for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
      if (![17, 18, 10].contains(CurrentTripItem().pointsOfInterest[i].type)) {
        cards.add(
          Card(
            key: i == CurrentTripItem().pointsOfInterest.length - 1
                ? _scrollToKeys.last
                : Key('card$i'),
            child: PointOfInterestTile(
              index: i,
              pointOfInterest: CurrentTripItem().pointsOfInterest[i],
              expanded: i == CurrentTripItem().pointsOfInterest.length - 1,
              imageRepository: _imageRepository,
              onUpdate: (value) => closeDrawerCallback(value),
            ),
          ),
        );
      }
    }
    _opened = false;
    _bottomDrawerController.setContent(content: cards);
    //   _bottomDrawerController.open(height: 300);
    developer.log('Drawer.open(height: 350) called @ 1135', name: '_d_open');
    CurrentTripItem().bottomDrawerData =
        BottomDrawerData.pointOfInterestRequested;
    _bottomDrawerController.open(height: 350);
    _bottomDrawerController.dockOpenTile(key: _scrollToKeys.last);
  }
*/
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
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
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
        _bottomDrawerController.setContent(content: BottomDrawerItems.group);
        _bottomDrawerController.open(height: 300);
        CurrentTripItem().tripActions = TripActions.none;
        return;

      default:
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        _bottomDrawerController.open(height: 300);
        CurrentTripItem().tripActions = TripActions.none;
    }
    return;
  }

  /// _onIdle should:
  ///   1 Display any updates to the published data if the viewport has changed
  ///   2 Display any new features that the user has added or removed using CreateTripChips
  ///     - The routeData - waypoints + routes for defining the drive
  ///     - GoodRoad routes and waypoints
  ///     Just using CurrentTripItem().isGoodRoad isn't enough as that could change before _onIdle() is called
  ///     enum ChangedFeatures{route, goodRoad, both, none} which is set when anything is changed should allow control

/*
  _debugUpdate() async {
    LatLngBounds bounds = await _mapController!.getVisibleRegion();
    double zoom = _mapController!.cameraPosition!.zoom;
    Map<String, dynamic> geoJson =
        await _tripRequest!.update(bounds: bounds, zoom: zoom);
    if (geoJson['features'].isNotEmpty) {
      developer.log('SetGeoJsonSource() called _onIdle() create_trip.dart 1352',
          name: '_map_');
      developer.log(
          '_mapController!.setGeoJsonSource("good-road-data", geoJson)',
          name: '_map_');
      await _mapController!.setGeoJsonSource("good-road-data", geoJson);
      return; // debug
    }
  }
*/
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
      double zoom = _mapController!.cameraPosition!.zoom;
      CurrentTripItem().mapController ??= _mapController;
      LatLngBounds? bounds2;
      try {
        bounds2 = await _mapController!.getVisibleRegion();
        developer.log('Bounds: $bounds2', name: "_mapUpdates_");
      } catch (e) {
        developer.log('Bounds: $bounds2', name: "_mapUpdates_");
      }
      // CurrentTripItem().mapController = _mapController;
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
          _geoJson = geoJson;
          await _mapController!.setGeoJsonSource("published-data", geoJson);
        }
        _executeChipActions();

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
          _executeChipActions();
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
    setState(
      () => _tripCards =
          _tripRequest!.getTripTiles(callback: closeDrawerCallback),
    );
  }

//  List<Map<String, dynamic>> getPolyLines() {
//    return CurrentTripItem().routes;
//  }

  Point chipPosition() {
    try {
      return Point(_mapController!.cameraPosition!.target.latitude,
          _mapController!.cameraPosition!.target.longitude);
      // _animatedMapController.mapController.camera.center;
    } catch (e) {
      return Point(0, 0);
    }
  }

//  Future<Position> _getDebugPosition() async {
//    return _debugRoute.getPosition ?? Geolocator.getCurrentPosition();
//  }

  Align getDirections(int index) {
    if (CurrentTripItem().tripState == TripState.following &&
        CurrentTripItem().maneuvers.isNotEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: DirectionTile(
          routes: CurrentTripItem().routes,
          maneuvers: CurrentTripItem().maneuvers,
          controller: _directionTileController,
          currentIndex: (_) => (),
          onTap: (index, routeIndex, pointIndex) => changeRoute(
              lastManeuverIndex: index,
              routeIndex: routeIndex,
              pointIndex: pointIndex),
          currentPosition: CurrentTripItem().tripValues.position,
          driveId: '', // CurrentTripItem().driveUri,
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
        position: Point(_currentPosition.longitude, _currentPosition.latitude),
        routeIndex: routeIndex,
        pointIndex: pointIndex);
    if (update) {
      setState(() => _directionTileController.updateRoute());
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
      // for (Follower follower in participants) {
      cIndex = cIndex < 16 ? ++cIndex : 2;
      if (Setup().user.email == follower.email) {
        myCarInfo = follower;
      }
      try {
        // if (follower.email != Setup().user.email) {

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

/*
  void updateMap(int index) {
    CurrentTripItem().mapUpdates =
        CurrentTripItem().mapUpdates.add(MapUpdates.pointsOfInterest);
    developer.log(
        'CurrentTripItem().mapUpdates: ${CurrentTripItem().mapUpdates}',
        name: '_repaint_');
  }

  */

//  void onSelectMember(int index) {}
/*
  List<Card> _showGroup() {
    List<Card> cards = [];
    for (int i = 0; i < _following.length; i++) {
      cards.add(
        Card(
          key: Key('ft_$i'),
          /*
          child: FollowerTile(
            follower: _following[i],
            index: i,
            onIconClick: followerIconClick,
            onLongPress: followerLongPress,
            distance: 0,
            currentPosition: LatLng(_currentPosition.latitude,
                _currentPosition.longitude), // ToDo: calculate how far away
          ),
          */
        ),
      );
    }
    return cards;
  }
  */
/*
  List<Card> _showManeuvers() {
    List<Card> cards = [];
    if (CurrentTripItem().maneuvers.isNotEmpty) {
      for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
        try {
          cards.add(
            Card(
              key: Key('mc_$i'),
              child: ManeuverTile(
                  index: i,
                  maneuver: CurrentTripItem().maneuvers[i],
                  routes: CurrentTripItem().routes,
                  onLongPress: maneuverLongPress),
            ),
          );
        } catch (e) {
          developer.log('Error preparing maneuvers cards: ${e.toString()}',
              name: '_chips');
        }
      }
    }
    return cards;
  }
  */
/*
  List<Card> _showMessages() {
    List<Card> cards = [];
    for (int i = 0; i < _tripMessages.length; i++) {
      cards.add(
        Card(
          key: Key('mt_$i'),
          child: TripMessageTile(
            index: i,
            message: _tripMessages[i],
            onEdit: (_) => (),
            onSelect: (_) => (),
          ),
        ),
      );
    }
    return cards;
  }
*/
/*
  void maneuverLongPress(int index) async {
    // CurrentTripItem().tripValues.showTarget = true;

    bool? moved = await _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(
            CurrentTripItem().maneuvers[index].point.y.toDouble(),
            CurrentTripItem().maneuvers[index].point.x.toDouble())),
        duration: Duration(milliseconds: 300));

    debugPrint('index: $index moved: ${moved ?? false}');
    final String fileName = await getSpeech(
        text:
            'Stop the car you idiot, I want to get out', //CurrentTripItem().maneuvers[index].modifier,
        fileName: 'text.mp3');
    if (fileName.isNotEmpty) {
      final bool exists = await File(fileName).exists();
      if (exists) {
        debugPrint('File size: ${File(fileName).lengthSync}');
        DeviceFileSource source = DeviceFileSource(fileName);
        try {
          final player = AudioPlayer(); //..setReleaseMode(ReleaseMode.stop);
          // player.setSourceAsset(fileName);
          player.play(source); //(source);
        } catch (e) {
          debugPrint('Error : ${e.toString()}');
        }
      }
    }
    setState(() => _directions.currentIndex = index);
    return;
  }
*/

/*

  Future<void> followerIconClick(int index) async {
    String message = await messageGroup(index);
    if (message.isNotEmpty) {}
    return;
  }

  */

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
/*
  void followerLongPress(int index) {
    // CurrentTripItem().tripValues.showTarget = true;
    _mapController!.animateCamera(
      CameraUpdate.newLatLng(LatLng(
              _currentPosition.latitude,
              _currentPosition
                  .longitude) //          position.latitude, position.longitude),
          ),
    );
    return;
  }

  */
/*
  List _showPointOfInterest({readOnly = false, index = 0}) {
    return CurrentTripItem()
        .pointsOfInterest
        .where((poi) => ![12, 14, 17, 18].contains(poi.type))
        .toList();
  }
*/

/*
  List<Card> _showPointOfInterest2({readOnly = false, index = 0}) {
    List<Card> cards = [];
    bool toComplete = true;
    CurrentTripItem().tripActions = TripActions.none;
    Key key;
    for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
      if (![12, 14, 17, 18]
          .contains(CurrentTripItem().pointsOfInterest[i].type)) {
        if (toComplete && CurrentTripItem().pointsOfInterest[i].name.isEmpty) {
          developer.log(
              '_scrollToKeys.add(GlobalKey()): ${_scrollToKeys.last} line 1989',
              name: '_global_key');
          _scrollToKeys.add(GlobalKey());
          key = _scrollToKeys.last;
          toComplete = false;
        } else {
          key = key = Key('poi_$i');
        }
        cards.add(
          Card(
            child: PointOfInterestTile(
              key: key,
              index: CurrentTripItem().tripValues.pointOfInterestIndex,
              pointOfInterest: CurrentTripItem().pointsOfInterest[i],
              controller: PointOfInterestController(),
              imageRepository: _imageRepository,
              onExpandChange: (expanded) => expandChange,
              onIconTap: iconButtonTapped,
              onDelete: removePointOfInterest,
              onRated: onPointOfInterestRatingChanged,
              onSave: (index) => onPointOfInterestSaved(index: i),
              expanded: true,
              canEdit: !readOnly,
              onUpdate: (value) => closeDrawerCallback(value),
            ),
          ),
        );
        CurrentTripItem().bottomDrawerData =
            BottomDrawerData.pointOfInterestRequested;
      }
    }
    return cards;
  }
*/

/*
  List<Card> _showExploreDetail(
      {String openUri = '', GlobalKey? key, readOnly = false}) {
    List<Card> cards = [];
    for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
      if (![12, 16, 17, 18, 19]
          .contains(CurrentTripItem().pointsOfInterest[i].type)) {
        cards.add(
          Card(
            key: Key('pit_$i'),
            child: PointOfInterestTile(
              key: CurrentTripItem().pointsOfInterest[i].uuid == openUri
                  ? key
                  : Key('poi_$i'),
              index: i,
              pointOfInterest: CurrentTripItem().pointsOfInterest[i],
              imageRepository: _imageRepository,
              onExpandChange: (expanded) => expandChange,
              onIconTap: iconButtonTapped,
              onDelete: removePointOfInterest,
              onRated: onPointOfInterestRatingChanged,
              onSave: (index) => onPointOfInterestSaved(index: index),
              expanded: CurrentTripItem().pointsOfInterest[i].uuid == openUri,
              canEdit: !readOnly,
            ),
          ),
        );
      }
    }
    return cards;
  }
*/
/*
  Widget _showExploreDetail({readOnly = false}) {
    if (CurrentTripItem().pointsOfInterest.isEmpty) {
      return Center(
        heightFactor: 10,
        child: Text('No features recorded yet.',
            style: titleStyle(context: context, size: 1)),
      );
    } else {
      int pois = 0;
      return SizedBox(
        height: listHeight,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (CurrentTripItem().tripValues.pointOfInterestIndex < 0 ||
                CurrentTripItem().tripState == TripState.editing) ...[
              // if (CurrentTripItem().pointsOfInterest.isEmpty) ...[
              SliverToBoxAdapter(
                child: _exploreDetailsHeader(),
              ),
              SliverReorderableList(
                itemBuilder: (context, index) {
                  int poiType = CurrentTripItem().pointsOfInterest[index].type;
                  bool exclude = [12, 16, 17, 18, 19].contains(poiType);

                  for (int i = 0;
                      i < CurrentTripItem().pointsOfInterest.length;
                      i++) {
                    if (![12, 16, 17, 18, 19]
                        .contains(CurrentTripItem().pointsOfInterest[i].type)) {
                      pois++;
                    }
                  }
                  ;
                  if (!exclude) {
                    // filter out followers
                    return // isWaypoint
                        // ? waypointTile(index)
                        //  :
                        PointOfInterestTile(
                      key: ValueKey(index),
                      index: index,
                      pointOfInterest:
                          CurrentTripItem().pointsOfInterest[index],
                      imageRepository: _imageRepository,
                      onExpandChange: (expanded) => expandChange,
                      onIconTap: iconButtonTapped,
                      onDelete: removePointOfInterest,
                      onRated: onPointOfInterestRatingChanged,
                      onSave: (index) => onPointOfInterestSaved(index: index),
                      canEdit: !readOnly,
                    );
                  } else {
                    return SizedBox(
                      key: ValueKey(index),
                      height: 1,
                    );
                  }
                },
                itemCount: pois,
                onReorder: (int oldIndex, int newIndex) {
                  setState(
                    () {
                      if (oldIndex < newIndex) {
                        newIndex = -1;
                      }
                      //    CurrentTripItem().movePointOfInterest(oldIndex, newIndex);
                    },
                  );
                },
              ),
            ],
            if (CurrentTripItem().tripValues.pointOfInterestIndex > -1 &&
                CurrentTripItem().tripValues.pointOfInterestIndex <
                    CurrentTripItem().pointsOfInterest.length &&
                ![12, 17, 18, 19].contains(CurrentTripItem()
                    .pointsOfInterest[
                        CurrentTripItem().tripValues.pointOfInterestIndex]
                    .type)) ...[
              SliverToBoxAdapter(
                child: PointOfInterestTile(
                  key: ValueKey(
                      CurrentTripItem().tripValues.pointOfInterestIndex),
                  index: CurrentTripItem().tripValues.pointOfInterestIndex,
                  pointOfInterest: CurrentTripItem().pointsOfInterest[
                      CurrentTripItem().tripValues.pointOfInterestIndex],
                  imageRepository: _imageRepository,
                  onExpandChange: (expanded) => expandChange,
                  onIconTap: iconButtonTapped,
                  onDelete: removePointOfInterest,
                  onRated: onPointOfInterestRatingChanged,
                  onSave: (index) => onPointOfInterestSaved(index: index),
                  // expanded: true,
                  canEdit: !readOnly,
                ),
              )
            ]
          ],
        ),
      );
    }
  }
*/
/*
  void _scrollDown() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2), curve: Curves.fastOutSlowIn);
  }
*/
  Future<void> deleteTrip(int index) async {
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage:
            ' ', // CurrentTripItem().heading, // _myTripItems[index].heading,
        okValue: index,
        callback: onConfirmDeleteTrip);
  }

  onPointOfInterestRatingChanged(int value, int index) async {
    // putPointOfInterestRating(
    //     CurrentTripItem().pointsOfInterest[index].url, value.toDouble());
  }

  void onPointOfInterestSaved({index = -1}) {
    if (index > -1) {
      //  PointOfInterest updated = PointOfInterest.clone(
      //       pointOfInterest: CurrentTripItem().pointsOfInterest[index]);

      //   setState(() => CurrentTripItem().pointsOfInterest[index] = updated);
      debugPrint('done');
    }
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

/*
  Widget _editTripDetails() {
    return _exploreDetailsHeader();
  }
*/
/*
  Widget _exploreDetailsHeader() {
    bool autofocus = CurrentTripItem().tripActions == TripActions.headingDetail;
    return FocusScope(
      // FocusScope  Sorted problems with TextInputAction.next / done
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
                autofocus: autofocus, //  tripItem.heading.isEmpty,
                focusNode: fn1,
                readOnly: CurrentTripItem().tripState == TripState.following,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,

                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Give your trip a name...',
                    hintStyle: hintStyle(context: context),
                    labelText: 'Trip name',
                    labelStyle: labelStyle(context: context)),
                style: textStyle(context: context),
                initialValue: ' ', // CurrentTripItem().heading,
                // autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (text) => (), //CurrentTripItem().heading = text,
                onFieldSubmitted: (text) => (debugPrint('submitted : $text')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                readOnly: CurrentTripItem().tripState == TripState.following,
                // autofocus: autofocus,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a short summary of your trip...',
                    hintStyle: hintStyle(context: context),
                    labelText: 'Trip summary',
                    labelStyle: labelStyle(context: context)),
                style: textStyle(context: context),
                initialValue: ' ', // CurrentTripItem()
                //   .subHeading, //widget.port.warning.toString(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (text) => (), // CurrentTripItem().subHeading = text,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: TextFormField(
                readOnly: CurrentTripItem().tripState == TripState.following,
                //  autofocus: autofocus,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.start,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,

                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Describe details of your trip...',
                    hintStyle: hintStyle(context: context),
                    labelText: 'Trip details',
                    labelStyle: labelStyle(context: context)),
                style: textStyle(context: context),
                initialValue:
                    CurrentTripItem().body, //widget.port.warning.toString(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (text) => CurrentTripItem().body = text,
              ),
            ),
          ],
        ),
      ),
    );
  }
*/
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

  void getLocationUpdates() async {
    try {
      if (CurrentTripItem().tripValues.pauseStream) {
        _positionStream.pause();
      } else if (CurrentTripItem().tripValues.resumeStream) {
        _positionStream.resume();
      } else if (CurrentTripItem().tripValues.stopStream) {
        //   CurrentTripItem().pointsOfInterest.add(PointOfInterest(
        //       type: 18, point: CurrentTripItem().tripValues.lastLatLng));
      } else {
        if (CurrentTripItem().tripValues.streamFinished) {
          _positionStream.cancel();
        }
        if (_debugging) {
          if (_debuggingRoute.isEmpty) {
            _debugRoute.follow(routes: CurrentTripItem().routes);
          } else {
            //    List<Map<String, dynamic>> debugRoute = await getPrivateRepository()
            //        .getRoutesByName(name: _debuggingRoute);
            //    _debugRoute.follow(routes: debugRoute);
          }
          // if (_debugPositionController.stream.)
          //  _positionStream = _debugPositionController.stream.listen(
          //    (Position position) {
          //      updatePosition(position);
          //    },
          //  );
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
        _positionStream
            .onDone(() => CurrentTripItem().tripValues.streamFinished = true);
      }
    } catch (e) {
      developer.log('Stream error: ${e.toString()}', name: '_stream');
    }
  }

  void updatePosition(position) {
    _currentPosition = position;
    _speed = position.speed * 3.6 / 8 * 5; // M/S -> MPH
/*
    LatLng pos = LatLng(
        position.latitude,
        position
            .longitude); // LatLng(_currentPosition.latitude, _currentPosition.longitude);
*/
    if (_debugging) {
      _speed = 43.0;
      /*
      if (_debugMarkers.isEmpty) {
        _debugMarkers.add(Marker(
            point: LatLng(position.latitude, position.longitude),
            child: Icon(Icons.navigation, size: 40, color: Colors.blue)));
      } else {
        _debugMarkers[0] = Marker(
            point: LatLng(position.latitude, position.longitude),
            child: Icon(Icons.navigation, size: 40, color: Colors.blue));
      }
      */
      // child: Icon(Icons.bug_report, size: 30, color: Colors.teal));
//      _animatedMapController.animateTo(
      //         dest: LatLng(position.latitude, position.longitude));
      if (_following.isNotEmpty) {
        try {
          int index = _debugRoute.getIndex;
          int jump = 12;
          for (int i = 0; i < _following.length; i++) {
            if (index > jump * (i + 1)) {
/*              
              _following[i] = Follower.moveFollower(
                follower: _following[i],
                marker: _following[i].marker,
                position: _debugRoute.getPositionAt(index - (jump * (i + 1))),
              );
*/
            } else {
              break;
            }
          }
        } catch (e) {
          debugPrint('Error setting followin ${e.toString()}');
        }
      }
    }
/*
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
        socket.emit('trip_message', {
          'message': '',
          'lat': position.latitude,
          'lng': position.longitude,
        });
      }
    } else if (CurrentTripItem().tripState == TripState.recording) {
      double distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          CurrentTripItem().tripValues.lastLatLng.latitude,
          CurrentTripItem().tripValues.lastLatLng.longitude);
      if (distance > 1000) {
        CurrentTripItem().addRoute(mt.Route(
            id: -1,
            points: [pos],
            borderColor: uiColours.keys.toList()[Setup().routeColour],
            color: uiColours.keys.toList()[Setup().routeColour],
            strokeWidth: 5));
        if (CurrentTripItem().routes.length == 1) {
          CurrentTripItem()
              .pointsOfInterest
              .add(PointOfInterest(type: 17, point: pos, waypoint: 0));
        } else {
          CurrentTripItem().pointsOfInterest.add(PointOfInterest(
              type: 12,
              point: pos,
              waypoint: CurrentTripItem().pointsOfInterest.length));
        }
        developer.log(
            'Distance from start point in CreateTrip: ${distance * metersToMiles}',
            name: '_tracking');
      } else {
        distance = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            CurrentTripItem().pointsOfInterest.last.point.latitude,
            CurrentTripItem().pointsOfInterest.last.point.longitude);
        setState(() => (CurrentTripItem().routes.last.points.add(pos)));
        if (distance > 1 / metersToMiles) {
          developer.log(
              'Distance from PointOfInterest.last.location in CreateTrip: ${distance * metersToMiles}',
              name: '_tracking');
          CurrentTripItem().pointsOfInterest.add(PointOfInterest(
              type: 12,
              point: pos,
              waypoint: CurrentTripItem().pointsOfInterest.length));
        }
      }
      if (CurrentTripItem().tripValues.goodRoad.isGood) {
        CurrentTripItem().isGoodRoads.last.points.add(pos);
      }
      CurrentTripItem().tripValues.lastLatLng = pos;
    }
*/
    if (CurrentTripItem().tripState == TripState.following) {
      setState(() => _directionsIndex = getDirectionsIndex());
    }
  }

  void addGoodRoad({required var position, name = 'Good road', audio = ''}) {
/*    
    CurrentTripItem().addPointOfInterest(
      PointOfInterest(
        driveId: CurrentTripItem().driveId,
        type: 13,
        name: name,
        point: position,
        sounds: audio,
        waypoint: id == -1 ? CurrentTripItem().pointsOfInterest.length : id + 1,
      ),
    );
    CurrentTripItem().addGoodRoad(
      mt.Route(
          id: -1,
          points: [position],
          borderColor: uiColours.keys.toList()[Setup().goodRouteColour],
          color: uiColours.keys.toList()[Setup().goodRouteColour],
          strokeWidth: 5,
          pointOfInterestIndex: CurrentTripItem().pointsOfInterest.length - 1),
    );
*/
  }

  int getDirectionsIndex() {
    int idx = -1;
    double distance = 99999;
    double temp;
    if (CurrentTripItem().tripState == TripState.following) {
      /*
      for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
        temp = Geolocator.distanceBetween(
            CurrentTripItem().tripValues.position.latitude,
            CurrentTripItem().tripValues.position.longitude,
            CurrentTripItem().maneuvers[i].location.latitude,
            CurrentTripItem().maneuvers[i].location.longitude);
        if (temp < distance) {
          distance = temp;
          idx = i;
        }
      }
      */
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

class HandleCTFabs extends StatelessWidget {
  final double _width = 50;
  final double _height = 56.0;
  final MapLibreMapController controller;
  Function? callback;
  HandleCTFabs({super.key, required this.controller, this.callback});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PlaceFinder(
          height: _height,
          width: _width,
          onSelect: (position) => controller.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        FloatingActionButton(
          heroTag: 'location',
          onPressed: () async {
            Position currentPosition = await Geolocator.getCurrentPosition();
            controller.animateCamera(CameraUpdate.newLatLng(
                LatLng(currentPosition.latitude, currentPosition.longitude)));
          },
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        // if (CurrentTripItem().isGoodRoads.isNotEmpty)
        FloatingActionButton(
          heroTag: 'test',
          onPressed: () async {
            // int value = await getGoodRoadsGeoJson();
            // testApi();
            if (callback != null) {
              () => callback;
            }

            // debugPrint('Test statusCode: $value');
          },
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.cruelty_free,
            color: Colors.white,
          ),
        ),
        const SizedBox(
          height: 15,
        ),
      ],
    );
  }
}
