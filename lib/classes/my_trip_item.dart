import 'dart:async';
import 'dart:ui' as ui;
//import 'package:flutter_map/flutter_map.dart';
//import 'package:uuid/uuid.dart';
// import 'dart:io';
//import 'package:universal_io/universal_io.dart';/
//import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '/constants.dart' hide routes;
// import '/classes/utilities.dart' as ut;
import '/helpers/helpers.dart';
import 'package:image_picker/image_picker.dart';
import '/services/services.dart';
import '/models/other_models.dart';
import '/classes/classes.dart' hide distanceBetween;
import 'package:flutter/material.dart' hide Route;
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';

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
  Route goodRoad = Route();
  bool isGoodRoad = false;
  bool addGoodRoadDetail = false;
  bool isEditing = false;
  Point startPosition = Point(0, 0);
  Point lastPosition = Point(0, 0);
  Point position = Point(0, 0);
  double heading = 0;
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

  void track() {
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
    pauseStream = true;
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

  startTracking() {
    stopStream = true;
    startStream = false;
    pauseStream = true;
    resumeStream = false;
    lastPosition = position;
  }

  stopTracking() {
    stopStream = true;
    startStream = false;
    pauseStream = false;
    resumeStream = false;
    mapHeight = MapHeights.full;
  }

  resumeTracking() {
    resumeFollowing();
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

  afterWaypoint({bool goodRoadDetails = false}) {
    showMask = false;
    setState = true;
    showTarget = true;
    addGoodRoadDetail == goodRoadDetails;
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
  bool isGoodRoad = false;
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
  BottomDrawerData bottomDrawerData = BottomDrawerData.none;
  MapUpdates mapUpdates = MapUpdates.none;
  ui.Image? mapImage; // = Image.asset('assets/images/map.png');
  List<Photo> photos = [];
  MapLibreMapController? mapController;
  // List<Route> routeFeatures = [];
  // List<Route> goodRoadsFeatures = [];
  String groupDriveId = '';
  //late Directions _directions;
  // ChangedFeatures changedFeatures = ChangedFeatures.none;
  Map<String, dynamic> geoJson = {};
  final GlobalKey mapLibreKey = GlobalKey();
  List bottomDrawerItems = [];
  int waypointIndex = -1;
  List<Follower> followers = [];
  List<TripMessage> tripMessages = [];
  MLMap? tripMap;

  List<Map> titleData = [
    {
      'label': 'Create a new drive',
      'icon': Icons.add_location_alt_outlined,
      'states': [TripState.none, TripState.tracking, TripState.manual],
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
        TripState.tracking,
        TripState.tracking,
        TripState.stoppedTracking,
        TripState.pausedTracking,
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
        TripState.pausedTracking,
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

  Map<String, dynamic> mapSources = {
    "route-data": routesToGeoJson,
    "good-road-data": goodRoadsToGeoJson,
    "waypoint-data": waypointsToGeoJson,
    "good-road-waypoint-data": goodRoadWaypointsToGeoJson,
    "point-of-interest-data": pointsOfInterestToGeoJson,
    "streamed-data": followersToGeoJson,
  };

  List<List<Waypoint>> backBuffer = [[]];
  int backBufferIndex = -1;
  bool updateMap = false;

  // static final _instance = CurrentTripItem._privateConstructor();

  // factory CurrentTripItem() {
  //   return _instance;
  // }

  static CurrentTripItem? _instance;

  CurrentTripItem._internal();

  factory CurrentTripItem() => _instance ??= CurrentTripItem._internal();

  static void reset() {
    _instance = null;
  }

  fromMyTripItem({required MyTripItem myTripItem}) async {
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
    mapUpdates = MapUpdates.updateAll;

    // micro-nudge
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
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
            CurrentTripItem().tripValues.title = 'Create a new trip';
        CurrentTripItem().tripValues.autoCentre = false;
  }
*/
  @override
  clearAll({TripState newTripState = TripState.clearing}) async {
    isSaved = false;
    id = -1;
    imageUrls = "";
    driveUri = '';
    title = '';
    subTitle = '';
    body = '';
    images = '';
    backBuffer.clear();
    maneuvers.clear();
    routes.clear();
    goodRoads.clear();
    pointsOfInterest.clear();
    isTracking = false;
    tripType = TripType.none;
    tripState = newTripState;
    tripActions = TripActions.none;
    highliteActions = HighliteActions.none;
    tripValues.showTarget = false;
    isSaved = false;
    isGoodRoad = false;
    appState = AppState.createTrip;
    nearestWaypoints = Point(0, 0);
    mapUpdates = MapUpdates.updateAll;
    backBufferIndex = 0;
    tripValues.title = 'Create a new trip';
    mapUpdates = MapUpdates.updateAll;
    tripValues.autoCentre = false;
  }

  RouteDelta goodRoadStart = RouteDelta();
  RouteDelta routeDelta = RouteDelta();
  WaypointState waypointState = WaypointState.none;

  /// load() method to hydrate the CurrentTripItem object with data from the
  /// api or the local SQLite database
  /// It sets the state flags and marks updateMap as true to make sure the map
  /// is redrawn on the first onIdle with the trip data.
  ///

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

  MLMap getMap(
      {Key? key,
      Function(LatLng, MapLibreMapController)? onUpdate,
      MapLibreMapController? mapController,
      Function(Point, LatLng)? onTap,
      Function()? onIdle}) {
    if (tripMap == null) {
      developer.log('***** Instantiating tripMap ****', name: '_mapUpdates_');
    } else {
      developer.log('***** returning tripMap instance ****',
          name: '_mapUpdates_');
    }
    try {
      tripMap ??= MLMap(
          // key: GlobalKey(),
          onIdle: onIdle,
          onTap: onTap,
          onUpdate: onUpdate,
          mapController: mapController);
    } catch (e) {
      developer.log(
          '***** Error returning tripMap instance: ${e.toString()} ****',
          name: '_mapUpdates_');
    }
    return tripMap!;
  }

  // Below is a hack to update the pointOfInterest point to the start of
  // the good road. Will have to ensure that is done when the first
  // good road waypoint is added.
  void reconcileGoodRoads() {
    if (goodRoads.isNotEmpty) {
      for (int i = 0; i < goodRoads.length; i++) {
        String poiId = goodRoads[i].pointOfInterestUri;
        Point start = Point(goodRoads[i].lines[0][0], goodRoads[i].lines[0][1]);
        for (int j = 0; j < pointsOfInterest.length; j++) {
          if (pointsOfInterest[j].uuid == poiId) {
            pointsOfInterest[j].point = start;
          }
        }
      }
    }
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
    /// 00000000 all empty
    /// 00000001 title Ok
    /// 00000010 subTitle Ok
    /// 00000100 body Ok
    /// The next line is to stop the keyboard appearing after clearing a trip
    /// because the CurrentTripItem() would exist and the data cleared
    if (tripState == TripState.none) {
      return 7;
    }
    int result = (title.isNotEmpty ? 1 : 0) |
        (subTitle.isNotEmpty ? (1 << 1) : 0) |
        (body.isNotEmpty ? (1 << 2) : 0);
    return result;
  }

  /// When the create_trip.dart BottomDrawer is closed
  /// have to ensure that the map is updated for PointsOfInterest
  /// by setting the mapUpdates flag for points of interest

  drawerClosed() {
    if (bottomDrawerData.isPointOfInterest) {
      mapUpdates = mapUpdates.add(MapUpdates.pointsOfInterest);
    }
    bottomDrawerData.completed();
  }

  Future<void> refreshMap({MapUpdates change = MapUpdates.updateAll}) async {
    try {
      if (change == MapUpdates.none || change == MapUpdates.updateAll) {
        mapUpdates = change;
      } else {
        mapUpdates = mapUpdates.add(change);
      }
      developer.log(
          'CurrentTripItem().refreshMap() called mapUpdates: $mapUpdates',
          name: '_mapUpdates_');
      // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
      await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    } catch (e) {
      developer.log(
          'CurrentTripItem().refreshMap() called BUT FAILED: ${e.toString()}',
          name: '_repaint_');
    }
  }

  /// updateMapGeoJson() is the only function that updates
  /// the MapLibre geoJson on the MapLibreMap onIdle callback in
  /// create_tip.dart. The updates are determined by the
  /// multi-value enum MapUpdates that tracks what has to be updated
  /// and holds both the MapLibre source names and the Dart method to convert the data
  /// to be used in the map update.
  /// The objective is to simplify the alignment of Dart data with the MapLibre source & layer
  /// so that there are only two calls to update the map
  ///   1 For published data that only changes when the zoom changes or the fence is breached
  ///   2 User data while editing the map initiated through the ActionChips

  var testData = {
    "type": "Feature",
    "geometry": {
      "type": "Point",
      "coordinates": [-0.5900587311911636, 51.419701499164724]
    },
    "properties": {
      "group": "point_of_interest",
      "icon": "shield",
      "color": "#4caf50",
      "drive_id": -1,
      "uri": "019dd42fd7fa7d37b726c51213780f5c",
      "name": "P",
      "description": "P",
      "type": 15,
      "images":
          '[{"url":"/data/user/0/com.motatek.drives/app_flutter/point_of_interest_3_1.jpg","caption":"image 1"}]',
      "rated": 0,
      "rating": "☆☆☆☆☆",
      "author": ""
    }
  };

  Future<void> updateMapGeoJson(
      {MapUpdates? exitMapUpdates, Point? centre}) async {
    centre ??= CurrentTripItem().tripValues.position;

    if (tripState == TripState.editing) {
      highlightWaypoints(targetCentre: centre);
    }

    if (mapUpdates != MapUpdates.none && !mapUpdates.isUpdating) {
      List<String> sources = mapUpdates.sourcesToUpdate;
      if (sources.isNotEmpty) {
        // Set the updating flag to prevent map onIdle calls restarting update before completed
        mapUpdates = mapUpdates.add(MapUpdates.updating);

        checkMapUpdates('updating');
        for (int i = 0; i < sources.length; i++) {
          try {
            if (i < 5) {
              try {
                await mapController!.setGeoJsonSource(sources[i], {
                  "type": "FeatureCollection",
                  "features": mapSources[sources[i]](),
                });
              } catch (e) {
                developer.log(
                    'my_tripItem.dart updateMapGeoJson() mapController.seGeoJsonSource() failed source: ${sources[i]} (i:$i)',
                    name: "_error_");
              }
            }
          } catch (e) {
            developer.log("updateMapGeoJson()  Error: ${e.toString()}",
                name: 'error');
          }
        }
      }
    }
    mapUpdates = exitMapUpdates ?? MapUpdates.none;
  }

  void highlightWaypoints({required Point targetCentre}) {
    List<int> waypoints = [];
    developer.log('Checking waypoints', name: '_waypoints_');
    try {
      waypoints = closestWaypoints(target: targetCentre, routes: routes);
    } catch (e) {
      developer.log('ERROR updateMapGeoJson() :${e.toString()}',
          name: '_waypoints_');
    }
    bool waypointsChanged = false;

    if (waypoints.isEmpty) {
      waypointState = WaypointState.none;
    } else if (waypointIndex > -1) {
      waypointState = WaypointState.remove;
    } else if (waypoints.length == 2) {
      waypointState = WaypointState.insert;
    } else if (waypoints[0] == 0) {
      waypointState = WaypointState.extendStart;
    } else {
      waypointState = WaypointState.extendEnd;
    }

    developer.log('waypointState :${waypointState.name}', name: '_waypoints_');

    /// Want to avoid unnecessary update of MapLibre so make sure something really has changed
    if (routes.isNotEmpty) {
      for (int i = 0; i < routes[0].waypoints.length; i++) {
        bool state = routes[0].waypoints[i].selected ?? false;
        routes[0].waypoints[i].selected =
            waypoints.isNotEmpty && waypoints.contains(i);
        waypointsChanged =
            state != routes[0].waypoints[i].selected! ? true : waypointsChanged;
      }
    }
    if (waypointsChanged) {
      mapUpdates = mapUpdates.add(MapUpdates.waypoints);
      checkMapUpdates('adding waypoints');
    }
    return;
  }

  void checkMapUpdates(String action) {
    if (mapUpdates == MapUpdates.none) {
      developer.log('Action: $action - mapUpdates = MapUpdates.none - STOP',
          name: '_mapUpdates_');
    }
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
      case TripState.pausedTracking:
        return 'Paused: $title';
      case TripState.tracking:
        return 'Recording a new drive';
      case TripState.stoppedTracking:
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
              if (backBufferIndex < backBuffer.length) {
                routes.last.waypoints = backBuffer[++backBufferIndex];
                if (routes.last.waypoints.length < 2) {
                  routes.last.lines.clear();
                } else {
                  routes = await replaceRoutes(
                    routes: routes,
                    updateBuffer: false,
                  );
                }
                mapUpdates = MapUpdates.routesAndWaypoints;
                await mapController!
                    .animateCamera(CameraUpdate.zoomBy(0.000001));
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

        actions.add(
          IconButton(
            onPressed: () async {
              if (backBufferIndex > 0) {
                routes.last.waypoints = backBuffer[--backBufferIndex];
                routes = await replaceRoutes(
                  routes: routes,
                  updateBuffer: false,
                );
                mapUpdates = MapUpdates.routesAndWaypoints;
                await mapController!
                    .animateCamera(CameraUpdate.zoomBy(0.000001));
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

  void requestClear() async {
    tripValues.setState = true;

    /// clearAll sets tripState to TripState.clearing making sure that the geoJson is updated on next _onIdle
    clearAll(newTripState: TripState.clearing);
    tripState = TripState.clearing;
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    // mapController = null;
    //leadingWidgetController?.changeWidget(0);
  }

  void requestAddManually() async {
    clearAll(newTripState: TripState.manualStart);
    // tripValues.startFollowing();
    tripValues.manual();
    if (CurrentTripItem().routes.isEmpty) {
      CurrentTripItem().routes = [Route(lines: [], waypoints: [])];
    }
    await mapController!
        .updateMyLocationTrackingMode(MyLocationTrackingMode.trackingCompass);
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    tripActions = TripActions.headingDetail;
  }

  void requestAddAutomatically() async {
    clearAll(newTripState: TripState.tracking);
    tripValues.track();
    if (CurrentTripItem().routes.isEmpty) {
      CurrentTripItem().routes = [Route(lines: [], waypoints: [])];
    }
    await mapController!
        .updateMyLocationTrackingMode(MyLocationTrackingMode.trackingCompass);
    tripActions = TripActions.none;
  }

  void requestEditing() async {
    tripState = TripState.editing;
    tripActions = TripActions.none;
    tripValues.editing();
    loadBackBuffer();
    mapUpdates = MapUpdates.updateAll;
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  void requestExtendStart() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();
    // addWaypoints methods set the appropriate mapUpdate enum values
    if (isGoodRoad) {
      await addGoodRoadWaypoint(point: tripValues.position);
    } else {
      await addWaypoint(index: -1, point: tripValues.position);
    }
    tripValues.afterWaypoint();
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    isSaved = false;
  }

  void requestWaypoint() async {
// addWaypoints methods set the appropriate mapUpdate enum values
    tripValues.beforeWaypoint();

    if (isGoodRoad) {
      await addGoodRoadWaypoint(
        index: 0,
        point: CurrentTripItem().tripValues.position,
      );
      mapUpdates = mapUpdates.add(MapUpdates.goodRoadsAndGoodRoadWaypoints);
      if (goodRoads.last.waypoints.length == 2) {
        // mapUpdates = mapUpdates.add(MapUpdates.pointsOfInterest);
      }
    } else {
      await addWaypoint(index: 0, point: CurrentTripItem().tripValues.position);
      mapUpdates = MapUpdates.routesAndWaypoints;
    }
    tripValues.afterWaypoint(); // pass flag that we need user to add details
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    isSaved = false;
  }

  void requestRevisitWaypoint() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();
    await addWaypoint(index: 0, point: tripValues.position, revisit: true);
    tripValues.afterWaypoint();
    isSaved = false;
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  void requestExtendEnd() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();
// addWaypoints methods set the appropriate mapUpdate enum values
    await addWaypoint(index: 1, point: CurrentTripItem().tripValues.position);
    tripValues.afterWaypoint();
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    isSaved = false;
  }

  void requestRemoveWaypoint() async {
    tripValues.setState = true;
    if (waypointIndex > -1) {
      await removeWaypoint(index: waypointIndex);
    }
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    tripValues.showTarget = true;
    isSaved = false;
  }

  /// requestPauseRecording() actions:
  ///   1 Pause the stream
  ///   2 Change tripState to TripState.paused
  ///
  void requestPauseTracking() {
    tripState = TripState.pausedTracking;
    tripValues.pauseFollowing();
  }

  /// requestEndRecording
  /// 1 Stop the stream
  /// 2 Change the tripState to TripState.stoppedRecording,
  /// ActionChips Save Trip & Clear Trip

  void requestEndTracking() async {
    tripState = TripState.stoppedTracking;
    await mapController!
        .updateMyLocationTrackingMode(MyLocationTrackingMode.none);
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    tripValues.stopTracking;
  }

  /// The point of interest that describes the good road is added when the good road is ended
  /// goodRoadEnd() - this eliminates problems when icon is tapped accidentally.
  ///
  void requestGreatRoad({String description = '', String sounds = ''}) {
    isGoodRoad = true;
    tripValues.isEditing = tripState == TripState.editing;
    if (CurrentTripItem().goodRoads.isEmpty) {
      goodRoads = [Route(lines: [], waypoints: [])];
    }
    goodRoads.add(Route(id: -1, uri: ''));
    if ([TripState.tracking, TripState.following].contains(tripState)) {
      goodRoads.last.waypoints
          .add(Waypoint(value: 1, point: tripValues.position));
    }
    isSaved = false;
  }

  /// The goodRoadIndex is set when the goodRoad is highlighted while goodRoad = false
  /// The Edit GoodRoad chip is only shown when a goodRoad is highlighted

  void requestEditGreatRoad() {
    isGoodRoad = true;
    isSaved = false;
    tripState = TripState.editing;
  }

  void requestGreatRoadEnd() {
    bool added = goodRoadEnd();
    isGoodRoad = false;
    tripValues.showMask = false;

    if (!added && tripState != TripState.tracking) {
      tripState = tripValues.isEditing ? TripState.editing : TripState.manual;
    }
  }

  void requestPointOfInterest() {
    tripActions = TripActions.pointOfInterest;
    tripValues.showMask = false;
    newPointOfInterest();
    //  mapUpdates = mapUpdates.add(MapUpdates.pointsOfInterest);
    tripValues.pointOfInterestIndex = pointsOfInterest.length - 1;

    return;
  }

  void requestGroup() {
    // CurrentTripItem().tripActions = TripActions.showGroup;
    // CurrentTripItem().tripValues.setState = true;
  }

  void requestMessages() {
    CurrentTripItem().tripActions = TripActions.showMessages;
  }

  void requestTrackRoute() async {
    tripState = TripState.tracking;
    if (tripValues.pauseStream) {
      tripValues.resumeTracking();
      tripState = TripState.tracking;
      await mapController!
          .updateMyLocationTrackingMode(MyLocationTrackingMode.none);
      await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    } else {
      tripValues.startTracking();
      if (routes.isEmpty) {
        routes = [
          Route(lines: [
            [tripValues.position.x.toDouble(), tripValues.position.y.toDouble()]
          ], waypoints: [
            Waypoint(value: 1, point: tripValues.position)
          ])
        ];
      }
      await mapController!
          .updateMyLocationTrackingMode(MyLocationTrackingMode.trackingCompass);
      await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
    }
    return;
  }

  void requestFollowRoute() async {
    tripState = TripState.following;
    developer.log(
        'my_trip_item.dart requestFollowRoute() tripValues.pauseStream: ${tripValues.pauseStream}',
        name: '_actionChips');
    if (tripValues.pauseStream) {
      await mapController!
          .updateMyLocationTrackingMode(MyLocationTrackingMode.trackingCompass);
      await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
      tripValues.resumeFollowing();
    } else {
      await mapController!
          .updateMyLocationTrackingMode(MyLocationTrackingMode.trackingCompass);
      await mapController!.animateCamera(CameraUpdate.zoomTo(12.1));
      await mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(routes.first.lines.first[1], routes.first.lines.first[0]),
        ),
      ); //cameraPosition.target[0] = LatLng()
      //   await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
      tripValues.startFollowing();
    }
    return;
  }

  void requestStopFollowing() async {
    tripState = TripState.stoppedFollowing;
    tripValues.pauseFollowing();
    await mapController!
        .updateMyLocationTrackingMode(MyLocationTrackingMode.none);
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  /// End create_chips.dart state routines.

  void newPointOfInterest({Point? position, int type = 15}) async {
    position = position ??
        Point(
          mapController!.cameraPosition!.target.longitude,
          mapController!.cameraPosition!.target.latitude,
        );
    pointsOfInterest.add(PointOfInterest(point: position, type: type));
    isSaved = false;
  }

  loadBackBuffer({Route? route}) {
    route ??= routes.last;
    backBuffer.clear();
    if (route.waypoints.isNotEmpty) {
      backBuffer.add(route.waypoints);
    }
    backBufferIndex = 0;
  }

  /// nearestTwoWaypoints() returns the nearest two waypoints in route.waypoints[]
  /// [0] is the closest [1] is the next closest

  List<int> nearestTwoWaypoints(
      {required Waypoint waypoint, required Route route}) {
    List<int> idx = [-1, -1];
    List<double> minDistance = [99999999.9, 99999999.9];
    for (int i = 0; i < route.waypoints.length; i++) {
      double distance = distanceBetween(
          startXY: waypoint.point, endXY: route.waypoints[i].point);
      if (distance < minDistance[0]) {
        minDistance[1] = minDistance[0];
        minDistance[0] = distance;
        idx[1] = idx[0];
        idx[0] = i;
      } else if (distance < minDistance[1]) {
        minDistance[1] = distance;
        idx[1] = i;
      }
    }
    return idx;
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

  /// closestWaypoints()
  /// NearestWaypoint strategy
  /// 3 cases:
  ///   1 before waypoint[0] extending start -> waypoint[0]
  ///   2 after waypoint[n] extending end -> waypoint[n]
  ///   3 between waypoint[0] and waypoint[n] -> nearest 2 waypoints

  List<int> closestWaypoints(
      {required Point target,
      required List<Route> routes,
      int routeIndex = 0}) {
    List<int> closest = [];
    if (routes.isNotEmpty) {
      double deltaX = routes[routeIndex].waypoints[0].point.x.toDouble() -
          routes[routeIndex].waypoints.last.point.x.toDouble();
      double deltaY = routes[routeIndex].waypoints[0].point.y.toDouble() -
          routes[routeIndex].waypoints.last.point.y.toDouble();
      if (deltaX.abs() > deltaY.abs()) {
        if (target.x > routes[routeIndex].waypoints[0].point.x) {
          return [0];
        } else if (target.x < routes[routeIndex].waypoints.last.point.x) {
          return [routes[routeIndex].waypoints.length - 1];
        }
      } else {
        if (target.y > routes[routeIndex].waypoints[0].point.y) {
          return [0];
        } else if (target.y < routes[routeIndex].waypoints.last.point.y) {
          return [routes[routeIndex].waypoints.length - 1];
        }
      }
      closest = [0, routes[routeIndex].waypoints.length - 1];
      List<double> distances = [999999, 999999];
      for (int i = 0; i < routes[routeIndex].waypoints.length; i++) {
        try {
          double distance = distanceBetween(
              startXY: target, endXY: routes[routeIndex].waypoints[i].point);
          if (distance < distances[0]) {
            distances[1] = distances[0];
            closest[1] = closest[0];
            distances[0] = distance;
            closest[0] = i;
          } else if (distance < distances[1]) {
            distances[1] = distance;
            closest[1] = i;
          }
        } catch (e) {
          developer.log('Error calculating closest waypoints. ${e.toString()}',
              name: '_repaint_');
        }
      }
    }
    return closest;
  }

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

  addWaypoint({
    int index = 1,
    Point? point,
    bool revisit = false,
    bool insert = false,
  }) async {
    routes = routes.isEmpty ? [Route(waypoints: [])] : routes;
    int insertAt = routes.last.waypoints.length;
    if (waypointState == WaypointState.insert) {
      for (int i = 0; i < routes.last.waypoints.length; i++) {
        if (routes.last.waypoints[i].selected!) {
          insertAt = i + 1;
          break;
        }
      }
    }

    LatLng target = mapController!.cameraPosition!.target;
    point = point == null || point.x == 0
        ? Point(target.longitude, target.latitude)
        : point;
    // routeFeatures.clear();
    Waypoint waypoint = Waypoint(point: point);
    // Set the mapUpdates flag
    routes.last.waypoints.insert(insertAt, waypoint);
    if (routes.last.waypoints.length == 1) {
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

    routes = await replaceRoutes(routes: routes, updateBuffer: false);
    addToBackBuffer();

    mapUpdates = MapUpdates.routesAndWaypoints;

    isSaved = false;
  }

  /// backBuffer is a [List<List<Waypoint>>].
  /// When a waypoint is added then all the routes waypoints should be inserted
  /// at backBuffer[0] - the latest state.
  /// If a waypoint is added when the backBuffer has been rolled-back backBufferIndex > 0
  /// then all the backBuffer values up to backBufferIndex is ditched.
  /// backBuffer.length is restricted to 10

  addToBackBuffer({Route? route}) {
    route ??= routes.last;
    if (backBufferIndex > 0) {
      backBuffer.removeRange(0, backBufferIndex - 1);
    }
    List<Waypoint> waypoints = [];
    for (int i = 0; i < route.waypoints.length; i++) {
      waypoints.add(Waypoint.clone(
          waypoint: route.waypoints[
              i])); // Waypoint.fromMap(map: route.waypoints[i].toMap()));
    }
    backBuffer.insert(0, waypoints);
    backBufferIndex = 0;
    if (backBuffer.length > 10) {
      backBuffer.removeRange(10, backBuffer.length - 1);
    }
  }

  removeWaypoint({int index = 0, int routeIndex = 0}) async {
    routes[routeIndex].waypoints.removeAt(index);
    routes = await replaceRoutes(routes: routes);
    addToBackBuffer(route: routes[routeIndex]);
    mapUpdates = MapUpdates.routesAndWaypoints;
    isSaved = false;
  }

  /// addGoodWaypoint() adds a new GoodRoads.waypoint under the cross-hairs.
  /// If it's the first Good Road waypoint it triggers the Bottom Drawer opening
  /// for the user to enter the description as a PointOfInterest. The PointOfInterest uri
  /// is generated and updates the GoodRoad.pointOfInterestUri too.

  addGoodRoadWaypoint({
    int index = 1,
    required Point point,
    bool revisit = false,
  }) async {
    if (goodRoads.isEmpty) {
      developer.log('GoodRoads is empty! check why', name: '_mapUpdates_');
      goodRoads.add(Route());
    }
    int insertAt =
        goodRoads.last.waypoints.isEmpty ? 0 : goodRoads.last.waypoints.length;
    try {
      Waypoint waypoint = Waypoint(
          point: latLngToPoint(latLng: mapController!.cameraPosition!.target),
          colour: Setup().goodRouteColourHex());
      if (goodRoads.last.waypoints.length == 1 &&
          goodRoads.last.waypoints[0].point.x == 0) {
        goodRoads.last.waypoints[0] = waypoint;
      }
      developer.log('Got to line 989', name: '_geo_json_');
      if (goodRoads.last.waypoints.isEmpty) {
        goodRoads.last.waypoints.add(waypoint);
        String poiUri = goodRoads.last.pointOfInterestUri;
        for (int i = 0; i < pointsOfInterest.length; i++) {
          if (pointsOfInterest[i].uuid == poiUri) {
            pointsOfInterest[i].point = waypoint.point;
          }
        }
      } else {
        if (revisit) {
          insertAt = 0;
        } else {
          if (tripState == TripState.editing) {
            insertAt = index == 1 ? goodRoads.last.waypoints.length : 0;
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
        developer.log('Got to line 1009', name: '_geo_json_');
        goodRoads.last.waypoints.insert(insertAt, waypoint);
      }

      mapUpdates = mapUpdates.add(MapUpdates.goodRoadsAndGoodRoadWaypoints);
      goodRoads = await replaceRoutes(routes: goodRoads);
      List? lastPoint;
      developer.log('Got to line 1018', name: '_geo_json_');
      if (goodRoads.isNotEmpty) {
        if (goodRoads.last.lines.isNotEmpty) {
          lastPoint = goodRoads.last.lines.last;
          goodRoads.last.lines = goodRoads.last.lines;
        }
      }
      isSaved = false;
    } catch (e) {
      developer.log('Error: ${e.toString()}', name: '_geo_json_');
    }
  }

  loadWaypoints({required Point point}) {}

  /// UpdateMapGeometry() takes the data from Waypoints and routes and displays the data on the
  /// map. Should be called after every change of waypoints
  /// CurrentTripItem().goodRoad is the flag to distinguish the waypoint type

  /// deleteWaypoint deletes a waypoint from either the routes List<waypoint> where id is 'i' - the waypoint index
  /// or goodRoads[n].List<waypoint>  where id = 'g_i' where g is the roodRoad index and i the waypoint index
/*
  deleteWaypoint({required String id}) async {
    int index = -1;
    int route = -1;
    List targetWaypoints = routes.last.waypoints;
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
      List<Route> features = await replaceRoutes(routes: goodRoads);
      if (id.contains('_')) {
        goodRoads = features;
      } else {
        routes = features;
      }
      mapUpdates = MapUpdates.routesAndWaypoints;
      isSaved = false;
    }
  }
*/
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

  void updateBackBuffer({required List<Waypoint> waypoints}) {
    if (waypoints.length > 1) {
      /*
      backBuffer.insert(0, []);
      for (int i = 0; i < waypoints.length; i++) {
        backBuffer[0].add(waypoints[i]);
      }
      developer.log(
        'replaceRoutes() adding to backBuffer - length ${backBuffer.length} backBuffer[0] waypoints added: ${backBuffer[0].length}',
        name: '_buffer',
      );
      if (backBuffer.length > 10) {
        backBuffer.removeAt(10);
      }
      backBufferIndex = 0;
    */
    }
  }

  Future<List<Route>> replaceRoutes({
    List<Route>? routes,
    int routeIndex = -1,
    bool updateBuffer = true,
    bool revisit = false,
  }) async {
    routes ??= <Route>[];

    if (routes.isNotEmpty) {
      routeIndex = routeIndex == -1 ? routes.length - 1 : routeIndex;
      updateBackBuffer(waypoints: routes[routeIndex].waypoints);
    }

    if (routes[routeIndex].waypoints.length > 1) {
      try {
        if (updateBuffer) {
          backBuffer[0] = routes[routeIndex].waypoints;
          if (backBuffer.length > 10) {
            backBuffer.removeAt(10);
          }
          backBufferIndex = 0;
        }
        RouterData routeData = await getRouterData(
          route: routes[routeIndex],
          addPoints: true,
          goodRoad: isGoodRoad,
        );
        distance = routeData.distance;
        if (routeData.message == 'OK') {
          List<Maneuver> newManeuvers = [];
          int wps = 0;
          routes = routeData.routes;

          /// Ensure that waypoints don't have both "arrive" and "depart"
          for (int i = 0; i < routeData.maneuvers.length; i++) {
            wps = ['arrive', 'depart'].contains(routeData.maneuvers[i].type)
                ? wps + 1
                : wps;
            bool add = i == 0;
            if (!add) {
              add = !([
                    'arrive',
                    'depart',
                  ].contains(routeData.maneuvers[i].type) &&
                  [
                    'arrive',
                    'depart',
                  ].contains(routeData.maneuvers[i - 1].type));
            }
            if (add) {
              newManeuvers.add(routeData.maneuvers[i]);
            }
          }

          /// Add next 2 lines to ensure the waypoint can be extracted from the maneuvers
          newManeuvers.last.type = 'arrive';
          newManeuvers.last.point = routes.last.waypoints.last.point;
          maneuvers = isGoodRoad ? maneuvers : newManeuvers;
          List<PointOfInterest> pointsOfInterest = reorderWaypoints(
            revisit: revisit,
          );
        } else {
          routes = [];
        }
      } catch (e) {
        developer.log('Error replaceRoutes() ${e.toString()}',
            name: '_geo_json_');
      }
    }
    return routes ?? [];
  }

  /// replaceRoutes() gets the maneuvers from a list of points.
  /// It ensures that everything is in the same order as the router
  /// has supplied.

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

    List<Map<String, dynamic>> routesJSON = [];
    for (int i = 0; i < routes.length; i++) {
      routesJSON.add(routes[i].toMap());
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
        'routes': routesJSON,
        'maneuvers': maneuversJSON,
        'good_roads': goodRoadsJSON,
        'points_of_interest': pointsOfInterestJSON,
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
    List<Route>? features,
  }) async {
    if (tripState == TripState.editing) {
      //  nearestWaypointIndex =
      // features = features ?? routeFeatures;
      List<int> newIndexes = closestWaypoints(target: point, routes: features!);
      //     waypoints: routes.last.waypoints,
      //     point: point,
      //   );

      if (newIndexes[0] != nearestWaypointIndexes[0] ||
          newIndexes[1] != nearestWaypointIndexes[1]) {
        nearestWaypointIndexes[0] = newIndexes[0];
        nearestWaypointIndexes[1] = newIndexes[1];

        for (int i = 0; i < routes.last.waypoints.length; i++) {
          routes.last.waypoints[i].colour = newIndexes.contains(i)
              ? Setup().highlightedColourHex()
              : Setup().routeColourHex();
        }

        newIndexes[0]++;
        newIndexes[1]++;

        /*
        for (int i = 0; i < features.length; i++) {
        
          if (features[i]['properties']['item'] == 'waypoint') {
            features[i]['properties']['color'] =
                newIndexes.contains(features[i]['properties']['number'])
                    ? "hsl(4, 82%, 56%)"
                    : "hsl(188, 53%, 60%)";
          }
          
        }
*/
        developer.log(
          'SetGeoJsonSource() called updateWaypoints() myTripItem.dart 1178',
          name: '_map_',
        );

        mapUpdates = isGoodRoad
            ? mapUpdates.add(MapUpdates.goodRoads)
            : mapUpdates.add(MapUpdates.routes);

        //    String source = goodRoad ? 'good-road-data' : 'route-data';
        //    await mapController!.setGeoJsonSource(source, {
        //      "type": "FeatureCollection",
        //      "features": features,
        //    });
        // Micro-nudge to update MapLibre
        // await mapController!.animateCamera(ml.CameraUpdate.zoomBy(0.000001));
      }
    }
  }

  updateRoutes({
    String id = '',
    List<Map<String, dynamic>>? features,
    String colour = "hsl(4, 82%, 56%",
  }) async {
    /*
    features ??= routeFeatures;

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
    mapUpdates = mapUpdates.add(MapUpdates.routes);
    */
    /*
    await mapController!.setGeoJsonSource(source, {
      "type": "FeatureCollection",
      "features": features,
    });
    */
  }
/*
  updatePointsOfInterest() async {

    List<Map<String, dynamic>> features =
        pointsOfInterestToGeoJSON(pointsOfInterest: pointsOfInterest);
    if (features.isNotEmpty) {
      await mapController!.setGeoJsonSource("point-of-interest-data", {
        "type": "FeatureCollection",
        "features": features,
      });
    }
  }
*/

  highlightWaypoint({String id = ''}) async {
    /*   
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
    */
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
    goodRoads.firstWhere((g) => g.uri == id).colour = colour;

/*
    for (int i = 0; i < goodRoadsFeatures.length; i++) {
      if (goodRoadsFeatures[i]['geometry']['type'] == 'LineString' &&
          (goodRoadsFeatures[i]['id'].toString() == id || id.isEmpty)) {
        goodRoadsFeatures[i]['properties']['color'] = colour;
      }
    }
 MapUpdates.values
        .firstWhere((e) => e.value == (value), orElse: () => MapUpdates.none);


    String source = goodRoad ? 'route-data' : 'good-road-data';
    developer.log(
      'SetGeoJsonSource() called highlightWaypoints() myTripItem.dart 1218',
      name: '_map_',
    );
*/
    goodRoadIndex = id.isEmpty ? goodRoadIndex : int.parse(id.substring(2)) - 1;

    mapUpdates = mapUpdates.add(MapUpdates.goodRoads);

    /*

    await mapController!.setGeoJsonSource(source, {
      "type": "FeatureCollection",
      "features": goodRoadsFeatures,
    });
    */
    // Micro-nudge to update MapLibre
    await mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  Future<void> reverseRoute({List<Map<String, dynamic>>? features}) async {
    // features = features ?? routeFeatures;
    List<Waypoint> points = backBuffer[0];
    backBuffer.insert(0, points.reversed.toList());
    routes.last.waypoints = backBuffer[0];
    routes = await replaceRoutes(routes: routes);
    mapUpdates = MapUpdates.routesAndWaypoints;
  }

  /// Recalculate route
  /// aims:
  ///   1 maintain all the maneuvers already passed
  ///   3 rejoin the route at the nearest sensible waypoint - type arrive
  ///     type "arrive" / "depart" are waypoints entered by the user
  Future<bool> changeRoute({
    required Point position,
    int lastManeuverIndex = 0,
    int routeIndex = 0,
    int pointIndex = 0,
  }) async {
    List<Waypoint> waypoints = CurrentTripItem().routes[routeIndex].waypoints;
    waypoints.clear();

    for (int i = 0; i <= lastManeuverIndex; i++) {
      waypoints.add(
          Waypoint(point: CurrentTripItem().maneuvers[i].point, value: i + 1));
    }

    /// now add current position as a waypoint
    waypoints
        .add(Waypoint(point: tripValues.position, value: waypoints.length + 1));

    /// Now look for closest waypoint to rejoin the route
    try {
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
          waypoints.add(
              Waypoint(point: maneuvers[i].point, value: waypoints.length + 1));
        }
      }

      if (waypoints.length > 2) {
        RouterData tripData = await getRouterData(route: routes.last);
        distance = tripData.distance;
        maneuvers = tripData.maneuvers;
        routes = tripData.routes;
        mapUpdates = MapUpdates.routes;
        await mapController!.setGeoJsonSource('route-data', {
          "type": "FeatureCollection",
          "features": routesToGeoJson(),
        });
      }
    } catch (e) {
      developer.log('Error in my_trip_item.dart changeRoute() :${e.toString()}',
          name: '_save_trip_');
    }
    return waypoints.length > 2;
  }

  bool goodRoadEnd(
      {String name = 'Great road',
      String description = 'Nice road',
      String sounds = ''}) {
    if (tripState == TripState.tracking) {
      goodRoads.last.waypoints.add(
        Waypoint(
            value: goodRoads.last.waypoints.length + 1,
            point: tripValues.position),
      );
    }
    isGoodRoad = false;
    isSaved = false;
    if (goodRoads.isNotEmpty &&
        goodRoads.last.waypoints.length > 1 &&
        goodRoads.last.pointOfInterestUri.isEmpty) {
      String uuid = getUuid();
      Point point = goodRoads.last.waypoints.first.point;
      pointsOfInterest.add(
        PointOfInterest(
          point: point,
          uuid: uuid,
          type: 13,
          name: name,
          description: description,
          sounds: sounds,
        ),
      );
      goodRoads.last.pointOfInterestUri = uuid;
      return true;
    } else {
      goodRoads.removeLast();
      return false;
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
  String score;
  int scored;
  int downloads;
  String authorUri;
  String author;
  double distance;
  double distanceAway;
  List<Route> routes;
  List<Route> goodRoads;
  // List<Waypoint> waypoints;
  List<Maneuver> maneuvers;
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
    this.score = '',
    this.scored = 0,
    this.distance = 0,
    this.distanceAway = 0,
    this.highlights = 0,
    this.closest = 0,
    this.downloads = 0,
    this.authorUri = '',
    this.author = '',
    List<Route>? routes,
    List<Maneuver>? maneuvers,
    List<PointOfInterest>? pointsOfInterest,
    List<Route>? goodRoads,
    this.images = '',
  })  : // driveUri = driveUri ?? getUuid(),
        maneuvers = maneuvers ?? <Maneuver>[],
        goodRoads = goodRoads ?? <Route>[],
        pointsOfInterest = pointsOfInterest ?? <PointOfInterest>[],
        routes = routes ?? <Route>[];

  factory MyTripItem.fromJson({required Map<String, dynamic> jsonObject}) {
    //   List<dynamic> routes = jsonObject["routes"];

    List<Route> routes = routesFromJson(jsonList: jsonObject["routes"]);

    List<Maneuver> maneuvers = maneuversFromJson(
      jsonList: jsonObject["maneuvers"],
    );
    List<Route> goodRoads = goodRoadsFromJson(
      jsonList: jsonObject["good_roads"],
    );

    List<PointOfInterest> pointsOfInterest = pointsOfInterestFromJson(
      jsonList: jsonObject["points_of_interest"],
    );

    /// Need to add all the images that are in each point of interest to trip image list
    /// so the images can be seen from the my_trip_tiles

    List<dynamic> imageList = jsonDecode(jsonObject['images']);
    for (int i = 0; i < pointsOfInterest.length; i++) {
      if (pointsOfInterest[i].images.isNotEmpty) {
        imageList.addAll(jsonDecode(pointsOfInterest[i].images));
      }
    }

    List<Waypoint> waypoints = [];
    MyTripItem tripItem = MyTripItem();
    try {
      tripItem = MyTripItem(
        id: jsonObject["id"] ?? -1,
        uri: jsonObject["uri"] ?? "",
        title: jsonObject["title"] ?? "",
        subTitle: jsonObject["sub_title"] ?? "",
        body: jsonObject["body"] ?? "",
        images: jsonEncode(imageList), // expecting a string not List<dynamic>
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

    List<Map<String, dynamic>> routesJSON = [];
    for (int i = 0; i < routes.length; i++) {
      routesJSON.add(routes[i].toMap());
    }

    List<Map<String, dynamic>> goodRoadsJSON = [];
    for (int i = 0; i < goodRoads.length; i++) {
      goodRoadsJSON.add(goodRoads[i].toMap());
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
      "routes": routesJSON,
      "maneuvers": maneuversJSON,
      "good_roads": goodRoadsJSON,
      "points_of_interest": pointsOfInterestJSON,
      "pois": pointsOfInterestJSON.length,
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
