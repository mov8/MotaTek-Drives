import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '/classes/classes.dart';
import '/constants.dart';

/// Offline maps (phones only - the map engine keeps them; the web can't):
/// the map along a saved trip, kept on the phone to follow it where there's
/// no signal. Routing, AI assist and messages still need the Internet.
///
/// Only along a trip, never a whole area, so nobody downloads half the
/// country from Drives' tile server: the route is cut into stretches
/// (stretchKm), and each stretch's box - with marginKm either side - is
/// downloaded at minZoom to maxZoom, the tiles' most detailed (the map draws
/// closer zooms from them). A trip's download is capped at mostTiles - about
/// 600 km of route (a day's drive is a few hundred tiles) - and the phone's
/// at mostOnPhone, about ten long trips, so a region can't be built up from
/// many.
///
/// Each box is a region in the map engine's offline store, with the trip's
/// uri in its metadata, so a trip's regions are listed, sized and deleted
/// together.
class OfflineMapsService extends ChangeNotifier {
  static final OfflineMapsService _instance = OfflineMapsService._internal();
  factory OfflineMapsService() => _instance;
  OfflineMapsService._internal();

  static const double minZoom = 6;
  static const double maxZoom = 13; // the tile server's most detailed
  static const int mostTiles = 2000; // a trip's, at most
  static const int mostOnPhone = 20000; // every trip's, together
  static const double stretchKm = 10;
  static const double marginKm = 2;

  List<OfflineRegion> _regions = [];
  final Map<String, double> downloading = {}; // trip uri -> 0 to 1
  final Map<String, int> _sizes = {}; // trip uri -> bytes

  bool get supported => !kIsWeb;

  /// The regions in the offline store, and each trip's size
  Future<void> load() async {
    if (!supported) return;
    try {
      _regions = await getListOfRegions();
      _sizes.clear();
      for (OfflineRegion region in _regions) {
        String uri = region.metadata['trip'] ?? '';
        OfflineRegionStatus status = await getOfflineRegionStatus(region.id);
        _sizes[uri] = (_sizes[uri] ?? 0) + status.completedResourceSize;
      }
    } catch (e) {
      developer.log('OfflineMapsService.load(): $e', name: 'error');
    }
    notifyListeners();
  }

  List<OfflineRegion> _regionsOf(String uri) =>
      _regions.where((region) => region.metadata['trip'] == uri).toList();

  bool isDownloaded(String uri) =>
      _regionsOf(uri).isNotEmpty && !downloading.containsKey(uri);

  /// The trip's map on the phone, in bytes
  int sizeOf(String uri) => _sizes[uri] ?? 0;

  /// The route's points, [lng, lat], as the trip has them
  static List<List<double>> routeOf(MyTripItem trip) =>
      [for (var route in trip.routes) ...route.lines];

  /// How many tiles the trip's map would be - to say before downloading
  static int tilesFor(MyTripItem trip) => countTiles(boxesAlong(routeOf(trip)));

  /// Downloads the map along the trip - null when it's done, or why not
  Future<String?> download(MyTripItem trip) async {
    if (!supported) return "Offline maps are for the phone app";
    List<LatLngBounds> boxes = boxesAlong(routeOf(trip));
    if (boxes.isEmpty) return 'This trip has no route to download yet';
    int tiles = countTiles(boxes);
    if (tiles > mostTiles) {
      return 'This trip is too long to download in one go - its map would be '
          '$tiles tiles, and the most is $mostTiles. Try a shorter trip.';
    }
    String uri = trip.uri;
    await delete(uri, quietly: true); // a fresh copy, for the route as it is
    downloading[uri] = 0;
    notifyListeners();
    String? problem;
    try {
      // the store's own limit, across every trip on the phone
      await setOfflineTileCountLimit(mostOnPhone);
      for (int i = 0; i < boxes.length && problem == null; i++) {
        Completer<String?> done = Completer();
        await downloadOfflineRegion(
          OfflineRegionDefinition(
              bounds: boxes[i],
              mapStyleUrl: urlTilerMapLibre,
              minZoom: minZoom,
              maxZoom: maxZoom),
          metadata: {
            'trip': uri,
            'title': trip.title,
            'part': i + 1,
            'parts': boxes.length
          },
          onEvent: (event) {
            if (event is InProgress) {
              downloading[uri] =
                  (i + (event.progress / 100).clamp(0, 1)) / boxes.length;
              notifyListeners();
            } else if (event is Success && !done.isCompleted) {
              done.complete(null);
            } else if (event is Error && !done.isCompleted) {
              done.complete(event.cause.message?.contains('limit') == true
                  ? 'The phone has as many offline maps as it can keep - '
                      'delete one you no longer need first.'
                  : event.cause.message ?? 'The download failed');
            }
          },
        );
        problem = await done.future;
      }
    } catch (e) {
      developer.log('OfflineMapsService.download(): $e', name: 'error');
      problem = "Couldn't download the map - check your connection";
    }
    downloading.remove(uri);
    if (problem != null) await delete(uri, quietly: true); // not half a map
    await load();
    return problem;
  }

  /// Takes the trip's map off the phone
  Future<void> delete(String uri, {bool quietly = false}) async {
    if (!supported) return;
    for (OfflineRegion region in _regionsOf(uri)) {
      try {
        await deleteOfflineRegion(region.id);
      } catch (e) {
        developer.log('OfflineMapsService.delete(): $e', name: 'error');
      }
    }
    if (!quietly) await load();
  }

  // ---- the sums - plain Dart, so they're tested ---------------------------------

  /// Boxes along a line of [lng, lat] points: a new one every stretchKm of
  /// route, each grown by marginKm either side
  static List<LatLngBounds> boxesAlong(List<List<double>> line,
      {double stretch = stretchKm, double margin = marginKm}) {
    List<LatLngBounds> boxes = [];
    double? south, west, north, east;
    double travelled = 0;
    List<double>? last;

    void include(List<double> point) {
      south = min(south ?? point[1], point[1]);
      north = max(north ?? point[1], point[1]);
      west = min(west ?? point[0], point[0]);
      east = max(east ?? point[0], point[0]);
    }

    void close() {
      if (south == null) return;
      double dLat = margin / 111.0;
      double dLng = margin / (111.0 * cos((south! + north!) / 2 * pi / 180));
      boxes.add(LatLngBounds(
          southwest: LatLng(south! - dLat, west! - dLng),
          northeast: LatLng(north! + dLat, east! + dLng)));
      south = north = west = east = null;
      travelled = 0;
    }

    for (List<double> point in line) {
      if (last != null) travelled += _km(last, point);
      include(point);
      if (travelled >= stretch) {
        close();
        include(point); // the next stretch starts where this one ended
      }
      last = point;
    }
    if (line.length > 1) close();
    return boxes;
  }

  /// Roughly how far apart two [lng, lat] points are
  static double _km(List<double> a, List<double> b) {
    double x = (b[0] - a[0]) * cos((a[1] + b[1]) / 2 * pi / 180);
    double y = b[1] - a[1];
    return sqrt(x * x + y * y) * 111.0;
  }

  /// How many tiles the boxes are, minZoom to maxZoom (overlaps counted
  /// twice - an estimate, on the high side)
  static int countTiles(List<LatLngBounds> boxes,
      {double from = minZoom, double to = maxZoom}) {
    int tiles = 0;
    for (LatLngBounds box in boxes) {
      for (int z = from.toInt(); z <= to.toInt(); z++) {
        int n = 1 << z;
        int x(double lng) => ((lng + 180) / 360 * n).floor().clamp(0, n - 1);
        int y(double lat) {
          double r = lat * pi / 180;
          return ((1 - log(tan(r) + 1 / cos(r)) / pi) / 2 * n)
              .floor()
              .clamp(0, n - 1);
        }

        tiles += (x(box.northeast.longitude) - x(box.southwest.longitude) + 1) *
            (y(box.southwest.latitude) - y(box.northeast.latitude) + 1);
      }
    }
    return tiles;
  }
}
