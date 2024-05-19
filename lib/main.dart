import 'dart:async';
// import 'dart:ffi';
import 'dart:ui' as ui;
import 'dart:math';
// import 'dart:developer';
import 'dart:io';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/utilities.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'models.dart';
import 'route.dart' as mt;
import 'screens/splash_screen.dart';
import 'services/web_helper.dart';
import 'services/db_helper.dart';
import 'point_of_interest_tile.dart';
/*
import 'screens/home.dart';
import 'services/image_helper.dart';
*/
import 'home_tile.dart';
import 'trip_tile.dart';
import 'my_trip_tile.dart';
import 'screens/dialogs.dart';
import 'screens/painters.dart';
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

enum AppState { loading, home, download, createTrip, myTrips, shop }

enum TripState { manual, automatic }

enum StickyState {
  manAuto,
  manAutoPub,
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
  final bool _exploreTracking = false;
  final List<PointOfInterest> _pointsOfInterest = [];
  AppState _appState = AppState.home;
  TripState _tripState = TripState.manual;
  final start = TextEditingController();
  final end = TextEditingController();
  final mapController = MapController();
  bool isVisible = false;
  PopupValue popValue = PopupValue(-1, '', '');
  final navigatorKey = GlobalKey<NavigatorState>();
  List<Marker> markers = [];
  // List<PointOfInterest> _pointsOfInterest = [];
  int id = -1;
  int userId = -1;
  int driveId = -1;
  int type = -1;
  double iconSize = 35;
  LatLng _startLatLng = const LatLng(0.00, 0.00);
  LatLng lastLatLng = const LatLng(0.00, 0.00);
  late Future<bool> _loadedOK;
  bool _tracking = false;
  bool _goodRoad = false;
  // late CutRoute _cutRoute;
  final List<CutRoute> _cutRoutes = [];
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
  late Position _position;
  double _tripDistance = 0;
  double _totalDistance = 0;
  DateTime _start = DateTime.now();
  DateTime _lastCheck = DateTime.now();
  double _speed = 0.0;
  int insertAfter = -1;
  int _poiDetailIndex = -1;
  int _bnbIndex = 0;
  var moveDelay = const Duration(seconds: 2);
  double _travelled = 0.0;
  TripItem tripItem = TripItem(heading: '');
  int highlightedIndex = -1;
  final ScrollController _scrollController = ScrollController();
  final PointOfInterestController _pointOfInterestController =
      PointOfInterestController();

  final mt.RouteAtCenter _routeAtCenter = mt.RouteAtCenter();

  // final MarkerWidget _markerWidget = MarkerWidget(type: 12);

  final List<List<bool>> _exploreMenuStates = [
    <bool>[true, false],
    <bool>[false, false, false, false],
    <bool>[false, false, false, false],
    <bool>[false, false, false]
  ];
  static final List<List<Widget>> _exploreMenuOptions = [
    const <Widget>[
      Padding(
          padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.touch_app),
            Text('Add trip details'),
            Text('manually')
          ])),
      Padding(
          padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.directions_car),
            Text('Add trip details'),
            Text('automatically'),
          ])),
    ],
    const <Widget>[
      Column(children: [Icon(Icons.save), Text('Save trip')]),
      Column(children: [Icon(Icons.publish), Text('Publish trip')]),
      Column(children: [Icon(Icons.wrong_location), Text('Clear trip')]),
      Column(children: [Icon(Icons.edit), Text('Edit trip')]),
    ],
    const <Widget>[
      Column(children: [Icon(Icons.save), Text('Save trip')]),
      Column(children: [Icon(Icons.publish), Text('Publish trip')]),
      Column(children: [Icon(Icons.wrong_location), Text('Clear trip')]),
      Column(children: [Icon(Icons.directions_car), Text('Record trip')])
    ],
    <Widget>[
      const Padding(
          padding: EdgeInsets.fromLTRB(9, 3, 9, 3),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.save),
            Text('Save'),
            Text('point of interest')
          ])),
      const Padding(
          padding: EdgeInsets.fromLTRB(9, 3, 9, 3),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.delete),
            Text('Delete'),
            Text('point of interest')
          ])),
      const Padding(
          padding: EdgeInsets.fromLTRB(9, 3, 9, 3),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.photo_library),
            Text('Image from'),
            Text('gallery'),
          ])),
    ],
  ];

  final List<List<String>> _hints = [
    [
      'MotaTrip News',
      'Trips available to download',
      'Create new trip',
      "Trips I've recorded",
      'MotaTrip user offers'
    ],
    [' - manually', ' - recording', ' - stopped', ' - paused']
  ];

  String _title = 'MotaTrip'; // _hints[0][0];

  final List<List<BottomNavigationBarItem>> _bottomNavigationsBarItems = [
    [
      /// Level 0
      const BottomNavigationBarItem(
          icon: Icon(Icons.home), label: 'Home', backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.route),
          label: 'Trips',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Create Trip',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'My Trips',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.storefront),
          label: 'Shop',
          backgroundColor: Colors.blue),
    ],
    [
      /// Level 1
      const BottomNavigationBarItem(
          icon: Icon(Icons.arrow_back),
          label: 'Back',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.add_location),
          label: 'Waypoint',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.add_photo_alternate),
          label: 'Point of Interest',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.add_road),
          label: 'Great Road',
          backgroundColor: Colors.blue),
    ],
    [
      /// Level 2
      const BottomNavigationBarItem(
          icon: Icon(Icons.arrow_back),
          label: 'Back',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.play_arrow),
          label: 'Start Recording',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.pause),
          label: 'Pause Recording',
          backgroundColor: Colors.blue),
    ],
    [
      /// Level 3
      const BottomNavigationBarItem(
          icon: Icon(Icons.arrow_back),
          label: 'Back',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.stop),
          label: 'Stop Recording',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.pause),
          label: 'Pause Recording',
          backgroundColor: Colors.blue),
    ],
    [
      /// Level 4
      const BottomNavigationBarItem(
          icon: Icon(Icons.arrow_back),
          label: 'Back',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.cut),
          label: 'Split Route',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.add_photo_alternate),
          label: 'Point of Interest',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.add_road),
          label: 'Great Road',
          backgroundColor: Colors.blue),
    ],
    [
      /// Level 5
      const BottomNavigationBarItem(
          icon: Icon(Icons.arrow_back),
          label: 'Back',
          backgroundColor: Colors.blue),
      /* const BottomNavigationBarItem(
          icon: Icon(Icons.cut),
          label: 'Split route',
          backgroundColor: Colors.blue),
      */
      const BottomNavigationBarItem(
          icon: Icon(Icons.add_photo_alternate),
          label: 'Point of Interest',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.remove_road),
          label: 'Great Road End',
          backgroundColor: Colors.blue),
    ],
  ];

  int _bottomNavigationsBarIndex = 0;
  // late bool _navigationMode;
  // late int _pointerCount;
  // double _markerSize = 200.0;
  // late final _animatedMapController = AnimatedMapController(vsync: this);
  late AnimatedMapController _animatedMapController;

  late final StreamController<double?> _allignPositionStreamController;
  late final StreamController<void> _allignDirectionStreamController;
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
    _pointsOfInterest.add(PointOfInterest(
      //  context,
      id,
      userId,
      driveId,
      iconIdx,
      desc,
      hint,
      size,
      size,
      images,
      //  markerIcon(iconIdx),
      /* ValueKey(id),*/
      markerPoint: latLng,
      marker: MarkerWidget(type: iconIdx),
    ));
    setState(() {
      // adjustHeigth(25);
      _scrollDown();
      //  _editPointOfInterest = _pointsOfInterest.length - 1;
    });
  }

  _addGreatRoadStartLabel(int id, int userId, int iconIdx, String desc,
      String hint, double size, LatLng latLng) {
    int top = mapHeight ~/ 2;
    int left = MediaQuery.of(context).size.width ~/ 2;

    _pointsOfInterest.add(PointOfInterest(
      //  context,
      id,
      userId,
      driveId,
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
      // adjustHeigth(25);
      _scrollDown();
      //  _editPointOfInterest = _pointsOfInterest.length - 1;
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
          userId,
          driveId,
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
          ),
        );
        if (id == -1) {
          _pointsOfInterest.add(poi);
        } else {
          _pointsOfInterest.insert(id + 1, poi);
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

    _loadedOK = dataFromDatabase();
    _title = _hints[0][0];
    _allignPositionStreamController = StreamController<double?>();
    _allignDirectionStreamController = StreamController<void>();
    _alignPositionOnUpdate = AlignOnUpdate.never;
    _alignDirectionOnUpdate = AlignOnUpdate.never;
    _animatedMapController = AnimatedMapController(vsync: this);
    mapHeight = 500; //500;
  }

  @override
  void dispose() {
    _allignPositionStreamController.close();
    _allignDirectionStreamController.close();
    _animatedMapController.dispose();
    super.dispose();
  }

  List<mt.Route> _routes = [
    mt.Route(
        points: const [LatLng(50, 0)], // routePoints,
        borderColor: uiColours.keys.toList()[Setup().routeColour],
        color: uiColours.keys.toList()[Setup().routeColour],
        strokeWidth: 5)
  ];
  // uture<List<LatLng>>

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
    setState(() {
      //  _markerSize = 200.0 * (zoom / 13.0);
      for (int i = 0; i < _pointsOfInterest.length; i++) {
        //    _pointsOfInterest[i].height = _markerSize;
        //    _pointsOfInterest[i].width = _markerSize;
      }
    });
  }

  Future<LatLng> locationCallback(String waypoint) async {
    LatLng result = const LatLng(0.00, 0.00);
    dynamic location; // = [LatLng(0.00, 0.00)];
    try {
      await locationFromAddress(waypoint).then((res) async {
        location = res;
        // debugPrint('Location: ${location[0].toString()}');
        await _animatedMapController
            .animateTo(
                dest: LatLng(location[0].latitude, location[0].longitude))
            .then((_) => setState(() {}));
      });
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
    // debugPrint('locationCallback returning: $result');
    return result;
  }

  Future<List<mt.Route>> routeCallback(List<String> waypoints) async {
    List<String> urlWaypoints = [];
    for (int i = 1; i < waypoints.length; i++) {
      List<Location> startL;
      List<Location> endL;
      try {
        await locationFromAddress(waypoints[i - 1]).then((res) async {
          startL = res;
          await locationFromAddress(waypoints[i]).then((res) {
            endL = res;
            urlWaypoints.add(
                '${startL[0].longitude},${startL[0].latitude};${endL[0].longitude},${endL[0].latitude}');
          });
        });
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    }

    _routes = [];

    for (int i = 0; i < urlWaypoints.length; i++) {
      Map<String, dynamic> apiData;
      apiData = await getRoutePoints(urlWaypoints[i]);
      routePoints = apiData["points"];
      await getRoutePoints(urlWaypoints[i]);
      _routes.add(mt.Route(
          id: -1,
          points: routePoints,
          color: _routeColour(_goodRoad),
          borderColor: _routeColour(_goodRoad),
          strokeWidth: 5));
    }
    setState(() {});
    return _routes;
  }

  // Future<List<Route>> routeCallback2(List<String> waypoints) async {
  Future<LatLng> routeCallback2(List<String> waypoints) async {
    //  List<String> urlWaypoints = [];
    for (int i = 0; i < waypoints.length; i++) {
      List<Location> startL;
      //   List<Location> endL;
      try {
        await locationFromAddress(waypoints[i]).then((res) async {
          startL = res;

          _animatedMapController.animateTo(
              dest: LatLng(startL[0].latitude, startL[0].longitude));
          return LatLng(startL[0].latitude, startL[0].longitude);
        });
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    }
    throw ('error in callback');
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
    for (int i = 0; i < _pointsOfInterest.length; i++) {
      if (_pointsOfInterest[i].type == 12) {
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
              '$waypoints${_pointsOfInterest[prior].point.longitude},${_pointsOfInterest[prior].point.latitude};';
          waypoints =
              '$waypoints${_pointsOfInterest[next].point.longitude},${_pointsOfInterest[next].point.latitude};';
        }
      }
    }
    if (waypoints != '') {
      _routes.clear();
      waypoints = waypoints.substring(0, waypoints.length - 1);
      List<LatLng> points = await getRoutes(waypoints);
      _routes.add(mt.Route(
          id: -1,
          points: points, // Route,
          color: _routeColour(_goodRoad),
          borderColor: _routeColour(_goodRoad),
          strokeWidth: 5));
    }
    setState(() {});
  }

  Future<Map<String, dynamic>> appendRoute(
    LatLng latLng2,
  ) async {
    LatLng latLng1;
    Map<String, dynamic> apiData = {};
    if (_startLatLng == const LatLng(0.00, 0.00)) {
      _startLatLng = latLng2;
      return apiData;
    }
    if (_routes.length > 1) {
      // Let's assume simple add
      latLng1 = _routes[_routes.length - 1]
          .points[_routes[_routes.length - 1].points.length - 1];
    } else {
      latLng1 = _startLatLng;
    }
    apiData = await addRoute(latLng1, latLng2);
    _routes.add(mt.Route(
        id: -1,
        points: apiData["points"], // Route,
        color: _routeColour(_goodRoad),
        borderColor: _routeColour(_goodRoad),
        strokeWidth: 5));
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
    } catch (e) {
      debugPrint('Error: $e');
    }
    String summary =
        '${(distance / 1000 * 5 / 8).toStringAsFixed(1)} miles - (${(duration / 60).floor()} minutes)';

    String name =
        '${jsonResponse['routes'][0]['legs'][0]['steps'][0]['name']}, ${jsonResponse['routes'][0]['legs'][0]['steps'][jsonResponse['routes'][0]['legs'][0]['steps'].length - 1]['name']}';
    name =
        '${jsonResponse['routes'][0]['legs'][0]['steps'][jsonResponse['routes'][0]['legs'][0]['steps'].length - 1]['name']}';
    //  if (!name.contains(',')) name = '$name, $name';

    result["name"] = name;

    result["distance"] = jsonResponse['routes'][0]['distance'];
    result["duration"] = jsonResponse['routes'][0]['duration'];
    result["summary"] = summary;
    result["points"] = routePoints;
    return result;
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
          bottom: _appState == AppState.createTrip && _showSearch
              ? PreferredSize(
                  preferredSize: const ui.Size.fromHeight(60),
                  child: AnimatedContainer(
                      height: 60,
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
            if (_appState == AppState.createTrip)
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

    debugPrint(
        'users: $userRecords  drives: $drivesRecords  polylines: $polyLineRecords  points of interest: $poiRecords');

    // tripItemFromDb();

    var user = alterTable();
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
  ///
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
        ] else if (_appState == AppState.createTrip) ...[
          SizedBox(
            height: mapHeight,
            width: MediaQuery.of(context).size.width,
            child: _handleMap(),
          ),
          _handleBottomSheetDivider(), // grab rail - GesureDetector()
          const SizedBox(
            height: 5,
          ),
          _showExploreDetail(), // Allows the trip to be planned
        ] else if (_appState == AppState.myTrips) ...[
          SizedBox(
            height: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                kBottomNavigationBarHeight,
            width: MediaQuery.of(context).size.width,
            child: _showMyTripTiles(),
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

  addWaypoint() {
    LatLng pos = _animatedMapController.mapController.camera.center;
    if (insertAfter == -1 &&
        _pointsOfInterest.isNotEmpty &&
        _pointsOfInterest[0].type == 12) {
      appendRoute(pos).then((data) {
        _addPointOfInterest(
            id, userId, 12, '${data["name"]}', '${data["summary"]}', 15.0, pos);
      });
    } else if (insertAfter > -1) {
      try {
        _singlePointOfInterest(context, pos, insertAfter).then((_) {
          loadRoutes();
        });
        insertAfter = -1;
      } catch (e) {
        debugPrint('Point of interest error: ${e.toString()}');
      }
    } else {
      _singlePointOfInterest(context, pos, insertAfter);
      _startLatLng = pos;
    }
    setState(() {});
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
    if (_pointsOfInterest[i].type < 12) {
      result.add(_pointsOfInterest[i].description == ''
          ? 'Point of interest - ${poiTypes[_pointsOfInterest[i].type]["name"]}'
          : _pointsOfInterest[i].description);
      result.add(_pointsOfInterest[i].description);
    } else {
      result.add('Waypoint ${i + 1} -  ${_pointsOfInterest[i].name}');
      result.add(_pointsOfInterest[i].description);
    }
    return result;
  }

  pointOfInterestRemove(int idx) async {
    /// Removing a poi:
    final PointOfInterest item = _pointsOfInterest.removeAt(idx);
    loadRoutes();
    setState(() {});
  }

  /// _handleBottomNavigationBar()
  /// controls BottoNavigationBar
  BottomNavigationBar _handleBottomNavigationBar() {
    bool roadHighlighted = false;
    int onTapOffset = 0;
    // int nbItemsIndex = 0;
    if (highlightedIndex > -1) {
      roadHighlighted = true;
      onTapOffset = _goodRoad
          ? 5 - _bottomNavigationsBarIndex
          : 4 - _bottomNavigationsBarIndex;

      debugPrint('Road highlighted! offSet $onTapOffset');
    }
    return BottomNavigationBar(
      currentIndex: _bnbIndex,
      showUnselectedLabels: true,
      selectedItemColor: Colors.white,
      unselectedItemColor: const Color.fromARGB(255, 214, 211, 211),
      backgroundColor: Colors.blue,
      items:
          _bottomNavigationsBarItems[_bottomNavigationsBarIndex + onTapOffset],
      onTap: ((idx) async {
        // _bnbIndex = idx + onTapOffset;
/*
        int bbIdx = roadHighlighted
            ? _goodRoad
                ? 4 // handle  Back | Point of Interest | Great Road End
                : 5 // handle  Back | Split Route | Point of Interest | Great Road
            : _bottomNavigationsBarIndex;
*/
        int bbIdx = _bottomNavigationsBarIndex + onTapOffset;

        switch (bbIdx) {
          //_bottomNavigationsBarIndex) {
          case 0:

            /// Top level Home, Download, Create Trip, ....
            _title = _hints[0][idx];

            switch (idx) {
              case 0:
                //  home
                _appState = AppState.home;
                break;
              case 1:
                // Web routes
                _appState = AppState.download;
                break;
              case 2:
                // Create route
                _appState = AppState.createTrip;
                _showTarget = true;
                _bottomNavigationsBarIndex = 1;
                _bnbIndex = 0;
                _exploreMenuStates[_stickyMenuIndex()][0] = true;
                _exploreMenuStates[_stickyMenuIndex()][1] = false;
                break;
              case 3:
                // My routes
                _appState = AppState.myTrips;
                break;
              case 4:
                // Shop
                _appState = AppState.shop;
                break;
            }
          case 1:

            /// <Back> <Waypoint> <Point of Interest> <Great Road>
            switch (idx) {
              case 0:
                _bottomNavigationsBarIndex = 0;
                _appState = AppState.home;
                highlightedIndex = -1;
                break;
              case 1:

                /// Add waypoint
                _goodRoad = false;
                await addWaypoint().then(() {
                  setState(() {});
                });
                break;
              case 2:
                _showTarget = true;
                LatLng pos = _animatedMapController.mapController.camera.center;
                await getPoiName(latLng: pos, name: 'Point of interest')
                    .then((name) {
                  _addPointOfInterest(id, userId, 15, name, '', 30.0, pos);
                });
                break;
              case 3:
                // Handle great road
                String txt =
                    'Great road start'; //_goodRoad ? 'Great road start' : 'Great road end';
                LatLng pos = _animatedMapController.mapController.camera.center;
                await _addGreatRoadStartLabel(id, userId, 13, txt, '', 80, pos)
                    .then(() {
                  setState(() {
                    _cutRoutes.clear;
                    _splitRoute();
                    _goodRoad = true;
                  });
                });
                break;
            }
          case 2 || 3:

            /// <Back> <Record>/<Stop> <Pause>
            switch (idx) {
              case 0:
                _bottomNavigationsBarIndex = 1;
                _tripState = TripState.manual;
                _tracking = false;
                _bnbIndex = 0;
                break;
              case 1:
                // stop / start
                _bottomNavigationsBarIndex = _tracking ? 2 : 3;
                _trackingState(trackingOn: !_tracking);
                _bnbIndex = 1;
                break;
              case 2:
                // pause
                _trackingState(trackingOn: false);
                _bottomNavigationsBarIndex = 2;
                _bnbIndex = 1;
                _tracking = false;
                break;
            }

          /// <Back> <Stop> <Pause>

          case 4:

            /// <Back> <Split Route> <Point of Interest> <Great Road>
            switch (idx) {
              case 0:
                _bottomNavigationsBarIndex = 1;
                _tripState = TripState.manual;
                _bnbIndex = 0;
                break;
              case 1:
                // split route
                _showTarget = true;
                /*
                LatLng pos = _animatedMapController.mapController.camera.center;
                await getPoiName(latLng: pos, name: 'Point of interest')
                    .then((name) {
                  _addPointOfInterest(id, userId, 15, name, '', 30.0, pos);
                });
               */

                /// When cutting a route it should place the waypoint in the correct position in _pointsOfInterest
                /// the 3rd parameter determines the position -1 is an append any other value is an insert
                ///  insertWayointAt
                ///

                int idx = insertWayointAt(
                    pointsOfInterest: _pointsOfInterest,
                    pointToFind: _routeAtCenter.pointOnRoute);

                await _singlePointOfInterest(context,
                        _animatedMapController.mapController.camera.center, idx,
                        refresh: false)
                    .then((res) {
                  try {
                    debugPrint('Result : ${res.toString()}');
                    _cutRoutes.clear();
                    _splitRoute();
                  } catch (e) {
                    debugPrint('Error splitting route: ${e.toString()}');
                  }
                });

                //    _bottomNavigationsBarIndex = _tracking ? 2 : 3;
                //    _trackingState(trackingOn: !_tracking);
                _bnbIndex = 1;
                break;
              case 2:
                // Point of interest at split
                _showTarget = true;
                LatLng pos = _animatedMapController.mapController.camera.center;
                await getPoiName(latLng: pos, name: 'Point of interest')
                    .then((name) {
                  _addPointOfInterest(id, userId, 15, name, '', 30.0, pos);
                });
                break;
              case 3:
                //  4 Back | Split Route | Point of Interest || Great Road Start
                //  3 Back | Point of Interest | Great Road End
                _bottomNavigationsBarIndex = 2;
                LatLng pos = _animatedMapController.mapController.camera.center;

                String txt = 'Great road start'; // : 'Great road end';
                await getPoiName(latLng: pos, name: 'Point of interest')
                    .then((name) {
                  _addGreatRoadStartLabel(
                      id, userId, _goodRoad ? 15 : 14, txt, name, 80.0, pos);
                }).then((_) {
                  _goodRoad = true;
                  _splitRoute();
                });
            }
          case 5:

            /// <Back> <Point of Interest> <Great Road End>
            switch (idx) {
              case 0:
                _bottomNavigationsBarIndex = 1;
                _tripState = TripState.manual;
                _bnbIndex = 0;
                break;
              case 1:
                _showTarget = true;
                LatLng pos = _animatedMapController.mapController.camera.center;
                await getPoiName(latLng: pos, name: 'Point of interest')
                    .then((name) {
                  _addPointOfInterest(id, userId, 15, name, '', 30.0, pos);
                });
                break;
              case 2:
                //  4 Back | Split Route | Point of Interest || Great Road Start
                //  3 Back | Point of Interest | Great Road End
                _bottomNavigationsBarIndex = 2;
                LatLng pos = _animatedMapController.mapController.camera.center;

                String txt = 'Great road end'; // : 'Great road end';
                await getPoiName(latLng: pos, name: 'Point of interest')
                    .then((name) {
                  _addGreatRoadStartLabel(
                      id, userId, _goodRoad ? 15 : 14, txt, name, 80.0, pos);
                }).then((_) {
                  _splitRoute();
                  _goodRoad = false;
                });
            }
        }

        setState(() {});
      }),
    );
  }

  ///
  /// _handleFabs()
  /// Controls the Loating Action Button behavious
  ///

  Column _handleFabs() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if ([AppState.createTrip /*, AppState.myTrips*/]
                  .contains(_appState) &&
              !_showSearch) ...[
            const SizedBox(
              height: 175,
            ),
            if (_tracking && _speed > 0.01) ...[
              Chip(
                backgroundColor: Colors.blue,
                avatar: const Icon(Icons.speed, size: 25),
                label: Text(
                  '${_speed.truncate()} Mph',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
            //      if (_tracking) ...[
            const SizedBox(
              height: 10,
            ),
            if (_bottomNavigationsBarIndex == 3) ...[
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    //  _showTarget = !_showTarget;
                    _goodRoad = _goodRoad ? false : true;
                  });
                },
                backgroundColor: Colors.blue,
                shape: const CircleBorder(),
                child: Icon(_goodRoad ? Icons.remove_road : Icons.add_road),
              )
            ],
            const SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              onPressed: () async {
                Position position = await Geolocator.getCurrentPosition();
                //  debugPrint('Position: ${position.toString()}');
                _animatedMapController.animateTo(
                    dest: LatLng(position.latitude, position.longitude));
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
  ///

  Stack _handleMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _animatedMapController.mapController,
          options: MapOptions(
            onMapEvent: checkMapEvent,
            onMapReady: () {
              mapController.mapEventStream.listen((event) {});
            },
            onPositionChanged: (position, hasGesure) {
              if (!_tracking) {
                int routeIdx = _routeAtCenter.getPolyLineNearestCenter();
                // if (routeIdx > -1) {
                for (int i = 0; i < _routes.length; i++) {
                  //  _routes[i].borderColor = _routes[i].color;
                  if (i == routeIdx) {
                    _routes[i].color =
                        uiColours.keys.toList()[Setup().selectedColour];
                  } else {
                    _routes[i].color = _routes[i].borderColor;
                  }
                }

                highlightedIndex = routeIdx;
              } else {
                updateTracking();
              }
              if (hasGesure) {
                _updateMarkerSize(position.zoom ?? 13.0);
              }
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
                markerSize: ui.Size(40, 40),
                markerDirection: MarkerDirection.heading,
              ),
            ),
            //  if (_pointsOfInterest.isNotEmpty)
            mt.RouteLayer(
              polylineCulling: true,
              polylines: _routes,
              onTap: routeTapped,
              onMiss: routeMissed,
              routeAtCenter: _routeAtCenter,
            ),
            MarkerLayer(markers: _pointsOfInterest),
            // mt.RouteLayer(polylines: Routes)
          ],
        ),
        if (_showTarget) ...[
          CustomPaint(
            painter: TargetPainter(
                top: mapHeight / 2,
                left: MediaQuery.of(context).size.width / 2,
                color: insertAfter == -1 ? Colors.black : Colors.red),
          )
        ],
      ],
    );
  }

  _splitRoute() async {
    try {
      _routes.add(mt.Route(
          id: -1,
          points: [], // Route,
          color: _routeColour(false), // == -1), //_goodRoad),
          borderColor: _routeColour(false), //  _goodPointStartIdx == -1),
          strokeWidth: 5));

      for (int i = _routeAtCenter.pointIndex;
          i < _routes[_routeAtCenter.routeIndex].points.length;
          i++) {
        _routes[_routes.length - 1]
            .points
            .add(_routes[_routeAtCenter.routeIndex].points.removeAt(i));
      }
    } catch (e) {
      debugPrint('splitRoute error: ${e.toString()}');
    }
  }

  ///
  /// _handleBottomSheetDivider()
  /// Handles the grab icion to separate the map from the bottom sheet
  ///
  GestureDetector _handleBottomSheetDivider() {
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
          mapHeight += details.delta.dy;
          adjustHeigth(100);
        });
      },
    );
  }

  /// The container that shows trip details

  SizedBox _showExploreDetail() {
    // _exploreTracking || _pointsOfInterest.isEmpty
    return SizedBox(
        height: listHeight,
        child: CustomScrollView(controller: _scrollController, slivers: [
          SliverPersistentHeader(
            pinned: true,
            floating: true,
            delegate: StickyMenuDeligate(
              options: _exploreMenuOptions[_stickyMenuIndex()],
              states: _exploreMenuStates[_stickyMenuIndex()],
              onButtonPressed: actionToggleButton,
            ),
          ),
          if (_editPointOfInterest < 0)
            SliverToBoxAdapter(
              child: _exploreDetailsHeader(),
            ),
          if (_editPointOfInterest < 0)
            SliverReorderableList(
                itemBuilder: (context, index) {
                  //   debugPrint('Index: $index');
                  return _pointsOfInterest[index].type == 12
                      ? waypointTile(index)
                      : PointOfInterestTile(
                          key: ValueKey(index),
                          pointOfInterestController: _pointOfInterestController,
                          index: index,
                          pointOfInterest: _pointsOfInterest[index],
                          onExpandChange: expandChange,
                          onIconTap: iconButtonTapped,
                        ); //   pointOfInterestTile(index);
                },
                itemCount: _pointsOfInterest.length,
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex = -1;
                    }
                    final PointOfInterest poi =
                        _pointsOfInterest.removeAt(oldIndex);
                    _pointsOfInterest.insert(newIndex, poi);
                  });
                }),
          if (_editPointOfInterest > -1)
            SliverToBoxAdapter(
                child: PointOfInterestTile(
              key: ValueKey(_editPointOfInterest),
              pointOfInterestController: _pointOfInterestController,
              index: _editPointOfInterest,
              pointOfInterest: _pointsOfInterest[_editPointOfInterest],
              onExpandChange: expandChange,
              onIconTap: iconButtonTapped,
              expanded: true,
            )) //     iconButtonTapped  expandChange      pointOfInterestTile(_editPointOfInterest)),
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

  Widget _showTripTiles() {
    List<TripItem> tripItems = [];
    tripItems.add(
      TripItem(
          heading: 'A Beautiful Trip Through The Cotswolds',
          subHeading:
              'Miles of lanes surrounded by beautiful countryside and honey stoned buildings',
          body:
              '''MotaTrip is a new app to help you make the most of the countryside around you. 
You can plan trips either on your own or you can explore in a group''',
          imageUrls: ['assets/images/map.png', 'assets/images/splash.png'],
          author: 'James Seddon',
          published: 'Feb 24',
          score: 3.5,
          distance: 54,
          closest: 98,
          scored: 19,
          pointsOfInterest: 4,
          downloads: 32),
    );

    tripItems.add(TripItem(
        heading: 'A Beautiful Trip Through The Cotswolds',
        subHeading:
            'Miles of lanes surrounded by beautiful countryside and honey stoned buildings',
        body:
            '''MotaTrip is a new app to help you make the most of the countryside around you. 
You can plan trips either on your own or you can explore in a group''',
        imageUrls: [
          'assets/images/map.png',
          'assets/images/splash.png',
          'assets/images/CarGroup.png'
        ],
        author: 'James Seddon',
        published: 'Dec 23',
        score: 2.5,
        scored: 5,
        pointsOfInterest: 6,
        distance: 52,
        closest: 32,
        downloads: 12));

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
        TripTile(tripItem: tripItems[i])
      ],
      const SizedBox(
        height: 40,
      ),
    ]);
  }

  Widget _showMyTripTiles() {
    List<MyTripItem> myTripItems = [];
    myTripItems.add(MyTripItem(
      heading: 'A Beautiful Trip Through The Cotswolds',
      subHeading:
          'Miles of lanes surrounded by beautiful countryside and honey stoned buildings',
      body:
          '''MotaTrip is a new app to help you make the most of the countryside around you. 
You can plan trips either on your own or you can explore in a group''',
      images:
          '[{"url": "assets/images/map.png", "caption": ""}, {"url": "assets/images/splash.png", "caption": ""}, {"url": "assets/images/CarGroup.png", "caption": "" }]',
      //   author: 'James Seddon',
      published: 'Feb 24',
      score: 3.5,
      distance: 54,
      closest: 98,
      //  scored: 19,
      pointsOfInterest: [],
    )
        //  downloads: 32),
        );

    myTripItems.add(MyTripItem(
      heading: 'A Beautiful Trip Through The Cotswolds',
      subHeading:
          'Miles of lanes surrounded by beautiful countryside and honey stoned buildings',
      body:
          '''MotaTrip is a new app to help you make the most of the countryside around you. 
You can plan trips either on your own or you can explore in a group''',
      images:
          '[{"url": "assets/images/map.png", "caption": ""}, {"url": "assets/images/splash.png", "caption": ""}, {"url": "assets/images/CarGroup.png", "caption": "" }]',

      //  "[{'url': assets/images/map.png, 'caption': }, {'url': assets/images/splash.png, 'caption':}, {'url': assets/images/CarGroup.png, 'caption': }]",
      //  author: 'James Seddon',
      published: 'Dec 23',
      score: 2.5,
      //  scored: 5,
      pointsOfInterest: [], //6,
      distance: 52,
      closest: 32,
    ));
    // downloads: 12));

    return ListView(children: [
      const Card(
          child: Column(children: [
        SizedBox(
          child: Padding(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 15),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Trips you've explored...",
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
      for (int i = 0; i < myTripItems.length; i++) ...[
        Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            child: MyTripTile(myTripItem: myTripItems[i]))
      ],
      const SizedBox(
        height: 40,
      ),
    ]);
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
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      trailing: IconButton(
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
                      leading: _pointsOfInterest[index].type < 12
                          ? IconButton(
                              iconSize: 25,
                              icon: Icon(
                                  markerIcon(_pointsOfInterest[index].type)),
                              onPressed: () async {
                                setState(() {});
                              },
                            )
                          : ReorderableDragStartListener(
                              key: Key('$index'),
                              index: index,
                              child: const Icon(Icons.drag_handle)),
                      title: Text(getTitles(index)[0]),
                      subtitle: Text(getTitles(index)[1]),
                      contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 30),
                      onLongPress: () => {
                            _animatedMapController.animateTo(
                                dest: _pointsOfInterest[index].point)
                          })),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                        elevation: 5,
                        shadowColor: const Color.fromRGBO(95, 94, 94, 0.984),
                        //   maximumSize: Size(12, 12),
                        backgroundColor: const Color.fromARGB(214, 245, 6, 6)),
                    onPressed: () {
                      //    debugPrint('Button No:$i');
                      insertAfter = insertAfter == index ? -1 : index;
                      _showTarget = insertAfter == index;
                      setState(() {});
                    },
                    icon: Icon(index == insertAfter ? Icons.close : Icons.add),
                  ),
                ],
              )
            ]));
  }

  Column _exploreDetailsHeader() {
    return Column(children: [
      SizedBox(
        height: 90,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: TextFormField(
              textAlign: TextAlign.start,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Give your trip a name...',
                labelText: 'Trip name',
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              initialValue: tripItem.heading, //widget.port.warning.toString(),
              onChanged: (text) => setState(() {
                    tripItem.heading = text;
                  })
              // () => widget.port.warning = double.parse(text)),
              ),
        ),
      ),
      SizedBox(
        height: 90,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: TextFormField(
              textAlign: TextAlign.start,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              spellCheckConfiguration: const SpellCheckConfiguration(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a short summary of your trip...',
                labelText: 'Trip summary',
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              initialValue:
                  tripItem.subHeading, //widget.port.warning.toString(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (text) => setState(() {
                    tripItem.subHeading = text;
                  })
              // () => widget.port.warning = double.parse(text)),
              ),
        ),
      ),
      SizedBox(
        height: 90,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: TextFormField(
              textAlign: TextAlign.start,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              spellCheckConfiguration: const SpellCheckConfiguration(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe details of your trip...',
                labelText: 'Trip details',
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              initialValue: tripItem.body, //widget.port.warning.toString(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (text) => setState(() {
                    tripItem.body = text;
                  })
              // () => widget.port.warning = double.parse(text)),
              ),
        ),
      ),
    ]);
  }

  /// actionToggleButton()
  /// Performs the actions for the sticky toggle button in its various forms

  actionToggleButton(value) async {
    int stickyMenuIndex = _stickyMenuIndex();
    switch (stickyMenuIndex) {
      case 0:

        /// Choose between manual and automatic routing
        _showTarget = value == 0;
        _bottomNavigationsBarIndex =
            _pointsOfInterest.isEmpty && value == 1 ? 2 : 1;

        break;
      case 1:
        // Choose between Save Publish Clear and Edit
        switch (value) {
          case 0:
            // Save trip
            await _saveTrip();
            break;
          case 1:
            // Publish trip
            // await _publishTrip();
            tripItemFromDb();
            break;
          case 2:
            // Clear trip
            _clearTrip();
            break;
          case 3:
            _tracking = false;
            _showTarget = true;
            break;
        }
        break;
      case 2:
        // Choose between Save Publish Clear and Record
        switch (value) {
          case 0:
            // Save trip
            await _saveTrip();
            break;
          case 1:
            // Publish trip
            // await _publishTrip();
            tripItemFromDb();
            break;
          case 2:
            // Clear trip
            _clearTrip();
            break;
          case 3:
            _tracking = true;
            _showTarget = false;
            break;
        }
        break;
      case 3:
        // Choose between save PointOfInterest delete PointOfInterest and load image
        switch (value) {
          case 0:
            // Save the point of interest
            _pointOfInterestController.save(_editPointOfInterest);
            setState(() {
              _updateMarker(_editPointOfInterest);
              _editPointOfInterest = -1;
            });
            break;
          case 1:
            // delete the point of interest
            if (_editPointOfInterest > -1 &&
                _editPointOfInterest < _pointsOfInterest.length) {
              PointOfInterest poi =
                  _pointsOfInterest.removeAt(_editPointOfInterest);
            }
            _editPointOfInterest = -1;
            break;
          case 2:
            // load image from galary
            _pointOfInterestController.loadImage(_editPointOfInterest);
            break;
        }
    }
    setState(() {
      for (int i = 0; i < _exploreMenuOptions[stickyMenuIndex].length; i++) {
        _exploreMenuStates[stickyMenuIndex][i] = i == value;
      }
    });
  }

  _updateMarker(editPointOfInterest) {
    setState(() {
      // _pointsOfInterest[_editPointOfInterest].marker.iconType = 4;
      // _pointsOfInterest[_editPointOfInterest].type;
      //});

      _pointsOfInterest[_editPointOfInterest].child = RawMaterialButton(
          onPressed: () => Utility().showAlertDialog(
              context,
              poiTypes.toList()[_pointsOfInterest[editPointOfInterest].type]
                  ['name'],
              _pointsOfInterest[editPointOfInterest].description),
          elevation: 2.0,
          fillColor: uiColours.keys.toList()[Setup()
              .pointOfInterestColour], // const Color.fromARGB(255, 224, 132, 10),
          shape: const CircleBorder(),
          child: Icon(
            markerIcon(_pointsOfInterest[editPointOfInterest]
                .type), //markerIcon(type),
            size: 25,
            color: Colors.blueAccent,
          ));
    });
  }

  /// Get the correct index from the sticky menu:
  ///

  int _stickyMenuIndex() {
    if (_editPointOfInterest > -1) {
      /// Editing a Point of Interest
      return 3;
    } else if (_pointsOfInterest.isEmpty) {
      /// Nothing added yet
      return 0;
    } else if (_tracking) {
      //}   exploreTracking) {
      /// Were currently tracking
      return 1;
    } else {
      /// Points of interest added manually.
      return 2;
    }
  }

  Future getImage(ImageSource source, PointOfInterest poi) async {
    await ImagePicker().pickImage(source: source).then((pickedFile) {
      setState(() {
        if (pickedFile != null) {
          poi.images = "${poi.images},{'url': ${pickedFile.path}, 'caption':}";
        }
      });
    });
  }

  /// _trackingState
  /// Sets tracking on if off
  /// Clears down the _routes

  _trackingState({required bool trackingOn, description = ''}) async {
    LatLng pos;
    try {
      pos = LatLng(_position.latitude, _position.longitude);
    } catch (e) {
      debugPrint('Error getting lat_long @ ${e.toString()}');
      pos = const LatLng(0.0, 0.0);
    }

    if (!_tracking) {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best)
          .then((position) {
        _position = position;
        pos = LatLng(position.latitude, position.longitude);
        _animatedMapController.animateTo(dest: pos);
        _routes.clear();
        _routes.add(mt.Route(
            id: -1,
            points: [LatLng(position.latitude, position.longitude)], // Route,
            color: _routeColour(_goodRoad),
            borderColor: _routeColour(_goodRoad),
            strokeWidth: 5));
        _startLatLng = pos;
        lastLatLng = pos;
        _travelled = 0.0;
        _start = DateTime.now();
        _lastCheck = DateTime.now();
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
    _goodRoad = false;
    _tracking = trackingOn;
  }

  updateTracking() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((position) {
      LatLng pos = LatLng(position.latitude, position.longitude);
      _speed = position.speed * 3.6 / 8 * 5;
      _position = position;
      if (lastLatLng == const LatLng(0.00, 0.00)) {
        lastLatLng = pos;
        _lastCheck = DateTime.now();
      } else {
        double distance = distanceBetween(pos, lastLatLng);
        if (distance > 0.01) {
          int secsMoving =
              _lastCheck.difference(DateTime.now()).inSeconds.abs();
          if (_speed == 0) {
            _speed = distance * 60 * 60 / secsMoving;
          }
          _lastCheck = DateTime.now();
          _travelled += distance;
          if (_routes[_routes.length - 1].points.length > 99) {
            _routes.add(mt.Route(
                points: [pos], // routePoints,
                borderColor: uiColours.keys.toList()[Setup().routeColour],
                color: uiColours.keys.toList()[Setup().routeColour],
                strokeWidth: 5));
          } else {
            _routes[_routes.length - 1].points.add(pos);
          }

          lastLatLng = pos;
          _tripDistance += distance;
          if (_tripDistance >= 0.5 ||
              _routes[_routes.length - 1].points.length == 1) {
            _totalDistance += _tripDistance;
            _tripDistance = 0;
            _singlePointOfInterest(context, pos, -1,
                distance: roundDouble(value: _totalDistance, places: 1),
                time: roundDouble(value: secsMoving / 60, places: 1));
          }
        }
        _animatedMapController.animateTo(dest: pos);
      }
    }).then((_) {
      setState(() {
        //  _showTarget = !_showTarget;
      });
    });
  }

  adjustHeigth(int percent) {
    double height = (MediaQuery.of(context).size.height -
            AppBar().preferredSize.height -
            kBottomNavigationBarHeight -
            _dividerHeight) *
        0.93;

    height = height * percent / 100;

    mapHeight = mapHeight > height ? height : mapHeight;
    mapHeight = mapHeight < 20 ? 20 : mapHeight;

    listHeight = (height - mapHeight);
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
        debugPrint(
            'Route tapped routes: ${routes.toString()}  details: ${details.toString()}');
      });
    }
  }

  expandChange(var details) {
    if (details != null) {
      debugPrint('ExpandChanged: $details');

      _editPointOfInterest = details;

      setState(() {});
    }
  }

  iconButtonTapped(var details) {
    // if (details != null) {
    debugPrint('IconButton pressed');
    if (_editPointOfInterest > -1) {
      _animatedMapController.animateTo(
          dest: _pointsOfInterest[_editPointOfInterest].point);
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
        debugPrint('Map event: ${details.toString()}');
      });
    }
  }

  Future<bool> _saveTrip() async {
    // Insert / Update the drive details
    if (tripItem.heading.isEmpty) {
      Utility().showConfirmDialog(context, "Can't save - more info please",
          "Please enter what you'd like to call this trip");
      return false;
    }

    if (tripItem.subHeading.isEmpty) {
      Utility().showConfirmDialog(context, "Can't save - more info please",
          'Please give a brief summary of this trip.');
      return false;
    }

    if (tripItem.body.isEmpty) {
      Utility().showConfirmDialog(context, "Can't save - more info please",
          'Please give some interesting details about this trip');
      return false;
    }

    Drive drive = Drive(
        id: 0,
        userId: -1,
        title: tripItem.heading,
        subTitle: tripItem.subHeading,
        body: tripItem.body,
        added: DateTime.now());

    int driveId = await saveDrive(drive: drive);

    if (driveId > -1 && _pointsOfInterest.isNotEmpty) {
      savePointsOfInterestLocal(
          userId: userId,
          driveId: driveId,
          pointsOfInterest: _pointsOfInterest);
      if (_routes.isNotEmpty) {
        savePolylinesLocal(
            id: id, userId: userId, driveId: driveId, polylines: _routes);
      }
    }

    // Insert / update all the points of interest with images

    // Insert / update all polylines

    return true;
  }

  Future<bool> _publishTrip() async {
    // Check user is registered - email verification

    // Insert / Update the drive details

    // Insert / update all the points of interest with images

    // Insert / update all polylines

    return true;
  }

  _clearTrip() {
    setState(() {
      _startLatLng == const LatLng(0.00, 0.00);
      _routes.clear();
      _pointsOfInterest.clear();
      _goodRoad = false;
      _cutRoutes.clear;
      _tracking = false;
      _bottomNavigationsBarIndex = 1; // Create route menu
    });
  }

/*
  int getPolyLineNearestCenter(
      {required BuildContext context,
      required List<mt.Route> routes,
      int pointerDistanceTolerance = 15}) {
    double maxValue = 9999999.0;
    int idx = -1;
    final mapState = MapCamera.of(context);

    var tap = mapState.pixelOrigin.toDoublePoint();

    // We might hit close to multiple polylines. We will therefore keep a reference to these in this map.
    // var mapState = MapCamera.of(context);
    // Calculating taps in between points on the polyline. We
    // iterate over all the segments in the polyline to find any
    // matches with the tapped point within the
    // pointerDistanceTolerance.

    for (int i = 0; i < routes.length; i++) {
      mt.Route currentPolyline = routes[i];
      for (var j = 1; j < currentPolyline.points.length; j++) {
        // We consider the points point1, point2 and tap points in a triangle
        var point1 = mapState.project(currentPolyline.points[j - 1]);
        var point2 = mapState.project(currentPolyline.points[j - 1]);
        // To determine if we have tapped in between two points, we
        // calculate the length from the tapped point to the line
        // created by point1, point2. If this distance is shorter
        // than the specified threshold, we have detected a tap
        // between two points.
        //
        // We start by calculating the length of all the sides using pythagoras.
        var a = _distanceBetweenPoints(point1, point2);
        var b = _distanceBetweenPoints(point1, tap);
        var c = _distanceBetweenPoints(point2, tap);

        // To find the height when we only know the lengths of the sides, we can use Heron's formula to get the Area.
        var semiPerimeter = (a + b + c) / 2.0;
        var triangleArea = sqrt(semiPerimeter *
            (semiPerimeter - a) *
            (semiPerimeter - b) *
            (semiPerimeter - c));

        // We can then finally calculate the length from the tapped point onto the line created by point1, point2.
        // Area of triangles is half the area of a rectangle
        // area = 1/2 base * height -> height = (2 * area) / base
        var height = (2 * triangleArea) / a;

        // We're not there yet - We need to satisfy the edge case
        // where the perpendicular line from the tapped point onto
        // the line created by point1, point2 (called point D) is
        // outside of the segment point1, point2. We need
        // to check if the length from D to the original segment
        // (point1, point2) is less than the threshold.

        var hypotenus = max(b, c);
        var newTriangleBase = sqrt((hypotenus * hypotenus) - (height * height));
        var lengthDToOriginalSegment = newTriangleBase - a;

        if (height < pointerDistanceTolerance &&
            lengthDToOriginalSegment < pointerDistanceTolerance) {
          var minimum = min(height, lengthDToOriginalSegment);
          if (minimum < maxValue) {
            debugPrint('Polyline $i found');
            idx = i;
            maxValue = minimum;
          }
        }
      }
    }
    return idx;
  }
*/
  double _distanceBetweenPoints(Point point1, Point point2) {
    var distancex = (point1.x - point2.x).abs();
    var distancey = (point1.y - point2.y).abs();

    var distance = sqrt((distancex * distancex) + (distancey * distancey));

    return distance;
  }

/*
  Future<bool> SaveRoutes({required int userid, required int tripid, required int color, required String points}) async {
    return true;
  }
*/

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
