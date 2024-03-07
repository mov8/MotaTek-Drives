import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';

import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
//import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

// import 'package:flutter_map/plugin_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart';
import 'screens/painters.dart';
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
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
  LatLng startLatLng = const LatLng(0.00, 0.00);
  late Size screenSize;
  late Size appBarSize;
  double mapHeight = 250;
  double listHeight = 100;
  bool showTarget = false;

  // late bool _navigationMode;
  // late int _pointerCount;
  // double _markerSize = 200.0;
  // late final _animatedMapController = AnimatedMapController(vsync: this);
  late AnimatedMapController _animatedMapController;
  late FollowOnLocationUpdate _followOnLocationUpdate;
  late TurnOnHeadingUpdate _turnOnHeadingUpdate;

  final _dividerHeight = 25.0;
//  double _ratio = 0.0; //0.6;
  // double _maxHeight = 100.0;

  // late AlignOnUpdate _alignOnUpdate;

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

  _addPointOfInterest(int id, int userId, int iconIdx, String desc, String hint,
      double size, LatLng latLng) {
    pointsOfInterest.add(PointOfInterest(
        context, id, userId, driveId, iconIdx, desc, hint, size, size,
        markerPoint: latLng));
  }

  @override
  void initState() {
    super.initState();
    // _navigationMode = false;
    // _pointerCount = 0;
    _followOnLocationUpdate = FollowOnLocationUpdate.never;
    _turnOnHeadingUpdate = TurnOnHeadingUpdate.never;
    _followCurrentLocationStreamController = StreamController<double?>();
    _turnHeadingUpStreamController = StreamController<void>();
    _animatedMapController = AnimatedMapController(vsync: this);
    //  _markerSize = 200.0;
    // screenSize = MediaQuery.of(context).size;
    // appBarSize = AppBar().preferredSize;, du
    // _maxHeight = MediaQuery.of(context).size.height * 0.6;
    mapHeight = 250.0;
    //(screenSize.height - appBarSize.height - _dividerHeight) * 0.9;
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
  }

  Future<Map<String, dynamic>> addPolyLine(
      LatLng latLng1, LatLng latLng2) async {
    String waypoint =
        '${latLng1.longitude},${latLng1.latitude};${latLng2.longitude},${latLng2.latitude}';
    return await getRoutePoints(waypoint);
  }

  Future<Map<String, dynamic>> insertPolyLine(LatLng latLng2) async {
    LatLng latLng1;
    Map<String, dynamic> apiData = {};
    if (startLatLng == const LatLng(0.00, 0.00)) {
      startLatLng = latLng2;
      return apiData;
    }
    if (polylines.length > 1) {
      // Let's assume simple add
      latLng1 = polylines[polylines.length - 1]
          .points[polylines[polylines.length - 1].points.length - 1];
    } else {
      latLng1 = startLatLng;
    }
    apiData = await addPolyLine(latLng1, latLng2);
    polylines.add(Polyline(
        points: apiData["points"], // polyline,
        color: const Color.fromARGB(255, 28, 97, 5),
        strokeWidth: 5));
    setState(() {});
    return apiData;
  }

//
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

    result["name"] = jsonResponse['routes'][0]['legs'][0]['summary'];
    result["distance"] = jsonResponse['routes'][0]['distance'];
    result["duration"] = jsonResponse['routes'][0]['duration'];
    result["summary"] = summary;
    result["points"] = routePoints;
    return result;
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
      // floatingActionButton: SeparatedColumn(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => (setState(() {
              showTarget = !showTarget;
            })),
            backgroundColor: Colors.blue,
            shape: const CircleBorder(),
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(
            height: 10,
          ),
          FloatingActionButton(
            onPressed: () async {
              // if (showTarget==true)  {
              if (showTarget) {
                LatLng pos = _animatedMapController.mapController.camera.center;
                insertPolyLine(pos).then((data) {
                  _addPointOfInterest(id, userId, 12, '${data["name"]}',
                      '${data["summary"]}', 15.0, pos);
                });
              }
            },
            backgroundColor: Colors.blue,
            shape: const CircleBorder(),
            child: const Icon(Icons.pin_drop),
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          SizedBox(
            //Column( //SingleChildScrollView(
            //   SafeArea(
            //     child: Padding(
            // padding: const EdgeInsets.all(12.0),
            // child: SingleChildScrollView(
            //    child: Column(
            //     children: [
            //        SizedBox(

            height: mapHeight,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _animatedMapController.mapController,
                  options: MapOptions(
                    onTap: (tapPos, LatLng latLng) {
                      _textFieldController.text = '';
                      popValue.dropdownIdx = -1;
                      popValue.text1 = '';
                      _displayTextInputDialog(context, latLng);
                      //   .then((value) {});
                    },
                    onLongPress: (tapPos, LatLng latLng) {
                      if (!showTarget) {
                        debugPrint("TAP $tapPos    $latLng");
                        insertPolyLine(latLng).then((data) {
                          _addPointOfInterest(id, userId, 12, '$data["name"]',
                              '$data["summary"]', 15.0, latLng);
                        });

                        setState(() {});
                      }
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
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                      maxZoom: 18,
                    ),
                    CurrentLocationLayer(
                      followScreenPoint: const CustomPoint(0.0, 1.0),
                      followScreenPointOffset: const CustomPoint(0.0, -60.0),
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
                if (showTarget) ...[
                  CustomPaint(
                    painter: TargetPainter(
                        top: mapHeight / 2,
                        left: MediaQuery.of(context).size.width / 2,
                        color: Colors.black),
                  )
                ],
              ],
            ),
            //    ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              height: _dividerHeight,

              width: MediaQuery.of(context).size.width,
              child: const Icon(
                Icons.drag_handle,
                color: Colors.blue,
              ),
              //    child: const RotationTransition(
              //      turns: AlwaysStoppedAnimation(0.25),
              //      child: Icon(Icons.drag_handle),
              //    ),
            ),
            onPanUpdate: (DragUpdateDetails details) {
              setState(() {
                //         _ratio += details.delta.dy;
                mapHeight += details.delta.dy;

                debugPrint("mapHeight: ${mapHeight.toString()}");
                double height = (MediaQuery.of(context).size.height -
                        AppBar().preferredSize.height -
                        _dividerHeight) *
                    0.93;

                mapHeight = mapHeight > height ? height : mapHeight;
                mapHeight = mapHeight < 20 ? 20 : mapHeight;

                listHeight = (height - mapHeight);
              });
            },
          ),
          // SingleChildScrollView(
          SizedBox(
            height: listHeight,
            //Column( //SingleChildScrollView(
            //   SafeArea(
            //     child: Padding(
            // padding: const EdgeInsets.all(12.0),
            //    child: SingleChildScrollView(
            //    child: Column(
            //     children: [
            //        SizedBox(

            //   width: MediaQuery.of(context).size.width,
            // child: Text('ListHeight $listHeight'),
/*
            child:
                ListView(padding: const EdgeInsets.all(8), children: <Widget>[
              Container(
                height: 50,
                color: Colors.amber[600],
                child: const Center(child: Text('Entry A')),
              ),
              Container(
                height: 50,
                color: Colors.amber[500],
                child: const Center(child: Text('Entry B')),
              ),
              Container(
                height: 50,
                color: Colors.amber[600],
                child: const Center(child: Text('Entry C')),
              ),
            ]),
*/
            child: pointsOfInterest.isNotEmpty
                ? ReorderableListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: <Widget>[
                      for (int i = 0; i < pointsOfInterest.length; i++)
                        //     Card(
                        //  /       key: ValueKey('$i'),
                        //         color: Colors.orangeAccent,
                        //          elevation: 2,
                        //          child: ListTile(
                        ListTile(
                            //  leading: _addRemoveWaypoint(
                            //      context, setState, i, pointsOfInterest),
                            trailing:
                                const Icon(Icons.assistant_direction_sharp),
                            key: ValueKey('$i'),
                            tileColor: i.isOdd ? Colors.white : Colors.blue,
                            leading: ReorderableDragStartListener(
                                index: i, child: const Icon(Icons.drag_handle)),
                            title: Text(getTitles(i)[0]),
                            subtitle: Text(getTitles(i)[1]),
                            onLongPress: () => {
                                  _animatedMapController.animateTo(
                                      dest: pointsOfInterest[i].point)
                                }),
                    ],
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final PointOfInterest item =
                            pointsOfInterest.removeAt(oldIndex);
                        pointsOfInterest.insert(newIndex, item);
                      });
                    })
                : const Text('No points of interest'),
            //   ),
          ),
          //   ),
          /*
          SingleChildScrollView(
            child: ReorderableListView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                children: <Widget>[
                  for (int i = 0; i < pointsOfInterest.length; i++)
                    ListTile(
                      key: Key('$i'),
                      tileColor: i.isOdd ? Colors.white : Colors.blue,
                      title: Text('Item $i'),
                    ),
                ],
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final PointOfInterest item =
                        pointsOfInterest.removeAt(oldIndex);
                    pointsOfInterest.insert(newIndex, item);
                  });
                }),
          ), */
        ],
      ),
      //  ),
      //  ),
      //   ),
    );
  }

  List<String> getTitles(int i) {
    List<String> result = [];
    if (pointsOfInterest.length == 1) {
      result.add('Waypoint 1 Trip Start');
      result.add('0.0 miles - (0 minutes)');
    } else if (i == 0) {
      result.add('Waypoint 1 ${pointsOfInterest[1].description.split(',')[0]}');
      result.add('0.0 miles - (0 minutes)');
    } else {
      result.add(
          'Waypoint ${i + 1} ${pointsOfInterest[i].description.split(',')[1]}');
      result.add(pointsOfInterest[i].hint);
    }
    return result;
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
/*
class WaypointList extends StatefulWidget {
  List<PointOfInterest> waypoints;
   final void Function(List<PointOfInterest>, int oldIndex, int newIndex)? onReorder;
   int? oldIndex;
   int? newIndex;
   Function? onReorderList;

  WaypointList({super.key, required this.waypoints, required this.oldIndex, required this.newIndex, required this.onReorderList});
  @override
  State<WaypointList> createState() => _WaypointListState();
}

class _WaypointListState extends State<WaypointList> {
  Widget build(BuildContext context) {
  return ReorderableListView(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      children: <Widget>[
        for (int i = 0; i < waypoints.length; i++)
          ListTile(
            key: Key('$i'),
            tileColor: i.isOdd ? Colors.white : Colors.blue,
            title: Text(
                'Item $i ${pointsOfInterest[i].description}'),
          ),
        //  setState((){});
      ],
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final PointOfInterest item =
              pointsOfInterest.removeAt(oldIndex);
          pointsOfInterest.insert(newIndex, item);
        });
      });

  )
  }
  
}

"{"code":"Ok","routes":[{"geometry":{"coordinates":[[-1.068075,51.437906],[-1.068075,51.437906]],"type":"LineString"},"legs":[{"s…"
*/
