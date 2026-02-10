import 'dart:async';
import 'dart:ui' as ui;
import 'package:uuid/uuid.dart';
// import 'dart:io';
import 'package:universal_io/universal_io.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
// import '/routes/create_trip.dart';
import 'package:geolocator/geolocator.dart';
import '/constants.dart' hide routes;
import '/classes/utilities.dart' as ut;
import '/helpers/create_trip_helpers.dart';
import 'package:image_picker/image_picker.dart';
import '/services/services.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import '/services/web_helper.dart' as wh;
import 'package:flutter/material.dart' hide Route;
// import '/tiles/tiles.dart';
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

//import 'package:path/path.dart';

String colorToHex(Color color) {
  final r = (color.r * 255.0).round().clamp(0, 255);
  final g = (color.g * 255.0).round().clamp(0, 255);
  final b = (color.b * 255.0).round().clamp(0, 255);
  return '#$r$g$b';
}

class Waypoint {
  List<double> latLng; // For MapLibre its [long, lat] - x y
  Color colour = Colors.blueGrey; //['#4287f5', '#fc0303'];
  Waypoint({required this.latLng, this.colour = Colors.blueGrey});
  String get hexColor => colorToHex(colour);
  List<double> get point => latLng;
}

class CreateTripValues {
  bool showMask = false;
  bool showTarget = false;
  bool autoCentre = false;
  bool stopStream = false;
  bool startStream = false;
  bool pauseStream = false;
  bool resumeStream = false;
  bool streamStarted = false;
  bool streamFinished = false;
  bool rotateMap = false;
  bool showProgress = false;
  int leadingWidget = 0;
  int initialLeadingWidget = 0;
  String title = 'Drives';
  MapHeights mapHeight = MapHeights.full;
  GoodRoad goodRoad = GoodRoad();
  List<double> lastLatLng = [0, 0];
  List<double> startLatLng = [0, 0];
  List<double> position = [0, 0];
  int pointOfInterestIndex = 0;
  bool setState = true;
  CreateTripValues();
  void manual() {
    showMask = false;
    showTarget = true; // false;
    autoCentre = false;
    title = 'Plan a new trip manually';
    leadingWidget = 1;
  }

  void automatic() {
    showMask = false;
    showTarget = false;
    autoCentre = true;
    title = 'Record a trip as you drive';
    leadingWidget = 1;
  }

  void editing() {
    showMask = false;
    showTarget = true; // false;
    autoCentre = true;
    title = 'Edit trip ';
    leadingWidget = 1;
  }

  void record() {
    showMask = false;
    showTarget = false;
    autoCentre = true;
    title = 'Track drive ';
    leadingWidget = 1;
    rotateMap = Setup().rotateMap;
    startFollowing();
  }

  stopFollowing() {
    stopStream = true;
    startStream = false;
    pauseStream = false;
    resumeStream = false;
    lastLatLng = position;
  }

  startFollowing() {
    stopStream = false;
    startStream = true;
    pauseStream = false;
    resumeStream = false;
    showTarget = false;
  }

  pauseFollowing() {
    stopStream = false;
    startStream = false;
    pauseStream = true;
    resumeStream = false;
    lastLatLng = position;
    mapHeight = MapHeights.full;
  }

  stopTracking() {
    stopStream = true;
    startStream = false;
    pauseStream = false;
    resumeStream = false;
    mapHeight = MapHeights.full;
  }

  resumeFollowing() {
    stopStream = false;
    startStream = false;
    pauseStream = false;
    resumeStream = true;
  }

  beforeWaypoint() {
    showMask = true;
    setState = true;
  }

  afterWaypoint() {
    showMask = false;
    setState = true;
    showTarget = true;
  }
}

class Progress {
  List currentPosition = const [0, 0];
  int nextManeuver = 0;
  int lastManeuver = 0;
  Progress({currentPosition, nextManeuver, lastManeuver});
}

class CurrentTripItem extends MyTripItem {
  CurrentTripItem._privateConstructor();
  bool isSaved = false;
  bool isTracking = false;
  TripState tripState = TripState.none;
  AppState appState = AppState.createTrip;
  TripActions tripActions = TripActions.none;
  TripType tripType = TripType.none;
  HighliteActions highliteActions = HighliteActions.none;
  String title = '';
  CreateTripValues tripValues = CreateTripValues();
  Progress progress = Progress();
  int goodRoadStartIndex = 0;
  int goodRoadStopIndex = 0;
  double size = 0.5;
  int files = 0;
  int downloaded = 0;
  Point nearestWaypoints = Point(0, 0);
  int nextManeuverIndex = 0;
  bool isChanged = false;
  int nearestRoute = 0;
  XFile? imageFile;
  List<Waypoint> waypoints = [];
  List<Photo> photos = [];
  ml.MapLibreMapController? mapController;
  //late Directions _directions;

  List<Map> titleData = [
    {
      'label': 'Create a new drive',
      'icon': Icons.add_location_alt_outlined,
      'states': [TripState.none, TripState.automatic, TripState.manual],
      'group': null,
    },
    {
      'label': 'Edit',
      'icon': Icons.edit,
      'states': [TripState.editing],
      'group': null,
    },
    {
      'label': 'Loaded',
      'icon': Icons.bookmark_outline,
      'states': [TripState.loaded, TripState.notFollowing],
      'group': null,
    },
    {
      'label': 'Group drive',
      'icon': Icons.group_outlined,
      'states': [TripState.loaded],
      'group': true,
    },
    {
      'label': 'Tracking drive',
      'icon': Icons.moving_outlined,
      'states': [
        TripState.recording,
        TripState.automatic,
        TripState.stoppedRecording,
        TripState.paused,
        TripState.startFollowing
      ],
      'group': false
    },
    {
      'label': 'Following drive',
      'icon': Icons.moving_outlined,
      'states': [
        TripState.following,
        TripState.stoppedFollowing,
        TripState.paused,
        TripState.startFollowing
      ],
      'group': false
    }
  ];

  List<Icon> tripTypeIcons = [
    Icon(Icons.add_location_alt_outlined),
    Icon(Icons.bookmark_outline),
    Icon(Icons.group_outlined)
  ];

  List<List<Waypoint>> backBuffer = [[]];
  int backBufferIndex = -1;

  static final _instance = CurrentTripItem._privateConstructor();

  factory CurrentTripItem() {
    return _instance;
  }

/*
  int id;
  String uri;
  String title;
  String subTitle;
  String body;
  String added;
  double score;
  int scored;
  int downloads;
  String authorUri;
  String author;
  List<Route> routes;
  List<Maneuver> maneuvers;
  List<GoodRoad> goodRoads;
  List<PointOfInterest> pointsOfInterest;
*/

  fromMyTripItem({required MyTripItem myTripItem}) {
    //id = myTripItem.id;
    //driveId = myTripItem.driveId;
    //index = myTripItem.index;
    //groupDriveId = myTripItem.groupDriveId;
    //driveUri = myTripItem.driveUri;
    //heading = myTripItem.title;
    // subHeading = myTripItem.subTitle;
    body = myTripItem.body;
    //published = myTripItem.added;
    //publisher = myTripItem.publisher;
    pointsOfInterest = myTripItem.pointsOfInterest;
    maneuvers = myTripItem.maneuvers;
    routes = myTripItem.routes;
    goodRoads = myTripItem.goodRoads;
    //images = myTripItem.images;
    score = myTripItem.score;
    //distance = myTripItem.distance;
    //closest = myTripItem.closest;
    //highlights = myTripItem.highlights;
    //showMethods = myTripItem.showMethods;
    //mapImage = myTripItem.mapImage;
    tripState = TripState.loaded;
    tripType = TripType.none;
  }

  MyTripItem clone() {
    MyTripItem myTripItem = MyTripItem(
      id: id,
      // driveId: driveId,
      // index: index,
      // groupDriveId: groupDriveId,
      // driveUri: driveUri,
      // heading: heading,
      // subHeading: subHeading,
      body: body,
      // published: published,
      // publisher: publisher,
      pointsOfInterest: pointsOfInterest,
      maneuvers: maneuvers,
      routes: routes,
      goodRoads: goodRoads,

      /// images: images,
      score: score,
      // distance: distance,
      // closest: closest,
      // highlights: highlights,
      // showMethods: showMethods,
    );
    // myTripItem.mapImage = mapImage;
    return myTripItem;
  }

  @override
  clearAll() {
    isSaved = false;
    // driveUri = '';
    // images = '';
    // groupDriveId = '';
    isTracking = false;
    tripType = TripType.none;
    tripState = TripState.none;
    tripActions = TripActions.none;
    highliteActions = HighliteActions.none;
    nearestWaypoints = Point(0, 0);
    backBuffer.clear();
    backBufferIndex = 0;
    //  return super.clearAll();
  }

  RouteDelta goodRoadStart = RouteDelta();
  RouteDelta routeDelta = RouteDelta();

  void load({required TripArguments arguments}) {
    fromMyTripItem(myTripItem: arguments.trip);
    // groupDriveId = arguments.groupDriveId;
    tripState = TripState.loaded;
    tripActions = TripActions.none;
    highliteActions = HighliteActions.none;
    // tripType = groupDriveId.isNotEmpty ? TripType.group : TripType.saved;
    tripValues.showTarget = false;
  }

/*
  Future<void> downloadTiles(
      {required BuildContext context, vmt.Style? style}) async {
    style ??= await VectorMapStyle().mapStyle();
    if (context.mounted) {
      /*   OfflineTiles offlineTiles = OfflineTiles(
          context: context,
          apiProvider: style!.providers.get('openmaptiles'),
          routes: routes);
      await offlineTiles.downloadMaps();
  */
    }
    return;
  }
*/
  String getTripTitle() {
    String title = 'Create a new drive';
    // IconData titleIcon = Icons.add_location_alt_outlined;
    if (tripValues.title.isNotEmpty) {
      // && heading.isEmpty) {
      title = tripValues.title;
    } else {
      for (int i = 1; i < titleData.length; i++) {
        if (titleData[i]['states'].contains(tripState)) {
          //  title = '${titleData[i]['label']} $heading';
          // titleIcon = titleData[i]['icon'];
          break;
        }
      }
    }

    return title;
  }

  List<List<double>> latLngsFromWaypoints({required List<Waypoint> waypoints}) {
    List<List<double>> points = [];
    for (int i = 0; i < waypoints.length; i++) {
      points.add(waypoints[i].latLng);
    }
    /*
    for (int i = 0; i < backBuffer[backBufferIndex].length; i++) {
      points.add(backBuffer[backBufferIndex][i].point);
    }
    */
    return points;
  }

  List<Widget> getActions(
      {required BuildContext context, Function(bool)? onUpdate}) {
    List<Widget> actions = [];
    if ([TripState.editing, TripState.manual].contains(tripState)) {
      if (backBuffer.length > 1) {
        actions.add(
          IconButton(
            onPressed: () async {
              if (++backBufferIndex < backBuffer.length) {
                if (backBuffer[backBufferIndex].length == 1) {
                  int start = -1;
                  for (int i = 0; i < pointsOfInterest.length; i++) {
                    if (pointsOfInterest[i].type == 17) {
                      start = i;
                      break;
                    }
                  }
                  if (start >= pointsOfInterest.length - 1 && start > -1) {
                    pointsOfInterest.removeAt(start);
                  }
                } else {
                  await replaceRoutes(
                      points: latLngsFromWaypoints(
                          waypoints: backBuffer[backBufferIndex]),
                      updateBuffer: false);
                }
                onUpdate!(true);
              }
            },
            icon: Icon(
              Icons.undo_outlined,
              color: backBufferIndex == backBuffer.length - 1
                  ? Colors.grey
                  : Colors.white,
            ),
          ),
        );
        if (backBuffer.length > 1) {
          actions.add(
            IconButton(
              onPressed: () async {
                if (--backBufferIndex >= 0) {
                  if (backBuffer[backBufferIndex].length == 1) {
                    waypoints.add(backBuffer[backBufferIndex][0]);
                  } else {
                    await replaceRoutes(
                        points: latLngsFromWaypoints(
                            waypoints: backBuffer[backBufferIndex]),
                        updateBuffer: false);
                    onUpdate!(true);
                  }
                }
              },
              icon: Icon(
                Icons.redo_outlined,
                color: backBufferIndex == 0 ? Colors.grey : Colors.white,
              ),
            ),
          );
        }
      }
    } else if (tripState == TripState.loaded) {
      actions.add(
        IconButton(
          onPressed: () async {
            //  await downloadTiles(context: context);
          },
          icon: Icon(
            Icons.map_outlined,
            color: Colors.white,
          ),
        ),
      );
    }
    actions.add(
      IconButton(
        onPressed: () => {},
        icon: Icon(Icons.help_outline_outlined),
      ),
    );
    return actions;
  }

  Future<bool> saveState() async {
    try {
      //     await saveLocal();
      //     Setup().appState =
      //         '{"route": 2, "id": $driveId, "saved": ${isSaved ? 1 : 0}, "isTracking": ${isTracking ? 1 : 0}, "tripState": ${tripState.index}, "tripActions": ${tripActions.index}}';
      Setup().setupToDb();
    } catch (e) {
      debugPrint("Can't save CurrentTrip state: ${e.toString}");
      return false;
    }
    return true;
  }

  Future<bool> restoreState() async {
    Map<String, dynamic> stateMap = jsonDecode(Setup().appState);
    if ((stateMap['route'] ?? -1) == 2) {
      try {
        //  await loadLocal(stateMap['id']);
        isSaved = (stateMap['isSaved'] ?? 0) == 1;
        isTracking = (stateMap['isTracking'] ?? 0) == 1;
        tripState = TripState.values[(stateMap['tripState'] ?? 0)];
        tripActions = TripActions.values[(stateMap['tripActions'] ?? 0)];
      } catch (e) {
        debugPrint('Error restoring State: ${e.toString()}');
      }
      final ImagePicker picker = ImagePicker();
      final LostDataResponse response = await picker.retrieveLostData();
      if (!response.isEmpty) {
        imageFile = response.files![0];
        if (imageFile != null) {
          //    debugPrint('Image file recovered');
        }
      }
      Setup().appState = '';
      Setup().setupToDb();
    }
    return true;
  }

  onBackPressed() {
    if (tripState == TripState.editing) {
      tripState = TripState.notFollowing;
      tripValues.title = ' '; //heading;
    } else {
      tripValues.title = 'Create a new trip';
      clearAll();
      tripState == TripState.none;
      tripValues.leadingWidget = 0;
      tripValues.mapHeight = MapHeights.full;
    }
  }

  Future<int> save() async {
    int status = -1;
    if (maneuvers.isEmpty) {
      List<List<double>> points = [];

      /// Have changed the way a tracked route is processed. Instead of trying to process
      /// the polylines to calculate the waypoints the new method drops a PointOfInterest every
      /// mile that can now be used to get the waypoints. This was because of the inconsistent
      /// spacing of the points in the polylines. Roundaboutes consume lots of ponts.
      /// It also has the added benefit of showing mile distance points along the route, and is
      /// consistent with the editing approach.
/*
      for (int i = 0; i < routes.length; i++) {
        points.addAll(routes[i].points);
      }
*/
      for (int i = 0; i < pointsOfInterest.length; i++) {
        if ([12, 17, 18].contains(pointsOfInterest[i].type)) {
          //         points.add(pointsOfInterest[i].point);
        }
      }
      await replaceRoutes(points: latLngsFromWaypoints(waypoints: waypoints));
      backBuffer.clear();
      backBufferIndex = -1;
    }
    isSaved = true;
    //  status = await saveLocal();
    return status;
  }

  void newPointOfInterest({required List<double> position, int type = 15}) {
    pointsOfInterest.add(PointOfInterest(
      //   point: position,
      type: type,
    ));
    isSaved = false;
  }

  loadBackBuffer() {
    backBuffer.clear();
    backBuffer.add(waypoints);
  }

  /// Waypoint handling routines
  /// addWaypoint() & deleteWaypoint()
  /// If tripState is TripState.manual then the waypoint is always added to the end
  /// of the route. If editing then can add anywhere.
  ///   Can extend the start or end or used to modify the route
  ///   The two highlighted waypoints act as anchors when editing
  ///   If the route is highlighted then the waypoint will be added as an anchor
  /// index = -1: extend start  0: insert in middle  1: extend end
/*
  addWaypoint(
      {int index = 1, required LatLng point, bool revisit = false}) async {
    List<LatLng> points = extractWaypoints(pointsOfInterest: pointsOfInterest);
    int insertAt = points.length;
    if (points.isEmpty) {
      pointsOfInterest.add(
        PointOfInterest(
          type: 17,
          waypoint: 0,
          point: point,
        ),
      );
      backBuffer.add([point]);
      backBufferIndex = 0;
    } else {
      if (revisit) {
        insertAt = 0;
      } else {
        if (tripState == TripState.editing) {
          insertAt = index == 1 ? points.length : 0;
          if ((nearestWaypoints.y > 0 || nearestWaypoints.x > 0) &&
              index == 0) {
            if (nearestWaypoints.y > nearestWaypoints.x) {
              insertAt = nearestWaypoints.x.toInt() + 1;
            } else {
              insertAt = nearestWaypoints.y.toInt() + 1;
            }
          }
        }
      }
      points.insert(insertAt, point);
      await replaceRoutes(points: points);
    }
    isSaved = false;
  }
*/
  addWaypoint(
      {int index = 1,
      required List<double> point,
      bool revisit = false}) async {
    int insertAt = waypoints.length;
    ml.LatLng target = mapController!.cameraPosition!.target;
    List<double> point = [target.longitude, target.latitude];
    List<Map<String, dynamic>> features = [];
    Waypoint waypoint = Waypoint(latLng: point);
    if (waypoints.isEmpty) {
      waypoints.add(Waypoint(latLng: point));
      backBuffer.add([waypoints.last]);
      backBufferIndex = 0;
    } else {
      if (revisit) {
        insertAt = 0;
      } else {
        if (tripState == TripState.editing) {
          insertAt = index == 1 ? waypoints.length : 0;
          if ((nearestWaypoints.y > 0 || nearestWaypoints.x > 0) &&
              index == 0) {
            if (nearestWaypoints.y > nearestWaypoints.x) {
              insertAt = nearestWaypoints.x.toInt() + 1;
            } else {
              insertAt = nearestWaypoints.y.toInt() + 1;
            }
          }
        }
      }
      waypoints.insert(insertAt, Waypoint(latLng: point));
      features = await replaceRoutes(
          points: latLngsFromWaypoints(waypoints: waypoints));
    }
    //

    /*
    TODO: Investigate using addSymbol - should be quicker

    Symbol? myWaypoint;

        void placeWaypoint(LatLng position) async {
          if (myWaypoint == null) {
            // Create it the first time
            myWaypoint = await mapController.addSymbol(
              SymbolOptions(
                geometry: position,
                iconImage: "marker-15", // Ensure this icon exists in your style
                iconSize: 1.5,
              ),
            );
          } else {
            // 2. Efficiently update its position
            mapController.updateSymbol(
              myWaypoint!,
              SymbolOptions(geometry: position),
            );
          }
        }
    
     */

    List lastPoint = [];
    if (features.isNotEmpty) {
      lastPoint = features.last['geometry']['coordinates'].last;
    }

    for (int i = 0; i < waypoints.length; i++) {
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": i == waypoints.length - 1 && lastPoint.isNotEmpty
              ? lastPoint
              : waypoints[i].point
        },
        "id": 'wp${i + 1}',
        "group": "shield",
        "properties": {"item": "waypoint", "number": i + 1, "group": 'shield'}
      });
    }

    await mapController!.setGeoJsonSource(
        "route-data", {"type": "FeatureCollection", "features": features});

    isSaved = false;
  }

//           await _mapController!.setGeoJsonSource("route-data", geoJson);

  deleteWaypoint({required List<double> position}) async {
    int index = -1;
    for (int i = 0; i < pointsOfInterest.length; i++) {
      if ([12, 17, 18, 19].contains(pointsOfInterest[i].type) &&
          Geolocator.distanceBetween(
                  pointsOfInterest[i].point.y.toDouble(),
                  pointsOfInterest[i].point.x.toDouble(),
                  position[1],
                  position[0]) <
              200) {
        index = i;
        break;
      }
    }
    if (index >= 0) {
      waypoints.removeAt(index);

      await replaceRoutes(points: latLngsFromWaypoints(waypoints: waypoints));

      isSaved = false;
    }
  }

  /// reorderWaypoints() generates the list of PointsOfInterest that
  /// include the waypoints in the correct order.

  List<PointOfInterest> reorderWaypoints(
      {List<List<double>> highlight = const [], bool revisit = false}) {
    List<PointOfInterest> reorderedPointsOfInterest = [];
    for (int i = 0; i < pointsOfInterest.length; i++) {
      if (![12, 17, 18, 19].contains(pointsOfInterest[i].type)) {
        reorderedPointsOfInterest.add(pointsOfInterest[i]);
      }
    }
    int wpIndex = 0;

    /// first maneuver always 'depart' last maneuver 'always' arrive
    for (int i = 0; i < maneuvers.length; i++) {
      if (['depart', 'arrive'].contains(maneuvers[i].type) ||
          i == maneuvers.length - 1) {
        int wpType = 12;
        wpType = wpIndex == maneuvers.length - 1 ? 18 : wpType;
        wpType = wpIndex == 0 ? 17 : wpType;
        wpType = revisit ? 19 : wpType;
        int colourIndex = highlight.contains(maneuvers[i].point)
            ? Setup().highlightedColour
            : 3;
        reorderedPointsOfInterest.add(
          PointOfInterest(
            type: wpType,
            //point: maneuvers[i].point,
          ),
        );
      }
    }

    pointsOfInterest = [];
    pointsOfInterest.addAll(reorderedPointsOfInterest);
    return pointsOfInterest;
  }
/*
  int waypointType({required List<LatLng> waypoints, required int index}) {
    if (index == 0) return 17;
    if (index == waypoints.length - 1) return 18;
    return 12;
  }

*/

  void checkWaypoints({required List<PointOfInterest> pointsOfInterest}) {}
/*
  List<LatLng> extractWaypoints(
      {required List<PointOfInterest> pointsOfInterest}) {
    List<LatLng> points = [];
    pointsOfInterest.sort((a, b) => a.waypoint.compareTo(b.waypoint));
    int waypoint = 0;
    for (int i = 0; i < pointsOfInterest.length; i++) {
      if ([12, 17, 18, 19].contains(pointsOfInterest[i].type)) {
        pointsOfInterest[i].waypoint = waypoint++;
        pointsOfInterest[i] =
            PointOfInterest.clone(pointOfInterest: pointsOfInterest[i]);
        points.add(pointsOfInterest[i].point);
      }
    }
    return points;
  }
*/
  /// replaceRoutes() gets the maneuvers from a list of points.
  /// It ensures that everything is in the same order as the router
  /// has supplied.
  Future<List<Map<String, dynamic>>> replaceRoutes(
      {required List<List<double>> points,
      bool updateBuffer = true,
      bool revisit = false}) async {
    List<Map<String, dynamic>> features = [];
    if (waypoints.length > 1) {
      try {
        if (updateBuffer) {
          backBuffer.insert(0, waypoints);
          if (backBuffer.length > 10) {
            backBuffer.removeAt(10);
          }
          backBufferIndex = 0;
        }
        Map<String, dynamic> routeData =
            await getRoutePoints(points: points, addPoints: true);
        if ((routeData["msg"] ?? " ") != "Error") {
          maneuvers = [];
          int wps = 0;
          features = routeData['routes'];

          /// Ensure that waypoints don't have both "arrive" and "depart"
          for (int i = 0; i < routeData['maneuvers'].length; i++) {
            wps = ['arrive', 'depart'].contains(routeData['maneuvers'][i].type)
                ? wps + 1
                : wps;
            bool add = i == 0;
            if (!add) {
              add = !(['arrive', 'depart']
                      .contains(routeData['maneuvers'][i].type) &&
                  ['arrive', 'depart']
                      .contains(routeData['maneuvers'][i - 1].type));
            }
            if (add) {
              maneuvers.add(routeData['maneuvers'][i]);
            }
          }

          routes = [];

          // Update the map with the new route.

          //  addRoute(routeData['points']);

          /// Add next 2 lines to ensure the waypoint can be extracted from the maneuvers
          maneuvers[maneuvers.length - 1].type = 'arrive';
          maneuvers[maneuvers.length - 1].point = waypoints.last.latLng;
          List<PointOfInterest> pointsOfInterest =
              reorderWaypoints(revisit: revisit);
        } else {
          routes = [];
        }
      } catch (e) {
        developer.log('Error replaceRoutes() ${e.toString()}');
      }
    }
    return features;
  }
/*
    Future<void> replaceRoutes(
      {required List<LatLng> points,
      bool updateBuffer = true,
      bool revisit = false}) async {
    if (points.length > 1) {
      if (updateBuffer) {
        backBuffer.insert(0, points);
        if (backBuffer.length > 10) {
          backBuffer.removeAt(10);
        }
        backBufferIndex = 0;
      }
      Map<String, dynamic> routeData =
          await getRoutePoints(points: points, addPoints: true);
      if ((routeData["msg"] ?? " ") != "Error") {
        maneuvers.clear();
        int wps = 0;

        /// Ensure that waypoints don't have both "arrive" and "depart"
        for (int i = 0; i < routeData['maneuvers'].length; i++) {
          wps = ['arrive', 'depart'].contains(routeData['maneuvers'][i].type)
              ? wps + 1
              : wps;
          bool add = i == 0;
          if (!add) {
            add = !(['arrive', 'depart']
                    .contains(routeData['maneuvers'][i].type) &&
                ['arrive', 'depart']
                    .contains(routeData['maneuvers'][i - 1].type));
          }
          if (add) {
            maneuvers.add(routeData['maneuvers'][i]);
          }
        }

        routes.clear();
        addRoute(List<List<double>>(
            points: routeData['points'],
            color: colourList[Setup().routeColour],
            borderColor: colourList[Setup().routeColour],
            strokeWidth: 5));

        /// Add next 2 lines to ensure the waypoint can be extracted from the maneuvers
        maneuvers[maneuvers.length - 1].type = 'arrive';
        maneuvers[maneuvers.length - 1].location = points[points.length - 1];
        reorderWaypoints(revisit: revisit);
      } else {
        routes.clear();
      }
    }
  }
*/

  Future<void> reverseRoute() async {
    List<Waypoint> points = backBuffer[0];
    backBuffer.insert(0, points.reversed.toList());
    await replaceRoutes(points: latLngsFromWaypoints(waypoints: backBuffer[0]));
  }

  /// Recalculate route
  /// aims:
  ///   1 maintain all the maneuvers already passed
  ///   3 rejoin the route at the nearest sensible waypoint - type arrive
  ///
  Future<bool> changeRoute(
      {required List<double> position,
      int lastManeuverIndex = 0,
      int routeIndex = 0,
      int pointIndex = 0}) async {
    List<List<double>> points = [];

    for (int i = 0; i <= lastManeuverIndex; i++) {
      if (['depart', 'arrive'].contains(CurrentTripItem().maneuvers[i].type)) {
        points.add([
          CurrentTripItem().maneuvers[i].point[1],
          CurrentTripItem().maneuvers[i].point[0]
        ]);
      }
    }

    /// now add current position as a waypoint
    points.add([
      position[0],
      position[1],
    ]);

    /// Now look for closest waypoint to rejoin the route
    double distance = 999999999999;
    int nextManeuver = 0;
    for (int i = lastManeuverIndex + 1; i < maneuvers.length; i++) {
      if (maneuvers[i].type == 'arrive' || i == maneuvers.length - 1) {
        double delta = Geolocator.distanceBetween(position[1], position[0],
            maneuvers[i].point[1], maneuvers[i].point[0]);
        if (delta < distance) {
          delta = distance;
          nextManeuver = i;
        }
      }
    }

    /// Complete list of waypoints to feed the router
    for (int i = nextManeuver; i < maneuvers.length; i++) {
      if (maneuvers[i].type == 'arrive' || i == maneuvers.length - 1) {
        points.add(maneuvers[i].point);
      }
    }

    if (points.length > 2) {
      Map<String, dynamic> tripData = await getRoutePoints(points: points);
      //  clearRoutes();
      //  addRoute(tripData['points']);
      maneuvers = tripData['maneuvers'];
    }
    return points.length > 2;
  }

  void startGoodRoad() {
    goodRoadStart.pointIndex = routeDelta.pointIndex;

//    goodRoads.add(Route(points: []));
    goodRoadStart.routeIndex = goodRoads.length - 1;
//    tripValues.goodRoad.isGood = true;
    highliteActions = HighliteActions.greatRoadStarted;
  }

  void goodRoadEnd() async {
    isSaved = false;
    highliteActions = HighliteActions.none;
    goodRoadStart.pointIndex = -1;
    //   tripValues.goodRoad.isGood = false;
  }

/*
  void changePosition(
      {required LatLng position, required Function(bool) onChange}) {
    isChanged = false;
    tripValues.position = position;
    HighliteActions currentHighlite = highliteActions;
    highliteActions = HighliteActions.none;
    Point currentNearestWaypPoints = nearestWaypoints;
    //   highliteActions = HighliteActions.none;
    if ([TripState.manual, TripState.editing].contains(tripState)) {
      Map<String, dynamic> waypointPositions =
          findNearestWaypoints(position: position);
      if ((waypointPositions['nearest'] ?? 1000) < 200) {
        highliteActions = HighliteActions.waypointHighlited;
      } else if (tripState == TripState.editing) {
        highlightNearestWaypoints(
            position: position,
            nearestIndex: waypointPositions['nearestIndex'],
            nextNearestIndex: waypointPositions['nextNearestIndex']);
      }
      routeDelta = findNearestRoute(routes: routes, position: position);
      highlightNearestRoute(routeData: routeDelta);
      if (goodRoadStart.pointIndex > -1) {
        List<LatLng> newList;
        if (routeDelta.pointIndex > goodRoadStart.pointIndex) {
          newList = routes[goodRoadStart.routeIndex]
              .points
              .sublist(goodRoadStart.pointIndex, routeDelta.pointIndex + 1);
        } else {
          newList = routes[goodRoadStart.routeIndex]
              .points
              .sublist(routeDelta.pointIndex, goodRoadStart.pointIndex + 1);
        }
        goodRoads.last.points.clear();
        goodRoads.last.points.addAll(newList);
      }
    }
    onChange(highliteActions != currentHighlite ||
        currentNearestWaypPoints != nearestWaypoints);
  }
*/
/*
  Map<String, dynamic> findNearestWaypoints({required LatLng position}) {
    double nearest = 9999999;
    double nextNearest = 9999999;
    int nearestIndex = -1;
    int nextNearestIndex = -1;

    for (int i = 0; i < pointsOfInterest.length; i++) {
      if ([12, 17, 18, 19].contains(pointsOfInterest[i].type)) {
        double distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            pointsOfInterest[i].point.latitude,
            pointsOfInterest[i].point.longitude);
        if (distance < nextNearest) {
          if (distance < nearest) {
            nextNearest = nearest;
            nextNearestIndex = nearestIndex;
            nearest = distance;
            nearestIndex = i;
          } else {
            nextNearest = distance;
            nextNearestIndex = i;
          }
        }
        pointsOfInterest[i] = PointOfInterest.clone(
            pointOfInterest: pointsOfInterest[i], colourIndex: 3);
      }
    }
    nearestWaypoints = Point(nearestIndex, nextNearestIndex);
    return {
      'nearest': nearest,
      'nearestIndex': nearestIndex,
      'nextNearest': nextNearest,
      'nextNearestIndex': nextNearestIndex
    };
  }
*/
/*
  void highlightNearestWaypoints(
      {required List position,
      required int nearestIndex,
      required int nextNearestIndex}) {
    developer.log(
        'nearestIndex: $nearestIndex   nextNearestIndex: $nextNearestIndex',
        name: '_waypoint');
    if (nearestIndex > -1) {
      pointsOfInterest[nearestIndex] = PointOfInterest.clone(
          pointOfInterest: pointsOfInterest[nearestIndex],
          colourIndex: Setup().highlightedColour);
    }
    if (nextNearestIndex > -1) {
      pointsOfInterest[nextNearestIndex] = PointOfInterest.clone(
          pointOfInterest: pointsOfInterest[nextNearestIndex],
          colourIndex: Setup().highlightedColour);
    }

    return;
  }

  RouteDelta findNearestRoute(
      {required List<List<List<double>>> routes,
      required List position,
      RouteDelta? routeDelta,
      int trigger = 100}) {
    int distance = 200000;
    routeDelta ??= RouteDelta();
    routeDelta.point = [position[1], position[0]];
    routeDelta.routeIndex = -1;
    routeDelta.distance = 200000;
    routeDelta.pointIndex = -1;
    for (int i = 0; i < routes.length; i++) {
      List<List<double>> route = routes[i];
      for (int j = 0; j < route.length; j++) {
        distance = Geolocator.distanceBetween(
                position[1],
                position[0],
                route[j][1], // Lat
                route[j][0]) // Lng
            .toInt();
        if (distance < routeDelta.distance) {
          routeDelta.distance = distance;
          routeDelta.pointIndex = j;
          routeDelta.point = route[j];
        } else if (distance <= trigger) {
          routeDelta.routeIndex = i;
          routeDelta.pointIndex = j;
          break;
        }
      }
    }
    return routeDelta;
  }

  highlightNearestRoute({required RouteDelta routeData}) {
    if (highliteActions != HighliteActions.waypointHighlited) {
      highliteActions = highliteActions == HighliteActions.routeHighlited
          ? HighliteActions.none
          : highliteActions;
      for (int i = 0; i < routes.length; i++) {
        if (routeData.routeIndex == i) {
          // routes[i].borderColor = colourList[Setup().selectedColour];
          // routes[i].color = colourList[Setup().selectedColour];
          highliteActions = HighliteActions.routeHighlited;
        } else {
          // routes[i].borderColor = colourList[Setup().routeColour];
          // routes[i].color = colourList[Setup().routeColour];
        }
      }
    }
  }
  */
}

class MyTripItem {
  int id;
  String uri;
  String driveUri;
  String title;
  String subTitle;
  String body;
  String added;
  double score;
  int scored;
  int downloads;
  String authorUri;
  String author;
  List<Map<String, dynamic>> routes;
  // List<Route> routes;
  List<Maneuver> maneuvers = [];
  List<GoodRoad> goodRoads = [];
  List<PointOfInterest> pointsOfInterest = [];
  String images;
  MyTripItem({
    this.id = -1,
    this.uri = '',
    this.driveUri = '',
    this.title = '',
    this.subTitle = '',
    this.body = '',
    this.added = '',
    this.score = 0,
    this.scored = 0,
    this.downloads = 0,
    this.authorUri = '',
    this.author = '',
    this.routes = const [],
    this.maneuvers = const [],
    this.goodRoads = const [],
    this.pointsOfInterest = const [],
    this.images = '',
  });

  factory MyTripItem.fromJson({required Map<String, dynamic> jsonObject}) {
    List<Map<String, dynamic>> routes = jsonObject["routes"];
    // routesFromJson(jsonList: jsonObject["routes"]);
    List<Maneuver> maneuvers =
        maneuversFromJson(jsonList: jsonObject["maneuvers"]);
    List<GoodRoad> goodRoads =
        goodRoadsFromJson(jsonList: jsonObject["good_roads"]);
    List<PointOfInterest> pointsOfInterest =
        pointsOfInterestFromJson(jsonList: jsonObject["points_of_interest"]);
    return MyTripItem(
      id: -1,
      uri: jsonObject["uri"] ?? "",
      title: jsonObject["title"] ?? "",
      subTitle: jsonObject["sub_title"] ?? "",
      body: jsonObject["body"] ?? "",
      added: jsonObject["added"] ?? "",
      score: jsonObject["score"] ?? 0,
      scored: jsonObject["scored"] ?? 0,
      downloads: jsonObject["downloads"] ?? 0,
      authorUri: jsonObject["author_uri"] ?? "",
      author: jsonObject["author"] ?? "",
      routes: routes,
      maneuvers: maneuvers,
      goodRoads: goodRoads,
      pointsOfInterest: pointsOfInterest,
    );
  }

  saveLocal() {
    return;
  }

  publish() {
    return;
  }

  String getPublishedDate({String noPrompt = ''}) {
    return added == '' ? noPrompt : added;
  }

  get distanceAway => 1;

  get distance => 10;

  get showMethods => false;
}

class MyTripItemOld {
  int id;
  int driveId;
  int index;
  String groupDriveId;
  String driveUri;
  String heading;
  String subHeading;
  String body;
  String published;
  String publisher;
  List<PointOfInterest> pointsOfInterest = [];
  List<Maneuver> maneuvers = [];
  List<Route> routes = [];
  List<Route> goodRoads = [];
  List<Follower> following = [];
  String images;
  double score;
  double distance;
  double distanceAway;
  int closest;
  int highlights;
  bool showMethods;
  bool selected;
  ui.Image? mapImage;

  MyTripItemOld({
    this.id = -1,
    this.driveId = -1,
    this.index = -1,
    this.driveUri = '',
    this.heading = '',
    this.subHeading = '',
    this.body = '',
    this.published = '',
    this.publisher = '',
    pointsOfInterest,
    following,
    maneuvers,
    routes,
    goodRoads,
    this.images = '',
    this.score = 5,
    this.distance = 0,
    this.distanceAway = 0,
    this.closest = 12,
    this.highlights = 0,
    this.groupDriveId = '',
    this.showMethods = false,
    this.selected = false,
  })  : pointsOfInterest = pointsOfInterest ?? [],
        maneuvers = maneuvers ?? [],
        routes = routes ?? [],
        following = following ?? [],
        goodRoads = goodRoads ?? [];

  clearAll() {
    id = -1; // These 2 lines were commented out
    driveId = -1; // Not sure why
    heading = '';
    subHeading = '';
    body = '';
    published = '';

    pointsOfInterest.clear();
    maneuvers.clear();
    routes.clear();
    goodRoads.clear();
    images = '';
    score = 0;
    distance = 0;
  }

  loadGroup() async {}

  // clearRoutes() {
  //   routes.clear();
//  }

  initialise(pointsOfInterest, maneuvers, routes, goodRoads) {
    this.pointsOfInterest = pointsOfInterest;
    this.maneuvers = maneuvers;
    this.routes = routes;
    this.goodRoads = goodRoads;
  }

  // DateFormat dateFormat = DateFormat("dd MMM yyyy");

  String getPublishedDate(
      {String yesPrompt = 'saved on', String noPrompt = 'not published'}) {
    try {
      return "$yesPrompt ${dateFormat.format(DateTime.parse(published))} ${driveUri.isEmpty ? 'but not published' : 'and published'}";
    } catch (e) {
      return noPrompt;
    }
  }

  void addPointOfInterest(PointOfInterest pointOfInterest) {
    pointsOfInterest.add(pointOfInterest);
  }

  void insertPointOfInterest(PointOfInterest pointOfInterest, int index) {
    pointsOfInterest.insert(index, pointOfInterest);
  }

  void removePointOfInterestAt(int index) {
    int id = pointsOfInterest[index].id;
    pointsOfInterest.removeAt(index);
    if (id > -1) {
      getPrivateRepository().deletePointOfInterestById(id);
    }
  }

  void movePointOfInterest(int oldIndex, int newIndex) {
    PointOfInterest pointOfInterest = pointsOfInterest.removeAt(oldIndex);
    pointsOfInterest.insert(newIndex, pointOfInterest);
  }

  void clearPointsOfInterest() {
    pointsOfInterest.clear();
  }

  void addManeuver(Maneuver maneuver) {
    maneuvers.add(maneuver);
  }

  void addManeuvers(List<Maneuver> maneuvers) {
    maneuvers = maneuvers;
  }

  void clearManeuvers() {
    maneuvers.clear();
  }

  void addRoute(Route route) {
    routes.add(route);
  }

  void clearRoutes() {
    routes.clear();
  }

  void insertRoute(Route route, int index) {
    routes.insert(index, route);
  }

  void addGoodRoad(Route route) {
    goodRoads.add(route);
  }

  void clearGoodRoads() {
    goodRoads.clear();
  }

  void insertGoodRoad(Route route, int index) {
    goodRoads.insert(index, route);
  }

  double updateDistance() {
    double distance = 0;
    for (int i = 0; i < maneuvers.length; i++) {
      distance += maneuvers[i].distance;
    }
    distance = distance * metersToMiles;
    this.distance = double.parse(distance.toStringAsFixed(2));
    return this.distance;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driveUri': driveUri,
      //   'groupUri': groupUri,
      'heading': heading,
      'subHeading': subHeading,
      'body': body,
      'published': published,
      'pointsOfInterest': pointsOfInterest.length,
      'images': images,
      'score': score,
      'distance': distance,
      'closest': closest,
    };
  }

  Map<String, dynamic> toDrivesMap() {
    return {
      'id': id,
      'uri': driveUri,
      'title': heading,
      'sub_title': subHeading,
      'body': body,
      'added': DateTime.now().toIso8601String(),
      'points_of_interest': pointsOfInterest.length,
      'distance': distance,
    };
  }

  Map<String, dynamic> myTripToMap() {
    List<Map<String, dynamic>> pointsOfInterestMap = [{}];
    List<Map<String, dynamic>> maneuversMap = [{}];
    List<Map<String, dynamic>> routesMap = [{}];
    List<Map<String, dynamic>> goodRoadsMap = [{}];

    double maxLat = -90;
    double minLat = 90;
    double maxLong = -180;
    double minLong = 180;

    String getUuid() {
      String uuidString = Uuid().v7();
      return uuidString.replaceAll(RegExp(r'-'), '');
    }

    if (driveUri.isEmpty) {
      driveUri = getUuid();
    }
    for (PointOfInterest pointOfInterest in pointsOfInterest) {
      //  pointOfInterest.url = getUuid();
      //  pointsOfInterestMap.add(pointOfInterest.toApiMap());
    }
    for (Maneuver maneuver in maneuvers) {
      //    Map<String, dynamic> maneuverMap = maneuver.toMap();
      //    maneuverMap['drive_uri'] = driveUri;
      maneuversMap.add(maneuver.toMap());
      maxLat = maneuver.point[1] > maxLat ? maneuver.point[1] : maxLat;
      minLat = maneuver.point[1] < minLat ? maneuver.point[1] : minLat;
      maxLong = maneuver.point[0] > maxLong ? maneuver.point[0] : maxLong;
      minLong = maneuver.point[0] < minLong ? maneuver.point[0] : minLong;
    }
    for (Route route in routes) {
      routesMap.add(routeToMap(route: route));
    }
    for (Route goodRoad in goodRoads) {
      routesMap.add(routeToMap(route: goodRoad));
    }

    Map<String, dynamic> tripMap = {
      'drive_uri': driveUri,
      'title': heading,
      'sub_title': subHeading,
      'body': body,
      'published': published,
      'publisher': publisher,
      'points_of_interest': pointsOfInterestMap,
      'maneuvers': maneuversMap,
      'routes': routesMap,
      'good_roads': goodRoadsMap,
      'images': images,
      'score': score,
      'distance': distance,
      'ne_lat': maxLat,
      'sw_lat': minLat,
      'ne_lng': maxLong,
      'sw_lng': minLong,
      'added': DateTime.now().toString()
    };

    return tripMap;
  }

  Map<String, dynamic> routeToMap({required Route route}) {
    return {
      //   'points': getPrivateRepository().pointsToString(route),
      //   'colour': colourList.indexOf(route.color),
      //   'stroke': route.strokeWidth,
    };
  }

  Future<int> saveLocal() async {
    int result = -1;
    updateDistance();
    //  id = await getPrivateRepository().saveMyTripItem(this);
    try {
      Uint8List? pngBytes = Uint8List.fromList([]);
      if (driveUri.isEmpty) {
        if (mapImage != null) {
          final byteData =
              await mapImage!.toByteData(format: ui.ImageByteFormat.png);
          pngBytes = byteData?.buffer.asUint8List();
        }
      } else {
        String url = Uri.parse('$urlDrive/images/$driveUri/map.png').toString();
        pngBytes = await wh.getImageBytes(url: url);
      }
      if (pngBytes != null) {
        String url =
            '${Setup().appDocumentDirectory}/drive$id.png'; // driveId.png';
        final imgFile = File(url);
        imgFile.writeAsBytes(pngBytes);
        if (imgFile.existsSync()) {
          result = 1;
          //   debugPrint('Image file $url exists');
        }
      }
    } catch (e) {
      String err = e.toString();
      debugPrint('saveLocal().Error: $err');
    }
    //  loadLocal(_driveId);

    return result;
  }

  Future<void> loadLocal(int driveId) async {
    clearAll();
    Map<String, dynamic> map = await getPrivateRepository().getDrive(driveId);
    List pos = const [0, 0];
    // double distance = 99999;
    try {
      await ut.getPosition().then((currentPosition) {
        pos = [currentPosition.longitude, currentPosition.latitude];
      });
/*
      final directory = Setup().appDocumentDirectory;
      id = driveId;
      driveId = driveId;
      heading = map['title'];
      subHeading = map['subTitle'];
      body = map['body'];
      published = map['added'].toString();
      distance = map['distance'];
      images = '{"url": "$directory/drive$id.png", "caption": ""}';
      pointsOfInterest =
          await getPrivateRepository().loadPointsOfInterestLocal(driveId);
      for (int i = 0; i < pointsOfInterest.length; i++) {
        if (pointsOfInterest[i].images.isNotEmpty) {
          images = '$images,${ut.unList(pointsOfInterest[i].images)}';
        }
      }
      closest = distance.toInt();
      images = '[$images]';
      maneuvers = await getPrivateRepository().loadManeuversLocal(driveId);
      if (maneuvers.isNotEmpty) {
        distanceAway = Geolocator.distanceBetween(pos.latitude, pos.longitude,
            maneuvers[0].location.latitude, maneuvers[0].location.longitude);
      }
      List<List<List<double>>> polyLines =
          await getPrivateRepository().loadPolyLinesLocal(driveId, type: 0);
      for (int i = 0; i < polyLines.length; i++) {
        routes.add(
          List<List<double>>(
              id: -1,
              points: polyLines[i].points,
              color: colourList[Setup().routeColour], //  polyLines[i].color,
              borderColor:
                  colourList[Setup().routeColour], //polyLines[i].color,
              strokeWidth: polyLines[i].strokeWidth),
        );
      }
      polyLines =
          await getPrivateRepository().loadPolyLinesLocal(driveId, type: 1);
      for (int i = 0; i < polyLines.length; i++) {
        // pointsOfInterest[polylines[i].pointOfInterestIndex].id
        // polyLines.pointOfInterestIndex is its pointOfInterest.id
        goodRoads.add(
          List<List<double>>(
              id: -1,
              points: polyLines[i].points,
              color: polyLines[i].color,
              borderColor: polyLines[i].color,
              strokeWidth: polyLines[i].strokeWidth,
              pointOfInterestIndex: polyLines[i].pointOfInterestIndex), // id
        );
      }
      */
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }

  Future<bool> publish({bool fromLocal = true}) async {
    if (fromLocal) {
      await loadLocal(id);
    }
    // var uuid = const Uuid();
    //  await postTrip(this);
    return true;
  }
/*
    Map<String, dynamic> response = await postDriveHeader();
    if (response['status'] == 'OK') {
      driveUri = response['uri'];

      for (PointOfInterest pointOfInterest in pointsOfInterest) {
        pointOfInterest.driveUri = driveUri;
        // need to link the point of interest to the good road
        // so will put the uuid in here rather than API
        // uuid.v7() returns a uuid with -s 019523a6-a2ed-7a9a-8635-f003daee7f5e
        // so have to remove them with a replaceAll
        if (pointOfInterest.getType() == 13) {
          String uuidString = uuid.v7();
          pointOfInterest.url = uuidString.replaceAll(RegExp(r'-'), '');
          //  debugPrint('Point of interest url set to ${pointOfInterest.url}');
        }

        await postPointOfInterest(pointOfInterest, driveUri);
      }

      // pointsOfInterest[polylines[i].pointOfInterestIndex].id
      // polyLines.pointOfInterestIndex is its pointOfInterest.id
      for (List<List<double>> route in goodRoads) {
        for (PointOfInterest pointOfInterest in pointsOfInterest) {
          if (pointOfInterest.id == route.pointOfInterestIndex) {
            // pick up the point of interest uuid
            route.pointOfInterestUri = pointOfInterest.url;
            //     debugPrint('route.interestUri set to ${pointOfInterest.url}');
            break;
          }
        }
      }

      for (int i = 0; i < 2; i++) {
        await postPolylines(
            polylines: i == 0 ? routes : goodRoads,
            driveUid: driveUri,
            type: i);
      }

      postManeuvers(maneuvers, driveUri);

      return true;
    } else {
      return false;
    }
  }

  int tripDistanceMeters(List<Maneuver> maneuvers) {
    double meters = 0;
    for (int i = 0; i < maneuvers.length; i++) {
      meters += maneuvers[i].distance;
    }
    return meters.toInt();
  }
  */
}
