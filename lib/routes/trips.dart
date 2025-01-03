// import 'package:drives/constants.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/models.dart';
import 'package:drives/tiles/trip_tile.dart';
import 'package:drives/screens/main_drawer.dart';
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

class TripsScreen extends StatefulWidget {
  const TripsScreen({
    super.key,
  });

  @override
  State<TripsScreen> createState() => _tripsScreenState();
}

class _tripsScreenState extends State<TripsScreen>
    with TickerProviderStateMixin {
  // GlobalKey mapKey = GlobalKey();
  late final LeadingWidgetController _leadingWidgetController;
  late final RoutesBottomNavController _bottomNavController;
  late AnimatedMapController _animatedMapController;
  final mapController = MapController();
  final GlobalKey _scaffoldKey = GlobalKey();
  late Future<bool> _dataLoaded;
  late Style _style;
  List<TripItem> tripItems = [];
  bool _showPreferences = false;
  final TripsPreferences _preferences = TripsPreferences();
  final ScrollController _preferencesScrollController = ScrollController();
  final _dividerHeight = 35.0;
  int _resizeDelay = 0;
  bool refreshTrips = true;
  List<double> mapHeights = [0, 0, 0, 0];
  double mapHeight = 250;
  double listHeight = -1;
  List<LatLng> routePoints = const [LatLng(51.478815, -0.611477)];
  String stadiaMapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';
  late StyleReader _styleReader;
  final TripItemRepository _tripItemRepository = TripItemRepository();
  final GoodRoadRepository _goodRoadRepository = GoodRoadRepository();
  final RouteRepository _routeRepository = RouteRepository();
  final ImageRepository _imageRepository = ImageRepository();
  // late Position _currentPosition;
  List<Map<String, dynamic>> _tripsOnMap = [];
  List<TripItem> _tripsToShow = [];
  List<Photo> _photosToShow = [];
  List<Feature> _features = [];
  List<ImageCacheItem> _images = [];
  List<mt.Route> _routes = [];
  List<mt.Route> _goodRoads = [];
  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    //  final mapController = MapController();
    _animatedMapController = AnimatedMapController(vsync: this);
    _dataLoaded = _getTripData();
    // adjustMapHeight(MapHeight.full);
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
        //  setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  Future<bool> _getTripData() async {
    /// if (!Setup().hasRefreshedTrips && Setup().hasLoggedIn) {
    ///   tripItems = await getTrips();
    ///   if (tripItems.isNotEmpty) {
    ///     Setup().hasRefreshedTrips = true;
    ///     tripItems = await saveTripItemsLocal(tripItems);
    ///   }
    /// } else {
    ///   tripItems = await loadTripItems();
    /// }
    try {
      _features = await getFeatures(
          zoom: 12, //_animatedMapController.mapController.camera.zoom,
          onTap: () => pinTap);
      _images = await getImages();
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

    // _currentPosition = await getPosition();
    // _currentPosition = Setup().lastPosition; // Geolocator.getCurrentPosition();
    return true;
  }

  pinTap() {
    debugPrint('Pin tapped');
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
        debugPrint('Value: $value  Index: $index');
        tripItems[index].score = value.toDouble();
      },
    );
    putDriveRating(tripItems[index].uri, value);
  }

  /*LatLngBounds _region =
      _animatedMapController.mapController.camera.visibleBounds;
*/

  Widget _getPortraitBody() {
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
          _showTrips(), // Allows the trip to be planned
        ],
      ),
    );
  }

  Widget _handleMap() {
    if (listHeight == -1) {
      adjustMapHeight(MapHeight.full);
    }
    //   return RepaintBoundary(
    //  key: mapKey,
    //     child:

    return Stack(
      children: [
        //  SizedBox(
        //    height: mapHeight,
        //    child:
        FlutterMap(
          mapController: _animatedMapController.mapController,
          options: MapOptions(
            onMapEvent: checkMapEvent,
            onMapReady: () async {
              await _filterTripItems(
                  controller: _animatedMapController, features: _features);
              mapController.mapEventStream.listen((event) {});
              debugPrint('Map ready......');
            },
            onPositionChanged: (pos, change) async {
              double zoom = _animatedMapController.mapController.camera.zoom;
              debugPrint('Position changed ${pos.toString()} zoom: $zoom');
              if (refreshTrips) {
                debugPrint('Refreshing trips');
                try {
                  refreshTrips = false;

                  await _filterTripItems(
                      controller: _animatedMapController,
                      features: _features,
                      showDetail: zoom >= 12);
                } finally {
                  debugPrint('Trips refreshed');
                  refreshTrips = true;
                }
              }
            },
            initialCenter: LatLng(
                Setup().lastPosition.latitude, Setup().lastPosition.longitude),
            initialZoom: getInitialZoom(),
            maxZoom: 18,
            minZoom: 5,
            //                initialZoom: 15,
            //     maxZoom: 18,
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
            MarkerLayer(markers: _features),
            PolylineLayer(polylines: _routes),
            PolylineLayer(polylines: _goodRoads),
            /*     TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                  maxZoom: 18,
                ), */

            //         MarkerLayer(markers: _currentTrip.pointsOfInterest()),
          ],
        ),
        //   ),
      ],
      //  ),
    );
  }

  double getInitialZoom() {
    // debugPrint('getInitialZoom called');
    return 12;
  }

  Future<List<TripItem>> getTripsToShow() async {
    try {
      // _goodRoads = await _goodRoadRepository.loadGoodRoad()
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

  List<Map<String, dynamic>> filterFeatures({
    required List<Feature> features,
    required LatLng northEast,
    required LatLng southWest,
    double zoom = 12,
  }) {
    double maxLong = northEast.longitude;
    double maxLat = northEast.latitude;
    double minLong = southWest.longitude;
    double minLat = southWest.latitude;
    List<Map<String, dynamic>> filtered = [];
    for (Feature feature in features) {
      if (feature.point.latitude >= minLat &&
          feature.point.longitude >= minLong &&
          feature.point.latitude <= maxLat &&
          feature.point.longitude <= maxLong) {
        filtered.add({
          "row": feature.row,
          "source": {
            "type": feature.type,
            "id": feature.featureId,
            "uri": feature.uri
          }
        });
        feature.zoomIcon(zoom);
      }
    }
    return filtered;
  }

  _filterTripItems(
      {required AnimatedMapController controller,
      required List<Feature> features,
      bool showDetail = false}) async {
    LatLng northEast = controller.mapController.camera.visibleBounds.northEast;
    LatLng southWest = controller.mapController.camera.visibleBounds.southWest;

    _tripsToShow.clear();
    _goodRoads.clear();
    _routes.clear();
    _photosToShow.clear();
    try {
      List<Map<String, dynamic>> tripsOnMap = filterFeatures(
          features: features,
          northEast: northEast,
          southWest: southWest,
          zoom: controller.mapController.camera.zoom);

      for (Map<String, dynamic> trip in tripsOnMap) {
        switch (trip['source']['type']) {
          case 0:
            _tripsToShow.add(await _tripItemRepository.loadTripItem(
                    key: trip['row'],
                    id: trip['source']['id'],
                    uri: trip['source']['uri'],
                    zoom: 30) ??
                TripItem(heading: ''));

            if (showDetail) {
              try {
                List<mt.Route>? routesToAdd = await _routeRepository.loadRoute(
                    key: trip['row'],
                    id: trip['source']['id'],
                    uri: trip['source']['uri']);
                if (routesToAdd != null && routesToAdd.isNotEmpty) {
                  _routes += routesToAdd;
                }
                /*
                _routeRepository
                    .loadRoute(
                        key: trip['row'],
                        id: trip['source']['id'],
                        uri: trip['source']['uri'])
                    .then((routes) => _routes = _routes + (routes ?? []));
                */
              } catch (e) {
                debugPrint('Error generating routes: ${e.toString()}');
              }
            }
            break;
          case 1:
            if (showDetail) {
              _goodRoads.add(await _goodRoadRepository.loadGoodRoad(
                      key: trip['row'],
                      id: trip['source']['id'],
                      uri: trip['source']['uri']) ??
                  mt.Route(points: [const LatLng(0, 0)]));
            }
            break;
          default:
            if (showDetail) {
              _routeRepository
                  .loadRoute(
                      key: trip['row'],
                      id: trip['source']['id'],
                      uri: trip['source']['uri'])
                  .then((routes) => _routes = _routes + (routes ?? []));
            }
            break;
        }
      }
    } catch (e) {
      debugPrint('_filteredTripItems() error: ${e.toString()}');
      return [];
    }
  }

  checkMapEvent(var details) {
    if (details != null) {
      setState(
        () {
          // debugPrint('Map event: ${details.toString()}');
        },
      );
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

  Widget _showTrips() {
    if (_tripsToShow.isEmpty) {
      _tripsToShow.add(
        TripItem(
            heading: 'Explore the countryside around you',
            subHeading: "Register now to enjoy other people's trips",
            body:
                '''Finding nice places for a drive can be a bit of a challenge particularly if you're not familiar with an area. 
You can download trips that other people have enjoyed, stopping at the pubs, restaurants and other points of interest they have rated. 
You can modify the trips, and publish them yourself for others to enjoy too. 
          ''',
            author: 'Alex S',
            published: '05 Aug 2025',
            imageUrls:
                '[{"url": "map.png", "caption": ""}, {"url": "meeting.png", "caption": ""}]',
            score: 5.0,
            distance: 15.5,
            pointsOfInterest: 3,
            closest: 10,
            scored: 15,
            downloads: 25,
            uri: 'assets/images/'),
      );
    }
    return SizedBox(
        height: listHeight,
        child: ListView.separated(
          itemCount: _tripsToShow.length,
          itemBuilder: (BuildContext context, int index) {
            return TripTile(
                tripItem: _tripsToShow[index],
                imageRepository: _imageRepository,
                index: index,
                onGetTrip: onGetTrip,
                onRatingChanged: onTripRatingChanged);
          },
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
        )

/*      
      child: ListView(
        children: List.generate(
          _tripsToShow.length,
          (index) => TripTile(
              tripItem: _tripsToShow[index],
              index: index,
              onGetTrip: onGetTrip,
              onRatingChanged: onTripRatingChanged),
        ),
        
      ), 
*/
        );
  }

  _handleBottomSheetDivider() {
    _resizeDelay = 0;
    if (listHeight == -1) {
      adjustMapHeight(MapHeight.full);
    }
    // adjustMapHeight(MapHeight.full);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: AbsorbPointer(
        child: Container(
          // margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          color: const Color.fromARGB(255, 158, 158, 158),
          height: _dividerHeight,
          width: MediaQuery.of(context).size.width,
          //  padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
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
      //     onTap: adjustMapHeight(
      //        mapHeight == MapHeights.full ? MapHeights.headers : MapHeights.full),
    ); //);
  }

  adjustMapHeight(MapHeight newHeight) {
    if (mapHeights[1] == 0) {
      mapHeights[0] = MediaQuery.of(context).size.height - 190; // info closed
      mapHeights[1] = mapHeights[0] - 200; // heading data
      mapHeights[2] = mapHeights[0] - 400; // open point of interest
      mapHeights[3] = mapHeights[0] - 300; // message
    }
    mapHeight = mapHeights[MapHeight.values.indexOf(newHeight)];
    //   if (newHeight == MapHeights.full) {
    //     dismissKeyboard();
    //   }
    listHeight = (mapHeights[0] - mapHeight);
    _resizeDelay = 400;
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
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
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
