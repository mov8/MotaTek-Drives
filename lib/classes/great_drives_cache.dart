import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:drives/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '/models/other_models.dart';
import '/classes/classes.dart';
import '/services/services.dart';
import '/helpers/helpers.dart';

/// Implements the Great Drives page routes cache. The functionality that has it be implemented is:
///   Optimise the routes held im memory based on a fence, and zoom level 12, 10, 8, <=8
///   Only fetch just the records needed
///   Discard records only based on the fence
///   Uses a POST request to get records based on the current fence and zoom level
///   The fence should be intelligent, and based around the viewport coverage, and not just distance
///   https://moldstud.com/articles/p-understanding-spatial-relationships-in-mariadb-what-why-and-how-to-leverage-geospatial-data
///
/// If the user changes the zoom level or moves outside the fence
/// will have to hit the api:
///
///   If they move outside the fence - a complete refresh
///
///   If they zoom inside the fence the cache will have to be
///   updated:
///       If they are zooming in then low res lines will be saved, and
///       the visible high res ones loaded
///
///       If they are zooming out, but remain within the fence nothing
///       will have to be loaded, as all lines within the fence will
///       already be there.
///
/// Current zoom levels in Drives.py are
///     Zoom    Point density   Km /Shield
/// 1   > 12             100%            2
/// 2   >  5              10%           10
/// 3   >  0               1%          100
///
/// These are defined in the api drive.py 166 add_json()
///
/// Will implement a 3-D cache:
///   Each zoom level will have the current fence for that zoom stored
///   along with all the GeoJson objects
///
///   When zooming in should send all the exclude lines from the next level
///   to zoom to (if there are any)
///
///   When zooming out should exclude all the all the cached objects
///   from the higher density layers.
///

const zoomLower = 7.0;
const zoomUpper = 10.0;

/// The published trips on Published: fetched for an area round the map's
/// view (three times its size), at the line detail that suits the zoom, and
/// fetched again when the view leaves that area or the zoom changes level.
/// The drawer lists the trips on the part of the map that's in view, and
/// follows every move and zoom - it listed the whole fetched area, and kept
/// trips that had gone out of view until the zoom changed level.
class DrivesRequest {
  Function(int) onUpdated;
  Function(int, String)? onGetDownload;
  Function(int)? onGetDetails;
  ImageRepository? imageRepository;

  DrivesRequest({
    required this.onUpdated,
    this.onGetDetails,
    this.onGetDownload,
    this.imageRepository,
  });

  /// The area fetched, and the level of detail it was fetched at ('' none)
  Map<String, dynamic> _fence = {};
  String _level = '';

  /// What was fetched: the map's features, the trips, and each trip's
  /// extent [west, south, east, north] from its line
  List _features = [];
  List<TripItem> _trips = [];
  final Map<String, List<double>> _extents = {};

  /// The trips the drawer lists now, by uri - it's only refilled when they
  /// change, so an open tile isn't closed by every move of the map
  List<String> _listed = [];

  /// Each fetch's number - a slower, older one is thrown away
  int _fetch = 0;

  /// The published trip whose details are open (MapService().
  /// showPublishedTrip()) - kept in the list while it's open
  String openTrip = '';

  /// After publishing: fetched again whatever the view
  void invalidate() => _level = '';

  Future<void> update(
      {required LatLngBounds bounds,
      required double zoom,
      bool force = false}) async {
    String zLevel = level(zoom: zoom);
    if (force || zLevel != _level || outsideFence(bounds: bounds)) {
      int fetch = ++_fetch;
      Map<String, dynamic> fence = fenceFor(bounds);
      try {
        dynamic geoJson =
            await getGeoJson(boundingBox: fence, exclude: const [], zoom: zoom);
        if (fetch != _fetch) return; // a later one is on its way
        var jsonData = geoJson is String ? jsonDecode(geoJson) : null;
        if (jsonData is! Map) return; // not reached - tried again next time
        read(jsonData['features'] ?? []);
        _fence = fence;
        _level = zLevel;
        onUpdated(zoom.toInt());
        await MapService().controller!.setGeoJsonSource("published-data",
            {"type": "FeatureCollection", "features": _features});
        _listed = []; // refill the drawer - its trips are new objects
      } catch (e) {
        developer.log('Error using 3-DCache: ${e.toString()}', name: 'error');
        return;
      }
    }
    _showInDrawer(bounds);
  }

  /// The API's features: a 'line' and a 'shield' for each of a trip's
  /// routes. The trips come from their shields, once each.
  void read(List features) {
    _features = [];
    _trips = [];
    _extents.clear();
    // Each trip's line shares its id - its first point is the start
    Map<String, List> starts = {};
    for (var feature in features) {
      String id = '${feature['id']}';
      Map properties = feature['properties'] ?? {};
      if (feature['group'] == 'line' && feature['geometry'] != null) {
        List coordinates = feature['geometry']['coordinates'] ?? [];
        while (coordinates.isNotEmpty && coordinates.first is List) {
          if (coordinates.first.first is! List) break;
          coordinates = coordinates.first; // a MultiLineString
        }
        if (coordinates.isNotEmpty) {
          starts.putIfAbsent(id, () => coordinates.first);
        }
        List<double>? extent = _extentOf(properties);
        if (extent != null) {
          List<double>? had = _extents[id];
          _extents[id] = had == null
              ? extent
              : [
                  min(had[0], extent[0]),
                  min(had[1], extent[1]),
                  max(had[2], extent[2]),
                  max(had[3], extent[3]),
                ];
        }
      }
    }
    Set<String> labelled = {};
    for (var feature in features) {
      String id = '${feature['id']}';
      // Its trip, for a tap on the route or label - MapLibre on the web
      // replaces text feature ids with numbers
      (feature['properties'] ??= {})['uri'] = id;
      if (feature['group'] != 'shield') {
        _features.add(feature);
        continue;
      }
      // One label per trip, at its start - the API sends a point every mile
      // or so along each route, which crowded the map with the same label
      if (!labelled.add(id)) continue;
      List points = feature['geometry']?['coordinates'] ?? [];
      List? start = starts[id] ??
          (points.isNotEmpty && points.first is List ? points.first : null);
      if (start != null) {
        feature['geometry'] = {'type': 'Point', 'coordinates': start};
      }
      Map properties = feature['properties'];
      if (!_extents.containsKey(id)) {
        List<double>? extent = _extentOf(properties);
        if (extent != null) _extents[id] = extent;
      }
      _trips.add(TripItem.from3DCache(
          map: Map<String, dynamic>.from(properties), uri: id)
        ..startPoint = starts[id] ?? const []);
      properties['color'] = Setup().routeColourHex();
      // the label's stars - none until it's rated
      properties['rating'] =
          unratedStars(properties['rated'], properties['rating']);
      _features.add(feature);
    }
  }

  List<double>? _extentOf(Map properties) {
    List values = [
      properties['min_lon'],
      properties['min_lat'],
      properties['max_lon'],
      properties['max_lat']
    ];
    if (values.any((v) => v is! num)) return null;
    return [for (var v in values) (v as num).toDouble()];
  }

  /// The trips on the part of the map in view (and the open one)
  List<TripItem> inView(LatLngBounds bounds) => [
        for (TripItem trip in _trips)
          if (trip.uri == openTrip || _overlaps(_extents[trip.uri], bounds))
            trip
      ];

  bool _overlaps(List<double>? extent, LatLngBounds bounds) {
    if (extent == null) return true; // can't tell
    return extent[0] <= bounds.northeast.longitude &&
        extent[2] >= bounds.southwest.longitude &&
        extent[1] <= bounds.northeast.latitude &&
        extent[3] >= bounds.southwest.latitude;
  }

  void _showInDrawer(LatLngBounds bounds) {
    List<TripItem> trips = inView(bounds);
    List<String> uris = [for (TripItem trip in trips) trip.uri];
    if (listEquals(uris, _listed)) return;
    _listed = uris;
    if (kIsWeb) {
      MapService()
          .sideDrawerController
          ?.setContent(content: BottomDrawerItems.drives, drawerItems: trips);
    } else {
      // The user opens the drawer to see them
      MapService().bottomDrawerController?.setContent(
          content: BottomDrawerItems.drives, drawerItems: trips, open: false);
    }
  }

  String level({required double zoom}) {
    if (zoom >= zoomUpper) {
      return 'upper';
    } else if (zoom > zoomLower) {
      return 'middle';
    }
    return 'lower';
  }

  bool outsideFence({required LatLngBounds bounds}) {
    if (_fence.isEmpty) return true;
    return bounds.southwest.longitude < _fence["sw"]["lng"] ||
        bounds.southwest.latitude < _fence["sw"]["lat"] ||
        bounds.northeast.longitude > _fence["ne"]["lng"] ||
        bounds.northeast.latitude > _fence["ne"]["lat"];
  }

  /// The area to fetch: the view with a view's width and height added all
  /// round
  Map<String, dynamic> fenceFor(LatLngBounds bounds) {
    double lngSpan =
        (bounds.southwest.longitude - bounds.northeast.longitude).abs();
    double latSpan =
        (bounds.northeast.latitude - bounds.southwest.latitude).abs();
    return {
      "sw": {
        "lng": bounds.southwest.longitude - lngSpan,
        "lat": bounds.southwest.latitude - latSpan
      },
      "ne": {
        "lng": bounds.northeast.longitude + lngSpan,
        "lat": bounds.northeast.latitude + latSpan
      }
    };
  }
}
