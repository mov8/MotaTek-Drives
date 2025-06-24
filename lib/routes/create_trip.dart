import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:drives/constants.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/classes/route.dart' as mt;
// import 'package:drives/classes/vectors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drives/screens/screens.dart';
import 'package:drives/services/services.dart' hide getPosition;
import 'package:drives/models/models.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
//import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

/*
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
email used jasme@motatek.com pw rubberduck
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

class CreateTrip extends StatefulWidget {
  const CreateTrip({super.key});
  @override
  State<CreateTrip> createState() => _CreateTripState();
}

class _CreateTripState extends State<CreateTrip> with TickerProviderStateMixin {
  GlobalKey mapKey = GlobalKey();
  final GlobalKey _scaffoldKey = GlobalKey();
  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
  List<double> mapHeights = [0, 0, 0, 0];
  AppState _appState = AppState.home;
  final start = TextEditingController();
  final end = TextEditingController();
  final mapController = MapController();
  late final RoutesBottomNavController _bottomNavController; // =
  final GroupMessagesController groupMessagesController =
      GroupMessagesController();
  bool isVisible = false;
  PopupValue popValue = PopupValue(-1, '', '');
  final navigatorKey = GlobalKey<NavigatorState>();
  List<Marker> markers = [];
  List<MyTripItem> _myTripItems = [];
  List<TripItem> tripItems = [];
  int id = -1;
  int userId = -1;
  int type = -1;
  int _directionsIndex = 0;
  double iconSize = 35;
  double _mapRotation = 0;
  LatLng _startLatLng = const LatLng(0.00, 0.00);
  LatLng _lastLatLng = const LatLng(0.00, 0.00);
  late StreamSubscription<Position> _positionStream;
  late Future<bool> _loadedOK;
  bool _showMask = false;
  bool _osmIncludingChange = false;
  late FocusNode fn1;
  final GoodRoad _goodRoad = GoodRoad();
  final List<CutRoute> _cutRoutes = [];
  late ui.Size screenSize;
  late ui.Size appBarSize;
  double mapHeight = 250;
  double listHeight = 0;
  bool _showTarget = false;
  final TripPreferences _preferences = TripPreferences();
  int _editPointOfInterest = -1;
  late Position _currentPosition;
  int _resizeDelay = 0;
  DateTime _start = DateTime.now();
  double _speed = 0.0;
  int insertAfter = -1;
  int _poiDetailIndex = -1;
  var moveDelay = const Duration(seconds: 2);
  double _travelled = 0.0;
  int highlightedIndex = -1;
  final List<Follower> _following = [];
  late LocationSettings _locationSettings;
  final _cacheFence = Fence.create();
  LatLng topRight = const LatLng(0, 0);
  LatLng bottomLeft = const LatLng(0, 0);
  bool _updateOverlays = true;
  late final ExpandNotifier _expandNotifier;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _preferencesScrollController = ScrollController();
  final mt.RouteAtCenter _routeAtCenter = mt.RouteAtCenter();
  bool _tripStarted = false;
  String _title = 'Drives'; // _hints[0][0];
  late AnimatedMapController _animatedMapController;
  late final StreamController<double?> _allignPositionStreamController;
  late final StreamController<void> _allignDirectionStreamController;
  late final LeadingWidgetController _leadingWidgetController;
  late final FloatingTextEditController _floatingTextEditController1;
  late final FloatingTextEditController _floatingTextEditController2;
  int initialLeadingWidgetValue = 0;
  late AlignOnUpdate _alignPositionOnUpdate;
  late AlignOnUpdate _alignDirectionOnUpdate;
  List<Place> _places = [];
  bool _autoCentre = false;
  final _dividerHeight = 35.0;
  List<LatLng> routePoints = const [LatLng(51.478815, -0.611477)];

  String images = '';
  //  String stadiaMapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';
  late Style _style;
  PublishedFeatures _publishedFeatures = PublishedFeatures(
      features: [], pinTap: (_) => (), pointOfInterestLookup: {});

  final OsmFeatures _osmFeatures = OsmFeatures();
  // List<PointOfInterest> _pointsOfInterest = [];

  String? _tripId;
  double _width = 56.0;
  final double _height = 56.0;
  bool _expanded = false;
  //double _width1 = 56.0;
  //double _height1 = 56.0;
  //bool _expanded1 = false;
  late bool _hasRepainted;
  StreamSocket streamSocket = StreamSocket();
  sio.Socket socket = sio.io(urlBase, <String, dynamic>{
    // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
    'transports': ['websocket'], // Specify WebSocket transport
    'autoConnect': false, // Prevent auto-connection
  });

  final List<TripMessage> _tripMessages = [];

  /// Routine to add point of interest
  /// Identified as a point

  _addPointOfInterest(int id, int userId, int iconIdx, String desc, String hint,
      double size, LatLng latLng, String audio) {
    try {
      CurrentTripItem().addPointOfInterest(
        PointOfInterest(
          id: id,
          driveId: CurrentTripItem().driveId,
          type: iconIdx,
          name: desc,
          description: hint,
          width: size,
          height: size,
          images: images,
          markerPoint: latLng,
          sounds: audio,
          marker: MarkerWidget(
            type: iconIdx,
            angle: -_mapRotation * pi / 180, // degrees to radians
            list: 0,
            listIndex: CurrentTripItem().pointsOfInterest.length,
          ),
        ),
      );
      setState(() {
        _showMask = false;
      });
    } catch (e) {
      String err = e.toString();
      debugPrint('Error: $err');
    }
  }

  // VectorTileProvider _tileProvider() =>
//      NetworkVectorTileProvider(urlTemplate: urlTiler, maximumZoom: 14);

  _addGreatRoadStartLabel(int id, int userId, int iconIdx, String desc,
      String hint, double size, LatLng latLng) {
    int top = mapHeight ~/ 2;
    int left = MediaQuery.of(context).size.width ~/ 2;

    CurrentTripItem().addPointOfInterest(
      PointOfInterest(
        //  context,
        id: id,
        driveId: CurrentTripItem().driveId,
        type: iconIdx,
        name: desc,
        description: hint,
        width: size,
        height: size,
        images: images,
        markerPoint: latLng,
        marker: LabelWidget(
            top: top,
            left: left,
            description: desc), // MarkerWidget(type: iconIdx),
      ),
    );
    setState(() {
      _scrollDown();
    });
  }

  /// _singlePointOfInterest uses Komoot reverse lookup to get the address, and doesn't
  /// try to generate any Routes

  _singlePointOfInterest(BuildContext context, latLng, int id,
      {name = 'Unknown location',
      distance = 0,
      time = 0,
      refresh = true}) async {
    int type = 12;
    await getPoiName(latLng: latLng, name: name).then((name) {
      if (context.mounted) {
        PointOfInterest poi = PointOfInterest(
          //   context,
          id: id,
          driveId: CurrentTripItem().driveId,
          type: type,
          name: name,
          description: '$distance miles - ($time minutes)',
          width: 10,
          height: 10,
          images: images,
          //   markerIcon(type),
          markerPoint: latLng,
          marker: MarkerWidget(
            type: type,
            description: name,
            angle: -_mapRotation * pi / 180,
            list: 0,
            listIndex:
                id == -1 ? CurrentTripItem().pointsOfInterest.length : id + 1,
          ),
        );
        if (id == -1) {
          CurrentTripItem().addPointOfInterest(poi);
        } else {
          CurrentTripItem().insertPointOfInterest(poi, id + 1);
        }
      }
    }).then((_) {
      if (refresh) {
        setState(() {});
      }
    });
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
    _leadingWidgetController = LeadingWidgetController();

    /// Have to have a controller instance for each Widget
    /// being controlled, as the controller shares the widgets state
    /// A single controller would then share the state of
    /// all the widgets it controlls - not good.
    _floatingTextEditController1 = FloatingTextEditController();
    _floatingTextEditController2 = FloatingTextEditController();
    _bottomNavController = RoutesBottomNavController();
    _expandNotifier = ExpandNotifier(-1);

    _locationSettings =
        getGeolocatorSettings(defaultTargetPlatform: TargetPlatform.android);

    try {
      _loadedOK = dataFromDatabase();
      _title = 'Create a new trip';
      developer.log(_title, name: '_title ! initState() 375');
      _allignPositionStreamController = StreamController<double?>.broadcast();
      _animatedMapController = AnimatedMapController(vsync: this);
      _allignDirectionStreamController = StreamController<void>.broadcast();
      _alignPositionOnUpdate = AlignOnUpdate.never;
      _alignDirectionOnUpdate = AlignOnUpdate.never; // never;
      fn1 = FocusNode();
      listHeight = -1;
      _autoCentre = false;
      socket.onConnectError((_) => debugPrint('connect error'));
      socket.onError((data) => debugPrint('Error: ${data.toString()}'));
      _hasRepainted = false;
      socket.on(
        'message_from_trip',
        (data) {
          TripMessage tripMessage = TripMessage.fromSocketMap(data);
          if (tripMessage.message.isNotEmpty) {
            try {
              var message = jsonDecode(tripMessage.message);
              if (message['type'] == 'p') {
                for (Follower follower in _following) {
                  if (follower.uri == tripMessage.senderId) {
                    follower.position = LatLng(message['lat'], message['lng']);
                  }
                }
              } else {
                _tripMessages.add(tripMessage);
              }
              setState(() {});
            } catch (e) {
              debugPrint('Error: ${e.toString()}');
            }
          }
        },
      );

      _preferencesScrollController.addListener(
        () {
          if (_preferencesScrollController.position.atEdge) {
            bool isTop = _preferencesScrollController.position.pixels == 0;
            if (isTop) {
              setState(() {
                _preferences.isRight = true;
                _preferences.isLeft = false;
              });
            } else {
              setState(() {
                _preferences.isLeft = true;
                _preferences.isRight = false;
              });
            }
          } else if (_preferences.isRight || _preferences.isLeft) {
            setState(() {
              _preferences.isLeft = false;
              _preferences.isRight = false;
            });
          }
        },
      );

      socket.onConnect((_) {
        //     debugPrint('onConnect connected');
        socket.emit('trip_join', {'token': Setup().jwt, 'trip': _tripId});
      });

      if (socket.connected) {
        socket.emit('trip_join', {'token': Setup().jwt, 'trip': _tripId});
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
    _animatedMapController.dispose();
    fn1.dispose();

    // Clean up the focus node when the Form is disposed.
    if (_tripId != null && socket.connected) {
      socket.emit('trip_leave', {'trip': _tripId});
      try {
        socket.emit('cleave');
      } catch (e) {
        debugPrint('error disposing of group_messages: ${e.toString()}');
      }
    }
    streamSocket.dispose();
    super.dispose();
  }

  Future<String> getWaypoints(List<TextEditingController> controllers) async {
    String waypoints = '';
    List<Location> startL;
    List<Location> endL;
    for (int i = 0; i < controllers.length; i += 2) {
      try {
        startL = await locationFromAddress(controllers[i].text);
        endL = await locationFromAddress(controllers[i + 1].text);
        waypoints =
            '$waypoints${startL[0].longitude},${startL[0].latitude};${endL[0].longitude},${endL[0].latitude};';
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    }
    return waypoints;
  }

  void _updateMarkerSize(double zoom) {
    setState(() {});
  }

  Future<Map<String, dynamic>> addRoute(LatLng latLng1, LatLng latLng2) async {
    String waypoint =
        '${latLng1.longitude},${latLng1.latitude};${latLng2.longitude},${latLng2.latitude}';
    return await getRoutePoints(waypoint);
  }

  Future loadRoutes() async {
    int prior = -1;
    int next = -1;
    String waypoints = '';
    for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
      if (CurrentTripItem().pointsOfInterest[i].getType() == 12) {
        if (prior == -1) {
          prior = i;
        } else if (next == -1) {
          next = i;
        } else {
          prior = next;
          next = i;
        }
        if (next > -1) {
          waypoints =
              '$waypoints${CurrentTripItem().pointsOfInterest[prior].point.longitude},${CurrentTripItem().pointsOfInterest[prior].point.latitude};';
          waypoints =
              '$waypoints${CurrentTripItem().pointsOfInterest[next].point.longitude},${CurrentTripItem().pointsOfInterest[next].point.latitude};';
        }
      }
    }
    if (waypoints != '') {
      CurrentTripItem().clearRoutes();
      CurrentTripItem().clearManeuvers();
      waypoints = waypoints.substring(0, waypoints.length - 1);
      List<LatLng> points = await getRoutes(waypoints);
      CurrentTripItem().addRoute(
        mt.Route(
            id: -1,
            points: points, // Route,
            color: _routeColour(_goodRoad.isGood),
            borderColor: _routeColour(_goodRoad.isGood),
            strokeWidth: 5),
      );
    }
    setState(() {});
  }

/*
  Adds a new 
*/
  Future<Map<String, dynamic>> appendRoute(
    LatLng latLng2,
  ) async {
    LatLng latLng1;
    Map<String, dynamic> apiData = {};
    if (_startLatLng == const LatLng(0.00, 0.00)) {
      apiData = await addRoute(latLng2, latLng2);
      return apiData;
    }
    if (CurrentTripItem().routes.isNotEmpty &&
        CurrentTripItem()
                .routes[CurrentTripItem().routes.length - 1]
                .points
                .length >
            1) {
      latLng1 = CurrentTripItem()
          .routes[CurrentTripItem().routes.length - 1]
          .points[CurrentTripItem()
              .routes[CurrentTripItem().routes.length - 1]
              .points
              .length -
          1];
    } else {
      latLng1 = _startLatLng;
    }
    apiData = await addRoute(latLng1, latLng2);
    CurrentTripItem().addRoute(mt.Route(
        id: -1,
        points: apiData["points"], // Route,
        color: _routeColour(_goodRoad.isGood),
        borderColor: _routeColour(_goodRoad.isGood),
        strokeWidth: 5));

    CurrentTripItem().distance = CurrentTripItem().distance +
        double.parse(apiData["distance"].toString());
    setState(() {});

    return apiData;
  }

  Future<List<LatLng>> getRoutes(String waypoints) async {
    dynamic jsonResponse;
    List<LatLng> routePoints = [];
    String avoid = setAvoiding();

    var url = Uri.parse(
        '$urlRouter$waypoints?steps=true&annotations=true&geometries=geojson&overview=full$avoid'); //&exclude=motorway');
    try {
      var response = await http.get(url);
      jsonResponse = jsonDecode(response.body);
    } catch (e) {
      debugPrint('Http error: ${e.toString()}');
    }
    var router = jsonResponse['routes'][0]['geometry']['coordinates'];
    for (int i = 0; i < router.length; i++) {
      routePoints.add(LatLng(router[i][1], router[i][0]));
    }
    return routePoints;
  }

  ///
  /// Returns the routepoints and the waypoint data for the added waypoint
  /// _SimpleUri (http://10.101.1.150:5000/route/v1/driving/-0.0237985,52.9776561;-0.0237985,52.9776561?steps=true&annotations=true&geometries=geojson&overview=full&exclude=motorway&exclude=trunk&exclude=primary)

  List<Maneuver> getManeuvers() {
    List<Maneuver> maneuvers = [];
    return maneuvers;
  }

  @override
  Widget build(BuildContext context) {
    int initialNavBarValue = 2;
    initialLeadingWidgetValue =
        [AppState.createTrip, AppState.driveTrip].contains(_appState) ? 1 : 0;
    if (ModalRoute.of(context)!.settings.arguments != null &&
        listHeight == -1) {
      final args = ModalRoute.of(context)!.settings.arguments as TripArguments;
      CurrentTripItem().fromMyTripItem(myTripItem: args.trip);
      loadGroup();
      _title = CurrentTripItem().heading;
      developer.log(_title, name: '_title at build 617');
      CurrentTripItem().tripState = TripState.notFollowing;
      CurrentTripItem().tripActions = TripActions.none;
      initialLeadingWidgetValue = 0;
      initialNavBarValue = 2;
    }
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      resizeToAvoidBottomInset: false, // Stops keyboard moving FABS
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: LeadingWidget(
          controller: _leadingWidgetController,
          initialValue: initialLeadingWidgetValue,
          value: initialLeadingWidgetValue,
          onMenuTap: (index) {
            if (index == 0) {
              _leadingWidget(_scaffoldKey.currentState);
            } else {
              setState(() {
                if (CurrentTripItem().tripState == TripState.editing) {
                  // CurrentTripItem().tripState = TripState.loaded;
                  CurrentTripItem().tripState = TripState.notFollowing;
                  _title = CurrentTripItem().heading;
                  developer.log(_title, name: '_title TripState.editing 641');
                } else {
                  _title = 'Create a new trip';
                  developer.log(_title, name: '_title ! TripState.editing 644');
                  adjustMapHeight(MapHeights.full);
                  _leadingWidgetController.changeWidget(0);
                  CurrentTripItem().clearAll();
                }
              });
            }
          },
        ),
        title: Text(
          _title,
          style: const TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: RoutesBottomNav(
          controller: _bottomNavController,
          initialValue: initialNavBarValue,
          onMenuTap: (_) => {}),
      backgroundColor: Colors.grey[300],
      floatingActionButton: _handleFabs(),
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

  Future<bool> dataFromDatabase() async {
    try {
      if (Setup().hasLoggedIn) {
        var setupRecords = await recordCount('setup');
        _myTripItems = await tripItemFromDb();
        _preferences.avoidMotorways = Setup().avoidMotorways;
        _preferences.avoidFerries = Setup().avoidFerries;
        _preferences.avoidTollRoads = Setup().avoidTollRoads;
        _publishedFeatures = await getPublishedFeatures(
            pinTap: pinTap, expandNotifier: _expandNotifier);
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
    _style = await VectorMapStyle().mapStyle();
    return true;
  }

  pinTap(int index) async {
    Map<String, dynamic> infoMap = await getDialogData(
        features: _publishedFeatures.features,
        index: index); //.then((infoMap){}
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          bool canPop = false;
          return StatefulBuilder(
            builder: (context, setStae) {
              return PopScope(
                canPop: canPop,
                child: AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  title: Text(infoMap['title'],
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)), //textStyle),
                  elevation: 5,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        child: infoMap['content'],
                      ),
                    ],
                  ),
                  actions: actionButtons(
                    context,
                    [],
                    ['Close'],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  Future<Map<String, dynamic>> getDialogData(
      {required List<Feature> features, required int index}) async {
    Feature feature = features[index];
    Key cardKey = Key('pin_${feature.row}');
    Map<String, dynamic> mapInfo = {
      'key': feature.row,
      'title': 'N/A',
      'content': Text('N/A'),
      'images': '',
      'details': false
    };

    for (int i = 0; i < _publishedFeatures.cards.length; i++) {
      if (_publishedFeatures.cards[i].key == cardKey) {
        mapInfo['content'] = _publishedFeatures.cards[i];
        break;
      }
    }
    mapInfo['key'] = feature.row;
    switch (feature.type) {
      case 0:
        TripItem tripItem = await _publishedFeatures.tripItemRepository
            .loadTripItem(key: feature.row, id: feature.id, uri: feature.uri);
        mapInfo = {
          'title': tripItem.heading,
          'content': tripItem.subHeading,
        };
        break;
      case 1:
        PointOfInterest? pointOfInterest = await _publishedFeatures
            .pointOfInterestRepository
            .loadPointOfInterest(
                key: feature.row, id: feature.id, uri: feature.uri);
        if (pointOfInterest != null) {
          mapInfo['title'] = poiTypes[feature.poiType]['name'];
        }

        break;

      case 2:
        mt.Route? goodRoad = await _publishedFeatures.goodRoadRepository
            .loadGoodRoad(key: feature.row, id: feature.id, uri: feature.uri);
        if (goodRoad != null) {
          for (Feature feature in features) {
            if (feature.type == 1 &&
                feature.uri == goodRoad.pointOfInterestUri) {
              PointOfInterest? pointOfInterest = await _publishedFeatures
                  .pointOfInterestRepository
                  .loadPointOfInterest(
                      key: feature.row, id: feature.id, uri: feature.uri);
              if (pointOfInterest != null) {
                mapInfo['title'] =
                    poiTypes[feature.poiType]; //pointOfInterest.getName();
                mapInfo['content'] = pointOfInterest.getDescription();
                return mapInfo;
              }
            }
          }
        }
        break;
      default:
        break;
    }
    return mapInfo;
  }

  Widget _getPortraitBody() {
    // adjustMapHeight(MapHeights.full);
    /*
enum TripState {
  none,
  manual,
  automatic,
  recording,
  stoppedRecording,
  paused,
  following,
  notFollowing,
  stoppedFollowing,
  startFollowing,
}
    */

    if (!_hasRepainted) {
      if (Setup().appState.isNotEmpty) {
        CurrentTripItem().restoreState();
      }
      if (CurrentTripItem().tripState != TripState.none) {
        switch (CurrentTripItem().tripState) {
          case TripState.manual:
            {
              manual();
              break;
            }
          case TripState.editing:
            {
              editing();
              break;
            }
          case TripState.automatic:
            {
              automatic();
              break;
            }

          case TripState.recording:
            {
              record();
              break;
            }
          default:
            break;
        }
      } else if (Setup().appState.isNotEmpty) {
        CurrentTripItem().restoreState();
      } else {
        //  CurrentTripItem().tripState = TripState.none;
      }
      if (ModalRoute.of(context)!.settings.arguments != null) {
        _leadingWidgetController.changeWidget(1);
        adjustMapHeight(MapHeights.full);
        _editPointOfInterest = CurrentTripItem().pointsOfInterest.length - 1;
      }

      _hasRepainted = true;
    }
    //  debugPrint('_getPortraitBody() mapHeihght');
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: _resizeDelay),
            curve: Curves.easeInOut, // fastOutSlowIn,
            height: mapHeight,
            width: MediaQuery.of(context).size.width,
            child: _handleMap(),
          ),

          //         _handleMap(),
          _handleBottomSheetDivider(), // grab rail - GesureDetector()
          const SizedBox(
            height: 5,
          ),

          _handleTripInfo(), // Allows the trip to be planned
        ],
      ),
    );
  }

  Widget setPreferences() {
    return SizedBox(
      height: 20,
      width: MediaQuery.of(context).size.width,
      child: Row(children: [
        //  if (!_preferences.isLeft) ...[
        Icon(_preferences.isLeft ? null : Icons.arrow_back_ios,
            color: Colors.white),
        //  ],
        SizedBox(
          width: MediaQuery.of(context).size.width - 60, //delta,
          child: ListView(
            scrollDirection: Axis.horizontal,
            controller: _preferencesScrollController,
            children: <Widget>[
              SizedBox(
                width: 210,
                child: CheckboxListTile(
                  checkColor: Colors.white,
                  title: const Text('Avoid motorways',
                      style: TextStyle(color: Colors.white)),
                  value: _preferences.avoidMotorways,
                  onChanged: (value) =>
                      setState(() => _preferences.avoidMotorways = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              SizedBox(
                width: 210,
                child: CheckboxListTile(
                  hoverColor: Colors.white,
                  title: const Text('Avoid toll roads',
                      style: TextStyle(color: Colors.white)),
                  value: _preferences.avoidTollRoads,
                  onChanged: (value) =>
                      setState(() => _preferences.avoidTollRoads = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              SizedBox(
                width: 210,
                child: CheckboxListTile(
                  title: const Text('Avoid ferries',
                      style: TextStyle(color: Colors.white)),
                  value: _preferences.avoidFerries,
                  onChanged: (value) =>
                      setState(() => _preferences.avoidFerries = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
        ),
        Icon(
          _preferences.isRight ? null : Icons.arrow_forward_ios,
          color: Colors.white,
        )
      ]),
    );
  }

/*
  VectorTileProvider _tileProvider() => NetworkVectorTileProvider(
      urlTemplate: "https://drives.motatek.com/static/tiles/{z}/{x}/{y}.pbf",
      // this is the maximum zoom of the provider, not the
      // maximum of the map. vector tiles are rendered
      // to larger sizes to support higher zoom levels
      maximumZoom: 14);
*/
  addWaypoint() async {
    LatLng pos = _animatedMapController.mapController.camera.center;
    Map<String, dynamic> data;
    if (insertAfter == -1 &&
        CurrentTripItem().pointsOfInterest.isNotEmpty &&
        CurrentTripItem().pointsOfInterest[0].getType() == 12) {
      data = await appendRoute(pos);
      await _addPointOfInterest(id, userId, 12, '${data["name"]}',
          '${data["summary"]}', 15.0, pos, '');
      setState(() {
        _showMask = false;
      });
    } else if (insertAfter > -1) {
      try {
        await _singlePointOfInterest(context, pos, insertAfter);
        await loadRoutes();
        setState(() {
          _showMask = false;
        });
        insertAfter = -1;
      } catch (e) {
        debugPrint('Point of interest error: ${e.toString()}');
      }
    } else {
      data = await appendRoute(pos);
      await _addPointOfInterest(id, userId, 17, '${data["name"]}',
          '${data["summary"]}', 15.0, pos, '');
      setState(() {
        _showMask = false;
        _startLatLng = pos;
      });

      CurrentTripItem().distance = CurrentTripItem().distance +
          double.parse(data['distance'].toString());
    }
  }

  detailClose() {
    //  debugPrint('resetting _poiDetailIndex');
    if (_poiDetailIndex > -1) {
      _poiDetailIndex = -1;
      setState(() {});
    }
  }

  List<String> getTitles(int i) {
    List<String> result = [];
    if (CurrentTripItem().pointsOfInterest[i].getType() < 12) {
      result.add(CurrentTripItem().pointsOfInterest[i].getDescription() == ''
          ? 'Point of interest - ${poiTypes[CurrentTripItem().pointsOfInterest[i].getType()]["name"]}'
          : CurrentTripItem().pointsOfInterest[i].getDescription());
      result.add(CurrentTripItem().pointsOfInterest[i].getDescription());
    } else {
      result.add(
          'Waypoint ${i + 1} -  ${CurrentTripItem().pointsOfInterest[i].getName()}');
      result.add(CurrentTripItem().pointsOfInterest[i].getDescription());
    }
    return result;
  }

  pointOfInterestRemove(int idx) async {
    /// Removing a poi:
    CurrentTripItem().removePointOfInterestAt(idx);
    loadRoutes();
    setState(() {});
  }

  ///
  /// _handleFabs()
  /// Controls the Loading Action Button behavious
  ///

  Column _handleFabs() {
    if (_places.isNotEmpty) {
      //    debugPrint('handleFabs() called _places.length: ${_places.length}');
    }
    //double screenHeight = MediaQuery.of(context).size.height;
    // debugPrint('Screen height: $screenHeight');
    return Column(
      //  mainAxisSize: MainAxisSize.max, // MediaQuery.of(context).size.height ,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (listHeight == 0) ...[
          SizedBox(
            height: 175,
          ),
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            // color: Colors.blueAccent,
            width: _width,
            height: _height,
            decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(_height / 2)),
            curve: Curves.fastOutSlowIn,
            onEnd: () => setState(() => _expanded = _width > _height),
            child: _expanded
                ? Row(
                    children: [
                      SizedBox(
                        width: _width - _height,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 5, 2, 5),
                          child: AutocompletePlace(
                            options: _places,
                            optionsMaxHeight: 100,
                            searchLength: 3,
                            decoration: InputDecoration(
                              filled: true,

                              fillColor: Colors.white,
                              //     enabledBorder: OutlineInputBorder(),
                              border: _width > _height
                                  ? OutlineInputBorder()
                                  : null,
                              //     enabled: _width > _height,
                              hintText: 'Enter place name...',
                            ),
                            keyboardType: TextInputType.text,
                            onSelect: (chosen) async {
                              _autoCentre = false;
                              _alignPositionOnUpdate = AlignOnUpdate.never;
                              _alignDirectionOnUpdate = AlignOnUpdate.never;
                              _animatedMapController.animateTo(
                                  dest: LatLng(chosen.lat, chosen.lng));
                            },
                            onChange: (text) => (debugPrint('onChange: $text')),
                            onUpdateOptionsRequest: (query) {
                              debugPrint('Query: $query');
                              getDropdownItems(query);
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(4, 4, 0, 0),
                          child: IconButton(
                            onPressed: () {
                              setState(() => _width = _height);
                              _expanded = false;
                            },
                            icon: Icon(
                                _width > _height
                                    ? Icons.search_off_outlined
                                    : Icons.search_outlined,
                                size: _height / 2,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 4, 0),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _expanded = false;
                            _width = MediaQuery.of(context).size.width - 40;
                          });
                        },
                        icon: Icon(Icons.search,
                            size: _height / 2, color: Colors.white),
                      ),
                    ),
                  ),
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
                await _osmFeatures.update(fence: _cacheFence);
                setState(() => ());
                _osmIncludingChange = false;
              }
            },
          ),
          const SizedBox(
            height: 10,
          ),

          //Zoomer(height: 50, width: 50, onZoomChanged: (_) => (), zoom: 12),
          // if (/*[AppState.createTrip, AppState.driveTrip].contains(_appState) && */
          //     !_showSearch && !_showPreferences) ...[
          if ([TripState.recording, TripState.following]
              .contains(CurrentTripItem().tripState)) ...[
            FloatingActionButton(
              heroTag: 'broadcast',
              onPressed: () => messageGroup(-1),
              backgroundColor: Colors.blue,
              shape: const CircleBorder(),
              child: Icon(
                Icons.chat_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (_goodRoad.isGood) ...[
              FloatingActionButton(
                heroTag: 'goodRoad',
                onPressed: () => setState(() => _goodRoad.isGood = false),
                backgroundColor: _goodRoad.isGood
                    ? uiColours.keys.toList()[Setup().goodRouteColour]
                    : Colors.blue,
                shape: const CircleBorder(),
                child: Icon(
                  Icons.add_road,
                  color: Colors.white,
                ),
              ),
            ] else ...[
              FloatingTextEdit(
                key: Key('ftepoi'),
                focusNode: FocusNode(),
                controller: _floatingTextEditController1,
                keyboardType: TextInputType.name,
                closedIcon: Icons.add_road,
                openIcon: Icons.add_task_outlined,
                onOpen: (_) => CurrentTripItem().saveState(),
                onClose: (description, audio) => setState(
                  () {
                    addGoodRoad(
                        position: LatLng(_currentPosition.latitude,
                            _currentPosition.longitude),
                        name: description,
                        audio: audio);
                    _goodRoad.isGood = true;
                    _editPointOfInterest =
                        CurrentTripItem().pointsOfInterest.length - 1;
                  },
                ),
                fillColor: Colors.white,
                inputBorder: _width > _height ? OutlineInputBorder() : null,
                hint: 'Description to edit later...',
                suffix:
                    IconButton(onPressed: (() => ()), icon: Icon(Icons.mic)),
              ),
            ],
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
                  LatLng(_currentPosition.latitude, _currentPosition.longitude),
                  audio,
                );
                _editPointOfInterest =
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
              if (_alignPositionOnUpdate == AlignOnUpdate.always) {
                _alignPositionOnUpdate = AlignOnUpdate.never;
                setState(() => _autoCentre = false);
              } else {
                _alignPositionOnUpdate = AlignOnUpdate.always;
                _currentPosition = await Geolocator.getCurrentPosition();
                //     debugPrint('Position: ${_currentPosition.toString()}');
                _animatedMapController.animateTo(
                    dest: LatLng(
                        _currentPosition.latitude, _currentPosition.longitude));
                setState(() => _autoCentre = true);
              }
            },
            heroTag: 'mapCentre',
            backgroundColor: Colors.blue,
            shape: const CircleBorder(),
            child: Icon(Icons.my_location,
                color: _autoCentre ? Colors.white : Colors.grey),
          ),
/*
          FloatingActionButton(
            onPressed: () => CurrentTripItem().saveState(),
            heroTag: 'test1',
            backgroundColor: Colors.blue,
            shape: const CircleBorder(),
            child: Icon(Icons.save,
                color: _autoCentre ? Colors.white : Colors.grey),
          ),
          FloatingActionButton(
            onPressed: () => setState(() => CurrentTripItem().restoreState()),
            heroTag: 'test2',
            backgroundColor: Colors.blue,
            shape: const CircleBorder(),
            child: Icon(Icons.restore,
                color: _autoCentre ? Colors.white : Colors.grey),
          ),
*/
          //  ]),
          //  ]
        ],
      ],
    );
  }

  getDropdownItems(String query) async {
    _places.clear();
    _places.addAll(await getPlaces(value: query));
    // debugPrint(
    //     'For query query $query dropdownOptions.length = ${_places.length}');
    setState(() {});
  }

/*
This looks like the way of implementing the vector tile layer from
OSRM

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
*/

  ///
  /// handlMap()
  /// does all the map UI
  /// Wrapped in a RepaintBoundary so that a screenshot of the map can be saved for the Route description
  ///

  Widget _handleMap() {
    if (listHeight == -1) {
      adjustMapHeight(MapHeights.full);
    }
    return RepaintBoundary(
      key: mapKey,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _animatedMapController.mapController,
            options: MapOptions(
              onMapEvent: checkMapEvent,
              onMapReady: () async {
                Fence newFence = Fence.fromBounds(
                    _animatedMapController.mapController.camera.visibleBounds);
                mapController.mapEventStream.listen((event) {});
                _cacheFence.setBounds(bounds: newFence, deltaDegrees: 0.5);
                _osmFeatures.update(fence: _cacheFence).then((osupdate) =>
                    _publishedFeatures.update(screenFence: _cacheFence).then(
                      (puupdate) {
                        if (puupdate || osupdate) {
                          setState(() => {});
                        }
                      },
                    ));
                if (!_tripStarted) {
                  _currentPosition = await Geolocator.getCurrentPosition();
                  _animatedMapController.animateTo(
                      dest: LatLng(_currentPosition.latitude,
                          _currentPosition.longitude));
                  _tripStarted = true;
                }
              },
              onPositionChanged: (position, hasGesure) {
                CurrentTripItem().highliteActions = HighliteActions.none;
                if ([TripState.manual, TripState.editing]
                    .contains(CurrentTripItem().tripState)) {
                  CurrentTripItem().tripActions = TripActions.none;
                  int routeIdx = lineAtCentre(
                      routes:
                          CurrentTripItem().routes, // _publishedFeatures.routes
                      controller: _animatedMapController);
                  for (int i = 0; i < CurrentTripItem().routes.length; i++) {
                    if (i == routeIdx) {
                      CurrentTripItem().highliteActions =
                          HighliteActions.routeHighlited;
                      // _routes[index].color = colour;
                      CurrentTripItem().routes[i].color =
                          uiColours.keys.toList()[Setup().selectedColour];
                      //       debugPrint(
                      //           'setting route()[i].colour => ${uiColours.values.toList()[Setup().selectedColour]}');
                    } else {
                      CurrentTripItem().routes[i].color =
                          uiColours.keys.toList()[Setup().routeColour];
                    }
                  }
                  highlightedIndex = routeIdx;
                }

                if (_tripId != null) {
                  if (socket.connected) {
                    socket.emit('trip_message', {
                      'message': '',
                      'lat': _animatedMapController
                          .mapController.camera.center.latitude,
                      'lng': _animatedMapController
                          .mapController.camera.center.longitude
                    });
                  }
                }
                if (hasGesure) {
                  _updateMarkerSize(position.zoom);
                }

                Fence newFence = Fence.fromBounds(
                    _animatedMapController.mapController.camera.visibleBounds);

                if (_updateOverlays) {
                  if (!_cacheFence.contains(bounds: newFence)) {
                    _updateOverlays = false;
                    _cacheFence.setBounds(bounds: newFence, deltaDegrees: 0.5);
                    _osmFeatures.update(fence: _cacheFence).then(
                          (update) => _publishedFeatures
                              .update(screenFence: _cacheFence)
                              .then(
                            (update2) {
                              if (update || update2) {
                                setState(() => {});
                              }
                            },
                          ),
                        );
                  }
                }

                _mapRotation =
                    _animatedMapController.mapController.camera.rotation;
              },
              initialCenter: routePoints[0],
              initialZoom: 15.0, // 15,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                  enableMultiFingerGestureRace: true,
                  flags: InteractiveFlag.doubleTapDragZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.pinchMove),
            ),
            children: [
              VectorTileLayer(
                  theme: _style.theme, //_style.theme,
                  //sprites: _style.sprites,
                  tileProviders: _style.providers,
                  //  showTileDebugInfo: true,
                  layerMode: VectorTileLayerMode.vector,
                  //  cacheFolder: getCacheFolder,
                  tileOffset: TileOffset.DEFAULT),
              CurrentLocationLayer(
                focalPoint: const FocalPoint(
                  ratio: Point(0.0, 1.0),
                  offset: Point(0.0, -60.0),
                ),
                alignPositionStream: _allignPositionStreamController.stream,
                alignDirectionStream: _allignDirectionStreamController.stream,
                alignPositionOnUpdate: _alignPositionOnUpdate,
                alignDirectionOnUpdate: _alignDirectionOnUpdate,
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    child: Icon(
                      Icons.navigation,
                      color: Colors.white,
                    ),
                  ),
                  markerSize: ui.Size(30, 30),
                  markerDirection: MarkerDirection.heading,
                ),
              ),
              mt.RouteLayer(
                polylines: CurrentTripItem().routes,
              ),
              mt.RouteLayer(
                polylines: _publishedFeatures.goodRoads,
              ),
              mt.RouteLayer(
                polylines: CurrentTripItem().goodRoads,
              ),
              MarkerLayer(markers: CurrentTripItem().pointsOfInterest),
              MarkerLayer(
                  markers: _publishedFeatures.markers,
                  alignment: Alignment.topCenter),
              MarkerLayer(markers: _following),
              MarkerLayer(markers: _osmFeatures.amenities),
            ],
          ),
          if (_speed > 0.01) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 0, 120),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.red,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.black,
                    child: Text('${_speed.truncate()}',
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Wrap(
                spacing: 5,
                children: getChips(),
              ),
            ),
          ),
          if (_showTarget) ...[
            CustomPaint(
              painter: TargetPainter(
                  top: mapHeight / 2,
                  left: MediaQuery.of(context).size.width / 2,
                  color: insertAfter == -1 ? Colors.black : Colors.red),
            )
          ],
          getDirections(_directionsIndex),
          if (_showMask) ...[
            _getOverlay2(),
          ]
        ],
      ),
    );
  }

  int lineAtCentre(
      {required List<mt.Route> routes,
      required AnimatedMapController controller}) {
    final double delta = ((controller.mapController.camera.visibleBounds.east -
                controller.mapController.camera.visibleBounds.west) /
            50)
        .abs();
    int closest = -1;
    double distance = delta;
    LatLng centre = controller.mapController.camera.center;
    for (int i = 0; i < routes.length; i++) {
      for (LatLng point in routes[i].points) {
        double deltaX = (point.longitude - centre.longitude).abs();
        double deltaY = (point.latitude - centre.latitude).abs();
        if (deltaX < delta && deltaY < delta) {
          closest = i;
          if (deltaX > deltaY) {
            if (distance > deltaY) {
              distance = deltaY;
              closest = i;
            }
          } else if (distance > deltaX) {
            distance = deltaX;
            closest = i;
          }
        }
      }
    }
    return closest;
  }

/* TileProviders(
                    {'openmaptiles': _tileProvider()},
                  ), //
 */

  Align getDirections(int index) {
    if (index >= 0 &&
        CurrentTripItem().tripState == TripState.following &&
        CurrentTripItem().maneuvers.isNotEmpty) {
      CurrentTripItem().maneuvers[index].distance = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          CurrentTripItem().maneuvers[index].location.latitude,
          CurrentTripItem().maneuvers[index].location.longitude);

      return Align(
        alignment: Alignment.topLeft,
        child: DirectionTile(
          direction: CurrentTripItem().maneuvers[index],
          index: index,
          directions: CurrentTripItem().maneuvers.length,
        ),
      );
    } else {
      return const Align(
        alignment: Alignment.topLeft,
      );
    }
  }

  dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<Directory> getCacheFolder() async {
    String appDocumentDirectory =
        (await getApplicationDocumentsDirectory()).path;
    Directory cacheDirectory = Directory('$appDocumentDirectory/cache');
    if (!await cacheDirectory.exists()) {
      await Directory('$appDocumentDirectory/cache').create();
    }
    return cacheDirectory;
    //  Directory cacheDir = Setup().cacheDirectory;
    //  if (!await cacheDir.exists()) {
    //    await cacheDir.create();
    //  }
    //  return cacheDir;
  }

  List<ActionChip> getChips() {
    List<String> chipNames = [];
    List<ActionChip> chips = [];
    if (CurrentTripItem().tripState == TripState.startFollowing) {
      stopFollowing();
    }
    final List<String> labels = [
      'Create manually',
      'Track drive',
      'Waypoint',
      'Point of interest',
      'Great road',
      'Start recording',
      'Stop recording',
      'Pause recording',
      'Save trip',
      'Clear trip',
      'Split route',
      'Remove section',
      'Great road end',
      'Follow route',
      'Stop following',
      'Steps',
      'Group',
      'Edit route',
      'Start or end',
      'Trip info',
      'Back',
      'Write message',
      'Read messages',
      'Reply',
      'Send',
    ];

    final List<Function> methods = [
      addManually,
      addAutomatically,
      waypoint,
      pointOfInterest,
      greatRoad,
      startRecording,
      stopRecording,
      pauseRecording,
      saveTrip,
      clearTrip,
      splitRoute,
      removeSection,
      greatRoadEnd,
      followRoute,
      stopFollowing,
      steps,
      group,
      editRoute,
      changeStartOrEnd,
      tripData,
      back,
    ];

    final List<IconData> avatars = [
      Icons.touch_app,
      Icons.directions_car,
      Icons.pin_drop,
      Icons.add_photo_alternate,
      Icons.add_road,
      Icons.play_arrow,
      Icons.stop,
      Icons.pause,
      Icons.save,
      Icons.wrong_location,
      Icons.cut,
      Icons.add_photo_alternate,
      Icons.remove_road,
      Icons.directions,
      Icons.directions_off,
      Icons.alt_route,
      Icons.directions_car,
      Icons.edit,
      Icons.start,
      Icons.map,
      Icons.arrow_back,
    ];

    if ([TripActions.saving, TripActions.saved]
        .contains(CurrentTripItem().tripActions)) {
      CurrentTripItem().tripActions = TripActions.saved;
      return chips;
    }

    if (CurrentTripItem().tripState == TripState.none) {
      chipNames.clear();
      chipNames
        ..add('Create manually')
        ..add('Track drive');
    }
    if ([TripState.manual, TripState.editing]
        .contains(CurrentTripItem().tripState)) {
      chipNames
        ..add('Waypoint')
        ..add('Point of interest');
    }
    if (CurrentTripItem().tripState == TripState.editing) {
      chipNames.add('Start or end');
    }

    if ([TripState.automatic, TripState.stoppedRecording, TripState.paused]
        .contains(CurrentTripItem().tripState)) {
      chipNames.add('Start recording');
    }
    if (CurrentTripItem().tripState == TripState.recording) {
      chipNames
        ..add('Stop recording')
        ..add('Pause recording');
    }
    if (CurrentTripItem().pointsOfInterest.isNotEmpty &&
        [TripState.manual, TripState.stoppedRecording]
            .contains(CurrentTripItem().tripState)) {
      if (!CurrentTripItem().isSaved) {
        chipNames.add('Save trip');
      }
      chipNames.add('Clear trip');
    }
    if (CurrentTripItem().highliteActions == HighliteActions.routeHighlited) {
      chipNames
        ..add('Split route')
        ..add('Remove section');
      if (CurrentTripItem().highliteActions ==
          HighliteActions.greatRoadStarted) {
        chipNames.add('Great road end');
      } else {
        chipNames.add('Great road');
      }
    }
    if ([TripState.stoppedFollowing, TripState.notFollowing]
        .contains(CurrentTripItem().tripState)) {
      chipNames.add('Follow route');
      chipNames.add('Clear trip');
    }
    if (CurrentTripItem().tripState == TripState.following) {
      chipNames.add('Stop following');
    }
    if ([
      TripState.following,
      TripState.stoppedFollowing,
      TripState.notFollowing
    ].contains(CurrentTripItem().tripState)) {
      if (CurrentTripItem().tripActions == TripActions.showGroup) {
        chipNames.add('Trip info');
      } else {
        chipNames.add('Group');
      }
      if (CurrentTripItem().tripActions == TripActions.showSteps) {
        chipNames.add('Trip info');
      } else {
        chipNames.add('Steps');
      }
      if (CurrentTripItem().tripState != TripState.following) {
        chipNames.add('Edit route');
      }
    }

    for (int i = 0; i < chipNames.length; i++) {
      int index = labels.indexOf(chipNames[i]);
      if (index >= 0) {
        chips.add(ActionChip(
            visualDensity: const VisualDensity(horizontal: 0.0, vertical: 0.5),
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            label: Text(labels[index],
                style: const TextStyle(fontSize: 16, color: Colors.white)),
            elevation: 10,
            shadowColor: Colors.black,
            onPressed: () => methods[index](),
            avatar: Icon(avatars[index], size: 20, color: Colors.white)));
      } else {
        debugPrint('Chip mismatch: ${chipNames[i]}');
      }
    }

    return chips;
  }

  /// Have sptit out the state change from the action part
  /// as want to use the state change when restoring the
  /// CreateTrip route without calling setState which is
  /// embedded in adjustMapHeight()
  /// ie automatic called when restoring CurrentTrip state
  /// automatically() called on the ActionChip onPress()

  void automatic() {
    _showMask = false;
    _showTarget = false;
    _autoCentre = true;
    _alignPositionOnUpdate = AlignOnUpdate.never;
    _alignDirectionOnUpdate = AlignOnUpdate.never;
    _leadingWidgetController.changeWidget(1);
    _appState = AppState.createTrip;
    _title = 'Create a new trip automatically';
    developer.log(_title, name: '_title automatic() 1866');
  }

  void addAutomatically() {
    setState(() {
      automatic();
      CurrentTripItem().tripActions = TripActions.headingDetail;
      CurrentTripItem().tripState = TripState.automatic;
      adjustMapHeight(MapHeights.headers);
    });
  }

  void manual() {
    _showMask = false;
    _showTarget = true; // false;
    _autoCentre = false;
    CurrentTripItem().tripState = TripState.manual;
    _leadingWidgetController.changeWidget(1);
    _title = 'Plan a new trip manually';
    developer.log(_title, name: '_title manual() 1886');
  }

  void editing() {
    _showMask = false;
    _showTarget = true; // false;
    _autoCentre = false;
    CurrentTripItem().tripState = TripState.editing;
    _leadingWidgetController.changeWidget(1);
    _title = 'Edit trip ${CurrentTripItem().heading}';
    developer.log(_title, name: '_title editing() 1896');
  }

  void addManually() {
    setState(() {
      manual();
      CurrentTripItem().tripActions = TripActions.headingDetail;
      CurrentTripItem().tripState = TripState.manual;
      adjustMapHeight(MapHeights.headers);
    });
  }

  void waypoint() async {
    _goodRoad.isGood = false;
    setState(() {
      _showMask = true;
      CurrentTripItem().tripActions = TripActions.none;
      _editPointOfInterest = -1;
      CurrentTripItem().isSaved = false;
      if (CurrentTripItem().pointsOfInterest.isEmpty) {
        _lastLatLng == const LatLng(0.00, 0.00);
        _startLatLng = const LatLng(0.00, 0.00);
        adjustMapHeight(MapHeights.full);
        CurrentTripItem().clearRoutes();
        CurrentTripItem().clearManeuvers();
      }
    });
    await addWaypoint();
  }

  void pointOfInterest() async {
    _showMask = true;
    LatLng pos = _animatedMapController.mapController.camera.center;
    String name = await getPoiName(latLng: pos, name: 'Point of interest');
    await _addPointOfInterest(id, userId, 15, name, '', 30.0, pos, '');
    CurrentTripItem().isSaved = false;
    setState(() {
      _showMask = false;
      CurrentTripItem().tripActions = TripActions.pointOfInterest;
      _editPointOfInterest = CurrentTripItem().pointsOfInterest.length - 1;
      adjustMapHeight(MapHeights.pointOfInterest);
    });
  }

  void greatRoad() {
    if (_routeAtCenter.routeIndex < CurrentTripItem().routes.length) {
      String txt =
          'Good road start'; //_goodRoad.isGood ? 'Great road start' : 'Great road end';
      setState(() {
        CurrentTripItem().isSaved = false;
        _goodRoad.isGood =
            true; // Must be called first as it sets all values to -1
        _goodRoad.routeIdx1 = _routeAtCenter.routeIndex;
        _goodRoad.pointIdx1 = _routeAtCenter.pointIndex;
        LatLng pos = CurrentTripItem().routes[_routeAtCenter.routeIndex].points[
            _routeAtCenter
                .pointIndex]; // _animatedMapController.mapController.camera.center;
        _addGreatRoadStartLabel(id, userId, 13, txt, '', 80, pos);

        CurrentTripItem().highliteActions = HighliteActions.greatRoadStarted;
        _cutRoutes.clear();
      });
    }
  }

  void record() async {
    _alignDirectionOnUpdate =
        Setup().rotateMap ? AlignOnUpdate.always : AlignOnUpdate.never;
    _alignPositionOnUpdate = AlignOnUpdate.always;
    _autoCentre = true;
    _showTarget = false;
    getLocationUpdates();
    CurrentTripItem().tripState = TripState.recording;
    CurrentTripItem().tripActions = TripActions.none;
    _leadingWidgetController.changeWidget(1);
    _title = 'Creating trip automatically';
    developer.log(_title, name: '_title record() 1972');
  }

  void startRecording() async {
    if (CurrentTripItem().pointsOfInterest.isEmpty) {
      CurrentTripItem().clearRoutes;
      record();
    }

    Geolocator.getCurrentPosition().then((pos) {
      _currentPosition = pos;
      getPoiName(
              latLng: LatLng(pos.latitude, pos.longitude), name: 'Trip start')
          .then((name) {
        _addPointOfInterest(
          id,
          userId,
          9,
          name,
          'Trip start',
          20.0,
          LatLng(pos.latitude, pos.longitude),
          '',
        );
      });
    });

    setState(() => record());
  }

  void stopRecording() async {
    _positionStream.cancel();
    CurrentTripItem().tripState = TripState.stoppedRecording;
    _alignDirectionOnUpdate = AlignOnUpdate.never;
    _alignPositionOnUpdate = AlignOnUpdate.never;
    CurrentTripItem().tripState = TripState.stoppedRecording;
    if (CurrentTripItem().routes.isNotEmpty) {
      final LatLng pos =
          LatLng(_currentPosition.latitude, _currentPosition.longitude);
      await getPoiName(latLng: pos, name: 'Trip end').then((name) {
        _addPointOfInterest(id, userId, 10, name, 'Trip end', 20.0, pos, '');
      });
    }
    setState(() {});
  }

  void pauseRecording() {
    setState(() {
      _trackingState(trackingOn: false);
      CurrentTripItem().tripState = TripState.paused;
    });
  }

  void saveTrip() async {
    setState(() {
      CurrentTripItem().tripActions = TripActions.saving;
      CurrentTripItem().highliteActions = HighliteActions.none;
      adjustMapHeight(MapHeights.full);
      //    CurrentTripItem().saveLocal();
    });
    int tries = 0;
    while (CurrentTripItem().tripActions != TripActions.saved && ++tries < 5) {
      await Future.delayed(const Duration(seconds: 1));
      //   debugPrint('Trying to take trip image - try no: $tries');
      setState(() {});
    }

    if (CurrentTripItem().tripActions != TripActions.saved) {
      //  debugPrint('Failed');
    } else {
      //  debugPrint('Succeded');
      try {
        ui.Image mapImage = await getMapImage();
        CurrentTripItem().tripActions = TripActions.none;
        CurrentTripItem().mapImage = mapImage;
        await _saveTrip();
        //  debugPrint('_saveTrip response: $ok');
        CurrentTripItem().isSaved = true;
        _title = CurrentTripItem().heading;
        developer.log(_title, name: '_title saveTrip() 2051');
        // CurrentTripItem().tripState = TripState.notFollowing;
      } catch (e) {
        String err = e.toString();
        debugPrint('Error: $err');
      }
    }
  }

  void clearTrip() {
    setState(() {
      CurrentTripItem().clearAll();
      _lastLatLng = const LatLng(0.00, 0.00);
      _startLatLng = const LatLng(0.00, 0.00);
      CurrentTripItem().tripState = TripState.none;
    });
  }

  void splitRoute() async {
    _showTarget = true;
    int idx = insertWayointAt(
        pointsOfInterest: CurrentTripItem().pointsOfInterest,
        pointToFind: _routeAtCenter.pointOnRoute);

    await _singlePointOfInterest(
            context, _animatedMapController.mapController.camera.center, idx,
            refresh: false)
        .then((res) {
      try {
        //    debugPrint('Result : ${res.toString()}');
        _cutRoutes.clear();
        _splitRoute();
      } catch (e) {
        debugPrint('Error splitting route: ${e.toString()}');
      }
      CurrentTripItem().isSaved = false;
      setState(() {
        CurrentTripItem().highliteActions = HighliteActions.routeHighlited;
      });
    });
  }

  void removeSection() async {
    _showTarget = true;
    LatLng pos = _animatedMapController.mapController.camera.center;
    await getPoiName(latLng: pos, name: 'Point of interest').then((name) {
      _addPointOfInterest(id, userId, 15, name, '', 30.0, pos, '');
    });
    CurrentTripItem().isSaved = false;
    setState(() {});
  }

  void greatRoadEnd() async {
    setState(() {
      CurrentTripItem().highliteActions = HighliteActions.greatRoadEnded;
      if (_routeAtCenter.routeIndex < CurrentTripItem().routes.length) {
        _goodRoad.routeIdx2 = _routeAtCenter.routeIndex;
        _goodRoad.pointIdx2 = _routeAtCenter.pointIndex;
        int start = _goodRoad.pointIdx1;
        int end = _goodRoad.pointIdx2;
        if (_goodRoad.pointIdx1 > _goodRoad.pointIdx2) {
          start = _goodRoad.pointIdx2;
          end = _goodRoad.pointIdx1;
        }
        List<LatLng> goodPoints = [
          for (int i = start; i < end; i++)
            LatLng(
                CurrentTripItem()
                    .routes[_goodRoad.routeIdx1]
                    .points[i]
                    .latitude,
                CurrentTripItem()
                    .routes[_goodRoad.routeIdx1]
                    .points[i]
                    .longitude)
        ];
        CurrentTripItem().addGoodRoad(
          mt.Route(
              id: -1,
              points: goodPoints,
              borderColor: uiColours.keys.toList()[Setup().goodRouteColour],
              color: uiColours.keys.toList()[Setup().goodRouteColour],
              strokeWidth: 5,
              pointOfInterestIndex:
                  CurrentTripItem().pointsOfInterest.length - 1),
        );
        _showMask = false;
        CurrentTripItem().tripActions = TripActions.pointOfInterest;
        _editPointOfInterest = CurrentTripItem().pointsOfInterest.length - 1;
        adjustMapHeight(MapHeights.pointOfInterest);
      }
      _goodRoad.isGood = false;
    });
  }

  void followRoute() async {
    Geolocator.getCurrentPosition().then((val) {
      getLocationUpdates();
      setState(() {
        CurrentTripItem().tripActions = TripActions.none;
        _currentPosition = val;
        CurrentTripItem().tripState = TripState.following;
        _animatedMapController.animateTo(
            dest:
                LatLng(_currentPosition.latitude, _currentPosition.longitude));
        _alignPositionOnUpdate = AlignOnUpdate.always;
        _alignDirectionOnUpdate =
            Setup().rotateMap ? AlignOnUpdate.always : AlignOnUpdate.never;
        _showTarget = false;
        adjustMapHeight(MapHeights.full);
      });
    });
  }

  void stopFollowing() {
    _alignPositionOnUpdate = AlignOnUpdate.never;
    _alignDirectionOnUpdate = AlignOnUpdate.never;
    CurrentTripItem().tripState = TripState.stoppedFollowing;
  }

  void steps() {
    setState(() {
      CurrentTripItem().tripActions = TripActions.showSteps;
      adjustMapHeight(MapHeights.headers);
    });
  }

  void group() {
    setState(() {
      CurrentTripItem().tripActions = TripActions.showGroup;
      adjustMapHeight(MapHeights.headers);
    });
  }

  void tripData() {
    setState(() {
      CurrentTripItem().tripActions = TripActions.none;
      adjustMapHeight(MapHeights.full);
    });
  }

  void back() {
    if ([TripState.stoppedFollowing, TripState.notFollowing]
        .contains(CurrentTripItem().tripState)) {
      if (CurrentTripItem().id < 0 && CurrentTripItem().driveUri.isNotEmpty) {
        _appState = AppState.download;
      } else {
        _appState = AppState.myTrips;
      }
      clearTrip();
    }
    CurrentTripItem().tripState = TripState.none;
    CurrentTripItem().tripActions = TripActions.none;
    _showTarget = false;
    setState(() => adjustMapHeight(MapHeights.full));
  }

  void loadGroup() async {
    String today = DateFormat('yyyy-mm-dd').format(DateTime.now());
    today = '2025-05-14'; // debug remove
    List<Map<String, dynamic>> drivers;
    try {
      drivers = await getDrivers(
          driveId: CurrentTripItem().driveUri, driveDate: today, accepted: 2);
    } catch (e) {
      debugPrint('error getting drivers: ${e.toString()}');
      drivers = [];
    }
    _following.clear();
    int cIndex = 2; // dont't want to use
    if (drivers.isNotEmpty) {
      try {
        socket.connect();
      } catch (e) {
        debugPrint('Woops> ${e.toString()}');
      }
      _tripId = drivers[0]['group_drive_id'];
      for (Map<String, dynamic> driver in drivers) {
        cIndex = cIndex < 16 ? cIndex++ : 2;
        _following.add(Follower(
          uri: driver['user_uri'] ?? '',
          driveId: driver['group_drive_id'] ?? CurrentTripItem().driveId,
          forename: driver['user_forename'] ?? 'N/A',
          surname: driver['user_surname'] ?? 'N/A',
          phoneNumber: driver['user_phone'],
          car: driver['user_car'] ?? 'N/A',
          registration: driver['user_car_reg'] ?? 'N/A',
          iconColour: cIndex,
          position: const LatLng(51.497157, -0.619253), // 51.459024 -0.580205
          marker: MarkerWidget(
            type: 16,
            description: '',
            angle: -_mapRotation * pi / 180,
            colourIdx: cIndex,
          ),
        ));
      }
    }
  }

  void editRoute() async {
    setState(() {
      _showTarget = true;
      CurrentTripItem().tripActions = TripActions.none;
      _appState = AppState.createTrip;
      CurrentTripItem().tripState = TripState.editing;
      _title = 'Editing: ${CurrentTripItem().heading}';
      developer.log(_title, name: 'editRoute() 2258');
    });
  }

  void changeStartOrEnd() async {
    bool changed = await changeTripStart(context, _currentPosition,
        _animatedMapController.mapController.camera.center);
    if (changed) {
      setState(() => CurrentTripItem().isSaved = false);
    }
  }

  /// _splitRoute() splits a route putting the two split parts contiguously in CurrentTripItem().routes array
  /// if being used to split a goodRoad then on the 2nd split it sets the colour and borderColour
  /// for the affected routes and returns the LatNng for the goodRoad marker point

  Future<LatLng> _splitRoute() async {
    LatLng result = const LatLng(0, 0);
    CurrentTripItem().isSaved = false;
    try {
      int newRouteIdx = 0;
      mt.Route newRoute = mt.Route(
          id: -1,
          points: [],
          color: _routeColour(false),
          borderColor: _routeColour(false),
          strokeWidth: 5);

      if (_routeAtCenter.routeIndex < CurrentTripItem().routes.length - 1) {
        CurrentTripItem().insertRoute(newRoute, _routeAtCenter.routeIndex + 1);
        newRouteIdx = _routeAtCenter.routeIndex + 1;
      } else {
        CurrentTripItem().addRoute(newRoute);
        newRouteIdx = CurrentTripItem().routes.length - 1;
      }
      for (int i = _routeAtCenter.pointIndex;
          i < CurrentTripItem().routes[_routeAtCenter.routeIndex].points.length;
          i++) {
        CurrentTripItem().routes[newRouteIdx].points.add(CurrentTripItem()
            .routes[_routeAtCenter.routeIndex]
            .points
            .removeAt(i));
        if (CurrentTripItem().routes[newRouteIdx].points.length > 1 &&
            i <
                CurrentTripItem()
                    .routes[_routeAtCenter.routeIndex]
                    .offsets
                    .length) {
          CurrentTripItem().routes[newRouteIdx].offsets.add(CurrentTripItem()
              .routes[_routeAtCenter.routeIndex]
              .offsets
              .removeAt(i));
        }
      }

      if (_goodRoad.isGood &&
          _goodRoad.routeIdx1 > -1 &&
          _goodRoad.routeIdx2 > -1) {
        /// Now set the good road flag for the split routes
        /// _splitRoute() puts the two parts of the cut route contiguously
        ///
        ///       a           b         c
        ///  O----------O-----X----O----------O       route b gests plit int b & b2
        ///
        ///       a        b    b2      c
        ///  O----------O-----O----O----------O
        ///
        ///       a        b    b2      c
        ///  O-----X----O--X--O--X--O----X----O      for 2nd split there are 4 possibilities
        ///        1       2     3       4
        ///
        /// roots are held in array CurrentTripItem().routes
        ///
        ///    SPLIT 1 on route b           SPLIT 2 @ X  4 possibilities
        /// a ----------  a ----------      a ----X-----  1) X < b      2nd bit of a + all b are good
        /// b ----X-----  b -----           b --X--       2) X == b     2nd bit of b is good
        /// c ----------  b2-----           b2--X--       3) X == b+1   1st bit of b2 is good
        ///               c ----------      c ----X-----  4) X > b+1    all from b2 to c are good
        ///

        List<LatLng> goodPoints = [];

        /// 1) X < b      2nd bit of a + all b are good
        if (_goodRoad.routeIdx2 < _goodRoad.routeIdx1) {
          for (int i = _goodRoad.routeIdx2 + 1; i < _goodRoad.routeIdx1; i++) {
            CurrentTripItem().routes[i].color = _routeColour(true);
            CurrentTripItem().routes[i].borderColor = _routeColour(true);
            for (int j = 0;
                j < CurrentTripItem().routes[i].points.length;
                j++) {
              goodPoints.add(CurrentTripItem().routes[i].points[j]);
            }
          }
        } else if (_goodRoad.routeIdx2 == _goodRoad.routeIdx1) {
          CurrentTripItem().routes[_goodRoad.routeIdx2 + 1].color =
              _routeColour(true);
          CurrentTripItem().routes[_goodRoad.routeIdx2 + 1].borderColor =
              _routeColour(true);
          for (int j = 0;
              j <
                  CurrentTripItem()
                      .routes[_goodRoad.routeIdx2 + 1]
                      .points
                      .length;
              j++) {
            goodPoints.add(
                CurrentTripItem().routes[_goodRoad.routeIdx2 + 1].points[j]);
          }
        } else if (_goodRoad.routeIdx2 == _goodRoad.routeIdx1 + 1) {
          CurrentTripItem().routes[_goodRoad.routeIdx2].color =
              _routeColour(true);
          CurrentTripItem().routes[_goodRoad.routeIdx2].borderColor =
              _routeColour(true);
          for (int j = 0;
              j < CurrentTripItem().routes[_goodRoad.routeIdx2].points.length;
              j++) {
            goodPoints
                .add(CurrentTripItem().routes[_goodRoad.routeIdx2].points[j]);
          }
        } else if (_goodRoad.routeIdx2 > _goodRoad.routeIdx1) {
          for (int i = _goodRoad.routeIdx1 + 1; i < _goodRoad.routeIdx2; i++) {
            CurrentTripItem().routes[i].color = _routeColour(true);
            CurrentTripItem().routes[i].borderColor = _routeColour(true);
            for (int j = 0;
                j < CurrentTripItem().routes[i].points.length;
                j++) {
              goodPoints.add(CurrentTripItem().routes[i].points[j]);
            }
          }
        }
        result = goodPoints[goodPoints.length ~/ 2];
      }
    } catch (e) {
      debugPrint('splitRoute error: ${e.toString()}');
    }

    return result;
  }

  /// _handleTripInfo() determins what is shon in the bottom drawer
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

  Widget _handleTripInfo() {
    developer.log(
        '_bottomSheetDivider listHeight: $listHeight  - TripActions.${CurrentTripItem().tripActions.name}',
        name: '_handleTripInfo onTap 2411');
    if (listHeight > 0) {
      switch (CurrentTripItem().tripActions) {
        /// Nothing to show TODO: add a help message
        case TripActions.none:
          return _showExploreDetail();

        /// User is not in a position to edit but show everything
        case TripActions.readOnly:
          return _showExploreDetail(readOnly: true);

        /// User has just added a point of interest in a manual create
        case TripActions.pointOfInterest:
          return _showPointOfInterest(
              readOnly: false,
              index: CurrentTripItem().pointsOfInterest.length - 1);

        /// User has tapped the ActionChip to show group members
        case TripActions.showGroup:
          return _showGroup();

        /// User has tapped the ActionChip to show maneuvers
        case TripActions.showSteps:
          return _showManeuvers();

        /// User has just started creating a new drive
        case TripActions.headingDetail:
          return _exploreDetailsHeader();

        ///
        default:
          developer.log('_bottomSheetDivider',
              name: '_handleTripIfo default onTap 2442');
          return SizedBox(height: 0);
      }
    } else {
      CurrentTripItem().tripActions = TripActions.none;
      developer.log(
          '_bottomSheetDivider - TripActions.${CurrentTripItem().tripActions.name}',
          name: '_handleTripIfo default onTap 2447');
      return SizedBox(height: 0);
    }
  }

  void onSelectMember(int index) {}

  /// _handleBottomSheetDivider()
  /// Handles the grab icion to separate the map from the bottom sheet

  _handleBottomSheetDivider() {
    _resizeDelay = 0;
    // debugPrint('_handleBottomSheetDivider() _dividerHeight: $_dividerHeight');
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: AbsorbPointer(
        child: Container(
          color: const Color.fromARGB(255, 158, 158, 158),
          height: _dividerHeight,
          width: MediaQuery.of(context).size.width,
          child: Icon(
            Icons.drag_handle,
            size: _dividerHeight,
            color: Colors.blue,
          ),
        ),
      ),
      onTap: () => setState(() {
        adjustMapHeight(mapHeight > mapHeights[0] - 50
            ? MapHeights.pointOfInterest
            : MapHeights.full);
        developer.log('_bottomSheetDivider',
            name: '_handleBottomSheetDivider onTap 2475');
        _handleTripInfo(); // <- remove keyboard

        //    _showExploreDetail();
      }),
      onVerticalDragUpdate: (DragUpdateDetails details) {
        setState(() {
          if (mapHeights[0] == 0) {
            mapHeights[0] = MediaQuery.of(context).size.height - 190;
          }
          mapHeight += details.delta.dy;
          mapHeight = mapHeight > mapHeights[0] ? mapHeights[0] : mapHeight;
          mapHeight = mapHeight < 1 ? 1 : mapHeight;
          listHeight = mapHeights[0] - mapHeight;
        });
      },
    );
  }

  SizedBox _showGroup() {
    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        itemCount: _following.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: FollowerTile(
            follower: _following[index],
            index: index,
            onIconClick: followerIconClick,
            onLongPress: followerLongPress,
            distance: 0, // ToDo: calculate how far away
          ),
        ),
      ),
    );
  }

  SizedBox _showManeuvers() {
    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        itemCount: CurrentTripItem().maneuvers.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: ManeuverTile(
              index: index,
              maneuver: CurrentTripItem().maneuvers[index],
              maneuvers: CurrentTripItem().maneuvers.length,
              onLongPress: maneuverLongPress,
              distance: 0),
        ),
      ),
    );
  }

  void maneuverLongPress(int index) {
    _showTarget = true;
    _animatedMapController.animateTo(
        dest: CurrentTripItem().maneuvers[index].location);
    return;
  }

  Future<int> getClosestManeuver(List<Maneuver> maneuvers) async {
    double distance = 9999999;
    double testDistance;
    int closest = 0;
    _currentPosition = await Geolocator.getCurrentPosition();
    for (int i = 0; i < maneuvers.length; i++) {
      testDistance = Geolocator.distanceBetween(
          maneuvers[i].location.latitude,
          maneuvers[i].location.longitude,
          _currentPosition.latitude,
          _currentPosition.longitude);
      if (testDistance < distance) {
        distance = testDistance;
        closest = i;
      }
    }
    return closest;
  }

  Future<void> followerIconClick(int index) async {
    String message = await messageGroup(index);
    if (message.isNotEmpty) {}
    return;
  }

  Future<String> messageGroup(int index) async {
    List<String> choices = [
      'All OK',
      'Stopping for fuel',
      'Stopping for food',
      'Mechanical problem',
      'Stopping for a break',
      'Stuck in traffic'
    ];
    String message = choices[0];
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: index > -1
              ? Text(
                  'Message ${_following[index].forename} ${_following[index].surname}')
              : const Text('Broadcast Message'),
          content: SizedBox(
            width: 100,
            height: 150,
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Saved Messages',
                        ),
                        value: choices[0],
                        items: choices
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge!),
                              ),
                            )
                            .toList(),
                        onChanged: (item) => setState(() {}),
                      ),
                    ),
                  ),
                ]),
                if (index > -1) ...[
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone),
                                const SizedBox(width: 8),
                                Text(
                                    'Telephone ${_following[index].phoneNumber}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    height: 70,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      //  child: SingleChildScrollView(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              minLines: 1,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter group message',
                              ),
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.multiline,
                              onChanged: (value) => message = 'message  $value',
                            ),
                          ),
                        ],
                      ),
                      //    ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Send'),
              onPressed: () {
                Navigator.pop(context, message);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
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

  void followerLongPress(int index) {
    _showTarget = true;
    _animatedMapController.animateTo(dest: _following[index].point);
    return;
  }

  SizedBox _showPointOfInterest({readOnly = false, index = 0}) {
    return SizedBox(
      height: listHeight,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: PointOfInterestTile(
              key: ValueKey(_editPointOfInterest),
              index: _editPointOfInterest,
              pointOfInterest:
                  CurrentTripItem().pointsOfInterest[_editPointOfInterest],
              imageRepository: _publishedFeatures.imageRepository,
              onExpandChange: (expanded) => expandChange,
              onIconTap: iconButtonTapped,
              onDelete: removePointOfInterest,
              onRated: onPointOfInterestRatingChanged,
              expanded: true,
              canEdit: !readOnly,
            ),
          )
        ],
      ),
    );
  }

  SizedBox _showExploreDetail({readOnly = false}) {
    return SizedBox(
      height: listHeight,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (_editPointOfInterest < 0) ...[
            // if (CurrentTripItem().pointsOfInterest.isEmpty) ...[
            SliverToBoxAdapter(
              child: _exploreDetailsHeader(),
            ),
            SliverReorderableList(
              itemBuilder: (context, index) {
                if (CurrentTripItem().pointsOfInterest[index].getType() != 16) {
                  // filter out followers
                  return CurrentTripItem().pointsOfInterest[index].getType() ==
                          12
                      ? waypointTile(index)
                      : PointOfInterestTile(
                          key: ValueKey(index),
                          index: index,
                          pointOfInterest:
                              CurrentTripItem().pointsOfInterest[index],
                          imageRepository: _publishedFeatures.imageRepository,
                          onExpandChange: (expanded) => expandChange,
                          onIconTap: iconButtonTapped,
                          onDelete: removePointOfInterest,
                          onRated: onPointOfInterestRatingChanged,
                          canEdit: !readOnly,
                        );
                } else {
                  return SizedBox(
                    key: ValueKey(index),
                    height: 1,
                  );
                }
              },
              itemCount: CurrentTripItem().pointsOfInterest.length,
              onReorder: (int oldIndex, int newIndex) {
                setState(
                  () {
                    if (oldIndex < newIndex) {
                      newIndex = -1;
                    }
                    CurrentTripItem().movePointOfInterest(oldIndex, newIndex);
                  },
                );
              },
            )
          ],
          if (_editPointOfInterest > -1 &&
              _editPointOfInterest <
                  CurrentTripItem().pointsOfInterest.length) ...[
            SliverToBoxAdapter(
              child: PointOfInterestTile(
                key: ValueKey(_editPointOfInterest),
                index: _editPointOfInterest,
                pointOfInterest:
                    CurrentTripItem().pointsOfInterest[_editPointOfInterest],
                imageRepository: _publishedFeatures.imageRepository,
                onExpandChange: (expanded) => expandChange,
                onIconTap: iconButtonTapped,
                onDelete: removePointOfInterest,
                onRated: onPointOfInterestRatingChanged,
                // expanded: true,
                canEdit: !readOnly,
              ),
            )
          ]
        ],
      ),
    );
  }

  void _scrollDown() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2), curve: Curves.fastOutSlowIn);
  }

  Future<void> deleteTrip(int index) async {
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage: _myTripItems[index].heading,
        okValue: index,
        callback: onConfirmDeleteTrip);
  }

  Future<void> onGetTrip(int index) async {
    // CurrentTripItem() = MyTripItem(heading: '');
    CurrentTripItem()
        .fromMyTripItem(myTripItem: await getMyTrip(tripItems[index].uri));
    CurrentTripItem().id = -1;
    CurrentTripItem().driveUri = tripItems[index].uri;
    setState(() {
      CurrentTripItem().tripState = TripState.notFollowing;
      _alignDirectionOnUpdate = AlignOnUpdate.never;
      _alignPositionOnUpdate = AlignOnUpdate.never;
      CurrentTripItem().tripActions = TripActions.none;
      _appState = AppState.driveTrip;
      _showTarget = false;
      _title = CurrentTripItem().heading;
      developer.log(_title, name: '_title onGetTrip() 2825');
      adjustMapHeight(MapHeights.full);
    });

    return;
  }

/*
  onTripRatingChanged(int value, int index) async {
    setState(() {
      debugPrint('Value: $value  Index: $index');
      tripItems[index].score = value.toDouble();
    });
    putDriveRating(tripItems[index].uri, value);
  }
*/
  onPointOfInterestRatingChanged(int value, int index) async {
    putPointOfInterestRating(
        CurrentTripItem().pointsOfInterest[index].url, value.toDouble());
  }

  void onConfirmDeleteTrip(int value) {
    debugPrint('Returned value: ${value.toString()}');
    if (value > -1) {
      int driveId = _myTripItems[value].driveId;
      deleteDriveLocal(driveId: driveId);
      setState(() => _myTripItems.removeAt(value));
    }
  }

  Widget waypointTile(int index) {
    return Material(
      key: Key('$index'),
      child: Stack(
        key: ValueKey('$index'),
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
              child: ListTile(
                  contentPadding: _appState == AppState.driveTrip
                      ? const EdgeInsets.fromLTRB(20, 5, 5, 0)
                      : const EdgeInsets.fromLTRB(5, 5, 5, 30),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  trailing: _appState == AppState.driveTrip
                      ? null
                      : IconButton(
                          iconSize: 25,
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await pointOfInterestRemove(index);
                            setState(() {});
                          },
                        ),
                  tileColor: index.isOdd
                      ? Colors.white
                      : const Color.fromARGB(255, 174, 211, 241),
                  leading: _appState == AppState.driveTrip
                      ? null
                      : ReorderableDragStartListener(
                          key: Key('$index'),
                          index: index,
                          child: const Icon(Icons.drag_handle)),
                  title: Text(getTitles(index)[0]),
                  subtitle: Text(getTitles(index)[1]),
                  onLongPress: () => {
                        _animatedMapController.animateTo(
                            dest:
                                CurrentTripItem().pointsOfInterest[index].point)
                      })),
          if (_appState != AppState.driveTrip) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(
                      elevation: 5,
                      shadowColor: const Color.fromRGBO(95, 94, 94, 0.984),
                      backgroundColor: const Color.fromARGB(214, 245, 6, 6)),
                  onPressed: () {
                    insertAfter = insertAfter == index ? -1 : index;
                    _showTarget = insertAfter == index;
                    setState(() {});
                  },
                  icon: Icon(index == insertAfter ? Icons.close : Icons.add),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _exploreDetailsHeader() {
    bool autofocus = CurrentTripItem().tripActions == TripActions.headingDetail;
    return FocusScope(
      // FocusScope  Sorted problems with TextInputAction.next / done
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
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Give your trip a name...',
                labelText: 'Trip name',
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              initialValue: CurrentTripItem().heading,
              // autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (text) => CurrentTripItem().heading = text,
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
              spellCheckConfiguration: const SpellCheckConfiguration(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a short summary of your trip...',
                labelText: 'Trip summary',
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              initialValue: CurrentTripItem()
                  .subHeading, //widget.port.warning.toString(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (text) => CurrentTripItem().subHeading = text,
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
              spellCheckConfiguration: const SpellCheckConfiguration(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe details of your trip...',
                labelText: 'Trip details',
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              initialValue:
                  CurrentTripItem().body, //widget.port.warning.toString(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => adjustMapHeight(MapHeights.full),
              onChanged: (text) => CurrentTripItem().body = text,
            ),
          ),
        ],
      ),
    );
  }

  Future getImage(ImageSource source, PointOfInterest poi) async {
    // XFile _image;
    final picker = ImagePicker();

    await picker.pickImage(source: source).then((pickedFile) {
      setState(
        () {
          if (pickedFile != null) {
            poi.setImages(
                "${poi.getImages()},{'url': ${pickedFile.path}, 'caption':}");
          }
        },
      );
    });
  }

  /// _trackingState
  /// Sets tracking on if off
  /// Clears down the CurrentTripItem().routes

  _trackingState({required bool trackingOn, description = ''}) async {
    LatLng pos;
    try {
      pos = LatLng(_currentPosition.latitude, _currentPosition.longitude);
    } catch (e) {
      debugPrint('Error getting lat_long @ ${e.toString()}');
      pos = const LatLng(0.0, 0.0);
    }

    if (CurrentTripItem().tripState == TripState.recording) {
      await Geolocator.getCurrentPosition(locationSettings: _locationSettings)
          .then(
        (position) {
          _currentPosition = position;
          pos = LatLng(_currentPosition.latitude, _currentPosition.longitude);
          if (_autoCentre) {
            _animatedMapController.animateTo(dest: pos);
          }
          CurrentTripItem().clearRoutes();
          CurrentTripItem().addRoute(mt.Route(
              id: -1,
              points: [
                LatLng(_currentPosition.latitude, _currentPosition.longitude)
              ], // Route,
              color: _routeColour(_goodRoad.isGood),
              borderColor: _routeColour(_goodRoad.isGood),
              strokeWidth: 5));
          _startLatLng = pos;
          _lastLatLng = pos;
          _travelled = 0.0;
          _start = DateTime.now();
        },
      );
    }

    if (mounted) {
      int elapsed = _start.difference(DateTime.now()).inMinutes.abs();
      _singlePointOfInterest(context, pos, -1,
          time: elapsed,
          distance: _travelled,
          name: description); // -1 = append
    }
    setState(() {});
    _goodRoad.isGood = false;
  }

  /// Uses Geolocator.getPositionStream to get a stream of locations. Triggers posotion update
  /// every 10M
  /// must use _positionStream.cancel() to cancel stream when no longer reading from it

  void getLocationUpdates() {
    _positionStream =
        Geolocator.getPositionStream(locationSettings: _locationSettings)
            .listen(
      (position) {
        _currentPosition = position;
        _speed = _currentPosition.speed * 3.6 / 8 * 5; // M/S -> MPH
        LatLng pos =
            LatLng(_currentPosition.latitude, _currentPosition.longitude);

        if (CurrentTripItem().tripState == TripState.recording) {
          if (_lastLatLng == const LatLng(0.00, 0.00)) {
            _lastLatLng = pos;
            CurrentTripItem().clearRoutes();
            CurrentTripItem().addRoute(mt.Route(
                id: -1,
                points: [pos],
                borderColor: uiColours.keys.toList()[Setup().routeColour],
                color: uiColours.keys.toList()[Setup().routeColour],
                strokeWidth: 5));
          }
          CurrentTripItem()
              .routes[CurrentTripItem().routes.length - 1]
              .points
              .add(pos);

          if (_goodRoad.isGood) {
            CurrentTripItem()
                .goodRoads[CurrentTripItem().goodRoads.length - 1]
                .points
                .add(pos);
          }
          //  debugPrint(
          //      'CurrentTripItem().routes.length: ${CurrentTripItem().routes.length}  points: ${CurrentTripItem().routes[CurrentTripItem().routes.length - 1].points.length}');

          _lastLatLng =
              LatLng(_currentPosition.latitude, _currentPosition.longitude);
        } else if (CurrentTripItem().tripState == TripState.following) {
          setState(() => _directionsIndex = getDirectionsIndex());
        }
        // },
      },
    );
  }

  void addGoodRoad({required LatLng position, name = 'Good road', audio = ''}) {
    CurrentTripItem().addPointOfInterest(
      PointOfInterest(
        driveId: CurrentTripItem().driveId,
        type: 13,
        name: name,
        markerPoint: position,
        sounds: audio,
        marker: MarkerWidget(
          type: 13,
          description: '',
          angle: -_mapRotation * pi / 180,
          list: 0,
          listIndex:
              id == -1 ? CurrentTripItem().pointsOfInterest.length : id + 1,
        ),
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
  }

  int getDirectionsIndex() {
    int idx = -1;
    double distance = 99999;
    double temp;
    if (CurrentTripItem().tripState == TripState.following) {
      for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
        temp = Geolocator.distanceBetween(
            _currentPosition.latitude,
            _currentPosition.longitude,
            CurrentTripItem().maneuvers[i].location.latitude,
            CurrentTripItem().maneuvers[i].location.longitude);
        if (temp < distance) {
          distance = temp;
          idx = i;
        }
      }
    }
    return idx;
  }

  adjustMapHeight(MapHeights newHeight) {
    // debugPrint(
    //     'adjustMapHeight() mapHeights[1]: $mapHeights[1], newHeight: $newHeight');

    if (mapHeights[1] == 0) {
      mapHeights[0] = MediaQuery.of(context).size.height - 190; // info closed
      mapHeights[1] = mapHeights[0] - 400; //275; // heading data
      mapHeights[2] = mapHeights[0] - 450; // open point of interest
      mapHeights[3] = mapHeights[0] - 300; // message
    }
    mapHeight = mapHeights[MapHeights.values.indexOf(newHeight)];
    if (newHeight == MapHeights.full) {
      dismissKeyboard();
    }
    listHeight = (mapHeights[0] - mapHeight);
    // debugPrint('adjustMapHeight() listHeight:$listHeight');
    _resizeDelay = 400;
  }

  locationLatLng(pos) {
    //  debugPrint(pos.toString());
    setState(() {
      //   _showSearch = false;
      _animatedMapController.animateTo(dest: pos);
    });
  }

  Color _routeColour(bool goodRoad) {
    return goodRoad
        ? uiColours.keys.toList()[Setup().goodRouteColour]
        : uiColours.keys.toList()[Setup().routeColour];
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
          //    debugPrint('ExpandChanged: $details');
          _editPointOfInterest = details;
          if (details >= 0) {
            adjustMapHeight(MapHeights.pointOfInterest);
          } else {
            dismissKeyboard();

            adjustMapHeight(MapHeights.full);
          }
        },
      );
    }
  }

  iconButtonTapped(var details) {
    if (_editPointOfInterest > -1) {
      _animatedMapController.animateTo(
          dest: CurrentTripItem().pointsOfInterest[_editPointOfInterest].point);
    }
  }

  removePointOfInterest(var details) {
    if (_editPointOfInterest > -1) {
      CurrentTripItem().removePointOfInterestAt(_editPointOfInterest);
    }
  }

  routeMissed(var details) {
    if (details != null) {
      setState(() {
        debugPrint('Route missed');
      });
    }
  }

  checkMapEvent(var details) {
    if (details != null) {
      if (details.source == MapEventSource.tap) {
        //    debugPrint('Map tapped');
        _floatingTextEditController1.changeOpen(0);
        _floatingTextEditController2.changeOpen(0);
      }
      setState(() {
        debugPrint('Map event: ${details.toString()}');
      });
    }
  }

  /// SaveTrip()
  /// Saves all the trip data to the local SQLLite db
  /// LatLng (LatLng(latitude:51.497157, longitude:-0.619253))
  /// LatLng (LatLng(latitude:51.484398, longitude:-0.62162))
  ///
  Future<int> _saveTrip() async {
    if (CurrentTripItem().heading.isEmpty) {
      Utility().showConfirmDialog(context, "Can't save - more info needed",
          "Please enter what you'd like to call this trip.");
      setState(() {
        _resizeDelay = 300;
        //   mapHeight = 400;
        adjustMapHeight(MapHeights.headers);
        CurrentTripItem().tripActions = TripActions.headingDetail;
        fn1.requestFocus();
      });
      return -1;
    }

    if (CurrentTripItem().subHeading.isEmpty) {
      Utility().showConfirmDialog(context, "Can't save - more info needed",
          'Please give a brief summary of this trip.');
      setState(() {
        adjustMapHeight(MapHeights.headers);
        CurrentTripItem().tripActions = TripActions.headingDetail;
      });
      return -1;
    }

    if (CurrentTripItem().body.isEmpty) {
      Utility().showConfirmDialog(context, "Can't save - more info needed",
          'Please give some interesting details about this trip.');
      setState(() {
        adjustMapHeight(MapHeights.headers);
        CurrentTripItem().tripActions = TripActions.headingDetail;
      });
      return -1;
    }

    if (CurrentTripItem().maneuvers.isEmpty) {
      /// If the trip was generated through tracking there will be
      /// no point by point data so have to generate it from
      /// the API using sample points
      try {
        String points = await waypointsFromPoints(50);
        if (points.isNotEmpty) {
          await getRoutePoints(points);
        }
      } catch (e) {
        debugPrint('error ${e.toString()}');
      }
    }

    try {
      int index = CurrentTripItem().index;
      await CurrentTripItem().saveLocal();
      int driveId = CurrentTripItem().driveId;
      if (driveId > -1) {
        await CurrentTripItem().loadLocal(driveId);
        if (index == -1) {
          CurrentTripItem().index = _myTripItems.length;
          _myTripItems.add(CurrentTripItem());
        } else {
          _myTripItems[index] = CurrentTripItem();
        }
      }
    } catch (e) {
      String err = e.toString();
      debugPrint('Error: $err');
    }
    setState(() {
      CurrentTripItem().tripState = TripState.loaded;
      _title = CurrentTripItem().heading;
      developer.log(_title, name: '_title _saveTrip() 3328');
    });
    return CurrentTripItem().driveId;
  }

  Future<ui.Image> getMapImage() async {
    final mapBoundary =
        mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    return await mapBoundary.toImage();
  }

  Widget _getOverlay2() {
    return ClipPath(
      clipper: InvertedClipper(),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: mapHeight,
        color: Colors.black54,
      ),
    );
  }

  /// _CreateTripState Class End -----------------------------------------
}

/// StickyMenuDeligate provides a ToggleButton menu at the top of the sliverList
/// for the bottom sheet.
/// The setState() is achieved by passing a callback function onButtonPressed that
/// will return the value of the button pressed to the parent widget allowing it to
/// update the state. The parent hands the appropriate menu options and actions
/// through the constructor parameters options1/2 and the state1/2

class StickyMenuDeligate extends SliverPersistentHeaderDelegate {
  final Function onButtonPressed;
  final List<Widget> options;
  final List<bool> states;

  StickyMenuDeligate({
    required this.onButtonPressed,
    required this.options,
    required this.states,
  });

  @override
  double get minExtent => 70.0; // Minimum height of the header

  @override
  double get maxExtent => 100.0; // Maximum height of the header

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color.fromARGB(255, 226, 225, 225),
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToggleButtons(
            isSelected: states,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            selectedBorderColor: Colors.blue[700],
            selectedColor: Colors.white,
            splashColor: Colors.grey,
            fillColor: Colors.blue[400],
            color: Colors.blue[400],
            constraints: const BoxConstraints(minHeight: 40.0, minWidth: 70.0),
            children: options,
            onPressed: (int index) {
              onButtonPressed(index);
            },
          )
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
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

Future<bool> changeTripStart(
    BuildContext context, Position currentPosition, LatLng screenCenter) async {
  final List<bool> values = [false, false, false, false, false];
  bool changed = await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("Change trip's start or end",
            style: TextStyle(fontSize: 26)),
        content: SizedBox(
          height: 300,
          child: Column(
            children: [
              CheckboxListTile(
                title: Text('Swap trip start with trip end',
                    style: TextStyle(fontSize: 18)),
                value: values[0],
                onChanged: (_) => setState(() => (values[0] = !values[0])),
              ),
              CheckboxListTile(
                title: Text('Join trip from your current position',
                    style: TextStyle(fontSize: 18)),
                value: values[1],
                onChanged: (_) => setState(() {
                  values[1] = !values[1];
                  values[2] = values[1] ? false : values[2];
                }),
              ),
              CheckboxListTile(
                title: Text('Join trip from position at screen centre',
                    style: TextStyle(fontSize: 18)),
                value: values[2],
                onChanged: (_) => setState(() {
                  values[2] = !values[2];
                  values[1] = values[2] ? false : values[1];
                }),
              ),
              CheckboxListTile(
                title: Text('Finish trip at your current position',
                    style: TextStyle(fontSize: 18)),
                value: values[3],
                onChanged: (_) => setState(() {
                  values[3] = !values[3];
                  values[4] = values[3] ? false : values[4];
                }),
              ),
              CheckboxListTile(
                title: Text('Finish trip from position at screen centre',
                    style: TextStyle(fontSize: 18)),
                value: values[4],
                onChanged: (_) => setState(() {
                  values[4] = !values[4];
                  values[3] = values[4] ? false : values[3];
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                bool changed = values[0] ||
                    values[1] ||
                    values[2] ||
                    values[3] ||
                    values[4];
                if (CurrentTripItem().routes.isNotEmpty && changed) {
                  List<PointOfInterest> pois;
                  if (values[0]) {
                    pois = CurrentTripItem().pointsOfInterest.reversed.toList();
                  } else {
                    pois = CurrentTripItem().pointsOfInterest;
                  }
                  if (CurrentTripItem().maneuvers.isEmpty) {
                    try {
                      String points = await waypointsFromPoints(50);
                      if (points.isNotEmpty) {
                        await getRoutePoints(points);
                      }
                    } catch (e) {
                      debugPrint('error ${e.toString()}');
                    }
                  }
                  // Reverse trip
                  String points =
                      await waypointsFromManeuvers(reverse: values[0]);
                  // Join trip from current position
                  if (values[1]) {
                    points =
                        '${currentPosition.longitude}, ${currentPosition.latitude}, $points';
                    addWaypointAt(
                        pos: LatLng(currentPosition.latitude,
                            currentPosition.longitude),
                        before: true);
                  }
                  // Join trip from screen centre
                  if (values[2]) {
                    points =
                        '${screenCenter.longitude}, ${screenCenter.latitude}, $points';
                    addWaypointAt(
                        pos: LatLng(
                            screenCenter.latitude, screenCenter.longitude),
                        before: true);
                  }
                  // End trip at current position
                  if (values[3]) {
                    points =
                        '$points, ${currentPosition.longitude}, ${currentPosition.latitude}';
                    addWaypointAt(
                        pos: LatLng(currentPosition.latitude,
                            currentPosition.longitude));
                  }
                  // End trip at screen centre
                  if (values[4]) {
                    points =
                        '$points, ${screenCenter.longitude}, ${screenCenter.latitude}';
                    addWaypointAt(
                        pos: LatLng(
                            screenCenter.latitude, screenCenter.longitude));
                  }
                  getRoutePoints(points);
                  if (CurrentTripItem().pointsOfInterest.isNotEmpty &&
                      values[0]) {
                    CurrentTripItem().pointsOfInterest = pois;
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Ok', style: TextStyle(fontSize: 22))),
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 20))),
        ],
      ),
    ),
  );
  return changed;
}

addWaypointAt({required LatLng pos, bool before = false}) async {
  String name = 'End';
  int idx = CurrentTripItem().pointsOfInterest.length;
  int markerType = 18;
  if (before) {
    name = 'Start';
    idx = 0;
    markerType = 17;
  }
  PointOfInterest waypoint = PointOfInterest(
    id: -1,
    driveId: CurrentTripItem().driveId,
    type: markerType,
    name: name,
    description: '',
    width: 10,
    height: 10,
    markerPoint: pos,
    marker: MarkerWidget(
      type: markerType,
      description: '',
      angle: 1 * pi / 180,
      list: idx,
      listIndex: 0,
    ),
  );
  if (before) {
    CurrentTripItem().pointsOfInterest.insert(0, waypoint);
  } else {
    CurrentTripItem().pointsOfInterest.add(waypoint);
  }
}

Future<String> waypointsFromPoints(int points) async {
  List<LatLng> latLongs = [];
  for (int i = 0; i < CurrentTripItem().routes.length; i++) {
    latLongs = latLongs + CurrentTripItem().routes[i].points;
  }
  int count = latLongs.length;

  if (count / points < 10) {
    points = count ~/ 10;
  }

  int gap = (count - 2) ~/ points;

  String waypoints = '${latLongs[0].longitude},${latLongs[0].latitude}';
  for (int i = 0; i < points - 2; i++) {
    int idx = (gap + 1) * (i + 1);
    waypoints =
        '$waypoints;${latLongs[idx].longitude},${latLongs[idx].latitude}';
  }

  waypoints =
      '$waypoints;${latLongs[count - 1].longitude},${latLongs[count - 1].latitude}';

  return waypoints;
}

Future<String> waypointsFromManeuvers(
    {int points = 50, reverse = false}) async {
  List<LatLng> latLongs = [];
  for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
    latLongs.add(CurrentTripItem().maneuvers[i].location);
  }

  if (reverse) {
    latLongs = latLongs.reversed.toList();
  }

  int count = latLongs.length;

  if (count / points < 10) {
    points = count ~/ 10;
  }

  int gap = (count - 2) ~/ points;

  String waypoints = '${latLongs[0].longitude},${latLongs[0].latitude}';
  for (int i = 0; i < points - 2; i++) {
    int idx = (gap + 1) * (i + 1);
    waypoints =
        '$waypoints;${latLongs[idx].longitude},${latLongs[idx].latitude}';
  }

  waypoints =
      '$waypoints;${latLongs[count - 1].longitude},${latLongs[count - 1].latitude}';

  return waypoints;
}

String waypointsFromPointsOfInterest() {
  String waypoints = '';
  for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
    if (CurrentTripItem().pointsOfInterest[i].getType() == 12) {
      waypoints =
          '$waypoints;${CurrentTripItem().pointsOfInterest[i].point.longitude},${CurrentTripItem().pointsOfInterest[i].point.latitude}';
    }
  }
  return waypoints.isEmpty ? waypoints : waypoints.substring(1);
}

_leadingWidget(context) {
  return context?.openDrawer();
}

Future<Map<String, dynamic>> getRoutePoints(String waypoints) async {
  dynamic jsonResponse;
  List<LatLng> routePoints = [];
  final Map<String, dynamic> result = {
    "name": '',
    "distance": '0.0',
    "duration": 0,
    "summary": '',
    "points": routePoints,
  };
  String avoid = setAvoiding();
  var url = Uri.parse(
      '$urlRouter$waypoints?steps=true&annotations=true&geometries=geojson&overview=full$avoid');
  try {
    var response = await http.get(url).timeout(const Duration(seconds: 5));
    if ([200, 201].contains(response.statusCode)) {
      jsonResponse = jsonDecode(response.body);
      if (jsonResponse == null) {
        return result;
      }
    } else {
      return jsonDecode('"msg": "err"}');
    }
  } catch (e) {
    debugPrint('Http error: ${e.toString()}');
    return result;
  }
  try {
    var router = jsonResponse['routes'][0]['geometry']['coordinates'];
    for (int i = 0; i < router.length; i++) {
      routePoints.add(LatLng(router[i][1], router[i][0]));
    }
  } catch (e) {
    debugPrint('Error getting distancence - ${e.toString()}');
  }
  double distance = 0;
  double duration = 0;
  try {
    distance = jsonResponse['routes'][0]['distance'].toDouble();
    duration = jsonResponse['routes'][0]['duration'].toDouble();
    distance = distance / 1000 * 5 / 8;
  } catch (e) {
    debugPrint('Error: $e');
  }
  String summary =
      '${distance.toStringAsFixed(1)} miles - (${(duration / 60).floor()} minutes)';

  String name =
      '${jsonResponse['routes'][0]['legs'][0]['steps'][0]['name']}, ${jsonResponse['routes'][0]['legs'][0]['steps'][jsonResponse['routes'][0]['legs'][0]['steps'].length - 1]['name']}';
  name =
      '${jsonResponse['routes'][0]['legs'][0]['steps'][jsonResponse['routes'][0]['legs'][0]['steps'].length - 1]['name']}';

  /// ToDo: handling turn by turn:
  /// ...['steps'][n]['name'] => the current road name
  /// ...['steps'][n]['maneuver'][bearing_before'] => approach bearing
  /// ...['steps'][n]['maneuver'][bearing_after] => exit bearing
  /// ...['steps'][n]['maneuver']['location'] => latLng of intersection
  /// ...['steps'][n]['maneuver']['modifier'] => 'right', 'left' etc
  /// ...['steps'][n]['maneuver']['type'] => 'turn' etc
  /// ...['steps'][n]['maneuver']['name'] => 'Alexandra Road'
  ///
  /// jsonResponse['routes'][0]['legs'][0]['steps'].length gives number of steps
  /// Maybe use flutter_tts to provide voice
  /// var parts = str.split(':');
  /// var prefix = parts[0]

  List<String> waypointList = waypoints.split(';');

  if (waypointList.length > 1 && waypointList[0] != waypointList[1]) {
    String lastRoad = name;
    for (int j = 0; j < jsonResponse['routes'][0]['legs'].length; j++) {
      for (int k = 0;
          k < jsonResponse['routes'][0]['legs'][j]['steps'].length;
          k++) {
        try {
          CurrentTripItem().addManeuver(
            Maneuver(
              roadFrom: jsonResponse['routes'][0]['legs'][j]['steps'][k]
                  ['name'],
              roadTo: lastRoad,
              bearingBefore: jsonResponse['routes'][0]['legs'][j]['steps'][k]
                      ['maneuver']['bearing_before'] ??
                  0,
              bearingAfter: jsonResponse['routes'][0]['legs'][j]['steps'][k]
                      ['maneuver']['bearing_after'] ??
                  0,
              exit: jsonResponse['routes'][0]['legs'][j]['steps'][k]['maneuver']
                      ['exit'] ??
                  0,
              location: LatLng(
                  jsonResponse['routes'][0]['legs'][j]['steps'][k]['maneuver']
                      ['location'][1],
                  jsonResponse['routes'][0]['legs'][j]['steps'][k]['maneuver']
                      ['location'][0]),
              modifier: jsonResponse['routes'][0]['legs'][j]['steps'][k]
                      ['maneuver']['modifier'] ??
                  ' ',
              type: jsonResponse['routes'][0]['legs'][j]['steps'][k]['maneuver']
                  ['type'],
              distance: (jsonResponse['routes'][0]['legs'][j]['steps'][k]
                      ['distance'])
                  .toDouble(),
            ),
          );
        } catch (e) {
          String err = e.toString();
          debugPrint(err);
        }
        if (k > 0) {
          CurrentTripItem().maneuvers[k - 1].roadTo =
              CurrentTripItem().maneuvers[k].roadFrom;
        }

        lastRoad = CurrentTripItem()
            .maneuvers[CurrentTripItem().maneuvers.length - 1]
            .roadTo;
        CurrentTripItem()
                .maneuvers[CurrentTripItem().maneuvers.length - 1]
                .type =
            CurrentTripItem()
                .maneuvers[CurrentTripItem().maneuvers.length - 1]
                .type
                .replaceAll('rotary', 'roundabout');
      }
    }
  }

  result["name"] = name;
  result["distance"] = distance.toStringAsFixed(1);
  result["duration"] = jsonResponse['routes'][0]['duration'];
  result["summary"] = summary;
  result["points"] = routePoints;
  return result;
}

String setAvoiding() {
  /// avoid = '&exclude=motorway,trunk,primary';
  /// The avoid categories are defined in OSRM/osrm-backend/car.lua
  String avoiding = '';
  if (Setup().avoidMotorways) {
    avoiding = '&exclude=motorway';
    if (Setup().avoidAroads) {
      avoiding = '&exclude=motorway,trunk,primary';
    }
  } else if (Setup().avoidAroads) {
    avoiding = '&exclude=trunk,primary';
  } else if (Setup().avoidFerries) {
    avoiding = '&exclude=ferry';
  } else if (Setup().avoidTollRoads) {
    avoiding = '&exclude=toll';
  }
  return avoiding;
}
