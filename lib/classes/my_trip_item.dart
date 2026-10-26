import 'dart:async';

import 'dart:convert';
import 'package:universal_io/universal_io.dart' show File;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '/constants.dart' hide routes;
import '/helpers/helpers.dart';
import '/tiles/tiles.dart';
import 'package:image_picker/image_picker.dart';
import '/services/services.dart';
import '/models/other_models.dart';
import '/classes/classes.dart' hide distanceBetween;
import 'package:flutter/material.dart' hide Route;
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';

String colorToHex(Color color) {
  final r = (color.r * 255.0).round().clamp(0, 255);
  final g = (color.g * 255.0).round().clamp(0, 255);
  final b = (color.b * 255.0).round().clamp(0, 255);
  return '#$r$g$b';
}

class CreateTripValues {
  bool showMask = false;
  bool showTarget = false;
  bool autoCentre = false;
  bool stopStream = false;
  bool startStream = false;
  bool pauseStream = false;
  bool resumeStream = false;
  bool isManual = false;
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
  int speed = 0; // mph - set by PositionService while tracking or following
  int pointOfInterestIndex = 0;
  bool setState = true;
  CreateTripValues();
  void manual() {
    showMask = false;
    isManual = true;
    showTarget = true;
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

  void stopFollowing() {
    stopStream = true;
    startStream = false;
    pauseStream = true;
    resumeStream = false;
    lastPosition = position;
  }

  void startFollowing() {
    stopStream = false;
    startStream = true;
    pauseStream = false;
    resumeStream = false;
    showTarget = false;
  }

  void pauseFollowing() {
    stopStream = false;
    startStream = false;
    pauseStream = true;
    resumeStream = false;
    mapHeight = MapHeights.full;
  }

  void startTracking() {
    stopStream = true;
    startStream = false;
    pauseStream = true;
    resumeStream = false;
    lastPosition = position;
  }

  void stopTracking() {
    stopStream = true;
    startStream = false;
    pauseStream = false;
    resumeStream = false;
    mapHeight = MapHeights.full;
  }

  void resumeTracking() {
    resumeFollowing();
  }

  void resumeFollowing() {
    stopStream = false;
    startStream = false;
    pauseStream = false;
    resumeStream = true;
  }

  void beforeWaypoint() {
    showMask = true;
    setState = true;
  }

  void afterWaypoint({bool goodRoadDetails = false}) {
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
  bool isSaved = false;

  /// A trip AI assist suggested (loadSuggestion()) that hasn't been saved -
  /// drawn in the AI colour, with the planner's other finds around it
  bool aiSuggestion = false;

  /// The trip as it was when last saved or loaded - see markSaved()
  String _savedSnapshot = '';

  /// True when clearing or replacing the trip would lose something - used to
  /// warn before Back or loading another trip. It compares the trip with its
  /// state when last saved or loaded, rather than relying on isSaved, which
  /// many actions clear even when nothing ends up different (e.g. an undone
  /// waypoint, an abandoned great road). A trip never saved only has
  /// something to lose if it has any content.
  bool get hasUnsavedChanges => _savedSnapshot.isEmpty
      // A route counts once its line has 2+ points, or it has waypoints but no
      // line yet (Create manually). Tracking records the starting position as
      // a waypoint and line point straight away - nothing to lose until the
      // user has moved.
      ? routes.any((route) =>
              route.lines.length > 1 ||
              (route.waypoints.isNotEmpty && route.lines.isEmpty)) ||
          goodRoads.any((route) => route.waypoints.isNotEmpty) ||
          pointsOfInterest.any((poi) => ![12, 17, 18].contains(poi.type)) ||
          title.isNotEmpty
      : _snapshot() != _savedSnapshot;

  /// A trip that isn't saved on the device - e.g. one just downloaded -
  /// so leaving it warns, like a new one
  void markUnsaved() {
    isSaved = false;
    _savedSnapshot = '';
  }

  /// Call after the trip is saved or loaded
  void markSaved() {
    // Saved without the removed points of interest - their media can go now
    for (String media in _pendingMediaDeletes) {
      deleteMedia(media);
    }
    _pendingMediaDeletes.clear();
    isSaved = true;
    _savedSnapshot = _snapshot();
    _savedMedia = {
      for (PointOfInterest poi in pointsOfInterest) ...mediaOf(poi)
    };
  }

  /// The voice memos and images of the trip as last saved or loaded
  Set<String> _savedMedia = {};

  /// Media of removed points of interest that the saved trip still uses.
  /// Deleted when the trip is next saved; kept if the changes are discarded
  /// (clearAll()) so the saved trip stays complete.
  final Set<String> _pendingMediaDeletes = {};

  /// Deletes a point of interest and its voice memo and images - straight
  /// away, unless the saved trip still uses them (see _pendingMediaDeletes).
  Future<void> removePointOfInterest(int index) async {
    if (index < 0 || index >= pointsOfInterest.length) return;
    PointOfInterest poi = pointsOfInterest.removeAt(index);
    isSaved = false;
    // Take its shield off the map
    refreshMap(change: MapUpdates.pointsOfInterest);
    if (poi.type == 13) {
      // Deleted - undo mustn't bring it back without its media
      for (List<Waypoint> entry in backBuffer) {
        _historyDescriptions[entry]?.remove(poi);
      }
    }
    await _discardMedia(mediaOf(poi));
  }

  /// A single photo removed from a point of interest (ImageArranger) - the
  /// same rule as removing a point of interest
  Future<void> discardPhoto(Photo photo) async {
    isSaved = false;
    await _discardMedia(_mediaOfPhoto(photo));
  }

  /// Deletes media now, or when the trip is saved if the saved trip uses it
  Future<void> _discardMedia(List<String> media) async {
    for (String item in media) {
      if (_savedMedia.contains(item)) {
        _pendingMediaDeletes.add(item);
      } else {
        await deleteMedia(item);
      }
    }
  }

  /// A point of interest's media as 'sound:key', 'image:key' or 'file:path'
  /// (memos and images stored as files before Hive)
  static List<String> mediaOf(PointOfInterest poi) {
    List<String> media = [];
    if (poi.sounds.isNotEmpty) {
      media.add(SoundRepository.isKey(poi.sounds)
          ? 'sound:${poi.sounds}'
          : 'file:${poi.sounds}');
    }
    List<Photo> photos = poi.photos.isNotEmpty || poi.images.isEmpty
        ? poi.photos
        : photosFromJson(photoString: poi.images);
    for (Photo photo in photos) {
      media.addAll(_mediaOfPhoto(photo));
    }
    return media;
  }

  /// A trip's own images (MyTripItem.images) as media
  static List<String> mediaOfImages(String images) => images.isEmpty
      ? []
      : [
          for (Photo photo in photosFromJson(photoString: images))
            ..._mediaOfPhoto(photo)
        ];

  static List<String> _mediaOfPhoto(Photo photo) {
    String key = photo.key.isNotEmpty ? photo.key : getFileName(url: photo.url);
    if (key.length == 32) {
      return ['image:$key'];
    }
    if (!kIsWeb &&
        Setup().appDocumentDirectory.isNotEmpty &&
        photo.url.startsWith(Setup().appDocumentDirectory)) {
      return ['file:${photo.url}'];
    }
    return [];
  }

  static Future<void> deleteMedia(String media) async {
    try {
      String value = media.substring(media.indexOf(':') + 1);
      if (media.startsWith('sound:')) {
        await SoundRepository().delete(value);
      } else if (media.startsWith('image:')) {
        await ImageRepository().deleteImage(value);
      } else if (!kIsWeb && await File(value).exists()) {
        await File(value).delete();
      }
    } catch (e) {
      developer.log('Error deleting point of interest media $media: $e',
          name: 'error');
    }
  }

  /// The parts of the trip a user can change. The Start / Waypoint / End
  /// points of interest (12, 17, 18) just mirror the waypoints.
  String _snapshot() => jsonEncode({
        'title': title,
        'subTitle': subTitle,
        'body': body,
        'waypoints': [
          for (Route route in routes)
            [
              for (Waypoint w in route.waypoints)
                [w.point.x, w.point.y, w.revisit, w.isGoodRoad]
            ]
        ],
        // A tracked route grows between waypoints
        'lines': [for (Route route in routes) route.lines.length],
        'goodRoads': [
          for (Route route in goodRoads)
            [
              for (Waypoint w in route.waypoints) [w.point.x, w.point.y]
            ]
        ],
        'pointsOfInterest': [
          for (PointOfInterest poi in pointsOfInterest)
            if (![12, 17, 18].contains(poi.type))
              [
                poi.type,
                poi.name,
                poi.description,
                poi.point.x,
                poi.point.y,
                poi.images,
                poi.sounds
              ]
        ],
      });
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
  MapLibreMapController? mapController = MapService().controller;
  TripHeaderController tripHeaderController = TripHeaderController();
  String groupDriveId = '';
  Map<String, dynamic> geoJson = {};

  final GlobalKey mapLibreKey = GlobalKey();
  List bottomDrawerItems = [];
  int waypointIndex = -1;
  List<Follower> followers = [];
  List<TripMessage> tripMessages = [];
  ImageInMemory? mapImage;
  ImageRepository? imageRepository;

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

  static CurrentTripItem? _instance;

  CurrentTripItem._internal();

  factory CurrentTripItem() => _instance ??= CurrentTripItem._internal();

  static void reset() {
    _instance = null;
  }

  void fromMyTripItem({required MyTripItem myTripItem}) async {
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
    await MapService().controller?.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  @override
  void clearAll({TripState newTripState = TripState.clearing}) async {
    // Descriptions only kept for redo go with the history - first, while
    // _savedMedia still protects any the saved trip uses
    _ditchDescriptions(backBuffer, const []);
    isSaved = false;
    _savedSnapshot = '';
    // Changes discarded - the saved trip keeps the media of any points of
    // interest removed since it was saved
    _savedMedia = {};
    _pendingMediaDeletes.clear();
    id = -1;
    imageUrls = "";
    driveUri = '';
    title = '';
    subTitle = '';
    body = '';
    images = '';
    // New lists rather than clear() - after a trip is loaded these are the
    // My Trips item's own lists, and clear() would empty that too
    backBuffer = [];
    maneuvers = [];
    routes = [];
    goodRoads = [];
    pointsOfInterest = [];
    isTracking = false;
    tripType = TripType.none;
    tripState = newTripState;
    tripActions = TripActions.none;
    highliteActions = HighliteActions.none;
    tripValues.showTarget = false;
    isSaved = false;
    isGoodRoad = false;
    aiSuggestion = false;
    appState = AppState.createTrip;
    nearestWaypoints = Point(0, 0);
    mapUpdates = MapUpdates.updateAll;
    backBufferIndex = 0;
    tripValues.title = 'Create a new trip';
    mapUpdates = MapUpdates.updateAll;
    tripValues.autoCentre = false;
    tripState = TripState.none;
    MapService().webAppBarController?.update();
    MapService().persistentAppBarController?.refresh();
    MapService().showLocation(); // hide the position marker
    tripHeaderController.clear();
  }

  RouteDelta goodRoadStart = RouteDelta();
  RouteDelta routeDelta = RouteDelta();
  WaypointState waypointState = WaypointState.none;
  // Replays the route as positions instead of the GPS, to test following,
  // turn-by-turn and group drives: --dart-define=DRIVES_REPLAY=true
  bool debugging = const bool.fromEnvironment('DRIVES_REPLAY');
  final String debuggingRoute = ''; // <-- Route name to follow

  /// load() method to hydrate the CurrentTripItem object with data from the
  /// api or the local SQLite database
  /// It sets the state flags and marks updateMap as true to make sure the map
  /// is redrawn on the first onIdle with the trip data.
  ///

  void load({required TripArguments arguments}) {
    fromMyTripItem(myTripItem: arguments.trip ?? MyTripItem());
    tripState = TripState.loaded;
    tripActions = TripActions.none;
    highliteActions = HighliteActions.none;
    tripValues.showTarget = false;
    updateMap = true;
    //mapController!.
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

  List<Waypoint> get waypoints => backBuffer.last;

  WaypointState setWaypointState(WaypointState state) => waypointState = state;

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
    int result = (CurrentTripItem().title.isNotEmpty ? 1 : 0) |
        (CurrentTripItem().subTitle.isNotEmpty ? (1 << 1) : 0) |
        (CurrentTripItem().body.isNotEmpty ? (1 << 2) : 0);
    return result;
  }

  /// When the create_trip.dart BottomDrawer is closed
  /// have to ensure that the map is updated for PointsOfInterest
  /// by setting the mapUpdates flag for points of interest

  void drawerClosed() {
    if (bottomDrawerData.isPointOfInterest) {
      mapUpdates = mapUpdates.add(MapUpdates.pointsOfInterest);
      MapService().updateMapGeoJson(mapUpdates: mapUpdates);
    }
    bottomDrawerData.completed();
  }

  Future<void> refreshMap({MapUpdates change = MapUpdates.updateAll}) async {
    developer.log('CurrentTripItem().refreshMap() called', name: 'goodRoad');
    try {
      if (change == MapUpdates.none || change == MapUpdates.updateAll) {
        mapUpdates = change;
      } else {
        mapUpdates = mapUpdates.add(change);
      }
      // Awaited so the micro-nudge comes after the sources are set - without
      // it e.g. a new point of interest's shield could miss the redraw
      await MapService().updateMapGeoJson(mapUpdates: mapUpdates);
      // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
      await MapService()
          .controller!
          .animateCamera(CameraUpdate.zoomBy(0.000001));
    } catch (e) {
      developer.log(
          'Error CurrentTripItem().refreshMap() called BUT FAILED: ${e.toString()}',
          name: 'error');
    }
  }

  void newWaypoint({Point? point}) {
    point = point ?? Point(0, 0);
    routes.last.waypoints
        .add(Waypoint(point: point, value: routes.last.waypoints.length + 1));
    if (isGoodRoad) {
      goodRoads.last.waypoints.add(Waypoint(
          point: point,
          value: goodRoads.last.waypoints.length + 1,
          isGoodRoad: true));
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
              if (canUndo) {
                await undo();
                onUpdate?.call(true);
              }
            },
            icon: Icon(
              Icons.undo_outlined,
              color: canUndo ? Colors.white : Colors.grey,
            ),
          ),
        );

        actions.add(
          IconButton(
            onPressed: () async {
              if (canRedo) {
                await redo();
                onUpdate?.call(true);
              }
            },
            icon: Icon(
              Icons.redo_outlined,
              color: canRedo ? Colors.white : Colors.grey,
            ),
          ),
        );
        MapService().webAppBarController?.update();
      }
    }
    return actions;
  }

  Future<bool> saveState() async {
    try {
      Setup().save();
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
        if (imageFile != null) {}
      }
      Setup().appState = '';
      Setup().save();
    }
    return true;
  }

  void onBackPressed() {
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

  Future<void> requestClear() async {
    tripValues.setState = true;

    /// clearAll sets tripState to TripState.clearing making sure that the geoJson is updated on next _onIdle
    clearAll(newTripState: TripState.clearing);
    // Everything has been cleared, so redraw every source - routesAndWaypoints
    // left the points of interest and great roads on the map
    mapUpdates = MapUpdates.updateAll;
    MapService().updateMapGeoJson(mapUpdates: mapUpdates);
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called

    MapService().createTripController!.update();
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  Future<void> requestAddManually() async {
    clearAll(newTripState: TripState.manualStart);
    uri = uri.isEmpty ? getUuid() : uri;
    tripValues.manual(); // <-- Set all the manual flags
    tripState = TripState.manual;
    if (CurrentTripItem().routes.isEmpty) {
      CurrentTripItem().routes = [Route(lines: [], waypoints: [])];
    }
    CurrentTripItem().tripValues.showTarget = true;
    await MapService().controller!.updateMyLocationTrackingMode(
        MyLocationTrackingMode.none); // trackingCompass);
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
    MapService().createTripController!.update();
    tripActions = TripActions.headingDetail;
  }

  Future<void> requestAddAutomatically() async {
    clearAll(newTripState: TripState.tracking);
    uri = uri.isEmpty ? getUuid() : uri;
    tripValues.track();
    if (CurrentTripItem().routes.isEmpty) {
      CurrentTripItem().routes = [Route(lines: [], waypoints: [])];
    }
    await MapService().controller!.updateMyLocationTrackingMode(
        MyLocationTrackingMode.none); // trackingCompass);
    MapService().createTripController!.update();
    tripActions = TripActions.none;
  }

  /// The trip AI assist suggested (PlannerService) becomes the trip being
  /// planned, in Edit mode - the user changes it like any other, and undo
  /// goes back no further than the suggestion. waypoints are routed here;
  /// stops are its points of interest.
  Future<void> loadSuggestion({
    required List<Waypoint> waypoints,
    required List<PointOfInterest> stops,
    required String title,
    required String subTitle,
    required String body,
  }) async {
    clearAll(newTripState: TripState.editing);
    uri = getUuid();
    this.title = title;
    this.subTitle = subTitle;
    this.body = body;
    aiSuggestion = true;
    routes = [Route(waypoints: waypoints)];
    syncWaypointPointsOfInterest(waypoints: routes.last.waypoints);
    pointsOfInterest.addAll(stops);
    List<Route> routed = await replaceRoutes(routes: routes, updateBuffer: false);
    if (routed.isNotEmpty) routes = routed;
    await syncGoodRoads();
    loadBackBuffer();
    tripState = TripState.editing;
    tripValues.editing();
    markUnsaved();
    mapUpdates = MapUpdates.updateAll;
    await MapService().updateMapGeoJson(mapUpdates: mapUpdates);
    MapService().createTripStackController?.refresh();
  }

  Future<void> requestEditing() async {
    tripState = TripState.editing;
    tripActions = TripActions.none;
    tripValues.editing();
    loadBackBuffer();
    mapUpdates = MapUpdates.updateAll;
    MapService().updateMapGeoJson(mapUpdates: mapUpdates);
    MapService().createTripController!.update();
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  Future<void> requestExtendStart() => _routeChange(_requestExtendStart);

  Future<void> _requestExtendStart() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();
    // addWaypoints methods set the appropriate mapUpdate enum values
    // The new waypoint becomes waypoint 1 and the rest move up one
    if (isGoodRoad) {
      addGoodRoadWaypoint(point: tripValues.position);
    } else {
      await addWaypoint(atStart: true, point: tripValues.position);
    }
    tripValues.afterWaypoint();
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    MapService().createTripController!.update();
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
    isSaved = false;
  }

  Future<void> requestWaypoint() => _routeChange(_requestWaypoint);

  Future<void> _requestWaypoint() async {
// addWaypoints methods set the appropriate mapUpdate enum values

    tripValues.beforeWaypoint();
    tripState = tripState =
        tripState == TripState.manualStart ? TripState.manual : tripState;
    // During a great road addWaypoint() flags the waypoint isGoodRoad and
    // the great roads are rebuilt from the route (syncGoodRoads())
    await addWaypoint(index: 0, point: tripValues.position);
    tripValues.afterWaypoint(); // pass flag that we need user to add details
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    MapService().createTripController!.update();
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
    isSaved = false;
  }

  Future<void> requestRevisitWaypoint() =>
      _routeChange(_requestRevisitWaypoint);

  Future<void> _requestRevisitWaypoint() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();
    List<Waypoint> waypoints = routes.isEmpty ? [] : routes.first.waypoints;
    if (waypointIndex > -1 && waypointIndex < waypoints.length) {
      // Use the earlier waypoint's exact point, not the crosshair's, so the
      // router goes through the same point. It's appended to the route with
      // no marker of its own - the earlier waypoint keeps the lower number.
      await addWaypoint(point: waypoints[waypointIndex].point, revisit: true);
    }
    tripValues.afterWaypoint();
    isSaved = false;
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    MapService().createTripController!.update();
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  Future<void> requestExtendEnd() => _routeChange(_requestExtendEnd);

  Future<void> _requestExtendEnd() async {
    tripActions = TripActions.none;
    tripValues.beforeWaypoint();
// addWaypoints methods set the appropriate mapUpdate enum values

    await addWaypoint(index: 0, point: tripValues.position);
    tripValues.afterWaypoint();
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    MapService().createTripController!.update();
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
    isSaved = false;
  }

  Future<void> requestRemoveWaypoint() => _routeChange(_requestRemoveWaypoint);

  Future<void> _requestRemoveWaypoint() async {
    tripValues.setState = true;
    if (waypointIndex > -1) {
      await removeWaypoint(index: waypointIndex);
    }
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    MapService().createTripController!.update();
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
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
    MapService().createTripController!.update();
  }

  /// requestEndRecording
  /// 1 Stop the stream
  /// 2 Change the tripState to TripState.stoppedRecording,
  /// ActionChips Save Trip & Clear Trip

  Future<void> requestEndTracking() async {
    tripState = TripState.stoppedTracking;
    await MapService()
        .controller!
        .updateMyLocationTrackingMode(MyLocationTrackingMode.none);
    MapService().createTripController!.update();
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
    tripValues.stopTracking;
  }

  /// The point of interest that describes the good road is added when the good road is ended
  /// goodRoadEnd() - this eliminates problems when icon is tapped accidentally.
  ///
  /// In Create manually and Edit modes great roads are made from the route:
  /// a waypoint added during a great road is a route waypoint flagged
  /// isGoodRoad (the leg arriving at it is great road). Each run of flagged
  /// waypoints, with the waypoint before it, is a great road. goodRoads is
  /// rebuilt from the route whenever it changes - waypoints added, removed,
  /// undone, redone or reversed - and is still saved separately, to show
  /// nice stretches of road and so users can join up with ones others have
  /// published. Great roads recorded while tracking, or saved before great
  /// roads were route waypoints, have waypoints off the route and are left
  /// as they are.
  Future<void> syncGoodRoads() async {
    if (tripState == TripState.tracking) return;
    Route? route = routes.isEmpty ? null : routes.last;
    List<Waypoint> waypoints = route?.waypoints ?? [];
    bool onRoute(Waypoint w) => waypoints.any((r) => r.point == w.point);
    List<Route> kept = [];
    List<Route> previous = [];
    for (Route goodRoad in goodRoads) {
      if (goodRoad.waypoints.isEmpty) continue; // placeholder
      // Built from the route before (fromRoute), or a loaded trip's great
      // road on its route - rebuilt below. Testing only "on the route" left
      // a great road behind, stale, once undo or remove took a waypoint off.
      if (goodRoad.fromRoute || goodRoad.waypoints.every(onRoute)) {
        previous.add(goodRoad);
      } else {
        kept.add(goodRoad);
      }
    }
    // Where each waypoint is on the route's line - a great road's line is
    // cut from the route's, so it's ready as soon as the route is
    List<int> indices = route == null || route.lines.length < 2
        ? []
        : waypointLineIndices(route);
    List<Route> rebuilt = [];
    int i = 0;
    while (i < waypoints.length) {
      if (!waypoints[i].isGoodRoad) {
        i++;
        continue;
      }
      int end = i;
      while (end + 1 < waypoints.length && waypoints[end + 1].isGoodRoad) {
        end++;
      }
      int start = i > 0 ? i - 1 : i;
      List<Waypoint> stretch = [
        for (int k = start; k <= end; k++)
          Waypoint(
              point: waypoints[k].point,
              isGoodRoad: true,
              colour: Setup().goodRouteColourHex())
      ];
      Route goodRoad = _goodRoadFor(stretch, previous);
      if (indices.length == waypoints.length && indices[end] > indices[start]) {
        goodRoad.lines = [
          for (List<double> point
              in route!.lines.sublist(indices[start], indices[end] + 1))
            [point[0], point[1]]
        ];
      }
      if (goodRoad.pointOfInterestUri.isEmpty) {
        // e.g. undone then redone - reconnect its description, which is
        // still in the trip at the great road's start
        Set<String> used = {
          for (Route r in [...kept, ...rebuilt]) r.pointOfInterestUri
        };
        PointOfInterest? description = pointsOfInterest
            .where((poi) =>
                poi.type == 13 &&
                _onStretch(poi.point, goodRoad) &&
                !used.contains(poi.uuid))
            .firstOrNull;
        if (description != null) {
          goodRoad.pointOfInterestUri = description.uuid;
        }
      }
      rebuilt.add(goodRoad);
      i = end + 1;
    }
    goodRoads = [...kept, ...rebuilt];
  }

  /// A description point of interest belongs to the great road it's on -
  /// within 30m of its line (it's placed in the middle), or at its start
  bool _onStretch(Point point, Route goodRoad) =>
      point == goodRoad.waypoints.first.point ||
      goodRoad.lines.any((p) =>
          Geolocator.distanceBetween(
              point.y.toDouble(), point.x.toDouble(), p[1], p[0]) <
          30);

  /// A great road for the stretch, keeping a previous one's description
  /// (pointOfInterestUri) if it's the same great road - same start, or the
  /// same points (reversed)
  Route _goodRoadFor(List<Waypoint> stretch, List<Route> previous) {
    bool related(Route r) =>
        r.waypoints.first.point == stretch.first.point ||
        (r.waypoints.length == stretch.length &&
            stretch.every((w) => r.waypoints.any((p) => p.point == w.point)));
    Route? match = previous.where(related).firstOrNull;
    return Route(
      id: match?.id ?? -1,
      uri: match?.uri ?? '',
      waypoints: stretch,
      colour: Setup().goodRouteColourHex(),
      pointOfInterestUri: match?.pointOfInterestUri ?? '',
    )..fromRoute = true;
  }

  /// The map sources to redraw after the route changes
  /// Every source - redrawing only some left e.g. a removed great road's
  /// layers showing their old contents
  MapUpdates get _routeMapUpdates => MapUpdates.updateAll;

  /// Route changes wait for the router. One started meanwhile (e.g. undo
  /// tapped again) could interleave with it and muddle the route, so it's
  /// ignored until the first has finished.
  bool _changingRoute = false;

  Future<void> _routeChange(Future<void> Function() change) async {
    if (_changingRoute) return;
    _changingRoute = true;
    try {
      await change();
    } finally {
      _changingRoute = false;
      _logRoute('route changed');
    }
  }

  /// Diagnostics (name _route_): each waypoint N(ormal) / G(reat road)
  /// (r = revisit), each great road R (from the route) / K (kept, off the
  /// route) with waypoint / line point counts, and the undo history.
  void _logRoute(String event) => debugPrint('[_route_] $event: waypoints ${[
        for (Waypoint w
            in routes.isEmpty ? <Waypoint>[] : routes.last.waypoints)
          '${w.isGoodRoad ? 'G' : 'N'}${w.revisit ? 'r' : ''}'
      ]} great roads ${[
        for (Route g in goodRoads)
          '${g.fromRoute ? 'R' : 'K'}${g.waypoints.length}/${g.lines.length}'
      ]} descriptions ${pointsOfInterest.where((poi) => poi.type == 13).length}'
          ' history ${backBuffer.length} at $backBufferIndex');

  void requestGreatRoad({String description = '', String sounds = ''}) {
    isGoodRoad = true;
    tripValues.isEditing = tripState == TripState.editing;
    // When tracking or following a great road is recorded from positions.
    // Otherwise the waypoints added next are flagged (see syncGoodRoads()).
    if ([TripState.tracking, TripState.following].contains(tripState)) {
      if (CurrentTripItem().goodRoads.isEmpty) {
        goodRoads = [Route(lines: [], waypoints: [])];
      }
      goodRoads.add(Route(id: -1, uri: ''));
      goodRoads.last.waypoints
          .add(Waypoint(value: 1, point: tripValues.position));
    }
    MapService().createTripController!.update();
    isSaved = false;
  }

  /// The goodRoadIndex is set when the goodRoad is highlighted while goodRoad = false
  /// The Edit GoodRoad chip is only shown when a goodRoad is highlighted

  void requestEditGreatRoad() {
    isGoodRoad = true;
    isSaved = false;
    tripState = TripState.editing;
    MapService().createTripController!.update();
  }

  /// True when the great road got a description to fill in - its index is
  /// then tripValues.pointOfInterestIndex
  bool requestGreatRoadEnd() {
    bool added = goodRoadEnd();
    isGoodRoad = false;
    tripValues.showMask = false;
    if (added) tripValues.pointOfInterestIndex = pointsOfInterest.length - 1;

    if (!added && tripState != TripState.tracking) {
      tripState = tripValues.isEditing ? TripState.editing : TripState.manual;
    }
    MapService().createTripController!.update();
    return added;
  }

  Future<void> requestPointOfInterest() async {
    tripActions = TripActions.pointOfInterest;
    tripValues.showMask = false;
    newPointOfInterest();
    tripValues.pointOfInterestIndex = pointsOfInterest.length - 1;
    MapService().createTripController!.update();
    // Show its shield straight away, not only when the drawer closes
    await refreshMap(change: MapUpdates.pointsOfInterest);
  }

  void requestGroup() {}

  void requestMessages() {
    CurrentTripItem().tripActions = TripActions.showMessages;
  }

  Future<void> requestTrackRoute() async {
    tripState = TripState.tracking;
    if (tripValues.pauseStream) {
      tripValues.resumeTracking();
      tripState = TripState.tracking;
      await MapService()
          .controller!
          .updateMyLocationTrackingMode(MyLocationTrackingMode.none);
      await MapService()
          .controller!
          .animateCamera(CameraUpdate.zoomBy(0.000001));
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
      await MapService().controller!.updateMyLocationTrackingMode(
          MyLocationTrackingMode.none); // PositionService moves the camera
      await MapService()
          .controller!
          .animateCamera(CameraUpdate.zoomBy(0.000001));
    }
    return;
  }

  /// What following this trip has noted - see DrivenLog
  DrivenLog? drivenLog;

  /// A new log for following this trip - if the user agreed, is logged in,
  /// and it's a published trip (or a copy of one)
  void _startDrivenLog() {
    drivenLog = null;
    if (!Setup().verifyDriven || Setup().jwt.isEmpty || publishedUri.isEmpty) {
      return;
    }
    drivenLog = DrivenLog(
      tripUri: publishedUri,
      // its turns - or, for a trip without turn instructions, points along
      // its route
      checkpoints: maneuvers.isNotEmpty
          ? [for (Maneuver maneuver in maneuvers) maneuver.point]
          : DrivenLog.pointsAlong([for (Route route in routes) ...route.lines]),
      pointsOfInterest: {
        for (PointOfInterest poi in pointsOfInterest)
          if (!DrivenLog.notVisitable.contains(poi.type)) poi.uuid: poi.point
      },
    );
  }

  Future<void> requestFollowRoute() async {
    tripState = TripState.following;
    if (!tripValues.pauseStream) _startDrivenLog(); // not when resuming
    if (tripValues.pauseStream) {
      await MapService().controller!.updateMyLocationTrackingMode(
          MyLocationTrackingMode.none); // PositionService moves the camera
      await MapService()
          .controller!
          .animateCamera(CameraUpdate.zoomBy(0.000001));
      tripValues.resumeFollowing();
    } else {
      await MapService().controller!.updateMyLocationTrackingMode(
          MyLocationTrackingMode.none); // PositionService moves the camera
      await MapService().controller!.animateCamera(CameraUpdate.zoomTo(12.1));
      await MapService().controller!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(routes.first.lines.first[1], routes.first.lines.first[0]),
            ),
          ); //cameraPosition.target[0] = LatLng()
      tripValues.startFollowing();
      MapService().createTripController!.update();
    }
    return;
  }

  Future<void> requestStopFollowing() async {
    tripState = TripState.stoppedFollowing;
    tripValues.pauseFollowing();
    // The summary of the drive - resuming carries on the same log
    if (drivenLog?.hasSomething ?? false) sendDriven(drivenLog!);
    await MapService()
        .controller!
        .updateMyLocationTrackingMode(MyLocationTrackingMode.none);
    MapService().createTripController!.update();
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  /// End create_chips.dart state routines.

  void newPointOfInterest({Point? position, int type = 15}) async {
    try {
      pointsOfInterest
          .add(PointOfInterest(point: tripValues.position, type: type));
    } catch (e) {
      developer.log('Error trying to add point of interest: ${e.toString()}',
          name: 'error');
    }
    MapService().createTripController!.update();
    isSaved = false;
  }

  /// Starts the undo history with just the current waypoints, so undo only
  /// applies to changes made after this - e.g. after a trip is loaded.
  /// Stores a copy so later changes to the route don't alter the buffer.
  void loadBackBuffer({Route? route}) {
    route ??= routes.isEmpty ? Route() : routes.last;
    List<Waypoint> entry = [
      for (Waypoint waypoint in route.waypoints)
        Waypoint.clone(waypoint: waypoint)
    ];
    _historyDescriptions[entry] = _descriptions;
    backBuffer = [entry];
    backBufferIndex = 0;
    MapService().webAppBarController?.update();
    MapService().persistentAppBarController?.refresh();
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
              name: 'error');
        }
      }
    }
    return closest;
  }

  void setPointOfInterestType() {
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

  /// addWaypoint() adds a new waypoint under the crosshairs - at the end, or
  /// at the start when atStart (Extend start), or after the selected waypoint
  /// when waypointState is insert.
  /// the call to replaceRoutes() ensures that everything is in
  /// the correct sequence.
  /// It generates the geoJSON data for the routes, waypoints and points of interest.

  Future<void> addWaypoint({
    int index = 1,
    Point? point,
    bool revisit = false,
    bool insert = false,
    bool atStart = false,
  }) async {
    try {
      routes = routes.isEmpty ? [Route(waypoints: [])] : routes;
      int insertAt = routes.last.waypoints.length;
      if (atStart) {
        insertAt = 0;
      } else if (waypointState == WaypointState.insert &&
          tripState == TripState.editing &&
          !isGoodRoad) {
        // (A great road carries on from the last waypoint, so it appends)
        // Insert after the first highlighted anchor - see getWaypointState()
        for (int i = 0; i < routes.last.waypoints.length; i++) {
          if (routes.last.waypoints[i].selected!) {
            insertAt = i + 1;
            break;
          }
        }
      }
      // No point given - the waypoint goes under the crosshair
      if (point == null || point.x == 0) {
        LatLng target = MapService().controller!.cameraPosition!.target;
        point = Point(target.longitude, target.latitude);
      }
      // A waypoint added during a great road is flagged as part of it
      Waypoint waypoint = Waypoint(
          point: point,
          revisit: revisit,
          isGoodRoad: isGoodRoad && tripState != TripState.tracking);
      // Set the mapUpdates flag
      routes.last.waypoints.insert(insertAt, waypoint);
      // Start / Waypoint / End points of interest follow the new order -
      // previously a new End was always added, wrong for Extend start / Insert
      syncWaypointPointsOfInterest(waypoints: routes.last.waypoints);

      routes = await replaceRoutes(routes: routes, updateBuffer: false);
      await syncGoodRoads();
      addToBackBuffer();

      mapUpdates = _routeMapUpdates;

      // Awaited so the micro-nudge that follows comes after every source is
      // set - otherwise e.g. the great road could miss the redraw
      await MapService().updateMapGeoJson(mapUpdates: mapUpdates);

      isSaved = false;
    } catch (e) {
      developer.log('CurrentTripItem().addWaypoint() error: ${e.toString()}',
          name: 'error');
    }
  }

  /// backBuffer is a [List<List<Waypoint>>].
  /// When a waypoint is added then all the routes waypoints should be inserted
  /// at backBuffer[0] - the latest state.
  /// If a waypoint is added when the backBuffer has been rolled-back backBufferIndex > 0
  /// then all the backBuffer values up to backBufferIndex is ditched.
  /// Undo steps back through every waypoint - great road or not - so the
  /// history isn't limited (it was 10, which stopped undo part way back).
  /// Each state is only a list of waypoints.

  void addToBackBuffer({Route? route}) {
    route ??= routes.last;
    if (backBufferIndex > 0) {
      // Ditch the undone states - removeRange's end is exclusive
      _ditchDescriptions(backBuffer.sublist(0, backBufferIndex),
          backBuffer.sublist(backBufferIndex));
      backBuffer.removeRange(0, backBufferIndex);
    }
    if (backBuffer.isEmpty) {
      // A new trip - start from no waypoints so the first can be undone too.
      // (A loaded trip starts from its saved waypoints - loadBackBuffer())
      List<Waypoint> start = [];
      _historyDescriptions[start] = [];
      backBuffer.add(start);
    }
    List<Waypoint> waypoints = [];
    for (int i = 0; i < route.waypoints.length; i++) {
      waypoints.add(Waypoint.clone(
          waypoint: route.waypoints[
              i])); // Waypoint.fromMap(map: route.waypoints[i].toMap()));
    }
    _historyDescriptions[waypoints] = _descriptions;
    backBuffer.insert(0, waypoints);
    backBufferIndex = 0;
    MapService().webAppBarController?.update();
    MapService().persistentAppBarController?.refresh();
  }

  /// The great road descriptions (type 13 points of interest) at each undo
  /// history entry, so undo takes a description away with its great road and
  /// redo brings it back. Keyed on the entry, so it can't get out of step.
  final Expando<List<PointOfInterest>> _historyDescriptions = Expando();

  List<PointOfInterest> get _descriptions =>
      pointsOfInterest.where((poi) => poi.type == 13).toList();

  /// Records the descriptions with the current history entry - Normal road
  /// mode adds one after the entry was made
  void _recordDescriptions() {
    if (backBufferIndex >= 0 && backBufferIndex < backBuffer.length) {
      _historyDescriptions[backBuffer[backBufferIndex]] = _descriptions;
    }
  }

  /// A description only in history entries being thrown away - undone and
  /// then a new change made, or the trip cleared - is ditched with its
  /// photos and memo (now, or when saved if the saved trip uses them)
  void _ditchDescriptions(
      Iterable<List<Waypoint>> discarded, Iterable<List<Waypoint>> remaining) {
    Set<PointOfInterest> keep = {
      ...pointsOfInterest,
      for (List<Waypoint> entry in remaining) ...?_historyDescriptions[entry],
    };
    Set<PointOfInterest> ditch = {
      for (List<Waypoint> entry in discarded) ...?_historyDescriptions[entry],
    }..removeAll(keep);
    for (PointOfInterest poi in ditch) {
      _discardMedia(mediaOf(poi));
    }
  }

  /// backBuffer[0] is the latest state, so undo moves backBufferIndex up
  /// and redo moves it back down.
  bool get canUndo => backBufferIndex < backBuffer.length - 1;

  bool get canRedo => backBufferIndex > 0;

  Future<void> undo() => _routeChange(() async {
        if (canUndo) {
          await _restoreBackBuffer(++backBufferIndex);
        }
      });

  Future<void> redo() => _routeChange(() async {
        if (canRedo) {
          await _restoreBackBuffer(--backBufferIndex);
        }
      });

  /// Restores a copy of backBuffer[index] - a copy so later changes to the
  /// route don't alter the buffer.
  Future<void> _restoreBackBuffer(int index) async {
    if (routes.isEmpty) {
      routes = [Route()];
    }
    routes.last.waypoints = [
      for (Waypoint waypoint in backBuffer[index])
        Waypoint.clone(waypoint: waypoint)
    ];
    // The great road descriptions as they were at this point
    List<PointOfInterest>? descriptions =
        _historyDescriptions[backBuffer[index]];
    if (descriptions != null) {
      pointsOfInterest
        ..removeWhere((poi) => poi.type == 13)
        ..addAll(descriptions);
    }
    syncWaypointPointsOfInterest(waypoints: routes.last.waypoints);
    if (routes.last.waypoints.length > 1) {
      List<Route> rerouted =
          await replaceRoutes(routes: routes, updateBuffer: false);
      if (rerouted.isNotEmpty) {
        routes = rerouted;
      }
    } else {
      // Too few waypoints to route - remove the old line and maneuvers
      routes.last.lines = [];
      maneuvers.clear();
      distance = 0;
    }
    waypointIndex = -1;
    waypointState = WaypointState.none;
    isSaved = false;
    await syncGoodRoads();
    mapUpdates = _routeMapUpdates;
    // Awaited so the micro-nudge that follows comes after every source is
    // set - otherwise e.g. the great road could miss the redraw
    await MapService().updateMapGeoJson(mapUpdates: mapUpdates);
    MapService().webAppBarController?.update();
    MapService().persistentAppBarController?.refresh();
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await MapService().controller?.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  /// removeWaypoint() works in both manual and editing modes.
  /// The numbers shown on the map come from each waypoint's position in the
  /// list, so they renumber themselves when the geoJson is regenerated.
  /// The Start / Waypoint / End points of interest are renumbered here.
  Future<void> removeWaypoint({int index = 0, int routeIndex = 0}) async {
    if (routeIndex >= routes.length ||
        index < 0 ||
        index >= routes[routeIndex].waypoints.length) {
      return;
    }
    Waypoint removed = routes[routeIndex].waypoints.removeAt(index);
    if (!removed.revisit) {
      // Its revisits have no markers, so they'd be left invisible but routed
      routes[routeIndex]
          .waypoints
          .removeWhere((w) => w.revisit && w.point == removed.point);
    }
    syncWaypointPointsOfInterest(waypoints: routes[routeIndex].waypoints);
    if (routes[routeIndex].waypoints.length > 1) {
      // Keep the waypoints if the router fails rather than losing the trip
      List<Route> rerouted =
          await replaceRoutes(routes: routes, updateBuffer: false);
      if (rerouted.isNotEmpty) {
        routes = rerouted;
      }
    } else {
      // Too few waypoints to route - remove the old line and maneuvers
      routes[routeIndex].lines = [];
      maneuvers.clear();
      distance = 0;
    }
    // The removed waypoint was under the crosshair - onIdle will recalculate
    waypointIndex = -1;
    waypointState = WaypointState.none;
    await syncGoodRoads();
    addToBackBuffer(route: routes[min(routeIndex, routes.length - 1)]);
    mapUpdates = _routeMapUpdates;
    // Awaited so the micro-nudge that follows comes after every source is
    // set - otherwise e.g. the great road could miss the redraw
    await MapService().updateMapGeoJson(mapUpdates: mapUpdates);
    isSaved = false;
  }

  /// Each waypoint is mirrored by a Start (17), Waypoint (12) or End (18)
  /// point of interest. Re-use, add or remove them so there's one per
  /// waypoint, re-typed and re-positioned to match, keeping Start at
  /// pointsOfInterest[0]. Used after a waypoint is removed, undone or redone.
  void syncWaypointPointsOfInterest({required List<Waypoint> waypoints}) {
    final List<PointOfInterest> markers = [
      ...pointsOfInterest.where((poi) => poi.type == 17),
      ...pointsOfInterest.where((poi) => poi.type == 12),
      ...pointsOfInterest.where((poi) => poi.type == 18),
    ];
    while (markers.length > waypoints.length) {
      pointsOfInterest.remove(markers.removeLast());
    }
    while (markers.length < waypoints.length) {
      PointOfInterest marker = PointOfInterest(
          point: waypoints[markers.length].point, name: 'Waypoint', type: 12);
      pointsOfInterest.add(marker);
      markers.add(marker);
    }
    for (int i = 0; i < markers.length; i++) {
      bool last = i == markers.length - 1;
      markers[i].type = i == 0 ? 17 : (last ? 18 : 12);
      markers[i].name = i == 0 ? 'Start' : (last ? 'End' : 'Waypoint');
      markers[i].point = waypoints[i].point;
    }
    if (markers.isNotEmpty) {
      pointsOfInterest.remove(markers.first);
      pointsOfInterest.insert(0, markers.first);
    }
  }

  /// addGoodWaypoint() adds a new GoodRoads.waypoint under the cross-hairs.
  /// If it's the first Good Road waypoint it triggers the Bottom Drawer opening
  /// for the user to enter the description as a PointOfInterest. The PointOfInterest uri
  /// is generated and updates the GoodRoad.pointOfInterestUri too.

  void addGoodRoadWaypoint({
    int index = 1,
    required Point point,
    bool revisit = false,
  }) async {
    if (goodRoads.isEmpty) {
      goodRoads.add(Route());
    }
    int insertAt =
        goodRoads.last.waypoints.isEmpty ? 0 : goodRoads.last.waypoints.length;
    try {
      Waypoint waypoint = Waypoint(
          point: latLngToPoint(
              latLng: MapService().controller!.cameraPosition!.target),
          colour: Setup().goodRouteColourHex());
      if (goodRoads.last.waypoints.length == 1 &&
          goodRoads.last.waypoints[0].point.x == 0) {
        goodRoads.last.waypoints[0] = waypoint;
      }
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
        goodRoads.last.waypoints.insert(insertAt, waypoint);
      }

      mapUpdates = mapUpdates.add(MapUpdates.goodRoadsAndGoodRoadWaypoints);
      MapService().updateMapGeoJson(mapUpdates: mapUpdates);
      // Great roads aren't in the route's undo history
      goodRoads = await replaceRoutes(routes: goodRoads, updateBuffer: false);
      isSaved = false;
    } catch (e) {
      developer.log('Error: ${e.toString()}', name: 'error');
    }
  }

  loadWaypoints({required Point point}) {}

  /// UpdateMapGeometry() takes the data from Waypoints and routes and displays the data on the
  /// map. Should be called after every change of waypoints
  /// CurrentTripItem().goodRoad is the flag to distinguish the waypoint type

  /// deleteWaypoint deletes a waypoint from either the routes List<waypoint> where id is 'i' - the waypoint index
  /// or goodRoads[n].List<waypoint>  where id = 'g_i' where g is the roodRoad index and i the waypoint index
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
    return pointsOfInterest;
  }

  void updateBackBuffer({required List<Waypoint> waypoints}) {
    if (waypoints.length > 1) {}
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

          /// The last maneuver arrives at the last waypoint. A route with no
          /// turns has only its depart left - it needs an arrive of its own,
          /// or the depart became the arrive and the Start moved to the end
          Point end = routes.last.waypoints.last.point;
          if (newManeuvers.length == 1) {
            newManeuvers.add(Maneuver(
                roadFrom: newManeuvers.first.roadTo,
                roadTo: newManeuvers.first.roadTo,
                exit: 0,
                bearingBefore: 0,
                bearingAfter: 0,
                point: end,
                modifier: '',
                type: 'arrive',
                distance: 0));
          } else {
            newManeuvers.last.type = 'arrive';
            newManeuvers.last.point = end;
          }
          maneuvers = isGoodRoad ? maneuvers : newManeuvers;
          reorderWaypoints(
            revisit: revisit,
          );
        }
        // The router didn't answer (no signal, or the server is down): the
        // routes are returned as they were. It used to return none, so
        // adding a waypoint without a connection wiped the whole trip.
      } catch (e) {
        developer.log('Error replaceRoutes() ${e.toString()}', name: 'error');
      }
    }
    return routes ?? [];
  }

  /// replaceRoutes() gets the maneuvers from a list of points.
  /// It ensures that everything is in the same order as the router
  /// has supplied.

  @override
  Map<String, dynamic> toJson() {
    int pois = pointsOfInterest.length;

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
        'pois': pois,
        'published_uri': publishedUri,
      };

      return json;
    } catch (e) {
      debugPrint('Error MyTripItem.toMap(): ${e.toString()}');
    }
    return {};
  }

  @override
  savePrivate() async {
    try {
      TripRepository tripRepository = TripRepository();
      uri = uri.isEmpty ? getUuid() : uri;
      added = added.isEmpty ? dateFormat.format(DateTime.now()) : added;
      tripRepository.saveTrip(CurrentTripItem());
    } catch (e) {
      developer.log('Error in CurrentTripItem().savePrivate() ${e.toString()}',
          name: 'error');
    } //     ? tripRepository;

    return;
  }

  Future<void> loadPrivate({String uri = '', int id = -1}) async {
    if (id == -1) {}
  }

  /// Current version
  updateWaypoints({
    required Point point,
    List<Route>? features,
  }) async {
    if (tripState == TripState.editing) {
      List<int> newIndexes = closestWaypoints(target: point, routes: features!);
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
        mapUpdates = isGoodRoad
            ? mapUpdates.add(MapUpdates.goodRoads)
            : mapUpdates.add(MapUpdates.routes);
        MapService().updateMapGeoJson(mapUpdates: mapUpdates);
      }
    }
  }

  highlightGoodRoad({String id = ''}) async {
    highliteActions = id.isEmpty
        ? HighliteActions.none
        : HighliteActions.greatRoadHighlighted;
    String colour = id.isNotEmpty
        ? Setup().highlightedColourHex()
        : Setup().goodRouteColourHex();
    goodRoads.firstWhere((g) => g.uri == id).colour = colour;
    goodRoadIndex = id.isEmpty ? goodRoadIndex : int.parse(id.substring(2)) - 1;

    mapUpdates = mapUpdates.add(MapUpdates.goodRoads);
    MapService().updateMapGeoJson(mapUpdates: mapUpdates);
    // Micro-nudge to update MapLibre
    await MapService().controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  /// reverseRoute() reverses the waypoints and feeds the new order to the
  /// router, so the maneuvers describe the trip driven the other way. The
  /// waypoint numbers follow the new order. Reverses the route on screen, not
  /// backBuffer[0], which isn't the current state after an undo.
  Future<void> reverseRoute({List<Map<String, dynamic>>? features}) =>
      _routeChange(_reverseRoute);

  Future<void> _reverseRoute() async {
    if (routes.isEmpty || routes.last.waypoints.length < 2) {
      return;
    }
    routes.last.waypoints =
        markRevisits(waypoints: _reverseGoodRoadFlags(routes.last.waypoints));
    syncWaypointPointsOfInterest(waypoints: routes.last.waypoints);
    List<Route> rerouted =
        await replaceRoutes(routes: routes, updateBuffer: false);
    if (rerouted.isNotEmpty) {
      routes = rerouted;
    }
    waypointIndex = -1;
    waypointState = WaypointState.none;
    isSaved = false;
    await syncGoodRoads();
    addToBackBuffer(); // also refreshes the app bars' undo / redo
    mapUpdates = _routeMapUpdates;
    // Awaited so the micro-nudge that follows comes after every source is
    // set - otherwise e.g. the great road could miss the redraw
    await MapService().updateMapGeoJson(mapUpdates: mapUpdates);
    // Micro-nudge to update MapLibre the nudge causes the onIdle callback to be called
    await MapService().controller?.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  /// Reverses the waypoints keeping the same stretches as great roads.
  /// isGoodRoad marks the leg arriving at a waypoint, so when reversed it
  /// moves to the waypoint at the other end of that leg.
  List<Waypoint> _reverseGoodRoadFlags(List<Waypoint> waypoints) {
    int n = waypoints.length;
    List<Waypoint> reversed = waypoints.reversed.toList();
    return [
      for (int j = 0; j < n; j++)
        Waypoint(
          colour: reversed[j].colour,
          point: reversed[j].point,
          revisit: reversed[j].revisit,
          isGoodRoad: j > 0 && waypoints[n - j].isGoodRoad,
        )
    ];
  }

  /// The first visit to a point is the waypoint and any later visit a revisit.
  /// After reversing, the revisit that was at the end is now first, so the
  /// flags have to move to keep the start's marker and the lower number.
  List<Waypoint> markRevisits({required List<Waypoint> waypoints}) {
    List<Point> visited = [];
    List<Waypoint> marked = [];
    for (Waypoint waypoint in waypoints) {
      bool revisit = visited.contains(waypoint.point);
      if (!revisit) {
        visited.add(waypoint.point);
      }
      marked.add(Waypoint(
        colour: waypoint.colour,
        point: waypoint.point,
        isGoodRoad: waypoint.isGoodRoad,
        revisit: revisit,
      ));
    }
    return marked;
  }

  /// changeRoute
  /// Recalculates route
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
        await MapService().controller!.setGeoJsonSource('route-data', {
          "type": "FeatureCollection",
          "features": routesToGeoJson(),
        });
        MapService().updateMapGeoJson(mapUpdates: mapUpdates);
      }
    } catch (e) {
      developer.log('Error in my_trip_item.dart changeRoute() :${e.toString()}',
          name: 'error');
    }
    return waypoints.length > 2;
  }

  bool goodRoadEnd(
      {String name = '', String description = '', String sounds = ''}) {
    if (![TripState.tracking, TripState.following].contains(tripState)) {
      // Made from the route (syncGoodRoads()) - add the description to the
      // great road just finished, if any waypoints were added to it
      isGoodRoad = false;
      isSaved = false;
      List<Waypoint> route = routes.isEmpty ? [] : routes.last.waypoints;
      Route? goodRoad = goodRoads
          .where((g) =>
              g.pointOfInterestUri.isEmpty &&
              g.waypoints.length > 1 &&
              route.isNotEmpty &&
              g.waypoints.last.point == route.last.point)
          .lastOrNull;
      if (goodRoad == null) return false;
      String uuid = getUuid();
      // In the middle of the stretch - at its start it sat on the waypoint
      // marker there, and hid it
      List<double>? middle = goodRoad.lines.length > 2
          ? goodRoad.lines[goodRoad.lines.length ~/ 2]
          : null;
      pointsOfInterest.add(PointOfInterest(
        point: middle == null
            ? goodRoad.waypoints.first.point
            : Point(middle[0], middle[1]),
        uuid: uuid,
        type: 13,
        name: name,
        description: description,
        sounds: sounds,
      ));
      goodRoad.pointOfInterestUri = uuid;
      _recordDescriptions();
      return true;
    }
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
  List<Maneuver> maneuvers;
  List<PointOfInterest> pointsOfInterest;
  String images;
  bool published = false;

  /// The published trip this is, or was downloaded from - its drives count
  /// for that one (DrivenLog). Empty for a trip that's never been published.
  String publishedUri = '';
  List<Photo>? photos;
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
    List<Photo>? photos,
    this.images = '',
  })  : // driveUri = driveUri ?? getUuid(),
        maneuvers = maneuvers ?? <Maneuver>[],
        goodRoads = goodRoads ?? <Route>[],
        pointsOfInterest = pointsOfInterest ?? <PointOfInterest>[],
        routes = routes ?? <Route>[],
        photos = photos ?? <Photo>[];
  // super(photos: photos ?? <Photo>[]); // <-- has to be last in list

  /// A trip saved on the device, or a published one from the API (GET
  /// drive/<uri>) - the API keeps a trip just as the app sends it
  factory MyTripItem.fromJson({required Map<String, dynamic> jsonObject}) {
    List<Route> routes = routesFromJson(jsonList: jsonObject["routes"] ?? []);

    List<Maneuver> maneuvers = maneuversFromJson(
      jsonList: jsonObject["maneuvers"] ?? [],
    );
    List<Route> goodRoads = goodRoadsFromJson(
      jsonList: jsonObject["good_roads"] ?? [],
    );

    List<PointOfInterest> pointsOfInterest = pointsOfInterestFromJson(
      jsonList: jsonObject["points_of_interest"] ?? [],
    );

    /// Need to add all the images that are in each point of interest to trip image list
    /// so the images can be seen from the my_trip_tiles
    MyTripItem tripItem = MyTripItem();
    try {
      tripItem = MyTripItem(
        id: jsonObject["id"] ?? -1,
        uri: jsonObject["uri"] ?? "",
        title: jsonObject["title"] ?? "",
        subTitle: jsonObject["sub_title"] ?? "",
        body: jsonObject["body"] ?? "",
        images: jsonObject['images'] ?? "",
// expecting a string not List<dynamic>
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
        // MyTripTile shows photos (e.g. the map image) - only images was set,
        // so a saved trip's map never showed in My Trips
        photos: (jsonObject['images'] ?? '').isEmpty
            ? []
            : photosFromJson(photoString: jsonObject['images']),
      )..publishedUri = jsonObject['published_uri'] ?? '';
    } catch (e) {
      developer.log('factory MyTripItem.fromJson() error: ${e.toString()}',
          name: 'error');
    }

    return tripItem;
  }

  factory MyTripItem.summaryFromJson(
      {required Map<String, dynamic> jsonObject}) {
    List<Photo> photos = [];
    String images = '';

    if ((jsonObject['images'] ?? []).isNotEmpty) {
      try {
        images = jsonObject['images'];
        photos = photosFromJsonObject(
          images: jsonObject[
              'images'], //<-- images is a dynamic as could be a List or String
          endpoint: '${urlBase}static/images/${jsonObject['uri'] ?? ''}',
        );
      } catch (e) {
        developer.log('Error adding photo to photos: ${e.toString()}',
            name: 'error');
      }
    }
    return MyTripItem(
      id: -1,
      uri: jsonObject["uri"] ?? "",
      title: jsonObject["title"] ?? "",
      subTitle: jsonObject["sub_title"] ?? "",
      body: jsonObject["body"] ?? "",
      images: images,
      added: jsonObject["added"] ?? dateFormat.format(DateTime.now()),
      distance: jsonObject["distance"] ?? 0,
      photos: photos,
    );
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

  /// This is overridden in CurrentTripItem
  Map<String, dynamic> toJson() {
    try {
      uri = uri.isEmpty ? getUuid() : uri;
      List<Map<String, dynamic>> maneuversJSON = [];
      int pois = pointsOfInterest.length;
      for (int i = 0; i < maneuvers.length; i++) {
        maneuversJSON.add(maneuvers[i].toMap(driveUid: uri));
      }

      List<Map<String, dynamic>> pointsOfInterestJSON = [];
      for (int i = 0; i < pois; i++) {
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
        "images": images,
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
        "pois": pois,
        "published": published,
        "published_uri": publishedUri,
      };
      return json;
    } catch (e) {
      debugPrint('error currentTripItemToJson: ${e.toString()}');
    }
    return {};
  }

  /// Going to save the newly created / edited trip
  ///   On device save to SQLite
  ///     Fields id, ne, sw, title, added, jsonObject to provide
  ///     enough info for the user to select the trip without having
  ///     to jsonDecode everything before selection
  ///   On web save to API as private
  ///     send the whole trip as a jsonObject and let the api shred it
  ///

  List<Photo> getPhotos() {
    List<Photo> photos = [];
    return photos;
  }

  set setPhotos(List<Photo> photos) => this.photos = photos;

  savePrivate() async {
    return;
  }

  String getPublishedDate({String noPrompt = ''}) {
    return added == '' ? noPrompt : added;
  }

  get showMethods => false;
}
