import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
// import 'package:universal_io/universal_io.dart';
import 'package:universal_io/universal_io.dart';
import 'dart:developer' as developer;
import '/models/other_models.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import 'package:flutter/material.dart' hide Route;
// import 'package:latlong2/latlong.dart';
import '/classes/route.dart';
import 'package:hive/hive.dart';

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

Future<Directory> getCache() async {
  Directory cacheDirectory = Directory('${Setup().appDocumentDirectory}/cache');
  if (!await cacheDirectory.exists()) {
    await Directory('${Setup().appDocumentDirectory}/cache').create();
  }
  return cacheDirectory;
}

/// ImageRepository is able to provide all images and keep them in a cache. The images come from
/// 3 sources:
/// 1 Assets for displaying images when not on-line.
/// 2 Hive LazyBox with a key of the trip id + photo No for CurrentTripItem and MyTrips()
///   The key is in the form uuid_#
/// 3 Images from the API for the Web version and API originating data.

class ImageRepository {
  final Map<String, Uint8List> _imageCache = {};
  bool openBox;
  ImageRepository({this.openBox = true});
  late final LazyBox _imageBox;
  bool boxOpen = false;

  FutureOr<Map<String, Image>> loadImage({
    String? key,
    int id = -1,
    String uri = '',
    double width = 100,
    Uint8List? bytes,
  }) async {
    if (openBox && !boxOpen) {
      boxOpen = await openHive();
    }

    key ??= getFileName(url: uri);
    key = key.isNotEmpty ? key : getFileName(url: uri);

    if (!_imageCache.containsKey(key) && key.length == 32) {
      Uint8List? imageBytes;
      if (_imageBox.containsKey(key)) {
        imageBytes = await _imageBox.get(key);
      } else if ((bytes ?? []).isNotEmpty) {
        try {
          await _imageBox.put(key, bytes);
          imageBytes = bytes;
        } catch (e) {
          developer.log('Error writing to _imageBox: ${e.toString()}',
              name: 'error');
        }
      }
      // Not in Hive - try the url below rather than failing on a null
      if (imageBytes != null) {
        _imageCache[key] = imageBytes;
      }
    }
    if (!_imageCache.containsKey(key)) {
      if (uri.isNotEmpty && uri.contains('assets')) {
        final ByteData bytes = await rootBundle.load(uri);
        _imageCache[key] = bytes.buffer.asUint8List();
      } else if (uri.isNotEmpty && bytes == null) {
        _imageCache[key] = await getImageBytes(url: uri);
      } else if (bytes != null) {
        // allow the bytes to be held for the Web version - they will be written away later
        _imageCache[key] = bytes;
      }
    }

    if (!_imageCache.containsKey(key)) {
      // Nowhere to be found - show the missing image placeholder
      return {
        key: Image.memory(Uint8List(0),
            errorBuilder: (context, error, stackTrace) =>
                const ImageMissing(width: 30))
      };
    }
    return {key: Image.memory(_imageCache[key]!)};
  }

  Future<bool> openHive() async {
    _imageBox = await Hive.openLazyBox('images');
    return true;
  }

  /// An image's bytes from the cache or Hive, or null if it isn't stored -
  /// e.g. to upload it when a trip is published. (loadImage() expects the
  /// image to be there.)
  Future<Uint8List?> imageBytes(String key) async {
    if (_imageCache.containsKey(key)) {
      return _imageCache[key];
    }
    if (key.length != 32) return null;
    if (!boxOpen) {
      boxOpen = await openHive();
    }
    if (!_imageBox.containsKey(key)) return null;
    dynamic bytes = await _imageBox.get(key);
    if (bytes is Uint8List) return bytes;
    if (bytes is List) return Uint8List.fromList(bytes.cast<int>());
    return null;
  }

  /// Removes an image from Hive, e.g. when its point of interest is deleted.
  /// Only Hive keys (32 characters) are stored there.
  Future<void> deleteImage(String key) async {
    if (key.length != 32) return;
    if (!boxOpen) {
      boxOpen = await openHive();
    }
    _imageCache.remove(key);
    await _imageBox.delete(key);
  }

  Uint8List getBytes({String key = ''}) {
    Uint8List? bytes = _imageCache[key];
    return bytes ?? Uint8List(0);
  }

  clear() {
    _imageCache.clear();
  }
}

Widget displayLocalImage(String imageId) {
  return FutureBuilder(
    future: Hive.openLazyBox('webImagesBox').then((box) => box.get(imageId)),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        final Uint8List bytes = snapshot.data as Uint8List;
        return Image.memory(bytes);
      }
      return const CircularProgressIndicator(); // Loading placeholder
    },
  );
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

Future<void> saveLocalImage(String imageId, Uint8List image) async {
  var imageBox = await Hive.openLazyBox('imageBox');
  imageBox.put(imageId, image);
}

Future<Uint8List> getLocalImage(String imageId) async {
  var imageBox = await Hive.openLazyBox('imageBox');
  return await imageBox.get(imageId);
}
