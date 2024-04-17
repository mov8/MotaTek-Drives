import 'dart:async';
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
import 'screens/splash_screen.dart';
import 'services/web_helper.dart';
/*
import 'screens/home.dart';
import 'services/image_helper.dart';
*/
import 'home_tile.dart';
import 'trip_tile.dart';
import 'my_trip_tile.dart';
import 'screens/painters.dart';
import 'screens/dialogs.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:image_picker/image_picker.dart';

// import 'package:reorderables/reorderables.dart';

/*
https://techblog.geekyants.com/implementing-flutter-maps-with-osm     /// Shows how to implement markers and group them
https://stackoverflow.com/questions/76090873/how-to-set-location-marker-size-depend-on-zoom-in-flutter-map      
https://pub.dev/packages/flutter_map_location_marker
https://github.com/tlserver/flutter_map_location_marker
https://www.appsdeveloperblog.com/alert-dialog-with-a-text-field-in-flutter/   /// Shows text input dialog
https://fabricesumsa2000.medium.com/openstreetmaps-osm-maps-and-flutter-daeb23f67620  /// tapablePolylineLayer  

https://github.com/OwnWeb/flutter_map_tappable_polyline/blob/master/lib/flutter_map_tappable_polyline.dart
*/

int testInt = 0;
bool _exploreTracking = false;
List<PointOfInterest> _pointsOfInterest = [];

enum AppState { loading, home, download, createTrip, myTrips, shop }

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
  AppState _appState = AppState.home;
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
  bool _tracking = false;
  bool _goodRoad = false;
  late Size screenSize;
  late Size appBarSize;
  double mapHeight = 250;
  double listHeight = 100;
  bool _showTarget = false;
  bool _showSearch = false;
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
  final ScrollController _scrollController = ScrollController();

  static const List<Widget> _exploreModes = <Widget>[
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
  ];
  final List<bool> _selectedMode = <bool>[true, false];

  static const List<Widget> _imageModes = <Widget>[
    Padding(
        padding: EdgeInsets.fromLTRB(9, 3, 9, 3),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.save),
          Text('Save'),
          Text('point of interest')
        ])),
    Padding(
        padding: EdgeInsets.fromLTRB(9, 3, 9, 3),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete),
          Text('Delete'),
          Text('point of interest')
        ])),
    Padding(
        padding: EdgeInsets.fromLTRB(9, 3, 9, 3),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.photo_library),
          Text('Image from'),
          Text('gallery'),
        ])),
  ];
  final List<bool> _selectedImage = <bool>[false, false, false];

  static const List<Widget> _exploreModes1 = <Widget>[
    Column(children: [Icon(Icons.save), Text('Save trip')]),
    Column(children: [Icon(Icons.share), Text('Share trip')]),
    Column(children: [Icon(Icons.wrong_location), Text('Clear trip')]),
  ];
  final List<bool> _selectedMode1 = <bool>[false, false, false];
  final bool _exploreTracking = false;

/*
  List<List<BottomNavigationBarItem>> _bottomNavigationsBarItems =  [[
    BottomNavigationBarItem(
                icon: Icon(Icons.add_photo_alternate),
                label: 'Add Point of Interest'),

  ]];
*/

  final List<List<BottomNavigationBarItem>> _bottomNavigationsBarItems = [
    [
      const BottomNavigationBarItem(
          icon: Icon(Icons.home), label: 'Home', backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.route),
          label: 'Download',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Create trip',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'My trips',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.storefront),
          label: 'Shop',
          backgroundColor: Colors.blue),
    ],
    [
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
      const BottomNavigationBarItem(
          icon: Icon(Icons.arrow_back),
          label: 'Back',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.play_arrow),
          label: 'Start recording',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.pause),
          label: 'Pause recording',
          backgroundColor: Colors.blue),
    ],
    [
      const BottomNavigationBarItem(
          icon: Icon(Icons.arrow_back),
          label: 'Back',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.stop),
          label: 'Stop recording',
          backgroundColor: Colors.blue),
      const BottomNavigationBarItem(
          icon: Icon(Icons.pause),
          label: 'Pause recording',
          backgroundColor: Colors.blue),
    ],
  ];
  int _bottomNavigationsBarIndex = 0;
  // late bool _navigationMode;
  // late int _pointerCount;
  // double _markerSize = 200.0;
  // late final _animatedMapController = AnimatedMapController(vsync: this);
  late AnimatedMapController _animatedMapController;
  late FollowOnLocationUpdate _followOnLocationUpdate;
  late TurnOnHeadingUpdate _turnOnHeadingUpdate;

  // final ValueNotifier<bool> _showTarget = ValueNotifier<bool>(false);

  final _dividerHeight = 35.0;

//  double _ratio = 0.0; //0.6;
  // double _maxHeight = 100.0;

  // late AlignOnUpdate _alignOnUpdate;

  late StreamController<double?> _followCurrentLocationStreamController;
  late StreamController<void> _turnHeadingUpStreamController;

  // List<LatLng> routePoints = [LatLng(52.05884, -1.345583)];
  List<LatLng> routePoints = const [LatLng(51.478815, -0.611477)];

  final TextEditingController _textFieldController = TextEditingController();

  Future<void> _displayTextInputDialog(BuildContext context, LatLng latLng) {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          // PopupValue popValue = PopupValue(-1, '', '');
          return AlertDialog(
            title: const Text('Location Description'),
            content: SizedBox(
                height: 200,
                child: Column(
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Type',
                        ),
                        items: poiTypes
                            .map((item) => DropdownMenuItem<String>(
                                  value: item['id'].toString(),
                                  child: Row(children: [
                                    Icon(
                                      IconData(item['iconMaterial'],
                                          fontFamily: 'MaterialIcons'),
                                      color: Color(item['colourMaterial']),
                                    ),
                                    Text('    ${item['name']}')
                                  ]),
                                ))
                            .toList(),
                        onChanged: (item) => setState(() =>
                            popValue.dropdownIdx = item == null
                                ? -1
                                : int.parse(
                                    item)) //index of chosen item as a string
                        ),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          popValue.text1 = value;
                        });
                      },
                      controller: _textFieldController,
                      decoration: const InputDecoration(
                          hintText: "Describe point of interest.."),
                    ),
                  ],
                )),
            actions: <Widget>[
              MaterialButton(
                color: Colors.red,
                textColor: Colors.white,
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              MaterialButton(
                color: Colors.green,
                textColor: Colors.white,
                child: const Text('OK'),
                onPressed: () {
                  setState(() {
                    int iconIdx = popValue.dropdownIdx;
                    if (iconIdx >= 0) {
                      String desc = popValue.text1;
                      _addPointOfInterest(
                          id, userId, iconIdx, desc, '', 30.0, latLng);
                    }
                    Navigator.of(context).pop();
                  });
                },
              ),
            ],
          );
        });
  }

  List<String> images = [];

  _addPointOfInterest(int id, int userId, int iconIdx, String desc, String hint,
      double size, LatLng latLng) {
    _pointsOfInterest.add(PointOfInterest(context, id, userId, driveId, iconIdx,
        desc, hint, size, size, images, markerIcon(iconIdx),
        markerPoint: latLng));
    setState(() {
      _scrollDown();
    });
  }

  ///
  /// _singlePointOfInterest uses Komoot reverse lookup to get the address, and doesn't
  /// try to generate any polylines
  ///
  _singlePointOfInterest(BuildContext context, latLng, int id,
      {name = '', distance = 0, time = 0}) async {
    int type = 12;

    await getPoiName(latLng: latLng, name: name).then((name) {
      if (context.mounted) {
        PointOfInterest poi = PointOfInterest(
            context,
            id,
            userId,
            driveId,
            type,
            name,
            '$distance miles - ($time minutes)',
            10,
            10,
            images,
            markerIcon(type),
            markerPoint: latLng);
        if (id == -1) {
          _pointsOfInterest.add(poi);
        } else {
          _pointsOfInterest.insert(id + 1, poi);
        }
      }
    }).then((_) {
      setState(() {});
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
    // _navigationMode = false;
    // _pointerCount = 0;
    _followOnLocationUpdate =
        AlignOnUpdate.never; //FollowOnLocationUpdate.never;
    _turnOnHeadingUpdate = AlignOnUpdate.never; //TurnOnHeadingUpdate.never;
    _followCurrentLocationStreamController = StreamController<double?>();
    _turnHeadingUpStreamController = StreamController<void>();
    _animatedMapController = AnimatedMapController(vsync: this);
    //  _markerSize = 200.0;
    // screenSize = MediaQuery.of(context).size;
    // appBarSize = AppBar().preferredSize;, du
    // _maxHeight = MediaQuery.of(context).size.height * 0.6;
    // _position = Geolocator.getCurrentPosition();
    // mapHeight = MediaQuery.of(context).size.height * 0.8; //250.0;
    mapHeight = 500; //500;
    //(screenSize.height - appBarSize.height - _dividerHeight) * 0.9;

    // Timer(const Duration(seconds: 3), () {
    //   _appState = AppState.home;
    // });
  }

  @override
  void dispose() {
    _followCurrentLocationStreamController.close();
    _turnHeadingUpStreamController.close();
    _animatedMapController.dispose();
    super.dispose();
  }

  List<Polyline> polylines = [
    Polyline(
        points: [LatLng(50, 0)], // routePoints,
        color: const Color.fromARGB(255, 28, 97, 5),
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

  Future<List<Polyline>> routeCallback(List<String> waypoints) async {
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

    polylines = [];

    for (int i = 0; i < urlWaypoints.length; i++) {
      Map<String, dynamic> apiData;
      apiData = await getRoutePoints(urlWaypoints[i]);
      routePoints = apiData["points"];
      await getRoutePoints(urlWaypoints[i]);
      polylines.add(Polyline(
          points: routePoints,
          color: _goodRoad ? Colors.red : const Color.fromARGB(255, 28, 97, 5),
          strokeWidth: 5));
    }
    setState(() {});
    return polylines;
  }

  // Future<List<Polyline>> routeCallback2(List<String> waypoints) async {
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

          //  debugPrint(
          //      'Position: lat: ${startL[0].latitude} long: ${startL[0].longitude}');

          return LatLng(startL[0].latitude, startL[0].longitude);
          //        await locationFromAddress(waypoints[i]).then((res) {
          //          endL = res;
          //          urlWaypoints.add(
          //              '${startL[0].longitude},${startL[0].latitude};${endL[0].longitude},${endL[0].latitude}');
          //        });
        });
      } catch (e) {
        debugPrint('Error: ${e.toString()}');
      }
    }
/*
    polylines = [];

    for (int i = 0; i < urlWaypoints.length; i++) {
      Map<String, dynamic> apiData;
      apiData = await getRoutePoints(urlWaypoints[i]);
      routePoints = apiData["points"];
      await getRoutePoints(urlWaypoints[i]);
      polylines.add(Polyline(
          points: routePoints,
          color: const Color.fromARGB(255, 28, 97, 5),
          strokeWidth: 5));
    }
    setState(() {});
    return polylines;
    */
    throw ('error in callback');
  }

  Future<Map<String, dynamic>> addPolyLine(
      LatLng latLng1, LatLng latLng2) async {
    String waypoint =
        '${latLng1.longitude},${latLng1.latitude};${latLng2.longitude},${latLng2.latitude}';
    return await getRoutePoints(waypoint);
  }

  Future loadPolyLines() async {
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
      polylines.clear();
      waypoints = waypoints.substring(0, waypoints.length - 1);
      List<LatLng> points = await getPolylines(waypoints);
      Polyline polyline = Polyline(
          points: points, // polyline,
          color: _goodRoad ? Colors.red : const Color.fromARGB(255, 28, 97, 5),
          strokeWidth: 5);
      polylines.add(polyline);
    }
    setState(() {});
  }

  Future<Map<String, dynamic>> appendPolyline(
    LatLng latLng2,
  ) async {
    LatLng latLng1;
    Map<String, dynamic> apiData = {};
    if (_startLatLng == const LatLng(0.00, 0.00)) {
      _startLatLng = latLng2;
      return apiData;
    }
    if (polylines.length > 1) {
      // Let's assume simple add
      latLng1 = polylines[polylines.length - 1]
          .points[polylines[polylines.length - 1].points.length - 1];
    } else {
      latLng1 = _startLatLng;
    }
    apiData = await addPolyLine(latLng1, latLng2);
    polylines.add(Polyline(
        points: apiData["points"], // polyline,
        color: _goodRoad ? Colors.red : const Color.fromARGB(255, 28, 97, 5),
        strokeWidth: 5));
    setState(() {});
    return apiData;
  }

  Future<List<LatLng>> getPolylines(String waypoints) async {
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
          title: const Text(
            'MotaTrip',
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.blue,
          //flexibleSpace: const Text('Flexible Space'),
          bottom: _appState == AppState.createTrip && _showSearch
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(60),
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
            /*
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Load route',
              onPressed: () async {},
            ),
            */
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
/*
            IconButton(
              icon: const Icon(Icons.assistant_direction_sharp),
              tooltip: 'Enter route',
              onPressed: () async {
                await routeDialog(context, 3, routeCallback)
                    .then((result) async {
                  polylines = result;
                  await Future.delayed(const Duration(seconds: 5))
                      .then((_) => setState(() {}));
                });
              },
            ), */
          ],
        ),
        bottomNavigationBar: _handleBottomNavigationBar(),
        backgroundColor: Colors.grey[300],
        floatingActionButton: _handleFabs(),
        body: SingleChildScrollView(
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
        )));
  }

  ///
  addWaypoint() {
    LatLng pos = _animatedMapController.mapController.camera.center;
    if (insertAfter == -1 &&
        _pointsOfInterest.isNotEmpty &&
        _pointsOfInterest[0].type == 12) {
      appendPolyline(pos).then((data) {
        _addPointOfInterest(
            id, userId, 12, '${data["name"]}', '${data["summary"]}', 15.0, pos);
      });
    } else if (insertAfter > -1) {
      try {
        _singlePointOfInterest(context, pos, insertAfter).then((_) {
          loadPolyLines();
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
      result.add(_pointsOfInterest[i].hint == ''
          ? 'Point of interest - ${poiTypes[_pointsOfInterest[i].type]["name"]}'
          : _pointsOfInterest[i].hint);
      result.add(_pointsOfInterest[i].description);
    } else {
      result.add('Waypoint ${i + 1} -  ${_pointsOfInterest[i].description}');
      result.add(_pointsOfInterest[i].hint);
    }
    return result;
  }

  pointOfInterestRemove(int idx) async {
    /// Removing a poi:
    final PointOfInterest item = _pointsOfInterest.removeAt(idx);
    loadPolyLines();
    setState(() {});
  }

  /// _handleBottomNavigationBar()
  /// controls BottoNavigationBar
  BottomNavigationBar _handleBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _bnbIndex,
      showUnselectedLabels: true,
      selectedItemColor: Colors.white,
      unselectedItemColor: Color.fromARGB(255, 214, 211, 211),
      backgroundColor: Colors.blue,
      onTap: ((idx) async {
        _bnbIndex = idx;
        if (_bottomNavigationsBarIndex == 0) {
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
              _selectedMode[0] = true;
              _selectedMode[1] = false;
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
        } else if (_bottomNavigationsBarIndex == 1) {
          switch (idx) {
            case 0:
              _bottomNavigationsBarIndex = 0;
              _appState = AppState.home;
              break;
            case 1:
              _goodRoad = false;
              await addWaypoint().then(() {
                setState(() {});
              });
              break;
            case 2:
              _showTarget = true;
              LatLng pos = _animatedMapController.mapController.camera.center;
              _addPointOfInterest(id, userId, 15, '', '', 30.0, pos);
              break;
            case 3:
              // Handle great road
              _goodRoad = true;
              await addWaypoint().then(() {
                setState(() {
                  _goodRoad = false;
                });
              });
              break;
          }
        } else {
          switch (idx) {
            case 0:
              _bottomNavigationsBarIndex = 0;
              _appState = AppState.home;
              _bnbIndex = 0;
              // Home
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
        }
        setState(() {});
      }),
      items: _bottomNavigationsBarItems[_bottomNavigationsBarIndex],
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
            if (_speed > 0.01) ...[
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
                    _goodRoad = !_goodRoad;
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
            /*     onTap: (tapPos, LatLng latLng) {
                        _textFieldController.text = '';
                        popValue.dropdownIdx = -1;
                        popValue.text1 = '';
                        _displayTextInputDialog(context, latLng);
                        //   .then((value) {});
                      },
                      onLongPress: (tapPos, LatLng latLng) async {
                        if (!_showTarget) {
                          debugPrint("TAP $tapPos    $latLng");
                          appendPolyline(latLng).then((data) {
                            _addPointOfInterest(
                                id,
                                userId,
                                12,
                                '${data["name"]}',
                                '${data["summary"]}',
                                15.0,
                                latLng);
                          });
                          setState(() {});
                        }
                      }, */
            onMapReady: () {
              mapController.mapEventStream.listen((event) {});
            },
            onPositionChanged: (position, hasGesure) {
              if (_tracking) {
                updateTracking();
              }
              if (hasGesure) {
                _updateMarkerSize(position.zoom ?? 13.0);
              }
            },
            initialCenter: routePoints[0],
            initialZoom: 15,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
              maxZoom: 18,
            ),
            CurrentLocationLayer(
              followScreenPoint: const CustomPoint(0.0, 1.0),
              followScreenPointOffset: const CustomPoint(0.0, -60.0),
              // focalPoint: const CustomPoint(0.0, 1.0),
              followCurrentLocationStream:
                  _followCurrentLocationStreamController.stream,
              turnHeadingUpLocationStream:
                  _turnHeadingUpStreamController.stream,
              followOnLocationUpdate: _followOnLocationUpdate,
              turnOnHeadingUpdate: _turnOnHeadingUpdate,
              style: const LocationMarkerStyle(
                marker: DefaultLocationMarker(
                  child: Icon(
                    Icons.navigation,
                    color: Colors.white,
                  ),
                ),
                markerSize: Size(40, 40),
                markerDirection: MarkerDirection.heading,
              ),
            ),
            PolylineLayer(
              polylineCulling: false,
              polylines: polylines,
            ),
            MarkerLayer(markers: _pointsOfInterest),
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
      //  onPanUpdate: (DragUpdateDetails details) {
      onVerticalDragUpdate: (DragUpdateDetails details) {
        setState(() {
          mapHeight += details.delta.dy;

          //  debugPrint("mapHeight: ${mapHeight.toString()}");
          double height = (MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  kBottomNavigationBarHeight -
                  _dividerHeight) *
              0.93;

          mapHeight = mapHeight > height ? height : mapHeight;
          mapHeight = mapHeight < 20 ? 20 : mapHeight;

          listHeight = (height - mapHeight);
        });
      },
    );
  }

  SizedBox _showExploreDetail() {
    return SizedBox(
        height: listHeight,
        child: CustomScrollView(controller: _scrollController, slivers: [
          SliverPersistentHeader(
            pinned: true,
            floating: true,
            delegate: StickyMenuDeligate(
              options1: _exploreModes,
              states1: _selectedMode,
              options2: _exploreModes1,
              states2: _selectedMode1,
              onButtonPressed: actionToggleButton,
            ),
          ),
          SliverToBoxAdapter(
            child: _exploreDetailsHeader(),
          ),
          SliverReorderableList(
              itemBuilder: (context, index) {
                debugPrint('Index: $index');
                return _pointsOfInterest[index].type == 12
                    ? waypointTile(index)
                    : pointOfInterestTile(index);
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
              })
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
      imageUrls: ['assets/images/map.png', 'assets/images/splash.png'],
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
      imageUrls: [
        'assets/images/map.png',
        'assets/images/splash.png',
        'assets/images/CarGroup.png'
      ],
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

  Widget pointOfInterestTile(int index) {
    return Material(
      key: Key('$index'),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5))),
        title: _pointsOfInterest[index].description == ''
            ? const Text(
                'Add a point of interest',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text(_pointsOfInterest[index].description,
                style: const TextStyle(
                    color: Colors.black)), //getTitles(index)[0]),
        collapsedBackgroundColor: index.isOdd
            ? Colors.white
            : const Color.fromARGB(255, 174, 211, 241),
        backgroundColor: Colors.white,
        initiallyExpanded: _pointsOfInterest[index].description == '',
        onExpansionChanged: (expanded) {},
        leading: IconButton(
          iconSize: 25,
          icon: Icon(markerIcon(_pointsOfInterest[index].type)),
          onPressed: () async {
            setState(() {
              _poiDetailIndex = index;
              _animatedMapController.animateTo(
                  dest: _pointsOfInterest[index].point);
            });
          },
        ),
        children: [
          SizedBox(
              // height: 200,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 0, 30),
                  child: Column(children: <Widget>[
                    Row(children: [
                      Expanded(
                          flex: 10,
                          child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Type',
                              ),
                              value: _pointsOfInterest[index].type.toString(),
                              items: poiTypes
                                  .map((item) => DropdownMenuItem<String>(
                                        value: item['id'].toString(),
                                        child: Row(children: [
                                          Icon(
                                            IconData(item['iconMaterial'],
                                                fontFamily: 'MaterialIcons'),
                                            color:
                                                Color(item['colourMaterial']),
                                          ),
                                          Text('    ${item['name']}')
                                        ]),
                                      ))
                                  .toList(),
                              onChanged: (item) => _pointsOfInterest[index]
                                  .type = item == null ? -1 : int.parse(item))),
                      const Expanded(
                        flex: 8,
                        child: SizedBox(),
                      ),
                    ]),
                    Row(
                      children: [
                        Expanded(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 10, 10, 10),
                                child: TextFormField(
                                    initialValue:
                                        _pointsOfInterest[index].description,
                                    textAlign: TextAlign.start,
                                    keyboardType: TextInputType.streetAddress,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText:
                                          "What is the point of interest's name...",
                                      labelText: 'Point of interest name',
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    onChanged: (text) =>
                                        _pointsOfInterest[index].description =
                                            text)))
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                              child: TextFormField(
                                  textAlign: TextAlign.start,
                                  keyboardType: TextInputType.streetAddress,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Describe Point of Interest...',
                                    labelText: 'Point of interest description',
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  initialValue: _pointsOfInterest[index].hint,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onChanged: (text) => _pointsOfInterest[index]
                                      .hint = text //body = text
                                  )),
                        ),
                      ],
                    ),
                    Row(children: [
                      Align(
                          alignment: Alignment.topCenter,
                          child: ToggleButtons(
                            isSelected: _selectedImage,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            selectedBorderColor: Colors.blue[700],
                            selectedColor: Colors.white,
                            fillColor: Colors.blue[400],
                            color: Colors.blue[400],
                            constraints: const BoxConstraints(
                                minHeight: 40.0, minWidth: 70.0),
                            children: _imageModes,
                            onPressed: (int idx) async {
                              switch (idx) {
                                case 0:
                                  setState(() {
                                    _pointsOfInterest[index].child =
                                        RawMaterialButton(
                                            onPressed: () => Utility()
                                                .showAlertDialog(
                                                    context,
                                                    poiTypes.toList()[
                                                        _pointsOfInterest[index]
                                                            .type]['name'],
                                                    _pointsOfInterest[index]
                                                        .description),
                                            elevation: 2.0,
                                            fillColor: const Color.fromARGB(
                                                255, 224, 132, 10),
                                            // padding: const EdgeInsets.all(5.0),
                                            shape: const CircleBorder(),
                                            child: Icon(
                                              markerIcon(_pointsOfInterest[
                                                      index]
                                                  .type), //markerIcon(type),
                                              size: 25,
                                              color: Colors.blueAccent,
                                            ));
                                  });
                                  break;
                                case 1:
                                  // delete
                                  _pointsOfInterest.removeAt(index);
                                  break;
                                case 2:
                                  await ImagePicker()
                                      .pickImage(source: ImageSource.gallery)
                                      .then((pickedFile) {
                                    try {
                                      if (pickedFile != null) {
                                        _pointsOfInterest[index]
                                            .imageURIs
                                            .add(pickedFile.path);
                                      }
                                    } catch (e) {
                                      debugPrint(
                                          'Error getting image: ${e.toString()}');
                                    }
                                  });
                                  break;
                              }
                              setState(() {});
                            },
                          ))
                    ]),
                    if (_pointsOfInterest[index].imageURIs.isNotEmpty)
                      Row(children: <Widget>[
                        Expanded(
                            flex: 8,
                            child: SizedBox(
                                height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (int i = 0;
                                        i <
                                            _pointsOfInterest[index]
                                                .imageURIs
                                                .length;
                                        i++)
                                      SizedBox(
                                          width: 160,
                                          child: Image.file(File(
                                              _pointsOfInterest[index]
                                                  .imageURIs[i]))),
                                    const SizedBox(
                                      width: 30,
                                    ),
                                  ],
                                )))
                      ]),
                  ]))),
        ],
      ),
    );
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

  actionToggleButton(value) {
    setState(() {
      if (value < 2) {
        _bottomNavigationsBarIndex =
            _pointsOfInterest.isEmpty && value == 1 ? 2 : 1;
      }
      if (_exploreTracking || _pointsOfInterest.isEmpty) {
        _showTarget = value == 0;
        // !_exploreTracking;
        for (int i = 0; i < _exploreModes.length; i++) {
          _selectedMode[i] = i == value;
        }
      } else if (value == 2) {
        _startLatLng == const LatLng(0.00, 0.00);
        polylines.clear();
        _pointsOfInterest.clear();
        _goodRoad = false;
        _tracking = false;
      } else {
        for (int i = 0; i < _exploreModes1.length; i++) {
          _selectedMode1[i] = i == value;
        }
      }
    });
  }

  Future getImage(ImageSource source, PointOfInterest poi) async {
    await ImagePicker().pickImage(source: source).then((pickedFile) {
      setState(() {
        if (pickedFile != null) {
          poi.imageURIs.add(pickedFile.path);
        }
      });
    });
  }

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
        polylines.clear();
        polylines.add(Polyline(
            points: [
              LatLng(position.latitude, position.longitude)
            ], // polyline,
            color:
                _goodRoad ? Colors.red : const Color.fromARGB(255, 28, 97, 5),
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
          polylines[0].points.add(pos);
          lastLatLng = pos;
          _tripDistance += distance;
          if (_tripDistance >= 0.5) {
            _totalDistance += _tripDistance;
            _tripDistance = 0;
            _singlePointOfInterest(context, pos, -1,
                distance: _totalDistance, time: secsMoving / 60);
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

  locationLatLng(pos) {
    debugPrint(pos.toString());
    setState(() {
      _showSearch = false;
      _animatedMapController.animateTo(dest: pos);
    });
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
  final List<Widget> options1;
  final List<bool> states1;
  final List<Widget> options2;
  final List<bool> states2;

  StickyMenuDeligate({
    required this.onButtonPressed,
    required this.options1,
    required this.states1,
    required this.options2,
    required this.states2,
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
              isSelected: _exploreTracking || _pointsOfInterest.isEmpty
                  ? states1
                  : states2,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              selectedBorderColor: Colors.blue[700],
              selectedColor: Colors.white,
              splashColor: Colors.grey,
              fillColor: Colors.blue[400],
              color: Colors.blue[400],
              constraints:
                  const BoxConstraints(minHeight: 40.0, minWidth: 70.0),
              children: _exploreTracking || _pointsOfInterest.isEmpty
                  ? options1
                  : options2,
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
