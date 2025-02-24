import 'dart:typed_data';
// import 'package:drives/constants.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';

// import 'package:flutter_map/flutter_map.dart';
// import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:drives/classes/route.dart' as mt;
// import 'package:drives/classes/classes.dart';

/// TripItemRepository handles the cache for TripItems in the Trips route
/// The List<Feature> initially hold the bare bones of the TripItems id, uri
/// When created it may hold several thousand lines and an index (row) is
/// added to each line that will be used to identify the cache entry.
/// When the map is zoomed a subset of the features will be created.
/// This subset will then use TripItemRepository to return the TripItem
/// from the cache if cached, from SQLite if saved or the API.
///
/*
class Feature extends Marker {
  final int row;
  final String uri;
  final int id;
  final int featureId;
  final int type;
  final Function ontap;
  //final double width;
  // final double height;
  final Color iconColor;
  // late IconButton super.child;

  Feature(
      {this.row = -1,
      this.uri = '',
      this.id = -1,
      this.featureId = -1,
      this.type = 0,
      required this.ontap,
      super.point = const LatLng(-50.0, -0.2),
      double height = 30,
      double width = 30,
      double iconSize = 30,
      this.iconColor = Colors.red})
      : super(
            width: width,
            height: height,
            child: FeatureMarker(
                index: id, width: width, color: iconColor, angle: 0));

  factory Feature.fromMap(
      {required Map<String, dynamic> map,
      int row = -1,
      double size = 30,
      required Function onTap}) {
    return Feature(
      row: row == -1 ? map['row'] ?? -1 : row,
      uri: map['uri'],
      id: map['id'] ?? -1,
      featureId: map['feature_id'] ?? -1,
      type: map['type'] ?? 0,
      point: LatLng(map['lat'] ?? 50.0, map['lng'] ?? 0.0),
      width: size,
      height: size,
      ontap: onTap,
      iconColor: pinColours[map['type']],
    );
  }

  toMap() {
    return {
      'row': row,
      'id': id,
      'uri': uri,
      'feature_id': id,
      'type': type,
      'latitude': point.latitude,
      'longitude': point.longitude
    };
  }
*/
/*
class DriveCacheItem extends Marker {
  final int cacheKey;
  final int id;
  final String uri;
  final LatLng northEast;
  final LatLng southWest;
  final Color iconColor;
  // final double height;
  // final double width;
  final double iconSize;
  DriveCacheItem(
      {super.point = ukSouthWest,
      super.height = 30,
      super.width = 30,
      this.northEast = ukNorthEast,
      this.southWest = ukSouthWest,
      this.cacheKey = -1,
      this.id = -1,
      this.uri = '',
      this.iconColor = Colors.red,
      this.iconSize = 30,
      FeatureMarker? marker})
      : super(
            child: marker ??
                FeatureMarker(
                    index: id, width: width, color: iconColor, angle: 0));

  factory DriveCacheItem.fromMap(
      {required Map<String, dynamic> map,
      int cacheKey = -1,
      //  double width = 30,
      double size = 30,
      double iconSize = 30,
      Color iconColor = Colors.red}) {
    LatLng northEast = LatLng(map['max_lat'] ?? 50.0, map['max_lng'] ?? 0.0);
    LatLng southWest = LatLng(map['min_lat'] ?? 50.0, map['min_lng'] ?? 0.0);
    return DriveCacheItem(
      cacheKey: cacheKey,
      point: centerPoint(maxPoint: northEast, minPoint: southWest),
      northEast: northEast,
      southWest: southWest,
      uri: map['uri'],
      id: map['id'] ?? -1,
      width: size,
      height: size,
      iconSize: iconSize,
      iconColor: iconColor,
    );
  }
/*
  factory Feature.fromMap(
      {required Map<String, dynamic> map,
      int row = -1,
      double size = 30,
      required Function onTap}) {
    return Feature(
      row: row == -1 ? map['row'] ?? -1 : row,
      uri: map['uri'],
      id: map['id'] ?? -1,
      featureId: map['feature_id'] ?? -1,
      type: map['type'] ?? 0,
      point: LatLng(map['lat'] ?? 50.0, map['lng'] ?? 0.0),
      width: size,
      height: size,
      ontap: onTap,
      iconColor: pinColours[map['type']],
    );
  }
*/

  toMap({int row = -1, int type = 0}) {
    return {
      'row': row,
      'id': id,
      'uri': uri,
      'feature_id': id,
      'type': type,
      'latitude': point.latitude,
      'longitude': point.longitude
    };
  }

  bool inScope({required Fence fence}) {
    Fence bounds = Fence(northEast: northEast, southWest: southWest);
    return containsBounds(fence: fence, bounds: bounds);
  }
}

*/

LatLng centerPoint({required LatLng maxPoint, required LatLng minPoint}) {
  return LatLng(
      minPoint.latitude + ((maxPoint.latitude - minPoint.latitude) / 2),
      minPoint.longitude + ((maxPoint.longitude - minPoint.longitude) / 2));
}

class TripItemRepository {
  final Map<int, TripItem?> _tripItemCache = {};
  TripItemRepository();
  Future<TripItem> loadTripItem(
      {required int key,
      required int id,
      required String uri,
      zoom = 30}) async {
    if (!_tripItemCache.containsKey(key)) {
      if (id >= 0) {
        _tripItemCache[key] = await loadTripItemLocal(id: id);
      } else if (uri.isNotEmpty) {
        _tripItemCache[key] = await getTrip(tripId: uri);
      } else {
        _tripItemCache[key] = TripItem(heading: '');
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
  Future<PointOfInterest?> loadPointOfInterest(
      {required int key,
      required int id,
      required String uri,
      zoom = 30}) async {
    // PointOfInterest pointOfIntest = PointOfInterest(markerPoint: MarkerPoint(), marker: marker)
    if (!_pointOfInterestCache.containsKey(key)) {
      //  try {
      if (id >= 0) {
        _pointOfInterestCache[key] = await loadPointOfInterestLocal(id: id);
      } else if (uri.isNotEmpty) {
        _pointOfInterestCache[key] = await getPointOfInterest(uri: uri);
      } else {
        _pointOfInterestCache[key] = PointOfInterest(
            markerPoint: const LatLng(0, 0), marker: const FeatureMarker());
      }
    } else {}
    //  debugPrint(fetched);
    return _pointOfInterestCache[key]!;
  }

  clear() {
    _pointOfInterestCache.clear();
  }
}

class RouteRepository {
  final Map<int, List<mt.Route>?> _routeCache = {};
  RouteRepository();

  Future<List<mt.Route>?> loadRoute({
    required int key,
    required int id,
    required String uri,
  }) async {
    if (!_routeCache.containsKey(key)) {
      if (id >= 0) {
        _routeCache[key] = await loadRoutesLocal(id, type: 0, driveKey: key);
      } else if (uri.isNotEmpty) {
        _routeCache[key] = await getDriveRoutes(driveUri: uri);
      } else {
        _routeCache[key] = [
          mt.Route(points: [const LatLng(0, 0)], driveKey: key)
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
  final Map<int, mt.Route?> _goodRoadCache = {};
  GoodRoadRepository();

  Future<mt.Route?> loadGoodRoad({
    required int key,
    required int id,
    required String uri,
  }) async {
    if (!_goodRoadCache.containsKey(key)) {
      if (id >= 0) {
        _goodRoadCache[key] = await loadPolyLineLocal(id, type: 1);
      } else if (uri.isNotEmpty) {
        _goodRoadCache[key] = await getRoute(uriString: uri, goodRoad: true);
      } else {
        _goodRoadCache[key] = mt.Route(points: [const LatLng(0, 0)]);
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

class ImageRepository {
  final Map<int, Image> _imageCache = {};
  ImageRepository();

  Future<Map<int, Image>> loadImage({
    required int key,
    required int id,
    required String uri,
    double width = 100,
  }) async {
    if (!_imageCache.containsKey(key)) {
      key = _imageCache.length;
      //   isEmpty ? 0 : _imageCache.keys.last + 1;
      if (id >= 0) {
        _imageCache[key] = await localImageFromBytes(id: id);
        debugPrint('Image returned from local database');
      } else if (uri.isNotEmpty && uri.contains('assets')) {
        _imageCache[key] = Image.asset(uri);
        debugPrint('Image returned from assets');
      } else if (uri.isNotEmpty) {
        _imageCache[key] = await webImageFromBytes(url: uri);
        debugPrint('Image returned from web');
      }
    } else {
      debugPrint('Image returned from cache');
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
  Uint8List? imageBytes = await loadImageByIdLocal(id: id);
  return Image.memory(imageBytes!);
}
