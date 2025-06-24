import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/models.dart';
import 'package:drives/screens/main_drawer.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:drives/services/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drives/classes/route.dart' as mt;
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
  final mapController = MapController();
  late final AnimatedMapController _animatedMapController;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final GlobalKey _scaffoldKey = GlobalKey();
  late final Future<bool> _dataLoaded;
  late Style _style;
  bool _showPreferences = false;
  final TripsPreferences _preferences = TripsPreferences();
  final ScrollController _preferencesScrollController = ScrollController();
  final _dividerHeight = 35.0;
  int _resizeDelay = 0;
  bool refreshTrips = true;
  // bool _showDetails = false;
  List<double> mapHeights = [0, 0, 0, 0];
  double mapHeight = -1; //250;
  double listHeight = -1;
  PublishedFeatures _publishedFeatures = PublishedFeatures(
      features: [], pinTap: (_) => (), pointOfInterestLookup: {});
  //late StyleReader _styleReader;

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _expandNotifier = ExpandNotifier(-1);
    _animatedMapController = AnimatedMapController(vsync: this);
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
      debugPrint('Error getting data from the Internet');
    }
    try {
      _style = await VectorMapStyle().mapStyle();
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
                  'Download this trip',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              elevation: 5,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Wrap(children: [
                      Text('Download to ',
                          style: TextStyle(color: Colors.black, fontSize: 18)),
                      Text('This Trip',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Icon(Icons.map_outlined),
                      Text('to edit or drive the trip now',
                          style: TextStyle(color: Colors.black, fontSize: 18))
                    ]),
                    value: options.newTrip,
                    onChanged: (value) =>
                        setState(() => options.isNew(isNew: value!)),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: Wrap(children: [
                      Text('Download to ',
                          style: TextStyle(color: Colors.black, fontSize: 18)),
                      Text('My Drives',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Icon(Icons.person_outline_outlined),
                      Text('to edit or drive the trip later',
                          style: TextStyle(color: Colors.black, fontSize: 18))
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
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          setState(() => adjustMapHeight(MapHeight.pointOfInterest));
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
          _expandNotifier.notifyListeners();
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
        mapInfo['content'] = Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 0, 10),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: Text(
                  tripItem.heading,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(children: [
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text('published ${tripItem.author}',
                        style: const TextStyle(fontSize: 12)),
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
                    child: Text('published ${tripItem.published}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ]),
            ],
          ),
        );
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

/*
  onTripRatingChanged(int value, int index) async {
    int row = int.parse(_publishedFeatures.cards[index].key
        .toString()
        .substring(
            7, _publishedFeatures.cards[index].key.toString().length - 3));
  }
*/
  Widget _getPortraitBody() {
    // await _dataLoaded == true;
    if (mapHeight == -1) {
      adjustMapHeight(MapHeight.full);
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: _resizeDelay),
            curve: Curves.easeInOut, // fastOutSlowIn,
            height: mapHeight,
            width: mounted ? MediaQuery.of(context).size.width : 100,
            child: _handleMap(),
          ),

          _handleBottomSheetDivider(), // grab rail - GesureDetector()
          const SizedBox(
            height: 5,
          ),
          SizedBox(
            height: listHeight,
            child: cardsList(cards: _publishedFeatures.routeCards),
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
          itemScrollController: _itemScrollController,
          scrollOffsetController: scrollOffsetController,
          itemPositionsListener: itemPositionsListener,
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
              Fence newFence = Fence.fromBounds(
                  _animatedMapController.mapController.camera.visibleBounds);
              mapController.mapEventStream.listen((event) {});
              _publishedFeatures.update(screenFence: newFence).then(
                (update) {
                  if (update) {
                    setState(() => {});
                  }
                },
              );
            },
            onPositionChanged: (pos, change) async {
              Fence newFence = Fence.fromBounds(
                  _animatedMapController.mapController.camera.visibleBounds);
              _publishedFeatures.update(screenFence: newFence).then(
                (update) {
                  if (update) {
                    setState(() => {});
                  }
                },
              );
            },
            initialCenter: LatLng(51.507, 0.1276),
            // Setup().lastPosition.latitude, Setup().lastPosition.longitude),
            initialZoom: getInitialZoom(),
            maxZoom: 16,
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
          /*
                       theme: _style.theme, //_style.theme,
                  sprites: _style.sprites,
                  tileProviders: _style.providers,
                  showTileDebugInfo: true,
                  layerMode: VectorTileLayerMode.vector,
                  //  cacheFolder: getCacheFolder,
                  tileOffset: TileOffset.DEFAULT),
          */
          children: [
            VectorTileLayer(
              theme: _style.theme,
              // sprites: _style.sprites,
              tileProviders: _style.providers,
              layerMode: VectorTileLayerMode.vector,
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
    return 8.0;
  }

  routeTapped(routes, details) {
    if (details != null) {}
  }

  checkMapEvent(var details) {
    if (details != null) {
      // debugPrint(
      //    'Map event: ${details.toString()} zoom: ${_animatedMapController.mapController.camera.zoom}');
      /*
      setState(() {
        if (_showDetails !=
            _animatedMapController.mapController.camera.zoom > 12) {
          _showDetails = _animatedMapController.mapController.camera.zoom > 12;
          // debugPrint('_showDetails has changed: $_showDetails');
        }
      });
      */
    }
  }

  Future<Directory> getCacheFolder() async {
    String appDocumentDirectory =
        (await getApplicationDocumentsDirectory()).path;
    Directory cacheDirectory = Directory('$appDocumentDirectory/cache');
    if (!await cacheDirectory.exists()) {
      await Directory('$appDocumentDirectory/cache').create();
    }
    return cacheDirectory;
//    Directory cacheDir = Setup().cacheDirectory;
//    if (!await cacheDir.exists()) {
//      await cacheDir.create();
//    }
//    return cacheDir;
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
          'Trips available to download',
          /*
          _publishedFeatures.features.isNotEmpty &&
                  _publishedFeatures.features[0].uri.isNotEmpty
              ? 'Trips available to download'
              : 'To share trips register for free', */
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
          throw ('Error - FutureBuilder line 554 in trips.dart');
        },
      ),

      floatingActionButton: HandleFabs(
          animatedMapController: _animatedMapController), // _handleFabs(),
      bottomNavigationBar: RoutesBottomNav(
        controller: _bottomNavController,
        initialValue: 1,
        onMenuTap: (_) => {},
      ),
      drawerEnableOpenDragGesture: false,
    );
  }
}

class HandleFabs extends StatelessWidget {
  final AnimatedMapController animatedMapController;
  const HandleFabs({super.key, required this.animatedMapController});

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
            //        debugPrint('Position: ${currentPosition.toString()}');
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
