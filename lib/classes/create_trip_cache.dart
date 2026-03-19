import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:drives/constants.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '/models/other_models.dart';
import '/tiles/tiles.dart';
import '/classes/classes.dart';
import '/services/services.dart';

/// Implements the My Trip page (create_trip.dart) routes cache. The functionality that has it be implemented is:
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

// const zoomCTLower = 7.0;
// const zoomCTUpper = 10.0;

class TripRequest {
  double _lastZoom = 0;
  double _thisZoom = 0;

  Function(int) onUpdated;
  Function(int, String)? onGetDownload;
  Function(int)? onGetDetails;
  ImageRepository? imageRepository;

  TripRequest({
    required this.onUpdated,
    this.onGetDetails,
    this.onGetDownload,
    this.imageRepository,
  });
  List<String> received = [];
  Map<String, dynamic> request = {"zoom": 14, "b_box": [], "exclude": []};
  Map<String, dynamic> exclude = {};
  List<TripItem> trips = [];
  List<Maneuver> maneuvers = [];
  List<PointOfInterest> pointsOfInterest = [];
  TripHeaderController _tripHeaderController = TripHeaderController();

  String requestId = '';

  final Map<String, dynamic> _3DCache = {
    "id": '',
    "cache": {
      "lower": {
        "fence": {
          "sw": {"lng": 0.0, "lat": 0.0},
          "ne": {"lng": 0.0, "lat": 0.0}
        },
        "data": {
          "route": [],
          "good_roads_lines": [],
          "good_road_shields": [],
          "pois": [],
          "reviews": [],
        },
        "exclude": []
      },
      "middle": {
        "fence": {
          "sw": {"lng": 0.0, "lat": 0.0},
          "ne": {"lng": 0.0, "lat": 0.0}
        },
        "data": {
          "route": [],
          "good_roads_lines": [],
          "good_road_shields": [],
          "pois": [],
          "reviews": [],
        },
        "exclude": []
      },
      "upper": {
        "fence": {
          "sw": {"lng": 0.0, "lat": 0.0},
          "ne": {"lng": 0.0, "lat": 0.0}
        },
        "data": {
          "route": [],
          "good_roads_lines": [],
          "good_road_shields": [],
          "pois": [],
          "reviews": [],
        },
        "exclude": []
      }
    }
  };
  dynamic apiGeoJson;

  Future<Map<String, dynamic>> update(
      {required LatLngBounds bounds, required double zoom}) async {
    /// If changing zoom level or breaching bounds
    ///   1 zoom higher -> lower all higher polylines can be used but shields can't - excludes should be included in lower level
    ///   2 zoom lower -> higher all lower level data should be left intact
    ///   3 outside fence complete refresh of that level data with excludes from higher levels

    _thisZoom = zoom;
    bool zoomChanged = zoomUpdate(zoom: zoom);
    bool fenceBreached = outsideFence(bounds: bounds, zoom: zoom);
    fenceBreached = true; // debug
    if (zoomChanged || fenceBreached) {
      try {
        String zLevel = level(zoom: zoom);
        List excluded = [];
        String useData = "";
        // fenceBreached = true; // Debug to force read from api
        if (fenceBreached) {
          _3DCache["cache"][zLevel]["data"]["lines"] = [];
          _3DCache["cache"][zLevel]["data"]["shields"] = [];
          _3DCache["cache"][zLevel]["exclude"] = [];
          if (zoom < _lastZoom) {
            useData = level(zoom: _lastZoom);
            excluded = _3DCache["cache"][useData]["exclude"];
          }
        }
        setBounds(bounds: bounds, zoom: zoom);
        developer.log(
            'create_trip_cache.dart 158 - update() bounds: ${bounds.toString()} zoom: $zoom',
            name: '_map_');
        dynamic geoJson = await getGoodRoadsGeoJson(
            boundingBox: _3DCache["cache"][level(zoom: zoom)]["fence"],
            exclude: excluded,
            zoom: zoom);
        var jsonData;
        if (geoJson.isNotEmpty) {
          jsonData = jsonDecode(geoJson);
          // return jsonData;  // Debug
          // Extract returned ids to exclude
          for (int i = 0; i < jsonData["features"].length; i++) {
            if (jsonData['features'][i]['properties'].length == 4) {
              _3DCache["cache"][zLevel]["data"]["lines"]
                  .add(jsonData["features"][i]);
              _3DCache["cache"][zLevel]["exclude"]
                  .add(jsonData['features'][i]["id"]);
            } else {
              _3DCache["cache"][zLevel]["data"]["shields"]
                  .add(jsonData["features"][i]);
            }
          }
        }

        geoJson = await getPointsOfInterestGeoJson(
            boundingBox: _3DCache["cache"][level(zoom: zoom)]["fence"],
            exclude: excluded,
            zoom: zoom);
        if (geoJson.isNotEmpty) {
          jsonData = jsonDecode(geoJson);
          // return jsonData;  // Debug
          // Extract returned ids to exclude
          for (int i = 0; i < jsonData["features"].length; i++) {
            _3DCache["cache"][zLevel]["data"]["pois"]
                .add(jsonData["features"][i]);
          }
        }
        _lastZoom = zoom;
        onUpdated(zoom.toInt());
        return {
          "type": "FeatureCollection",
          "features": _3DCache["cache"][zLevel]["data"]["lines"] +
              _3DCache["cache"][zLevel]["data"]["shields"]
        };
      } catch (e) {
        developer.log('Error using 3-DCache: ${e.toString()}');
      }
    }
    return {"type": "FeatureCollection", "features": []};
  }

  String level({required zoom}) {
    if (zoom >= zoomUpper) {
      return 'upper';
    } else if (zoom > zoomLower) {
      return 'middle';
    }
    return 'lower';
  }

  bool outsideFence({required LatLngBounds bounds, required double zoom}) {
    String zLevel = level(zoom: zoom);
    try {
      Map<String, dynamic> fence = _3DCache["cache"][zLevel]["fence"];
      if (bounds.southwest.longitude < fence["sw"]["lng"] ||
          bounds.southwest.latitude < fence["sw"]["lat"] ||
          bounds.northeast.longitude > fence["ne"]["lng"] ||
          bounds.northeast.latitude > fence["ne"]["lat"]) {
        return true;
      }
    } catch (e) {
      debugPrint(
          'error getting 3-DCache outsideFence() create_trip_cache.dart: ${e.toString()}');
    }
    return false;
  }

  bool zoomUpdate({required double zoom}) {
    bool update = (zoom - zoomLower) *
            (_lastZoom - zoomLower) *
            (zoom - zoomUpper) *
            (_lastZoom - zoomUpper) <
        0;
    return update;
  }

  setBounds({required LatLngBounds bounds, required double zoom}) async {
    /// Longitude decrease westwards New York 40.7 Lat -74.0 Lng  Moscow 55.7 Lat 37.6 Lng
    /// Latitude increase northwards

    double lngSpan =
        (bounds.southwest.longitude - bounds.northeast.longitude).abs();
    double latSpan =
        (bounds.northeast.latitude - bounds.southwest.latitude).abs();
    // Add a 100% buffer in all directions (1 screen width padding)
    String zLevel = level(zoom: zoom);
    _3DCache["cache"][zLevel]["fence"] = {
      "sw": {
        "lng": bounds.southwest.longitude - lngSpan,
        "lat": bounds.southwest.latitude - latSpan
      },
      "ne": {
        "lng": bounds.northeast.longitude + lngSpan,
        "lat": bounds.northeast.latitude + latSpan
      }
    };
    return;
  }

  List<TripItem> getSummaries() {
    List<TripItem> trips = [];
    String zLevel = level(zoom: _thisZoom);
    List<String> ids = [];
    for (int i = 0;
        i < _3DCache["cache"][zLevel]["data"]["shields"].length;
        i++) {
      String id = _3DCache["cache"][zLevel]["data"]["shields"][i]["id"]
          .substring(0, 32);
      if (!ids.contains(id)) {
        trips.add(TripItem.from3DCache(
            map: _3DCache["cache"][zLevel]["data"]["shields"][i]
                ["properties"]));
        trips.last.driveUri = id;
        ids.add(id);
      }
    }
    return trips;
  }

  List<Card> getTripTiles(
      {String openUri = '',
      GlobalKey? key,
      Function(bool)? callback,
      TripHeaderController? tripHeaderController}) {
    List<Card> cards = [
      Card(
        key: openUri.isEmpty ? key : Key('tc-1'),
        child: TripHeaderTile(
          key: Key('th_0'),
          controller: tripHeaderController,
          index: 0,
          tripItem: CurrentTripItem(),
          appState: AppState.createTrip,
          onUpdate: (value) {
            if (value == 7 && callback != null) {
              callback(true);
            }
          },
          // onUpdate: (value) => callback!(value) ?? (_) => (),
        ),
      )
    ];
    if (pointsOfInterest.isNotEmpty) {
      for (int i = 0; i < pointsOfInterest.length; i++) {
        cards.add(
          Card(
            child: PointOfInterestTile(
              key: pointsOfInterest[i].uuid == openUri ? key : Key('tt$i'),
              pointOfInterest: pointsOfInterest[i],
              imageRepository: imageRepository!,
              index: i,
              expanded: pointsOfInterest[i].uuid == openUri,
              onUpdate: (value) {
                if (callback != null) {
                  callback(value);
                }
              },
            ),
          ),
        );
      }
    }
    return cards;
  }
}
