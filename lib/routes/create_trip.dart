import 'dart:async';
import 'dart:core';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:universal_io/universal_io.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'dart:math';
import '/constants.dart';
import '/classes/classes.dart';
import '/classes/route.dart' as mt;
import '/helpers/create_trip_helpers.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '/screens/screens.dart';
import '/services/services.dart' hide getPosition;
import '/models/models.dart';
import '/helpers/edit_helpers.dart';
import '/tiles/tiles.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
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

class CreateTripController {
  _CreateTripState? _createTripState;
  void _addState(_CreateTripState createTripState) {
    _createTripState = createTripState;
  }

  bool get isAttached => _createTripState != null;

  Future<ui.Image?> getMapImage() async {
    try {
      return _createTripState?.getMapImage();
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
      _createTripState?.updateValues(values: values);
    } catch (e) {
      debugPrint("Can't update CreateTrip state values");
    }
  }

  bool? getTripInfo({bool prompt = false}) {
    try {
      return _createTripState?.getTripDetails(prompt: prompt);
    } catch (e) {
      debugPrint("Can't stop following");
    }
    return false;
  }

  void drive({bool follow = false}) {
    try {
      _createTripState?.getLocationUpdates();
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
  final mapController = MapController();
  late final RoutesBottomNavController _bottomNavController; // =
  final GroupMessagesController groupMessagesController =
      GroupMessagesController();
  bool isVisible = false;
  PopupValue popValue = PopupValue(-1, '', '');
  final navigatorKey = GlobalKey<NavigatorState>();
  List<Marker> markers = [];
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
  LatLng topRight = const LatLng(0, 0);
  LatLng bottomLeft = const LatLng(0, 0);
  LatLng testPos = LatLng(0, 0);
  bool _updateOverlays = true;
  late final ExpandNotifier _expandNotifier;
  final ScrollController _scrollController = ScrollController();
  // final mt.RouteAtCenter _routeAtCenter = mt.RouteAtCenter();
  bool _tripStarted = false;
  late AnimatedMapController _animatedMapController;
  late final StreamController<double?> _allignPositionStreamController;
  late final StreamController<void> _allignDirectionStreamController;
  late final LeadingWidgetController _leadingWidgetController;
  late final FloatingTextEditController _floatingTextEditController1;
  late final FloatingTextEditController _floatingTextEditController2;
  late final DirectionTileController _directionTileController;
  late TileProviders _cachedProviders;
  late final StreamController<Position> _debugPositionController;
  late final FollowRoute _debugRoute;
  int initialLeadingWidgetValue = 0;
  // late AlignOnUpdate _alignPositionOnUpdate;
  late AlignOnUpdate _alignDirectionOnUpdate;
  final List<Place> _places = [];
  // Map<String, dynamic> _waypointPositions = {};

  double _zoom = 13;
  final _dividerHeight = 35.0;
  List<LatLng> routePoints = const [LatLng(51.478815, -0.611477)];

  String images = '';
  //  String stadiaMapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';
  late Style _style;
  PublishedFeatures _publishedFeatures = PublishedFeatures(
      features: [], pinTap: (_) => (), pointOfInterestLookup: {});

  final OsmFeatures _osmFeatures = OsmFeatures(amenities: []);
  // List<PointOfInterest> _pointsOfInterest = [];
  final List<Marker> _debugMarkers = [];
  final bool _debugging = true;
  final String _debuggingRoute = 'Debug';
  final Directions _directions = Directions();

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
          point: latLng,
          sounds: audio,
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
    // NetworkState().initialise();

    /// Have to have a controller instance for each Widget
    /// being controlled, as the controller shares the widgets state
    /// A single controller would then share the state of
    /// all the widgets it controlls - not good.

    _floatingTextEditController1 = FloatingTextEditController();
    _floatingTextEditController2 = FloatingTextEditController();
    _bottomNavController = RoutesBottomNavController();
    _directionTileController = DirectionTileController();
    _expandNotifier = ExpandNotifier(-1);

    _locationSettings = getGeolocatorSettings(
        defaultTargetPlatform: TargetPlatform.android, distanceFilter: 5);

    if (_debugging) {
      _debugPositionController = StreamController<Position>();
      _debugRoute = FollowRoute(controller: _debugPositionController);
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
      CurrentTripItem().tripValues.title = 'Create a new trip';
      _allignPositionStreamController = StreamController<double?>.broadcast();
      _animatedMapController = AnimatedMapController(vsync: this);
      _allignDirectionStreamController = StreamController<void>.broadcast();
      //   _alignPositionOnUpdate = AlignOnUpdate.never;
      CurrentTripItem().tripValues.autoCentre = false;
      _alignDirectionOnUpdate = AlignOnUpdate.never; // never;
      fn1 = FocusNode();
      listHeight = -1;
      CurrentTripItem().tripValues.autoCentre = false;
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
              //      developer.log('setState() 496', name: '_setState');
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

  ///
  /// Returns the routepoints and the waypoint data for the added waypoint
  /// _SimpleUri (http://10.101.1.150:5000/route/v1/driving/-0.0237985,52.9776561;-0.0237985,52.9776561?steps=true&annotations=true&geometries=geojson&overview=full&exclude=motorway&exclude=trunk&exclude=primary)

  @override
  Widget build(BuildContext context) {
    int initialNavBarValue = 2;
    initialLeadingWidgetValue = [TripState.manual, TripState.editing]
            .contains(CurrentTripItem().tripState)
        ? 1
        : 0;
    //  developer.log(
    //      'Build 1 setting initialLeadingValue to: $initialLeadingWidgetValue',
    //      name: '_leading');

    if (ModalRoute.of(context)?.settings.arguments != null &&
        listHeight == -1) {
      final args = ModalRoute.of(context)!.settings.arguments as TripArguments;
      CurrentTripItem().load(arguments: args);
      // CurrentTripItem().downloadTiles(style: _style);
      CurrentTripItem().tripValues.mapHeight = MapHeights.full;

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
      //  developer.log(
      //      'Build 2 setting initialLeadingValue to: $initialLeadingWidgetValue',
      //      name: '_leading');

      initialNavBarValue = 2;
    }
    return Scaffold(
      backgroundColor: Colors.blue,
      key: _scaffoldKey,

      drawer: const MainDrawer(),
      resizeToAvoidBottomInset: false, // Stops keyboard moving FABS
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
                adjustMapHeight(CurrentTripItem().tripValues.mapHeight);
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
              onUpdate: (val) => val ? setState(() => ()) : () => ())),

      bottomNavigationBar: RoutesBottomNav(
          key: _bottomNavKey,
          controller: _bottomNavController,
          initialValue: initialNavBarValue,
          onMenuTap: (_) => {}),
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
      _currentPosition = await Geolocator.getCurrentPosition();

      if (Setup().hasLoggedIn) {
        var setupRecords = await getPrivateRepository().recordCount('setup');
        //  _myTripItems = await tripItemFromDb();
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
    VectorTileProvider apiProvider = _style.providers.get('openmaptiles');
    _cachedProvider = CachedVectorTileProvider(delegate: apiProvider);
    _cachedProviders = TileProviders({'openmaptiles': _cachedProvider});

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
                mapInfo['content'] = pointOfInterest.description;
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
    if (!_hasRepainted) {
      if (Setup().appState.isNotEmpty) {
        CurrentTripItem().restoreState();
      }
      if (CurrentTripItem().tripState != TripState.none) {
        switch (CurrentTripItem().tripState) {
          case TripState.manual:
            {
              CurrentTripItem().tripValues.manual();
              break;
            }
          case TripState.editing:
            {
              CurrentTripItem().tripValues.editing();
              break;
            }
          case TripState.automatic:
            {
              CurrentTripItem().tripValues.automatic();
              break;
            }

          case TripState.recording:
            {
              CurrentTripItem().tripValues.record();
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
        CurrentTripItem().tripValues.pointOfInterestIndex =
            CurrentTripItem().pointsOfInterest.length - 1;
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

  detailClose() {
    //  debugPrint('resetting _poiDetailIndex');
    if (_poiDetailIndex > -1) {
      _poiDetailIndex = -1;
      //    developer.log('setState() 848', name: '_setState');
      setState(() {});
    }
  }

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
          if (CurrentTripItem().groupDriveId.isNotEmpty) ...[
            FloatingActionButton(
              heroTag: 'broadcast',
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => contactDiolog(
                      context: context, socket: socket)), // messageGroup(-1),
              backgroundColor: Colors.blue,
              shape: const CircleBorder(),
              child: Icon(
                Icons.chat_outlined,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
          ],
          if ([TripState.recording, TripState.following]
              .contains(CurrentTripItem().tripState)) ...[
            // const SizedBox(height: 10),
            if (CurrentTripItem().tripValues.goodRoad.isGood) ...[
              FloatingActionButton(
                heroTag: 'goodRoad',
                onPressed: () => setState(
                    () => CurrentTripItem().tripValues.goodRoad.isGood = false),
                backgroundColor: CurrentTripItem().tripValues.goodRoad.isGood
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
                    CurrentTripItem().tripValues.goodRoad.isGood = true;
                    CurrentTripItem().tripValues.pointOfInterestIndex =
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

                _animatedMapController
                    .animateTo(
                        dest: LatLng(_currentPosition.latitude,
                            _currentPosition.longitude))
                    .then((_) => updateOverlays(
                        zoom:
                            _animatedMapController.mapController.camera.zoom));
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

  onPlaceSelect(LatLng position) async {
    CurrentTripItem().tripValues.autoCentre = false;
    //   _alignPositionOnUpdate = AlignOnUpdate.never;
    _alignDirectionOnUpdate = AlignOnUpdate.never;
    _animatedMapController
        .animateTo(dest: position)
        .then((_) => updateOverlays());
  }

  getDropdownItems(String query) async {
    _places.clear();
    _places.addAll(await getPlaces(value: query));
    //  developer.log('setState() 1233', name: '_setState');
    setState(() {});
  }

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
                updateOverlays(zoom: 13);
                setState(() => listHeight = 0);

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
                    CurrentTripItem().tripValues.title =
                        CurrentTripItem().heading;
                    CurrentTripItem().tripValues.showTarget = false;
                    if (!socket.connected) {
                      socket.connect();
                    }
                  }
                }
              },
              onPositionChanged: (position, hasGesure) {
                try {
                  CurrentTripItem().changePosition(
                      position:
                          _animatedMapController.mapController.camera.center,
                      onChange: (update) => update ? setState(() => ()) : null);
                  if (hasGesure) {
                    // _updateMarkerSize(position.zoom);
                  }

                  if (_updateOverlays) {
                    updateOverlays(zoom: position.zoom);
                  }

                  _mapRotation =
                      _animatedMapController.mapController.camera.rotation;
                } catch (e) {
                  debugPrint('Error: ${e.toString()}');
                }
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
              if (kIsWeb)
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png', //  drives.motatek.com/static/tiles/{z}/{x}/{y}.pbf',
                ),
              if (!kIsWeb)
                VectorTileLayer(
                    theme: _style.theme, //_style.theme,
                    maximumZoom: 13,
                    //sprites: _style.sprites,
                    tileProviders: _cachedProviders, // _style.providers,
                    // showTileDebugInfo: true,
                    layerMode: VectorTileLayerMode.vector,
                    //  cacheFolder: getCacheFolder,
                    tileOffset: TileOffset.DEFAULT),
              if (!_debugging) ...[
                CurrentLocationLayer(
                  focalPoint: const FocalPoint(
                    ratio: Point(0.0, 1.0),
                    offset: Point(0.0, -60.0),
                  ),
                  alignPositionStream: _allignPositionStreamController.stream,
                  alignDirectionStream: _allignDirectionStreamController.stream,
                  //   alignPositionOnUpdate: _alignPositionOnUpdate,
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
                )
              ],
              mt.RouteLayer(
                polylines: getPolyLines(),

                ///CurrentTripItem().routes,
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
                      onUpdate: () => setState(
                          () => {}), //CurrentTripItem().tripValues = values),
                    ),
            ),
          ),
          if (CurrentTripItem().tripValues.showTarget) ...[
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

  List<mt.Route> getPolyLines() {
    return CurrentTripItem().routes;
  }

  LatLng chipPosition() {
    try {
      return _animatedMapController.mapController.camera.center;
    } catch (e) {
      return LatLng(0, 0);
    }
  }

  Future<Position> _getDebugPosition() async {
    return _debugRoute.getPosition ?? Geolocator.getCurrentPosition();
  }

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
          driveId: CurrentTripItem().driveUri,
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
        position: LatLng(_currentPosition.latitude, _currentPosition.longitude),
        routeIndex: routeIndex,
        pointIndex: pointIndex);
    if (update) {
      setState(() => _directionTileController.updateRoute());
    }
  }

  dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void updateOverlays({double zoom = 12}) async {
    Fence newFence = Fence.fromBounds(
        _animatedMapController.mapController.camera.visibleBounds);

    zoom = _animatedMapController.mapController.camera.zoom;

    /// Updating the overlays depends on two factors:
    /// 1 The cached data needs refreshing
    /// 2 The zoom level has changed - so the markers have to change

    if (!_cacheFence.contains(bounds: newFence) || zoom != _zoom) {
      _zoom = zoom;
      if (zoom > 10) {
        _updateOverlays = false;
        _cacheFence.setBounds(bounds: newFence, deltaDegrees: 0.5);
        double markerSize = 20 + ((zoom - 10) * 4);
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

  /// Have split out the state change from the action part
  /// as want to use the state change when restoring the
  /// CreateTrip route without calling setState which is
  /// embedded in adjustMapHeight()
  /// ie automatic called when restoring CurrentTrip state
  /// automatically() called on the ActionChip onPress()
  ///
  ///
  void updateValues({required CreateTripValues values}) {
    CurrentTripItem().tripValues = values;
    adjustMapHeight(values.mapHeight);
    _leadingWidgetController.changeWidget(values.leadingWidget);
    if (CurrentTripItem().tripValues.stopStream) {
      _positionStream.cancel();
    }

    if (values.setState) {
      setState(() => {});
    }
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
              socket: socket,
              forename: follower.forename,
              surname: follower.surname,
              phoneNumber: follower.phoneNumber,
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
        marker: FollowerMarkerWidget(
          colourIndex: 17,
          socket: socket,
        ),
      );
      _following.add(myCarInfo);
    }
    await carInfo(myCarInfo);

    return true;
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

        case TripActions.goodRoad:
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
        default:
          return SizedBox(height: 0);
      }
    } else {
      if ([
        TripActions.showGroup,
        TripActions.showMessages,
        TripActions.showSteps
      ].contains(CurrentTripItem().tripActions)) {
        setState(() => CurrentTripItem().tripActions = TripActions.none);
      }
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
        _handleTripInfo(); // <- remove keyboard

        //    _showExploreDetail();
      }),
      onVerticalDragUpdate: (DragUpdateDetails details) {
        //  developer.log('setState() 1689', name: '_setState');
        setState(() {
          if (mapHeights[0] == 0) {
            mapHeights[0] = MediaQuery.of(context).size.height - 190;
          }
          mapHeight += details.delta.dy;
          mapHeight = mapHeight > mapHeights[0] ? mapHeights[0] : mapHeight;
          mapHeight = mapHeight < 1 ? 1 : mapHeight;
          listHeight = mapHeights[0] - mapHeight;
          if (listHeight == 0.0) {
            debugPrint('listHeight reset');
          }
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
            maneuvers: CurrentTripItem().maneuvers,
            routes: CurrentTripItem().routes,
            onLongPress: maneuverLongPress,
          ),
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

  void maneuverLongPress(int index) async {
    CurrentTripItem().tripValues.showTarget = true;
    _animatedMapController.animateTo(
        dest: CurrentTripItem().maneuvers[index].location);
    // CurrentTripItem().tripState = TripState.following;
    debugPrint('index: $index');
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
    _directions.update(position: CurrentTripItem().maneuvers[index].location);
    setState(() => _directions.currentIndex = index);
    return;
  }

  Future<void> followerIconClick(int index) async {
    String message = await messageGroup(index);
    if (message.isNotEmpty) {}
    return;
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
                driver.position = LatLng(
                    _currentPosition.latitude, _currentPosition.longitude);
                await sendDriverDetails(driver);
                if (!socket.connected) {
                  socket.connect();
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
    CurrentTripItem().tripValues.showTarget = true;
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
              key: ValueKey(CurrentTripItem().tripValues.pointOfInterestIndex),
              index: CurrentTripItem().tripValues.pointOfInterestIndex,
              pointOfInterest: CurrentTripItem().pointsOfInterest[index],
              imageRepository: _publishedFeatures.imageRepository,
              onExpandChange: (expanded) => expandChange,
              onIconTap: iconButtonTapped,
              onDelete: removePointOfInterest,
              onRated: onPointOfInterestRatingChanged,
              onSave: (index) => onPointOfInterestSaved(index: index),
              expanded: true,
              canEdit: !readOnly,
            ),
          )
        ],
      ),
    );
  }

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
                      imageRepository: _publishedFeatures.imageRepository,
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
                      CurrentTripItem().movePointOfInterest(oldIndex, newIndex);
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
                  imageRepository: _publishedFeatures.imageRepository,
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
        alertMessage: CurrentTripItem().heading, // _myTripItems[index].heading,
        okValue: index,
        callback: onConfirmDeleteTrip);
  }

/*
  Future<void> onGetgTrip(int index) async {
    // CurrentTripItem() = MyTripItem(heading: '');
    CurrentTripItem()
        .fromMyTripItem(myTripItem: await getMyTrip(tripItems[index].uri));
    CurrentTripItem().id = -1;
    CurrentTripItem().driveUri = tripItems[index].uri;
    setState(() {
      CurrentTripItem().tripState = TripState.notFollowing;
      _alignDirectionOnUpdate = AlignOnUpdate.never;
      // _alignPositionOnUpdate = AlignOnUpdate.never;
      CurrentTripItem().tripActions = TripActions.none;
      _appState = AppState.driveTrip;
      CurrentTripItem().tripValues.showTarget = false;
      CurrentTripItem().tripValues.title = CurrentTripItem().heading;
      adjustMapHeight(MapHeights.full);
    });

    return;
  }
*/
  onPointOfInterestRatingChanged(int value, int index) async {
    putPointOfInterestRating(
        CurrentTripItem().pointsOfInterest[index].url, value.toDouble());
  }

  void onPointOfInterestSaved({index = -1}) {
    if (index > -1) {
      PointOfInterest updated = PointOfInterest.clone(
          pointOfInterest: CurrentTripItem().pointsOfInterest[index]);

      setState(() => CurrentTripItem().pointsOfInterest[index] = updated);
      debugPrint('done');
    }
  }

  void onConfirmDeleteTrip(int value) {
    debugPrint('Returned value: ${value.toString()}');
    if (value > -1) {
      // int driveId = _myTripItems[value].driveId;
      int driveId = CurrentTripItem().driveId;
      getPrivateRepository().deleteDriveLocal(driveId: driveId);
      CurrentTripItem().clearAll();
      // setState(() => _myTripItems.removeAt(value));
    }
  }

/*
  Widget _editTripDetails() {
    return _exploreDetailsHeader();
  }
*/

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
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a short summary of your trip...',
                    hintStyle: hintStyle(context: context),
                    labelText: 'Trip summary',
                    labelStyle: labelStyle(context: context)),
                style: textStyle(context: context),
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
                onFieldSubmitted: (_) => adjustMapHeight(MapHeights.full),
                onChanged: (text) => CurrentTripItem().body = text,
              ),
            ),
          ],
        ),
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
        CurrentTripItem().pointsOfInterest.add(PointOfInterest(
            type: 18, point: CurrentTripItem().tripValues.lastLatLng));
      } else {
        if (CurrentTripItem().tripValues.streamFinished) {
          _positionStream.cancel();
        }
        if (_debugging) {
          if (_debuggingRoute.isEmpty) {
            _debugRoute.follow(routes: CurrentTripItem().routes);
          } else {
            List<mt.Route> debugRoute = await getPrivateRepository()
                .getRoutesByName(name: _debuggingRoute);
            _debugRoute.follow(routes: debugRoute);
          }
          // if (_debugPositionController.stream.)
          _positionStream = _debugPositionController.stream.listen(
            (Position position) {
              updatePosition(position);
            },
          );
        } else {
          _positionStream =
              Geolocator.getPositionStream(locationSettings: _locationSettings)
                  .listen(updatePosition);
        }
        CurrentTripItem().tripValues.streamStarted = true;
        CurrentTripItem().tripValues.streamFinished = false;
        CurrentTripItem().tripValues.lastLatLng = LatLng(0, 0);
        CurrentTripItem().tripValues.startLatLng = LatLng(0, 0);
        CurrentTripItem().tripValues.position = LatLng(0, 0);
        _positionStream
            .onDone(() => CurrentTripItem().tripValues.streamFinished = true);
      }
    } catch (e) {
      developer.log('Stream error: ${e.toString()}', name: '_stream');
    }
  }

  void updatePosition(position) {
    // developer.log('updatePosition() called', name: '_tracking');
    _currentPosition = position;
    _speed = position.speed * 3.6 / 8 * 5; // M/S -> MPH

    LatLng pos = LatLng(
        position.latitude,
        position
            .longitude); // LatLng(_currentPosition.latitude, _currentPosition.longitude);

    if (_debugging) {
      _speed = 43.0;
      if (_debugMarkers.isEmpty) {
        _debugMarkers.add(Marker(
            point: LatLng(position.latitude, position.longitude),
            child: Icon(Icons.navigation, size: 40, color: Colors.blue)));
      } else {
        _debugMarkers[0] = Marker(
            point: LatLng(position.latitude, position.longitude),
            child: Icon(Icons.navigation, size: 40, color: Colors.blue));
      }
      // child: Icon(Icons.bug_report, size: 30, color: Colors.teal));
      _animatedMapController.animateTo(
          dest: LatLng(position.latitude, position.longitude));
      if (_following.isNotEmpty) {
        try {
          int index = _debugRoute.getIndex;
          int jump = 12;
          for (int i = 0; i < _following.length; i++) {
            if (index > jump * (i + 1)) {
              _following[i] = Follower.moveFollower(
                follower: _following[i],
                marker: _following[i].marker,
                position: _debugRoute.getPositionAt(index - (jump * (i + 1))),
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
        CurrentTripItem().goodRoads.last.points.add(pos);
      }
      CurrentTripItem().tripValues.lastLatLng = pos;
    }

    if (CurrentTripItem().tripState == TripState.following) {
      setState(() => _directionsIndex = getDirectionsIndex());
    }
  }

  void addGoodRoad({required LatLng position, name = 'Good road', audio = ''}) {
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
  }

  int getDirectionsIndex() {
    int idx = -1;
    double distance = 99999;
    double temp;
    if (CurrentTripItem().tripState == TripState.following) {
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
    }
    return idx;
  }

  adjustMapHeight(MapHeights newHeight) {
    // debugPrint(
    //     'adjustMapHeight() mapHeights[1]: $mapHeights[1], newHeight: $newHeight');
    double abHeight = 100;
    double bnHeight = 100;

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
          (abHeight + bnHeight + 40); //was 30 * .825; //- 190; // info closed
      mapHeights[1] = mapHeights[0] * .35; // 400; //275; // heading data
      mapHeights[2] = mapHeights[0] * .30; // open point of interest
      mapHeights[3] = mapHeights[0] * .6; // message
    }
    mapHeight = mapHeights[MapHeights.values.indexOf(newHeight)];

    if (newHeight == MapHeights.full) {
      dismissKeyboard();
    }
    listHeight = (mapHeights[0] - mapHeight);
    if (listHeight == 0.0) {
      // setState(() => ());
      debugPrint('listHeight reset');
    }

    // debugPrint('adjustMapHeight() listHeight:$listHeight');
    _resized = false;
    _resizeDelay = 400;
  }

  locationLatLng(pos) {
    //  debugPrint(pos.toString());
    //  developer.log('setState() 2574', name: '_setState');
    setState(() {
      //   _showSearch = false;
      _animatedMapController.animateTo(dest: pos);
    });
  }

/*
  Color _routeColour(bool goodRoad) {
    return goodRoad
        ? uiColours.keys.toList()[Setup().goodRouteColour]
        : uiColours.keys.toList()[Setup().routeColour];
  }
*/
  routeTapped(routes, details) {
    if (details != null) {
      //   developer.log('setState() 2589', name: '_setState');
      setState(() {});
    }
  }

  expandChange(var details) {
    if (details != null) {
      //   developer.log('setState() 2596', name: '_setState');
      setState(
        () {
          //    debugPrint('ExpandChanged: $details');
          CurrentTripItem().tripValues.pointOfInterestIndex = details;
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
    if (CurrentTripItem().tripValues.pointOfInterestIndex > -1) {
      _animatedMapController.animateTo(
          dest: CurrentTripItem()
              .pointsOfInterest[
                  CurrentTripItem().tripValues.pointOfInterestIndex]
              .point);
    }
  }

  removePointOfInterest(var details) {
    if (CurrentTripItem().tripValues.pointOfInterestIndex > -1) {
      CurrentTripItem().removePointOfInterestAt(
          CurrentTripItem().tripValues.pointOfInterestIndex);
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
      //   developer.log('setState() 2644', name: '_setState');
      //    setState(() {
      //      debugPrint('Map event: ${details.toString()}');
      //    });
    }
  }

  Future<ui.Image> getMapImage({int delay = 1}) async {
    if (CurrentTripItem().mapImage == null) {
      //     developer.log('setState() 2697', name: '_setState');
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
    }
    return CurrentTripItem().mapImage!;
  }

  bool getTripDetails({bool prompt = false}) {
    if (CurrentTripItem().heading.isEmpty) {
      if (prompt) {
        Utility().showConfirmDialog(context, "Can't save - more info needed",
            "Please enter what you'd like to call this trip.");
      }
      //  developer.log('setState() 2658', name: '_setState');
      setState(() {
        adjustMapHeight(MapHeights.headers);
        CurrentTripItem().tripActions = TripActions.headingDetail;
        fn1.requestFocus();
      });
      return false;
    }

    if (CurrentTripItem().subHeading.isEmpty) {
      if (prompt) {
        Utility().showConfirmDialog(context, "Can't save - more info needed",
            'Please give a brief summary of this trip.');
      }
      //  developer.log('setState() 2672', name: '_setState');
      setState(() {
        adjustMapHeight(MapHeights.headers);
        CurrentTripItem().tripActions = TripActions.headingDetail;
      });
      return false;
    }

    if (CurrentTripItem().body.isEmpty) {
      if (prompt) {
        Utility().showConfirmDialog(context, "Can't save - more info needed",
            'Please give some interesting details about this trip.');
      }
      //  developer.log('setState() 2685', name: '_setState');
      setState(() {
        adjustMapHeight(MapHeights.headers);
        CurrentTripItem().tripActions = TripActions.headingDetail;
      });
      return false;
    }
    return true;
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
