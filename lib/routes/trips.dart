import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:universal_io/universal_io.dart';
import '/constants.dart';
import '/classes/classes.dart';
import '/models/models.dart';
import '/screens/main_drawer.dart';
import '/screens/dialogs.dart';
import '/services/services.dart';
import 'package:latlong2/latlong.dart' as fmll;
// import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '/classes/route.dart' as mt;
import '/helpers/edit_helpers.dart';
// import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:flutter_map_maplibre/flutter_map_maplibre.dart';
import 'package:maplibre_gl/maplibre_gl.dart'; // hide LatLng;
import 'package:flutter_map/src/geo/latlng_bounds.dart' as fm;
import 'dart:developer' as developer;

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
}

class Trips extends StatefulWidget {
  const Trips({
    super.key,
  });

  @override
  State<Trips> createState() => _TripsState();
}

class _TripsState extends State<Trips> with TickerProviderStateMixin {
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  late final ExpandNotifier _expandNotifier;
  // final mapController = MapController();
  late Position _currentPosition;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final DraggableScrollableController _bdScrollController =
      DraggableScrollableController();
  MapLibreMapController? _mapController;
  final GlobalKey _scaffoldKey = GlobalKey();
  late final Future<bool> _dataLoaded;
  // late Style _style;
  bool _showPreferences = false;
  bool _publishedFeaturesUpdated = true;
  final TripsPreferences _preferences = TripsPreferences();
  final ScrollController _preferencesScrollController = ScrollController();
  //final _dividerHeight = 35.0;
  bool refreshTrips = true;
  List<double> mapHeights = [0, 0, 0, 0];
  double mapHeight = -1; //250;
  double listHeight = -1;
  PublishedFeatures _publishedFeatures = PublishedFeatures(
      features: [], pinTap: (_) => (), pointOfInterestLookup: {});
  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _bottomNavKey = GlobalKey();

  Map<String, dynamic> linesMap = {};

  Map<String, dynamic> _routeFeatures = {
    "type": "FeatureCollection",
    "features": []
  };

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _expandNotifier = ExpandNotifier(-1);
    _dataLoaded = dataFromDatabase();

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

  Future<bool> dataFromDatabase() async {
    try {
      _publishedFeatures = await getPublishedFeatures(
          pinTap: pinTap,
          onGetTrip: onGetTrip,
          showRoutes: true,
          expandNotifier: _expandNotifier);
    } catch (e) {
      debugPrint('Error getting data from the Internet error ${e.toString()}');
    }
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting data: ${e.toString()}');
    }
    return true;
  }

  onGetTrip(int index, String uri) async {
    DownloadOptions options = DownloadOptions();
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              title: Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Text(
                  'Download this trip to -',
                  style: titleStyle(
                      context: context, color: Colors.black, size: 1),
                ),
              ),
              elevation: 5,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Wrap(children: [
                      //  Text('To ',
                      //      style: textStyle(
                      //          context: context, color: Colors.black, size: 2)),
                      Text('My Trip ',
                          style: titleStyle(
                              context: context, color: Colors.black, size: 2)),
                      Icon(Icons.map_outlined),
                      Text('to edit or drive the trip now',
                          style: textStyle(
                              context: context, color: Colors.black, size: 2))
                    ]),
                    value: options.newTrip,
                    onChanged: (value) =>
                        setState(() => options.isNew(isNew: value!)),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: Wrap(children: [
                      //  Text('To ',
                      //      style: textStyle(
                      //          context: context, color: Colors.black, size: 2)),
                      Text('My Drives ',
                          style: titleStyle(
                              context: context, color: Colors.black, size: 2)),
                      Icon(Icons.person_outline_outlined),
                      Text('to edit or drive the trip later',
                          style: textStyle(
                              context: context, color: Colors.black, size: 2))
                    ]),
                    value: options.myTrip,
                    onChanged: (value) =>
                        setState(() => options.isNew(isNew: !value!)),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 30),
                ],
              ),
              actions: actionButtons(context, [() => options.downLoad = true],
                  ['Download', 'Close']),
            );
          },
        );
      },
    ).then((_) async {
      if (options.downLoad) {
        MyTripItem gotTrip = await getMyTrip(uri);
        if (options.myTrip) {
          await gotTrip.saveLocal();
        } else if (mounted) {
          Navigator.pushNamed(context, 'createTrip',
              arguments: TripArguments(gotTrip, '')); //'web'));
        }
      }
    });
    // }
  }

  /// pinTap is executed when a marker pin is tapped
  /// It's attached to each marker as they are generated
  /// from the features obtained from the API
  /// Unlike the pinTap for CreateTrip the cards will be shown
  /// in different ways:
  /// If a Route pin is tapped then the details list should contained
  /// all the children of that trip.
  /// The selected Route name will appear as the page title
  /// Tapping a pin that belongs to the selected Route should open
  /// the details list at the appropriate tile. This allows the user
  /// to see the sequence of features as the occur in the trip.
  /// If a pin is tapped that doesn't belong to the last selected trip
  /// then it will be shown in the dialog like in the CreateTrip class,
  /// and the details list will be unaffected.

  pinTap(int index) async {
    Map<String, dynamic> infoMap = await getDialogData(
        features: _publishedFeatures.features, index: index);
    Key cardKey = infoMap['key'];
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            title: Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: Text(
                infoMap['title'],
                style:
                    titleStyle(context: context, color: Colors.black, size: 2),
              ),
            ), //textStyle),
            elevation: 5,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  child: infoMap['content'],
                ),
              ],
            ),
            actions: actionButtons(
              context,
              callbacks(isRoute: infoMap['isRoute'], cardKey: cardKey),
              buttonTexts(isRoute: infoMap['isRoute']),
            ),
          );
        },
      );
    }
  }

  List<dynamic> callbacks({bool isRoute = false, Key? cardKey}) {
    if (isRoute) {
      return [
        () async {
          int idx = 0;
          setState(() => adjustMapHeight(MapHeights.pointOfInterest));
          await Future.delayed(const Duration(milliseconds: 500));

          for (int i = 0; i < _publishedFeatures.routeCards.length; i++) {
            if (_publishedFeatures.routeCards[i].key == cardKey) {
              idx = i;
              break;
            }
          }

          _itemScrollController.jumpTo(index: idx);
          await Future.delayed(const Duration(milliseconds: 200));
          _expandNotifier.targetValue(target: idx);
          await Future.delayed(const Duration(milliseconds: 200));
          _itemScrollController.scrollTo(
              index: idx,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic);
          // refresh listeners else works only once
          // _expandNotifier.notifyListeners();
        }
      ];
    } else {
      return [];
    }
  }

  List<String> buttonTexts({bool isRoute = false}) {
    if (isRoute) {
      return ['Details', 'Close'];
    } else {
      return ['Close'];
    }
  }

  Future<Map<String, dynamic>> getDialogData(
      {required List<Feature> features, required int index}) async {
    Feature feature = features[index];
    Key cardKey = Key('pin_${feature.row}');
    Map<String, dynamic> mapInfo = {
      'key': cardKey,
      'title': 'N/A',
      'content': Text('N/A'),
      'images': '',
    };
    if (feature.type == 0) {
      for (int i = 0; i < _publishedFeatures.routeCards.length; i++) {
        if (_publishedFeatures.routeCards[i].key == cardKey) {
          mapInfo['content'] = _publishedFeatures.routeCards[i];
          break;
        }
      }
    } else {
      for (int i = 0; i < _publishedFeatures.cards.length; i++) {
        if (_publishedFeatures.cards[i].key == cardKey) {
          mapInfo['content'] = _publishedFeatures.cards[i];
          break;
        }
      }
    }
    switch (feature.type) {
      case 0:
        TripItem tripItem = await _publishedFeatures.tripItemRepository
            .loadTripItem(key: feature.row, id: feature.id, uri: feature.uri);
        mapInfo['title'] = 'Published Trip';
        mapInfo['isRoute'] = true;
        if (mounted) {
          mapInfo['content'] = Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 0, 10),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    tripItem.heading,
                    style: textStyle(
                        context: context, color: Colors.black, size: 3),
                  ),
                ),
                Row(children: [
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text('by ${tripItem.author}',
                          style: textStyle(
                              context: context, color: Colors.black, size: 3)),
                    ),
                  ),
                ]),
                Row(children: [
                  Expanded(
                      flex: 1,
                      child: StarRating(
                          rating: tripItem.score, onRatingChanged: () => {})),
                ]),
                Row(children: [
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'on ${tripItem.published}',
                        style: textStyle(
                            context: context, color: Colors.black, size: 3),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          );
        }
        break;
      case 1:
        PointOfInterest? pointOfInterest = await _publishedFeatures
            .pointOfInterestRepository
            .loadPointOfInterest(
                key: feature.row, id: feature.id, uri: feature.uri);
        if (pointOfInterest != null) {
          mapInfo['title'] = poiTypes[feature.poiType]['name'];
          mapInfo['isRoute'] = false;
        }
        break;
      case 2:
        mt.Route? goodRoad = await _publishedFeatures.goodRoadRepository
            .loadGoodRoad(key: feature.row, id: feature.id, uri: feature.uri);
        if (goodRoad != null) {
          for (Feature feature in features) {
            if (feature.type == 1 &&
                feature.uri == goodRoad.pointOfInterestUri) {
              PointOfInterest? pointOfInterest = await _publishedFeatures
                  .pointOfInterestRepository
                  .loadPointOfInterest(
                      key: feature.row, id: feature.id, uri: feature.uri);
              if (pointOfInterest != null) {
                mapInfo['title'] = 'Point of Interest';
                mapInfo['isRoute'] = false;
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

  Widget _getPortraitBody() {
    return _handleMap();
  }

  Widget? cardsList({required List<Card> cards}) {
    Widget? scrollList;
    try {
      if (cards.isNotEmpty) {
        scrollList = ListView.builder(
          itemCount: cards.length,
          itemBuilder: (context, index) =>
              cards[index < cards.length ? index : cards.length - 1],
        );
      }
    } catch (e) {
      debugPrint('Error building scrollList ${e.toString()}');
    }
    return scrollList;
  }
  /*
  OnFeatureInteractionCallback = void Function(
  Point<double> point,
  LatLng coordinates,
  String id,
  String layerId,
  Annotation? annotation,
);
  */

  _onMapUpdate(LatLng pos, MapLibreMapController mapController) async {
    _mapController ??= mapController;
    developer.log("_onMapUpdate called", name: "_shieldTap");
    if (!_mapController!.onFeatureTapped.contains(_onShieldTapped)) {
      developer.log("_onMapUpdate callback added", name: "_shieldTap");
      _mapController!.onFeatureTapped.add(_onShieldTapped);
    }

    LatLngBounds fenceRegion = await mapController.getVisibleRegion();
    Fence newFence = Fence.fromDoubles(
        fenceRegion.northeast.latitude,
        fenceRegion.northeast.longitude,
        fenceRegion.southwest.latitude,
        fenceRegion.southwest.longitude);
    if (_publishedFeaturesUpdated) {
      _publishedFeaturesUpdated = false;
      _publishedFeatures.update(screenFence: newFence).then(
        (update) {
          _publishedFeaturesUpdated = true;
          debugPrint('Routes ${_publishedFeatures.routes.length}');
          if (_publishedFeatures.routes.isNotEmpty) {
            addPolyLines(routes: _publishedFeatures.routes);
          }
          if (update) {
            setState(() => {});
          }
        },
      );
    }
  }

  _onFeatureTapped(
      dynamic featureId, Point<double> point, LatLng coords) async {
    var features = await _mapController?.queryRenderedFeatures(
        point, ["published-data"], null);
    if (features?.isNotEmpty ?? false) {
      debugPrint('Featured: ${features.toString()}');
    }
  }

  void _onShieldTapped(point, latlng, id, layerId, annotation) async {
    developer.log("_onShieldTapped called", name: "_shieldTap");
    var features = await _mapController!
        .queryRenderedFeatures(point, ["route-shield-layer"], null);
    if (features.isNotEmpty) {
      var tappedFeature = features.first;
      var name = tappedFeature['properties']['name'];
      developer.log("_onShieldTapped feature $name found", name: "_shieldTap");
    } else {
      developer.log("_onShieldTapped features are empty", name: "_shieldTap");
    }
  }

  _onTap(var tap, LatLng pos) async {
    LatLngBounds bounds = await _mapController!.getVisibleRegion();
    var foundFeatures;
    try {
      // var point = Point(tap.x.toDouble(), tap.y.toDouble());
      foundFeatures = await _mapController!
          .queryRenderedFeatures(tap, ["route-shield-layer"], null);
      if (foundFeatures.isNotEmpty) {
        var tappedFeature = foundFeatures.first;
        var name = tappedFeature['properties']['name'];
        developer.log("_onShieldTapped feature $name found",
            name: "_shieldTap");
      } else {
        developer.log("_onShieldTapped features are empty", name: "_shieldTap");
      }
    } catch (e) {
      developer.log(
          '_onTap Error ${e.toString} - features: ${foundFeatures.toString()}');
    }
    /*  
    var lineToChange =
        _routeFeatures["features"].firstWhere((f) => f["id"] == "route-1");
    lineToChange['properties']['color'] = Setup().goodRouteColourHex();
    await _mapController!.setGeoJsonSource("route-features", _routeFeatures);
  */
  }

  Future<Rect> getScreenRect({required LatLngBounds bounds}) async {
    Point topRight = await _mapController!.toScreenLocation(bounds.northeast);
    Point botLeft = await _mapController!.toScreenLocation(bounds.southwest);
    return Rect.fromPoints(
        Offset(topRight.x.toDouble(), 0), Offset(0, botLeft.y.toDouble()));
  }

  Future<String?> getFirstLabelLayer() async {
    String? firstLabelId;
    List<dynamic> layerIds = await _mapController!.getLayerIds();
    for (var id in layerIds) {
      if (id.toString().contains('label') ||
          id.toString().contains('place') ||
          id.toString().contains('poi')) {
        firstLabelId = id;
        break;
      }
    }
    return firstLabelId;
  }

  Future<bool> layerExists({required String layerId}) async {
    List<dynamic> layerIds = await _mapController!.getLayerIds();
    bool result = false;
    for (var id in layerIds) {
      if (id.toString().contains(layerId)) {
        result = true;
        break;
      }
    }
    return result;
  }

  void addPolyLines({required List<mt.Route> routes}) async {
    //  String? firstLabelLayer = await getFirstLabelLayer();
    linesMap.clear();
    List<Map<String, dynamic>> features = [];
    for (int i = 0; i < routes.length; i++) {
      List<fmll.LatLng> points = routes[i].points;
      var geometry = {
        "coordinates":
            points.map((point) => [point.longitude, point.latitude]).toList(),
        "type": "LineString"
      };
      features.add(
        {
          "type": "Feature",
          "id": "route-$i",
          "properties": {
            "color": Setup().routeColourHex(), // '#007AFF', //"#FF0000",
            "width": 3.0,
            "name": "published route $i",
          }, //<String, dynamic>{},
          "geometry": geometry,
        },
      );
      linesMap["route-${i + 1}"] = features.last;
    }
    _routeFeatures['features'] = features;
    await _mapController!.setGeoJsonSource("published-data", _routeFeatures);

    /* await _mapController!.addLineLayer(
      belowLayerId: firstLabelLayer,
      "route_features", // Source - Data
      "published_routes", // Layer-id
      const LineLayerProperties(
        lineColor: ["get", "color"],
        lineCap: "round",
        lineJoin: "round",
        lineWidth: [
          "interpolate",
          ["linear"],
          ["zoom"],
          10,
          ["get", "width"],
          13,
          [
            "*",
            ["get", "width"],
            2
          ]
        ],
      ),
    );
    */
    /*
     await _mapController!.addSymbolLayer(
      "route_features", // The source containing your lines
      "route_shield_layer",
      SymbolLayerProperties(
        // Option A: Use the shorthand
        textField: "{name}",
        textFont: ["Noto Sans Regular"],
        iconSize: 0.5,
        iconColor: colourToHex(color: Colors.amber),
        iconImage: "shield",
        iconKeepUpright: true,
        iconAnchor: "bottom",
        iconRotationAlignment: "viewport",

        // Option B: Use the formal expression (Recommended)
        // textField: ["get", "ref"],

        textSize: 12.0,
        textColor: "#FFFFFF",
        symbolPlacement: "line", // This makes the labels follow the line path
        symbolSpacing: 250, // Pixels between repeated labels
      ),
    );
    */
  }

  Widget _handleMap() {
    return Stack(children: [
      MLMap(
        onUpdate: _onMapUpdate,
        onTap: _onTap,
      ),
      BottomDrawer(
        maxHeight: 200,
        content: cardsList(cards: _publishedFeatures.routeCards),
      ),
    ]);

    /*Stack(
      children: [
        IgnorePointer(child: MLMap()),
        // MediaQuery.of(context).size.height - 200
        //  const MapLibreLayer(
        //    initStyle: _style,
        //  ),
        /*
        MapLibreMap(
          // ignore: avoid_redundant_argument_values --- EXAMPLE ---
          styleString:
              _testStyle, // 'https://demotiles.maplibre.org/style.json',
          //    'http://10.101.1.216:5001/v1/tile/style.json', // 'https://demotiles.maplibre.org/style.json',
          //    _testStyle, // urlTiler, // 'https://demotiles.maplibre.org/style.json',
          myLocationEnabled: true,
          onMapCreated: (c) => _controller = c,
          initialCameraPosition: const CameraPosition(
            target: LatLng(0, 0), // LatLng(51.5, 0.126),
            zoom: 2,
          ),
          trackCameraPosition: true,
        ),
*/
/*
        FlutterMap(
          mapController: _animatedMapController.mapController,
          options: MapOptions(
            onMapReady: () async {
              Fence newFence = Fence.fromBounds(
                  _animatedMapController.mapController.camera.visibleBounds);
              mapController.mapEventStream.listen((event) {});
              if (_publishedFeaturesUpdated) {
                _publishedFeaturesUpdated = false;
                _publishedFeatures.update(screenFence: newFence).then(
                  (update) {
                    if (update) {
                      setState(() => {});
                    }
                  },
                );
                _publishedFeaturesUpdated = true;
              }
            },
            onPositionChanged: (pos, change) async {
              Fence newFence = Fence.fromBounds(
                  _animatedMapController.mapController.camera.visibleBounds);
              if (_publishedFeaturesUpdated) {
                _publishedFeaturesUpdated = false;
                _publishedFeatures.update(screenFence: newFence).then(
                  (update) {
                    _publishedFeaturesUpdated = true;
                    if (update) {
                      setState(() => {});
                    }
                  },
                );
              }
            },
            initialCenter: LatLng(_currentPosition.latitude,
                _currentPosition.longitude), // LatLng(51.507, 0.1276),
            initialZoom: getInitialZoom(),
            maxZoom: 16,
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
            if (kIsWeb)
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png', //  drives.motatek.com/static/tiles/{z}/{x}/{y}.pbf',
              ),
            if (!kIsWeb)
              VectorTileLayer(
                theme: _style.theme,
                // sprites: _style.sprites,
                tileProviders: _style.providers,
                layerMode: VectorTileLayerMode.raster, //  vector,
                tileOffset: TileOffset.DEFAULT,
                // cacheFolder: getCacheFolder,
              ),
            PolylineLayer(polylines: _publishedFeatures.routes),
            PolylineLayer(polylines: _publishedFeatures.goodRoads),
            MarkerLayer(
              markers: _publishedFeatures.markers,
              alignment: Alignment.topCenter,
            ),
          ],
        ),
        */
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
                Text(
                  'Published trip',
                  style:
                      labelStyle(context: context, size: 3, color: Colors.blue),
                ),
                Icon(Icons.location_on,
                    size: 25, color: colourList[Setup().pointOfInterestColour]),
                Text(
                  'Point of interest',
                  style: labelStyle(
                      context: context, size: 3, color: Colors.green),
                ),
                Icon(Icons.route_outlined,
                    size: 25, color: colourList[Setup().goodRouteColour]),
                Text(
                  'Good road',
                  style:
                      labelStyle(context: context, size: 3, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    */
  }

  double getInitialZoom() {
    return 9.0;
  }

  routeTapped(routes, details) {
    if (details != null) {}
  }

  Future<Directory> getCacheFolder() async {
    String appDocumentDirectory =
        (await getApplicationDocumentsDirectory()).path;
    Directory cacheDirectory = Directory('$appDocumentDirectory/cache');
    if (!await cacheDirectory.exists()) {
      await Directory('$appDocumentDirectory/cache').create();
    }
    return cacheDirectory;
  }

  onPointOfInterestRatingChanged(int value, int index) {
    // key.toString() => "[<'pin_12'>]"
    int row = int.parse(_publishedFeatures.cards[index].key
        .toString()
        .substring(
            7, _publishedFeatures.cards[index].key.toString().length - 3));
    String uri = _publishedFeatures.features[row].uri;
    putPointOfInterestRating(uri, value.toDouble());
  }

  adjustMapHeight(MapHeights newHeight) {
    double abHeight = 80;
    double bnHeight = 80;

    if (mapHeights[1] == 0) {
      final bnKeyContext = _bottomNavKey.currentContext;
      final abKeyContext = _appBarKey.currentContext;
      if (abKeyContext != null) {
        final box = abKeyContext.findRenderObject() as RenderBox;
        abHeight = box.size.height;
      }
      if (bnKeyContext != null) {
        final box = bnKeyContext.findRenderObject() as RenderBox;
        bnHeight = box.size.height;
      }
      mapHeights[0] = MediaQuery.of(context).size.height -
          (abHeight + bnHeight + 30); //* .825; //- 190; // info closed
      mapHeights[1] = mapHeights[0] * .35; // 400; //275; // heading data
      mapHeights[2] = mapHeights[0] * .30; // open point of interest
      mapHeights[3] = mapHeights[0] * .6; // message
    }
    mapHeight = mapHeights[MapHeights.values.indexOf(newHeight)];
    listHeight = (mapHeights[0] - mapHeight);
  }

  expandChange(var details) {
    if (details != null) {
      setState(
        () {
          if (details >= 0) {
            adjustMapHeight(MapHeights.pointOfInterest);
          } else {
            FocusManager.instance.primaryFocus?.unfocus(); // dismiss keyboard
            adjustMapHeight(MapHeights.full);
          }
        },
      );
    }
  }

  double getMapHeight(MapHeight height) {
    return mapHeights[MapHeight.values.indexOf(height)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.blue,
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: AppBar(
        key: _appBarKey,
        automaticallyImplyLeading: false,
        leading: LeadingWidget(
          controller: _leadingWidgetController,
          onMenuTap: (index) => _leadingWidget(_scaffoldKey.currentState),
        ), // IconButton(
        title: Text(
          'Trips available to download',
          style: const TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              onPressed: () => {}, icon: Icon(Icons.help_outline_outlined))
        ],

        backgroundColor: Colors.blue,
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
                        preferencesScrollController:
                            _preferencesScrollController), //setPreferences(),
                  ),
                ),
              )
            : null,
      ),
      body: //PortraitBody(),

          FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            // debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            // _building = false;
            return _getPortraitBody();
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
          throw ('Error - FutureBuilder line 752 in trips.dart');
        },
      ),
      floatingActionButton: _mapController != null
          ? HandleFabs(controller: _mapController!)
          : null,
      bottomNavigationBar: RoutesBottomNav(
        key: _bottomNavKey,
        controller: _bottomNavController,
        initialValue: 1,
        onMenuTap: (_) => {},
      ),
      drawerEnableOpenDragGesture: false,
    );
  }
}

class HandleFabs extends StatelessWidget {
  final double _width = 50;
  final double _height = 56.0;
  final MapLibreMapController controller;
  const HandleFabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(
          height: 220,
        ),
        PlaceFinder(
          height: _height,
          width: _width,
          onSelect: (position) => controller.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        FloatingActionButton(
          heroTag: 'location',
          onPressed: () async {
            Position currentPosition = await Geolocator.getCurrentPosition();
            controller.animateCamera(CameraUpdate.newLatLng(
                LatLng(currentPosition.latitude, currentPosition.longitude)));
          },
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
          ),
        ),
        const SizedBox(
          height: 15,
        ),
      ],
    );
  }
}

class DownloadOptions {
  bool downLoad = false;
  bool newTrip;
  bool myTrip;
  String uri;
  DownloadOptions({this.uri = '', this.newTrip = false, this.myTrip = true});
  isNew({required bool isNew}) {
    newTrip = isNew;
    myTrip = !newTrip;
  }
}
