import 'dart:async';
// import 'dart:ffi';
// import 'dart:ffi';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

import 'dart:math';
// import 'dart:developer';
import 'dart:io';

import 'package:drives/screens/main_drawer.dart';
import 'package:drives/screens/group_member.dart';
import 'package:drives/screens/share.dart';
import 'package:drives/utilities.dart';
// import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
//import 'package:flutter/rendering.dart';
import 'package:wakelock/wakelock.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
//import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

// import 'package:flutter_map/plugin_api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:drives/models.dart';
import 'package:drives/drives_classes.dart';
import 'package:drives/route.dart' as mt;
import 'package:drives/screens/splash_screen.dart';
import 'package:drives/services/web_helper.dart';
import 'package:drives/services/db_helper.dart';
import 'package:drives/tiles/point_of_interest_tile.dart';
import 'package:drives/tiles/message_tile.dart';
import 'package:drives/tiles/directions_tile.dart';
import 'package:drives/tiles/group_member_tile.dart';
import 'package:drives/tiles/follower_tile.dart';
import 'package:drives/tiles/maneuver_tile.dart';
import 'package:drives/tiles/home_tile.dart';
import 'package:drives/tiles/trip_tile.dart';
import 'package:drives/tiles/my_trip_tile.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:drives/screens/painters.dart';
// import 'screens/dialogs.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:image_picker/image_picker.dart';

// import 'package:reorderables/reorderables.dart';

/*
https://techblog.geekyants.com/implementing-flutter-maps-with-osm     /// Shows how to implement markers and group them
https://stackoverflow.com/questions/76090873/how-to-set-location-marker-size-depend-on-zoom-in-flutter-map      
https://pub.dev/packages/flutter_map_location_marker
https://github.com/tlserver/flutter_map_location_marker
https://www.appsdeveloperblog.com/alert-dialog-with-a-text-field-in-flutter/   /// Shows text input dialog
https://fabricesumsa2000.medium.com/openstreetmaps-osm-maps-and-flutter-daeb23f67620  /// tapableRouteLayer  
https://github.com/OwnWeb/flutter_map_tappable_Route/blob/master/lib/flutter_map_tappable_Route.dart
https://pub.dev/packages/flutter_map_animations/example  shows how to animate markers too
*/

int testInt = 0;

enum AppState {
  loading,
  home,
  download,
  createTrip,
  myTrips,
  shop,
  messages,
  driveTrip
}

enum TripState {
  none,
  manual,
  automatic,
  recording,
  stoppedRecording,
  paused,
  following,
  notFollowing,
  stoppedFollowing
}

enum TripActions {
  none,
  showGroup,
  showSteps,
  routeHighlited,
  greatRoadStart,
  saving,
  headingDetail,
  pointOfInterest,
  saved,
}

enum MessageActions { none, read, write, writing, reply, send, delete }

enum MapHeights {
  full,
  headers,
  pointOfInterest,
  message,
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Wakelock.enable();
    return const MaterialApp(
      title: 'MotaTrip trip planner',
      debugShowCheckedModeBanner: false,
      // theme: lightTheme,
      home: SplashScreen(), // MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  GlobalKey mapKey = GlobalKey();
  DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
  List<double> mapHeights = [0, 0, 0, 0];
  // List<PointOfInterest> pointsOfInterest = [];
  AppState _appState = AppState.home;
  TripState _tripState = TripState.manual;
  TripActions _tripActions = TripActions.none;
  final start = TextEditingController();
  final end = TextEditingController();
  final mapController = MapController();
  bool isVisible = false;
  PopupValue popValue = PopupValue(-1, '', '');
  final navigatorKey = GlobalKey<NavigatorState>();
  List<Marker> markers = [];
  MyTripItem _currentTrip = MyTripItem(heading: '');
  List<MyTripItem> _myTripItems = [];
  List<TripItem> tripItems = [];
  List<Message> _messages = [];
  String _message = '';
  List<Message> _filteredMessages = [];
  MessageActions _messageActions = MessageActions.read;
  List<Group> _groups = [];
  List<GroupMember> _groupMembers = [];
  List<GroupMember> _filteredGroupMembers = [];
  int id = -1;
  int userId = -1;
  // int driveId = -1;
  int type = -1;
  int _directionsIndex = 0;
  int _selectedRadio = 0;
  int _selectedGroup = -1;
  double iconSize = 35;
  double _mapRotation = 0;
  LatLng _startLatLng = const LatLng(0.00, 0.00);
  LatLng _lastLatLng = const LatLng(0.00, 0.00);
  late StreamSubscription<Position> _positionStream;
  late Future<bool> _loadedOK;
  bool _showMask = false;
  late FocusNode fn1;
  final GoodRoad _goodRoad = GoodRoad();
  // bool _goodRoad.isGood = false;
  // late CutRoute _cutRoute;
  final List<CutRoute> _cutRoutes = [];
  // List<Maneuver> _maneuvers = [];
  //int _goodRouteStartIdx = -1;
  //int _goodPointStartIdx = -1;
  // LatLng _goodNewPoi = const LatLng(0.00, 0.00);
  late ui.Size screenSize;
  late ui.Size appBarSize;
  double mapHeight = 250;
  double listHeight = 100;
  bool _showTarget = false;
  bool _showSearch = false;
  int _editPointOfInterest = -1;
  late Position _currentPosition;
  double _tripDistance = 0;
  int _resizeDelay = 0;
  double _totalDistance = 0;
  DateTime _start = DateTime.now();
  // DateTime _lastCheck = DateTime.now();
  double _speed = 0.0;
  int insertAfter = -1;
  int _poiDetailIndex = -1;
  var moveDelay = const Duration(seconds: 2);
  double _travelled = 0.0;
  // TripItem tripItem = TripItem(heading: '');
  int highlightedIndex = -1;
  List<Follower> _following = [];

  final ScrollController _scrollController = ScrollController();
  // final PointOfInterestController _pointOfInterestController =
  //     PointOfInterestController();

  final mt.RouteAtCenter _routeAtCenter = mt.RouteAtCenter();

  // final MarkerWidget _markerWidget = MarkerWidget(type: 12);

  final List<List<String>> _hints = [
    [
      'MotaTrip News',
      'Trips available to download',
      'Create new trip',
      "Trips I've recorded",
      'MotaTrip user offers',
      'Messages'
    ],
    [' - manually', ' - recording', ' - stopped', ' - paused']
  ];

  String _title = 'MotaTrip'; // _hints[0][0];

  int _bottomNavigationsBarIndex = 0;
  late AnimatedMapController _animatedMapController;

  late final StreamController<double?> _allignPositionStreamController;
  late final StreamController<void> _allignDirectionStreamController;
  // late final StreamSubscription<double?> _positionSubscription;
  late AlignOnUpdate _alignPositionOnUpdate;
  late AlignOnUpdate _alignDirectionOnUpdate;

  // final ValueNotifier<bool> _showTarget = ValueNotifier<bool>(false);

  final _dividerHeight = 35.0;

  List<LatLng> routePoints = const [LatLng(51.478815, -0.611477)];

  String images = '';

  /// Routine to add point of interest
  /// Identified as a point

  _addPointOfInterest(int id, int userId, int iconIdx, String desc, String hint,
      double size, LatLng latLng) {
    try {
      _currentTrip.addPointOfInterest(PointOfInterest(
        id,
        _currentTrip.getDriveId(),
        iconIdx,
        desc,
        hint,
        size,
        size,
        images,
        markerPoint: latLng,
        marker: MarkerWidget(
          type: iconIdx,
          angle: -_mapRotation * pi / 180, // degrees to radians
        ),
      ));
      setState(() {
        _showMask = false;
      });
    } catch (e) {
      String err = e.toString();
      debugPrint('Error: $err');
    }
  }

  _addGreatRoadStartLabel(int id, int userId, int iconIdx, String desc,
      String hint, double size, LatLng latLng) {
    int top = mapHeight ~/ 2;
    int left = MediaQuery.of(context).size.width ~/ 2;

    _currentTrip.addPointOfInterest(PointOfInterest(
      //  context,
      id,
      _currentTrip.getDriveId(),
      iconIdx,
      desc,
      hint,
      size,
      size,
      images,
      //   markerIcon(iconIdx),
      /* ValueKey(id),*/
      markerPoint: latLng,
      marker: LabelWidget(
          top: top,
          left: left,
          description: desc), // MarkerWidget(type: iconIdx),
    ));
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
          id,
          _currentTrip.getDriveId(),
          type,
          name,
          '$distance miles - ($time minutes)',
          10,
          10,
          images,
          //   markerIcon(type),
          markerPoint: latLng,
          marker: MarkerWidget(
            type: type,
            description: name,
            angle: -_mapRotation * pi / 180,
          ),
        );
        if (id == -1) {
          _currentTrip.addPointOfInterest(poi);
        } else {
          _currentTrip.insertPointOfInterest(poi, id + 1);
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
        //  throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      return name;
      // throw Exception('Failed to load data: ${e.toString()}');
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      _loadedOK = dataFromDatabase();
      tripsFromWeb();

      _title = _hints[0][0];
      // stream_controller = StreamController<int>.broadcast();
      _allignPositionStreamController = StreamController<double?>.broadcast();
      _animatedMapController = AnimatedMapController(vsync: this);
      _allignDirectionStreamController = StreamController<void>.broadcast();
      _alignPositionOnUpdate = AlignOnUpdate.never;
      _alignDirectionOnUpdate = AlignOnUpdate.never; // never;

      fn1 = FocusNode();
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
    //  if (latLng2 != const LatLng(0.00, 0.00)) {
    //    waypoint = 'waypoint;${latLng2.longitude},${latLng2.latitude}';
    //  }

    //  return await getRoutePoints(points);
    return await getRoutePoints(waypoint);
  }

  Future loadRoutes() async {
    int prior = -1;
    int next = -1;
    String waypoints = '';
    for (int i = 0; i < _currentTrip.pointsOfInterest().length; i++) {
      if (_currentTrip.pointsOfInterest()[i].type == 12) {
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
              '$waypoints${_currentTrip.pointsOfInterest()[prior].point.longitude},${_currentTrip.pointsOfInterest()[prior].point.latitude};';
          waypoints =
              '$waypoints${_currentTrip.pointsOfInterest()[next].point.longitude},${_currentTrip.pointsOfInterest()[next].point.latitude};';
        }
      }
    }
    if (waypoints != '') {
      _currentTrip.clearRoutes();
      _currentTrip.clearManeuvers();
      waypoints = waypoints.substring(0, waypoints.length - 1);
      List<LatLng> points = await getRoutes(waypoints);
      _currentTrip.addRoute(mt.Route(
          id: -1,
          points: points, // Route,
          color: _routeColour(_goodRoad.isGood),
          borderColor: _routeColour(_goodRoad.isGood),
          strokeWidth: 5));
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
      // _startLatLng = latLng2;
      return apiData;
    }
    if (_currentTrip.routes().isNotEmpty &&
        _currentTrip.routes()[_currentTrip.routes().length - 1].points.length >
            1) {
      // Let's assume simple add
      latLng1 = _currentTrip.routes()[_currentTrip.routes().length - 1].points[
          _currentTrip
                  .routes()[_currentTrip.routes().length - 1]
                  .points
                  .length -
              1];
    } else {
      latLng1 = _startLatLng;
    }
    apiData = await addRoute(latLng1, latLng2);
    _currentTrip.addRoute(mt.Route(
        id: -1,
        points: apiData["points"], // Route,
        color: _routeColour(_goodRoad.isGood),
        borderColor: _routeColour(_goodRoad.isGood),
        strokeWidth: 5));

    _currentTrip.setDistance(_currentTrip.getDistance() +
        double.parse(apiData["distance"].toString()));
    setState(() {});
    return apiData;
  }

  Future<List<LatLng>> getRoutes(String waypoints) async {
    dynamic jsonResponse;
    List<LatLng> routePoints = [];

    /// http://router.project-osrm.org/route/v1/driving/-0.515525,51.43148;-1.2577262999999999,51.7520209?steps=true&annotations=true&geometries=geojson&overview=full
    var url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$waypoints?steps=true&annotations=true&geometries=geojson&overview=full');
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
  ///
  Future<Map<String, dynamic>> getRoutePoints(String waypoints) async {
    dynamic jsonResponse;
    final Map<String, dynamic> result = {};
    List<LatLng> routePoints = [];

    /// http://router.project-osrm.org/route/v1/driving/-0.515525,51.43148;-1.2577262999999999,51.7520209?steps=true&annotations=true&geometries=geojson&overview=full
    var url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$waypoints?steps=true&annotations=true&geometries=geojson&overview=full');
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
    double distance = 0;
    double duration = 0;
    try {
      distance = jsonResponse['routes'][0]['distance'];
      duration = jsonResponse['routes'][0]['duration'];
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
            _currentTrip.addManeuver(Maneuver(
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
            ));
          } catch (e) {
            String err = e.toString();
            debugPrint(err);
          }
          if (k > 0) {
            _currentTrip.maneuvers()[k - 1].roadTo =
                _currentTrip.maneuvers()[k].roadFrom;
          }

          lastRoad = _currentTrip
              .maneuvers()[_currentTrip.maneuvers().length - 1]
              .roadTo;
          _currentTrip.maneuvers()[_currentTrip.maneuvers().length - 1].type =
              _currentTrip
                  .maneuvers()[_currentTrip.maneuvers().length - 1]
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

/*
  waypointsFromPoints(10).then((waypoints) = {getRoutePoints(waypoints});
*/

  List<Maneuver> getManeuvers() {
    List<Maneuver> maneuvers = [];

    return maneuvers;
  }

  Future<String> waypointsFromPoints(int points) async {
    List<LatLng> latLongs = [];
    for (int i = 0; i < _currentTrip.routes().length; i++) {
      latLongs = latLongs + _currentTrip.routes()[i].points;
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
    for (int i = 0; i < _currentTrip.pointsOfInterest().length; i++) {
      if (_currentTrip.pointsOfInterest()[i].type == 12) {
        waypoints =
            '$waypoints;${_currentTrip.pointsOfInterest()[i].point.longitude},${_currentTrip.pointsOfInterest()[i].point.latitude}';
      }
    }
    return waypoints.isEmpty ? waypoints : waypoints.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const MainDrawer(),
        appBar: AppBar(
          title: Text(
            _title,
            style: const TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.blue,
          //flexibleSpace: const Text('Flexible Space'),
          bottom: (_appState == AppState.createTrip ||
                      _appState == AppState.driveTrip) &&
                  _showSearch
              ? PreferredSize(
                  preferredSize: const ui.Size.fromHeight(60),
                  child: AnimatedContainer(
                      height: 60,
                      curve: Curves.easeInOut,
                      duration: const Duration(seconds: 3),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                        child: SearchLocation(
                            onSelect:
                                locationLatLng), /*SearchBar(
                    leading: Icon(Icons.search),
                  )*/
                      )))
              : null, //Text('Flexible Space')),
          actions: <Widget>[
            if (_appState == AppState.createTrip ||
                _appState == AppState.driveTrip)
              IconButton(
                icon: _showSearch
                    ? const Icon(Icons.search_off)
                    : const Icon(Icons.search),
                tooltip: 'Search',
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                  });
                },
              ),
          ],
        ),
        bottomNavigationBar: _handleBottomNavigationBar(),
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
                      child: CircularProgressIndicator()));
            }

            throw ('Error - FutureBuilder in main.dart');
          },
        ));
  }

  Future<bool> dataFromDatabase() async {
    var setupRecords = await recordCount('setup');
    var userRecords = await recordCount('users');
    var drivesRecords = await recordCount('drives');
    var polyLineRecords = await recordCount('polylines');
    var poiRecords = await recordCount('points_of_interest');

    _myTripItems = await tripItemFromDb();
    _groups = await loadGroups();
    _groupMembers = await loadGroupMembers();

    debugPrint(
        'users: $userRecords  drives: $drivesRecords  polylines: $polyLineRecords  points of interest: $poiRecords');

    // tripItemFromDb();

    // var user = alterTable();
    if (setupRecords > 0) {
      try {
        Setup().loaded;
      } catch (e) {
        debugPrint('Error starting local database: ${e.toString()}');
      }
    }
    return true;
  }

  ///

  Widget _getPortraitBody() {
    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_appState == AppState.loading) ...[
          SizedBox(
            height: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                kBottomNavigationBarHeight,
            width: MediaQuery.of(context).size.width,
            child: _showHomeTiles(), // const Text("Loading"),
          ),
        ] else if (_appState == AppState.home) ...[
          SizedBox(
            height: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                kBottomNavigationBarHeight,
            width: MediaQuery.of(context).size.width,
            child: _showHomeTiles(), // const Text("Home"),
          ),
        ] else if (_appState == AppState.download) ...[
          SizedBox(
            height: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                kBottomNavigationBarHeight,
            width: MediaQuery.of(context).size.width,
            child: _showTripTiles(),
          ),
        ] else if (_appState == AppState.messages) ...[
          AnimatedContainer(
            duration: Duration(milliseconds: _resizeDelay),
            curve: Curves.easeInOut, // fastOutSlowIn,
            height: mapHeight,
            width: MediaQuery.of(context).size.width,
            child: _showMessages(),
          ),

          _handleBottomSheetDivider(), // grab rail - GesureDetector()
          const SizedBox(
            height: 5,
          ),
          _handleMessages(), // Allows the trip to be planned
        ] else if (_appState == AppState.createTrip ||
            _appState == AppState.driveTrip) ...[
          AnimatedContainer(
            duration: Duration(milliseconds: _resizeDelay),
            curve: Curves.easeInOut, // fastOutSlowIn,
            height: mapHeight,
            width: MediaQuery.of(context).size.width,
            child: _handleMap(),
          ),

          _handleBottomSheetDivider(), // grab rail - GesureDetector()
          const SizedBox(
            height: 5,
          ),
          _handleTripInfo(), // Allows the trip to be planned
        ] else if (_appState == AppState.myTrips) ...[
          SizedBox(
            height: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                kBottomNavigationBarHeight,
            width: MediaQuery.of(context).size.width,
            child: _showMyTripTiles(_myTripItems),
          ),
        ] else if (_appState == AppState.shop) ...[
          SizedBox(
            height: mapHeight,
            width: MediaQuery.of(context).size.width,
            child: const Text("Shop"),
          ),
        ]
      ],
    ));
  }

  addWaypoint() async {
    LatLng pos = _animatedMapController.mapController.camera.center;
    Map<String, dynamic> data;
    if (insertAfter == -1 &&
        _currentTrip.pointsOfInterest().isNotEmpty &&
        _currentTrip.pointsOfInterest()[0].type == 12) {
      data = await appendRoute(pos);
      await _addPointOfInterest(
          id, userId, 12, '${data["name"]}', '${data["summary"]}', 15.0, pos);
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
      await _addPointOfInterest(
          id, userId, 12, '${data["name"]}', '${data["summary"]}', 15.0, pos);
      setState(() {
        _showMask = false;
        _startLatLng = pos;
      });

      _currentTrip.setDistance(_currentTrip.getDistance() +
          double.parse(data['distance'].toString()));
    }
  }

  detailClose() {
    debugPrint('resetting _poiDetailIndex');
    if (_poiDetailIndex > -1) {
      _poiDetailIndex = -1;
      setState(() {});
    }
  }

  List<String> getTitles(int i) {
    List<String> result = [];
    if (_currentTrip.pointsOfInterest()[i].type < 12) {
      result.add(_currentTrip.pointsOfInterest()[i].description == ''
          ? 'Point of interest - ${poiTypes[_currentTrip.pointsOfInterest()[i].type]["name"]}'
          : _currentTrip.pointsOfInterest()[i].description);
      result.add(_currentTrip.pointsOfInterest()[i].description);
    } else {
      result.add(
          'Waypoint ${i + 1} -  ${_currentTrip.pointsOfInterest()[i].name}');
      result.add(_currentTrip.pointsOfInterest()[i].description);
    }
    return result;
  }

  pointOfInterestRemove(int idx) async {
    /// Removing a poi:
    _currentTrip.removePointOfInterestAt(idx);
    loadRoutes();
    setState(() {});
  }

  NavigationBar _handleBottomNavigationBar() {
    return NavigationBar(
      height: 60,
      surfaceTintColor: Colors.blue,
      onDestinationSelected: (int index) {
        setState(() {
          _bottomNavigationsBarIndex = index;
          _title = _hints[0][index];
          switch (index) {
            case 0:
              //  home
              _appState = AppState.home;

              break;
            case 1:
              // Web routes
              _appState = AppState.download;
              tripsFromWeb();
              break;
            case 2:
              // Create route
              _appState = AppState.createTrip;
              _showMask = false;

              if (_currentTrip.pointsOfInterest().isEmpty) {
                _tripState = TripState.none;
                _showTarget = false;
                _tripActions = TripActions.headingDetail;
                mapHeight = MediaQuery.of(context).size.height - 190;
              }
              break;
            case 3:
              // My routes
              _appState = AppState.myTrips;
              break;
            case 4:
              _appState = AppState.shop;
            case 5:
              // // Messages
              loadGroups()
                  .then((v) => _groups = v)
                  .then((_) => loadGroupMembers())
                  .then((v) => _groupMembers = v)
                  .then((_) => _getMessages())
                  .then((_) => setState(() {
                        _appState = AppState.messages;
                        adjustMapHeight(MapHeights.full);
                      }));

              break;
          }
        });
      },
      indicatorColor: Colors.lightBlue,
      selectedIndex: _bottomNavigationsBarIndex,
      destinations: <Widget>[
        const NavigationDestination(
          selectedIcon: Icon(
            Icons.home,
          ),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        const NavigationDestination(
          selectedIcon: Icon(Icons.route),
          icon: Icon(Icons.route_outlined),
          label: 'Trips',
        ),
        const NavigationDestination(
          selectedIcon: Icon(
            Icons.map,
          ),
          icon: Icon(Icons.map_outlined),
          label: 'Create Trip',
        ),
        const NavigationDestination(
          selectedIcon: Icon(Icons.person),
          icon: Icon(Icons.person_outlined),
          label: 'My Trips',
        ),
        const NavigationDestination(
          selectedIcon: Icon(
            Icons.storefront,
          ),
          icon: Icon(Icons.storefront_outlined),
          label: 'Shop',
        ),
        NavigationDestination(
          icon: Badge(
            label: _messages.isEmpty ? null : Text(_messages.length.toString()),
            child: const Icon(Icons.messenger_outlined),
          ),
          selectedIcon: Badge(
            label: _messages.isEmpty ? null : Text(_messages.length.toString()),
            child: const Icon(Icons.messenger),
          ),
          label: 'Messages',
        ),
      ],
    );
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
          if ([AppState.createTrip, AppState.driveTrip].contains(_appState) &&
              !_showSearch) ...[
            const SizedBox(
              height: 175,
            ),
            if ([TripState.recording, TripState.following]
                    .contains(_tripState) &&
                _speed > 0.01) ...[
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue,
                child: Text('${_speed.truncate()}',
                    style: const TextStyle(fontSize: 20)),
              ),
            ],
            const SizedBox(
              height: 10,
            ),
            if (_tripState == TripState.recording) ...[
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    //  _showTarget = !_showTarget;
                    _goodRoad.isGood = _goodRoad.isGood ? false : true;
                    _currentTrip.addRoute(mt.Route(
                        id: -1,
                        points: [
                          LatLng(_currentPosition.latitude,
                              _currentPosition.longitude)
                        ],
                        borderColor: uiColours.keys.toList()[_goodRoad.isGood
                            ? Setup().goodRouteColour
                            : Setup().routeColour],
                        color: uiColours.keys.toList()[_goodRoad.isGood
                            ? Setup().goodRouteColour
                            : Setup().routeColour],
                        strokeWidth: 5));
                  });
                },
                backgroundColor: _goodRoad.isGood
                    ? uiColours.keys.toList()[Setup().goodRouteColour]
                    : Colors.blue,
                shape: const CircleBorder(),
                child:
                    Icon(_goodRoad.isGood ? Icons.remove_road : Icons.add_road),
              )
            ],
            const SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              onPressed: () async {
                _currentPosition = await Geolocator.getCurrentPosition();
                debugPrint('Position: ${_currentPosition.toString()}');
                _animatedMapController.animateTo(
                    dest: LatLng(
                        _currentPosition.latitude, _currentPosition.longitude));
                setState(() {
                  //  _showTarget = !_showTarget;
                });
              },
              backgroundColor: Colors.blue,
              shape: const CircleBorder(),
              child: const Icon(Icons.my_location),
            ),
            //  ]),
          ]
        ]);
  }

  ///
  /// handlMap()
  /// does all the map UI
  /// Wrapped in a RepaintBoundary so that a screenshot of the map can be saved for the Route description
  ///

  Widget _handleMap() {
    return RepaintBoundary(
        key: mapKey,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _animatedMapController.mapController,
              options: MapOptions(
                onMapEvent: checkMapEvent,
                onMapReady: () {
                  mapController.mapEventStream.listen((event) {});
                },
                onPositionChanged: (position, hasGesure) {
                  if (_tripState == TripState.manual) {
                    _tripActions = TripActions.none;
                    int routeIdx = _routeAtCenter.getPolyLineNearestCenter();
                    // if (routeIdx > -1) {
                    for (int i = 0; i < _currentTrip.routes().length; i++) {
                      //  _currentTrip.routes()[i].borderColor = _currentTrip.routes()[i].color;
                      if (i == routeIdx) {
                        _tripActions = TripActions.routeHighlited;
                        _currentTrip.routes()[i].color =
                            uiColours.keys.toList()[Setup().selectedColour];
                      } else {
                        _currentTrip.routes()[i].color =
                            _currentTrip.routes()[i].borderColor;
                      }
                    }

                    highlightedIndex = routeIdx;
                  } else {
                    //      updateTracking();
                  }
                  if (hasGesure) {
                    _updateMarkerSize(position.zoom ?? 13.0);
                  }
                  _mapRotation =
                      _animatedMapController.mapController.camera.rotation;
                },
                initialCenter: routePoints[0],
                initialZoom: 15,
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
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                  maxZoom: 18,
                ),
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
                  polylineCulling: false, //true,
                  polylines: _currentTrip.routes(),
                  onTap: routeTapped,
                  onMiss: routeMissed,
                  routeAtCenter: _routeAtCenter,
                ),
                MarkerLayer(markers: _currentTrip.pointsOfInterest()),
                MarkerLayer(markers: _following),
              ],
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Wrap(
                    spacing: 5,
                    children: getChips(),
                  )),
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
        ));
  }

  Align getDirections(int index) {
    if (index >= 0 &&
        _tripState == TripState.following &&
        _currentTrip.maneuvers().isNotEmpty) {
      return Align(
          alignment: Alignment.topLeft,
          child: DirectionTile(
            direction: _currentTrip.maneuvers()[index],
            index: index,
            directions: _currentTrip.maneuvers().length,
          ));
    } else {
      return const Align(
        alignment: Alignment.topLeft,
      );
    }
  }

  dismissKeyboard() {
    if (WidgetsBinding
            .instance.platformDispatcher.views.first.viewInsets.bottom >
        0) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  List<ActionChip> getChips() {
    List<String> chipNames = [];
    List<ActionChip> chips = [];
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
      tripData,
      back,
      writeMessage,
      readMessages,
      reply,
      send,
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
      Icons.map,
      Icons.arrow_back,
      Icons.add_comment,
      Icons.mark_chat_read,
      Icons.quickreply,
      Icons.send
    ];
    if (_appState == AppState.messages) {
      if ([MessageActions.none, MessageActions.read]
          .contains(_messageActions)) {
        chipNames.add('Write message');
      }
      if ([MessageActions.none, MessageActions.write]
          .contains(_messageActions)) {
        chipNames.add('Read messages');
      }
      if (_messageActions == MessageActions.writing) {
        chipNames
          ..add('Send')
          ..add('Read messages');
      }
    } else {
      if ([TripActions.saving, TripActions.saved].contains(_tripActions)) {
        _tripActions = TripActions.saved;
        return chips;
      }
      if (_tripState == TripState.none) {
        chipNames
          ..add('Create manually')
          ..add('Track drive');
      }
      if (_tripState == TripState.manual) {
        chipNames
          ..add('Waypoint')
          ..add('Point of interest')
          ..add('Great road');
      }

      if (_tripState == TripState.manual &&
          _currentTrip.pointsOfInterest().isEmpty) {
        chipNames.add('Back');
      }

      if ([TripState.automatic, TripState.stoppedRecording, TripState.paused]
          .contains(_tripState)) {
        chipNames
          ..add('Start recording')
          ..add('Back');
      }
      if (_tripState == TripState.recording) {
        chipNames
          ..add('Stop recording')
          ..add('Pause recording');
      }
      if (_currentTrip.pointsOfInterest().isNotEmpty &&
          [TripState.manual, TripState.stoppedRecording].contains(_tripState)) {
        chipNames
          ..add('Save trip')
          ..add('Clear trip');
      }
      if (_tripActions == TripActions.routeHighlited) {
        chipNames
          ..add('Split route')
          ..add('Remove section');
      }
      if (_tripActions == TripActions.greatRoadStart) {
        chipNames.add('Great road end');
      }

      if ([TripState.stoppedFollowing, TripState.notFollowing]
          .contains(_tripState)) {
        chipNames.add('Follow route');
      }
      if (_tripState == TripState.following) {
        chipNames.add('Stop following');
      }
      if ([
        TripState.following,
        TripState.stoppedFollowing,
        TripState.notFollowing
      ].contains(_tripState)) {
        if (_tripActions == TripActions.showGroup) {
          chipNames.add('Trip info');
        } else {
          chipNames.add('Group');
        }
        if (_tripActions == TripActions.showSteps) {
          chipNames.add('Trip info');
        } else {
          chipNames.add('Steps');
        }
        if (_tripState != TripState.following) {
          chipNames
            ..add('Edit route')
            //    ..add('Clear trip')
            ..add('Back');
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

  void addManually() {
    setState(() {
      _showMask = false;
      _showTarget = true;
      _alignPositionOnUpdate = AlignOnUpdate.never;
      _alignDirectionOnUpdate = AlignOnUpdate.never;
      _tripState = TripState.manual;
      _tripActions = TripActions.headingDetail;
      adjustMapHeight(MapHeights.headers);
    });
  }

  void addAutomatically() {
    setState(() {
      _showMask = false;
      _showTarget = false;
      _tripState = TripState.automatic;
      _tripActions = TripActions.headingDetail;
      adjustMapHeight(MapHeights.headers);
    });
  }

  void waypoint() async {
    _goodRoad.isGood = false;
    setState(() {
      _showMask = true;
      _tripActions = TripActions.none;
      _editPointOfInterest = -1;
      // _poiDetailIndex = -1;
      if (_currentTrip.pointsOfInterest().isEmpty) {
        adjustMapHeight(MapHeights.full);
        _currentTrip.clearRoutes();
        _currentTrip.clearManeuvers();
      }
    });
    await addWaypoint();
  }

  void pointOfInterest() async {
    _showMask = true;
    LatLng pos = _animatedMapController.mapController.camera.center;
    String name = await getPoiName(latLng: pos, name: 'Point of interest');
    await _addPointOfInterest(id, userId, 15, name, '', 30.0, pos);
    setState(() {
      try {
        //  tripItem.pointsOfInterest += 1;
      } catch (e) {
        debugPrint(e.toString());
      }
      _showMask = false;
      _tripActions = TripActions.pointOfInterest;
      _editPointOfInterest = _currentTrip.pointsOfInterest().length - 1;
      adjustMapHeight(MapHeights.pointOfInterest);
    });
  }

  void greatRoad() async {
    String txt =
        'Great road start'; //_goodRoad.isGood ? 'Great road start' : 'Great road end';
    LatLng pos = _animatedMapController.mapController.camera.center;
    _addGreatRoadStartLabel(id, userId, 13, txt, '', 80, pos).then(() {
      setState(() {
        _tripActions = TripActions.greatRoadStart;
        _cutRoutes.clear();
        _splitRoute();
        _goodRoad.isGood = true;
      });
    });
  }

  void startRecording() async {
    _alignDirectionOnUpdate =
        Setup().rotateMap ? AlignOnUpdate.always : AlignOnUpdate.never;
    _alignPositionOnUpdate = AlignOnUpdate.always;

    if (_currentTrip.pointsOfInterest().isEmpty) {
      _currentTrip.clearRoutes();
    }

    Geolocator.getCurrentPosition().then((pos) {
      _currentPosition = pos;
      getPoiName(
              latLng: LatLng(pos.latitude, pos.longitude), name: 'Trip start')
          .then((name) {
        _addPointOfInterest(id, userId, 9, name, 'Trip start', 20.0,
            LatLng(pos.latitude, pos.longitude));
      });
    });
    getLocationUpdates();
    _tripState = TripState.recording;
    _tripState = TripState.recording;
    setState(() {});
  }

  void stopRecording() async {
    _positionStream.cancel();
    _tripState = TripState.stoppedRecording;
    _alignDirectionOnUpdate = AlignOnUpdate.never;
    _alignPositionOnUpdate = AlignOnUpdate.never;
    _tripState = TripState.stoppedRecording;
    if (_currentTrip.routes().isNotEmpty) {
      final LatLng pos =
          LatLng(_currentPosition.latitude, _currentPosition.longitude);
      await getPoiName(latLng: pos, name: 'Trip end').then((name) {
        _addPointOfInterest(id, userId, 10, name, 'Trip end', 20.0, pos);
      });
    }
    setState(() {});
  }

  void pauseRecording() {
    setState(() {
      _trackingState(trackingOn: false);
      _tripState = TripState.paused;
    });
  }

  void saveTrip() async {
    setState(() {
      _tripActions = TripActions.saving;
      adjustMapHeight(MapHeights.full);
    });
    int tries = 0;
    while (_tripActions != TripActions.saved && tries < 5) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {});
      tries++;
    }

    if (_tripActions != TripActions.saved) {
      debugPrint('Failed');
    } else {
      debugPrint('Succeded');
      try {
        ui.Image mapImage = await getMapImage();
        _tripActions = TripActions.none;
        _currentTrip.setImage(mapImage);
        _saveTrip();
      } catch (e) {
        String err = e.toString();
        debugPrint('Error: $err');
      }
    }
  }
  // _saveTrip();

  void clearTrip() {
    setState(() {
      _currentTrip = MyTripItem(heading: '');
      _tripState = TripState.none;
    });
  }

  void splitRoute() async {
    _showTarget = true;

    int idx = insertWayointAt(
        pointsOfInterest: _currentTrip.pointsOfInterest(),
        pointToFind: _routeAtCenter.pointOnRoute);

    await _singlePointOfInterest(
            context, _animatedMapController.mapController.camera.center, idx,
            refresh: false)
        .then((res) {
      try {
        debugPrint('Result : ${res.toString()}');
        _cutRoutes.clear();
        _splitRoute();
      } catch (e) {
        debugPrint('Error splitting route: ${e.toString()}');
      }
      setState(() {
        _tripActions = TripActions.routeHighlited;
      });
    });
  }

  void removeSection() async {
    _showTarget = true;
    LatLng pos = _animatedMapController.mapController.camera.center;
    await getPoiName(latLng: pos, name: 'Point of interest').then((name) {
      _addPointOfInterest(id, userId, 15, name, '', 30.0, pos);
    });
    setState(() {});
  }

  void greatRoadEnd() async {
    _goodRoad.isGood = false;
    if (_currentTrip.pointsOfInterest().isEmpty) {
      _currentTrip.clearRoutes();
      _currentTrip.clearManeuvers();
    }
    await addWaypoint().then((_) => setState(() {
          _tripActions = TripActions.none;
        }));
  }

  void followRoute() async {
    Geolocator.getCurrentPosition().then((val) {
      getLocationUpdates();
      setState(() {
        _tripActions = TripActions.none;
        _currentPosition = val;
        _tripState = TripState.following;
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

  void stopFollowing() async {
    setState(() {
      _alignPositionOnUpdate = AlignOnUpdate.never;
      _alignDirectionOnUpdate = AlignOnUpdate.never;
      _tripState = TripState.stoppedFollowing;
    });
  }

  void steps() {
    setState(() {
      _tripActions = TripActions.showSteps;
      adjustMapHeight(MapHeights.headers);
    });
  }

  void tripData() {
    setState(() {
      _tripActions = TripActions.none;
      adjustMapHeight(MapHeights.full);
    });
  }

  void back() {
    setState(() {
      if ([TripState.stoppedFollowing, TripState.notFollowing]
          .contains(_tripState)) {
        if (_currentTrip.getId() < 0 && _currentTrip.getDriveUri().isNotEmpty) {
          _appState = AppState.download;
          _bottomNavigationsBarIndex = 1;
        } else {
          _appState = AppState.myTrips;

          _bottomNavigationsBarIndex = 3;
        }
        clearTrip();
      }
      _tripState = TripState.none;
      _tripActions = TripActions.none;
      _showTarget = false;
      adjustMapHeight(MapHeights.full);
    });
  }

  void group() async {
    setState(() {
      _tripActions = TripActions.showGroup;
      adjustMapHeight(MapHeights.headers);
    });
    _following.clear();
    _following.add(Follower(
      id: -1,
      driveId: _currentTrip.getDriveId(),
      forename: 'James',
      surname: 'Seddon',
      phoneNumber: '07761632236',
      car: 'Avion',
      registration: 'K223RPF',
      iconColour: 3,
      position: const LatLng(51.470503, -0.59637), // 51.459024 -0.580205
      marker: MarkerWidget(
        type: 16,
        description: '',
        angle: -_mapRotation * pi / 180,
        colourIdx: 3,
      ),
    ));
    _following.add(Follower(
      id: -1,
      driveId: _currentTrip.getDriveId(),
      forename: 'Frank',
      surname: 'Seddon',
      phoneNumber: '07761632236',
      car: 'Morgan',
      registration: 'K223RPF',
      iconColour: 4,
      position: const LatLng(51.459024, -0.580205), // 51.459024 -0.580205
      marker: MarkerWidget(
        type: 16,
        description: '',
        angle: -_mapRotation * pi / 180,
        colourIdx: 4,
      ),
    ));
  }

  void editRoute() async {
    setState(() {
      _showTarget = true;
      _tripActions = TripActions.none;
      _appState = AppState.createTrip;
      _tripState = TripState.manual;
      _bottomNavigationsBarIndex = 2;
    });
  }

  void writeMessage() {
    setState(() {
      _title = 'Write message';
      if (_messageActions == MessageActions.writing) {
        adjustMapHeight(MapHeights.headers);
        fn1.requestFocus();
      }
      _messageActions = MessageActions.write;
    });
  }

  void readMessages() {
    setState(() {
      _title = 'Read messages';
      adjustMapHeight(MapHeights.full);
      fn1.unfocus();
      _messageActions = MessageActions.read;
    });
  }

  void reply() {
    setState(() {
      adjustMapHeight(MapHeights.headers);
      _messageActions = MessageActions.reply;
    });
  }

  void send() {
    setState(() {
      for (int i = 0; i < _groupMembers.length; i++) {
        if (_groupMembers[i].selected) {
          Message message = Message(
            id: -1,
            groupMember: _groupMembers[i],
            message: _message,
          );
          saveMessage(message);
        }
        adjustMapHeight(MapHeights.full);
        fn1.unfocus();
      }
    });
  }

  /// _splitR
  /// oute() splits a route putting the two split parts contiguously in _currentTrip.routes array
  /// if being used to split a goodRoad then on the 2nd split it sets the colour and borderColour
  /// for the affected routes and returns the LatNng for the goodRoad marker point

  Future<LatLng> _splitRoute() async {
    LatLng result = const LatLng(0, 0);
    try {
      int newRouteIdx = 0;
      mt.Route newRoute = mt.Route(
          id: -1,
          points: [],
          color: _routeColour(false),
          borderColor: _routeColour(false),
          strokeWidth: 5);

      if (_routeAtCenter.routeIndex < _currentTrip.routes().length - 1) {
        _currentTrip.insertRoute(newRoute, _routeAtCenter.routeIndex + 1);
        newRouteIdx = _routeAtCenter.routeIndex + 1;
      } else {
        _currentTrip.addRoute(newRoute);
        newRouteIdx = _currentTrip.routes().length - 1;
      }
      for (int i = _routeAtCenter.pointIndex;
          i < _currentTrip.routes()[_routeAtCenter.routeIndex].points.length;
          i++) {
        _currentTrip.routes()[newRouteIdx].points.add(_currentTrip
            .routes()[_routeAtCenter.routeIndex]
            .points
            .removeAt(i));
        if (_currentTrip.routes()[newRouteIdx].points.length > 1 &&
            i <
                _currentTrip
                    .routes()[_routeAtCenter.routeIndex]
                    .offsets
                    .length) {
          _currentTrip.routes()[newRouteIdx].offsets.add(_currentTrip
              .routes()[_routeAtCenter.routeIndex]
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
        /// roots are held in array _currentTrip.routes
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
            _currentTrip.routes()[i].color = _routeColour(true);
            _currentTrip.routes()[i].borderColor = _routeColour(true);
            for (int j = 0; j < _currentTrip.routes()[i].points.length; j++) {
              goodPoints.add(_currentTrip.routes()[i].points[j]);
            }
          }

          /// 2) X == b     2nd bit of b is
        } else if (_goodRoad.routeIdx2 == _goodRoad.routeIdx1) {
          _currentTrip.routes()[_goodRoad.routeIdx2 + 1].color =
              _routeColour(true);
          _currentTrip.routes()[_goodRoad.routeIdx2 + 1].borderColor =
              _routeColour(true);
          for (int j = 0;
              j < _currentTrip.routes()[_goodRoad.routeIdx2 + 1].points.length;
              j++) {
            goodPoints
                .add(_currentTrip.routes()[_goodRoad.routeIdx2 + 1].points[j]);
          }

          /// 3) X == b+1   1st bit of b2 is good
        } else if (_goodRoad.routeIdx2 == _goodRoad.routeIdx1 + 1) {
          _currentTrip.routes()[_goodRoad.routeIdx2].color = _routeColour(true);
          _currentTrip.routes()[_goodRoad.routeIdx2].borderColor =
              _routeColour(true);
          for (int j = 0;
              j < _currentTrip.routes()[_goodRoad.routeIdx2].points.length;
              j++) {
            goodPoints
                .add(_currentTrip.routes()[_goodRoad.routeIdx2].points[j]);
          }

          /// 4) X > b+1    all from b2 to c are good
        } else if (_goodRoad.routeIdx2 > _goodRoad.routeIdx1) {
          for (int i = _goodRoad.routeIdx1 + 1; i < _goodRoad.routeIdx2; i++) {
            _currentTrip.routes()[i].color = _routeColour(true);
            _currentTrip.routes()[i].borderColor = _routeColour(true);
            for (int j = 0; j < _currentTrip.routes()[i].points.length; j++) {
              goodPoints.add(_currentTrip.routes()[i].points[j]);
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

  Widget _handleTripInfo() {
    switch (_tripActions) {
      case TripActions.showGroup:
        return _showGroup();
      case TripActions.showSteps:
        return _showManeuvers();
      case TripActions.headingDetail:
        return _exploreDetailsHeader();
      default:
        return _showExploreDetail();
    }
  }

  Widget _handleMessages() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(children: [
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Row(children: [
                Text(
                  'Enter your message:',
                  textAlign: TextAlign.left,
                )
              ])),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: TextFormField(
                autofocus: false,
                focusNode: fn1,
                autocorrect: false,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                minLines: 5,
                maxLines: 20,
                onChanged: (val) {
                  _message = val;
                  //         if (_messageActions != MessageActions.writing) {
                  //           setState(() => _messageActions = MessageActions.writing);
                  //         }
                },
                onFieldSubmitted: (val) => _message = val,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(width: 1),
                  ),
                ),
              )),
        ]));
  }

  Widget _filterMessages() {
    int chosen = 0;
    List<String> groupNames = ['All members'];
    /*
    if (_groups.isEmpty) {
      _groups.add(Group(id: -1, name: 'Old Farts'));
      _groups.add(Group(id: -1, name: 'Outlaws'));
    }
    */
    for (int i = 0; i < _groups.length; i++) {
      groupNames.add(_groups[i].name);
    }

    return Column(children: [
      Row(children: [
        Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Group name',
              ),
              value: groupNames[chosen],
              items: groupNames
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!), // bodyLarge!),
                      ))
                  .toList(),
              onChanged: (item) => {
                setState(() {
                  _selectedGroup = groupNames.indexOf(item!) - 1;
                  if ([MessageActions.read, MessageActions.none]
                      .contains(_messageActions)) {
                    _filteredMessages = filterMessages(_selectedRadio);
                  } else {
                    _filteredGroupMembers = filterGroupMembers();
                  }
                })
              },
            )),
        if ([MessageActions.read, MessageActions.none]
            .contains(_messageActions)) ...[
          Expanded(
              flex: 1,
              child: ButtonBar(
                alignment: MainAxisAlignment.center,
                children: <Widget>[
                  Column(children: [
                    const Text('All'),
                    Radio(
                      value: 0,
                      groupValue: _selectedRadio,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        setState(() {
                          _selectedRadio = 0;
                          _filteredMessages = filterMessages(_selectedRadio);
                        });
                        debugPrint("Radio $val");
                        //    set_selectedRadio(val);
                      },
                    ),
                  ]),
                  Column(children: [
                    const Text('Read'),
                    Radio(
                      value: 1,
                      groupValue: _selectedRadio,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        setState(() {
                          _selectedRadio = 1;
                          _filteredMessages = filterMessages(_selectedRadio);
                        });
                        debugPrint("Radio $val");
                        // set_selectedRadio(val);
                      },
                    )
                  ]),
                  Column(children: [
                    const Text('Unread'),
                    Radio(
                      value: 2,
                      groupValue: _selectedRadio,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        setState(() {
                          _selectedRadio = 2;
                          _filteredMessages = filterMessages(_selectedRadio);
                        });
                        debugPrint("Radio $val");
                        //    set_selectedRadio(val);
                      },
                    ),
                  ]),
                ],
              ))
        ] else ...[
          const Expanded(flex: 1, child: SizedBox())
        ]
      ]),
    ]);
  }

  List<Message> filterMessages(int type) {
    List<Message> messages = [];
    try {
      for (int i = 0; i < _messages.length; i++) {
        bool stateOk = type == 0 ||
            (_messages[i].read && type == 1) ||
            (!_messages[i].read && type == 2);
        if (_messages[i].groupMember.groupIds.isEmpty || _selectedGroup < 0) {
          if (stateOk) {
            _messages[i].groupMember.index = i;
            messages.add(_messages[i]);
          }
        } else {
          var groupIds = jsonDecode(_messages[i].groupMember.groupIds);
          for (int j = 0; j < groupIds.length; j++) {
            if (groupIds[j]['groupId'] == _groups[_selectedGroup].id &&
                stateOk) {
              _messages[i].groupMember.index = i;
              messages.add(_messages[i]);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing messages: ${e.toString()}');
      messages = _messages;
    }
    // setState(() {});
    return messages;
  }

  List<GroupMember> filterGroupMembers() {
    List<GroupMember> members = [];
    try {
      for (int i = 0; i < _groupMembers.length; i++) {
        if (_groupMembers[i].groupIds.isEmpty || _selectedGroup < 0) {
          _groupMembers[i].index = i;
          members.add(_groupMembers[i]);
        } else {
          var groupIds = jsonDecode(_groupMembers[i].groupIds);
          for (int j = 0; j < groupIds.length; j++) {
            if (groupIds[j]['groupId'] == _groups[_selectedGroup].id) {
              _groupMembers[i].index = i;
              members.add(_groupMembers[i]);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing messages: ${e.toString()}');
      members = _groupMembers;
    }
    // setState(() {});
    return members;
  }

  void onEditMember(int index) async {
    GroupMember member;
    int parentIndex;
    if ([MessageActions.write, MessageActions.writing]
        .contains(_messageActions)) {
      parentIndex = _filteredGroupMembers[index].index;
      member = _groupMembers[parentIndex];
    } else {
      parentIndex = _filteredMessages[index].index;
      member = _messages[parentIndex].groupMember;
    }
    String groupName = 'None';
    if (member.groupIds.isNotEmpty) {
      var groupIds = jsonDecode(member.groupIds);
      for (int j = 0; j < _groups.length; j++) {
        if (groupIds[0]['groupId'] == _groups[j].id) {
          groupName = _groups[j].name;
          break;
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GroupMemberForm(
                groupMember: member,
                groupName: groupName,
                groups: _groups,
              )),
    ).then((value) {
      setState(() {
        /// if deleted in GroupMemberForm filteredGroupMembers[index].index is set to -1
        /*     if (_messages[_filteredMessages[index].index].groupMember.index == -1) {
          _groupMembers.removeAt(parentIndex);
        } else if (_filteredMessages[index].groupMember.forename.isEmpty &&
            _filteredMessages[index].groupMember.surname.isEmpty) {
          Utility().showConfirmDialog(context, "Missing information",
              "Records without a forename and surname can't be saved");
          _groupMembers.removeAt(_filteredMessages[index].groupMember.index);
        }
  */
        filterMessages(type);
      });
    });
    return;
  }

  void onSelectMember(int index) {
    if (_messageActions != MessageActions.writing) {
      setState(() {
        _messageActions = MessageActions.writing;
        debugPrint('Selected : $index');
      });
    } else if (!_filteredGroupMembers[index].selected) {
      setState(() {
        adjustMapHeight(MapHeights.message);
        fn1.requestFocus();
      });
    }
  }

  /// _handleBottomSheetDivider()
  /// Handles the grab icion to separate the map from the bottom sheet

  _handleBottomSheetDivider() {
    _resizeDelay = 0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: AbsorbPointer(
          child: Container(
        // margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        color: const Color.fromARGB(255, 158, 158, 158),
        height: _dividerHeight,
        width: MediaQuery.of(context).size.width,
        //  padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
        child: Icon(
          Icons.drag_handle,
          size: _dividerHeight,
          color: Colors.blue,
        ),
      )),
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
      //     onTap: adjustMapHeight(
      //        mapHeight == MapHeights.full ? MapHeights.headers : MapHeights.full),
    ); //);
  }

  SizedBox _showGroup() {
    // List<Follower> sortedFollowing = _following
    //   ..sort((item1, item2) => item2.compareTo(item1));
    return SizedBox(
        height: listHeight,
        child: ListView.builder(
            itemCount: _following.length,
            itemBuilder: (context, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: FollowerTile(
                  follower: _following[index],
                  index: index,
                  onIconClick: followerIconClick,
                  onLongPress: followerLongPress,
                  distance: 0, // ToDo: calculate how far away
                ))));
  }

  SizedBox _showManeuvers() {
    return SizedBox(
        height: listHeight,
        child: ListView.builder(
            itemCount: _currentTrip.maneuvers().length,
            itemBuilder: (context, index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: ManeuverTile(
                    index: index,
                    maneuver: _currentTrip.maneuvers()[index],
                    maneuvers: _currentTrip.maneuvers().length,
                    onLongPress: maneuverLongPress,
                    distance: 0))));
  }

  void maneuverLongPress(int index) {
    _showTarget = true;
    _animatedMapController.animateTo(
        dest: _currentTrip.maneuvers()[index].location);
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
    await messageGroup(index);
    return;
  }

  Future<void> messageGroup(int index) async {
    List<String> choices = [
      'All OK',
      'Stopping for fuel',
      'Stopping for food',
      'Mechanical problem',
      'Stopping for a break',
      'Stuck in traffic'
    ];
    String chosen;
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
              child: Column(children: [
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
                              .map((item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!),
                                  ))
                              .toList(),
                          onChanged: (item) =>
                              setState(() => chosen = item.toString()),
                        )),
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
                                ))),
                      ),
                      //  Text('Text'),
                    ],
                  )
                ]
              ])),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Send'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return;
  }

  void followerLongPress(int index) {
    _showTarget = true;
    _animatedMapController.animateTo(dest: _following[index].point);
    return;
  }

  SizedBox _showExploreDetail() {
    return SizedBox(
        height: listHeight,
        child: CustomScrollView(controller: _scrollController, slivers: [
          if (_editPointOfInterest < 0) ...[
            SliverToBoxAdapter(
              child: _exploreDetailsHeader(),
            ),
            //      if (_editPointOfInterest <
            //          0) // && _currentTrip.pointsOfInterest()[index].type != 12)
            SliverReorderableList(
                itemBuilder: (context, index) {
                  //   debugPrint('Index: $index');
                  if (_currentTrip.pointsOfInterest()[index].type != 16) {
                    // filter out followers
                    return _currentTrip.pointsOfInterest()[index].type == 12
                        ? waypointTile(index)
                        : PointOfInterestTile(
                            key: ValueKey(index),
                            //   pointOfInterestController:
                            // _pointOfInterestController,
                            index: index,
                            pointOfInterest:
                                _currentTrip.pointsOfInterest()[index],
                            onExpandChange: expandChange,
                            onIconTap: iconButtonTapped,
                            onDelete: removePointOfInterest,
                            onRated: onPointOfInterestRatingChanged,
                            canEdit: _appState != AppState.driveTrip,
                          ); //   pointOfInterestTile(index);
                  } else {
                    return SizedBox(
                      key: ValueKey(index),
                      height: 1,
                    );
                  }
                },
                itemCount: _currentTrip.pointsOfInterest().length,
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex = -1;
                    }
                    _currentTrip.movePointOfInterest(oldIndex, newIndex);
                  });
                })
          ],
          if (_editPointOfInterest > -1) ...[
            SliverToBoxAdapter(
                child: PointOfInterestTile(
              key: ValueKey(_editPointOfInterest),
              //  pointOfInterestController: _pointOfInterestController,
              index: _editPointOfInterest,
              pointOfInterest:
                  _currentTrip.pointsOfInterest()[_editPointOfInterest],
              onExpandChange: expandChange,
              onIconTap: iconButtonTapped,
              onDelete: removePointOfInterest,
              onRated: onPointOfInterestRatingChanged,
              expanded: true,
              canEdit: _appState != AppState.driveTrip,
            ))
          ] //     iconButtonTapped  expandChange      pointOfInterestTile(_editPointOfInterest)),
        ]));
  }

  void _scrollDown() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2), curve: Curves.fastOutSlowIn);
  }

  Widget _showHomeTiles() {
    List<HomeItem> homeItems = [];
    homeItems.add(HomeItem(
        heading: 'New trip planning app',
        subHeading: 'Stop polishing your car and start driving it...',
        body:
            '''MotaTrip is a new app to help you make the most of the countryside around you. 
You can plan trips either on your own or you can explore in a group''',
        imageUrl: 'assets/images/splash.png'));

    homeItems.add(HomeItem(
        heading: 'Share your trips',
        subHeading: 'Let others know about your beautiful trip',
        body: '''MotaTrip lets you enjoy trips other users have saved. 
You can also publish your trips for others to enjoy. You can invite a group of friends to share your trip and track their progress as they drive with you. You can rate pubs and other points of interest to help others enjoy their trip.
''',
        imageUrl: 'assets/images/CarGroup.png'));

    return ListView(children: [
      const Card(
          child: Column(children: [
        SizedBox(
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'MotaTrip',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              )),
        ),
        SizedBox(
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 15),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'the new free trip planning app',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              )),
        ),
      ])),
      for (int i = 0; i < homeItems.length; i++) ...[
        HomeTile(homeItem: homeItems[i])
      ],
      const SizedBox(
        height: 40,
      ),
    ]);
  }

  void tripsFromWeb() async {
    int tries = 0;
    while (Setup().jwt.isEmpty && ++tries < 4) {
      await login(context);
      if (Setup().jwt.isEmpty) {
        debugPrint('Login failed');
      }
    }
    tripItems = await getTrips();
    for (int i = 0; i < tripItems.length; i++) {}
    setState(() {});
  }

  Widget _showTripTiles() {
    return ListView(children: [
      const Card(
          child: Column(children: [
        SizedBox(
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 15),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'Trips for you to enjoy...',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              )),
        ),
      ])),
      for (int i = 0; i < tripItems.length; i++) ...[
        TripTile(
          tripItem: tripItems[i],
          index: i,
          onGetTrip: onGetTrip,
          onRatingChanged: onTripRatingChanged,
        )
      ],
      const SizedBox(
        height: 40,
      ),
    ]);
  }

  _getMessages() async {
    _messages = await messagesFromDb();
    if (_messages.isEmpty) {
      // _messages.clear();
      _messages.add(Message(
        id: -1,
        groupMember: GroupMember(forename: 'Frank', surname: 'Seddon'),
        message: 'Message 1',
        read: false,
      ));
      _messages.add(Message(
        id: -1,
        groupMember: GroupMember(forename: 'Frank', surname: 'Seddon'),
        message:
            'Message 2 blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah',
      ));
    }
    _filteredMessages = filterMessages(0);
  }

  Widget _showMessages() {
    /// https://www.dhiwise.com/post/flutter-pull-to-refresh-how-to-implement-customize
    /// https://www.youtube.com/watch?app=desktop&v=X_hQijCqaKA  handling bottom system nav visibility
    /// https://www.youtube.com/watch?v=bWehAFTFc9o  share on social media

    if ([MessageActions.read, MessageActions.none].contains(_messageActions)) {
      if (_messages.isEmpty) {
        _getMessages();
      }
      return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: Column(children: [
                _filterMessages(),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                    child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _filteredMessages.length,
                  itemBuilder: (context, index) => Card(
                    elevation: 5,
                    child: MessageTile(
                      index: index,
                      message: _filteredMessages[index],
                      onEdit: onEditMember,
                      onSelect: (val) => {debugPrint('Selected message: $val')},
                    ),
                  ),
                )),
                //  ]),
                Align(
                    alignment: Alignment.bottomLeft,
                    child: Wrap(
                      spacing: 5,
                      children: getChips(),
                    )),
              ])));
    } else {
      if (_groupMembers.isEmpty) {}
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Column(children: [
            _filterMessages(),
            const SizedBox(
              height: 10,
            ),
            Expanded(
                child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _filteredGroupMembers.length,
              itemBuilder: (context, index) => Card(
                elevation: 5,
                child: GroupMemberTile(
                  index: index,
                  groupMember: _filteredGroupMembers[index],
                  onEdit: onEditMember,
                  onDelete: (val) => {debugPrint('Selected message: $val')},
                  onSelect: onSelectMember,
                ),
              ),
            )),
            //  ]),
            Align(
                alignment: Alignment.bottomLeft,
                child: Wrap(
                  spacing: 5,
                  children: getChips(),
                )),
          ]));
    }
  }

  Future<void> _handleRefresh() async {
    // Simulate network fetch or database query

    await Future.delayed(const Duration(seconds: 2));

    // Update the list of items and refresh the UI

    setState(() {
      _getMessages();

      /// xx = List.generate(20, (index) => "Refreshed Item ${index + 1}");
    });
  }

  Widget _showMyTripTiles(List<MyTripItem> _myTripItems) {
    return ListView(children: [
      const Card(
          child: Column(children: [
        SizedBox(
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 15),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Trips I've already explored...",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              )),
        ),
      ])),
      for (int i = 0; i < _myTripItems.length; i++) ...[
        Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: MyTripTile(
              index: i,
              myTripItem: _myTripItems[i],
              onLoadTrip: loadTrip,
              onShareTrip: shareTrip,
              onDeleteTrip: deleteTrip,
              onPublishTrip: publishTrip,
            ))
      ],
      const SizedBox(
        height: 40,
      ),
    ]);
  }

  Future<void> loadTrip(int index) async {
    /// Flutter uses pass-by-reference for all objects (not int bool etc which are pass-by-value)
    /// so clearing the _currentTrip.pointsOfInterest will also clear _myTripItems[index].pointsOfInterest
    /// if the _myTripItems[index] is the currently just entered trip

    int driveId = _myTripItems[index].getDriveId();

    _currentTrip = _myTripItems[index];
    await _currentTrip.loadLocal(driveId);
    _currentTrip.setIndex(index);

    setState(() {
      //   _bottomNavigationsBarIndex = 2;
      _tripState = TripState.notFollowing;
      _alignDirectionOnUpdate = AlignOnUpdate.never;
      _alignPositionOnUpdate = AlignOnUpdate.never;
      _tripActions = TripActions.none;
      _appState = AppState.driveTrip;
      _showTarget = false;
      _title = _currentTrip.getHeading();
      try {
        _animatedMapController.animateTo(
            dest: _currentTrip.pointsOfInterest()[0].point);
      } catch (e) {
        debugPrint('Error animatedMapController not initialised');
      }
    });

    return;
  }

  Future<void> getTripDetails(int index) async {
    _currentTrip.clearRoutes();
    List<Polyline> polyLines =
        await loadPolyLinesLocal(_currentTrip.getDriveId());
    for (int i = 0; i < polyLines.length; i++) {
      _currentTrip.addRoute(mt.Route(
          id: -1,
          points: polyLines[i].points,
          color: polyLines[i].color,
          borderColor: polyLines[i].color,
          strokeWidth: polyLines[i].strokeWidth));
    }

    loadManeuversLocal(_currentTrip.getDriveId())
        .then((maneuvers) => _currentTrip.addManeuvers(maneuvers));

    int closest = await getClosestManeuver(_currentTrip.maneuvers());
    debugPrint('closest maneuver is: $closest');
    return;
  }

  Future<void> shareTrip(int index) async {
    MyTripItem currentTrip = _myTripItems[index];
    currentTrip.showMethods = false;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ShareForm(
                tripItem: currentTrip,
              )),
    ).then((value) {
      setState(() {
        currentTrip.showMethods = true;
      });
    });
    return;
  }

  Future<void> deleteTrip(int index) async {
    // _indexToDelete = index;
    Utility().showOkCancelDialog(
        context: context,
        alertTitle: 'Permanently delete trip?',
        alertMessage: _myTripItems[index].getHeading(),
        okValue: index, // _myTripItems[index].getDriveId(),
        callback: onConfirmDeleteTrip);
  }

  Future<void> publishTrip(int index) async {
    String driveUI = '';
    int driveId = _myTripItems[index].getDriveId();
    postTrip(_myTripItems[index]).then((driveUi) {
      driveUI = driveUi['id'];
      for (PointOfInterest pointOfInterest
          in _myTripItems[index].pointsOfInterest()) {
        postPointOfInterest(pointOfInterest, driveUI);
      }
    }).then((_) async {
      List<Polyline> polylines = await loadPolyLinesLocal(driveId);
      postPolylines(polylines, driveUI);

      List<Maneuver> maneuvers = await loadManeuversLocal(driveId);
      postManeuvers(maneuvers, driveUI);
    });
    return;
  }

  Future<void> onGetTrip(int index) async {
    _currentTrip = MyTripItem(heading: '');
    _currentTrip = await getTrip(tripItems[index].uri);
    _currentTrip.setId(-1);
    _currentTrip.setDriveUri(tripItems[index].uri);
    setState(() {
      _tripState = TripState.notFollowing;
      _alignDirectionOnUpdate = AlignOnUpdate.never;
      _alignPositionOnUpdate = AlignOnUpdate.never;
      _tripActions = TripActions.none;
      _appState = AppState.driveTrip;
      _showTarget = false;
      _title = _currentTrip.getHeading();
      adjustMapHeight(MapHeights.full);
    });

    return;
  }

  onTripRatingChanged(int value, int index) async {
    setState(() {
      debugPrint('Value: $value  Index: $index');
      tripItems[index].score = value.toDouble();
    });
    putDriveRating(tripItems[index].uri, value);
  }

  onPointOfInterestRatingChanged(int value, int index) async {
    putPointOfInterestRating(_currentTrip.pointsOfInterest()[index].url, value);
  }

  void onConfirmDeleteTrip(int value) {
    debugPrint('Returned value: ${value.toString()}');
    if (value > -1) {
      int driveId = _myTripItems[value].getDriveId();
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
                      //  contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 30),
                      onLongPress: () => {
                            _animatedMapController.animateTo(
                                dest: _currentTrip
                                    .pointsOfInterest()[index]
                                    .point)
                          })),
              if (_appState != AppState.driveTrip) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(
                          elevation: 5,
                          shadowColor: const Color.fromRGBO(95, 94, 94, 0.984),
                          //   maximumSize: Size(12, 12),
                          backgroundColor:
                              const Color.fromARGB(214, 245, 6, 6)),
                      onPressed: () {
                        //    debugPrint('Button No:$i');
                        insertAfter = insertAfter == index ? -1 : index;
                        _showTarget = insertAfter == index;
                        setState(() {});
                      },
                      icon:
                          Icon(index == insertAfter ? Icons.close : Icons.add),
                    ),
                  ],
                ),
              ],
            ]));
  }

  Column _exploreDetailsHeader() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: TextFormField(
            autofocus: _tripActions ==
                TripActions.headingDetail, //  tripItem.heading.isEmpty,
            focusNode: fn1,
            textInputAction: TextInputAction.next,
            readOnly: _tripState == TripState.following,
            //    enabled: _appState != AppState.driveTrip,
            textAlign: TextAlign.start,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Give your trip a name...',
              labelText: 'Trip name',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            initialValue:
                _currentTrip.getHeading(), //widget.port.warning.toString(),
            onChanged: (text) => setState(() {
                  _currentTrip.setHeading(text);
                })
            // () => widget.port.warning = double.parse(text)),
            ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: TextFormField(
            readOnly: _tripState == TripState.following,
            //  enabled: _appState != AppState.driveTrip,
            autofocus: false,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.start,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            spellCheckConfiguration: const SpellCheckConfiguration(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter a short summary of your trip...',
              labelText: 'Trip summary',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            initialValue:
                _currentTrip.getSubHeading(), //widget.port.warning.toString(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (text) => setState(() {
                  _currentTrip.setSubHeading(text);
                })
            // () => widget.port.warning = double.parse(text)),
            ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: TextFormField(
            readOnly: _tripState == TripState.following,
            autofocus: false,
            textInputAction: TextInputAction.done,
            // enabled: _appState != AppState.driveTrip,
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
                _currentTrip.getBody(), //widget.port.warning.toString(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (text) => setState(() {
                  _currentTrip.setBody(text);
                })
            // () => widget.port.warning = double.parse(text)),
            ),
      ),
    ]);
  }

  Future getImage(ImageSource source, PointOfInterest poi) async {
    // XFile _image;
    final picker = ImagePicker();

    await picker.pickImage(source: source).then((pickedFile) {
      setState(() {
        if (pickedFile != null) {
          poi.images = "${poi.images},{'url': ${pickedFile.path}, 'caption':}";
        }
      });
    });
  }

  /// _trackingState
  /// Sets tracking on if off
  /// Clears down the _currentTrip.routes

  _trackingState({required bool trackingOn, description = ''}) async {
    LatLng pos;
    try {
      pos = LatLng(_currentPosition.latitude, _currentPosition.longitude);
    } catch (e) {
      debugPrint('Error getting lat_long @ ${e.toString()}');
      pos = const LatLng(0.0, 0.0);
    }

    if (_tripState == TripState.recording) {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best)
          .then((position) {
        _currentPosition = position;
        pos = LatLng(_currentPosition.latitude, _currentPosition.longitude);
        _animatedMapController.animateTo(dest: pos);
        _currentTrip.clearRoutes();
        _currentTrip.addRoute(mt.Route(
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
        // _lastCheck = DateTime.now();
        _tripDistance = 0;
        _totalDistance = 0;
      });
    }

    if (context.mounted) {
      int elapsed = _start.difference(DateTime.now()).inMinutes.abs();
      _singlePointOfInterest(context, pos, -1,
          time: elapsed,
          distance: _travelled,
          name: description); // -1 = append
    }
    setState(() {});
    _goodRoad.isGood = false;
    // _tracking = trackingOn;
  }

  /// Uses Geolocator.getPositionStream to get a stream of locations. Triggers posotion update
  /// every 10M
  /// must use _positionStream.cancel() to cancel stream when no longer reading from it

  void getLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10, // 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      _currentPosition = position;
      _speed = _currentPosition.speed * 3.6 / 8 * 5; // M/S -> MPH
      LatLng pos =
          LatLng(_currentPosition.latitude, _currentPosition.longitude);

      if (_tripState == TripState.recording) {
        if (_lastLatLng == const LatLng(0.00, 0.00)) {
          _lastLatLng = pos;
          _tripDistance = 0;
          _currentTrip.clearRoutes();
          _currentTrip.addRoute(mt.Route(
              id: -1,
              points: [pos],
              borderColor: uiColours.keys.toList()[Setup().routeColour],
              color: uiColours.keys.toList()[Setup().routeColour],
              strokeWidth: 5));
        }
        _currentTrip.routes()[_currentTrip.routes().length - 1].points.add(pos);
        debugPrint(
            '_currentTrip.routes().length: ${_currentTrip.routes().length}  points: ${_currentTrip.routes()[_currentTrip.routes().length - 1].points.length}');
        _tripDistance += Geolocator.distanceBetween(
            _lastLatLng.latitude,
            _lastLatLng.longitude,
            _currentPosition.latitude,
            _currentPosition.longitude);

        _lastLatLng =
            LatLng(_currentPosition.latitude, _currentPosition.longitude);
      } else if (_tripState == TripState.following) {
        setState(() => _directionsIndex = getDirectionsIndex());
      }
    });
  }

  int getDirectionsIndex() {
    int idx = -1;
    double distance = 99999;
    double temp;
    if (_tripState == TripState.following) {
      for (int i = 0; i < _currentTrip.maneuvers().length; i++) {
        temp = Geolocator.distanceBetween(
            _currentPosition.latitude,
            _currentPosition.longitude,
            _currentTrip.maneuvers()[i].location.latitude,
            _currentTrip.maneuvers()[i].location.longitude);
        if (temp < distance) {
          distance = temp;
          idx = i;
        }
      }
    }

    return idx;
  }

  adjustMapHeight(MapHeights newHeight) {
    if (mapHeights[1] == 0) {
      mapHeights[0] = MediaQuery.of(context).size.height - 190; // info closed
      mapHeights[1] = mapHeights[0] - 200; // heading data
      mapHeights[2] = mapHeights[0] - 400; // open point of interest
      mapHeights[3] = mapHeights[0] - 300; // message
    }
    mapHeight = mapHeights[MapHeights.values.indexOf(newHeight)];
    if (newHeight == MapHeights.full) {
      dismissKeyboard();
    }
    listHeight = (mapHeights[0] - mapHeight);
    _resizeDelay = 400;
  }

  locationLatLng(pos) {
    debugPrint(pos.toString());
    setState(() {
      _showSearch = false;
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
      setState(() {
        //  debugPrint(
        //      'Route tapped routes: ${routes().toString()}  details: ${details.toString()}');
      });
    }
  }

  expandChange(var details) {
    if (details != null) {
      setState(() {
        debugPrint('ExpandChanged: $details');
        _editPointOfInterest = details;
        if (details >= 0) {
          adjustMapHeight(MapHeights.pointOfInterest);
        } else {
          FocusManager.instance.primaryFocus?.unfocus(); // dismiss keyboard
          adjustMapHeight(MapHeights.full);
        }
      });
      //  Future.delayed(const Duration(milliseconds: 500), () {
      //    setState(() {});
      //  });
    }
  }

  iconButtonTapped(var details) {
    // if (details != null) {
    //  debugPrint('IconButton pressed');
    if (_editPointOfInterest > -1) {
      _animatedMapController.animateTo(
          dest: _currentTrip.pointsOfInterest()[_editPointOfInterest].point);
    }
  }

  removePointOfInterest(var details) {
    if (_editPointOfInterest > -1) {
      _currentTrip.removePointOfInterestAt(_editPointOfInterest);
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
      setState(() {
        // debugPrint('Map event: ${details.toString()}');
      });
    }
  }

  /// SaveTrip()
  /// Saves all the trip data to the local SQLLite db
  ///

  Future<int> _saveTrip() async {
    if (_currentTrip.getHeading().isEmpty) {
      Utility().showConfirmDialog(context, "Can't save - more info needed",
          "Please enter what you'd like to call this trip.");
      setState(() {
        _resizeDelay = 300;
        mapHeight = 400;
        adjustMapHeight(MapHeights.headers);
        _tripActions = TripActions.headingDetail;
        fn1.requestFocus();
      });
      return -1;
    }

    if (_currentTrip.getSubHeading().isEmpty) {
      Utility().showConfirmDialog(context, "Can't save - more info needed",
          'Please give a brief summary of this trip.');
      setState(() {
        adjustMapHeight(MapHeights.headers);
        _tripActions = TripActions.headingDetail;
      });
      return -1;
    }

    if (_currentTrip.getBody().isEmpty) {
      Utility().showConfirmDialog(context, "Can't save - more info needed",
          'Please give some interesting details about this trip.');
      setState(() {
        adjustMapHeight(MapHeights.headers);
        _tripActions = TripActions.headingDetail;
      });
      return -1;
    }

    if (_currentTrip.maneuvers().isEmpty) {
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
      int index = _currentTrip.getIndex();
      await _currentTrip.saveLocal();
      int driveId = _currentTrip.getDriveId();
      if (driveId > -1) {
        await _currentTrip.loadLocal(driveId);
        if (index == -1) {
          _currentTrip.setIndex(_myTripItems.length);
          _myTripItems.add(_currentTrip);
        } else {
          _myTripItems[index] = _currentTrip;
        }
      }
    } catch (e) {
      String err = e.toString();
      debugPrint('Error: $err');
    }
    setState(() {
      //  mapHeight = height;
    });
    return _currentTrip.getDriveId();
  }

  Future<ui.Image> getMapImage() async {
    final mapBoundary =
        mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    return await mapBoundary.toImage();
  }

  Future<bool> _publishTrip() async {
    return true;
  }

  _clearTrip() {
    setState(() {
      //    _currentTrip = MyTripItem(heading: '');
      _startLatLng = const LatLng(0.00, 0.00);
      _lastLatLng = const LatLng(0.00, 0.00);
      _goodRoad.isGood = false;
      _cutRoutes.clear;
      _tripActions = TripActions.none;
      //  _currentTrip.setDriveId(-1);
    });
  }

  Widget _getOverlay() {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.only(right: 4, bottom: 4),
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors
                      .black, // Color does not matter but should not be transparent

                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  /// _MyHomePageState Class End -----------------------------------------
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
              constraints:
                  const BoxConstraints(minHeight: 40.0, minWidth: 70.0),
              children: options,
              onPressed: (int index) {
                onButtonPressed(index);
              },
            )
          ]),
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
              decoration: InputDecoration(hintText: 'Enter text')),
          actions: [
            TextButton(
                onPressed: submit(context, setState),
                child: const Text('Submit'))
          ],
        ),
      ),
    );

submit(BuildContext context, setState) {
  Navigator.of(context).pop();
  setState(() {});
}
/**
 *         Chip(
          backgroundColor: Colors.yellow,
          avatar: const Icon(Icons.device_thermostat, size: 25),
          label: Text(
            '${adcToTemp(cooker.temperature).truncate()} C',
            style: const TextStyle(fontSize: 20),
          ),
        ),
 */
