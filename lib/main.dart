import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart';
import 'screens/dialogs.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

/*
https://techblog.geekyants.com/implementing-flutter-maps-with-osm     /// Shows how to implement markers and group them
https://stackoverflow.com/questions/76090873/how-to-set-location-marker-size-depend-on-zoom-in-flutter-map      
https://pub.dev/packages/flutter_map_location_marker
https://github.com/tlserver/flutter_map_location_marker
https://www.appsdeveloperblog.com/alert-dialog-with-a-text-field-in-flutter/   /// Shows text input dialog
https://fabricesumsa2000.medium.com/openstreetmaps-osm-maps-and-flutter-daeb23f67620  /// tapablePolylineLayer  
*/

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final start = TextEditingController();
  final end = TextEditingController();
  final mapController = MapController();
  bool isVisible = false;
  PopupValue popValue = PopupValue(-1, '', '');
  final navigatorKey = GlobalKey<NavigatorState>();
  List<Marker> markers = [];
  List<PointOfInterest> pointsOfInterest = [];
  int id = -1;
  int userId = -1;
  int driveId = -1;
  int type = -1;
  double iconSize = 35;
  LatLng startLatLng = LatLng(0.00, 0.00);

  late bool _navigationMode;
  late int _pointerCount;
  double _markerSize = 200.0;
  late FollowOnLocationUpdate _followOnLocationUpdate;
  late TurnOnHeadingUpdate _turnOnHeadingUpdate;

  late AlignOnUpdate _alignOnUpdate;

  late StreamController<double?> _followCurrentLocationStreamController;
  late StreamController<void> _turnHeadingUpStreamController;

  // List<LatLng> routePoints = [LatLng(52.05884, -1.345583)];
  List<LatLng> routePoints = [LatLng(51.478815, -0.611477)];

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
                          id, userId, iconIdx, desc, 30.0, latLng);
                    }
                    Navigator.of(context).pop();
                  });
                },
              ),
            ],
          );
        });
  }

  _addPointOfInterest(int id, int userId, int iconIdx, String desc, double size,
      LatLng latLng) {
    pointsOfInterest.add(PointOfInterest(
        context, id, userId, driveId, iconIdx, desc, size, size,
        markerPoint: latLng));
  }

  @override
  void initState() {
    super.initState();
    _navigationMode = false;
    _pointerCount = 0;
    _followOnLocationUpdate = FollowOnLocationUpdate.never;
    _turnOnHeadingUpdate = TurnOnHeadingUpdate.never;
    _followCurrentLocationStreamController = StreamController<double?>();
    _turnHeadingUpStreamController = StreamController<void>();
    _markerSize = 200.0;
  }

  @override
  void dispose() {
    _followCurrentLocationStreamController.close();
    _turnHeadingUpStreamController.close();
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
      _markerSize = 200.0 * (zoom / 13.0);
      for (int i = 0; i < pointsOfInterest.length; i++) {
        //    pointsOfInterest[i].height = _markerSize;
        //    pointsOfInterest[i].width = _markerSize;
      }
    });
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
      routePoints = await getRoutePoints(urlWaypoints[i]);
      polylines.add(Polyline(
          points: routePoints,
          color: const Color.fromARGB(255, 28, 97, 5),
          strokeWidth: 5));
    }
    setState(() {});
    return polylines;
  }

  Future<List<LatLng>> addPolyLine(LatLng latLng1, LatLng latLng2) async {
    String waypoint =
        '${latLng1.longitude},${latLng1.latitude};${latLng2.longitude},${latLng2.latitude}';
    return await getRoutePoints(waypoint);
  }

  Future insertPolyLine(LatLng latLng2) async {
    List<LatLng> polyline;
    LatLng latLng1;
    if (startLatLng == LatLng(0.00, 0.00)) {
      startLatLng = latLng2;
      return;
    }
    if (polylines.length > 1) {
      // Let's assume simple add
      latLng1 = polylines[polylines.length - 1]
          .points[polylines[polylines.length - 1].points.length - 1];
    } else {
      latLng1 = startLatLng;
    }
    polyline = await addPolyLine(latLng1, latLng2);
    polylines.add(Polyline(
        points: polyline,
        color: const Color.fromARGB(255, 28, 97, 5),
        strokeWidth: 5));
    setState(() {});
  }

  Future<List<LatLng>> getRoutePoints(String waypoints) async {
    dynamic router;
    List<LatLng> routePoints = [];

    /// http://router.project-osrm.org/route/v1/driving/-0.515525,51.43148;-1.2577262999999999,51.7520209?steps=true&annotations=true&geometries=geojson&overview=full
    var url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$waypoints?steps=true&annotations=true&geometries=geojson&overview=full');
    try {
      var response = await http.get(url);
      router =
          jsonDecode(response.body)['routes'][0]['geometry']['coordinates'];
    } catch (e) {
      debugPrint('Http error: ${e.toString()}');
    }

    debugPrint("router.length: ${router.length.toString()}");
    //  routePoints = [];
    for (int i = 0; i < router.length; i++) {
      var reep = router[i].toString();
      reep = reep.replaceAll("[", "");
      reep = reep.replaceAll("]", "");
      var lat1 = reep.split(',');
      var long1 = reep.split(",");
      routePoints.add(LatLng(double.parse(lat1[1]), double.parse(long1[0])));
    }
    return routePoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Routing',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.grey[500],
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.assistant_direction_sharp),
            tooltip: 'Enter route',
            onPressed: () async {
              await routeDialog(context, 3, routeCallback).then((result) async {
                polylines = result;
                await Future.delayed(const Duration(seconds: 5))
                    .then((_) => setState(() {}));
              });
            },
          ),
          IconButton(
              icon: const Icon(Icons.read_more),
              tooltip: 'Enter route',
              onPressed: () async {
                setState(() {});
              }),
        ],
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Visibility(
                    visible: true, //isVisible,

                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        onTap: (tapPos, LatLng latLng) {
                          _textFieldController.text = '';
                          popValue.dropdownIdx = -1;
                          popValue.text1 = '';
                          _displayTextInputDialog(context, latLng);
                          //   .then((value) {});
                        },
                        onLongPress: (tapPos, LatLng latLng) {
                          debugPrint("TAP $tapPos    $latLng");
                          _addPointOfInterest(
                              id,
                              userId,
                              12,
                              'Lat:${latLng.latitude} Long:${latLng.longitude}',
                              15.0,
                              latLng);
                          insertPolyLine(latLng);

                          setState(() {});
                        },
                        onMapReady: () {
                          mapController.mapEventStream.listen((event) {});
                        },
                        onPositionChanged: (position, hasGesure) {
                          if (hasGesure) {
                            _updateMarkerSize(position.zoom ?? 13.0);
                          }
                        },
                        initialCenter: routePoints[0],
                        initialZoom: 10,
                      ),
                      //      nonRotatedChildren: [
                      //        AttributionWidget.defaultWidget(
                      //            source: 'OpenStreetMap contributors',
                      //            onSourceTapped: null),
                      //      ],
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                          maxZoom: 18,
                        ),
                        CurrentLocationLayer(
                          followScreenPoint: const CustomPoint(0.0, 1.0),
                          followScreenPointOffset:
                              const CustomPoint(0.0, -60.0),
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
                        MarkerLayer(markers: pointsOfInterest),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
