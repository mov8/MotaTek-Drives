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
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
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
  final GlobalKey mapKey = GlobalKey();
  final GlobalKey _scaffoldKey = GlobalKey();
  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _bottomNavKey = GlobalKey();

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
  // late Future<bool> _groupChecked;
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
  bool _resized = false;
  bool _repainted = false;
  DateTime _start = DateTime.now();
  double _speed = 0.0;
  int insertAfter = -1;
  int _poiDetailIndex = -1;
  int _poiHighlighted = -1;
  var moveDelay = const Duration(seconds: 2);
  double _travelled = 0.0;
  int highlightedIndex = -1;
  final List<Follower> _following = [];
  late LocationSettings _locationSettings;
  final _cacheFence = Fence.create();
  LatLng topRight = const LatLng(0, 0);
  LatLng bottomLeft = const LatLng(0, 0);
  LatLng testPos = LatLng(0, 0);
  bool _updateOverlays = true;
  late final ExpandNotifier _expandNotifier;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _preferencesScrollController = ScrollController();
  final mt.RouteAtCenter _routeAtCenter = mt.RouteAtCenter();
  bool _tripStarted = false;
  String _title = 'Drives';
  late AnimatedMapController _animatedMapController;
  late final StreamController<double?> _allignPositionStreamController;
  late final StreamController<void> _allignDirectionStreamController;
  late final LeadingWidgetController _leadingWidgetController;
  late final FloatingTextEditController _floatingTextEditController1;
  late final FloatingTextEditController _floatingTextEditController2;

  late final StreamController<Position> _debugPositionController;
  late final FollowRoute _debugRoute;
  int initialLeadingWidgetValue = 0;
  late AlignOnUpdate _alignPositionOnUpdate;
  late AlignOnUpdate _alignDirectionOnUpdate;
  final List<Place> _places = [];
  bool _autoCentre = false;
  double _zoom = 13;
  final _dividerHeight = 35.0;
  List<LatLng> routePoints = const [LatLng(51.478815, -0.611477)];

  String images = '';
  //  String stadiaMapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';
  late Style _style;
  PublishedFeatures _publishedFeatures = PublishedFeatures(
      features: [], pinTap: (_) => (), pointOfInterestLookup: {});

  final OsmFeatures _osmFeatures = OsmFeatures();
  // List<PointOfInterest> _pointsOfInterest = [];
  final List<Marker> _debugMarkers = [];
  final bool _debugging = false; // true;
  final Directions _directions = Directions();

  double _width = 56.0;
  final double _height = 56.0;
  bool _expanded = false;
  bool _pubUpdate = true;
  //double _width1 = 56.0;
  //double _height1 = 56.0;
  //bool _expanded1 = false;
  final RouteDelta _distanceFromRoute = RouteDelta();
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
  // NetworkVectorTileProvider(urlTemplate: urlTiler, maximumZoom: 14);

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

    _locationSettings = getGeolocatorSettings(
        defaultTargetPlatform: TargetPlatform.android, distanceFilter: 5);

    if (_debugging) {
      _debugPositionController = StreamController<Position>();
      _debugRoute = FollowRoute(controller: _debugPositionController);

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
    }

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
          developer.log('trip_message: ${data.toString()}', name: '_socket');
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
                    _following[i] = Follower.moveFollower(
                        follower: _following[i],
                        marker: _following[i].marker,
                        position: LatLng(tripMessage.lat, tripMessage.lng));
                    if (tripMessage.type == 's') {
                      _following[i].manufacturer = tripMessage.manufacturer;
                      _following[i].model = tripMessage.model;
                      _following[i].carColour = tripMessage.carColour;
                      _following[i].registration = tripMessage.registration;
                      _following[i].phoneNumber = tripMessage.phoneNumber;
                      _following[i].position =
                          LatLng(tripMessage.lat, tripMessage.lng);
                      _following[i].accepted = tripMessage.accepted;
                    }
                    if (_following[i].track) {
                      if (_following[i].routeIndex == -1) {
                        _following[i].routeIndex =
                            CurrentTripItem().routes.length;
                        CurrentTripItem().routes.add(
                              mt.Route(
                                color: colourList[_following[i].iconColour],
                                borderColor:
                                    colourList[_following[i].iconColour],
                                strokeWidth: 5,
                                points: [
                                  LatLng(tripMessage.lat, tripMessage.lng)
                                ],
                              ),
                            );
                      } else {
                        CurrentTripItem()
                            .routes[_following[i].routeIndex]
                            .points
                            .add(LatLng(tripMessage.lat, tripMessage.lng));
                      }
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

                _tripMessages.add(tripMessage);
                showMessages(message: tripMessage);
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
    _animatedMapController.dispose();
    fn1.dispose();

    // Clean up the focus node when the Form is disposed.
    if (CurrentTripItem().groupDriveId.isNotEmpty && socket.connected) {
      socket.emit('trip_leave', {'trip': CurrentTripItem().groupDriveId});
      try {
        socket.emit('cleave');
      } catch (e) {
        debugPrint('error disposing of group_messages: ${e.toString()}');
      }
    }
    if (socket.connected) {
      socket.close;
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
    developer.log('_updateMarkerSize zoom: $zoom', name: '_overlays');
    setState(() {});
  }

  Future<Map<String, dynamic>> addRoute(LatLng latLng1, LatLng latLng2) async {
    return await getRoutePoints(points: [latLng1, latLng2], addPoints: true);
  }

  Future reRoute({bool editing = true}) async {
    List<LatLng> waypoints = [];

    for (int i = 0; i < CurrentTripItem().pointsOfInterest.length; i++) {
      PointOfInterest poi = CurrentTripItem().pointsOfInterest[i];
      if ([12, 17, 18, 19].contains(poi.getType())) {
        waypoints.add(poi.point);
      }
    }

    if (waypoints.isNotEmpty) {
      Map<String, dynamic> routeData = {};
      if (editing) {
        CurrentTripItem().clearRoutes();
        CurrentTripItem().clearManeuvers();

        routeData = await getRoutePoints(points: waypoints, addPoints: true);
        CurrentTripItem().maneuvers = routeData['maneuvers'];
      } else {
        routeData = await getRoutePoints(points: [
          waypoints[waypoints.length - 2],
          waypoints[waypoints.length - 1]
        ], addPoints: true);
        CurrentTripItem().maneuvers.addAll(routeData['maneuvers']);
      }

      CurrentTripItem().addRoute(
        mt.Route(
            id: -1,
            points: routeData['points'], // Route,
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
      {required LatLng position, bool first = true}) async {
    LatLng latLng1;
    Map<String, dynamic> apiData = {};
    if (first) {
      apiData = await addRoute(position, position);
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
    apiData = await addRoute(latLng1, position);
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
/*
  Future<List<LatLng>> _get_Routes(String waypoints) async {
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
    try {
      var router = jsonResponse['routes'][0]['geometry']['coordinates'];

      for (int i = 0; i < router.length; i++) {
        routePoints.add(LatLng(router[i][1], router[i][0]));
      }
    } catch (e) {
      debugPrint('Error getRoutes(): ${e.toString()}');
    }
    return routePoints;
  }
*/
  ///
  /// Returns the routepoints and the waypoint data for the added waypoint
  /// _SimpleUri (http://10.101.1.150:5000/route/v1/driving/-0.0237985,52.9776561;-0.0237985,52.9776561?steps=true&annotations=true&geometries=geojson&overview=full&exclude=motorway&exclude=trunk&exclude=primary)

  List<Maneuver> getManeuvers() {
    List<Maneuver> maneuvers = [];
    return maneuvers;
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Widget build', name: '_initialise');
    int initialNavBarValue = 2;
    initialLeadingWidgetValue =
        [AppState.createTrip, AppState.driveTrip].contains(_appState) ? 1 : 0;
    if (ModalRoute.of(context)!.settings.arguments != null &&
        listHeight == -1) {
      final args = ModalRoute.of(context)!.settings.arguments as TripArguments;
      CurrentTripItem().fromMyTripItem(myTripItem: args.trip);
      CurrentTripItem().groupDriveId = args.groupDriveId;
      _title = CurrentTripItem().heading;
      // _groupChecked = true;
      developer.log(_title, name: '_title at build 627');
      CurrentTripItem().tripState = TripState.notFollowing;
      CurrentTripItem().tripActions = TripActions.none;
      CurrentTripItem().highliteActions = HighliteActions.none;
      if (CurrentTripItem().pointsOfInterest.isNotEmpty) {
        checkWaypoints(pointsOfInterest: CurrentTripItem().pointsOfInterest);
        renumberWaypoints(pointsOfInterest: CurrentTripItem().pointsOfInterest);
      }
      _directions.maneuvers = CurrentTripItem().maneuvers;

      _tripStarted = false;
      if (args.groupDriveId.isNotEmpty) {
        CurrentTripItem().tripType = TripType.group;
      } else {
        CurrentTripItem().tripType = TripType.saved;
      }

      if (_debugging) {
        for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
          _debugMarkers.add(Marker(
              point: CurrentTripItem().maneuvers[i].location,
              child: Icon(Icons.bug_report, color: Colors.pink, size: 15)));
        }
      }

      initialLeadingWidgetValue = 0;
      initialNavBarValue = 2;
    }
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      resizeToAvoidBottomInset: false, // Stops keyboard moving FABS
      appBar: AppBar(
        key: _appBarKey,
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
                flex: 1,
                child: tripTypeIcons[CurrentTripItem().tripType.index]),
            SizedBox(width: 3),
            Expanded(
              flex: 12,
              child: Text(
                _title,
                style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: RoutesBottomNav(
          key: _bottomNavKey,
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
    developer.log('loading data', name: '_initialise');
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
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
    developer.log('data loaded', name: '_initialise');
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
                  title: Text(
                    infoMap['title'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
            onEnd: () => _resized = true,
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

  /// addWaypoint rules are:
  /// First waypoint = type 17
  /// Last waypoint = type 18
  /// Any other waypoint = type 12
  /// So in pseudocode:
  /// a) insertAfter == -1  a straight forward addition
  ///     if CurrentTripItem().pointsOfInterest.length == 0 add waypoint type = 17
  ///     if CurrentTripItem().pointsOfInterest.length == 1 add waypoint type = 18
  ///     if a waypoint is added and CurrentTripItem().pointsOfInterest.length > 1 then:
  ///       if CurrentTripItem().pointsOfInterest.length[CurrentTripItem().pointsOfInterest.length-1] == 18
  ///         CurrentTripItem().pointsOfInterest.length[CurrentTripItem().pointsOfInterest.length-1] -> 12
  ///     add new waypoint type 18
  /// b) insertAfter > -1 a waypoint is inserted into CurrentTripItem().pointsOfInterest list
  ///     waypoint type 12 is inserted at inserAfter position
  ///

  Future<String> newWaypoint({bool currentPosition = false, index = -1}) async {
    LatLng pos;
    if (currentPosition) {
      pos = LatLng(_currentPosition.latitude, _currentPosition.longitude);
    } else {
      pos = _animatedMapController.mapController.camera.center;
    }
    return '${pos.latitude},${pos.longitude}';
  }

  ///
  /// addWaypoint adds a waypoint to a map there are 5 scenarios:
  /// 1 It's the first waypoint - just adds to the pointsOfInterest[]
  /// 2 It's the second wapoint - adds to the pointsOfInterest[] and calculates the route
  /// 3 It's a waypoint that extends the route adds to pointsOfInterest[] and recalculates the route
  /// 4 It's a waypoint along the route - an anchor waypoint inserts the waypoint into pointsOfInterest[]
  ///   This is a tricky bit. It has to find where in the list to be inserted. It should look up and down
  ///   the pointsOfInterest[] looking for the adjacent waypoints. It can then be inserted in the correct position to allow
  ///   the route to be regenerated without any double-backs etc. There is no recalculation of the route.
  /// 5 It's a wawpoint between the end and start that modifies the route recalculates the route using all waypoints.
  ///   Again the correct position will have to be calculated before the waypoint is inserted between the adjacent waypoints.
  ///   To find the leave-route-point find the two closest existing waypoint to the new waypoint and insert the new waypoint
  ///   between the two. Then recalculate the route.
  ///
  /// In this model waypoints are the only route defining points. PointsOfInterest do not determine the route taken, as
  /// they could well be slightly off the route, accesible by foot only etc.
  ///
  /// Provision will have to be made to allow the user to modify a route by inserting a new waypoint, then removing a
  /// waypoint.
  ///
  /// NB:  Waypoint types - Start: 17  End: 18  Other: 12

  addWaypoint(
      {required List<PointOfInterest> pointsOfInterest,
      bool currentPosition = false,
      bool isAnchor = false,
      bool isRevisit = false,
      bool isLast = false}) async {
    LatLng pos;
    if (currentPosition) {
      pos = LatLng(_currentPosition.latitude, _currentPosition.longitude);
    } else {
      pos = _animatedMapController.mapController.camera.center;
    }

    int index = insertAt(pointsOfInterest: pointsOfInterest, position: pos);
    int wpType = 12;

    if (index == 0) {
      wpType = 17;
    } else if (isRevisit || isLast) {
      wpType = 19;
    } else if (index == pointsOfInterest.length) {
      wpType = 18;
    }

    PointOfInterest waypoint = PointOfInterest(
      driveId: CurrentTripItem().driveId,
      type: wpType,
      markerPoint: pos,
      description: 'insertAt: $index isAnchor: $isAnchor',
      marker: MarkerWidget(
        type: wpType,
        angle: -_mapRotation * pi / 180, // degrees to radians
        list: index,
        listIndex: index,
      ),
    );
    int waypoints = index;
    pointsOfInterest.insert(index, waypoint);
    if (CurrentTripItem().tripState == TripState.editing) {
      waypoints = renumberWaypoints(pointsOfInterest: pointsOfInterest);
    }
    if (waypoints > 0 && !isAnchor) {
      debugPrint('reRouting');
      await reRoute(editing: CurrentTripItem().tripState == TripState.editing);
    }
    setState(() => _showMask = false);
  }

  /// insertAt()
  /// Calculates where to insert the new waypoint in pointsOfInterest[]
  /// Test cases:
  /// 1 Very first waypoint - should return 0 - type 17
  /// 2 Second waypoint - should return list.length (1) - type 18
  /// 3 New waypoint between two waypoints - should just work  a------c-------b
  /// 4 New waypoint before the first waypoint  c  a------------b  (c - b) > (a - b)
  /// 5 New waypoint after last waypoint  a------------b  c  (c - a) > (a - b)
  /// Flutter's List.insert(index, value) index >=0 && <= length

  int insertAt(
      {required List<PointOfInterest> pointsOfInterest,
      required LatLng position,
      editing = false}) {
    int index = 0;
    int points = 0;
    int startIndex = -1;
    int endIndex = -1;
    LatLng firstPoint = LatLng(0, 0);
    LatLng lastPoint = LatLng(0, 0);
    LatLng testPoint = LatLng(0, 0);

    for (int i = 0; i < pointsOfInterest.length; i++) {
      int poiType = pointsOfInterest[i].getType();
      if ([12, 17, 18, 19].contains(poiType)) {
        points++;
        testPoint = pointsOfInterest[i].point;
        if (poiType == 17) {
          startIndex = i;
          firstPoint = testPoint;
        } else if (poiType == 18) {
          endIndex = i;
          lastPoint = testPoint;
        }
      }
    }
    if (!editing) {
      return points;
    }

    /// Two special cases:
    ///   1 new waypoint before first waypoint
    ///   2 new waypoint after last waypoint
    ///
    if (points > 1) {
      double tripLength = pointDistance(point1: firstPoint, point2: lastPoint);
      double fromStart = pointDistance(point1: firstPoint, point2: position);
      double toEnd = pointDistance(point1: lastPoint, point2: position);

      /// 4 New waypoint before the first waypoint  c  a------------b  (c - b) > (a - b)
      if (toEnd > tripLength && toEnd > fromStart) {
        pointsOfInterest[startIndex].setType(12);
        return 0;
      }

      /// 5 New waypoint after last waypoint  a------------b  c  (c - a) > (a - b)
      if (fromStart > tripLength && fromStart > toEnd) {
        pointsOfInterest[endIndex].setType(12);
        return pointsOfInterest.length;
      }

      if (points == 2) return 1;

      /// Point must be inside the route and there are more than just the start
      /// and end points.
      /// If the position of the point to insert is closer to the start than
      /// the testPoint then insert before the testPoint
      ///   0               1        2
      ///   s-----------p--tp--------e
      for (int i = 0; i < pointsOfInterest.length; i++) {
        int wpType = pointsOfInterest[i].getType();
        if (wpType == 18) return i;
        if (wpType == 12) {
          double testPointFromStart = pointDistance(
              point1: firstPoint, point2: pointsOfInterest[i].point);
          if (testPointFromStart > fromStart) return i;
        }
      }
    }

    return index;
  }

  double pointDistance({required LatLng point1, required LatLng point2}) {
    return Geolocator.distanceBetween(
        point1.latitude, point1.longitude, point2.latitude, point2.longitude);
  }

  int renumberWaypoints({required List<PointOfInterest> pointsOfInterest}) {
    List<int> wpIndexes = waypointIndexes(pointsOfInterest: pointsOfInterest);
    if (wpIndexes.isNotEmpty) {
      try {
        for (int i = 0; i < wpIndexes.length; i++) {
          try {
            int wpType = pointsOfInterest[wpIndexes[i]].getType();
            LatLng pos = pointsOfInterest[wpIndexes[i]].point;
            pointsOfInterest[wpIndexes[i]] = PointOfInterest(
              driveId: CurrentTripItem().driveId,
              type: wpType,
              markerPoint: pos,
              marker: MarkerWidget(
                type: wpType,
                angle: -_mapRotation * pi / 180, // degrees to radians
                list: 2,
                listIndex: i,
              ),
            );
          } catch (e) {
            debugPrint('Error: ${e.toString()}');
          }
        }
      } catch (e) {
        debugPrint('Error: ${e.toString}');
      }
    }
    return wpIndexes.length;
  }

  /// waypointIndexes() returns a list of indexes of waypoints in the pointsOfInterest List
  /// Assumptions:
  ///   Type 17 = trip start
  ///   Type 18 = trip end
  ///   Type 12 = other waypoint
  ///   The next waypoint is the closest waypoint to the current one as the crow flies
  ///   Once a waypoint is identified as the closest it is excluded from further comparisons

  List<int> waypointIndexes({required List<PointOfInterest> pointsOfInterest}) {
    List<int> indexes = [];
    int start = -1;
    int end = -1;
    for (int i = 0; i < pointsOfInterest.length; i++) {
      PointOfInterest poi = pointsOfInterest[i];
      int poiType = poi.getType();
      if ([12, 17, 18, 19].contains(poiType)) {
        indexes.add(i);
        start = poiType == 17 ? i : start;
        end = poiType == 18 ? i : end;
      }
    }
    if (end == -1) {
      if (start == -1) {
        return [];
      }
      return [0];
    }

    List<int> result = [start];

    if (start > -1) {
      List<int> tested = [];

      int closest = -1;
      for (int i = 0; i < indexes.length; i++) {
        if (!tested.contains(i)) {
          LatLng testPos = pointsOfInterest[indexes[i]].point;
          tested.add(i);
          double distance = 9999999999;
          for (int j = 0; j < indexes.length; j++) {
            if (!tested.contains(j)) {
              double testDistance = pointDistance(
                  point1: testPos, point2: pointsOfInterest[indexes[j]].point);
              if (testDistance < distance) {
                distance = testDistance;
                closest = j;
              }
            }
          }
          if (!result.contains(closest)) {
            result.add(closest);
          }
        }
      }
      if (!result.contains(end)) {
        result.add(end);
      }
    }
    developer.log('waypointIndex() result:${result.toString()}',
        name: '_waypoint');
    return result;
  }

  void checkWaypoints({required List<PointOfInterest> pointsOfInterest}) {
    LatLng start = LatLng(0, 0);
    LatLng end = LatLng(0, 0);
    int wayPoints = 0;
    for (int i = 0; i < pointsOfInterest.length; i++) {
      if (pointsOfInterest[i].getType() == 17) {
        start = pointsOfInterest[i].point;
      }
      if (pointsOfInterest[i].getType() == 18) {
        end = pointsOfInterest[i].point;
      }
      if ([12, 17, 18, 19].contains(pointsOfInterest[i].getType())) {
        ++wayPoints;
      }
    }
    if (start == LatLng(0, 0)) {
      pointsOfInterest.insert(
        0,
        PointOfInterest(
          id: id,
          driveId: CurrentTripItem().driveId,
          type: 17,
          markerPoint: CurrentTripItem().routes[0].points[0],
          marker: MarkerWidget(
            type: 17,
            angle: -_mapRotation * pi / 180, // degrees to radians
            list: 0,
            listIndex: 0,
          ),
        ),
      );
    }
    if (end == LatLng(0, 0)) {
      pointsOfInterest.add(
        PointOfInterest(
          id: id,
          driveId: CurrentTripItem().driveId,
          type: 18,
          markerPoint: CurrentTripItem()
              .routes[0]
              .points[CurrentTripItem().routes.length],
          marker: MarkerWidget(
            type: 18,
            angle: -_mapRotation * pi / 180, // degrees to radians
            list: 0,
            listIndex: wayPoints - 1,
          ),
        ),
      );
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
    reRoute();
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
            height: 220,
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
                              _animatedMapController
                                  .animateTo(
                                      dest: LatLng(chosen.lat, chosen.lng))
                                  .then((_) => updateOverlays());
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
                Fence newFence = Fence.fromBounds(
                    _animatedMapController.mapController.camera.visibleBounds);
                mapController.mapEventStream.listen((event) {});
                _cacheFence.setBounds(bounds: newFence, deltaDegrees: 0.5);
                await _osmFeatures.update(fence: _cacheFence, size: 20);
                setState(() => ());
                _osmIncludingChange = false;
              }
            },
          ),
          const SizedBox(
            height: 10,
          ),

          if (_debugging) ...[
            FloatingActionButton(
              heroTag: 'goodRoad',
              onPressed: () async {
                CurrentTripItem().maneuvers.clear();
                if (CurrentTripItem().maneuvers.isEmpty) {
                  /// If the trip was generated through tracking there will be
                  /// no point by point data so have to generate it from
                  /// the API using sample points
                  try {
                    //  String points = await waypointsFromPoints(50);
                    if (CurrentTripItem().routes[0].points.isNotEmpty) {
                      // await getRoutePoints(waypoints: points);
                    }
                    List<LatLng> points = [];
                    for (int i = 0; i < CurrentTripItem().routes.length; i++) {
                      points.addAll(CurrentTripItem().routes[i].points);
                    }

                    Map<String, dynamic> routeData =
                        await getRoutePoints(points: points, addPoints: false);

                    CurrentTripItem().maneuvers = routeData['maneuvers'];
                    debugPrint('maneuvers done');
                  } catch (e) {
                    debugPrint('error ${e.toString()}');
                  }
                }

/*
                dynamic response = await getRoutePoints(points: [
                  CurrentTripItem().routes[0].points.first,
                  CurrentTripItem().routes[0].points.last
                ]);
                Map<String, dynamic> routeData =
                    processRouterData(jsonResponse: response, waypoints: '');
                setState(
                    () => CurrentTripItem().maneuvers = routeData['maneuvers']);

                    */
              },
              backgroundColor: _goodRoad.isGood
                  ? uiColours.keys.toList()[Setup().goodRouteColour]
                  : Colors.blue,
              shape: const CircleBorder(),
              child: Icon(
                Icons.bug_report_outlined,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
          ],
          //Zoomer(height: 50, width: 50, onZoomChanged: (_) => (), zoom: 12),
          // if (/*[AppState.createTrip, AppState.driveTrip].contains(_appState) && */
          //     !_showSearch && !_showPreferences) ...[
          if (CurrentTripItem().groupDriveId.isNotEmpty) ...[
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
            SizedBox(height: 10),
            FloatingActionButton(
              onPressed: () {
                if (socket.connected) {
                  if (testPos == LatLng(0, 0)) {
                    testPos = LatLng(
                        _animatedMapController
                            .mapController.camera.center.latitude,
                        _animatedMapController
                            .mapController.camera.center.longitude);
                  } else {
                    double lat = testPos.latitude + 0.001;
                    double lng = testPos.longitude + 0.001;
                    testPos = LatLng(lat, lng);
                  }
                  socket.emit('trip_message', {
                    'message': '',
                    'lat': testPos.latitude,
                    'lng': testPos.longitude,
                  });
                }
              },
              heroTag: 'test1',
              backgroundColor: Colors.blue,
              shape: const CircleBorder(),
              child: Icon(Icons.add_alarm,
                  color: _autoCentre ? Colors.white : Colors.grey),
            ),
            const SizedBox(height: 10),
          ],
          if ([TripState.recording, TripState.following]
              .contains(CurrentTripItem().tripState)) ...[
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
              if (CurrentTripItem().isTracking) {
                if (_alignPositionOnUpdate == AlignOnUpdate.always) {
                  _alignPositionOnUpdate = AlignOnUpdate.never;
                  setState(() => _autoCentre = false);
                } else {
                  _alignPositionOnUpdate = AlignOnUpdate.always;
                  _currentPosition = await Geolocator.getCurrentPosition();
                  //     debugPrint('Position: ${_currentPosition.toString()}');
                  _animatedMapController
                      .animateTo(
                          dest: LatLng(_currentPosition.latitude,
                              _currentPosition.longitude))
                      .then((_) => updateOverlays(
                          zoom: _animatedMapController
                              .mapController.camera.zoom));
                  setState(() => _autoCentre = true);
                }
              } else {
                _animatedMapController.animateTo(
                    dest: LatLng(
                        _currentPosition.latitude, _currentPosition.longitude));
              }
            },
            heroTag: 'mapCentre',
            backgroundColor: Colors.blue,
            shape: const CircleBorder(),
            child: Icon(Icons.my_location,
                color: CurrentTripItem().isTracking
                    ? _autoCentre
                        ? Colors.white
                        : Colors.grey
                    : Colors.white),
          ),
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
                developer.log('onMapReady', name: '_connect');
                updateOverlays(zoom: 13);
                if (!_tripStarted) {
                  if (_debugging) {
                    _currentPosition = await _getDebugPosition();
                  } else {
                    _currentPosition = await Geolocator.getCurrentPosition();
                  }
                  _animatedMapController.animateTo(
                      dest: LatLng(_currentPosition.latitude,
                          _currentPosition.longitude));
                  _tripStarted = true;
                  if (CurrentTripItem().groupDriveId.isNotEmpty) {
                    if (_following.isEmpty) {
                      await loadGroup(
                          groupDriveId: CurrentTripItem().groupDriveId);
                    }
                    _title = CurrentTripItem().heading;
                    if (!socket.connected) {
                      socket.connect();
                      developer.log('socket.connect() called',
                          name: '_connect');
                    }
                  }
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
                      CurrentTripItem().routes[i].color =
                          uiColours.keys.toList()[Setup().selectedColour];
                    } else {
                      CurrentTripItem().routes[i].color =
                          uiColours.keys.toList()[Setup().routeColour];
                    }
                  }
                  LatLng mapPos =
                      _animatedMapController.mapController.camera.center;
                  for (int i = 0;
                      i < CurrentTripItem().pointsOfInterest.length;
                      i++) {
                    LatLng wpPos = CurrentTripItem().pointsOfInterest[i].point;
                    double distance = Geolocator.distanceBetween(
                        mapPos.latitude,
                        mapPos.longitude,
                        wpPos.latitude,
                        wpPos.longitude);
                    if (distance < 200) {
                      CurrentTripItem().highliteActions =
                          HighliteActions.waypointHighlited;
                      _poiHighlighted = i;
                      developer.log(
                          'Distance $distance markerType: ${CurrentTripItem().pointsOfInterest[i].getType()}',
                          name: '_waypoint');
                    }
                  }
                  highlightedIndex = routeIdx;
                }

                if (hasGesure) {
                  _updateMarkerSize(position.zoom);
                }

                if (_updateOverlays) {
                  updateOverlays(zoom: position.zoom);
                }

                _mapRotation =
                    _animatedMapController.mapController.camera.rotation;
              },
              initialCenter: routePoints[0],
              initialZoom: _zoom, // 15,
              maxZoom: 13.99999,
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
                  maximumZoom: 13,
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
              MarkerLayer(markers: _debugMarkers),
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

  Future<Position> _getDebugPosition() async {
    return _debugRoute.getPosition ?? Geolocator.getCurrentPosition();
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

  RouteDelta distanceFromRoute(
      {required List<mt.Route> routes,
      required LatLng position,
      RouteDelta? routeDelta}) {
    int distance = 200000;
    int longers = 0;
    routeDelta ??= RouteDelta();
    routeDelta.point = position;
    routeDelta.distance = distance;
    for (int i = 0; i < routes.length; i++) {
      mt.Route route = routes[i];
      for (int j = 0; j < route.points.length; j++) {
        distance = Geolocator.distanceBetween(
                routeDelta.point.latitude,
                routeDelta.point.longitude,
                route.points[j].latitude,
                route.points[j].longitude)
            .toInt();
        if (distance < routeDelta.distance) {
          routeDelta.distance = distance;
          routeDelta.pointIndex = j;
          routeDelta.routeIndex = i;
          routeDelta.point = route.points[j];
          longers = 0;
        } else {
          ++longers;
        }
        if (longers > 20) {
          break;
        }
      }
    }
    return routeDelta;
  }

/* TileProviders(
                    {'openmaptiles': _tileProvider()},
                  ), //
 */

  Align getDirections(int index) {
    // if (index >= 0 &&
    if (CurrentTripItem().tripState == TripState.following &&
        CurrentTripItem().maneuvers.isNotEmpty) {
      //  CurrentTripItem().maneuvers[index].distance = Geolocator.distanceBetween(
      //      _currentPosition.latitude,
      //      _currentPosition.longitude,
      //      CurrentTripItem().maneuvers[index].location.latitude,
      //      CurrentTripItem().maneuvers[index].location.longitude);
      _directions.maneuvers = CurrentTripItem().maneuvers;
      _directions.update(
          position:
              LatLng(_currentPosition.latitude, _currentPosition.longitude));

      index = _directions.currentIndex;
      return Align(
        alignment: Alignment.topLeft,
        child: DirectionTile(
          direction: CurrentTripItem().maneuvers[index],
          index: index,
          directions: CurrentTripItem().maneuvers.length,
          metersToManeuver: _directions.distance,
          distance: _distanceFromRoute.distance,
          routeDelta: _distanceFromRoute,
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

  void updateOverlays({double zoom = 12}) async {
    Fence newFence = Fence.fromBounds(
        _animatedMapController.mapController.camera.visibleBounds);

    // developer.log(
    //     'newFence: ${newFence.toString()}, _cacheFence: ${_cacheFence.toString()}',
    //     name: '_overlays');

    zoom = _animatedMapController.mapController.camera.zoom;
    // developer.log('_ipdateOverlays = true ', name: '_overlays');

    /// Updating the overlays depends on two factors:
    /// 1 The cached data needs refreshing
    /// 2 The zoom level has changed - so the markers have to change

    if (!_cacheFence.contains(bounds: newFence) || zoom != _zoom) {
      _zoom = zoom;
      developer.log('_ipdateOverlays = true and newFence outside _cachedFence',
          name: '_overlays');
      if (zoom > 10) {
        _updateOverlays = false;
        _cacheFence.setBounds(bounds: newFence, deltaDegrees: 0.5);
        double markerSize = 20 + ((zoom - 10) * 4);
        developer.log('_ipdateOverlays markerSize: $markerSize',
            name: '_overlays');
        if (!_cacheFence.contains(bounds: newFence)) {
          bool osmUpdate = await _osmFeatures.update(
              fence: _cacheFence, size: markerSize); // 20 - 30 for zoom 10 - 14
          if (_pubUpdate) {
            _pubUpdate = false;
            bool pubUpdate =
                await _publishedFeatures.update(screenFence: _cacheFence);
            _pubUpdate = true;
            if (osmUpdate || pubUpdate) {
              setState(() => _updateOverlays = true);
            }
          }
        } else {
          _osmFeatures.resizeOsmAmenities(size: markerSize);
          _updateOverlays = true;
        }
      } else {
        _osmFeatures.clear();
      }
    }
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
    developer.log(
        'getChips() 2107 CurrentTripItem().tripState: ${CurrentTripItem().tripState.name}',
        name: '_tripState');
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
      'Anchor waypoint', //'Split route',
      'Remove waypoint', //'Remove section',
      'Revisit waypoint',
      'Last waypoint',
      'Great road end',
      'Follow route',
      'Stop following',
      'Steps',
      'Group',
      'Edit route',
      'Start or end',
      'Trip info',
      'Back',
      'Messages', //'Write message',
      'Read messages',
      'Reply',
      'Send',
      // 'Remove waypoint'
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
      anchorWaypoint, // splitRoute,
      removeWaypoint, //removeSection,
      revisitWaypoint,
      lastWaypoint,
      greatRoadEnd,
      followRoute,
      stopFollowing,
      steps,
      group,
      editRoute,
      changeStartOrEnd,
      tripData,
      back,
      messages,
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
      Icons.delete,
      Icons.anchor, //Icons.cut,
      Icons.wrong_location, //Icons.add_photo_alternate,
      Icons.replay,
      Icons.sports_score,
      Icons.remove_road,
      Icons.directions,
      Icons.directions_off,
      Icons.alt_route,
      Icons.directions_car,
      Icons.edit,
      Icons.start,
      Icons.map,
      Icons.arrow_back,
      Icons.chat,
    ];

    if (CurrentTripItem().tripActions == TripActions.saving) {
      CurrentTripItem().tripActions = TripActions.saved;
      CurrentTripItem().tripState = TripState.loaded;
      return chips;
    }
    _repainted = true;
    if (CurrentTripItem().highliteActions ==
        HighliteActions.waypointHighlited) {
      chipNames.clear();
      chipNames.add('Remove waypoint');
      if (CurrentTripItem().pointsOfInterest.length != _poiHighlighted + 1) {
        chipNames.add('Revisit waypoint');
      }
      if (_poiHighlighted == 0) {
        chipNames.add('Last waypoint');
      }
    } else {
      if (CurrentTripItem().tripState == TripState.none) {
        chipNames.clear();
        _showTarget = false;
        chipNames
          ..add('Create manually')
          ..add('Track drive');
      }
      if ([TripState.manual, TripState.editing]
          .contains(CurrentTripItem().tripState)) {
        chipNames
          ..add(CurrentTripItem().highliteActions ==
                  HighliteActions.routeHighlited
              ? 'Anchor waypoint'
              : 'Waypoint')
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
          CurrentTripItem().groupDriveId.isEmpty &&
          [TripState.manual, TripState.stoppedRecording, TripState.editing]
              .contains(CurrentTripItem().tripState)) {
        if (!CurrentTripItem().isSaved) {
          chipNames.add('Save trip');
        }
        chipNames.add('Clear trip');
      }
      if (CurrentTripItem().highliteActions == HighliteActions.routeHighlited) {
        //    chipNames
        //      ..add('Anchor waypoint') //'Split route')
        //      ..add('Remove section');
        if (CurrentTripItem().highliteActions ==
            HighliteActions.greatRoadStarted) {
          chipNames.add('Great road end');
        } else {
          chipNames.add('Great road');
        }
      }

      if ([TripState.stoppedFollowing, TripState.notFollowing, TripState.loaded]
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
        TripState.notFollowing,
        TripState.loaded
      ].contains(CurrentTripItem().tripState)) {
        if (CurrentTripItem().groupDriveId.isNotEmpty) {
          if (CurrentTripItem().tripActions == TripActions.showGroup) {
            chipNames.add('Trip info');
          } else {
            chipNames.add('Group');
          }
          if (CurrentTripItem().tripActions == TripActions.showMessages) {
            chipNames.add('Trip info');
          } else {
            chipNames.add('Messages');
          }
        }
        if (CurrentTripItem().tripActions == TripActions.showSteps) {
          chipNames.add('Trip info');
        } else {
          chipNames.add('Steps');
        }

        if (CurrentTripItem().tripState != TripState.following &&
            CurrentTripItem().groupDriveId.isEmpty) {
          chipNames.add('Edit route');
        }
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

  /// Have split out the state change from the action part
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
        _lastLatLng = const LatLng(0.00, 0.00);
        _startLatLng = const LatLng(0.00, 0.00);
        adjustMapHeight(MapHeights.full);
        CurrentTripItem().clearRoutes();
        CurrentTripItem().clearManeuvers();
      }
    });
    await addWaypoint(pointsOfInterest: CurrentTripItem().pointsOfInterest);
  }

  void anchorWaypoint() {
    addWaypoint(
        pointsOfInterest: CurrentTripItem().pointsOfInterest, isAnchor: true);
  }

  void removeWaypoint() async {
    CurrentTripItem().pointsOfInterest.removeAt(_poiHighlighted);
    renumberWaypoints(pointsOfInterest: CurrentTripItem().pointsOfInterest);
    await reRoute();
    setState(() {});
  }

  void revisitWaypoint() async {
    addWaypoint(
        pointsOfInterest: CurrentTripItem().pointsOfInterest, isRevisit: true);
  }

  void lastWaypoint() async {
    addWaypoint(
        pointsOfInterest: CurrentTripItem().pointsOfInterest, isLast: true);
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
    try {
      /// Step 1 get map image
      await getMapImage();

      /// Now save the data locally
      await _saveTrip();

      developer.log(_title, name: '_title saveTrip() 2054');
    } catch (e) {
      String err = e.toString();
      debugPrint('Error: $err');
    }
  }

  void clearTrip() {
    setState(() {
      CurrentTripItem().clearAll();
      _debugMarkers.clear();
      _following.clear();
      _lastLatLng = const LatLng(0.00, 0.00);
      _startLatLng = const LatLng(0.00, 0.00);
      CurrentTripItem().tripState = TripState.none;
      _title = 'Create a new trip';
      _leadingWidgetController.changeWidget(0);
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
        //  _alignPositionOnUpdate = AlignOnUpdate.always;
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
    try {
      _positionStream.cancel();
    } catch (e) {
      debugPrint("can't stop: ${e.toString()}");
    }

    setState(() => CurrentTripItem().tripState = TripState.stoppedFollowing);
  }

  void steps() {
    setState(() {
      CurrentTripItem().tripActions = TripActions.showSteps;
      adjustMapHeight(MapHeights.headers);
    });
  }

  void messages() {
    setState(() {
      CurrentTripItem().tripActions = TripActions.showMessages;
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
            marker: FollowerMarkerWidget(
              index: i,
              manufacturer: follower.manufacturer,
              model: follower.model,
              colour: follower.carColour,
              registration: follower.registration,
              angle: -_mapRotation * pi / 180,
              colourIndex: follower.email == Setup().user.email
                  ? 17
                  : cIndex, // 17 = transparent
            ),
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
        driveName: CurrentTripItem().heading,
        iconColour: cIndex,
        position: LatLng(_currentPosition.latitude, _currentPosition.longitude),
        marker: FollowerMarkerWidget(colourIndex: 17),
      );
      _following.add(myCarInfo);
    }
    await carInfo(myCarInfo);

    return true;
  }

  void editRoute() async {
    setState(() {
      _showTarget = true;
      CurrentTripItem().tripActions = TripActions.none;
      _appState = AppState.createTrip;
      CurrentTripItem().tripState = TripState.editing;
      _title = 'Editing: ${CurrentTripItem().heading}';
      _leadingWidgetController.changeWidget(1);
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

        case TripActions.showMessages:
          return _showMessages();

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
            distance: 0,
            currentPosition: LatLng(_currentPosition.latitude,
                _currentPosition.longitude), // ToDo: calculate how far away
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

  SizedBox _showMessages() {
    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        itemCount: _tripMessages.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TripMessageTile(
            index: index,
            message: _tripMessages[index],
            onEdit: (_) => (),
            onSelect: (_) => (),
          ),
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
    if (_debugging) {
      _currentPosition = await _getDebugPosition();
    } else {
      _currentPosition = await Geolocator.getCurrentPosition();
    }
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
      'Stuck in traffic',
      'Lost the way',
    ];
    String message = choices[0];
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: index > -1
              ? Text(
                  'Message ${_following[index].forename} ${_following[index].surname}')
              : const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text('Broadcast Message')),
          content: SizedBox(
            width: 200,
            height: 150,
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Saved Messages',
                          ),
                          initialValue: choices[0],
                          items: choices
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(item,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!),
                                ),
                              )
                              .toList(),
                          onChanged: (item) => message = item!),
                    ),
                  ),
                ]),
                if (index > -1) ...[
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await FlutterPhoneDirectCaller.callNumber(
                              _following[index].phoneNumber);
                        },
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
                            child: TextFormField(
                              autofocus: true,
                              minLines: 1,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter group message',
                              ),
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.multiline,
                              onChanged: (value) => message = value,
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
              child: const Text('Send', style: TextStyle(fontSize: 22)),
              onPressed: () {
                socket.emit('trip_message', {'message': message});
                Navigator.pop(context, message);
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
          title: Text('Drive - ${driver.driveName}'),
          content: SizedBox(
            width: 200,
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
                            decoration: const InputDecoration(
                              label: Text('Vehicle manufacturer'),
                              border: OutlineInputBorder(),
                              hintText: 'Manufacturer',
                            ),
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
                            decoration: const InputDecoration(
                              label: Text('Vehicle model'),
                              border: OutlineInputBorder(),
                              hintText: 'Model',
                            ),
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.model = value,
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
                            decoration: const InputDecoration(
                              label: Text('Colour'),
                              border: OutlineInputBorder(),
                              hintText: 'Colour',
                            ),
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.carColour = value,
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: driver.registration,
                            decoration: const InputDecoration(
                              label: Text('Registration'),
                              border: OutlineInputBorder(),
                              hintText: 'Reg No',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            onChanged: (value) => driver.registration = value,
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
                            initialValue: driver.phoneNumber,
                            decoration: const InputDecoration(
                              label: Text('Mobile'),
                              border: OutlineInputBorder(),
                              hintText: 'Mobile phone number',
                            ),
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
                driver.position = LatLng(
                    _currentPosition.latitude, _currentPosition.longitude);
                await sendDriverDetails(driver);
                if (!socket.connected) {
                  socket.connect();
                  developer.log('socket.connect() called', name: '_connect');
                }
                if (socket.connected) {
                  socket.emit('trip_join', {
                    'token': Setup().jwt,
                    'trip': CurrentTripItem().groupDriveId,
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
                int poiType =
                    CurrentTripItem().pointsOfInterest[index].getType();
                bool isWaypoint = [12, 17, 18, 19].contains(poiType);
                if (poiType != 16) {
                  // filter out followers
                  return isWaypoint
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
                  CurrentTripItem().pointsOfInterest.length &&
              ![12, 17, 18, 19].contains(CurrentTripItem()
                  .pointsOfInterest[_editPointOfInterest]
                  .getType())) ...[
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

    await picker.pickImage(source: source, imageQuality: 10).then((pickedFile) {
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
    if (_debugging) {
      _debugRoute.follow(points: CurrentTripItem().routes[0].points);
      developer.log('_debugRoute.follow() called', name: '_debug');

      _debugPositionController.stream.listen(
        (Position position) {
          updatePosition(position);
        },
      );
    } else {
      _positionStream =
          Geolocator.getPositionStream(locationSettings: _locationSettings)
              .listen(updatePosition);
    }
  }

  void updatePosition(position) {
    _currentPosition = position;
    developer.log(
        'getLocationUpdates position - lat: ${position.latitude} lng: ${position.longitude}',
        name: '_debug');
    _speed = _currentPosition.speed * 3.6 / 8 * 5; // M/S -> MPH
    LatLng pos = LatLng(_currentPosition.latitude, _currentPosition.longitude);

    if (_debugging) {
      _debugMarkers[0] = Marker(
          point: LatLng(_currentPosition.latitude, _currentPosition.longitude),
          child: Icon(Icons.bug_report, size: 30, color: Colors.teal));
      _animatedMapController.animateTo(
          dest: LatLng(_currentPosition.latitude, _currentPosition.longitude));
    }

    if (CurrentTripItem().groupDriveId.isNotEmpty) {
      if (!socket.connected) {
        developer.log('reconnectint to socket', name: '_connect');
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
              'lat': _currentPosition.latitude,
              'lng': _currentPosition.longitude,
            });
          }
        }
      }

      if (socket.connected) {
        developer.log('socket.emit() with location', name: '_connect');
        socket.emit('trip_message', {
          'message': '',
          'lat': _currentPosition.latitude,
          'lng': _currentPosition.longitude,
        });
      }
    }

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
      distanceFromRoute(
          routes: CurrentTripItem().routes,
          position: pos,
          routeDelta: _distanceFromRoute);
      setState(() => _directionsIndex = getDirectionsIndex());
    }
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
    double abHeight = 80;
    double bnHeight = 80;

    if (mapHeights[1] == 0) {
      final bnKeyContext = _bottomNavKey.currentContext;
      final abKeyContext = _appBarKey.currentContext;
      if (abKeyContext != null) {
        final box = abKeyContext.findRenderObject() as RenderBox;
        abHeight = box.size.height;
      }
      if (bnKeyContext != null) {
        final box = bnKeyContext.findRenderObject() as RenderBox;
        bnHeight = box.size.height;
      }
      mapHeights[0] = MediaQuery.of(context).size.height -
          (abHeight + bnHeight + 30); //* .825; //- 190; // info closed
      mapHeights[1] = mapHeights[0] * .35; // 400; //275; // heading data
      mapHeights[2] = mapHeights[0] * .30; // open point of interest
      mapHeights[3] = mapHeights[0] * .6; // message
    }
    mapHeight = mapHeights[MapHeights.values.indexOf(newHeight)];
    if (newHeight == MapHeights.full) {
      dismissKeyboard();
    }
    listHeight = (mapHeights[0] - mapHeight);
    // debugPrint('adjustMapHeight() listHeight:$listHeight');
    _resized = false;
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
        try {
          _floatingTextEditController1.changeOpen(0);
          _floatingTextEditController2.changeOpen(0);
        } catch (e) {
          debugPrint('FloatingTextEditController not attached');
        }
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
        //  String points = await waypointsFromPoints(50);F
        if (CurrentTripItem().routes[0].points.isNotEmpty) {
          // await getRoutePoints(waypoints: points);
        }
        List<LatLng> points = [];
        for (int i = 0; i < CurrentTripItem().routes.length; i++) {
          points.addAll(CurrentTripItem().routes[i].points);
        }

        Map<String, dynamic> routeData =
            await getRoutePoints(points: points, addPoints: true);
        CurrentTripItem().maneuvers = routeData['maneuvers'];
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
      developer.log('_error', name: '_saveTrip() 3337 : ${e.toString()}');
    }

    /// There is an issue with taking the map image in that it uses the Repaintboundary, which
    /// caseses delays in setState() affecting the widgets within the RepaintBoundary. The most
    /// common advice is to allow a delay between the image capture and the next setState() call.
    /// I have used the boolean variable _repainted to tell me when the getChips() method is called
    /// which indicates that the setState() has got through. _repained is set to false in getMapImage()
    /// just before capturing the image. The problem manifests itsself in that after saving the trip
    /// the ActionChips don't reappear automatically, but do as soon as the map is moved - ie a subsequent
    /// setState() is called.

    int tries = 0;
    while (++tries < 5) {
      await Future.delayed(Duration(seconds: 2));
      if (!_repainted) {
        setState(() => CurrentTripItem().tripState = TripState.loaded);
      } else {
        break;
      }
      developer.log(_title, name: '_title _saveTrip() 3343');
    }
    setState(() {
      CurrentTripItem().tripState = TripState.loaded;
      _title = CurrentTripItem().heading;
      CurrentTripItem().isSaved = true;
    });
    _animatedMapController.animateTo(
        dest: LatLng(_currentPosition.latitude, _currentPosition.longitude));
    return CurrentTripItem().driveId;
  }

  Future<ui.Image> getMapImage({int delay = 1}) async {
    if (CurrentTripItem().mapImage == null) {
      setState(() {
        CurrentTripItem().tripActions = TripActions.saving;
        CurrentTripItem().highliteActions = HighliteActions.none;
        adjustMapHeight(MapHeights.full);
      });
      int tries = 0;
      while (_resized == false && ++tries < 5) {
        await Future.delayed(Duration(milliseconds: delay * 500));
      }

      final mapBoundary =
          mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      CurrentTripItem().mapImage = await mapBoundary.toImage();
      await Future.delayed(Duration(seconds: 1));
      _repainted = false;
    }
    return CurrentTripItem().mapImage!;
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

/// ChangeTripStart is an important facility.
///
/// Routes published are unlikely to start or end where the downloader wants them to.
/// The routes published may also be the wrong way round.
///
/// This facility allows the user to change those constraints.
///
/// There are two basic assumptions:
///
/// 1 If a route is reversed than the only constraining points for the Router are the
///   trip start and end, and any points of interest or waypoints entered by the author.
///   To this end the maneuvers are recalculated based on those constraints
///
/// 2 If a route isn't reversed, but just extended then the maneuvers will be kept, and
///   simply extended at either end.
///
/// Trying to follow the original maneuvers if a route is reversed is just too problamatic,
/// with roundabouts, one-way systems and motorways making it unreliable.

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
          height: 350,
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
                List<LatLng> points = [];
                LatLng newPoint;

                /// Now look at the waypoints
                /// 1 Reverse the current waypoints if required
                /// 2 Add the new waypoint for added start or end

                Map<String, dynamic> tripData = {};
                if (CurrentTripItem().routes.isNotEmpty && changed) {
                  List<LatLng> currentPoints = CurrentTripItem()
                      .routes[CurrentTripItem().routes.length - 1]
                      .points;

                  if (values[0]) {
                    points = waypointsFromPointsOfInterest(reversed: true);
                    tripData = await getRoutePoints(points: points);
                    currentPoints.clear();
                    currentPoints.addAll(tripData['points']);

                    CurrentTripItem().maneuvers.clear();
                    CurrentTripItem().maneuvers = tripData['maneuvers'];
                  }
                  if (values[1] || values[2] || values[3] || values[4]) {
                    /// 1 / 3 start  2 / 4 finish from current position / screenCentre
                    points = waypointsFromPointsOfInterest();
                    newPoint = values[1] || values[3]
                        ? LatLng(
                            currentPosition.latitude, currentPosition.longitude)
                        : LatLng(screenCenter.latitude, screenCenter.longitude);
                    if (values[1] || values[3]) {
                      tripData =
                          await getRoutePoints(points: [newPoint, points[0]]);
                      CurrentTripItem().routes.insert(
                            0,
                            mt.Route(
                                points: tripData['points'],
                                color: colourList[Setup().routeColour]),
                          );
                      tripData['maneuvers'].addAll(CurrentTripItem().maneuvers);
                      CurrentTripItem().maneuvers = tripData['maneuvers'];
                    } else {
                      tripData = await getRoutePoints(
                          points: [points[points.length - 1], newPoint]);
                      CurrentTripItem().routes.add(
                            mt.Route(
                                points: tripData['points'],
                                color: colourList[Setup().routeColour],
                                strokeWidth: 5),
                          );
                      CurrentTripItem().maneuvers.addAll(tripData['maneuvers']);
                    }
                  }
                }
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Ok', style: TextStyle(fontSize: 22))),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 20)),
          ),
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
  if (idx == 0 || before) {
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
    // int idx = (gap + 1) * (i + 1);
    int idx = gap * (i + 1);
    try {
      waypoints =
          '$waypoints;${latLongs[idx].longitude},${latLongs[idx].latitude}';
    } catch (e) {
      debugPrint('Error getting points: ${e.toString()}');
    }
  }

  waypoints =
      '$waypoints;${latLongs[count - 1].longitude},${latLongs[count - 1].latitude}';

  return waypoints;
}

Future<String> waypointsFromManeuvers(
    {int points = 50, reverse = false}) async {
  List<LatLng> latLongs = [];

  /// Only going to add the start, end, and any turns. The Router will do the rest

  /*
  for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
    if (i == 0 ||
        i == CurrentTripItem().maneuvers.length - 1 ||
        CurrentTripItem().maneuvers[i].type == 'turn' ||
        CurrentTripItem().maneuvers[i].type.contains('exit')) {
      latLongs.add(CurrentTripItem().maneuvers[i].location);
    }
  }
  */
  latLongs.add(CurrentTripItem().maneuvers[0].location);
  latLongs.add(CurrentTripItem()
      .maneuvers[CurrentTripItem().maneuvers.length - 1]
      .location);

  if (reverse) {
    latLongs = latLongs.reversed.toList();
    return '${latLongs[0].longitude},${latLongs[0].latitude};${latLongs[1].longitude},${latLongs[1].latitude}';
  }

  int count = latLongs.length;
  final double incrementer;
  if (count <= points) {
    incrementer = 1;
  } else {
    incrementer = count / points;
  }

  String waypoints = '';
  String delimiter = '';
  for (int i = 0; i < count; i++) {
    int idx = (incrementer * i).round();
    if (idx < latLongs.length) {
      waypoints =
          '$waypoints$delimiter${latLongs[idx].longitude},${latLongs[idx].latitude}';
      delimiter = ';';
    } else {
      debugPrint('Index overflow');
    }
  }

  return waypoints;
}

List<LatLng> waypointsFromPointsOfInterest(
    {bool reversed = false,
    double newPointLat = 0.0,
    newPointLng = 0.0,
    atEnd = false}) {
  List<LatLng> waypoints = [];
  List<PointOfInterest> pois = [];
  pois.addAll(CurrentTripItem().pointsOfInterest);
  if (reversed) {
    pois = pois.reversed.toList();
  }

  if (newPointLat + newPointLng != 0) {
    if (atEnd) {
      if (pois[pois.length - 1].getType() == 18) {
        pois[pois.length - 1].setType(12);
      }
      pois.add(
        PointOfInterest(
          type: 18,
          markerPoint: LatLng(newPointLat, newPointLng),
          marker: MarkerWidget(
            type: 18,
            description: 'Trip end',
            angle: 1 * pi / 180,
          ),
        ),
      );
    } else {
      if (pois[0].getType() == 17) {
        pois[0].setType(12);
      }
      pois.insert(
        0,
        PointOfInterest(
          type: 17,
          markerPoint: LatLng(newPointLat, newPointLng),
          marker: MarkerWidget(
            type: 17,
            description: 'Trip start',
            angle: 1 * pi / 180,
          ),
        ),
      );
    }
    CurrentTripItem().pointsOfInterest = pois;
  }

  for (int i = 0; i < pois.length; i++) {
    if ([12, 17, 18, 19].contains(pois[i].getType())) {
      waypoints.add(pois[i].point);
    }
  }

  return waypoints;
}

_leadingWidget(context) {
  return context?.openDrawer();
}

/// Function for getting the api data from the router it returns a Map<String, dynamic> when
/// a string of ; delimited lat long pairs is passed as waypoints the returned map contains:
/// 'name': name of the last point added
/// 'distance' the distance between the first and last point
/// 'duration' the time estimated to follow the route
/// 'summary:
/// 'points': the List<LatLng> of points that describe the route - PointOfInterest.route[x].points

Future<Map<String, dynamic>> getRoutePoints(
    {required List<LatLng> points, bool addPoints = true}) async {
  dynamic jsonResponse;
  String delim = '';
  String waypoints = '';
  int i;
  int jump = points.length > 50 ? (points.length ~/ 50) : 1;
  jump = jump > 1 && jump * 50 > points.length ? jump - 1 : jump;

  for (i = 0; i < points.length; i += jump) {
    waypoints = '$waypoints$delim${points[i].longitude},${points[i].latitude}';
    delim = ';';
  }

  String avoid = setAvoiding();
  var url = Uri.parse(
      '$urlRouter$waypoints?steps=true&annotations=true&geometries=geojson&overview=full$avoid');
  try {
    var response = await http.get(url).timeout(const Duration(seconds: 5));
    if ([200, 201].contains(response.statusCode)) {
      jsonResponse = jsonDecode(response.body);
      if (jsonResponse == null) {
        return {'msg': 'Error'};
      }
    } else {
      return {'msg': 'Error'};
    }
  } catch (e) {
    debugPrint('Http error: ${e.toString()}');
    return {'msg': 'Error'};
  }
//  return jsonResponse;
//}

  /// processRouterData()
  /// Takes the data sent from the router and generates the data for the map:
  /// 1 The points - used for manual route planning
  /// 2 The turn-by-turn directions

//Map<String, dynamic> processRouterData(
//    {required dynamic jsonResponse,
//    required String waypoints,
//    bool includeWaypoints = true,
//    bool addPoints = true}) {
  List<LatLng> routePoints = [];
  List<Maneuver> maneuvers = [];
  final Map<String, dynamic> result = {
    "name": '',
    "distance": '0.0',
    "duration": 0,
    "summary": '',
    "maneuvers": maneuvers,
    "points": routePoints,
  };

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

  // List<String> waypointList = waypoints.split(';');
  // CurrentTripItem().maneuvers.clear();

  // if (waypointList.length > 1 && waypointList[0] != waypointList[1]) {
  // includeWaypoints = true;  String lastRoad = name;

  String type = '';

  bool added = false;

  if (addPoints) {
    var router = jsonResponse['routes'][0]['geometry']['coordinates'];
    for (int i = 0; i < router.length; i++) {
      routePoints.add(LatLng(router[i][1], router[i][0]));
    }
  }

  try {
    List<dynamic> legs = jsonResponse['routes'][0]['legs'];
    String lastRoad = legs[0]['steps'][0]['name'];
    String name =
        '$lastRoad - ${legs[0]['steps'][legs[0]['steps'].length - 1]['name']}';
    for (int j = 0; j < legs.length; j++) {
      List<dynamic> steps = legs[j]["steps"];
      //  String _roadFrom = '';
      //  String _roadTo = '';
      double distance = 0;

      for (int k = 0; k < steps.length; k++) {
        Map<String, dynamic> maneuver = steps[k]['maneuver'];
        try {
          type = maneuver['type'] ?? '';
          String modifier = maneuver['modifier'] ?? '';
          added = false;
          if ((modifier.isNotEmpty || type == 'depart')) {
            if (modifier.isEmpty) {
              debugPrint('empty');
            }

            if (type.contains('roundabout') || type.contains('rotary')) {
              developer.log('type: $type', name: '_maneuver');
            }
            List<dynamic> lngLat = maneuver['location'];
            added = (points.length == 2 ||
                !points.contains(
                    LatLng(lngLat[1].toDouble(), lngLat[0].toDouble())));
            distance += steps[k]['distance'].toDouble();
            if (added) {
              maneuvers.add(
                Maneuver(
                  roadFrom: steps[k]['name'],
                  roadTo: lastRoad,
                  bearingBefore: maneuver['bearing_before'] ?? 0,
                  bearingAfter: maneuver['bearing_after'] ?? 0,
                  exit: maneuver['exit'] ?? 0,
                  location: LatLng(lngLat[1].toDouble(), lngLat[0].toDouble()),
                  modifier: modifier,
                  type: type,
                  distance: distance,
                ),
              );
              distance = 0;
            }
          }
        } catch (e) {
          String err = e.toString();
          debugPrint(err);
        }
        if (added) {
          if (maneuvers.length > 1) {
            maneuvers[maneuvers.length - 2].roadTo =
                maneuvers[maneuvers.length - 1].roadFrom;
          }
          if (maneuvers.isNotEmpty) {
            lastRoad = maneuvers[maneuvers.length - 1].roadTo;
            maneuvers[maneuvers.length - 1].type =
                maneuvers[maneuvers.length - 1]
                    .type
                    .replaceAll('rotary', 'roundabout');
          }
        }
      }
    }
    result["name"] = name;
    result["distance"] = distance.toStringAsFixed(1);
    result["duration"] = jsonResponse['routes'][0]['duration'];
    result["summary"] = summary;
    result["maneuvers"] = maneuvers;
    result["points"] = routePoints;
  } catch (e) {
    debugPrint('Error processing router data: ${e.toString()}');
  }
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
