import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:uuid/uuid.dart';
// import 'dart:io';
import 'package:universal_io/universal_io.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '/constants.dart' hide routes;
import '/classes/utilities.dart' as ut;
import '/helpers/helpers.dart';
import 'package:image_picker/image_picker.dart';
import '/services/services.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import 'package:flutter/material.dart' hide Route;
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

//import 'package:path/path.dart';

String colorToHex(Color color) {
  // String hexString = '#' + color.value.toRadixString(16).substring(2, hexString.length)
  final r = (color.r * 255.0).round().clamp(0, 255);
  final g = (color.g * 255.0).round().clamp(0, 255);
  final b = (color.b * 255.0).round().clamp(0, 255);
  return '#$r$g$b';
}

/*
class Waypooint {
  Point latLng; // For MapLibre its [long, lat] - x y
  Color colour = Colors.blueGrey; //['#4287f5', '#fc0303'];
  Waypooint({required this.latLng, this.colour = Colors.blueGrey});
  String get hexColor => colorToHex(colour);
  Point get point => latLng;
}
*/
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
  bool isGoodRoad = false;
  Point startPosition = Point(0, 0);
  Point lastPosition = Point(0, 0);
  //List<double> lastLatLng = [0, 0];
  //List<double> startLatLng = [0, 0];
  // List<double> position = [0, 0];
  Point position = Point(0, 0);

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
    // lastLatLng = position;
    lastPosition = position;
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
    //  lastLatLng = position;
    lastPosition = position;
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
  Icon? titleIcon;
  CreateTripValues tripValues = CreateTripValues();
  Progress progress = Progress();
  bool goodRoad = false;
  int goodRoadIndex = -1;
  double size = 0.5;
  int files = 0;
  int downloaded = 0;
  Point nearestWaypoints = Point(0, 0);
  List<int> nearestWaypointIndexes = [-1, -1];
  int nextManeuverIndex = 0;
  bool isChanged = false;
  int nearestRoute = 0;
  XFile? imageFile;
  List<Point> waypoints = [];

  ui.Image? mapImage; // = Image.asset('assets/images/map.png');
  List<Photo> photos = [];
  ml.MapLibreMapController? mapController;
  List<Map<String, dynamic>> routeFeatures = [];
  List<Map<String, dynamic>> goodRoadsFeatures = [];
  String groupDriveId = '';
  //late Directions _directions;
  ChangedFeatures changedFeatures = ChangedFeatures.none;
  Map<String, dynamic> geoJson = {};
  final GlobalKey mapLibreKey = GlobalKey();

  List<Map> titleData = [
    {
      'label': 'Create a new drive',
      'icon': Icons.add_location_alt_outlined,
      'states': [TripState.none, TripState.automatic, TripState.manual],
      'group': null,
      'leadingWidget': 0,
    },
    {
      'label': 'Edit',
      'icon': Icons.edit,
      'states': [TripState.editing],
      'group': null,
      'leadingWidget': 1,
    },
    {
      'label': 'Loaded',
      'icon': Icons.bookmark_outline,
      'states': [TripState.loaded, TripState.notFollowing],
      'group': null,
      'leadingWidget': 1,
    },
    {
      'label': 'Group drive',
      'icon': Icons.group_outlined,
      'states': [TripState.loaded],
      'group': true,
      'leadingWidget': 1,
    },
    {
      'label': 'Tracking drive',
      'icon': Icons.moving_outlined,
      'states': [
        TripState.recording,
        TripState.automatic,
        TripState.stoppedRecording,
        TripState.paused,
        TripState.startFollowing,
      ],
      'group': false,
      'leadingWidget': 0,
    },
    {
      'label': 'Following drive',
      'icon': Icons.moving_outlined,
      'states': [
        TripState.following,
        TripState.stoppedFollowing,
        TripState.paused,
        TripState.startFollowing,
      ],
      'group': false,
      'leadingWidget': 1,
    },
  ];

  List<Icon> tripTypeIcons = [
    Icon(Icons.add_location_alt_outlined),
    Icon(Icons.bookmark_outline),
    Icon(Icons.group_outlined),
  ];

  List<List<Point>> backBuffer = [[]];
  int backBufferIndex = -1;
  bool updateMap = false;

  static final _instance = CurrentTripItem._privateConstructor();

  factory CurrentTripItem() {
    return _instance;
  }

  fromMyTripItem({required MyTripItem myTripItem}) {
    title = myTripItem.title;
    subTitle = myTripItem.subTitle;
    author = myTripItem.author;
    authorUri = myTripItem.authorUri;
    images = myTripItem.images;
    imageUrls = myTripItem.imageUrls;
    body = myTripItem.body;
    pointsOfInterest = myTripItem.pointsOfInterest;
    maneuvers = myTripItem.maneuvers;
    routes = myTripItem.routes;
    goodRoads = myTripItem.goodRoads;
    score = myTripItem.score;
    tripState = TripState.loaded;
    tripType = TripType.none;
    updateMap = true;
    waypoints = myTripItem.waypoints;
  }

  /*
  MyTripItem clone() {
    MyTripItem myTripItem = MyTripItem(
      id: id,
      body: body,
      pointsOfInterest: pointsOfInterest,
      maneuvers: maneuvers,
      routes: routes,
      goodRoads: goodRoads,
      score: score,
    );
    return myTripItem;
  }
*/
  @override
  clearAll() async {
    isSaved = false;
    driveUri = '';
    // groupDriveId = '';
    title = '';
    subTitle = '';
    body = '';
    images = '';
    backBuffer.clear();
    maneuvers.clear();
    routes.clear();
    pointsOfInterest.clear();
    waypoints.clear();
    isTracking = false;
    tripType = TripType.none;
    tripState = TripState.none;
    tripActions = TripActions.none;
    highliteActions = HighliteActions.none;
    tripValues.showTarget = false;
    isSaved = false;
    goodRoad = false;
    goodRoads.clear();
    appState = AppState.createTrip;
    nearestWaypoints = Point(0, 0);
    changedFeatures = ChangedFeatures.none;
    routeFeatures.clear();
    goodRoadsFeatures.clear();

    if (mapController != null) {
      await mapController!.setGeoJsonSource("route-data", {
        "type": "FeatureCollection",
        "features": [],
      });
      await mapController!.setGeoJsonSource("user-data", {
        "type": "FeatureCollection",
        "features": [],
      });
      await mapController!.setGeoJsonSource("good-road-data", {
        "type": "FeatureCollection",
        "features": [],
      });
    }
    backBufferIndex = 0;
  }

  RouteDelta goodRoadStart = RouteDelta();
  RouteDelta routeDelta = RouteDelta();

  /// load() method to hydrate the CurrentTripItem object with data from the
  /// api or the local SQLite database
  /// It sets the state flags and marks updateMap as true to make sure the map
  /// is redrawn on the first onIdle with the trip data.

  void load({required TripArguments arguments}) {
    fromMyTripItem(myTripItem: arguments.trip);
    tripState = TripState.loaded;
    tripActions = TripActions.none;
    highliteActions = HighliteActions.none;
    tripValues.showTarget = false;
    updateMap = true;
    //mapController!.
    // redrawMap();
  }

  /// headerComplete returns:
  /// [title, subTitle & body described  -> 7  (All               OK)]
  /// [title empty                       -> 6  (body & subTitle   OK)]
  /// [subTitle empty                    -> 5  (title & body      OK)]
  /// [title & subTitle empty            -> 4  (body              OK)]
  /// [body empty                        -> 3  (title & subTitle  OK)]
  /// [title & body empty                -> 2  (subTitle          OK)]
  /// [subTitle & body empty             -> 1  (title             OK)]
  /// [title, subTitle & body empty      -> 0  (nothing           OK)]

  int headerComplete() {
    return (title.isNotEmpty ? 1 : 0) +
        (subTitle.isNotEmpty ? 2 : 0) +
        (body.isNotEmpty ? 4 : 0);
  }

  String getTripTitle() {
    String tripTitle = 'Create a new drive';
    for (int i = 1; i < titleData.length; i++) {
      if (titleData[i]['states'].contains(tripState)) {
        tripTitle = '${titleData[i]['label']} $title';
        titleIcon = Icon(titleData[i]['icon']);
        tripValues.leadingWidget = titleData[i]['leadingWidget'];
        break;
      }
    }
    return tripTitle;
  }

  String getTitle() {
    String title = "Create a new drive";
    switch (tripState) {
      case TripState.loaded:
        return 'Loaded: $title';
      case TripState.editing:
        return 'Editing $title';
      case TripState.following:
        return 'Drive: $title';
      case TripState.stoppedFollowing:
        return 'Drive: $title stopped';
      case TripState.manual:
        return 'Creating a new drive';
      case TripState.paused:
        return 'Paused: $title';
      case TripState.recording:
        return 'Recording a new drive';
      case TripState.stoppedRecording:
        return 'Drive recording stopped';
      case TripState.startFollowing:
        return 'Following $title';
      default:
        return "Create a new drive";
    }
  }

  /// getActions returns the ActionBar buttons depending on the
  /// state of CurrentTripItem().

  List<Widget> getActions({
    required BuildContext context,
    Function(bool)? onUpdate,
  }) {
    List<Widget> actions = [];
    if ([TripState.editing, TripState.manual].contains(tripState)) {
      if (backBuffer.length > 1) {
        actions.add(
          IconButton(
            onPressed: () async {
              if (backBufferIndex < backBuffer.length - 1) {
                waypoints = backBuffer[++backBufferIndex];
                routeFeatures = await replaceRoutes(
                  points: waypoints,
                  updateBuffer: false,
                );
                await updateMapGeometry();
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
                if (backBufferIndex > 0) {
                  waypoints = backBuffer[--backBufferIndex];
                  routeFeatures = await replaceRoutes(
                    points: waypoints,
                    updateBuffer: false,
                  );
                  await updateMapGeometry();
                  onUpdate!(true);
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
          icon: Icon(Icons.map_outlined, color: Colors.white),
        ),
      );
    }
    actions.add(
      IconButton(onPressed: () => {}, icon: Icon(Icons.help_outline_outlined)),
    );
    return actions;
  }

  Future<bool> saveState() async {
    try {
      //     await savePrivate();
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
      tripValues.leadingWidget = 0;
      tripValues.mapHeight = MapHeights.full;
    }
  }

  /// Routines that are called by create_trip_chips.dart that change
  /// the state of the CurrentTripItem()
  ///

  void requestClear() {
    tripState = TripState.none;
    tripActions = TripActions.none;
    highliteActions = HighliteActions.none;
    tripValues.setState = true;
    //leadingWidgetController?.changeWidget(0);
  }

  void requestAddManually() {
    clearAll();
    tripState = TripState.manual;
    tripActions = TripActions.headingDetail;
    tripValues.showTarget = true;
  }

  void addAutomatically() {
    clearAll();
    tripActions = TripActions.headingDetail;
    tripState = TripState.automatic;
  }

  void requestEditing() {
    tripState = TripState.editing;
    tripActions = TripActions.none;
    tripValues.editing();
    loadBackBuffer();
  }

  void requestExtendStart() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();
    if (goodRoad) {
      await addGoodRoadWaypoint(point: tripValues.position);
    } else {
      await addWaypoint(index: -1, point: tripValues.position);
    }
    tripValues.afterWaypoint();
    isSaved = false;
  }

  void requestWaypoint() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();
    if (goodRoad) {
      await addGoodRoadWaypoint(
        index: 0,
        point: CurrentTripItem().tripValues.position,
      );
      changedFeatures.add(ChangedFeatures.goodRoad);
    } else {
      await addWaypoint(index: 0, point: CurrentTripItem().tripValues.position);
      changedFeatures.add(ChangedFeatures.route);
    }
    tripValues.afterWaypoint();
    isSaved = false;
  }

  void requestRevisitWaypoint() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();
    await addWaypoint(index: 0, point: tripValues.position, revisit: true);
    tripValues.afterWaypoint();
    isSaved = false;
  }

  void requestExtendEnd() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();

    await addWaypoint(index: 1, point: CurrentTripItem().tripValues.position);
    tripValues.afterWaypoint();
    isSaved = false;
  }

  void requestRemoveWaypoint() async {
    tripValues.setState = true;
    tripValues.showTarget = true;
  }

  void requestPauseRecording() {
    tripState = TripState.paused;
    tripValues.pauseFollowing();
  }

  void requestEndTracking() {
    tripState = TripState.stoppedRecording;
    tripValues.stopTracking;
  }

  void requestGreatRoad() {
    goodRoad = true;
    isSaved = false;
    goodRoads.add(GoodRoad(id: -1, waypoints: []));
    goodRoadIndex = goodRoads.length - 1;
  }

  /// The goodRoadIndex is set when the goodRoad is highlighted while goodRoad = false
  /// The Edit GoodRoad chip is only shown when a goodRoad is highlighted

  void requestEditGreatRoad() {
    goodRoad = true;
    isSaved = false;
    tripState = TripState.editing;
  }

  void requestGreatRoadEnd() {
    goodRoadEnd();
    goodRoad = false;
    tripValues.showMask = false;
  }

  void requestPointOfInterest() {
    tripActions = TripActions.pointOfInterest;
    tripValues.showMask = false;
    newPointOfInterest();
    tripValues.pointOfInterestIndex = pointsOfInterest.length - 1;
    return;
  }

  void requestGroup() {
    CurrentTripItem().tripActions = TripActions.showGroup;
    CurrentTripItem().tripValues.setState = true;
  }

  void requestMessages() {
    CurrentTripItem().tripActions = TripActions.showMessages;
  }

  void requestTrackRoute() {
    tripState = TripState.recording;
    if (tripValues.pauseStream) {
      tripValues.resumeFollowing();
    } else {
      tripValues.startFollowing();
    }
    return;
  }

  void requestFollowRoute() {
    tripState = TripState.following;
    if (tripValues.pauseStream) {
      tripValues.resumeFollowing();
    } else {
      tripValues.startFollowing();
    }
    return;
  }

  void requestStopFollowing() {
    tripState = TripState.stoppedFollowing;
    tripValues.pauseFollowing();
  }

  /// End create_chips.dart state routines.

  void newPointOfInterest({Point? position, int type = 15}) async {
    position = position ??
        Point(
          mapController!.cameraPosition!.target.longitude,
          mapController!.cameraPosition!.target.latitude,
        );
    pointsOfInterest.add(PointOfInterest(point: position, type: type));
    pointsOfInterestToGeoJSON(
      pointsOfInterest: pointsOfInterest,
      geoJsonFeatures: routeFeatures,
    );
    isSaved = false;
  }

  /// redrawMap() uses the waypoints to generate the routes and creates the
  /// geoJSON for the routes, waypoints and points of interest
  ///

  Future<void> redrawMap() async {
    routeFeatures = await replaceRoutes(points: waypoints);
    List? lastPoint;
    if (routeFeatures.isNotEmpty) {
      lastPoint = routeFeatures.last['geometry']['coordinates'].last;
    }
    waypointsToGeoJSON(
      waypoints: waypoints,
      geoJsonFeatures: routeFeatures,
      lastPoint: lastPoint,
    );
    pointsOfInterestToGeoJSON(
      pointsOfInterest: pointsOfInterest,
      geoJsonFeatures: routeFeatures,
    );

    developer.log(
      'SetGeoJsonSource() called redrawMap() myTripItem.dart 768',
      name: '_map_',
    );
    await mapController!.setGeoJsonSource("route-data", {
      "type": "FeatureCollection",
      "features": routeFeatures,
    });
    // Micro-nudge to update MapLibre
    await mapController!.animateCamera(ml.CameraUpdate.zoomBy(0.000001));

    ///  replaceRoutes(points: waypoints, updateBuffer: false);
    // await updateRoutes();
  }

  loadBackBuffer() {
    backBuffer.clear();
    backBuffer.add(waypoints);
    backBufferIndex = 0;
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

  setPointOfInterestType() {
    if (pointsOfInterest.length == 1) {
      pointsOfInterest[0].type = 17;
      pointsOfInterest[0].name = 'Start';
      return;
    }
    for (int i = 0; i < pointsOfInterest.length; i++) {
      if (pointsOfInterest[i].type == 18) {
        pointsOfInterest[i].type = 12;
        pointsOfInterest[i].name = 'Waypoint';
      }
    }
    pointsOfInterest.last.type = 18;
    pointsOfInterest.last.name = 'End';
  }

  /// addWaypoint() adds a new waypoint under the crosshairs.
  /// the call to replaceRoutes() ensures that everything is in
  /// the correct sequence.
  /// It generates the geoJSON data for the routes, waypoints and points of interest.
  ///
  addWaypoint({
    int index = 1,
    required Point point,
    bool revisit = false,
  }) async {
    int insertAt = waypoints.length;
    ml.LatLng target = mapController!.cameraPosition!.target;
    List point = [target.longitude, target.latitude];
    routeFeatures.clear();
    Point waypoint = Point(target.longitude, target.latitude);

    if (waypoints.isEmpty) {
      waypoints.add(waypoint);
      // backBuffer.add([waypoints.last]);
      //  backBufferIndex = 0;
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
      waypoints.insert(insertAt, waypoint);
    }
    if (waypoints.length == 1) {
      pointsOfInterest.add(
        PointOfInterest(
          point: Point(target.longitude, target.latitude),
          name: 'Start',
          type: 17,
        ),
      );
    } else {
      final lstIdx = pointsOfInterest.indexWhere((poi) => poi.type == 18);
      if (lstIdx >= 0) {
        pointsOfInterest[lstIdx].type = 12;
        pointsOfInterest[lstIdx].name = 'Waypoint';
      }
      pointsOfInterest.add(
        PointOfInterest(
          point: Point(target.longitude, target.latitude),
          name: 'End',
          type: 18,
        ),
      );
    }
    routeFeatures = await replaceRoutes(points: waypoints);
    List? lastPoint;
    if (routeFeatures.isNotEmpty) {
      routeFeatures.last['geometry']['coordinates'].last;
    }
    waypointsToGeoJSON(
      waypoints: waypoints,
      geoJsonFeatures: routeFeatures,
      lastPoint: lastPoint,
    );
    pointsOfInterestToGeoJSON(
      pointsOfInterest: pointsOfInterest,
      geoJsonFeatures: routeFeatures,
    );

    String source = goodRoad ? 'good-road-data' : 'route-data';
    developer.log(
      'SetGeoJsonSource() called addWaypoint() myTripItem.dart 848',
      name: '_map_',
    );
    await mapController!.setGeoJsonSource(source, {
      "type": "FeatureCollection",
      "features": routeFeatures,
    });
    // Micro-nudge to update MapLibre
    await mapController!.animateCamera(ml.CameraUpdate.zoomBy(0.000001));
    isSaved = false;
  }

  /// addGoodWaypoint() adds a new GoodRoads.waypoint under the crosshairs.
  ///
  /// the call to replaceRoutes() ensures that everything is in
  /// the correct sequence.
  /// It generates the geoJSON data for the routes, waypoints and points of interest.
  ///
  addGoodRoadWaypoint({
    int index = 1,
    required Point point,
    bool revisit = false,
  }) async {
    int goodRoad = goodRoads.length;
    int insertAt = goodRoad > 0 ? goodRoads[goodRoad - 1].waypoints.length : 0;
    Point waypoint = latLngToPoint(
      latLng: mapController!.cameraPosition!.target,
    );
    if (goodRoads[goodRoadIndex].waypoints.length == 1 &&
        goodRoads[goodRoadIndex].waypoints[0].x == 0) {
      goodRoads[goodRoadIndex].waypoints[0] = waypoint;
    }
    if (goodRoads[goodRoadIndex].waypoints.isEmpty) {
      goodRoads[goodRoadIndex].waypoints.add(waypoint);
      // backBuffer.add([waypoints.last]);
      //  backBufferIndex = 0;
    } else {
      if (revisit) {
        insertAt = 0;
      } else {
        if (tripState == TripState.editing) {
          insertAt = index == 1 ? goodRoads[goodRoadIndex].waypoints.length : 0;
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
      goodRoads[goodRoadIndex].waypoints.insert(insertAt, waypoint);
    }
    goodRoadsFeatures =
        await replaceRoutes(points: goodRoads[goodRoadIndex].waypoints);
    List? lastPoint;
    if (goodRoadsFeatures.isNotEmpty) {
      lastPoint = goodRoadsFeatures.last['geometry']['coordinates'].last;
      goodRoads[goodRoadIndex].lines =
          goodRoadsFeatures.last['geometry']['coordinates'];
    }
    goodRoadWaypointsToGeoJSON(
      goodRoads: goodRoads,
      geoJsonFeatures: goodRoadsFeatures,
      lastPoint: lastPoint,
    );
    developer.log(
      'SetGeoJsonSource() called addGoodRoadWaypoint() myTripItem.dart 918',
      name: '_map_',
    );
    await mapController!.setGeoJsonSource("good-road-data", {
      "type": "FeatureCollection",
      "features": goodRoadsFeatures,
    });
    // Micro-nudge to update MapLibre
    await mapController!.animateCamera(ml.CameraUpdate.zoomBy(0.000001));
    isSaved = false;
  }

  loadWaypoints({required Point point}) {}

  /// UpdateMapGeometry() takes the data from Waypoints and routes and displays the data on the
  /// map. Should be called after every change of waypoints
  /// CurrentTripItem().goodRoad is the flag to distinguish the waypoint type

  Future<void> updateMapGeometry() async {
    List? lastPoint;

    List<Point> targetWaypoints =
        goodRoad ? goodRoads[goodRoadIndex].waypoints : waypoints;
    if (targetWaypoints.isNotEmpty) {
      if (goodRoad) {
        goodRoadWaypointsToGeoJSON(
          goodRoads: goodRoads,
          geoJsonFeatures: goodRoadsFeatures,
        );
      } else {
        if (routeFeatures.isNotEmpty) {
          lastPoint = routeFeatures.last['geometry']['type'] == 'LineString'
              ? routeFeatures.last['geometry']['coordinates'].last
              : lastPoint;
        }
        waypointsToGeoJSON(
          waypoints: targetWaypoints, // as List<Point>,
          geoJsonFeatures: routeFeatures,
          lastPoint: lastPoint,
        );
      }
      routes = [];
      for (int i = 0; i < routeFeatures.length; i++) {
        if (routeFeatures[i]['geometry']['type'] == 'LineString') {
          List points = routeFeatures[i]['geometry']['coordinates'];
          Map<String, dynamic> route = {'route': points};
          routes.add(route);
        }
      }

      // mapController!.updateLine(line, changes)
      developer.log(
        'SetGeoJsonSource() called updateMapGeometry() myTripItem.dart 949',
        name: '_map_',
      );
      String source = goodRoad ? 'good-road-data' : 'route-data';
      await mapController!.setGeoJsonSource(source, {
        "type": "FeatureCollection",
        "features": routeFeatures,
      });
      await mapController!.animateCamera(ml.CameraUpdate.zoomBy(0.000001));
    }
  }

  /// deleteWaypoint deletes a waypoint from either the routes List<waypoint> where id is 'i' - the waypoint index
  /// or goodRoads[n].List<waypoint>  where id = 'g_i' where g is the roodRoad index and i the waypoint index

  deleteWaypoint({required String id}) async {
    int index = -1;
    int route = -1;
    List targetWaypoints = waypoints;
    if (id.contains('_')) {
      List<String> ids = id.split('_');
      route = int.parse(ids[0]);
      index = int.parse(ids[1]);
      targetWaypoints = goodRoads[route].waypoints;
    } else {
      index = int.parse(id);
    }
    if (index >= 0) {
      targetWaypoints.removeAt(index);
      List<Map<String, dynamic>> features = await replaceRoutes(
        points: targetWaypoints,
      );
      if (id.contains('_')) {
        goodRoadsFeatures = features;
      } else {
        routeFeatures = features;
      }
      await updateMapGeometry();

      isSaved = false;
    }
  }

  /// reorderWaypoints() generates the list of PointsOfInterest that
  /// include the waypoints in the correct order.

  List<PointOfInterest> reorderWaypoints({
    List<List<double>> highlight = const [],
    bool revisit = false,
  }) {
    /// first maneuver always 'depart' last maneuver always 'arrive'

    final int startPointOfInterest = pointsOfInterest.indexWhere(
      (poi) => poi.type == 17,
    );

    final int endPointOfInterest = pointsOfInterest.indexWhere(
      (poi) => poi.type == 18,
    );

    if (startPointOfInterest > -1) {
      pointsOfInterest[startPointOfInterest].point = maneuvers.first.point;
    }
    if (endPointOfInterest > -1) {
      pointsOfInterest[endPointOfInterest].point = maneuvers.last.point;
    }
    /*  DON'T REMOVE UNTIL REPLACEMENT WORKS PROPERLY
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
    */
    return pointsOfInterest;
  }

  /// replaceRoutes() gets the maneuvers from a list of points.
  /// It ensures that everything is in the same order as the router
  /// has supplied.
  Future<List<Map<String, dynamic>>> replaceRoutes({
    required List points,
    bool updateBuffer = true,
    bool revisit = false,
  }) async {
    List<Map<String, dynamic>> features = [];
    if (points.length > 1) {
      try {
        if (updateBuffer) {
          backBuffer.insert(0, []);
          for (int i = 0; i < points.length; i++) {
            backBuffer[0].add(points[i]);
          }
          developer.log(
            'replaceRoutes() adding to backBuffer - length ${backBuffer.length} backBuffer[0] waypoints added: ${backBuffer[0].length}',
            name: '_buffer',
          );
          if (backBuffer.length > 10) {
            backBuffer.removeAt(10);
          }
          backBufferIndex = 0;
        }
        Map<String, dynamic> routeData = await getRoutePoints(
          points: points,
          addPoints: true,
          goodRoad: goodRoad,
        );
        distance = double.parse(routeData['distance'] ?? '0.0');
        if ((routeData["msg"] ?? " ") != "Error") {
          List<Maneuver> newManeuvers = [];
          int wps = 0;
          features = routeData['routes'];

          /// Ensure that waypoints don't have both "arrive" and "depart"
          for (int i = 0; i < routeData['maneuvers'].length; i++) {
            wps = ['arrive', 'depart'].contains(routeData['maneuvers'][i].type)
                ? wps + 1
                : wps;
            bool add = i == 0;
            if (!add) {
              add = !([
                    'arrive',
                    'depart',
                  ].contains(routeData['maneuvers'][i].type) &&
                  [
                    'arrive',
                    'depart',
                  ].contains(routeData['maneuvers'][i - 1].type));
            }
            if (add) {
              newManeuvers.add(routeData['maneuvers'][i]);
            }
          }

          routes = [];

          /// Add next 2 lines to ensure the waypoint can be extracted from the maneuvers
          newManeuvers.last.type = 'arrive';
          newManeuvers.last.point = waypoints.last;
          maneuvers = goodRoad ? maneuvers : newManeuvers;
          List<PointOfInterest> pointsOfInterest = reorderWaypoints(
            revisit: revisit,
          );
        } else {
          routes = [];
        }
      } catch (e) {
        developer.log('Error replaceRoutes() ${e.toString()}');
      }
    }
    return features;
  }

  @override
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> maneuversJSON = [];
    for (int i = 0; i < maneuvers.length; i++) {
      maneuversJSON.add(maneuvers[i].toMap());
    }

    List<Map<String, dynamic>> pointsOfInterestJSON = [];
    for (int i = 0; i < pointsOfInterest.length; i++) {
      Map<String, dynamic> poiMap = pointsOfInterest[i].toMap();
      pointsOfInterestJSON.add(poiMap);
    }
    List<List> tripWaypoints = [[]];
    try {
      for (int i = 0; i < waypoints.length; i++) {
        tripWaypoints.add([waypoints[i].x, waypoints[i].y]);
      }
    } catch (e) {
      debugPrint('Error handling waypoints: ${e.toString()}');
    }

    List<Map<String, dynamic>> goodRoadsJSON = [];
    for (int i = 0; i < goodRoads.length; i++) {
      goodRoadsJSON.add(goodRoads[i].toMap());
    }

    // String tripWaypoints = jsonEncode('$waypoints');
    // String tripWaypoints = waypoints.toString();

    try {
      Map<String, dynamic> json = {
        'id': id,
        'uri': uri,
        'images': images,
        'title': title,
        'sub_title': subTitle,
        'body': body,
        'added': added,
        'score': score,
        'scored': scored,
        'distance': distance,
        'downloads': downloads,
        'author_uri': authorUri,
        'author': author,
        'routes': routes,
        'maneuvers': maneuversJSON,
        'good_roads': goodRoadsJSON,
        'points_of_interest': pointsOfInterestJSON,
        'waypoints': tripWaypoints,
      };

      return json;
    } catch (e) {
      debugPrint('Error MyTripItem.toMap(): ${e.toString()}');
    }
    return {};
  }

  @override
  savePrivate() async {
    uri = uri.isEmpty ? getUuid() : uri;
    added = added.isEmpty ? dateFormat.format(DateTime.now()) : added;
    id = await getPrivateRepository().saveMyTrip(this);
    return;
  }

  Future<void> loadPrivate({String uri = '', int id = -1}) async {
    if (id == -1) {}
  }

  updateWaypoints({
    required Point point,
    List<Map<String, dynamic>>? features,
  }) async {
    if (tripState == TripState.editing) {
      //  nearestWaypointIndex =
      features = features ?? routeFeatures;
      List<int> newIndexes = closestWaypoints(
        waypoints: waypoints,
        point: point,
      );

      if (newIndexes[0] != nearestWaypointIndexes[0] ||
          newIndexes[1] != nearestWaypointIndexes[1]) {
        nearestWaypointIndexes[0] = newIndexes[0];
        nearestWaypointIndexes[1] = newIndexes[1];
        newIndexes[0]++;
        newIndexes[1]++;
        for (int i = 0; i < features.length; i++) {
          if (features[i]['properties']['item'] == 'waypoint') {
            features[i]['properties']['color'] =
                newIndexes.contains(features[i]['properties']['number'])
                    ? "hsl(4, 82%, 56%)"
                    : "hsl(188, 53%, 60%)";
          }
        }
        developer.log(
          'SetGeoJsonSource() called updateWaypoints() myTripItem.dart 1178',
          name: '_map_',
        );
        String source = goodRoad ? 'good-road-data' : 'route-data';
        await mapController!.setGeoJsonSource(source, {
          "type": "FeatureCollection",
          "features": features,
        });
        // Micro-nudge to update MapLibre
        await mapController!.animateCamera(ml.CameraUpdate.zoomBy(0.000001));
      }
    }
  }

  updateRoutes({
    String id = '',
    List<Map<String, dynamic>>? features,
    String colour = "hsl(4, 82%, 56%",
  }) async {
    features = features ?? routeFeatures;

    for (int i = 0; i < features.length; i++) {
      if (features[i]['geometry']['type'] == 'LineString' &&
          (features[i]['id'] == id || id.isEmpty)) {
        features[i]['properties']['color'] = colour;
      }
    }
    String source = goodRoad ? 'good-road-data' : 'route-data';
    developer.log(
      'SetGeoJsonSource() called updateRoutes() myTripItem.dart 1199',
      name: '_map_',
    );
    await mapController!.setGeoJsonSource(source, {
      "type": "FeatureCollection",
      "features": features,
    });
  }

  highlightWaypoint({String id = ''}) async {
    List<Map<String, dynamic>> features =
        goodRoad ? goodRoadsFeatures : routeFeatures;
    highliteActions =
        id.isEmpty ? HighliteActions.none : HighliteActions.waypointHighlited;
    String colour = highliteActions == HighliteActions.waypointHighlited
        ? Setup().highlightedColourHex()
        : goodRoad
            ? Setup().goodRouteColourHex()
            : Setup().routeColourHex();

    for (int i = 0; i < features.length; i++) {
      if (features[i]['geometry']['type'] == 'Point' &&
          (features[i]['id'].toString() == id || id.isEmpty)) {
        features[i]['properties']['color'] = colour;
      }
    }
    String source = goodRoad ? 'good-road-data' : 'route-data';
    developer.log(
      'SetGeoJsonSource() called highlightWaypoints() myTripItem.dart 1218',
      name: '_map_',
    );
    await mapController!.setGeoJsonSource(source, {
      "type": "FeatureCollection",
      "features": features,
    });
    // Micro-nudge to update MapLibre
    await mapController!.animateCamera(ml.CameraUpdate.zoomBy(0.000001));
  }

  highlightGoodRoad({String id = ''}) async {
    //  List<Map<String, dynamic>> features =
    //      goodRoad ? goodRoadsFeatures : routeFeatures;
    highliteActions = id.isEmpty
        ? HighliteActions.none
        : HighliteActions.greatRoadHighlighted;
    String colour = id.isNotEmpty
        ? Setup().highlightedColourHex()
        : Setup().goodRouteColourHex();

    for (int i = 0; i < goodRoadsFeatures.length; i++) {
      if (goodRoadsFeatures[i]['geometry']['type'] == 'LineString' &&
          (goodRoadsFeatures[i]['id'].toString() == id || id.isEmpty)) {
        goodRoadsFeatures[i]['properties']['color'] = colour;
      }
    }
    String source = goodRoad ? 'route-data' : 'good-road-data';
    developer.log(
      'SetGeoJsonSource() called highlightWaypoints() myTripItem.dart 1218',
      name: '_map_',
    );

    goodRoadIndex = id.isEmpty ? goodRoadIndex : int.parse(id.substring(2)) - 1;

    await mapController!.setGeoJsonSource(source, {
      "type": "FeatureCollection",
      "features": goodRoadsFeatures,
    });
    // Micro-nudge to update MapLibre
    await mapController!.animateCamera(ml.CameraUpdate.zoomBy(0.000001));
  }

  Future<void> reverseRoute({List<Map<String, dynamic>>? features}) async {
    features = features ?? routeFeatures;
    List<Point> points = backBuffer[0];
    backBuffer.insert(0, points.reversed.toList());
    features = await replaceRoutes(points: backBuffer[0]);
    await updateMapGeometry();
  }

  /// Recalculate route
  /// aims:
  ///   1 maintain all the maneuvers already passed
  ///   3 rejoin the route at the nearest sensible waypoint - type arrive
  ///
  Future<bool> changeRoute({
    required Point position,
    int lastManeuverIndex = 0,
    int routeIndex = 0,
    int pointIndex = 0,
  }) async {
    List<Point> points = [];

    for (int i = 0; i <= lastManeuverIndex; i++) {
      if (['depart', 'arrive'].contains(CurrentTripItem().maneuvers[i].type)) {
        points.add(CurrentTripItem().maneuvers[i].point);
      }
    }

    /// now add current position as a waypoint
    points.add(position);

    /// Now look for closest waypoint to rejoin the route
    double distance = 999999999999;
    int nextManeuver = 0;
    for (int i = lastManeuverIndex + 1; i < maneuvers.length; i++) {
      if (maneuvers[i].type == 'arrive' || i == maneuvers.length - 1) {
        double delta = Geolocator.distanceBetween(
          position.y.toDouble(),
          position.x.toDouble(),
          maneuvers[i].point.y.toDouble(),
          maneuvers[i].point.x.toDouble(),
        );
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

  void goodRoadEnd() async {
    isSaved = false;
    goodRoad = false;
    String uuid = getUuid();
    if (goodRoads.isNotEmpty &&
        goodRoads[goodRoadIndex].waypoints.isNotEmpty &&
        goodRoads[goodRoadIndex].pointOfInterestUri.isEmpty) {
      Point point = goodRoads[goodRoadIndex].waypoints.first;
      pointsOfInterest.add(PointOfInterest(point: point, uuid: uuid, type: 14));
      goodRoads[goodRoadIndex].pointOfInterestUri = uuid;
    }
  }
}

class MyTripItem extends TripItem {
  int id;
  String uri;
  // String driveUri;
  String title;
  String subTitle;
  String body;
  String added;
  int highlights;
  int closest;
  double score;
  int scored;
  int downloads;
  String authorUri;
  String author;
  double distance;
  double distanceAway;
  List<Map<String, dynamic>> routes;
  List<Point> waypoints;
  List<Maneuver> maneuvers;
  List<GoodRoad> goodRoads;
  List<PointOfInterest> pointsOfInterest;
  String images;
  bool published = false;
  MyTripItem({
    this.id = -1,
    this.uri = '',
    String? driveUri,
    this.title = '',
    this.subTitle = '',
    this.body = '',
    this.added = '',
    this.score = 0,
    this.scored = 0,
    this.distance = 0,
    this.distanceAway = 0,
    this.highlights = 0,
    this.closest = 0,
    this.downloads = 0,
    this.authorUri = '',
    this.author = '',
    List<Map<String, dynamic>>? routes,
    List<Maneuver>? maneuvers,
    List<PointOfInterest>? pointsOfInterest,
    List<Point>? waypoints,
    List<GoodRoad>? goodRoads,
    this.images = '',
  })  : // driveUri = driveUri ?? getUuid(),
        maneuvers = maneuvers ?? <Maneuver>[],
        goodRoads = goodRoads ?? <GoodRoad>[],
        pointsOfInterest = pointsOfInterest ?? <PointOfInterest>[],
        routes = routes ?? <Map<String, dynamic>>[],
        waypoints = waypoints ?? <Point>[];

  factory MyTripItem.fromJson({required Map<String, dynamic> jsonObject}) {
    //   List<dynamic> routes = jsonObject["routes"];
    List<Map<String, dynamic>> routes = [
      {'route': jsonObject["routes"]},
    ];
    List<Maneuver> maneuvers = maneuversFromJson(
      jsonList: jsonObject["maneuvers"],
    );
    List<GoodRoad> goodRoads = goodRoadsFromJson(
      jsonList: jsonObject["good_roads"],
    );

    List<PointOfInterest> pointsOfInterest = pointsOfInterestFromJson(
      jsonList: jsonObject["points_of_interest"],
    );
    List<Point> waypoints = [];
    try {
      List wps = jsonObject['waypoints'];
      for (int i = 0; i < wps.length; i++) {
        if (wps[i].length == 2) {
          waypoints.add(Point(wps[i][0], wps[i][1]));
        }
      }
    } catch (e) {
      debugPrint('Error is: ${e.toString()}');
    }
    MyTripItem tripItem = MyTripItem();
    try {
      tripItem = MyTripItem(
        id: -1,
        uri: jsonObject["uri"] ?? "",
        title: jsonObject["title"] ?? "",
        subTitle: jsonObject["sub_title"] ?? "",
        body: jsonObject["body"] ?? "",
        images: jsonObject['images'] ?? "",
        added: jsonObject["added"] ?? dateFormat.format(DateTime.now()),
        distance: jsonObject["distance"] ?? 0,
        score: jsonObject["score"] ?? 0,
        scored: jsonObject["scored"] ?? 0,
        downloads: jsonObject["downloads"] ?? 0,
        authorUri: jsonObject["author_uri"] ?? "",
        author: jsonObject["author"] ?? "",
        routes: routes,
        maneuvers: maneuvers,
        goodRoads: goodRoads,
        pointsOfInterest: pointsOfInterest,
        waypoints: waypoints,
      );
    } catch (e) {
      debugPrint('Error MyTripItem.toJson(): ${e.toString()}');
    }

    return tripItem;
  }

  factory MyTripItem.fromTripItem({required TripItem tripItem}) {
    return MyTripItem(
      id: tripItem.id,
      uri: tripItem.uri,
      title: tripItem.title,
      subTitle: tripItem.subTitle,
      body: tripItem.body,
      images: tripItem.imageUrls,
      added: tripItem.added,
      distance: tripItem.distance,
      author: tripItem.author,
      authorUri: tripItem.authorUrl,
      downloads: tripItem.downloads,
      routes: [],
      maneuvers: [],
      goodRoads: [],
      pointsOfInterest: [],
    );
  }

  Map<String, dynamic> toJson() {
    uri = uri.isEmpty ? getUuid() : uri;
    List<Map<String, dynamic>> maneuversJSON = [];
    for (int i = 0; i < maneuvers.length; i++) {
      maneuversJSON.add(maneuvers[i].toMap(driveUid: uri));
    }

    List<Map<String, dynamic>> pointsOfInterestJSON = [];
    for (int i = 0; i < pointsOfInterest.length; i++) {
      pointsOfInterestJSON.add(pointsOfInterest[i].toMap(driveUid: uri));
    }

    Map<String, dynamic> json = {
      "id": id,
      "uri": uri,
      "title": title,
      "sub_title": subTitle,
      "body": body,
      "added": added,
      "score": score,
      "scored": scored,
      "distance": distance,
      "downloads": downloads,
      "author_uri": authorUri,
      "author": author,
      "routes": routes,
      "maneuvers": maneuversJSON,
      "good_roads": goodRoads,
      "points_of_interest": pointsOfInterestJSON,
      "pois": pointsOfInterestJSON.length,
      'waypoints': waypoints,
      "published": published,
    };
    return json;
  }

  /// Going to save the newly created / edited trip
  ///   On device save to SQLite
  ///     Fields id, ne, sw, title, added, jsonObject to provide
  ///     enough info for the user to select the trip without having
  ///     to jsonDecode everything before selection
  ///   On web save to API as private
  ///     send the whole trip as a jsonObject and let the api shred it
  ///

  savePrivate() async {
    //   await getPrivateRepository().saveMyTrip();
    return;
  }

  // publish(this);

  _publish() {
    return;
  }

  String getPublishedDate({String noPrompt = ''}) {
    return added == '' ? noPrompt : added;
  }

  // get distanceAway => 1;

  // get distance => 10;

  get showMethods => false;
}

// saveMyTripItem();
