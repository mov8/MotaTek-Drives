// import 'package:drives/constants.dart';
// import 'package:drives/constants.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:path/path.dart' hide Style;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/models.dart';
import 'package:drives/tiles/tiles.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:drives/services/services.dart'; // hide getPosition;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/constants.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';

/// Improving performance -
/// Use classes not functions
/// Use Keys
/// use devtools Perfomance view
/// enable the Track layouts option in DevTools
/// https://docs.flutter.dev/perf/impeller
/// https://www.google.com/search?client=firefox-b-d&q=flutter+devtools+vscode#fpstate=ive&vld=cid:48f0e919,vid:_EYk-E29edo,st:0
/// https://docs.flutter.dev/perf/best-practices
/// https://docs.flutter.dev/perf/rendering-performance
/// https://medium.com/flutterdude/flutter-performance-series-building-an-efficient-widget-tree-84fd236e9868

enum MapHeight {
  full,
  headers,
  pointOfInterest,
  message,
  variable,
  togglePointOfInterest,
  toggleMessage,
}

enum MapHeightChangeType { heights, toggle, fromDrag }

List<double> mapHeights = [0, 0, 0, 0];

class Trips extends StatefulWidget {
  const Trips({
    super.key,
  });

  @override
  State<Trips> createState() => _TripsState();
}

class _TripsState extends State<Trips> with TickerProviderStateMixin {
  late final LeadingWidgetController _leadingWidgetController;
  final GlobalKey _scaffoldKey = GlobalKey();
  bool _showPreferences = false;
  final List<TripItem> tripItems = [];
  final TripsPreferences _preferences = TripsPreferences();
  late final RoutesBottomNavController _bottomNavController;

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
  }

  @override
  void dispose() {
    //   _animatedMapController.dispose();
    //   _mapController.dispose();
    super.dispose();
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  double getInitialZoom() {
    return 8;
  }

  routeTapped(routes, details) {
    if (details != null) {}
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
                    child: SetPreferences(
                      preferences: _preferences,
                    ), //setPreferences(),
                  ),
                ),
              )
            : null,
      ),
      body: PortraitBody(),
      //   floatingActionButton: Fabs(),
      //     animatedMapController: _animatedMapController), // _handleFabs(),
      bottomNavigationBar: RoutesBottomNav(
        controller: _bottomNavController,
        initialValue: 1,
        onMenuTap: (_) => {},
      ),
    );
  }
/*
  Future<List<TripItem>> getTripsToShow() async {
    try {
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
*/

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

  /// Trying to speed up the search of long polylines
  /// Strategy is to start in the middle and search both towards
  /// the top and bottom of the list at the same time looking for
  /// points that are within the screen fence. If the upward search
  /// finds a valid point before the downward search it changes the lastPoint
  /// to that of the found point and the firstPoint to 0. If the downward
  /// search finds a valid point first it changes the firstPoint to the
  /// found point and the lastPoint to the points.length
}

class Fabs extends StatelessWidget {
  final AnimatedMapController animatedMapController;
  const Fabs({super.key, required this.animatedMapController});

  @override
  Widget build(BuildContext context) {
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
            animatedMapController.animateTo(
              dest: LatLng(currentPosition.latitude, currentPosition.longitude),
            );
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
            animatedMapController.animatedZoomIn();
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
            animatedMapController.animatedZoomOut();
          },
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
          child: const Icon(Icons.zoom_out, size: 30),
        ),
      ],
    );
  }
}

class SetPreferences extends StatefulWidget {
  final TripsPreferences preferences;

  const SetPreferences({
    super.key,
    required this.preferences,
  });

  @override
  State<SetPreferences> createState() => _SetPreferencesState();
}

class _SetPreferencesState extends State<SetPreferences> {
  late final ScrollController _scrollController;
  @override
  initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(
      () {
        if (_scrollController.position.atEdge) {
          bool isTop = _scrollController.position.pixels == 0;
          if (isTop) {
            setState(() {
              widget.preferences.isRight = true;
              widget.preferences.isLeft = false;
            });
          } else {
            setState(() {
              widget.preferences.isLeft = true;
              widget.preferences.isRight = false;
            });
          }
        } else if (widget.preferences.isRight || widget.preferences.isLeft) {
          setState(() {
            widget.preferences.isLeft = false;
            widget.preferences.isRight = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          //  if (!_preferences.isLeft) ...[
          Icon(widget.preferences.isLeft ? null : Icons.arrow_back_ios,
              color: Colors.white),
          //  ],
          SizedBox(
            width: MediaQuery.of(context).size.width - 60, //delta,
            child: ListView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              children: <Widget>[
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    checkColor: Colors.white,
                    title: const Text('Current location',
                        style: TextStyle(color: Colors.white)),
                    value: widget.preferences.currentLocation,
                    onChanged: (value) =>
                        widget.preferences.currentLocation = value!,
                    // setState(() => preferences.currentLocation = value!),
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
                    value: widget.preferences.northWest,
                    onChanged: (value) => widget.preferences.northWest = value!,
                    //   setState(() => _preferences.northWest = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    title: const Text('North East',
                        style: TextStyle(color: Colors.white)),
                    value: widget.preferences.northEast,
                    onChanged: (value) => widget.preferences.northEast = value!,
                    // setState(() => _preferences.northEast = value!),
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
                    value: widget.preferences.southWest,
                    onChanged: (value) => widget.preferences.southWest = value!,
                    //  setState(() => _preferences.southWest = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    title: const Text('South East',
                        style: TextStyle(color: Colors.white)),
                    value: widget.preferences.southEast,
                    onChanged: (value) => widget.preferences.southEast = value!,
                    //   setState(() => _preferences.southEast = value!),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),
          //  if (!_preferences.isRight) ...[
          Icon(
            widget.preferences.isRight ? null : Icons.arrow_forward_ios,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// PortraitBody has three main children
/// TripsMap
/// Divider
/// Details
///

class PortraitBody extends StatefulWidget {
  const PortraitBody({
    super.key,
  });
  @override
  State<PortraitBody> createState() => _PortraitBody();
}

class _PortraitBody extends State<PortraitBody> with TickerProviderStateMixin {
  late final TripItemRepository _tripItemRepository;
  late final PointOfInterestRepository _pointOfInterestRepository;
  late final GoodRoadRepository _goodRoadRepository;
  late final RouteRepository _routeRepository;
  late final ImageRepository _imageRepository;

  final double listHeight = 0;
  final List<mt.Route> _routes = [];
  final List<mt.Route> _goodRoads = [];
  final List<Card> _cards = [];
  late final MapInfo _mapInfo;
  late final FeatureDetailsController _featuresController;
  late final TripMapController _tripMapController;
  final List<Feature> _features = [];
  late Future<bool> _dataLoaded;
  double _mapHeight = 130;
  @override
  late BuildContext context;

  int _resizeDelay = 0;

  @override
  void initState() {
    super.initState();
    _featuresController = FeatureDetailsController();
    _tripMapController = TripMapController();
    _mapInfo = MapInfo.create();
    _dataLoaded = _getTripData(features: _features);
    _tripItemRepository = TripItemRepository();
    _pointOfInterestRepository = PointOfInterestRepository();
    _goodRoadRepository = GoodRoadRepository();
    _routeRepository = RouteRepository();
    _imageRepository = ImageRepository();
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

      _features.addAll(await getFeatures(zoom: 10, onTap: pinTap));
      return true;
    } catch (e) {
      debugPrint('Error getting features: ${e.toString()}');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: _resizeDelay),
                  curve: Curves.easeInOut, // fastOutSlowIn,
                  height: 163, // widget.mapHeight,
                  width: MediaQuery.of(context).size.width,
                  child: TripsMap(
                    key: UniqueKey(),
                    height: 613, //mapHeight,
                    controller: _tripMapController,
                    initialZoom: 6.5,
                    features: _features,
                    routes: _routes,
                    goodRoads: _goodRoads,
                    onChange: (_) => {}, //widget.onMapChange,
                    // style: style,
                  ), // _handleMap(),
                ),
                BottomSheetDivider(
                    height: listHeight, onChange: onDividerChange),
                const SizedBox(
                  height: 5,
                ),
                SizedBox(
                  height: listHeight,
                  child: FeatureDetails(
                    key: UniqueKey(),
                    controller: _featuresController,
                    pointOfInterestRepository: _pointOfInterestRepository,
                    tripItemsRepository: _tripItemRepository,
                    imageRepository: _imageRepository,
                    features: _features,
                    mapInfo: _mapInfo,
                    dataLoaded: _dataLoaded,
                    expandChange: expandChange,
                  ),
                ),
              ],
            );
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
          throw ('Error - FutureBuilder in trips.dart');
        },
      ),
    );
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

  onDividerChange(height, tapped) {
    if (_mapInfo.ready == true) {
      setState(() {
        if (tapped) {
          adjustMapHeight(MapHeight.togglePointOfInterest);
        } else {
          adjustMapHeight(MapHeight.variable, listDelta: height);
        }
      });
      debugPrint(
          'listHeight: $listHeight, mapHeight: $_mapHeight, tapped: $tapped');
    }
  }

  adjustMapHeight(MapHeight newHeight, {double listDelta = 0}) {
    if (mapHeights[1] == 0) {
      mapHeights[0] = MediaQuery.of(context).size.height - 190; // info closed
      mapHeights[1] = mapHeights[0] - 200; // heading data
      mapHeights[2] = mapHeights[0] - 400; // open point of interest
      mapHeights[3] = mapHeights[0] - 300; // message
    }
    if (newHeight == MapHeight.togglePointOfInterest) {
      _mapHeight =
          _mapHeight > mapHeights[0] - 50 ? mapHeights[2] : mapHeights[0];
    } else if (newHeight == MapHeight.toggleMessage) {
      _mapHeight =
          _mapHeight > mapHeights[0] - 50 ? mapHeights[3] : mapHeights[0];
    } else if (newHeight == MapHeight.variable) {
      // (detailHeight >= 0) {
      _mapHeight += listDelta;
    } else {
      _mapHeight = mapHeights[MapHeight.values.indexOf(newHeight)];
    }
    _mapHeight = _mapHeight > mapHeights[0] ? mapHeights[0] : _mapHeight;
    _mapHeight = _mapHeight < 0 ? 0 : _mapHeight;
    _resizeDelay = newHeight == MapHeight.variable ? 0 : 500;
  }

  pinTap(int index) async {
    Map<String, dynamic> infoMap = await getDialogData(
        features: _features, index: index); //.then((infoMap){}
    Key cardKey = Key('pin_${infoMap['key']}');
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
                  _featuresController.updateDetails(idx);
                },
                //       () => {// debugPrint('callback - Cancel')}
              ],
              ['Details', 'Cancel'],
            ),
          );
        },
      );
    }
  }

  Future<bool> filterFeatures(
      {required List<Feature> source,
      required List<Feature> cache,
      required List<Feature> markers,
      required Fence screenFence,
      required Fence cacheFence,
      List<mt.Route> routes = const [],
      List<mt.Route> goodRoads = const [],
      double zoom = 12}) async {
    if (source.isEmpty) {
      return false;
    }

    if (zoom < 20) return false;

    if (zoom > 10) {
      debugPrint('Zoom: $zoom');
    }

    bool updateCache =
        cache.isEmpty || !cacheFence.contains(bounds: screenFence);

    if (cache.isEmpty) {
      debugPrint('Filling cache list - cache is empty');
    } else {
      if (!cacheFence.contains(bounds: screenFence)) {
        debugPrint('Refreshing cache - _screenFence outside _cacheFence');
      }
    }

    bool updateDetails = true;
    //zoom > 11;
    //false;

    List<Feature> listToFilter = cache;
    if (updateCache) {
      cache.clear();
      routes.clear();
      //   markers.clear();
      goodRoads.clear();
      cacheFence.setBounds(bounds: screenFence, deltaDegrees: 0.5);
      updateDetails = true;
      listToFilter = source;
    } else if (markers.isEmpty) {
      updateDetails = true;
    } else if (zoom > 11) {
      for (Feature feature in markers) {
        if (!screenFence.contains(bounds: feature.getBounds())) {
          debugPrint('Feature ${feature.row}has left the _screenFence');
          updateDetails = true;
          break;
        }
      }
      updateDetails = true;
    }
    if (updateDetails) {
      markers.clear();
      for (Feature feature in listToFilter) {
        switch (feature.type) {
          case 0:
            if (cacheFence.overlapped(bounds: feature.getBounds())) {
              List<mt.Route>? toAdd = await _routeRepository.loadRoute(
                  key: feature.row, id: feature.id, uri: feature.uri);
              if (toAdd != null) {
                if (updateCache) {
                  routes.addAll(toAdd);
                  cache.add(feature);
                }
                if (zoom > 10) {
                  updateDetails = await addRouteMarker(
                      screenFence: screenFence,
                      routes: toAdd,
                      feature: feature,
                      visibleFeatures: markers,
                      score: 1,
                      zoom: zoom);
                }
              }
              debugPrint(
                  'markers.length = ${markers.length} adding feature.${feature.row}');
            }
            break;
          case 1:
            if ((![12, 14, 16].contains(feature.poiType) &&
                    cacheFence.contains(
                      bounds: feature.getBounds(),
                    )) &&
                zoom > 10 &&
                updateCache) {
              if ([17, 18].contains(feature.poiType) &&
                  feature.child.runtimeType != EndMarkerWidget) {
                feature = Feature.fromFeature(
                    feature: feature,
                    child: EndMarkerWidget(
                      index: feature.row,
                      begining: feature.poiType == 17,
                      width: 25,
                      color: Colors.white60,
                      onPress: pinTap,
                    ));
              } else if (feature.child.runtimeType != PinMarkerWidget) {
                PointOfInterest? pointOfInterest =
                    await _pointOfInterestRepository.loadPointOfInterest(
                        key: feature.row, id: feature.id, uri: feature.uri);
                feature = Feature.fromFeature(
                    feature: feature,
                    child: PinMarkerWidget(
                      index: feature.row,
                      color: feature.poiType == 13
                          ? colourList[Setup().goodRouteColour]
                          : colourList[Setup().pointOfInterestColour],
                      width: zoom * 2,
                      overlay:
                          markerIcon(getIconIndex(iconIndex: feature.poiType)),
                      onPress: pinTap,
                      rating: pointOfInterest!.getScore(),
                    ));
              }
              cache.add(feature);
            }

            if (screenFence.contains(bounds: feature.getBounds())) {
              markers.add(feature);
              updateDetails = true;
            }
            break;
          case 2:
            if (cacheFence.overlapped(bounds: feature.getBounds())) {
              mt.Route? goodRoad = await _goodRoadRepository.loadGoodRoad(
                  key: feature.row, id: feature.id, uri: feature.uri);
              if (goodRoad != null) {
                if (updateCache) {
                  goodRoads.add(goodRoad);
                  cache.add(feature);
                }
                if (zoom > 10) {
                  updateDetails = await moveRouteMarker(
                    screenFence: screenFence,
                    route: goodRoad,
                    feature: feature,
                    visibleFeatures: markers,
                    cache: cache,
                    zoom: zoom,
                  );
                }
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

    return updateDetails && markers.isNotEmpty;
  }

  Future<bool> addRouteMarker(
      {required List<mt.Route> routes,
      required Feature feature,
      required List<Feature> visibleFeatures,
      required Fence screenFence,
      double score = 1,
      zoom = 12}) async {
    LatLng? markerPoint =
        await routeMarkerPosition(polylines: routes, fence: screenFence);
    if (markerPoint != null && screenFence.containsPoint(point: markerPoint)) {
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
            rating: routes[0].rating.toDouble(),
          ),
        ),
      );
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
    if (screenFence.containsPoint(point: markerPoint!)) {
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
        TripItem tripItem = await _tripItemRepository.loadTripItem(
          key: features[index].row,
          id: features[index].id,
          uri: features[index].uri,
        );
        mapInfo = {
          'key': features[index].row,
          'title': tripItem.heading,
          'content': tripItem.body,
          'images': tripItem.imageUrls,
        };
        break;
      case 1:
        PointOfInterest? pointOfInterest =
            await _pointOfInterestRepository.loadPointOfInterest(
                key: features[index].row,
                id: features[index].id,
                uri: features[index].uri);
        if (pointOfInterest != null) {
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
}

class MapInfo {
  final bool ready;
  final Fence fence;
  final double zoom;
  final double height;
  const MapInfo(
      {required this.fence,
      required this.zoom,
      required this.height,
      this.ready = false});
  MapInfo.create({
    this.ready = false,
    this.zoom = 10,
    this.height = 130,
  }) : fence = Fence.create();
}
/*
class LeadingWidgetController {
  _LeadingWidgetState? _leadingWidgetState;

  void _addState(_LeadingWidgetState leadingWidgetState) {
    _leadingWidgetState = leadingWidgetState;
  }

  bool get isAttached => _leadingWidgetState != null;

  void changeWidget(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _leadingWidgetState?.changeWidget(id);
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}
*/

class TripMapController {
  _TripsMapState? _tripMapState;
  void _addState(_TripsMapState tripMapState) {
    _tripMapState = tripMapState;
  }

  bool get isAttached => _tripMapState != null;

  void updateMap(MapInfo mapInfo) {
    assert(isAttached, 'Controller must be attached');
    try {
      _tripMapState?.update(mapInfo);
    } catch (e) {
      debugPrint('Error changing map: ${e.toString()}');
    }
  }
}

class TripsMap extends StatefulWidget {
  final TripMapController controller;
  final Function(MapInfo) onChange;
  final List<Feature> features;
  final List<mt.Route> routes;
  final List<mt.Route> goodRoads;
  final double height;
  final double initialZoom;
  const TripsMap({
    super.key,
    required this.controller,
    required this.features,
    required this.routes,
    required this.goodRoads,
    required this.onChange,
    required this.height,
    required this.initialZoom,
  });
  @override
  State<TripsMap> createState() => _TripsMapState();
}

class _TripsMapState extends State<TripsMap> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedController;
  late Future<Style> style;

  @override
  void initState() {
    super.initState();
    _animatedController = AnimatedMapController(vsync: this);
    widget.controller._addState(this);
    style = getMapStyle();
  }

  update(MapInfo mapInfo) {}

  Future<Style> getMapStyle() async {
    final StyleReader styleReader = StyleReader(
        uri:
            'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key={key}',
        apiKey: stadiaMapsApiKey,
        logger: null);
    Style style = await styleReader.read();
    return style;
  }

  MapInfo setMapInfo({ready = false, height = 0}) {
    return MapInfo(
      fence: Fence.fromBounds(
          _animatedController.mapController.camera.visibleBounds),
      zoom: _animatedController.mapController.camera.zoom,
      ready: ready,
      height: height,
    );
  }

  checkMapEvent(var details) {
    if (details != null) {
      debugPrint('Map event: ${details.toString()}');
      //   if
      //   setMapInfo(ready: widget.mapInfo.ready,  )
    }
  }

  /// Get VectorMapTiles cache folder
  Future<Directory> getCache() async {
    String appDocumentDirectory =
        (await getApplicationDocumentsDirectory()).path;
    Directory cacheDirectory = Directory('$appDocumentDirectory/cache');
    if (!await cacheDirectory.exists()) {
      await Directory('$appDocumentDirectory/cache').create();
    }
    return cacheDirectory;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: FutureBuilder<Style>(
        future: style,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            throw ('map build error - ${snapshot.error.toString()}');
            // return const Text('Error');
          } else if (snapshot.hasData) {
            return Stack(children: [
              FlutterMap(
                mapController: _animatedController.mapController,
                options: MapOptions(
                  onMapEvent: checkMapEvent,
                  onMapReady: () async {
                    widget.onChange(
                        setMapInfo(ready: true, height: widget.height));
                  },
                  onPositionChanged: (pos, change) async {
                    widget.onChange(
                        setMapInfo(ready: true, height: widget.height));
                  },
                  initialCenter: LatLng(Setup().lastPosition.latitude,
                      Setup().lastPosition.longitude),
                  initialZoom: widget.initialZoom, // getInitialZoom(),
                  maxZoom: 18,
                  minZoom: 5,
                  interactionOptions: const InteractionOptions(
                      enableMultiFingerGestureRace: true,
                      flags: InteractiveFlag.doubleTapDragZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.pinchMove),
                ),
                children: [
                  CachedVectorTileLayer(
                    theme: snapshot.data!.theme,
                    sprites: snapshot.data!.sprites,
                    //          tileProviders:
                    //              TileProviders({'openmaptiles': _tileProvider()}),
                    tileProviders: snapshot.data!.providers,
                    layerMode: VectorTileLayerMode.vector,
                    tileOffset: TileOffset.DEFAULT,
                    cacheFolder: getCache,
                  ),
                  PolylineLayer(polylines: widget.routes),
                  PolylineLayer(polylines: widget.goodRoads),
                  MarkerLayer(
                    markers: widget.features,
                    alignment: Alignment.topCenter,
                  ),
                ],
              ),
              MapLegend(key: UniqueKey(), bottom: 0, left: 0),
            ]);
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
        },
      ),
    );
  }
}

class MapLegend extends StatelessWidget {
  final double bottom;
  final double left;
  const MapLegend({super.key, this.bottom = 0, this.left = 0});
  @override
  Widget build(BuildContext context) {
    return Positioned(
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
    );
  }
}

/// FeatureDetails handles the display of the cards
/// handing it Cards rather than Features allows the
/// Cards to be defined by a parent
///

class FeatureDetailsController {
  _FeatureDetailsState? _featureDetailsState;

  void _addState(_FeatureDetailsState leadingWidgetState) {
    _featureDetailsState = leadingWidgetState;
  }

  bool get isAttached => _featureDetailsState != null;

  void updateDetails(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _featureDetailsState?.updateDetails(id);
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}

class FeatureDetails extends StatefulWidget {
  final List<Feature> features;
  final FeatureDetailsController controller;
  final TripItemRepository tripItemsRepository;
  final PointOfInterestRepository pointOfInterestRepository;
  final ImageRepository imageRepository;
  final MapInfo mapInfo;
  final Future<bool> dataLoaded;
  final Function(int) expandChange;
  const FeatureDetails({
    super.key,
    required this.features,
    required this.controller,
    required this.tripItemsRepository,
    required this.pointOfInterestRepository,
    required this.imageRepository,
    required this.mapInfo,
    required this.dataLoaded,
    required this.expandChange,
  });
  @override
  State<FeatureDetails> createState() => _FeatureDetailsState();
}

class _FeatureDetailsState extends State<FeatureDetails> {
  late final PointOfInterestController _pointOfInterestController;
  late final ItemScrollController _scrollController;
  late final ScrollOffsetController _offsetController;
  late final ItemPositionsListener _positionsListener;
  late final ExpandNotifier _expandNotifier;
  late Future<bool> _cardsReady;

  final List<Card> _cards = [];

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    _pointOfInterestController = PointOfInterestController();
    _scrollController = ItemScrollController();
    _offsetController = ScrollOffsetController();
    _expandNotifier = ExpandNotifier(-1);
    _positionsListener = ItemPositionsListener.create();
    _cardsReady = getCards(features: widget.features);
  }

  void updateDetails(int id) async {
    _scrollController.jumpTo(index: id);
    await Future.delayed(const Duration(milliseconds: 200));
    _expandNotifier.targetValue(target: id);
    await Future.delayed(const Duration(milliseconds: 200));
    _scrollController.scrollTo(
        index: id,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic);

    _expandNotifier.notifyListeners();
  }

  Future<bool> getCards(
      {required List<Feature> features, List<Card> cards = const []}) async {
    await widget.dataLoaded == true;

    if (features.isNotEmpty && widget.mapInfo.ready) {
      cards.clear();
      debugPrint('**** populating cards with ${features.length} features');
      for (int i = 0; i < features.length; i++) {
        debugPrint(
            '****** calling getCard() feature.row:${features[i].row} feature.type:${features[i].type}, feature.uri ${features[i].uri}');
        Card? newCard = await getCard(feature: features[i], index: i);
        if (newCard != null) {
          cards.add(newCard);
        }
      }
    } else {
      // debugPrint('Using existing cards - refresh not needed');
    }
    debugPrint('Cards.length = ${cards.length}');
    return true;
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
      TripItem tripItem = await widget.tripItemsRepository
          .loadTripItem(key: feature.row, id: feature.id, uri: feature.uri);
      debugPrint('getting trip data ${feature.uri} name ${tripItem.heading}');
      return Card(
        key: Key('pin_${feature.row}'),
        elevation: 10,
        shadowColor: Colors.grey.withValues(alpha: 125),
        color: index.isOdd
            ? Colors.white
            : const Color.fromARGB(255, 174, 211, 241),
        child: TripTile(
          tripItem: tripItem,
          expandNotifier: _expandNotifier,
          imageRepository: widget.imageRepository,
          index: index,
          onGetTrip: onGetTrip,
          onRatingChanged: onTripRatingChanged,
        ),
      );
    } else if (feature.type == 1 || feature.type == 6 || feature.type == 3) {
      PointOfInterest? pointOfInterest = await widget.pointOfInterestRepository
          .loadPointOfInterest(
              key: feature.row, id: feature.id, uri: feature.uri);
      // pointOfInterest?.setName('$index. ${pointOfInterest.getName()}');
      return Card(
        key: Key('pin_${feature.row}'),
        elevation: 10,
        shadowColor: Colors.grey.withValues(alpha: 0.5),
        color: index.isOdd
            ? Colors.white
            : const Color.fromARGB(255, 174, 211, 241),
        child: PointOfInterestTile(
          expandNotifier: _expandNotifier,
          controller: _pointOfInterestController,
          index: index,
          pointOfInterest: pointOfInterest!,
          imageRepository: widget.imageRepository,
          onExpandChange: widget.expandChange, //testFunc,
          onIconTap: testFunc,
          onDelete: testFunc,
          onRated: onPointOfInterestRatingChanged,
          canEdit: false,
        ),
      );
    } else {
      // debugPrint('Type 12 PointOfInterest ignored');
    }
    return null;
  }

  onPointOfInterestRatingChanged(int value, int index) {
    // key.toString() => "[<'pin_12'>]"
    int row = int.parse(_cards[index]
        .key
        .toString()
        .substring(7, _cards[index].key.toString().length - 3));
    String uri = widget.features[row].uri;
    putPointOfInterestRating(uri, value.toDouble());
  }

  onTripRatingChanged(int value, int index) async {
    int row = int.parse(_cards[index]
        .key
        .toString()
        .substring(7, _cards[index].key.toString().length - 3));
    String uri = widget.features[row].uri;
    putDriveRating(uri, value);
  }

  Future<void> onGetTrip(int index) async {
    /*     
    MyTripItem webTrip = await getMyTrip(tripItems[index].driveUri);
    webTrip.setId(-1);
    webTrip.setDriveUri(tripItems[index].driveUri);
    if (context.mounted) {
      Navigator.pushNamed(context, 'createTrip',
          arguments: TripArguments(webTrip, 'web'));
    }
    */
  }

  testFunc(var details) {
    // debugPrint('testFunc');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    FutureBuilder(
      future: _cardsReady,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Snapshot error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return ScrollablePositionedList.builder(
            itemCount: _cards.length,
            itemBuilder: (context, index) =>
                _cards[index < _cards.length ? index : _cards.length - 1],
            itemScrollController: _scrollController,
            scrollOffsetController: _offsetController,
            itemPositionsListener: _positionsListener,
          );
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
        throw ('error creating details cards');
      },
    );
    throw ('error creating details cards');
  }
}

/// BottomSheetDivider is a stateful widget as it needs to call
/// serState(()=>{})

class BottomSheetDivider extends StatefulWidget {
  final Function(double, bool) onChange;
  final double height;
  const BottomSheetDivider(
      {super.key, required this.onChange, this.height = 35});
  @override
  State<BottomSheetDivider> createState() => _BottomSheetDividerState();
}

class _BottomSheetDividerState extends State<BottomSheetDivider> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // excludeFromSemantics: true,
      behavior: HitTestBehavior.translucent, //deferToChild, //translucent,
      onTap: () => setState(() => widget.onChange(widget.height, true)),
      onVerticalDragUpdate: (DragUpdateDetails details) =>
          setState(() => widget.onChange(details.delta.dy, false)),
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: const Color.fromARGB(255, 158, 158, 158),
          height: 35,
          width: MediaQuery.of(context).size.width,
          child: const Icon(
            Icons.drag_handle,
            size: 35,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}

/*
Future<bool> filterFeatures(
    {required List<Feature> source,
    required List<Feature> cache,
    required List<Feature> markers,
    required Fence screenFence,
    required Fence cacheFence,
    List<mt.Route> routes = const [],
    List<mt.Route> goodRoads = const [],
    double zoom = 12}) async {
  if (source.isEmpty) {
    return false;
  }

  if (zoom < 20) return false;

  if (zoom > 10) {
    debugPrint('Zoom: $zoom');
  }

  bool updateCache = cache.isEmpty || !cacheFence.contains(bounds: screenFence);

  if (cache.isEmpty) {
    debugPrint('Filling cache list - cache is empty');
  } else {
    if (!cacheFence.contains(bounds: screenFence)) {
      debugPrint('Refreshing cache - _screenFence outside _cacheFence');
    }
  }

  bool updateDetails = true;
  //zoom > 11;
  //false;

  List<Feature> listToFilter = cache;
  if (updateCache) {
    cache.clear();
    routes.clear();
    //   markers.clear();
    goodRoads.clear();
    cacheFence.setBounds(bounds: screenFence, deltaDegrees: 0.5);
    updateDetails = true;
    listToFilter = source;
  } else if (markers.isEmpty) {
    updateDetails = true;
  } else if (zoom > 11) {
    for (Feature feature in markers) {
      if (!screenFence.contains(bounds: feature.getBounds())) {
        debugPrint('Feature ${feature.row}has left the _screenFence');
        updateDetails = true;
        break;
      }
    }
    updateDetails = true;
  }
  if (updateDetails) {
    markers.clear();
    for (Feature feature in listToFilter) {
      switch (feature.type) {
        case 0:
          if (cacheFence.overlapped(bounds: feature.getBounds())) {
            List<mt.Route>? toAdd = await _routeRepository.loadRoute(
                key: feature.row, id: feature.id, uri: feature.uri);
            if (toAdd != null) {
              if (updateCache) {
                routes.addAll(toAdd);
                cache.add(feature);
              }
              if (zoom > 10) {
                updateDetails = await addRouteMarker(
                    screenFence: screenFence,
                    routes: toAdd,
                    feature: feature,
                    visibleFeatures: markers,
                    score: 1,
                    zoom: zoom);
              }
            }
            debugPrint(
                'markers.length = ${markers.length} adding feature.${feature.row}');
          }
          break;
        case 1:
          if ((![12, 14, 16].contains(feature.poiType) &&
                  cacheFence.contains(
                    bounds: feature.getBounds(),
                  )) &&
              zoom > 10 &&
              updateCache) {
            if ([17, 18].contains(feature.poiType) &&
                feature.child.runtimeType != EndMarkerWidget) {
              feature = Feature.fromFeature(
                  feature: feature,
                  child: EndMarkerWidget(
                    index: feature.row,
                    begining: feature.poiType == 17,
                    width: 25,
                    color: Colors.white60,
                    onPress: pinTap,
                  ));
            } else if (feature.child.runtimeType != PinMarkerWidget) {
              PointOfInterest? pointOfInterest =
                  await _pointOfInterestRepository.loadPointOfInterest(
                      key: feature.row, id: feature.id, uri: feature.uri);
              feature = Feature.fromFeature(
                  feature: feature,
                  child: PinMarkerWidget(
                    index: feature.row,
                    color: feature.poiType == 13
                        ? colourList[Setup().goodRouteColour]
                        : colourList[Setup().pointOfInterestColour],
                    width: zoom * 2,
                    overlay:
                        markerIcon(getIconIndex(iconIndex: feature.poiType)),
                    onPress: pinTap,
                    rating: pointOfInterest!.getScore(),
                  ));
            }
            cache.add(feature);
          }

          if (screenFence.contains(bounds: feature.getBounds())) {
            markers.add(feature);
            updateDetails = true;
          }
          break;
        case 2:
          if (cacheFence.overlapped(bounds: feature.getBounds())) {
            mt.Route? goodRoad = await _goodRoadRepository.loadGoodRoad(
                key: feature.row, id: feature.id, uri: feature.uri);
            if (goodRoad != null) {
              if (updateCache) {
                goodRoads.add(goodRoad);
                cache.add(feature);
              }
              if (zoom > 10) {
                updateDetails = await moveRouteMarker(
                  screenFence: screenFence,
                  route: goodRoad,
                  feature: feature,
                  visibleFeatures: markers,
                  cache: cache,
                  zoom: zoom,
                );
              }
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

  return updateDetails && markers.isNotEmpty;
}

Future<bool> addRouteMarker(
    {required List<mt.Route> routes,
    required Feature feature,
    required List<Feature> visibleFeatures,
    required Fence screenFence,
    double score = 1,
    zoom = 12}) async {
  LatLng? markerPoint =
      await routeMarkerPosition(polylines: routes, fence: screenFence);
  if (markerPoint != null && screenFence.containsPoint(point: markerPoint)) {
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
          rating: routes[0].rating.toDouble(),
        ),
      ),
    );
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
    required PointOfInterestRepository pointOfInterestRepository,
    zoom = 12}) async {
  Feature start = feature;
  LatLng? markerPoint =
      await routeMarkerPosition(polylines: [route], fence: screenFence);
  if (screenFence.containsPoint(point: markerPoint!)) {
    for (Feature feature in cache) {
      if (feature.poiType == 13) {
        PointOfInterest? goodRoadStart =
            await pointOfInterestRepository.loadPointOfInterest(
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

pinTap(
    {int index = -1,
    required BuildContext context,
    required TripItemRepository tripItemRepository,
    required PointOfInterestRepository pointOfInterestRepository,
    required GoodRoadRepository goodRoadRepository,
    required List<Feature> features,
    required List<Card> cards}) async {
  Map<String, dynamic> infoMap = await getDialogData(
      features: features,
      index: index,
      tripItemRepository: tripItemRepository,
      pointOfInterestRepository: pointOfInterestRepository,
      goodRoadRepository: goodRoadRepository); //.then((infoMap){}
  Key cardKey = Key('pin_${infoMap['key']}');
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

                for (int i = 0; i < cards.length; i++) {
                  if (cards[i].key == cardKey) {
                    // Key('pin_${_features[rowIndex].row}')) {
                    idx = i;
                    break;
                  }
                  // i++;
                }
                _featuresController.updateDetails(idx);
              },
              //       () => {// debugPrint('callback - Cancel')}
            ],
            ['Details', 'Cancel'],
          ),
        );
      },
    );
  }
}

Future<Map<String, dynamic>> getDialogData(
    {required List<Feature> features,
    required int index,
    required TripItemRepository tripItemRepository,
    required PointOfInterestRepository pointOfInterestRepository,
    required GoodRoadRepository goodRoadRepository}) async {
  Map<String, dynamic> mapInfo = {
    'key': features[index].row,
    'title': 'N/A',
    'content': 'N/A',
    'images': ''
  };

  switch (features[index].type) {
    case 0:
      await tripItemRepository
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
          await pointOfInterestRepository.loadPointOfInterest(
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
      mt.Route? goodRoad = await goodRoadRepository.loadGoodRoad(
          key: features[index].row,
          id: features[index].id,
          uri: features[index].uri);
      if (goodRoad != null) {
        for (Feature feature in features) {
          if (feature.type == 1 && feature.uri == goodRoad.pointOfInterestUri) {
            PointOfInterest? pointOfInterest =
                await pointOfInterestRepository.loadPointOfInterest(
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
*/
/*
class Providers {
  const Providers();

    final TripItemRepository _tripItemRepository = TripItemRepository();
  final PointOfInterestRepository _pointOfInterestRepository =
      PointOfInterestRepository();
  final GoodRoadRepository _goodRoadRepository = GoodRoadRepository();
  final RouteRepository _routeRepository = RouteRepository();
  final ImageRepository _imageRepository = ImageRepository();

  dynamic getData(dynamic data) {
    switch (data.runtimeType) {
      case TripItem _:
        return _tripItemRepository.loadTripItem(key: key, id: id, uri: uri)


    }
  }


}
*/
