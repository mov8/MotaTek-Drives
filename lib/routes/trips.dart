// import 'package:drives/constants.dart';
// import 'package:drives/constants.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/models.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:drives/services/services.dart' hide getPosition;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drives/classes/route.dart' as mt;

import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';

enum MapHeight {
  full,
  headers,
  pointOfInterest,
  message,
}

class Trips extends StatefulWidget {
  const Trips({
    super.key,
  });

  @override
  State<Trips> createState() => _TripsState();
}

class _TripsState extends State<Trips> with TickerProviderStateMixin {
  // GlobalKey mapKey = GlobalKey();
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  late final PointOfInterestController _pointOfInterestController;
  late final ExpandNotifier _expandNotifier;
  late final AnimatedMapController _animatedMapController;
  // late final MapCamera _animatedMapController.mapController.camera;
// scrollablepositonedlist
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  // final ScrollOffsetListener scrollOffsetListener =
  //     ScrollOffsetListener.create();
// scrollablepositonedlist
//  final _mapController = MapController();
  final GlobalKey _scaffoldKey = GlobalKey();
  late final Future<bool> _dataLoaded;
  late Style _style;
  late final List<TripItem> tripItems;
  bool _showPreferences = false;
  final TripsPreferences _preferences = TripsPreferences();
  final ScrollController _preferencesScrollController = ScrollController();

  final _dividerHeight = 35.0;
  int _resizeDelay = 0;
  bool refreshTrips = true;
  bool _showDetails = false;
  List<double> mapHeights = [0, 0, 0, 0];
  double mapHeight = 250;
  double listHeight = -1;
  final List<LatLng> routePoints = const [LatLng(51.478815, -0.611477)];
  final String stadiaMapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';
  late StyleReader _styleReader;
  final TripItemRepository _tripItemRepository = TripItemRepository();
  final PointOfInterestRepository _pointOfInterestRepository =
      PointOfInterestRepository();
  final GoodRoadRepository _goodRoadRepository = GoodRoadRepository();
  final RouteRepository _routeRepository = RouteRepository();
  final ImageRepository _imageRepository = ImageRepository();
  final List<Map<String, dynamic>> _tripsOnMap = [];
  final Fence _cacheFence =
      Fence(northEast: const LatLng(0, 0), southWest: const LatLng(0, 0));
  final Fence _screenFence =
      Fence(northEast: const LatLng(0, 0), southWest: const LatLng(0, 0));
  final List<Feature> _features = [];
  final List<Feature> _visibleFeatures = [];
  final List<Feature> _cachedFeatures = [];
  final List<mt.Route> _routes = [];
  final List<mt.Route> _goodRoads = [];
  final List<Card> _cards = [];

  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    tripItems = [];
    // _features = [];
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _pointOfInterestController = PointOfInterestController();
    _expandNotifier = ExpandNotifier(-1);
    _animatedMapController = AnimatedMapController(vsync: this);
    //  _animatedMapController.mapController.camera = _animatedMapController.mapController.camera;

    _dataLoaded = _getTripData(features: _features);

    _preferencesScrollController.addListener(
      () {
        if (_preferencesScrollController.position.atEdge) {
          bool isTop = _preferencesScrollController.position.pixels == 0;
          if (isTop) {
            setState(() {
              _preferences.isRight = true;
              _preferences.isLeft = false;
            });
          } else {
            setState(() {
              _preferences.isLeft = true;
              _preferences.isRight = false;
            });
          }
        } else if (_preferences.isRight || _preferences.isLeft) {
          setState(() {
            _preferences.isLeft = false;
            _preferences.isRight = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    //   _mapController.dispose();
    super.dispose();
  }

  Future<bool> _getTripData({required List<Feature> features}) async {
    try {
      /// getFeatures returns all the features from the API
      /// type 1: drives - id + max/min lat/lng
      /// type 2: points of interest excluding type 12 ad 16 drive start end (12) and followers (16)
      ///         type 3 is the automatically inserted point of imterest
      ///         when a good road is tarted.
      /// type 3: good roads - id + max/min lat/lng
      ///
      /// good_roads.point_of_interest_id ties the point of interest
      /// to the good_roads polylines(mt.route)

      _features.addAll(await getFeatures(zoom: 12, onTap: pinTap));
    } catch (e) {
      // debugPrint('Error getting features: ${e.toString()}');
    }
    try {
      _styleReader = StyleReader(
          uri:
              'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key={key}',
          apiKey: stadiaMapsApiKey,
          logger: null);
      _style = await _styleReader.read();
    } catch (e) {
      // debugPrint('Error initiating style: ${e.toString}');
    }
    return true;
  }

  pinTap(int index) async {
    Map<String, dynamic> infoMap = await getDialogData(
        features: _features, index: index); //.then((infoMap){}
    Key cardKey = Key('pin_${infoMap['key']}');
    //   int rowIndex = 0;
    //  for (rowIndex; rowIndex < _features.length; rowIndex++) {
    //    //   Feature feature in _features) {
    //    if (_features[rowIndex].row == index) {
    //     break;
    //   }
    // }
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(infoMap['title'],
                style: const TextStyle(fontSize: 16)), //textStyle),
            elevation: 5,
            content:
                Text(infoMap['content'], style: const TextStyle(fontSize: 16)),
            actions: actionButtons(
              context,
              [
                () async {
                  int idx = 0;
                  setState(() => adjustMapHeight(MapHeight.pointOfInterest));
                  await Future.delayed(
                      const Duration(milliseconds: 500)); //_resizeDelay));

                  for (int i = 0; i < _cards.length; i++) {
                    if (_cards[i].key == cardKey) {
                      // Key('pin_${_features[rowIndex].row}')) {
                      idx = i;
                      break;
                    }
                    // i++;
                  }

                  itemScrollController.jumpTo(index: idx);
                  await Future.delayed(const Duration(milliseconds: 200));
                  _expandNotifier.targetValue(target: idx);
                  await Future.delayed(const Duration(milliseconds: 200));
                  itemScrollController.scrollTo(
                      index: idx,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic);

                  _expandNotifier.notifyListeners(); // refresh listeners
                },
                //       () => {// debugPrint('callback - Cancel')}
              ],
              ['Details', 'Cancel'],
            ),
          );
        },
      );
    }
    // });
    // debugPrint('Pin no $index tapped');
  }

  Future<Map<String, dynamic>> getDialogData(
      {required List<Feature> features, required int index}) async {
    Map<String, dynamic> mapInfo = {
      'key': features[index].row,
      'title': 'N/A',
      'content': 'N/A',
      'images': ''
    };

    switch (features[index].type) {
      case 0:
        await _tripItemRepository
            .loadTripItem(
                key: features[index].row,
                id: features[index].id,
                uri: features[index].uri)
            .then((tripItem) => mapInfo = {
                  'key': features[index].row,
                  'title': tripItem.heading,
                  'content': tripItem.body,
                  'images': tripItem.imageUrls
                });
        break;
      case 1:
        PointOfInterest? pointOfInterest =
            await _pointOfInterestRepository.loadPointOfInterest(
                key: features[index].row,
                id: features[index].id,
                uri: features[index].uri);
        if (pointOfInterest != null) {
          // .then((pointOfInterest) =>
          mapInfo = {
            'key': features[index].row,
            'title': pointOfInterest.getName(),
            'content': pointOfInterest.getDescription(),
            'images': pointOfInterest.getImages()
          };
        } //);
        break;

      case 2:
        mt.Route? goodRoad = await _goodRoadRepository.loadGoodRoad(
            key: features[index].row,
            id: features[index].id,
            uri: features[index].uri);
        if (goodRoad != null) {
          for (Feature feature in features) {
            if (feature.type == 1 &&
                feature.uri == goodRoad.pointOfInterestUri) {
              PointOfInterest? pointOfInterest =
                  await _pointOfInterestRepository.loadPointOfInterest(
                      key: feature.row, id: feature.id, uri: feature.uri);
              if (pointOfInterest != null) {
                mapInfo = {
                  'key': feature.row,
                  'title': pointOfInterest.getName(),
                  'content': pointOfInterest.getDescription(),
                  'images': pointOfInterest.getImages()
                };
                return mapInfo;
              }
            }
          }
        }
        break;
      default:
        break;
    }
    return mapInfo;
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Future<void> onGetTrip(int index) async {
    MyTripItem webTrip = await getMyTrip(tripItems[index].driveUri);
    webTrip.setId(-1);
    webTrip.setDriveUri(tripItems[index].driveUri);
    if (context.mounted) {
      Navigator.pushNamed(context, 'createTrip',
          arguments: TripArguments(webTrip, 'web'));
    }
  }

  onTripRatingChanged(int value, int index) async {
    setState(
      () {
        // debugPrint('Value: $value  Index: $index');
        tripItems[index].score = value.toDouble();
      },
    );
    putDriveRating(tripItems[index].uri, value);
  }

  Future<Widget>? _getPortraitBody() async {
    await _dataLoaded == true;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: _resizeDelay),
            curve: Curves.easeInOut, // fastOutSlowIn,
            height: mapHeight,
            width: MediaQuery.of(context).size.width,
            child: _handleMap(),
          ),

          _handleBottomSheetDivider(), // grab rail - GesureDetector()
          const SizedBox(
            height: 5,
          ),
          SizedBox(
            height: listHeight,
            child: cardsList(cards: _cards),
          ),
        ],
      ),
    );
  }

  Widget? cardsList({required List<Card> cards}) {
    Widget? scrollList;
    try {
      if (cards.isNotEmpty) {
        scrollList = ScrollablePositionedList.builder(
          itemCount: cards.length,
          itemBuilder: (context, index) =>
              cards[index < cards.length ? index : cards.length - 1],
          itemScrollController: itemScrollController,
          scrollOffsetController: scrollOffsetController,
          itemPositionsListener: itemPositionsListener,
          //  scrollOffsetListener: scrollOffsetListener,
        );
      }
    } catch (e) {
      debugPrint('Error building scrollList ${e.toString()}');
    }
    return scrollList;
  }

  Widget _handleMap() {
    if (listHeight == -1) {
      adjustMapHeight(MapHeight.full);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _animatedMapController.mapController,
          options: MapOptions(
            onMapEvent: checkMapEvent,
            onMapReady: () async {
              _screenFence.changeBounds(
                  latlngBounds: _animatedMapController
                      .mapController.camera.visibleBounds);
              _cacheFence.setBounds(bounds: _screenFence, deltaDegrees: 0.5);
              _routes.add(mt.Route(points: [const LatLng(0, 0)]));
              _mapReady = true;

              await filterFeatures(
                      source: _features,
                      cache: _cachedFeatures,
                      markers: _visibleFeatures,
                      cacheFence: _cacheFence,
                      screenFence: _screenFence,
                      goodRoads: _goodRoads,
                      routes: _routes)
                  .then((update) {
                if (update) {
                  debugPrint(
                      '>>>>> Map ready about to run getCards cards refreshing cards.length = ${_cards.length}');
                  getCards(features: _visibleFeatures, cards: _cards);
                  debugPrint(
                      '>>>>> Map ready cards refreshed cards.length = ${_cards.length}');
                  // debugPrint(
                  //   '>>>>> Map ready cards refreshed _cards.length: ${_cards.length}');
                }
              });
              setState(() => adjustMapHeight(MapHeight.full));
              // _mapController.mapEventStream.listen((event) {});
              // debugPrint('Map ready......');
            },
            onPositionChanged: (pos, change) async {
              // double zoom = _animatedMapController.mapController.camera.zoom;
              if (refreshTrips) {
                // debugPrint('Refreshing trips');
                _screenFence.changeBounds(
                    latlngBounds: _animatedMapController
                        .mapController.camera.visibleBounds);
                try {
                  refreshTrips = false;
                  bool update = await filterFeatures(
                      source: _features,
                      cache: _cachedFeatures,
                      markers: _visibleFeatures,
                      cacheFence: _cacheFence,
                      screenFence: _screenFence,
                      goodRoads: _goodRoads,
                      routes: _routes);
                  //   .then((update)
                  if (update) {
                    debugPrint(
                        '>>>>> Position canged cards refreshing cards.length = ${_cards.length}');
                    getCards(features: _visibleFeatures, cards: _cards);
                    debugPrint(
                        '>>>>> Map positionChanged cards refreshed cards.length = ${_cards.length}');
                    // debugPrint(
                    // '>>>>> Position canged cards refreshed _cards.length: ${_cards.length}');
                    setState(() => refreshTrips = true);
                  } else {
                    // debugPrint('>>>> Trips refreshed nothing changed');
                    setState(() => refreshTrips = true);
                  }
                  // );
                } finally {
                  // debugPrint('Trips refreshed');
                  //  setState(() => refreshTrips = true);
                }
              }
            },
            initialCenter: LatLng(
                Setup().lastPosition.latitude, Setup().lastPosition.longitude),
            initialZoom: getInitialZoom(),
            maxZoom: 18,
            minZoom: 5,
            //  initialZoom: 15,
            //  maxZoom: 18,
            interactionOptions: const InteractionOptions(
                enableMultiFingerGestureRace: true,
                flags: InteractiveFlag.doubleTapDragZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.pinchMove),
          ),
          children: [
            VectorTileLayer(
              theme: _style.theme,
              sprites: _style.sprites,
              //          tileProviders:
              //              TileProviders({'openmaptiles': _tileProvider()}),
              tileProviders: _style.providers,
              layerMode: VectorTileLayerMode.vector,
              tileOffset: TileOffset.DEFAULT,
              cacheFolder: getCache,
            ),
            PolylineLayer(polylines: _routes),
            PolylineLayer(polylines: _goodRoads),
            MarkerLayer(
              markers: _visibleFeatures,
              alignment: Alignment.topCenter,
            ),
            /*     TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                  maxZoom: 18,
                ), */
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white60,
            child: Row(
              children: [
                Icon(Icons.route_outlined,
                    size: 25, color: colourList[Setup().publishedTripColour]),
                const Text(
                  'Published trip',
                  style: TextStyle(fontSize: 16),
                ),
                Icon(Icons.location_on,
                    size: 25, color: colourList[Setup().pointOfInterestColour]),
                const Text(
                  'Point of interest',
                  style: TextStyle(fontSize: 16),
                ),
                Icon(Icons.route_outlined,
                    size: 25, color: colourList[Setup().goodRouteColour]),
                const Text(
                  'Good road',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double getInitialZoom() {
    return 12;
  }

  routeTapped(routes, details) {
    if (details != null) {
      //   setState(() {
      //   // debugPrint(
      //      'Route tapped routes: ${routes().toString()}  details: ${details.toString()}');
      //    });
    }
  }

  Future<List<TripItem>> getTripsToShow() async {
    try {
      //  _goodRoads = await _goodRoadRepository.loadGoodRoad()
      return [
        for (Map<String, dynamic> trip in _tripsOnMap)
          await _tripItemRepository.loadTripItem(
              key: trip['row'],
              id: trip['source']['id'],
              uri: trip['source']['uri'])
      ];
    } catch (e) {
      // debugPrint('Error: ${e.toString()}');
    }
    return [];
  }

  Future<bool> filterFeatures(
      {required List<Feature> source,
      required List<Feature> cache,
      required List<Feature> markers,
      required Fence screenFence,
      required Fence cacheFence,
      List<mt.Route> routes = const [],
      List<mt.Route> goodRoads = const [],
      double zoom = 12.0}) async {
    if (source.isEmpty) {
      return false;
    }
    bool updateCache =
        cache.isEmpty || !_cacheFence.contains(bounds: screenFence);

    if (cache.isEmpty) {
      debugPrint('Filling cache list - cache is empty');
    } else {
      if (!_cacheFence.contains(bounds: screenFence)) {
        debugPrint('Refreshing cache - _screenFence outside _cacheFence');
      }
    }

    bool updateDetails = true;
    //false;

    List<Feature> listToFilter = cache;
    if (updateCache) {
      cache.clear();
      routes.clear();
      //   markers.clear();
      goodRoads.clear();
      _cacheFence.setBounds(bounds: screenFence, deltaDegrees: 0.5);
      updateDetails = true;
      listToFilter = source;
    } else if (markers.isEmpty) {
      updateDetails = true;
    } else {
      for (Feature feature in markers) {
        if (!_screenFence.contains(bounds: feature.getBounds())) {
          debugPrint('Feature ${feature.row}has left the _screenFence');
          updateDetails = true;
          //   markers.clear();
          break;
        }
      }
      updateDetails = true;
    }
    // debugPrint('______ Update details $updateDetails _______');
    if (updateDetails) {
      //    debugPrint('_____Clearing ${markers.length} markers ______');
      markers.clear();
      for (Feature feature in listToFilter) {
        switch (feature.type) {
          case 0:
            if (_cacheFence.overlapped(bounds: feature.getBounds())) {
              List<mt.Route>? toAdd = await _routeRepository.loadRoute(
                  key: feature.row, id: feature.id, uri: feature.uri);
              if (toAdd != null) {
                if (updateCache) {
                  routes.addAll(toAdd);
                  cache.add(feature);
                }
                updateDetails = await addRouteMarker(
                    screenFence: screenFence,
                    routes: toAdd,
                    feature: feature,
                    visibleFeatures: markers,
                    zoom: zoom);
              }
            }
            break;
          case 1:
            if ((![12, 14, 16].contains(feature.poiType) &&
                    _cacheFence.contains(bounds: feature.getBounds())) &&
                updateCache) {
              if (feature.child.runtimeType != PinMarkerWidget) {
                feature.child = PinMarkerWidget(
                  index: feature.row,
                  color: feature.poiType == 13
                      ? colourList[Setup().goodRouteColour]
                      : colourList[Setup().pointOfInterestColour],
                  width: zoom * 2,
                  overlay: markerIcon(getIconIndex(iconIndex: feature.poiType)),
                  onPress: pinTap,
                );
              }
              cache.add(feature);
            }

            if (_screenFence.contains(bounds: feature.getBounds())) {
              markers.add(feature);
              updateDetails = true;
            }
            break;
          case 2:
            if (_cacheFence.overlapped(bounds: feature.getBounds())) {
              mt.Route? goodRoad = await _goodRoadRepository.loadGoodRoad(
                  key: feature.row, id: feature.id, uri: feature.uri);
              if (goodRoad != null) {
                if (updateCache) {
                  goodRoads.add(goodRoad);
                  cache.add(feature);
                }
                updateDetails = await moveRouteMarker(
                    screenFence: screenFence,
                    route: goodRoad,
                    feature: feature,
                    visibleFeatures: markers,
                    cache: cache,
                    zoom: zoom);
              }
            }

          default:
            break;
        }
      }
    } else {
      debugPrint('filterFeatures had nothing to update');
    }
    updateDetails = updateDetails || _cards.length != markers.length;

    // debugPrint(
    //     '____ Left filterFeatures with updateDtails is $updateDetails and ${markers.length} markers _____');
    return updateDetails && markers.isNotEmpty;
  }

  /// filterFeatures
  ///   Objective is to keep two lists of features correctly populated
  ///   from a complete feature list based on the map position.
  ///   - The master list of all features fetched from the API or local db
  ///   - The cached subset of features - several screens worth
  ///   - The visible subset of features on the screen and in the grid
  ///
  ///
  ///   if the cacheFeatures is empty populates it from all features
  ///   that are bounded by the cache fence and populates the features
  ///   visible on screen
  ///
  ///   if map moves but the _screenFence is till within the _cacheFence
  ///   just repulates the visible features
  ///
  ///   if the map moves outside the cachedFence then redefines the
  ///   _cacheFence based on the _screenFence with a cache margin 0.5 degrees
  ///   It populated the cachedfeatures from the master list. It also
  ///   populated the visible features as the
  ///

  Future<LatLng?> routeMarkerPosition(
      {required List<Polyline> polylines, required Fence fence}) async {
    int first = -1;
    // int last = -1;
    Fence offsetFence = Fence.fromFence(bounds: fence, deltaDegrees: -0.025);
    Polyline? polyline;
    for (polyline in polylines) {
      for (int i = 0; i < polyline.points.length; i++) {
        if (offsetFence.containsPoint(point: polyline.points[i])) {
          first = first < 0 ? i : first;
          //   last = i;
        } else {
          if (first >= 0) {
            break;
          }
        }
      }
    }
    if (first >= 0) {
      return polyline!.points[first]; // + ((last - first) ~/ 2)];
    }
    return null;
  }

  /// Trying to speed up the search of long polylines
  /// Strategy is to start in the middle and search both towards
  /// the top and bottom of the list at the same time looking for
  /// points that are within the screen fence. If the upward search
  /// finds a valid point before the downward search it changes the lastPoint
  /// to that of the found point and the firstPoint to 0. If the downward
  /// search finds a valid point first it changes the firstPoint to the
  /// found point and the lastPoint to the points.length

  bool pointsSearch(
      {required Fence fence,
      required List<LatLng> points,
      required int firstPoint, // Middle point of list
      required int lastPoint, // Last point in list
      int jump = 1}) {
    int first = -1;
    int last = -1;
    int j;

    for (j = firstPoint; j < lastPoint; j += jump) {
      if (first == -1 &&
          (firstPoint - j) >= 0 &&
          fence.containsPoint(point: points[firstPoint - j])) {
        first = firstPoint - j;
        if (last == -1 && j > firstPoint) {
          lastPoint = first;
          firstPoint = 0;
          return false;
        }
      }
      if (last == -1 &&
          (firstPoint + j) < lastPoint &&
          fence.containsPoint(point: points[firstPoint + j])) {
        last = firstPoint + j;
        if (first == -1) {
          firstPoint = last;
          lastPoint = points.length;
          return false;
        }
      }
    }

    return last != -1 && first != -1;
  }

  Future<bool> addRouteMarker(
      {required List<mt.Route> routes,
      required Feature feature,
      required List<Feature> visibleFeatures,
      required Fence screenFence,
      zoom = 12}) async {
    LatLng? markerPoint =
        await routeMarkerPosition(polylines: routes, fence: screenFence);
    if (markerPoint != null && _screenFence.containsPoint(point: markerPoint)) {
      visibleFeatures.add(
        Feature.fromFeature(
          feature: feature,
          point: markerPoint,
          child: PinMarkerWidget(
            index: feature.row,
            color: feature.type == 0
                ? colourList[Setup().publishedTripColour]
                : colourList[Setup().goodRouteColour],
            width: (zoom * 2).toDouble(),
            overlay: Icons.route_outlined,
            onPress: pinTap,
          ),
        ),
      );
      LatLng firstPoint = routes[0].points[0];
      mt.Route lastRoute = routes[routes.length - 1];
      LatLng lastPoint = lastRoute.points[lastRoute.points.length - 1];
      if (_screenFence.containsPoint(point: firstPoint)) {
        visibleFeatures.add(
          Feature.fromFeature(
            feature: feature,
            point: firstPoint,
            child: EndMarkerWidget(
              index: feature.row,
              color: Colors.blueAccent,
              width: (zoom * 2).toDouble(),
              begining: true,
              onPress: pinTap,
            ),
          ),
        );
      }
      if (_screenFence.containsPoint(point: lastPoint)) {
        visibleFeatures.add(
          Feature.fromFeature(
            feature: feature,
            point: lastPoint,
            child: EndMarkerWidget(
              index: feature.row,
              color: Colors.blueAccent,
              width: (zoom * 2).toDouble(),
              begining: false,
              onPress: pinTap,
            ),
          ),
        );
      }

      return true;
    }
    return false;
  }

  Future<bool> moveRouteMarker(
      {required mt.Route route,
      required Feature feature,
      required List<Feature> cache,
      required List<Feature> visibleFeatures,
      required Fence screenFence,
      zoom = 12}) async {
    Feature start = feature;
    LatLng? markerPoint =
        await routeMarkerPosition(polylines: [route], fence: screenFence);
    if (markerPoint != null && _screenFence.containsPoint(point: markerPoint)) {
      for (Feature feature in cache) {
        if (feature.poiType == 13) {
          PointOfInterest? goodRoadStart =
              await _pointOfInterestRepository.loadPointOfInterest(
                  key: feature.row,
                  id: feature.id,
                  uri: feature.uri); // Good road marker
          if (goodRoadStart != null) {
            if (route.pointOfInterestUri == goodRoadStart.url) {
              start = feature;
              break;
            }
          }
        }
      }

      visibleFeatures.add(
        Feature.fromFeature(
          feature: start,
          point: markerPoint,
          child: PinMarkerWidget(
            index: feature.row,
            color: feature.type == 0
                ? colourList[Setup().publishedTripColour]
                : colourList[Setup().goodRouteColour],
            width: (zoom * 2).toDouble(),
            overlay: Icons.route_outlined,
            onPress: pinTap,
          ),
        ),
      );
      return true;
    }
    return false;
  }

  checkMapEvent(var details) {
    if (details != null) {
      // debugPrint(
      //    'Map event: ${details.toString()} zoom: ${_animatedMapController.mapController.camera.zoom}');
      setState(() {
        if (_showDetails !=
            _animatedMapController.mapController.camera.zoom > 12) {
          _showDetails = _animatedMapController.mapController.camera.zoom > 12;
          // debugPrint('_showDetails has changed: $_showDetails');
        }
      });
    }
  }

  Future<Directory> getCache() async {
    String appDocumentDirectory =
        (await getApplicationDocumentsDirectory()).path;
    Directory cacheDirectory = Directory('$appDocumentDirectory/cache');
    if (!await cacheDirectory.exists()) {
      await Directory('$appDocumentDirectory/cache').create();
    }
    return cacheDirectory;
  }

  void getCards(
      {required List<Feature> features, List<Card> cards = const []}) async {
    await _dataLoaded == true;

    if (features.isNotEmpty && _mapReady) {
      // int i = 0;
      cards.clear();
      // debugPrint('Line 539 clearing cards');
      // https://stackoverflow.com/questions/54150583/concurrent-modification-during-iteration-while-trying-to-remove-object-from-a-li
      // globals.filteredPollsList = List.from(pollsList);
      debugPrint('**** populating cards with ${features.length} features');
      for (int i = 0; i < features.length; i++) {
        //    debugPrint(
        //        '****** calling getCard() feature.row:${features[i].row} feature.type:${features[i].type}, feature.uri ${features[i].uri}');
        Card? newCard = await getCard(feature: features[i], index: i);
        if (newCard != null) {
          cards.add(newCard);
        }
      }

      //    for (Feature feature in features) {
      //      Card? newCard = await getCard(feature: feature, index: i);
      //      if (newCard != null) {
      //        cards.add(newCard);
      //        i++;
      //      }
      //    }
    } else {
      // debugPrint('Using existing cards - refresh not needed');
    }
    debugPrint('Cards.length = ${cards.length}');
    return;
  }
/*
  bool refreshCards(
      {required List<Feature> features, required List<Card> cards}) {
    final bool refresh = cards.isEmpty ||
        cards[0].key != Key('pin_${features[0].row}') ||
        cards[cards.length - 1].key !=
            Key('pin_${features[features.length - 1].row}');
    return refresh;
  }
*/
  //Widget

  testFunc(var details) {
    // debugPrint('testFunc');
    return null;
  }

  Future<Card?> getCard({required Feature feature, required int index}) async {
    // debugPrint('getCard called for index $index');
    /// getFeatures returns all the features from the API
    /// type 1: drives - id + max/min lat/lng
    /// type 2: points of interest excluding type 12 ad 16 drive start end (12) and followers (16)
    ///         type 3 is the automatically inserted point of imterest
    ///         when a good road is tarted.
    /// type 3: good roads - id + max/min lat/lng
    ///
    /// good_roads.point_of_interest_id ties the point of interest
    /// to the good_roads polylines(mt.route)

    if (feature.type == 0) {
      TripItem tripItem = await _tripItemRepository.loadTripItem(
          key: feature.row, id: feature.id, uri: feature.uri);
      debugPrint('getting trip data ${feature.uri} name ${tripItem.heading}');
      return Card(
        key: Key('pin_${feature.row}'),
        elevation: 10,
        shadowColor: Colors.grey.withOpacity(0.5),
        color: index.isOdd
            ? Colors.white
            : const Color.fromARGB(255, 174, 211, 241),
        child: TripTile(
          tripItem: tripItem,
          expandNotifier: _expandNotifier,
          imageRepository: _imageRepository,
          index: index,
          onGetTrip: onGetTrip,
          onRatingChanged: onTripRatingChanged,
        ),
      );
    } else if (feature.type == 1 || feature.type == 6 || feature.type == 3) {
      PointOfInterest? pointOfInterest =
          await _pointOfInterestRepository.loadPointOfInterest(
              key: feature.row, id: feature.id, uri: feature.uri);
      // pointOfInterest?.setName('$index. ${pointOfInterest.getName()}');
      return Card(
        key: Key('pin_${feature.row}'),
        elevation: 10,
        shadowColor: Colors.grey.withOpacity(0.5),
        color: index.isOdd
            ? Colors.white
            : const Color.fromARGB(255, 174, 211, 241),
        child: PointOfInterestTile(
          expandNotifier: _expandNotifier,
          controller: _pointOfInterestController,
          index: index,
          pointOfInterest: pointOfInterest!,
          imageRepository: _imageRepository,
          onExpandChange: expandChange, //testFunc,
          onIconTap: testFunc,
          onDelete: testFunc,
          onRated: testFunc,
          canEdit: false,
        ),
      );
    } else {
      // debugPrint('Type 12 PointOfInterest ignored');
    }
    return null;
  }

  adjustMapHeight(MapHeight newHeight) {
    if (mapHeights[1] == 0) {
      mapHeights[0] = MediaQuery.of(context).size.height - 190; // info closed
      mapHeights[1] = mapHeights[0] - 200; // heading data
      mapHeights[2] = mapHeights[0] - 400; // open point of interest
      mapHeights[3] = mapHeights[0] - 300; // message
    }
    mapHeight = mapHeights[MapHeight.values.indexOf(newHeight)];
    listHeight = (mapHeights[0] - mapHeight);
    _resizeDelay = 400;
  }

  expandChange(var details) {
    if (details != null) {
      setState(
        () {
          // debugPrint('ExpandChanged: $details');
          //    _editPointOfInterest = details;
          if (details >= 0) {
            adjustMapHeight(MapHeight.pointOfInterest);
          } else {
            FocusManager.instance.primaryFocus?.unfocus(); // dismiss keyboard
            adjustMapHeight(MapHeight.full);
          }
        },
      );
    }
  }

  _handleBottomSheetDivider() {
    _resizeDelay = 0;
    if (listHeight == -1) {
      adjustMapHeight(MapHeight.full);
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: AbsorbPointer(
        child: Container(
          color: const Color.fromARGB(255, 158, 158, 158),
          height: _dividerHeight,
          width: MediaQuery.of(context).size.width,
          child: Icon(
            Icons.drag_handle,
            size: _dividerHeight,
            color: Colors.blue,
          ),
        ),
      ),
      onTap: () => setState(() => adjustMapHeight(mapHeight > mapHeights[0] - 50
          ? MapHeight.pointOfInterest
          : MapHeight.full)),
      onVerticalDragUpdate: (DragUpdateDetails details) {
        setState(() {
          if (mapHeights[0] == 0) {
            mapHeights[0] = MediaQuery.of(context).size.height - 190;
          }
          mapHeight += details.delta.dy;
          mapHeight = mapHeight > mapHeights[0] ? mapHeights[0] : mapHeight;
          mapHeight = mapHeight < 1 ? 1 : mapHeight;
          listHeight = mapHeights[0] - mapHeight;
        });
      },
    );
  }

  double getMapHeight(MapHeight height) {
    return mapHeights[MapHeight.values.indexOf(height)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: LeadingWidget(
          controller: _leadingWidgetController,
          onMenuTap: (index) => _leadingWidget(_scaffoldKey.currentState),
        ), // IconButton(
        title: Text(
          tripItems.isNotEmpty && tripItems[0].uri.contains('http')
              ? 'Trips available to download'
              : 'To share trips register for free',
          style: const TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),

        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list), //more_vert),
            onPressed: () =>
                setState(() => _showPreferences = !_showPreferences),
          ),
        ],
        bottom: (_showPreferences)
            ? PreferredSize(
                preferredSize: const ui.Size.fromHeight(60),
                child: AnimatedContainer(
                  height: 60,
                  curve: Curves.easeInOut,
                  duration: const Duration(seconds: 3),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    child: setPreferences(),
                  ),
                ),
              )
            : null,
      ),
      body: FutureBuilder<Widget>(
        future: _getPortraitBody(), //_dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            // debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            // _building = false;
            return snapshot.data!;
          } else {
            return const SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            );
          }
          throw ('Error - FutureBuilder line 554 in trips.dart');
        },
      ),
      floatingActionButton: _handleFabs(),
      bottomNavigationBar: RoutesBottomNav(
        controller: _bottomNavController,
        initialValue: 1,
        onMenuTap: (_) => {},
      ),
    );
  }

  Column _handleFabs() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(
          height: 175,
        ),
        FloatingActionButton(
          heroTag: 'location',
          onPressed: () async {
            Position currentPosition = await Geolocator.getCurrentPosition();
            debugPrint('Position: ${currentPosition.toString()}');
            _animatedMapController.animateTo(
              dest: LatLng(currentPosition.latitude, currentPosition.longitude),
            );
            //  setState(() {});
          },
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(
          height: 15,
        ),
        FloatingActionButton(
          heroTag: 'zoomIn',
          onPressed: () async {
            Position currentPosition = await Geolocator.getCurrentPosition();
            debugPrint('Position: ${currentPosition.toString()}');
            _animatedMapController.animatedZoomIn(curve: Curves.ease);

            // setState(() {});
          },
          backgroundColor: Colors.blue, //.withOpacity(0.5),
          shape: const CircleBorder(),
          child: const Icon(Icons.zoom_in, size: 30),
        ),
        const SizedBox(
          height: 15,
        ),
        FloatingActionButton(
          heroTag: 'zoomOut',
          onPressed: () async {
            Position currentPosition = await Geolocator.getCurrentPosition();
            debugPrint('Position: ${currentPosition.toString()}');
            _animatedMapController.animatedZoomOut(curve: Curves.ease);

            // setState(() {});
          },
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
          child: const Icon(Icons.zoom_out, size: 30),
        ),
      ],
    );
  }

  Widget setPreferences() {
    return SizedBox(
      height: 20,
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          //  if (!_preferences.isLeft) ...[
          Icon(_preferences.isLeft ? null : Icons.arrow_back_ios,
              color: Colors.white),
          //  ],
          SizedBox(
            width: MediaQuery.of(context).size.width - 60, //delta,
            child: ListView(
              scrollDirection: Axis.horizontal,
              controller: _preferencesScrollController,
              children: <Widget>[
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    checkColor: Colors.white,
                    title: const Text('Current location',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.currentLocation,
                    onChanged: (value) =>
                        setState(() => _preferences.currentLocation = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    //  activeColor: Colors.white,
                    hoverColor: Colors.white,
                    title: const Text('North West',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.northWest,
                    onChanged: (value) =>
                        setState(() => _preferences.northWest = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    title: const Text('North East',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.northEast,
                    onChanged: (value) =>
                        setState(() => _preferences.northEast = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    //  activeColor: Colors.white,
                    hoverColor: Colors.white,
                    title: const Text('South West',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.southWest,
                    onChanged: (value) =>
                        setState(() => _preferences.southWest = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    title: const Text('South East',
                        style: TextStyle(color: Colors.white)),
                    value: _preferences.southEast,
                    onChanged: (value) =>
                        setState(() => _preferences.southEast = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),
          //  if (!_preferences.isRight) ...[
          Icon(
            _preferences.isRight ? null : Icons.arrow_forward_ios,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
