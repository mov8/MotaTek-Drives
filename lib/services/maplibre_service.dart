import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'package:drives/classes/create_trip_stack.dart';
import 'package:drives/main.dart' hide Routes;
import 'package:drives/routes/my_trips.dart';
import 'package:flutter/foundation.dart';
import 'package:drives/classes/classes.dart' hide Position, distanceBetween;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../helpers/helpers.dart';
import '../services/services.dart';
import '../routes/create_trip.dart';
import '../routes/home.dart';
import '../routes/shop.dart';
import '../routes/messages.dart';
import '../tiles/tiles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/gestures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart' show File;

/// OVERALL STRUCTURE
/// 1 CurrentTripItem - singleton that looks after the persistent data - routes, waypoints etc
///   CurrentTripItem is changed first as many of the map updates depend on previously entered
///   data - Clear Trip Extend Start etc.
///
/// 2 MapService - singleton that looks after the map display. Requests for the map to change
///   - are effected by posting MapRequests into the updateRequest() method. These requests
///     are initiated by the ActionChips
///
///     ActionChip -> CurrentTripItem() -> MapService()
///   MapService is also controlled by the FABS which change the MapCenter, Zoom etc.
///
///   the MapRequest is actioned on the onIdle and are changes mage to the geoJson
///   MapService also actions any immediate requests like changing position and zoom

/// This implementation tries to minimise the work the device has to do when displaying the map.
/// The MapService object is really just responsible for retrieving the style.json. It's a singleton
/// so should only get built once. It two another purpose
/// 1 holding the MapLibre's GlobalKey.
/// 2 giving access to the controller
/// The neat trick in this structure is that the singleton holds the GlobalKey for the actual map
/// object. The fact that the key is persisted in the singleton means that Flutter won't reinitialise
/// the MapLibre object which is expensive as the MapLibre object is destroyed, though it will rebuild
/// the Widget which is very cheap as it only creates a blueprint of the MapLibre object which is kept alive.
/// As the singleton holds the style.json data already it's very efficient.

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  int _page = 0;
  int _navIndex = 0;

  /// Completers are the way to use a manual Future. It triggers any FutureBuilder that the action being
  /// waited for has completed. The completer is completed in the setMapController() below.
  /// A reset call has been added just in case there is a restart
  /// In the UI section CreateTripStack() The FutureBuilder the Future is MapService().mapFuture, and the
  /// controller = snapShot.data! - it works well

  Future<MapLibreMapController> get mapFuture => _controllerCompleter.future;

  /// Completes when the map's style has loaded - its sources can't be
  /// changed before then
  Future<void> get styleReady => _styleCompleter.future;
  final Completer<void> _styleCompleter = Completer<void>();
  final Completer<MapLibreMapController> _controllerCompleter =
      Completer<MapLibreMapController>();

  ///
  MapLibreMapController? controller;
  SideDrawerController? sideDrawerController;
  BottomDrawerController? bottomDrawerController;
  WebAppBarController? webAppBarController;
  StatusBarController? statusBarController;
  FabsController? fabsController;
  ZoomFabController? zoomFabController; // = ZoomFabController();
  ScrollController scrollController = ScrollController();
  CreateTripController? createTripController = CreateTripController();
  LeadingWidgetController leadingWidgetController = LeadingWidgetController();
  CreateTripStackController? createTripStackController =
      CreateTripStackController();

  HomeController? homeController = HomeController();
  MyTripsController? myTripsController = MyTripsController();
  MessagesController? messagesController = MessagesController();
  ShopController? shopController = ShopController();
  BaseShellController? baseShellController = BaseShellController();
  BottomNavController? bottomNavController = BottomNavController();
  PersistentAppBarController? persistentAppBarController =
      PersistentAppBarController();
  TripHeaderController? tripHeaderController = TripHeaderController();
  MessageBoxController? messageBoxController = MessageBoxController();

  final GlobalKey mapKey = GlobalKey();
  ItemScrollController itemScrollController = ItemScrollController();

  final ImageRepository _tripImageRepository = ImageRepository();

  String _styleString = '';
  Future<String>? _styleFuture;
  late Future<bool> mapReady;
  Future<String> get style => _styleFuture ??= _fetchStyle();
  DrivesRequest? _drivesRequest;
  TripRequest? _tripRequest;
  bool? _checkUpdates = false;
  bool _idleCalled = false;
  CameraPosition? _cameraPosition;
  MapUpdates mapUpdates = MapUpdates.updateAll; // <-- What geoJson to update
  MapUpdates onExitUpdate = MapUpdates.none;
  Future<bool>? mapControllerReady;
  MapLibreMap? mlMap;

  UserLocation? useLocation;

  final ValueNotifier<int?> scrollToSideDrawerIndex = ValueNotifier<int?>(null);

  void requestScroll(int index) {
    scrollToSideDrawerIndex.value = index;
  }

  Future<bool> setMapController(MapLibreMapController mapController) async {
    controller = mapController;
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(mapController);
    }
    return true;
  }

  onTap(tap, position) {
    if (_page == 1) {
      _tripsOnTap(tap);
    }
    return ' ';
  }

  /// This adds a request for a map change at next onIdle callback
  void updateRequest(
      {required MapUpdates mapUpdates, MapUpdates onExit = MapUpdates.none}) {
    mapUpdates.add(mapUpdates);
  }

  void mapStyle(String style) {
    _styleString = style;
  }

  onCameraMove(position) {
    try {
      _cameraPosition ??= position;
      Point start = Point(position.target.longitude, position.target.latitude);
      Point end = Point(
          _cameraPosition!.target.longitude, _cameraPosition!.target.latitude);
      double distance = distanceBetween(startXY: start, endXY: end);
      _checkUpdates = distance > 100;
      if (_checkUpdates!) {
        _cameraPosition = position;
      }
    } catch (e) {
      developer.log(
          'MapService().onCameraMove() error getting distance: ${e.toString()}',
          name: 'error');
    }
  }

  /// To try and separate the logic from the UI all the mapping mechanics have
  /// now been moved to this singleton.
  ///   It controls the map, the SideDrawer, and the BottomDrawer
  ///   It fetches the data from the API either directly or through a cache
  /// Pans the map so a point is in the middle of the part of the map that's
  /// showing - above the BottomDrawer on a phone, right of the SideDrawer on
  /// the web (both cover part of the map), e.g. the start of a trip
  void showInView(LatLng point) {
    if (controller == null) return;
    // Degrees of longitude per logical pixel (512px tiles), and of latitude
    // near this latitude
    double zoom = controller!.cameraPosition?.zoom ?? 12;
    double lngPerPixel = 360 / (512 * pow(2, zoom));
    double latPerPixel = lngPerPixel * cos(point.latitude * pi / 180);
    double dx = kIsWeb ? -(sideDrawerController?.getWidth() ?? 0) / 2 : 0;
    double dy = kIsWeb ? 0 : (bottomDrawerController?.getHeight() ?? 0) / 2;
    controller!.animateCamera(
        CameraUpdate.newLatLng(LatLng(point.latitude - dy * latPerPixel,
            point.longitude + dx * lngPerPixel)),
        duration: const Duration(seconds: 1));
  }

  /// Puts a point under the crosshair - the middle of the whole map, drawer
  /// or not - so the Status Bar says what's there and Waypoint adds it
  void showUnderCrosshair(LatLng point) =>
      controller?.animateCamera(CameraUpdate.newLatLng(point),
          duration: const Duration(seconds: 1));

  /// Switches the map page's mode - Published (1) or Explore (2) - once the
  /// map and its style are ready. They're the same page, so this is what
  /// tells them apart.
  Future<void> showPage(int page) async {
    if (![1, 2].contains(page)) return;
    await mapFuture;
    await styleReady;
    _resizeWebMap();
    await setPage(page: page);
  }

  /// The web map told its size again. Moved between pages, its canvas could
  /// keep the size it had while hidden - the map then showed zoomed in, with
  /// the place names stretched sideways. Again after a moment, once the page
  /// has laid out.
  void _resizeWebMap() {
    if (!kIsWeb || controller == null) return;
    controller!.forceResizeWebMap();
    Future.delayed(const Duration(milliseconds: 400),
        () => controller?.forceResizeWebMap());
  }

  Future<bool> setPage({required int page}) async {
    _page = page;
    switch (_page) {
      case 1:
        return await initialiseTrips();
      case 2:
        return await initialiseExplore();
    }
    return true;
  }

  int get page => _page;

  setNavIndex(int index) {
    _navIndex = index;
  }

  int get navIndex => _navIndex;

  int screen() {
    return _page;
  }

  Future<bool> loadStyle2() async {
    _styleString = await _fetchStyle();
    return true;
  }

  /// onIdle called after the map has stopped doing something
  /// defined within main.dart where the persistent mapLibreMap
  /// id instantiated - its onCameraIdle gets assigned to this method.

  Future<Map<String, dynamic>> waypointTargetted() async {
    Point point =
        await controller!.toScreenLocation(controller!.cameraPosition!.target);
    final rect = Rect.fromCenter(
        center: Offset(point.x.toDouble(), point.y.toDouble()),
        width: 10,
        height: 10);
    String layer = CurrentTripItem().isGoodRoad
        ? 'good-road-marker-layer'
        : 'way-marker-layer';

    var features =
        await controller!.queryRenderedFeaturesInRect(rect, [layer], null);
    if (features.isNotEmpty) {
      for (int i = 0; i < features.length; i++) {
        if (features[i]['properties']['group'] == 'waypoint') {
          double x = features[i]['geometry']['coordinates'][0];
          double y = features[i]['geometry']['coordinates'][1];
          Point position = Point(x, y);
          return {'index': int.parse(features[i]['id']), 'point': position};
        }
      }
    }
    return {'index': -1};
  }

  /// Completed on the next onIdle - when the camera has stopped and the map
  /// has drawn, e.g. so a snapshot captures the finished map
  Completer<void>? _idleWaiter;

  Future<void> nextIdle() {
    _idleWaiter = Completer<void>();
    return _idleWaiter!.future;
  }

  onIdle() async {
    if (_idleWaiter != null && !_idleWaiter!.isCompleted) {
      _idleWaiter!.complete();
    }
    if (controller != null) {
      zoomFabController?.update();
      if (kIsWeb) {
        // The StatusBar's scale follows the zoom
        _meters = await getMapWidthMeters();
        statusBarController?.refresh();
      }
// handle Published state
      /// The following onIdle came from GitHub branch web_with_markdown create_trip.dart

      ///  OnIdle behaves differently depending on whether in Explore or in Published
      /// In Explore it has to handle the edits of the trip.
      ///   If the mouse is over a waypoint then it offers to delete the waypoint
      ///   If the mouse is between two waypoints it offers re-routing
      ///   If the mouse could extend the start or finish it offers those two options
      /// InPublished mode
      ///   It controls the trips cache - looking at the the bounding box and loads the
      ///   appropriate routes, waypoints and points of interest to minimise API calls

      if (NavigationService().page == 1) {
        try {
          LatLngBounds bounds =
              await MapService().controller!.getVisibleRegion();
          double zoom = MapService().controller!.cameraPosition!.zoom;
          _drivesRequest ??= DrivesRequest(
              onUpdated: (_) => {},
              onGetDetails: (_) => {},
              onGetDownload: (index, name) => {},
              imageRepository: _tripImageRepository);
          await _drivesRequest!
              .update(bounds: bounds, zoom: zoom, force: !_idleCalled);
          _idleCalled = true;
          await _publishedFilters(bounds);
        } catch (e) {
          developer.log('Error setting published data: ${e.toString()}',
              name: 'error');
        }

        // handle Explore and Favourites not going to use the cache as all the data is now in Hive
      } else
      // When tracking or following don't need any published or favourites data
      if (NavigationService().page == 2 &&
          [TripState.tracking, TripState.following]
              .contains(CurrentTripItem().tripState)) {
        createTripStackController!.refresh(); // _positionUpdate.update();
      } else {
        LatLngBounds bounds = await MapService().bounds;
        statusBarController!.refresh();
        CurrentTripItem().mapController ??= controller;
        LatLngBounds? bounds2;
        try {
          bounds2 = await controller!.getVisibleRegion();
        } catch (e) {
          developer.log('Error _onIdle() Bounds: $bounds2', name: 'error');
        }
        try {
          if ([
            TripState.editing,
            TripState.manual,
            TripState.tracking,
            TripState.loaded,
            TripState.clearing,
            TripState.goodRoadStart,
          ].contains(CurrentTripItem().tripState)) {
            if (CurrentTripItem().tripState == TripState.editing) {
              // Handle any highlighted features identified by the user.
              // Get waypointState() sets insert, delete, extendStart, extendEdd
              await getWaypointState();
              await updateMapGeoJson(mapUpdates: MapUpdates.updateAll);
            } else if (CurrentTripItem().tripState == TripState.manual) {
              // Waypoint under the crosshair offers Remove / Revisit waypoint
              await getWaypointState();
              createTripStackController?.refresh();
            }
          }
          if (CurrentTripItem().tripState == TripState.clearing) {
            CurrentTripItem().tripState = TripState.none;
            CurrentTripItem().waypointState = WaypointState.none;
            CurrentTripItem().tripState == TripState.none;
            CurrentTripItem().routes = [];

            createTripStackController?.refresh();
          }

          if (CurrentTripItem().tripActions != TripActions.none) {}

          /// Update the published features that are within the "select fence",
          /// Shows the highlight background for roads + their shields
          /// The factor in fenceFilter is the same as used to generate fence box HighlightPainter()
          /// testFenceFilter(bounds: bounds, jsonData: _geoJson); <-- Very useful

          var filter = fenceFilter(bounds: bounds, proportion: 0.6);
          controller!.setFilter("good_roads_highlighted", filter);
          controller!.setFilter("route-marker-layer", shieldFilter(filter));

          /// Filter waypoints for TripStates manual, editing or goodRoadStart but only in Explore mode
          /// which is set when _CreateTripState is built
          if (NavigationService().page == 2) {
            filter = tripStateFilter(tripState: CurrentTripItem().tripState);
            controller!.setFilter("way-marker-layer", filter);
            controller!.setFilter("good-road-way-marker-layer", filter);
            await _showEditHint();
          }
        } catch (e) {
          developer.log('_onIdle() error: ${e.toString()}', name: 'error');
        }
        CurrentTripItem().tripValues.position = Point(
            controller!.cameraPosition!.target.longitude,
            controller!.cameraPosition!.target.latitude);
      }
      createTripStackController?.refresh();
    }
    return;
  }

  List<int> closestWaypoints(
      {required List<Waypoint> waypoints, required Point point}) {
    List<int> idx = [-1, -1];
    List<double> distance = [999999999, 999999999];
    for (int i = 0; i < waypoints.length; i++) {
      double gap = distanceBetween(startXY: waypoints[i].point, endXY: point);
      if (gap < distance[0]) {
        idx[1] = idx[0];
        idx[0] = i;
        distance[1] = distance[0];
        distance[0] = gap;
      } else if (gap < distance[1]) {
        idx[1] = i;
        distance[1] = gap;
      }
    }
    return idx;
  }

  /// getWaypointState() works out what's under the crosshair on each onIdle:
  ///   WaypointState.remove       crosshair is over an existing waypoint
  ///   WaypointState.extendStart  crosshair is beyond the start
  ///   WaypointState.extendEnd    crosshair is beyond the end
  ///   WaypointState.extendBoth   crosshair is beyond both ends of a round trip
  ///   WaypointState.insert       anywhere else on a route of 2+ waypoints
  ///   WaypointState.none         fewer than 2 waypoints
  ///
  /// Insert always goes between two anchors - consecutive waypoints that stay
  /// in the re-calculated route - so the router can't miss a waypoint the user
  /// has placed, avoiding the random re-routing of other route planners. To
  /// free the router the user deletes an anchor. The anchors are the leg where
  /// the new waypoint adds the least distance (see _insertionLeg()).
  ///
  /// Each end is only judged against its neighbouring waypoint, not the other
  /// end of the route. Comparing with the other end fails on a circular route,
  /// where the start and end are close together:
  ///   beyond the start: distance(crosshair, waypoint 2) >
  ///                     distance(start, waypoint 2)
  ///   beyond the end:   distance(crosshair, last but one) >
  ///                     distance(end, last but one)
  /// An end is considered when it's the waypoint nearest the crosshair, or
  /// when the other end is nearest and it's next nearest. On a circular route
  /// both ends are close together - often the same place - so checking only
  /// the nearest would let the start always win. If both tests pass it's
  /// WaypointState.extendBoth, and the user chooses: start, end or both.
  /// It won't be right every time, but undo lets the user try again.
  ///

  /// The leg - waypoints i and i + 1 - where adding point makes the least
  /// detour: distance(i, point) + distance(point, i + 1) - distance(i, i + 1).
  /// More reliable than the two nearest waypoints, which on a circular or
  /// figure of eight route needn't be consecutive. Returns i.
  int _insertionLeg({required List<Waypoint> waypoints, required Point point}) {
    int leg = 0;
    double leastDetour = double.infinity;
    for (int i = 0; i < waypoints.length - 1; i++) {
      double detour =
          distanceBetween(startXY: waypoints[i].point, endXY: point) +
              distanceBetween(startXY: point, endXY: waypoints[i + 1].point) -
              distanceBetween(
                  startXY: waypoints[i].point, endXY: waypoints[i + 1].point);
      if (detour < leastDetour) {
        leastDetour = detour;
        leg = i;
      }
    }
    return leg;
  }

  bool _hinting = false; // the Status Bar is showing _showEditHint()'s hint

  /// The Status Bar says what the chips do at the crosshair - "Insert a
  /// waypoint between waypoints 7 and 8", "Remove waypoint 9" - after a
  /// place AI assist found that's under it. Set by getWaypointState().
  Future<void> _showEditHint() async {
    if (statusBarController == null) return;
    CurrentTripItem trip = CurrentTripItem();
    if (![TripState.editing, TripState.manual].contains(trip.tripState)) {
      if (_hinting) statusBarController!.clear();
      _hinting = false;
      PlannerService().placeUnderCrosshair.value = null;
      return;
    }
    List<Waypoint> waypoints =
        trip.routes.isEmpty ? [] : trip.routes.first.waypoints;
    List<int> anchors = [
      for (int i = 0; i < waypoints.length; i++)
        if (waypoints[i].selected ?? false) i
    ];
    int over = trip.waypointIndex;
    String hint = switch (trip.waypointState) {
      WaypointState.remove when trip.tripState == TripState.editing =>
        'Remove waypoint ${markerNumber(waypoints, over)}',
      WaypointState.remove when over < waypoints.length - 1 =>
        'Revisit waypoint ${markerNumber(waypoints, over)} - go back to it',
      WaypointState.remove => 'Waypoint ${markerNumber(waypoints, over)}',
      WaypointState.insert
          when trip.tripState == TripState.editing && anchors.length == 2 =>
        'Insert a waypoint between waypoints '
            '${markerNumber(waypoints, anchors[0])} and '
            '${markerNumber(waypoints, anchors[1])}',
      WaypointState.extendStart when trip.tripState == TripState.editing =>
        'Extend the start - a new first waypoint here',
      WaypointState.extendEnd when trip.tripState == TripState.editing =>
        'Extend the end - a new last waypoint here',
      WaypointState.extendBoth when trip.tripState == TripState.editing =>
        'Extend the start, the end, or both - from and back to here',
      _ => waypoints.isEmpty
          ? 'Waypoint - the start here'
          : 'Waypoint - waypoint ${waypoints.where((w) => !w.revisit).length + 1} here',
    };
    String? place = await PlannerService().candidateAt(controller!);
    statusBarController!.update([place == null ? hint : '$place  -  $hint']);
    _hinting = true;
  }

  Future<void> getWaypointState() async {
    Map<String, dynamic> waypointData = await waypointTargetted();
    int index = waypointData['index'];
    CurrentTripItem().waypointIndex = index;
    LatLng targetLatLng = controller!.cameraPosition!.target;
    Point position = Point(targetLatLng.longitude, targetLatLng.latitude);

    List<Waypoint> waypoints = CurrentTripItem().routes.isEmpty
        ? []
        : CurrentTripItem().routes.first.waypoints;
    List<int> nearest = closestWaypoints(waypoints: waypoints, point: position);
    // nearest[0] is closer than nearest[1]
    WaypointState state = WaypointState.none;

    if (CurrentTripItem().waypointIndex > -1) {
      state = WaypointState.remove;
    } else if (waypoints.length > 1) {
      int last = waypoints.length - 1;
      // nearest[0] is the closest waypoint to target, nearest[1] the next.
      // An end counts if it's the closest, or the other end is closest and
      // it's next - the ends are close together, as on a circular route
      bool nearStart =
          nearest[0] == 0 || (nearest[0] == last && nearest[1] == 0);
      bool nearEnd =
          nearest[0] == last || (nearest[0] == 0 && nearest[1] == last);

      /// Further from waypoint 2 than the start is
      bool beyondStart = nearStart &&
          distanceBetween(startXY: waypoints[1].point, endXY: position) >
              distanceBetween(
                  startXY: waypoints[0].point, endXY: waypoints[1].point);

      /// Further from the last but one waypoint than the end is
      bool beyondEnd = nearEnd &&
          distanceBetween(startXY: waypoints[last - 1].point, endXY: position) >
              distanceBetween(
                  startXY: waypoints[last].point,
                  endXY: waypoints[last - 1].point);

      if (beyondStart && beyondEnd) {
        // A round trip - the ends are close together, often the same place,
        // so either could be meant: the chips offer start, end and both
        state = WaypointState.extendBoth;
      } else if (beyondStart) {
        state = WaypointState.extendStart;
      } else if (beyondEnd) {
        state = WaypointState.extendEnd;
      } else {
        state = WaypointState.insert;
      }
    }
    // Edit mode highlights (in the user's highlight colour):
    //   remove - the waypoint under the crosshair
    //   insert - the two anchors the new waypoint goes between, which stay in
    //            the re-calculated route. addWaypoint() inserts after the
    //            first selected waypoint, so Insert waypoint depends on this.
    List<int> highlighted = [];
    if (CurrentTripItem().tripState == TripState.editing) {
      if (state == WaypointState.remove) {
        highlighted = [CurrentTripItem().waypointIndex];
      } else if (state == WaypointState.insert) {
        int leg = _insertionLeg(waypoints: waypoints, point: position);
        highlighted = [leg, leg + 1];
      }
    }
    for (int i = 0; i < waypoints.length; i++) {
      waypoints[i].selected = highlighted.contains(i);
    }
    mapUpdates = mapUpdates.add(MapUpdates.waypoints);
    CurrentTripItem().setWaypointState(state);
    updateMapGeoJson(mapUpdates: mapUpdates);
    return;
  }

  Future<Position> getCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition();
    return position;
  }

  /// Where the user is, or null if no fix comes within 10 seconds - a
  /// browser whose location prompt isn't answered, or a computer with its
  /// location switched off. Without a limit getCurrentPosition() waits for
  /// ever, and the app waited with it on the splash screen.
  Future<Position?> currentPositionOrNull() async {
    try {
      return await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(timeLimit: Duration(seconds: 10)));
    } catch (e) {
      developer.log('No location: ${e.toString()}', name: 'error');
      return null;
    }
  }

  LatLng? _currentPosition;
  double _meters = 0;

  LatLngBounds? _bounds;

  Future<bool> loadStyle() async {
    try {
      if (_styleString.isEmpty) {
        _styleString = await _fetchStyle();
        mlMap = MapLibreMap(
          key: mapKey,
          styleString: _styleString,
          compassViewPosition: CompassViewPosition.topLeft,
          onMapCreated: onMapUpdated,
          initialCameraPosition: hasPosition
              ? CameraPosition(target: currentPosition, zoom: 11)
              : britain,
          trackCameraPosition: true,
          onCameraMove: onCameraMove,
          onMapClick: onTap,
          onCameraIdle: onIdle,
          scrollGesturesEnabled: true,
          onStyleLoadedCallback: () => onStyleLoaded(),
          zoomGesturesEnabled: true,
          gestureRecognizers: Set()
            ..add(
              Factory<EagerGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            ),
        );

        return _styleString.isNotEmpty;
      } else {
        return true;
      }
    } catch (e) {
      developer.log('MapService().loadStyle() error: ${e.toString()}',
          name: 'error');
    }
    return false;
  }

  Future<void> onMapUpdated(MapLibreMapController mapController) async {
    // Completes mapFuture too - nothing did after the move to go_router,
    // so anything waiting for the map waited for ever
    await setMapController(mapController);
    zoomFabController ??= ZoomFabController();

    if (CurrentTripItem().pointsOfInterest.isNotEmpty) {
      try {
        List<Map<String, dynamic>> jsonRoutes =
            routesToGeoJson(routes: CurrentTripItem().routes);
        await controller?.setGeoJsonSource("route-data", {
          "type": "FeatureCollection",
          "features": jsonRoutes,
        });
        List<Map<String, dynamic>> jsonEnds =
            routeEndsToGeoJson(routes: CurrentTripItem().routes);
        LatLng start = LatLng(
            CurrentTripItem().pointsOfInterest.first.point.y.toDouble(),
            CurrentTripItem().pointsOfInterest.first.point.x.toDouble());
        await controller?.setGeoJsonSource("waypoint-data", {
          "type": "FeatureCollection",
          "features": jsonEnds,
        });
        controller?.animateCamera(CameraUpdate.newLatLng(start),
            duration: Duration(seconds: 1));
      } catch (e) {
        developer.log('Error showing routes: ${e.toString()}', name: 'error');
      }
    }

    fabsController?.refresh();
    if (kIsWeb && statusBarController != null) {
      statusBarController!.refresh();
    }
  }

  Future<void> onStyleLoaded() async {
    if (!_styleCompleter.isCompleted) _styleCompleter.complete();
    // A new style drops runtime layers, so add the marker every time
    await addLocationMarker();
    await PlannerService().styleLoaded(); // and AI assist's candidates
    if (controller != null) {
      if (CurrentTripItem().pointsOfInterest.isNotEmpty) {
        LatLng position = LatLng(
            CurrentTripItem().pointsOfInterest.first.point.y.toDouble(),
            CurrentTripItem().pointsOfInterest.first.point.x.toDouble());
        await controller?.moveCamera(
          CameraUpdate.newLatLngZoom(
            position,
            12.0,
          ),
        );
      } else if (hasPosition) {
        // without a fix yet it stays on Britain - locate() moves it later
        await controller?.moveCamera(
          CameraUpdate.newLatLngZoom(
            currentPosition,
            12.0,
          ),
        );
      }
    }
  }

  static const String locationSource = 'location-data';
  static const String locationLayer = 'location-layer';
  static const String locationIcon = 'location-arrow';

  /// The user's position marker is added by the app, not the style sheet. The
  /// style is downloaded once at the start of a session so the app works
  /// offline, and may become per-user, so it can't be relied on to have it.
  /// The arrow is drawn in code (no asset or network) and the layer rotates
  /// it by the feature's bearing, aligned to the map.
  Future<void> addLocationMarker() async {
    if (controller == null) return;
    try {
      await controller!.addImage(locationIcon, await locationArrowImage());
      await controller!.addGeoJsonSource(
          locationSource, {"type": "FeatureCollection", "features": []});
      await controller!.addSymbolLayer(
        locationSource,
        locationLayer,
        const SymbolLayerProperties(
          iconImage: locationIcon,
          iconRotate: [Expressions.get, 'bearing'],
          iconRotationAlignment: 'map',
          iconPitchAlignment: 'map',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          // The arrow is drawn 96 pixels across. A phone shows it at its
          // screen's density (about a third of that); the web showed all 96.
          iconSize: kIsWeb ? 0.4 : 1.0,
        ),
        enableInteraction: false,
      );
    } catch (e) {
      developer.log('Error MapService().addLocationMarker(): ${e.toString()}',
          name: 'error');
    }
  }

  /// Moves the position marker, or hides it when position is null
  Future<void> showLocation({Point? position, double bearing = 0}) async {
    if (controller == null) return;
    try {
      await controller!.setGeoJsonSource(locationSource, {
        "type": "FeatureCollection",
        "features": position == null
            ? []
            : locationMarkerToGeoJson(location: position, bearing: bearing),
      });
    } catch (e) {
      developer.log('Error MapService().showLocation(): ${e.toString()}',
          name: 'error');
    }
  }

  /// A navigation arrow pointing up (north), outlined in white so it shows on
  /// any map style.
  Future<Uint8List> locationArrowImage(
      {Color colour = const Color(0xFF1E88E5), double size = 96}) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    Path arrow = Path()
      ..moveTo(size * 0.5, size * 0.1)
      ..lineTo(size * 0.85, size * 0.88)
      ..lineTo(size * 0.5, size * 0.68)
      ..lineTo(size * 0.15, size * 0.88)
      ..close();
    canvas.drawPath(
        arrow,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.1
          ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(arrow, Paint()..color = colour);
    ui.Image image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  LatLng get currentPosition =>
      _currentPosition ?? LatLng(51.433, -0.513); // <-- Staines

  /// Whether currentPosition is where the user is, not the default
  bool get hasPosition => _currentPosition != null;

  /// The last style fetched, kept on the phone - without a signal the app
  /// still has a map, and offline maps' tiles to draw it with
  Future<File?> _savedStyleFile() async => kIsWeb
      ? null
      : File(
          '${(await getApplicationDocumentsDirectory()).path}/map_style.json');

  Future<String> _fetchStyle() async {
    try {
      String style = await getStyle(url: urlTilerMapLibre);
      File? saved = await _savedStyleFile();
      if (style.trimLeft().startsWith('{')) {
        await saved?.writeAsString(style);
      } else if (saved != null && await saved.exists()) {
        style = await saved.readAsString(); // offline - the last one fetched
      }
      _styleString = appStyle(style);
    } catch (e) {
      developer.log('Error getting style from api: ${e.toString()}',
          name: 'error');
      return '';
    }
    // Where the phone last was, if it may say - instant, so the map starts
    // there. A browser can't say.
    if (!kIsWeb) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if ([LocationPermission.always, LocationPermission.whileInUse]
            .contains(permission)) {
          Position? last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            _currentPosition = LatLng(last.latitude, last.longitude);
          }
        }
      } catch (e) {
        developer.log('No last position: ${e.toString()}', name: 'error');
      }
    }
    // The app doesn't wait for the location: the prompt may not be answered
    // for a while (a browser's is easy to miss), and a fix can take seconds
    unawaited(locate());
    return _styleString;
  }

  /// The map's view before there's a fix: Great Britain
  static const CameraPosition britain =
      CameraPosition(target: LatLng(54.0, -2.5), zoom: 5);

  /// Asks for the user's position, and when the first fix comes moves the
  /// map there - unless they've moved it already, or a trip is on it.
  /// Refused, switched off or never answered, the map stays where it is.
  Future<void> locate() async {
    try {
      await getPermission().timeout(const Duration(seconds: 30));
    } catch (e) {
      developer.log('Location permission: ${e.toString()}', name: 'error');
    }
    Position? position = await currentPositionOrNull();
    if (position == null) return;
    LatLng? start = _currentPosition;
    _currentPosition = LatLng(position.latitude, position.longitude);
    MapLibreMapController map = await mapFuture; // the map page may come later
    LatLng? showing = map.cameraPosition?.target;
    LatLng expected = start ?? britain.target;
    bool untouched = showing == null ||
        ((showing.latitude - expected.latitude).abs() < 0.01 &&
            (showing.longitude - expected.longitude).abs() < 0.01);
    if (untouched && CurrentTripItem().pointsOfInterest.isEmpty) {
      await map.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 11),
          duration: const Duration(seconds: 2));
    }
  }

  Future<LatLngBounds> get bounds async => (await controller!
      .getVisibleRegion()
      .then((onValue) => _bounds = onValue));

  double get mapWidth => mapSize().width;

  double get mapHeight => mapSize().height;

  Point get mapMiddle => Point(mapSize().width / 2, mapSize().height / 2);

  double get mapWidthMeters => _meters;

  void setMapWidthMeters({required double meters}) {
    _meters = meters;
  }

  void setPosition({required LatLng latLng}) {
    _currentPosition = latLng;
  }

  void setBounds({required LatLngBounds bounds}) {
    _bounds = bounds;
  }

  Future<double> getMapWidthMeters() async {
    _bounds = await controller!.getVisibleRegion();
    if (_bounds != null) {
      double meters = distanceBetween(startList: [
        _bounds!.southwest.longitude,
        _bounds!.southwest.latitude
      ], endList: [
        _bounds!.northeast.longitude,
        _bounds!.southwest.latitude
      ]);
      _meters = meters > 10 ? meters : _meters;
    }
    return _meters;
  }

  /// mapSize returns the Logical Size of the map in Logical Pixels which may be less than the actual size
  /// https://www.dhiwise.com/post/getting-the-right-size-a-tutorial-on-flutter-get-widget-size
  Size mapSize() {
    Size mapSize = Size(0, 0);
    final bnKeyContext = mapKey.currentContext;
    if (bnKeyContext != null) {
      try {
        RenderBox box = bnKeyContext.findRenderObject() as RenderBox;
        mapSize = Size(box.size.width, box.size.height);
      } catch (e) {
        debugPrint('error: ${e.toString()}');
      }
    }
    return mapSize;
  }

  /// THESE ARE THE TRIPS.DART METHODS
  ///

  _tripsOnTap(tap) async {
    var foundFeatures;
    try {
      // A trip's label, or its route - its trip is in its properties
      foundFeatures = await controller!.queryRenderedFeatures(
          tap,
          [
            publishedHighlightLabel,
            "route-marker-layer",
            "planned_routes_highlighted"
          ],
          null);
      if (foundFeatures.isEmpty) {
        // A route is a few pixels wide - a near miss counts
        Point p = tap as Point;
        foundFeatures = await controller!.queryRenderedFeaturesInRect(
            Rect.fromCenter(
                center: Offset(p.x.toDouble(), p.y.toDouble()),
                width: 24,
                height: 24),
            [
              publishedHighlightLabel,
              "route-marker-layer",
              "planned_routes_highlighted"
            ],
            null);
      }
      if (foundFeatures.isNotEmpty) {
        String uri = '${foundFeatures.first['properties']?['uri'] ?? ''}';
        if (kIsWeb) {
          sideDrawerController?.showTrip(uri);
        } else {
          bottomDrawerController?.showTrip(uri);
        }
        // Keep the trip in view beside the drawer that's just opened - the
        // label is at the start of the trip; a tapped route stays where it is
        List points = foundFeatures.first['geometry']?['type'] == 'Point'
            ? [foundFeatures.first['geometry']['coordinates']]
            : const [];
        if (points.isNotEmpty && points.first is List) {
          // After the BottomDrawer has slid open (half a second), so its
          // height is the open height
          Future.delayed(
              Duration(milliseconds: kIsWeb ? 50 : 600),
              () => showInView(LatLng(
                  points.first[1].toDouble(), points.first[0].toDouble())));
        }
      }
    } catch (e) {
      developer.log(
          'Error MapService() _tripsOnTap() error ${e.toString} - features: ${foundFeatures.toString()}',
          name: 'error');
    }
  }

  _tripsOnMapUpdate() async {
    _drivesRequest ??= DrivesRequest(
        onUpdated: (_) => {},
        onGetDetails: (_) => {},
        onGetDownload: (index, name) => {},
        imageRepository: _tripImageRepository);

    _tripRequest ??= TripRequest(
        onUpdated: (_) => {},
        onGetDetails: (_) => {},
        imageRepository: _tripImageRepository);
    Position? position = await currentPositionOrNull();
    if (position != null) {
      _currentPosition = LatLng(position.latitude, position.longitude);
    }
  }

  Function(bool)? createTripOnMapIde;

  /// Published's filters, for the view: the trip under the crosshair -
  /// its route glows, and its label is drawn over any others (where trips
  /// start from the same place only one label had room) - and every other
  /// trip's label. (The labels were limited to the middle of the view
  /// Published opened with, so went missing as the map moved; the glow was
  /// on every trip near the middle.)
  Future<void> _publishedFilters(LatLngBounds bounds) async {
    List<String> highlighted = await _tripsUnderCrosshair();
    // Only when the trip picked out changes: a symbol layer queried while
    // it's laid out again after a filter change can throw, losing a tap
    String key = highlighted.join(',');
    if (key == _highlightedTrips) return;
    _highlightedTrips = key;
    controller!
        .setFilter("route-marker-layer", publishedLabelsFilter(highlighted));
    controller!.setFilter(publishedHighlightLabel,
        publishedHighlightFilter(highlighted, 'shield'));
    controller!.setFilter("good_roads_highlighted",
        publishedHighlightFilter(highlighted, 'line'));
    controller!.setFilter(
        "roads_highlighted", fenceFilter(bounds: bounds, proportion: 0.6));
  }

  /// The trip picked out last (its uri, '' none) - null before any
  String? _highlightedTrips;

  /// The published trip whose route is under the crosshair - the nearest,
  /// if more than one (where routes share a road, both labels were drawn
  /// over each other). Within a few pixels, as a route is only a few wide.
  Future<List<String>> _tripsUnderCrosshair() async {
    try {
      Point middle = mapMiddle;
      for (double size in [8, 20]) {
        List features = await controller!.queryRenderedFeaturesInRect(
            Rect.fromCenter(
                center: Offset(middle.x.toDouble(), middle.y.toDouble()),
                width: size,
                height: size),
            ["planned_routes_highlighted"],
            null);
        for (var feature in features) {
          String uri = '${feature['properties']?['uri'] ?? ''}';
          if (uri.isNotEmpty) return [uri];
        }
      }
    } catch (e) {
      developer.log('_tripsUnderCrosshair(): ${e.toString()}', name: 'error');
    }
    return [];
  }

  /// A trip just published: the next time Published opens, the map shows
  /// it, fetched again (see initialiseTrips())
  MyTripItem? _justPublished;

  void tripPublished(MyTripItem trip) {
    _justPublished = trip;
    _drivesRequest?.invalidate();
    _publishedGreatRoads = null; // its great roads, on Explore
  }

  /// The great roads in published trips - fetched once, and again after
  /// publishing. All of them: the API doesn't use the view yet.
  List? _publishedGreatRoads;

  /// Explore shows them, so a trip can be planned along them
  Future<void> _showPublishedGreatRoads() async {
    try {
      if (_publishedGreatRoads == null) {
        dynamic geoJson = await getGoodRoadsGeoJson();
        var data = geoJson is String ? jsonDecode(geoJson) : null;
        if (data is! Map) return; // not reached - tried again next time
        _publishedGreatRoads = [
          for (var feature in data['features'] ?? [])
            if (feature['group'] == 'line') feature
        ];
      }
      if (_page != 2) return; // Published opened meanwhile
      await controller?.setGeoJsonSource(publishedGreatRoadSource,
          {"type": "FeatureCollection", "features": _publishedGreatRoads});
    } catch (e) {
      developer.log('_showPublishedGreatRoads(): ${e.toString()}',
          name: 'error');
    }
  }

  /// The map moved to show the trip just published - its route's extent
  Future<void> _showJustPublished() async {
    MyTripItem? trip = _justPublished;
    _justPublished = null;
    if (trip == null || controller == null) return;
    List<List<double>> points = [
      for (var route in trip.routes)
        for (List<double> point in route.lines)
          if (point.length >= 2) point
    ];
    if (points.isEmpty) return;
    double west = points.map((p) => p[0]).reduce(min);
    double east = points.map((p) => p[0]).reduce(max);
    double south = points.map((p) => p[1]).reduce(min);
    double north = points.map((p) => p[1]).reduce(max);
    try {
      await controller!
          .moveCamera(CameraUpdate.newLatLngBounds(
              LatLngBounds(
                  southwest: LatLng(south, west),
                  northeast: LatLng(north, east)),
              // on the web, clear of the SideDrawer, which opens over the
              // left of the map
              left: 40 + (kIsWeb ? mapWidth * 0.4 : 0),
              top: 40,
              right: 80,
              bottom: 40))
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (e) {
      developer.log('_showJustPublished(): ${e.toString()}', name: 'error');
    }
  }

  Future<void> _tripsOnIdle({required int page, bool force = false}) async {
    Map geoJson = {};
    if (force || (_checkUpdates ?? false)) {
      _checkUpdates = false; // <-- Only run this when the map has moved

      try {
        LatLngBounds bounds = await controller!.getVisibleRegion();
        double zoom = controller!.cameraPosition!.zoom;

        /// DrivesRequest cache keeps track of api data updating the map and the drawers

        if (page == 1) {
          // 1 = trips / published  2 = createTrip / explore
          await _drivesRequest!.update(
              bounds: bounds,
              zoom: zoom,
              force: force); //  _bottomDrawerController.itemsCount() == 0);
        } else {
          /// _tripRequests the Published cache _tripRequest keeps track of the data required
          /// as the user moves the map or changes the zoom. It redraws the geoJson features
          /// on the map to correspond to the data.
          await _tripRequest!.update(bounds: bounds, zoom: zoom);
        }
        if (page == 1) await _publishedFilters(bounds);
        await controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
      } catch (e) {
        developer.log(
            'Error MapService()._tripsOnIdle() error: ${e.toString()} ${geoJson.toString()}',
            name: 'error');
      }
    }
  }

  /// Initialisation routines for the 3 different Map screens (2 in mobile version)
  ///   1 Put the correct data into the side / bottom drawer
  ///   2 Set the drawer to fixed or not fixed

  /// Empties the published trips and every layer of the current trip -
  /// before only the route and waypoints were cleared, so its great roads
  /// and points of interest showed over the published trips
  /// A published trip opened on Published: its waypoints and points of
  /// interest on the map (publishedTripLayers()) - or, with none, none
  Future<void> showPublishedTrip(MyTripItem? trip) async {
    // kept in the drawer's list while it's open, whatever the view
    _drivesRequest?.openTrip = trip?.uri ?? '';
    try {
      await controller?.setGeoJsonSource(
          publishedTripSource,
          trip == null
              ? {"type": "FeatureCollection", "features": []}
              : publishedTripToGeoJson(trip));
    } catch (e) {
      developer.log('showPublishedTrip(): ${e.toString()}', name: 'error');
    }
  }

  Future<void> clearGeoJson() async {
    for (String source in [
      'published-data',
      publishedTripSource,
      publishedGreatRoadSource,
      ...mapSources.keys
    ]) {
      try {
        await controller!.setGeoJsonSource(
            source, {"type": "FeatureCollection", "features": []});
      } catch (e) {
        developer.log('clearGeoJson() $source: ${e.toString()}', name: 'error');
      }
    }
    await controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  Future<bool> initialiseTrips() async {
    // Explore changes the label filter - set Published's again
    _highlightedTrips = null;
    if (kIsWeb) {
      // Replaced by the published trips once they've loaded
      await sideDrawerController!
          .setContent(content: BottomDrawerItems.drives, drawerItems: []);
    } else {
      // Closed until the user opens it; the trips fill it as they load
      bottomDrawerController?.setContent(
          content: BottomDrawerItems.drives, drawerItems: [], open: false);
      bottomDrawerController?.close();
    }
    _tripsOnMapUpdate(); // <-- Initialise the Trips cache
    await clearGeoJson();
    await _showJustPublished();

    await _tripsOnIdle(
        page: _page,
        force: true); // <-- Update the drawer contents and map geoJson
    if (kIsWeb) {
      // Open, with the trips in view - it can be closed for more map
      sideDrawerController!.setFixed(fixed: false);
      sideDrawerController!.open();
    }
    return true;
  }

  Future<bool> initialiseExplore() async {
    await clearGeoJson();
    // Draw the trip being planned again - Published cleared it
    await CurrentTripItem().refreshMap();
    _showPublishedGreatRoads(); // not waited for
    if (!kIsWeb) {
      // The trip's details, not Published's list - closed until wanted
      bottomDrawerController?.setContent(
          content: BottomDrawerItems.trip, open: false);
      bottomDrawerController?.close();
    }
    if (kIsWeb) {
      sideDrawerController!.setContent(content: BottomDrawerItems.trip);
      sideDrawerController!.setFixed(fixed: false);
      sideDrawerController!.close();
    } else {}
    return true;
  }

  /// GeoJson handling routines
  /// Uses the MapUpdated Enum to action the GeoJson updates
  /// The MapUpdated Enum is a bitmask that returns a list of things to update
  /// MapUpdates.sourcesToUpdate. Requests can be added to the bitmask with a
  /// MapUpdates.add(MapUpdates)

  Map<String, dynamic> mapSources = {
    "route-data": routesToGeoJson,
    "good-road-data": goodRoadsToGeoJson,
    "waypoint-data": waypointsToGeoJson,
    "good-road-waypoint-data": goodRoadWaypointsToGeoJson,
    "point-of-interest-data": pointsOfInterestToGeoJson,
    "streamed-data": followersToGeoJson,
  };
  Future<void> updateMapGeoJson(
      {required MapUpdates mapUpdates,
      MapUpdates? exitMapUpdates,
      Point? centre}) async {
    if (controller == null) return; // no map yet - e.g. in a test
    centre ??= Point(controller!.cameraPosition!.target.longitude,
        controller!.cameraPosition!.target.latitude);
    if (mapUpdates != MapUpdates.none && !mapUpdates.isUpdating) {
      List<String> sources = mapUpdates.sourcesToUpdate;
      if (sources.isNotEmpty) {
        // Set the updating flag to prevent map onIdle calls restarting update before completed
        mapUpdates = mapUpdates.add(MapUpdates.updating);

        for (int i = 0; i < sources.length; i++) {
          try {
            await controller!.setGeoJsonSource(sources[i], {
              "type": "FeatureCollection",
              "features": mapSources[sources[i]](),
            });
          } catch (e) {
            developer.log(
                'Error MapService().updateMapGeoJson() setGeoJsonSource() failed source: ${sources[i]}: ${e.toString()}',
                name: "error");
          }
        }
      }
    }
    createTripController?.update();
    mapUpdates = exitMapUpdates ?? MapUpdates.none;
  }

  Future getPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services not enabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied. Check your settings');
      }
    }
  }
}
