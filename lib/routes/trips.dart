import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:math';
import '/classes/classes.dart' hide Position;
import '/screens/main_drawer.dart';
import '/screens/painters.dart';
import '/services/services.dart';
import 'package:geolocator/geolocator.dart';
import '/helpers/geojson_helpers.dart';
import 'package:maplibre_gl/maplibre_gl.dart'; // hide LatLng;
import '../constants.dart';
import 'dart:developer' as developer;

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
  // late Position _currentPosition;
  // final ScrollController _scrollController = ScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  MapLibreMapController? _mapController;

  BottomDrawerController _bottomDrawerController = BottomDrawerController();
  final GlobalKey _scaffoldKey = GlobalKey();
  late final Future<bool> _dataLoaded;
  bool styleLoaded = false;
  ImageRepository _imageRepository = ImageRepository();
  bool refreshTrips = true;
  List<double> mapHeights = [0, 0, 0, 0];
  double mapHeight = -1; //250;
  double listHeight = -1;
  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _bottomNavKey = GlobalKey();
  final GlobalKey _scrollToKey = GlobalKey();
  DrivesRequest? _drivesRequest;
  TripRequest? _tripRequest;
  List<Card> _tripCards = [];

  bool _opened = true;

  Map<String, dynamic> linesMap = {};

  Widget? _cardList;

  @override
  void initState() {
    super.initState();
    _leadingWidgetController = LeadingWidgetController();
    _bottomNavController = RoutesBottomNavController();
    _dataLoaded = dataFromDatabase();
  }

  Future<bool> dataFromDatabase() async {
    try {
      // _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting data: ${e.toString()}');
    }
    return true;
  }

  _leadingWidget(context) {
    return context?.openDrawer();
  }

  Widget _getPortraitBody() {
    return _handleMap();
  }

  Widget cardsList(
      {required List<Card> cards, required ScrollController controller}) {
    Widget scrollList = Text('');
    try {
      if (cards.isNotEmpty) {
        scrollList = ListView.builder(
          controller: controller,
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

  onUpdated(zoom) {
    setState(
      () => _tripCards = _drivesRequest!.getTripTiles(),
    );
  }

  onGetDetails(index) {}

  onGetDownloads({int index = -1, String name = ''}) {
    debugPrint('Requesting download index: $index, name: $name');
  }

  _onMapUpdate(LatLng pos, MapLibreMapController mapController) async {
    _mapController = mapController;
    _drivesRequest ??= DrivesRequest(
        onUpdated: onUpdated,
        onGetDetails: onGetDetails,
        onGetDownload: (index, name) => onGetDownloads,
        imageRepository: _imageRepository);
    _mapController = mapController;

    _tripRequest ??= TripRequest(
        onUpdated: onUpdated,
        onGetDetails: onGetDetails,
        imageRepository: _imageRepository);
    CurrentTripItem().mapController = _mapController;
  }

  _onIdle() async {
    if (_mapController != null) {
      Map<String, dynamic> geoJson = {};
      try {
        LatLngBounds bounds = await _mapController!.getVisibleRegion();
        double zoom = _mapController!.cameraPosition!.zoom;
        Map<String, dynamic> geoJson;
        geoJson = await _drivesRequest!.update(bounds: bounds, zoom: zoom);
        debugPrint('geoJson: $geoJson');
        if (geoJson.isNotEmpty) {
          await _mapController!.setGeoJsonSource("published-data", geoJson);
          _tripCards = _drivesRequest!.getTripTiles(openUri: "");
          _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
          for (int i = 0; i < geoJson['features'].length; i++) {
            developer.log("Routes $i ${geoJson['features'][i]['properties']}",
                name: '_x_x_');
          }
          // cardsList(cards: _tripCards, controller: _scrollController));
        }
        geoJson = await _tripRequest!.update(bounds: bounds, zoom: zoom);
        if (geoJson['features'].isNotEmpty) {
          await _mapController!.setGeoJsonSource(
              "good-road-data", geoJson); //"published-data", geoJson);
          for (int i = 0; i < geoJson['features'].length; i++) {
            developer.log(
                "Good roads $i ${geoJson['features'][i]['properties']}",
                name: '_x_x_');
          }
        }
        var filter = fenceFilter(bounds: bounds, proportion: 0.6);
        _mapController!.setFilter("route-marker-layer", filter);
        _mapController!.setFilter("good_roads_highlighted", filter);
        _mapController!.setFilter("good-road-marker-layer", filter);
        _mapController!.setFilter("roads_highlighted", filter);
        await _mapController!.animateCamera(CameraUpdate.zoomBy(0.000001));
      } catch (e) {
        developer.log('error: ${e.toString()} ${geoJson.toString()}',
            name: '_ezoom');
      }
    }
  }

  onOpened(open) {
    //  _scrollController.jumpTo(12);
    if (!_opened) {
      _bottomDrawerController.dockOpenTile();
    }
    _opened = true;
    //  setState(() => ());
  }

  _onTap(var tap, LatLng pos) async {
    var foundFeatures;
    try {
      // var point = Point(tap.x.toDouble(), tap.y.toDouble());
      foundFeatures = await _mapController!
          .queryRenderedFeatures(tap, ["route-marker-layer"], null);
      if (foundFeatures.isNotEmpty) {
        var tappedFeature = foundFeatures.first;
        var name = tappedFeature['properties']['name'];
        String uri = tappedFeature['id'].substring(0, 32);

        _tripCards =
            _drivesRequest!.getTripTiles(openUri: uri, key: _scrollToKey);
        _bottomDrawerController.setContent(content: BottomDrawerItems.trip);
        //  cardsList(cards: _tripCards, controller: _scrollController));
        _bottomDrawerController.open(
            height: 300); // height of opened ExpandTile
        _opened = false;
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
          id.toString().contains('shield') ||
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

/*
  addGeoJson() async {
    var geoJson = await getGeoJson(zoom: 14);
    try {
      await _mapController!.setGeoJsonSource("published-data", geoJson);
    } catch (e) {
      String err = e.toString();
      debugPrint('error: $err');
    }
  }
*/
  Widget _handleMap() {
    return Stack(children: [
      MLMap(
        onUpdate: _onMapUpdate,
        onTap: _onTap,
        onIdle: _onIdle,
      ),
      if (_mapController != null)
        Positioned(
          right: 20,
          top: 22,
          child: HandleFabs(controller: _mapController!),
        ),
      CustomPaint(
        painter: HighlightPainter(
          boundary: mapSize(),
          proportion: 0.8,
          color: Colors.blueGrey,
        ),
      ),
      BottomDrawer(
        context: context,
        maxHeight: 200,
        //  content:
        //      _tripCards, //cardsList(cards: _tripCards, controller: _scrollController),
        controller: _bottomDrawerController,
        // scrollController: _scrollController,
        onOpened: onOpened,
      ),
    ]);
  }

  Size mapSize() {
    Size mapSize = Size(0, 0);
    final bnKeyContext = MapService().mapKey.currentContext;
    if (bnKeyContext != null) {
      RenderBox box = bnKeyContext.findRenderObject() as RenderBox;
      mapSize = Size(box.size.width, box.size.height);
    }
    return mapSize;
  }

  double getInitialZoom() {
    return 9.0;
  }

  onPointOfInterestRatingChanged(int value, int index) {
    putPointOfInterestRating('uri', value.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      // extendBodyBehindAppBar: true,
      backgroundColor: Colors.blue,
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      appBar: AppBar(
        key: _appBarKey,
        automaticallyImplyLeading: false,
        leading: LeadingWidget(
          controller: _leadingWidgetController,
          onMenuTap: (index) => _leadingWidget(_scaffoldKey.currentState),
        ),
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
      ),
      body: FutureBuilder<bool>(
        future: _dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
          } else if (snapshot.hasData) {
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
    final GlobalKey _topFabKey = GlobalKey();
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PlaceFinder(
          key: _topFabKey,
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
            controller.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(currentPosition.latitude, currentPosition.longitude),
              ),
            );
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
        FloatingActionButton(
          heroTag: 'location',
          onPressed: () async {
            try {
              await controller.setGeoJsonSource("route-data", {
                "type": "FeatureCollection",
                "features": [
                  {
                    "type": "Feature",
                    "geometry": {
                      "type": "Point",
                      "coordinates": [-0.520467, 51.453987]
                    },
                    "id": '0001',
                    "properties": {"item": "waypoint", "number": 1}
                  },
                  {
                    "type": "Feature",
                    "geometry": {
                      "type": "Point",
                      "coordinates": [-0.514, 51.46]
                    },
                    "id": '0002',
                    "properties": {"item": "waypoint", "number": 2}
                  }
                ]
              });
            } catch (e) {
              debugPrint("error ${e.toString()}");
            }
          },
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  double getPadding({required GlobalKey<State<StatefulWidget>> key}) {
    var box = key.currentContext!.findRenderObject() as RenderBox;
    return box.localToGlobal(Offset.zero).dy;
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
