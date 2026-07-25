import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
// import 'package:geolocator/geolocator.dart';
import '/services/services.dart';
// import '/classes/classes.dart' hide Position;
import '/constants.dart';
import 'dart:developer' as developer;
// import '/classes/classes.dart' hide Position;
import '/models/other_models.dart';
import 'dart:collection';
import 'dart:async';
import 'dart:math';
// import 'dart:developer' as developer;

const apiKey = "VEmtdNyruRLF2YvVedde";
const styleUrl = "https://api.maptiler.com/maps/streets-v2/style.json";
/*

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MLMap();
  }
}
*/
/// The challenge with MapLibreMaps is that the style must be loaded before anything else happens.
/// MapLibreMaps provides a callBack that tell the calling page that all is ready to go.
///
/*
class MLMapControllerOld extends ChangeNotifier {
  _MLMapState? _mlMapState;
  void _addState(mlMapState) {
    _mlMapState = mlMapState;
  }

//  LatLngBounds bounds = await _mapController!.getVisibleRegion();
  Future<LatLngBounds> getVisibleRegion() async {
    return await _mlMapState!.getVisibleRegion();
  }

  bool get mapLoaded => _mlMapState != null && (_mlMapState!._mapLoaded);

  CameraPosition get cameraPosition => _mlMapState != null
      ? _mlMapState!._mapLibreController!.cameraPosition!
      : CameraPosition(target: LatLng(0, 0));

// onMapCreated(MapLibreMapController controller)

  // this.onMapCreated = _mlMapState._onMapCreated();

  setGeoJsonSource(source, geoJson) {
    _mlMapState!._mapLibreController!.setGeoJsonSource(source, geoJson);
  }

  animateCamera(update, {duration = 0}) {
    _mlMapState!._mapLibreController!.animateCamera(update, duration: duration);
  }

  moveCamera(update) {
    _mlMapState!._mapLibreController!.moveCamera(update);
  }

  queryRenderedFeatures(point, layerIds, filter) {
    developer.log('queryRenderedFeatures ', name: 'controller');
    _mlMapState!._mapLibreController!
        .queryRenderedFeatures(point, layerIds, filter);
  }

  queryRenderedFeaturesInRect(rect, layerIds, filter) {
    _mlMapState!._mapLibreController!
        .queryRenderedFeaturesInRect(rect, layerIds, filter);
  }

  setFilter(layer, filter) {
    _mlMapState!._mapLibreController!.setFilter(layer, filter);
  }

  getLayerIds() {
    _mlMapState!._mapLibreController!.getLayerIds();
  }

  takeSnapshot() {
    _mlMapState!._mapLibreController!.takeSnapshot();
  }

  toScreenLocation(latLng) {
    _mlMapState!._mapLibreController!.toScreenLocation(latLng);
  }

  updateMyLocationTrackingMode(newMode) {
    _mlMapState!._mapLibreController!.updateMyLocationTrackingMode(newMode);
  }
*/
/// Because the MapLibreMap is going to be a persistent widget, more than one screen
/// needs to be notified of the maps updates. This is done using the ChangeNotifier
/// pattern. The map notifies the controller, that then broadcasts the change to
/// any widget that's listening.
/*
    this.onIdle,
    this.onTap,
    this.onUpdate,
    this.onMove,
    this.onStyleLoaded,
    this.onLocationUpdated,
 */
/*
  VoidCallback? onIdle;
  ValueChanged<Map>? onTap;

  VoidCallback? onMapReady;
  void mapReady({VoidCallback? action}) {
    developer.log(
        'maplibre_map.dart controller.mapReady called passed up from MLMap()._onMapCreated()',
        name: '_map_');

    onMapReady = action;
    notifyListeners();
  }

  ValueChanged<CameraPosition>? onMove;
  VoidCallback? onStyleLoaded;
  ValueChanged<UserLocation>? onLocationUpdated;

  bool get isAttached => _mlMapState != null;
}
*/
/*
class MLMap extends StatefulWidget {
  Function(LatLng, MLMapController)? onUpdate;
  MLMapController? mapController;
  // MLMapController? controller;
  Function(Point, LatLng)? onTap;
  Function()? onIdle;
  Function(UserLocation)? onLocationUpdated;
  Function(CameraPosition)? onMove;
  Function()? onStyleLoaded;
  bool? debug;
  bool? showLocation;
  // Key? key; this.key,
  MLMap({
    super.key,
    bool? debug,
    bool? showLocation,
    this.onIdle,
    this.onTap,
    this.onUpdate,
    this.onMove,
    this.onStyleLoaded,
    this.onLocationUpdated,
    this.mapController,
    //  this.controller,
  })  : debug = debug ?? false,
        showLocation = showLocation ?? true;

  @override
  State createState() => _MLMapState();
}

class _MLMapState extends State<MLMap> {
  @override
  void initState() {
    super.initState();
    developer.log('_MLMap instantiated - initState() called', name: '_map_');
    if (widget.mapController != null) {
      widget.mapController!._addState(this);
    }
  }

  MapLibreMapController? _mapLibreController;
  bool _mapLoaded = false;

  /// There is a bit of a problem because _onMapCreated allows
  /// access of the MapLibreMapController, which until it does
  /// is unavailable

  void _onMapCreated(MapLibreMapController controller) async {
    try {
      developer.log('_MLMap  - _onMapCreated() called', name: '_map_');
      // MapService().controller = widget.mapController;
      //  Setup().mlMapController = mlController;
      _mapLibreController = controller;
      // widget.mapController = mlController;
      // Setup().mlMapController = widget.mapController;

      _mapLoaded = true;

      /// .call() inside a class allows that class to be called like a function
      ///
      /// class CallTest {
      ///    String call(String a, String b);
      /// }
      ///
      /// CallTest()('this is a ', 'this is b');   will return 'this is a this is b'
      ///
      /// Check here the status of the two map controllers.
      // Setup().mlMapController!.onMapReady!.call();
      /*
      if (widget.onUpdate != null) {
        widget.onUpdate!(MapService().currentPosition, mlController);
      }
      */
      developer.log(
          'maplibre_map.dart _onMapCreated() called about to pass up to controller',
          name: '_map_');
      //  if (widget.mapController != null) {
      //    widget.mapController!.onMapReady!.call();
      //  }
    } catch (e) {
      developer.log(
          'Error ${e.toString()} in maplibre_map.dart _onMapCreated()',
          name: '_map_');
    }
  }

  void _onStyleLoaded() {
    if (widget.onStyleLoaded != null) {
      developer.log('_MLMap  - _onStyleLoaded() called', name: '_map_');
      widget.onStyleLoaded!();
      widget.mapController!.onStyleLoaded!.call();
    }
  }

  void _onLocationUpdated(UserLocation newLocation) {
    if (widget.onLocationUpdated != null) {
      widget.onLocationUpdated!(newLocation);
      widget.mapController!.onLocationUpdated!.call(newLocation);
    }
  }

  // MapLibreMapController? get controller => MapService().controller;

  void _onTap(Point<double> point, LatLng coordinates) async {
    widget.onTap!(point, coordinates);
    widget.mapController!.onTap!
        .call({'point': point, 'coordinates': coordinates});
  }

  void _onCameraIdle() async {
    widget.onIdle!();
    widget.mapController!.onIdle!.call();
  }

  void _onMove(CameraPosition position) async {
    if (widget.debug ?? false) {
      widget.onMove!(position);
      widget.mapController!.onMove!.call(position);
    }
  }

  Future<LatLngBounds> getVisibleRegion() async {
    if (_mapLibreController != null) {
      return await _mapLibreController!.getVisibleRegion();
    } else {
      return LatLngBounds(southwest: LatLng(0, 0), northeast: LatLng(0, 0));
    }
  }

  //https://pub.dev/documentation/maplibre_gl/latest/maplibre_gl/

  @override
  Widget build(BuildContext context) {
    developer.log('_MLMap build  called', name: '_map_');
    return Scaffold(
      body: FutureBuilder<String>(
        future: MapService().style,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Error getting style ${snapshot.error}');
          } else if (snapshot.hasData) {
            developer.log('_MLMap snapshot.hasData', name: '_map_');
            return MapLibreMap(
              key: MapService().mapKey, // <-- Stops the map being reinitialised
              styleString: snapshot.data!,
              myLocationEnabled: (widget.showLocation ??
                  true), // Should only have this in debugging mode
              compassViewPosition: kIsWeb ? null : CompassViewPosition.topLeft,
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              onUserLocationUpdated: _onLocationUpdated,
              initialCameraPosition: CameraPosition(
                  target: MapService().currentPosition, // LatLng(51.4, -0.5),
                  zoom: 13), // MapService().currentPosition, zoom: 11),
              trackCameraPosition: true, // ensures that zoom is updated
              onCameraMove: _onMove,
              onMapClick: _onTap,
              onCameraIdle: _onCameraIdle,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer()),
                Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer())
              },
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
          throw ('Error loading the map style.');
        },
      ),
    );
  }

  // style:
  String type = "fill";

  Future<String> mapStyle({String map = ''}) async {
    if (map == '') {
      return getStyle(url: urlTiler);
    } else {
      return getStyle(url: urlTilerMapLibre);
    }
  }
}*/
/// Test map from the publishers
///

// FIXME: Be sure to set your own API key here. You can register for a free one at https://client.stadiamaps.com/.

enum OfflineDataState { unknown, downloaded, downloading, notDownloaded }

class DemoMap extends StatefulWidget {
  const DemoMap({super.key});
  @override
  State createState() => DemoMapState();
}

class DemoMapState extends State<DemoMap> {
  MapLibreMapController? mapController;
  static const clusterLayer = "clusters";
  static const unclusteredPointLayer = "unclustered-point";

  OfflineDataState offlineDataState = OfflineDataState.unknown;
  double? downloadProgress;

  @override
  void dispose() {
    //  mapController?.onFeatureTapped.remove(_onFeatureTapped);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) async {
    mapController = controller;

    // Event listener that fires for the cluster layer (not due to an explicit
    // filter; only a consequence of the current mix of layers used).
    // controller.onFeatureTapped.add(_onFeatureTapped);

    // Determine if we have data stored offline. Note that this is a fairly
    // crude check, and if you are dealing with multiple styles or regions,
    // you will want to do something a bit more advanced.
    final result = await getListOfRegions();
    setState(() {
      if (result.isEmpty) {
        offlineDataState = OfflineDataState.notDownloaded;
      } else {
        offlineDataState = OfflineDataState.downloaded;
      }
    });
  }

  void _onStyleLoadedCallback() async {
    const sourceId = "locations";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Style loaded"),
      backgroundColor: Theme.of(context).primaryColor,
      duration: const Duration(seconds: 1),
    ));

    // Alternate form when using hard-coded local data; load this however you like
    // await addClusteredPointSource(sourceId, {
    //   "type": "FeatureCollection",
    //   "features": [
    //     {
    //       "type": "Feature",
    //       "geometry": {
    //         "type": "Point",
    //         "coordinates": [-77.03238901390978, 38.913188059745586]
    //       },
    //       "properties": {"title": "Washington, DC"}
    //     },
    //     {
    //       "type": "Feature",
    //       "geometry": {
    //         "type": "Point",
    //         "coordinates": [-122.414, 37.776]
    //       },
    //       "properties": {"title": "San Francisco"}
    //     }
    //   ]
    // });
    //  await addClusteredPointSource(sourceId,
    //      "https://maplibre.org/maplibre-gl-js/docs/assets/earthquakes.geojson");
    //  await addClusteredPointLayers(sourceId);
  }
/*
MyLocationTrackingMode.None: The map stays where it is; the dot moves. (Best for "Explore" mode).

MyLocationTrackingMode.Follow: The map centers on the user as they move.

MyLocationTrackingMode.Follow_and_Bearing: The map centers on the user and rotates so the direction they are facing is always "up." (Best for active driving/navigation).

*/

/*   Point<double> point,
  LatLng coordinates,
  String id,
  String layerId,*/
  // Logic for interacting with clusters on iOS.
  // See bug report: https://github.com/m0nac0/flutter-maplibre-gl/issues/160
  ///void _onFeatureTapped(LatLng coords, String id, String layerId) async {
  //  dynamic featureId, Point<double> point, LatLng coords) async {
  ///  var features =
  ///      await mapController?.queryRenderedFeatures(point, [clusterLayer], null);
  ///  if (features?.isNotEmpty ?? false) {
  // Naive zoom += 2. There is a `getClusterExpansionZoom` method
  // on sources, but the Flutter wrapper does not actually expose
  // sources at the moment so we're just falling back to a simple
  // approach.
  ///    mapController!.animateCamera(CameraUpdate.newLatLngZoom(
  ///        coords, mapController!.cameraPosition!.zoom + 2));
  ///  }
  ///}

  // This method handles interaction with the actual earthquake points on iOS.
  // See bug report: https://github.com/m0nac0/flutter-maplibre-gl/issues/160
  void _onMapClick(Point<double> point, LatLng coordinates) async {
    var messenger = ScaffoldMessenger.of(context);
    var color = Theme.of(context).primaryColor;

    var features = await mapController?.queryRenderedFeatures(
        point, [unclusteredPointLayer], null);
    if (features?.isNotEmpty ?? false) {
      var feature = HashMap.from(features!.first);
      messenger.showSnackBar(SnackBar(
        content: Text("Magnitude ${feature["properties"]["mag"]} earthquake"),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  // Adds a data source to the map via a GeoJSON layer. The data is assumed
  // to be a PointCollection
  Future<void>? addClusteredPointSource(String sourceId, Object? data) {
    return mapController?.addSource(
        sourceId, GeojsonSourceProperties(data: data, cluster: true));
  }

  Future<void> addClusteredPointLayers(String sourceId) async {
    await mapController?.addCircleLayer(
        sourceId,
        clusterLayer,
        const CircleLayerProperties(circleColor: [
          "step",
          ["get", "point_count"],
          "#51bbd6",
          100,
          "#f1f075",
          750,
          "#f28cb1"
        ], circleRadius: [
          "step",
          ["get", "point_count"],
          20,
          100,
          30,
          750,
          40
        ]),
        filter: ["has", "point_count"]);

    await mapController?.addSymbolLayer(
        sourceId,
        "cluster-count",
        const SymbolLayerProperties(
            // NOTE: I would expect to be able to do something like "{point_count_abbreviated}", but this breaks on Android
            textField: [Expressions.get, "point_count_abbreviated"],
            textFont: ["Open Sans Regular"]),
        filter: ["has", "point_count"]);

    await mapController?.addCircleLayer(
        sourceId,
        unclusteredPointLayer,
        const CircleLayerProperties(
            circleColor: "#11b4da",
            circleRadius: 8,
            circleStrokeWidth: 1,
            circleStrokeColor: "#fff"),
        filter: [
          "!",
          ["has", "point_count"]
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    switch (offlineDataState) {
      case OfflineDataState.downloaded:
        child = const Icon(Icons.delete);
        break;
      case OfflineDataState.notDownloaded:
        child = const Icon(Icons.download_for_offline_outlined);
        break;
      case OfflineDataState.downloading:
      case OfflineDataState.unknown:
        // Indeterminate progress indicator
        child = CircularProgressIndicator(
          value: downloadProgress,
          color: Colors.white,
        );
        break;
    }

    final Widget? actionButton;
    if (kIsWeb) {
      // Offline tiles are not supported in the browser
      actionButton = null;
    } else {
      actionButton =
          FloatingActionButton(onPressed: _actionButtonPressed, child: child);
    }

    return Scaffold(
      body: MapLibreMap(
        styleString: _mapStyleUrl(),
        myLocationEnabled: true,
        initialCameraPosition: const CameraPosition(target: LatLng(0.0, 0.0)),
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoadedCallback,
        onMapClick: _onMapClick,
        trackCameraPosition: true,
      ),
      floatingActionButton: actionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  String _mapStyleUrl() {
    const styleUrl =
        "https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json";
    return "$styleUrl?api_key=$apiKey";
  }

  void _actionButtonPressed() async {
    switch (offlineDataState) {
      case OfflineDataState.downloaded:
        _deleteOfflineRegion();
        break;
      case OfflineDataState.notDownloaded:
        await _downloadOfflineRegion();
        break;
      case OfflineDataState.downloading:
      case OfflineDataState.unknown:
        return;
    }
  }

  Future<OfflineRegion?> _downloadOfflineRegion() async {
    setState(() {
      offlineDataState = OfflineDataState.downloading;
    });

    try {
      // Bounding box around Manhattan. Note that this will consume
      // approximately 200 API credits.
      final bounds = LatLngBounds(
        southwest: const LatLng(40.69, -74.03),
        northeast: const LatLng(40.84, -73.86),
      );
      final regionDefinition = OfflineRegionDefinition(
          bounds: bounds, mapStyleUrl: _mapStyleUrl(), minZoom: 0, maxZoom: 14);
      final region = await downloadOfflineRegion(regionDefinition,
          metadata: {
            'name': 'Manhattan',
          },
          onEvent: _onDownloadEvent);

      return region;
    } on Exception catch (_) {
      setState(() {
        offlineDataState = OfflineDataState.notDownloaded;
        downloadProgress = null;
      });
      return null;
    }
  }

  void _onDownloadEvent(DownloadRegionStatus status) {
    // Event listener for download progress; MapLibre uses a repeated
    // callback API, and the download command, while async, completes early.
    if (status is Success) {
      setState(() {
        offlineDataState = OfflineDataState.downloaded;
        downloadProgress = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Manhattan Downloaded for Offline Use"),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 3),
      ));
    } else if (status is Error) {
      setState(() {
        offlineDataState = OfflineDataState.notDownloaded;
        downloadProgress = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Data Downloaded Failed!"),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ));
    } else if (status is InProgress) {
      setState(() {
        offlineDataState = OfflineDataState.downloading;
        downloadProgress = status.progress / 100;
      });
    }
  }

  void _deleteOfflineRegion() async {
    setState(() {
      offlineDataState = OfflineDataState.unknown;
    });

    final regions = await getListOfRegions();

    for (final region in regions) {
      // NOTE: The term "delete" here is a bit of a misnomer. From the docs:
      //
      // When you remove an offline pack, any resources that are required by
      // that pack, but not other packs, become eligible for deletion from
      // offline storage. Because the backing store used for offline storage
      // is also used as a general purpose cache for map resources, such
      // resources may not be immediately removed if the implementation
      // determines that they remain useful for general performance of the map.
      //
      // Ambient cache controls also exist, but these are not currently wrapped
      // for Flutter. This is not normally an issue, and the storage engine will
      // eventually clear these tiles out.
      //
      // Source: https://maplibre.org/maplibre-gl-native/ios/api/Classes/MGLOfflineStorage.html#/c:objc(cs)MGLOfflineStorage(im)removePack:withCompletionHandler:
      await deleteOfflineRegion(
        region.id,
      );
    }

    setState(() {
      offlineDataState = OfflineDataState.notDownloaded;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Offline data marked for removal"),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 1),
      ));
    }
  }
}
