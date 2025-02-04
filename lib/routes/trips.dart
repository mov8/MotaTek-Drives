// import 'package:drives/constants.dart';
// import 'package:drives/constants.dart';
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
// import 'package:geolocator/geolocator.dart';
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
  late AnimatedMapController _animatedMapController;
// scrollablepositonedlist
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener =
      ScrollOffsetListener.create();
// scrollablepositonedlist
  final _mapController = MapController();
  final ScrollController _scrollController = ScrollController();
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
  final Fence cacheFence =
      Fence(northEast: const LatLng(0, 0), southWest: const LatLng(0, 0));
  final Fence screenFence =
      Fence(northEast: const LatLng(0, 0), southWest: const LatLng(0, 0));
  late final List<Feature> _features;
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
    _dataLoaded = _getTripData();
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
    _mapController.dispose();
    _scrollController.dispose();
    // scrollablepositonedlist listenrs dont have a dispose method
    super.dispose();
  }

  Future<bool> _getTripData() async {
    try {
      _features = await getFeatures(zoom: 12, onTap: () => pinTap);
    } catch (e) {
      debugPrint('Error getting features: ${e.toString()}');
    }
    try {
      _styleReader = StyleReader(
          uri:
              'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key={key}',
          apiKey: stadiaMapsApiKey,
          logger: null);
      _style = await _styleReader.read();
    } catch (e) {
      debugPrint('Error initiating style: ${e.toString}');
    }
    return true;
  }

  pinTap(int index) async {
    _pointOfInterestRepository
        .loadPointOfInterest(
            key: _features[index].row,
            id: _features[index].id,
            uri: _features[index].uri)
        .then(
          (pointOfInterest) => showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(pointOfInterest!.getName(),
                    style: const TextStyle(fontSize: 16)), //textStyle),
                elevation: 5,
                content: Text(pointOfInterest.getDescription(),
                    style: const TextStyle(fontSize: 16)),
                actions: actionButtons(
                  context,
                  [
                    () async {
                      int i = 0;
                      int idx = 0;
                      setState(
                          () => adjustMapHeight(MapHeight.pointOfInterest));
                      await Future.delayed(
                          const Duration(milliseconds: 500)); //_resizeDelay));

                      for (Card card in _cards) {
                        if (card.key == Key('pin_${_features[index].row}')) {
                          idx = i;
                          break;
                        }
                        i++;
                        // card. = 10;
                      }

                      itemScrollController.jumpTo(index: idx);
                      await Future.delayed(const Duration(milliseconds: 200));
                      _expandNotifier.targetValue(target: idx);
                      await Future.delayed(const Duration(milliseconds: 200));
                      itemScrollController.scrollTo(
                          index: idx,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOutCubic);

                      /// _expandNotifier.notifyListeners(); resets
                      /// all the listeners else they only work once !
                      _expandNotifier.notifyListeners();
                    },
                    () => {debugPrint('callback - Cancel')}
                  ],
                  ['Details', 'Cancel'],
                ),
              );
            },
          ),
        );
    debugPrint('Pin no $index tapped');
  }

  /*  
    void get positionsView => ValueListenableBuilder<Iterable<ItemPosition>>(
        valueListenable: itemPositionsListener.itemPositions,
        builder: (context, positions, child) {
          int? min;
          int? max;
          if (positions.isNotEmpty) {
            // Determine the first visible item by finding the item with the
            // smallest trailing edge that is greater than 0.  i.e. the first
            // item whose trailing edge in visible in the viewport.
            min = positions
                .where((ItemPosition position) => position.itemTrailingEdge > 0)
                .reduce((ItemPosition min, ItemPosition position) =>
                    position.itemTrailingEdge < min.itemTrailingEdge
                        ? position
                        : min)
                .index;
            // Determine the last visible item by finding the item with the
            // greatest leading edge that is less than 1.  i.e. the last
            // item whose leading edge in visible in the viewport.
            max = positions
                .where((ItemPosition position) => position.itemLeadingEdge < 1)
                .reduce((ItemPosition max, ItemPosition position) =>
                    position.itemLeadingEdge > max.itemLeadingEdge
                        ? position
                        : max)
                .index;
          }
       /*  return Row(
            children: <Widget>[
              Expanded(child: Text('First Item: ${min ?? ''}')),
              Expanded(child: Text('Last Item: ${max ?? ''}')),
              const Text('Reversed: '),
              Checkbox(
                  value: reversed,
                  onChanged: (bool? value) => setState(() {
                        reversed = value!;
                      }))
            ],
          ); */
        },
      );
*/
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
        debugPrint('Value: $value  Index: $index');
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
            //  key: cardListKey,
            height: listHeight,
// scrollablepositonedlist
            child: _cards.isNotEmpty
                ? ScrollablePositionedList.builder(
                    itemCount: _cards.length,
                    itemBuilder: (context, index) =>
                        //  getCard(feature: _visibleFeatures[index], index: index),
                        //  getCards(features: _visibleFeatures, cards: _cards),
                        _cards[index],
                    itemScrollController: itemScrollController,
                    scrollOffsetController: scrollOffsetController,
                    itemPositionsListener: itemPositionsListener,
                    scrollOffsetListener: scrollOffsetListener,
                  )
                : null,

// scrollablepositonedlist

            /*           
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                children: _cards,
              )
  */
            //_showTrips(), // Allows the trip to be planned
          ),
        ],
      ),
    );
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
              screenFence.changeBounds(
                  llBounds: _animatedMapController
                      .mapController.camera.visibleBounds);
              cacheFence.setBounds(bounds: screenFence, deltaDegrees: 0.5);
              _routes.add(mt.Route(points: [const LatLng(0, 0)]));
              _mapReady = true;
              filterFeatures(
                      features: _features,
                      cacheFence: cacheFence,
                      screenFence: screenFence,
                      cachedFeatures: _cachedFeatures,
                      visibleFeatures: _visibleFeatures,
                      goodRoads: _goodRoads,
                      routes: _routes)
                  .then((update) {
                if (update) {
                  debugPrint('>>>>> Map ready cards refreshing');
                  getCards(features: _visibleFeatures, cards: _cards);
                  debugPrint(
                      '>>>>> Map ready cards refreshed _cards.length: ${_cards.length}');
                }
              });
              setState(() => adjustMapHeight(MapHeight.full));
              _mapController.mapEventStream.listen((event) {});
              debugPrint('Map ready......');
            },
            onPositionChanged: (pos, change) async {
              // double zoom = _animatedMapController.mapController.camera.zoom;
              if (refreshTrips) {
                debugPrint('Refreshing trips');
                try {
                  refreshTrips = false;

                  filterFeatures(
                          features: _features,
                          cacheFence: cacheFence,
                          screenFence: screenFence,
                          cachedFeatures: _cachedFeatures,
                          visibleFeatures: _visibleFeatures,
                          goodRoads: _goodRoads,
                          routes: _routes)
                      .then((update) {
                    if (update) {
                      debugPrint('>>>>> Position canged cards refreshing');
                      getCards(features: _visibleFeatures, cards: _cards);
                      debugPrint(
                          '>>>>> Position canged cards refreshed _cards.length: ${_cards.length}');
                      setState(() => refreshTrips = true);
                    } else {
                      debugPrint('>>>> Trips refreshed nothing changed');
                      setState(() => refreshTrips = true);
                    }
                  });
                } finally {
                  debugPrint('Trips refreshed');
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
            MarkerLayer(
              markers: _visibleFeatures,
              alignment: Alignment.topCenter,
            ),
            PolylineLayer(polylines: _routes),
            PolylineLayer(polylines: _goodRoads),
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
      //   debugPrint(
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
                  uri: trip['source']['uri']) ??
              TripItem(heading: '')
      ];
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
    return [];
  }

  /// filterFeatures(List<Feature> features, LatLng northEast, LatLng southWest)
  /// reurns a List<Map<String, dynamic>> of filterFeatures - features that
  /// are in scope of the fence (northEast, soutWest), zoom determines
  /// the size of the marker icon. The outut is in the form of:
  /// [{"row": r, "source": {"type": t, "id": i, "uri": u} }]
  /// row r is the row number in the unfiltered list - used as a cahce key
  /// source tracks where the data originated from
  ///    "type" t 0 = point of interest
  ///             1 = good road
  ///    "id" i is the local database id if the item has been saved locally
  ///    "uri" u is the api uri of the point of interest or good road
  ///
  ///

  Future<bool> filterFeatures({
    required List<Feature> features,
    required Fence cacheFence,
    required Fence screenFence,
    List<Feature> cachedFeatures = const [],
    List<Feature> visibleFeatures = const [],
    List<mt.Route> goodRoads = const [],
    List<mt.Route> routes = const [],
    double zoom = 12,
  }) async {
    int iconsOnMap = 0;
    int featuresInGrid = 0;
    bool updateDetails = false;

    try {
      if (cacheFence.contains(bounds: screenFence) &&
          cachedFeatures.isNotEmpty) {
        Feature feature0 = Feature();
        Feature featuren = Feature();
        if (visibleFeatures.isNotEmpty) {
          feature0 = visibleFeatures[0];
          featuren = visibleFeatures[visibleFeatures.length - 1];
          visibleFeatures.clear();
        }

        for (Feature feature in cachedFeatures) {
          if (screenFence.contains(bounds: feature.getBounds())) {
            visibleFeatures.add(feature);
          }
        }
        updateDetails = feature0 != visibleFeatures[0] ||
            featuren != visibleFeatures[visibleFeatures.length - 1];
      } else {
        cacheFence.setBounds(bounds: screenFence, deltaDegrees: 0.5);
        cachedFeatures.clear();
        visibleFeatures.clear();
        goodRoads.clear();
        routes.clear();
        for (Feature feature in features) {
          if (cacheFence.contains(bounds: feature.getBounds())) {
            switch (feature.type) {
              case 0: // trip - route
                _routeRepository
                    .loadRoute(
                        key: feature.row, id: feature.id, uri: feature.uri)
                    .then((toAdd) {
                  if (toAdd != null) {
                    routes.addAll(toAdd); // to add one list to another
                  }
                });
                break;
              case 1: // point of interest
                feature.child = PinMarkerWidget(
                  index: feature.row,
                  color: colourList[Setup().pointOfInterestColour],
                  width: zoom * 2,
                  overlay: markerIcon(getIconIndex(iconIndex: feature.poiType)),
                  onPress: pinTap,
                );
                iconsOnMap++;
                break;
              case 2: // good road
                goodRoads.add(await _goodRoadRepository.loadGoodRoad(
                        key: feature.row, id: feature.id, uri: feature.uri) ??
                    mt.Route(points: [const LatLng(0, 0)]));
                break;
              default:
                break;
            }
            cachedFeatures.add(feature);
            if (screenFence.contains(bounds: feature.getBounds())) {
              visibleFeatures.add(feature);
              if (feature.poiType != 12) {
                featuresInGrid++;
                updateDetails = true;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
    debugPrint(
        'filterFeatures() iconsOnMap: $iconsOnMap  visibleFeatures.length: ${visibleFeatures.length} featuresInGrid: $featuresInGrid');
    return updateDetails;
  }

  checkMapEvent(var details) {
    if (details != null) {
      debugPrint(
          'Map event: ${details.toString()} zoom: ${_animatedMapController.mapController.camera.zoom}');
      setState(() {
        if (_showDetails !=
            _animatedMapController.mapController.camera.zoom > 12) {
          _showDetails = _animatedMapController.mapController.camera.zoom > 12;
          debugPrint('_showDetails has changed: $_showDetails');
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

  getCards(
      {required List<Feature> features, List<Card> cards = const []}) async {
    await _dataLoaded == true;

    if (features.isNotEmpty && _mapReady) {
      int i = 0;
      cards.clear();
      debugPrint('Line 539 clearing cards');

      for (Feature feature in features) {
        Card? newCard = await getCard(feature: feature, index: i);
        if (newCard != null) {
          cards.add(newCard);
          i++;
        }
      }
      return cards;
    } else {
      debugPrint('Using existing cards - refresh not needed');
    }

    return cards;
  }

  bool refreshCards(
      {required List<Feature> features, required List<Card> cards}) {
    final bool refresh = cards.isEmpty ||
        cards[0].key != Key('pin_${features[0].row}') ||
        cards[cards.length - 1].key !=
            Key('pin_${features[features.length - 1].row}');
    return refresh;
  }

  //Widget

  testFunc(var details) {
    debugPrint('testFunc');
    return null;
  }

  Future<Card?> getCard({required Feature feature, required int index}) async {
    debugPrint('getCard called for index $index');
    if (feature.type == 0) {
      TripItem tripItem = await _tripItemRepository.loadTripItem(
          key: feature.row, id: feature.id, uri: feature.uri);
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
    } else if (feature.type == 1) {
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
      debugPrint('Type 12 PointOfInterest ignored');
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
          debugPrint('ExpandChanged: $details');
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
            debugPrint('Snapshot error: ${snapshot.error}');
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
      bottomNavigationBar: RoutesBottomNav(
        controller: _bottomNavController,
        initialValue: 1,
        onMenuTap: (_) => {},
      ),
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
