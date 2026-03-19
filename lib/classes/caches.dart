import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:universal_io/universal_io.dart';
import 'package:universal_io/universal_io.dart';
import 'dart:developer' as developer;
import '/models/other_models.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import 'package:flutter/material.dart' hide Route;
// import 'package:latlong2/latlong.dart';
import '/classes/route.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
// import 'package:path_provider/path_provider.dart';

// import '/classes/classes.dart';

/// TripItemRepository handles the cache for TripItems in the Trips route
/// The [List<Feature>] initially hold the bare bones of the TripItems id, uri
/// When created it may hold several thousand lines and an index (row) is
/// added to each line that will be used to identify the cache entry.
/// When the map is zoomed a subset of the features will be created.
/// This subset will then use TripItemRepository to return the TripItem
/// from the cache if cached, from SQLite if saved or the API.
///

List<double> centerPoint({required List maxPoint, required List minPoint}) {
  return [
    minPoint[1] + ((maxPoint[1] - minPoint[1]) / 2),
    minPoint[0] + ((maxPoint[0] - minPoint[0]) / 2)
  ];
}

class TripItemRepository {
  final Map<int, TripItem?> _tripItemCache = {};
  TripItemRepository();
  FutureOr<TripItem> loadTripItem(
      {required int key,
      required int id,
      required String uri,
      zoom = 30}) async {
    if (!_tripItemCache.containsKey(key)) {
      if (!kIsWeb && id >= 0) {
        _tripItemCache[key] =
            await getPrivateRepository().loadTripItemLocal(id: id);
      } else if (uri.isNotEmpty) {
        _tripItemCache[key] = await getTrip(tripId: uri);
      } else {
        _tripItemCache[key] = TripItem(title: '');
      }
    } else {}
    //   debugPrint(fetched);
    return _tripItemCache[key]!;
  }

  clear() {
    _tripItemCache.clear();
  }
}

class PointOfInterestRepository {
  final Map<int, PointOfInterest> _pointOfInterestCache = {};
  PointOfInterestRepository();
  FutureOr<PointOfInterest?> loadPointOfInterest(
      {required int key,
      required int id,
      required String uri,
      zoom = 30}) async {
    // PointOfInterest pointOfIntest = PointOfInterest(markerPoint: MarkerPoint(), marker: marker)
    if (!_pointOfInterestCache.containsKey(key)) {
      if (id >= 0) {
        _pointOfInterestCache[key] =
            await getPrivateRepository().loadPointOfInterestLocal(id: id);
      } else if (uri.isNotEmpty) {
        _pointOfInterestCache[key] = await getPointOfInterest(uri: uri);
      } else {
        _pointOfInterestCache[key] = PointOfInterest(
            //    point: const [0, 0],
            ); //child1: const FeatureMarker());
      }
    }
    return _pointOfInterestCache[key]!;
  }

  clear() {
    _pointOfInterestCache.clear();
  }
}

/*

class OsmDataRepository {
  final Map<int, OsmAmenity> _osmAmenityCache = {};
  OsmDataRepository();
  FutureOr<OsmAmenity?> loadPointOfInterest(
      {required int key,
      required int id,
      required int osmId,
      zoom = 30}) async {
    // PointOfInterest pointOfIntest = PointOfInterest(markerPoint: MarkerPoint(), marker: marker)
    if (!_osmAmenityCache.containsKey(key)) {
      //  try {
      if (id >= 0) {
        _osmAmenityCache[key] =
            await getPrivateRepository().loadOsmAmenityLocal(id: id);
      } else if (osmId >= 0) {
        _osmAmenityCache[key] = await getOsmAmenity(osmId: osmId);
      } else {
        _osmAmenityCache[key] = OsmAmenity(
            position: const LatLng(0, 0), marker: const FeatureMarker());
      }
    } else {
      //   debugPrint('Point of obtained from cache');
    }
    //  debugPrint(fetched);
    return _osmAmenityCache[key]!;
  }

  clear() {
    _osmAmenityCache.clear();
  }

  load({required List<OsmAmenity> amenities, required CacheFence fence}) async {
    _osmAmenityCache.clear();
  }
}
*/

class RouteRepository {
  final Map<int, List<Route>?> _routeCache = {};
  RouteRepository();

  FutureOr<List<Route>?> loadRoute({
    required int key,
    required int id,
    required String uri,
  }) async {
    if (!_routeCache.containsKey(key)) {
      if (id >= 0 && !kIsWeb) {
        _routeCache[key] = await getPrivateRepository()
            .loadRoutesLocal(id, type: 0, driveKey: key);
      } else if (uri.isNotEmpty) {
        _routeCache[key] = await getDriveRoutes(driveUri: uri);
      } else {
        _routeCache[key] = [
          //       Route(points: [const []])
        ];
      }
    } else {
      //    debugPrint('Route returned from cache');
    }
    return _routeCache[key];
  }

  clear() {
    _routeCache.clear();
  }
}

class GoodRoadRepository {
  final Map<int, Route?> _goodRoadCache = {};
  GoodRoadRepository();

  FutureOr<Route?> loadGoodRoad({
    required int key,
    required int id,
    required String uri,
  }) async {
    if (!_goodRoadCache.containsKey(key)) {
      if (id >= 0) {
        _goodRoadCache[key] =
            await getPrivateRepository().loadPolyLineLocal(id, type: 1);
      } else if (uri.isNotEmpty) {
        _goodRoadCache[key] = await getRoute(uriString: uri, goodRoad: true);
      } else {
        //     _goodRoadCache[key] = Route(points: [
        //       const [0, 0]
        //     ]);
      }
    } else {
      //    debugPrint('GoodRoad returned from cache');
    }
    return _goodRoadCache[key];
  }

  clear() {
    _goodRoadCache.clear();
  }
}

/// TileRepository doesn't try to maintain a memory cache as the VectorTile class has a pretty good
/// cache, and it would only double the memory footprint.
/// This repository only stores tiles offline for patchy internet.

class TileRepository {
  final VectorTileProvider deligate;
  TileRepository({required this.deligate});
  FutureOr<Uint8List> loadTile({
    required TileIdentity tile,
    required int id,
    required String uri,
  }) async {
    Directory? cacheDirectory;
    cacheDirectory ??= await getCache();
    Uint8List? data = Uint8List.fromList([]);
    String key = '${tile.z}.${tile.x}.${tile.y}';
    File mapFile =
        File('${cacheDirectory.path}/_${tile.z}_${tile.x}_${tile.y}.pbf');
    bool tileExists = await mapFile.exists();
    if (tileExists) {
      data = await mapFile.readAsBytes();
      developer.log('map got from file $key', name: '__map');
    } else {
      data = await deligate.provide(tile);
      await mapFile.writeAsBytes(data);
    }
    return data;
  }
}

Future<Directory> getCache() async {
  Directory cacheDirectory = Directory('${Setup().appDocumentDirectory}/cache');
  if (!await cacheDirectory.exists()) {
    await Directory('${Setup().appDocumentDirectory}/cache').create();
  }
  return cacheDirectory;
}

class ImageRepository {
  final Map<int, Image> _imageCache = {};
  ImageRepository();

  FutureOr<Map<int, Image>> loadImage({
    required int key,
    required int id,
    required String uri,
    double width = 100,
  }) async {
    if (!_imageCache.containsKey(key)) {
      key = _imageCache.length;
      //   isEmpty ? 0 : _imageCache.keys.last + 1;
      if (id >= 0 && !kIsWeb) {
        _imageCache[key] = await localImageFromBytes(id: id);
        //   debugPrint('Image returned from local database');
      } else if (uri.isNotEmpty && uri.contains('assets')) {
        _imageCache[key] = Image.asset(uri);
        //  debugPrint('Image returned from assets');
      } else if (uri.isNotEmpty) {
        _imageCache[key] = await webImageFromBytes(url: uri);
        //   debugPrint('Image returned from web');
      }
    } else {
      //   debugPrint('Image returned from cache');
    }
    return {key: _imageCache[key]!};
  }

  clear() {
    _imageCache.clear();
  }
}

Future<Image> webImageFromBytes({required String url}) async {
  Uint8List imageBytes = await getImageBytes(url: url);
  return Image.memory(imageBytes);
}

Future<Image> localImageFromBytes({required int id}) async {
  Uint8List? imageBytes =
      await getPrivateRepository().loadImageByIdLocal(id: id);
  return Image.memory(imageBytes!);
}
