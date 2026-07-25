import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:drives/classes/classes.dart' hide Position, distanceBetween;
import 'package:flutter/rendering.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
// import 'package:drives/helpers/create_trip_helpers.dart';
import 'package:flutter/material.dart';
import 'web_helper.dart';
import '../constants.dart';
// import '../classes/maplibre_map.dart';
import '../helpers/helpers.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../tiles/tiles.dart';
import 'package:geolocator/geolocator.dart';

// import 'package:flutter/gestures.dart';
// import 'package:flutter/foundation.dart';
// import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';

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

  MapLibreMapController? controller;
  SideDrawerController? sideDrawerController;
  BottomDrawerController? bottomDrawerController;
  WebAppBarController? webAppBarController;
  StatusBarController? statusBarController;
  ZoomFabController zoomFabController = ZoomFabController();
  ScrollController scrollController = ScrollController();

  final GlobalKey mapKey = GlobalKey();
  // final GlobalKey scrollToKey = GlobalKey();
  ItemScrollController itemScrollController = ItemScrollController();

  final ImageRepository _tripImageRepository = ImageRepository();

  String _styleString = '';
  Future<String>? _styleFuture;
  Future<String> get style => _styleFuture ??= _fetchStyle();
  DrivesRequest? _drivesRequest;
  TripRequest? _tripRequest;
  bool? _checkUpdates = false;
  CameraPosition? _cameraPosition;
  MapUpdates mapUpdates = MapUpdates.updateAll; // <-- What geoJson to update
  MapUpdates onExitUpdate = MapUpdates.none;

  final ValueNotifier<int?> scrollToSideDrawerIndex = ValueNotifier<int?>(null);

  void requestScroll(int index) {
    scrollToSideDrawerIndex.value = index;
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
  Future<bool> setPage({required int page}) async {
    _page = page;
    switch (_page) {
      case 1:
        return await initialiseTrips();
      case 2:
        return await initialiseExplore();
      case 3:
        return initialiseFavourites();
    }
    return true;
  }

  /// onIdle called after the map has stopped doing something
  /// defined within main.dart where the persistent mapLibreMap
  /// id instantiated - its onCameraIdle gets assigned to this method.

  onIdle() async {
    _meters = await getMapWidthMeters();
    statusBarController!.refresh();
    zoomFabController.update();
    //  if (_page == 1) {
    _tripsOnIdle(page: _page);
    //  } else if (_page == 2) {
    //    _createTripsOnIdle();
    // }
  }

  LatLng? _currentPosition;
  double _meters = 0;

  LatLngBounds? _bounds;

  Future<bool> loadStyle() async {
    if (_styleString.isEmpty) {
      _styleFuture ??= _fetchStyle();
      return await _styleFuture != null;
    } else {
      return true;
    }
  }

  LatLng get currentPosition =>
      _currentPosition ?? LatLng(51.433, -0.513); // <-- Staines

  Future<String> _fetchStyle() async {
    _styleString = await getStyle(url: urlTilerMapLibre);
    Position position = await Geolocator.getCurrentPosition();
    _currentPosition = LatLng(position.latitude, position.longitude);
    return _styleString;
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

  // List<Widget> screenCache = [];

  // Future<double> get mapWidthMeters => getMapWidthMeters();

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
    final bnKeyContext = MapService().mapKey.currentContext;
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
      // var point = Point(tap.x.toDouble(), tap.y.toDouble());
      foundFeatures = await controller!
          .queryRenderedFeatures(tap, ["route-marker-layer"], null);
      if (foundFeatures.isNotEmpty) {
        var tappedFeature = foundFeatures.first;
        var name = tappedFeature['properties']['name'];
        String uri = tappedFeature['id'].substring(0, 32);
      }
    } catch (e) {
      developer.log(
          'Error MapService() _tripsOnTap() error ${e.toString} - features: ${foundFeatures.toString()}',
          name: 'error');
    }
  }

  // _tripsOnMapUpdate(LatLng pos) async {
  _tripsOnMapUpdate() async {
    _drivesRequest ??= DrivesRequest(
        onUpdated: (_) => {},
        onGetDetails: (_) => {},
        onGetDownload: (index, name) => {},
        imageRepository: _tripImageRepository);
    // _mapController = mapController;

    // MapService().currentPosition = await Geolocator.getCurrentPosition();
    _tripRequest ??= TripRequest(
        onUpdated: (_) => {},
        onGetDetails: (_) => {},
        imageRepository: _tripImageRepository);
    // CurrentTripItem().mapController = _mapController;
    Position position = await Geolocator.getCurrentPosition();
    _currentPosition = LatLng(position.latitude, position.longitude);
  }

  Function(bool)? createTripOnMapIde;

  _tripsOnIdle({required int page, bool force = false}) async {
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
        } else if (page == 2) {
          /// _tripRequests the Published cache _tripRequest keeps track of the data required
          /// as the user moves the map or changes the zoom. It redraws the geoJson features
          /// on the map to correspond to the data.
          await _tripRequest!.update(bounds: bounds, zoom: zoom);
        }
        var filter = fenceFilter(bounds: bounds, proportion: 0.6);
        controller!.setFilter("route-marker-layer", filter);
        controller!.setFilter("good_roads_highlighted", filter);
        // _mapController!.setFilter("good-road-marker-layer", filter);
        controller!.setFilter("roads_highlighted", filter);
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

  Future<void> clearGeoJson() async {
    /// Update the map
    await controller!.setGeoJsonSource(
        "published-data", {"type": "FeatureCollection", "features": []});
    await controller!.setGeoJsonSource(
        "route-data", {"type": "FeatureCollection", "features": []});
    await controller!.setGeoJsonSource(
        "waypoint-data", {"type": "FeatureCollection", "features": []});
    await controller!.animateCamera(CameraUpdate.zoomBy(0.000001));
  }

  Future<bool> initialiseTrips() async {
    _tripsOnMapUpdate(); // <-- Initialise the Trips cache
    await clearGeoJson();
    await _tripsOnIdle(
        page: _page,
        force: true); // <-- Update the drawer contents and map geoJson
    if (kIsWeb) {
      sideDrawerController!.setFixed(fixed: false);
      sideDrawerController!.open();
    }
    return true;
  }

  Future<bool> initialiseExplore() async {
    await clearGeoJson();
    if (kIsWeb) {
      sideDrawerController!.setContent(content: BottomDrawerItems.trip);
      sideDrawerController!.setFixed(fixed: false);
      sideDrawerController!.close();
    } else {
      // await bottomDrawerController!.setContent(content: BottomDrawerItems.trip, drawerItems: [empty]);
    }
    return true;
  }

  Future<bool> initialiseFavourites() async {
    List myTripItems = [];
    await clearGeoJson();
    myTripItems.addAll(await getPrivateRepository().loadMyTripItems());
    try {
      await MapService().sideDrawerController!.setContent(
          content: BottomDrawerItems.favourites,
          drawerItems: myTripItems); // as List<Widget>);
      Future.delayed(Duration(milliseconds: 200));
      sideDrawerController!.open(width: 0.4);
    } catch (e) {
      developer.log(
          'Error MapService().initialiseFavourites() setting sideDrawer contents: ${e.toString()}',
          name: 'error');
    }

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
    //  centre ??= CurrentTripItem().tripValues.position;
    developer.log(
        '--- MapService().updateMapGeoJson() called mapUpdates: ${mapUpdates.toString()} ---',
        name: '_goodRoad_');
    centre ??= Point(controller!.cameraPosition!.target.longitude,
        controller!.cameraPosition!.target.latitude);

    if (mapUpdates != MapUpdates.none && !mapUpdates.isUpdating) {
      List<String> sources = mapUpdates.sourcesToUpdate;
      if (sources.isNotEmpty) {
        // Set the updating flag to prevent map onIdle calls restarting update before completed
        mapUpdates = mapUpdates.add(MapUpdates.updating);

        for (int i = 0; i < sources.length; i++) {
          try {
            if (i < 5) {
              try {
                await controller!.setGeoJsonSource(sources[i], {
                  "type": "FeatureCollection",
                  "features": mapSources[sources[i]](),
                });
              } catch (e) {
                developer.log(
                    'Error MapService().updateMapGeoJson() mapController.seGeoJsonSource() failed source: ${sources[i]} (i:$i)',
                    name: "error");
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
}

/*
void _executeChipActions(
    {MyTripActions tripActions = MyTripActions.none}) async {
  developer.log('_executeChipAction MyTripActions.${tripActions.toString()}',
      name: '_chips_');
  switch (tripActions) {
    case MyTripActions.beginTracking:
      await MapService().controller!.animateCamera(CameraUpdate.zoomTo(14.2));
      CurrentTripItem().tripState = TripState.tracking;
      setLocationUpdates();
      // setState(()  {});
      return;

    case MyTripActions.none || MyTripActions.addWaypoint:
      // setState(()  {});
      return;

    case MyTripActions.editTrip:
      CurrentTripItem().tripState = TripState.editing;
      return;

    case MyTripActions.saveTrip:
      _saveTrip();
      return;

    case MyTripActions.clearTrip:
      // setState(() => (CurrentTripItem().tripState = TripState.none));
      // CurrentTripItem().mapUpdates = MapUpdates.updateAll;
      // micro-nudge to ensure MapLibre refreshes
      // await _mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
      return;

    case MyTripActions.startManual:
      /*
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
      */
      try {
        updateControllers(
            items: BottomDrawerItems.trip, open: true, dock: true);
        CurrentTripItem().tripValues.showTarget = true;
        CurrentTripItem().tripActions = TripActions.none;
        CurrentTripItem().tripState = TripState.manualStart;
        // setState(()  {});
      } catch (e) {
        developer.log('Error _executeTripActions() ${e.toString()}',
            name: '_chips_');
      }
      return;

    case MyTripActions.addPointOfInterest:
      /*
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
      */
      setState(
        () => updateControllers(
          items: BottomDrawerItems.trip,
          open: true,
          dock: true,
        ),
      );

      return;

    case MyTripActions.addGoodRoad:
      setState(() => (CurrentTripItem().isGoodRoad = true));
      return;

    /// May be able to combine this with .addPointOfInterest
    case MyTripActions.addGoodRoadDetails:
      /*
        _bottomDrawerController.setContent(content: BottomDrawerItems.goodRoad);
        _bottomDrawerController.open(height: 300);
        _bottomDrawerController.dockOpenTile();
        */
      updateControllers(
          items: BottomDrawerItems.goodRoad, open: true, dock: true);
      setState(()  {});
      return;

    case MyTripActions.showSteps:
      /*
        _bottomDrawerController.setContent(content: BottomDrawerItems.maneuvers);
        _bottomDrawerController.open(height: 300);
        */
      updateControllers(
          items: BottomDrawerItems.maneuvers, open: true, dock: true);
      CurrentTripItem().tripActions = TripActions.none;
      return;

    case MyTripActions.showMessages:
      _bottomDrawerController.setContent(content: BottomDrawerItems.maneuvers);
      _bottomDrawerController.open(height: 300);
      CurrentTripItem().tripActions = TripActions.none;
      return;

    case MyTripActions.showGroup:
      _bottomDrawerController.setContent(
          content: BottomDrawerItems.group, drawerItems: _following);
      _bottomDrawerController.open(height: 300);
      CurrentTripItem().tripActions = TripActions.none;
      return;

    case MyTripActions.follow:
      _bottomDrawerController.setContent(content: BottomDrawerItems.maneuvers);
      setState(() => CurrentTripItem().tripActions = TripActions.none);
      setLocationUpdates();

      return;

    case MyTripActions.stopFollowing:
      CurrentTripItem().tripValues.pauseStream = true;
      setState(() => CurrentTripItem().tripState = TripState.stoppedFollowing);
      setLocationUpdates();
      return;

    case MyTripActions.track:
      setLocationUpdates();
      setState(()  {});
      return;

    case MyTripActions.stopTracking:
      CurrentTripItem().tripValues.stopStream = true;
      setState(() => CurrentTripItem().tripState = TripState.stoppedTracking);
      setLocationUpdates();
      return;

    default:
      _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
      //  _bottomDrawerController.open(height: 300);
      CurrentTripItem().tripActions = TripActions.none;
  }
  return;
}
*/

/*
class PersistentMap extends StatelessWidget {
  final Function(LatLng, MapLibreMapController)? onUpdate;
  final Function(Point, LatLng)? onTap;
  final Function()? onIdle;
  const PersistentMap({super.key, this.onIdle, this.onTap, this.onUpdate});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: MapService().style,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        return MapLibreMap(
          key: MapService().mapKey, // <-- Keeps the map alive
          styleString: snapshot.data!,

          /// snapshot.data!.toString(),
          initialCameraPosition:
              CameraPosition(target: MapService().currentPosition, zoom: 11),

          trackCameraPosition: true, // ensures that zoom is updated
          //     onCameraMove: (position) {
          //       widget.onUpdate!(position.target, mapController!);
          //     },
          onMapCreated: _onMapCreated,
          onMapClick: onTap,
          onCameraIdle: onIdle,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer())
          },
        );
      },
    );
  }

  void _onMapCreated(MapLibreMapController controller) async {
    MapService().controller = controller;
    Position position = await Geolocator.getCurrentPosition();
    LatLng currentPosition = LatLng(position.latitude, position.longitude);
    onUpdate!(currentPosition, controller);
  }
}
*/
