// import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
// import 'package:flutter_map/flutter_map.dart';
// import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/classes/classes.dart';

/// TripItemRepository handles the cache for TripItems in the Trips route
/// The List<Feature> initially hold the bare bones of the TripItems id, uri
/// When created it may hold several thousand lines and an index (row) is
/// added to each line that will be used to identify the cache entry.
/// When the map is zoomed a subset of the features will be created.
/// This subset will then use TripItemRepository to return the TripItem
/// from the cache if cached, from SQLite if saved or the API.

class TripItemRepository {
  final Map<int, TripItem?> _tripItemCache = {};
  TripItemRepository();

  Future<TripItem?> loadTripItem(
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
    }

    //_tripItemCache[key].
    return _tripItemCache[key];
  }
}

class RouteRepository {
  final Map<int, List<mt.Route>> _routeCache = {};
  RouteRepository();

  Future<List<mt.Route>?> loadRoute({
    required int key,
    required int id,
    required String uri,
  }) async {
    if (!_routeCache.containsKey(key)) {
      if (id >= 0) {
        _routeCache[key] = await loadRoutesLocal(id, type: 0);
      } else if (uri.isNotEmpty) {
        _routeCache[key] = await getPolylines(uri);
      } else {
        _routeCache[key] = [
          mt.Route(points: [const LatLng(0, 0)])
        ];
      }
    }
    return _routeCache[key];
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
    }
    return _goodRoadCache[key];
  }
}

class ImageRepository {
  final Map<int, Image> _imageCache = {};
  ImageRepository();

  Map<int, Image> loadImage({
    required int key,
    required int id,
    required String uri,
    double width = 100,
  }) {
    if (!_imageCache.containsKey(key)) {
      if (_imageCache.isNotEmpty) {
        key = _imageCache.keys.last + 1;
      } else {
        key = 0;
      }
      if (id >= 0) {
        _imageCache[key] = getImage(id: id, width: width);
        //  LocalImage(id: id).getImage(); // loadImageByIdLocal(id: id);
      } else if (uri.isNotEmpty && uri.contains('assets')) {
        _imageCache[key] = getAssetImage(uri: uri);
        //  Image.asset(uri).toByteData(format: ImageByteFormat.png);
      } else if (uri.isNotEmpty) {
        _imageCache[key] = getWebImage(url: uri);
        /*
        _imageCache[key] = Image.network(
          uri,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
            
          },
          errorBuilder:
              (BuildContext context, Object exception, StackTrace? stackTrace) {
            return ImageMissing(width: width);
          },
        );
        */

        // _imageCache[key] = Image.memory(await getImageBytes(url: uri));
        // final pngByteData = await image.toByteData(format: ImageByteFormat.png);
      } else {
        // _imageCache[key] = Icon(Icons.no_photography)
      }
    }
    return {key: _imageCache[key]!};
  }
}

getImage({required int id, double width = 50}) {
  return FutureBuilder(
    future: localImageFromBytes(id: id),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ImageMissing(width: width);
      } else if (snapshot.hasData) {
        return snapshot.data!;
      } else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    },
  );
}

getAssetImage({required String uri, double width = 50}) {
  return FutureBuilder(
    future: rootBundle.load(uri),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ImageMissing(width: width);
      } else if (snapshot.hasData) {
        return snapshot.data as Image;
      } else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    },
  );
}

getWebImage({required String url, double width = 50}) {
  return FutureBuilder(
    future: webImageFromBytes(url: url),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ImageMissing(width: width);
      } else if (snapshot.hasData) {
        return snapshot.data!;
      } else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    },
  );
}

Future<Image> webImageFromBytes({required String url}) async {
  Uint8List imageBytes = await getImageBytes(url: url);
  return Image.memory(imageBytes);
}

Future<Image> localImageFromBytes({required int id}) async {
  Uint8List? imageBytes = await loadImageByIdLocal(id: id);
  return Image.memory(imageBytes!);
}

/*
getImageBytes({required String url})

      Uint8List? pngBytes = Uint8List.fromList([]);
      if (_driveUri.isEmpty) {
        final byteData =
            await _mapImage.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData?.buffer.asUint8List();
      } else {
        String url =
            Uri.parse('$urlDrive/images/$_driveUri/map.png').toString();
        pngBytes = await wh.getImageBytes(url: url);
*/