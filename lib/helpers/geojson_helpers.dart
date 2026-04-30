import 'dart:math';
import 'dart:developer' as developer;
import '../classes/classes.dart';
import '../models/models.dart';
import '../constants.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// saveMyTrip saves a complete trip locally
/// All lists should be stored in SQLite as strings using jsonEncode()
///
/// {'uri': '0203023..', 'title': 'Drive name', 'sub_title': 'Drive sub_title',
/// 'body': 'Drive description', 'added': '01/01/2006', 'score': 5,
/// 'scored': 0, 'distance': 125, 'downloads': 0, 'author_uri': '',
/// 'author': 'James Seddon',
/// 'ne': [-0.765, 51.9879], 'sw':[-0.765, 51.9879],
/// 'routes':[
///   {'uri': '98018...',
///     'lines': {'type': 'LineString', 'coordinates':[[-0.765, 51.9879], [-0.7654, 519978], ...]},
///     'shields': {'type': 'MultiPoint', 'coordinates': [[-0.765, 51.9879], [-0.7654, 519978], ...]}},
///   ],
/// 'good_roads':[
///   {'uri': '98018...', 'point_of_interest_id': '98018...', 'ne': [-0.765, 51.9879], 'sw':[-0.765, 51.9879],
///     'lines': {'type': 'LineString', 'coordinates':[[-0.765, 51.9879], [-0.7654, 519978], ...]},
///     'shields': {'type': 'MultiPoint', 'coordinates': [[-0.765, 51.9879], [-0.7654, 519978], ...]}},
///   ],
/// 'maneuvers':[
///   {'uri': '98018...',
///     'road_from': 'jkhk', 'road_to': 'hkkkjh', 'bearing_before': 45,
///     'bearing_after': 67, 'point': {'type': 'Point', 'coordinates': [-0.5454, 54.3]},
///     'modifier': 'left', 'type': 'roundabout',
///     'distance': 12.6,
///     'point': }, {...}
///  ],
/// 'points_of_interest':[
///   {'uri': '98018...', 'type': 12, 'name': 'start', 'description': 'hgjghj',
///   'images': [], 'point': {'type': 'Point', 'coordinates': [-0.65, 51.23]},
///   'score': 5, 'scored': 0, 'comment': ' '}, {...}
///   ]
/// }

/// GeoJSON considerations:
/// Each source should be tied to a single FeatureCollection so that only the data that has
/// been changed is updated on the map
/// All api data changes on zoom and bounding box
/// Waypoints can change when a waypoint is highlighted without changing user-route
/// User-routes
/// Driving data - driven route and followers
///
///
///   Data                  Source                    Flutter geoJSON List      Flutter data        Drives route
///   api-routes            route-data                routeDataGEOJSON          routes              Great Drives
///   api-goodRoads         route-data                routeDataGEOJSON          routes              Great Drives / My Trip
///   waypoints             waypoint-data             waypointsGEOJSON          waypoints           My Trip
///   edited-routes         user-data                 userRouteGEOJSON          routes              My Trip
///   edited-goodRoads      goodRoad-data             goodRoadsGEOJSON          goodRoads           My Trip
///   points of interest    point-of-interest-data    pointsOfInterestGEOJSON   pointsOfInterest    My Trip
///
///
///
/// Should have two methods for each FeatureCollection
///   1 updateFeatures()
///       Flutter list is cleared
///       Flutter list is generated
///       geoJSON FeatureList is generated
///       MapLibre FeatureList is updated
///   2 addFeature()
///       feature is added to the Flutter List
///       feature geoJSON is regenerated
///       LibreMap is updated with just adding the feature
///

/// fenceFilter() uses MapLibre's setFilter() method to change the filter conditions
/// on a layer. This avoids having to identify all the visible features, and the decide if they
/// should be visible.
/// In this case the objects to be highlighted will be made visible:
/// The route and good road highlight layer, and their associated shields.
/// The geoJson objects have to have a min_lat min_lon etc that is calculated by
/// Mariadb.

List fenceFilter({required LatLngBounds bounds, proportion = 0.6}) {
  double height = bounds.northeast.latitude - bounds.southwest.latitude;
  double width = bounds.northeast.longitude - bounds.southwest.longitude;

  double lngGap = (width - (width * proportion));
  double latGap = (height - (height * proportion));

  LatLng ne = LatLng(
      bounds.northeast.latitude - latGap, bounds.northeast.longitude - lngGap);
  LatLng sw = LatLng(
      bounds.southwest.latitude + latGap, bounds.southwest.longitude + lngGap);

  var filter = [
    //"published_routes", [
    "all", // <- all conditions must be met so NOT "any"
    // Object's sw corner must be further south and west than the fence's ne corner
    [
      "<=",
      ["get", "min_lat"], // <- object sw.lat
      ne.latitude
    ],
    [
      "<=",
      ["get", "min_lon"], // <- object sw.lng
      ne.longitude
    ],
    // Object's ne corner must be further north and east than the fence's sw corner
    [
      ">=",
      ["get", "max_lat"], // <- object ne.lat
      sw.latitude
    ],
    [
      ">=",
      ["get", "max_lon"], // <- object ne.lng
      sw.longitude
    ]
  ];
  return filter;
}

testFenceFilter(
    {required LatLngBounds bounds,
    required Map<String, dynamic> jsonData,
    proportion = 0.6}) {
  double height = bounds.northeast.latitude - bounds.southwest.latitude;
  double width = bounds.northeast.longitude - bounds.southwest.longitude;

  double lngGap = (width - (width * proportion));
  double latGap = (height - (height * proportion));

  LatLng ne = LatLng(
      bounds.northeast.latitude - latGap, bounds.northeast.longitude - lngGap);
  LatLng sw = LatLng(
      bounds.southwest.latitude + latGap, bounds.southwest.longitude + lngGap);

  developer.log("FENCE BOUNDS - NE: $ne  SW: $sw", name: "_x_x_");

  for (int i = 0; i < jsonData['features'].length; i++) {
    double min_lat = jsonData['features'][i]['properties']['min_lat'] ?? 90;
    double max_lat = jsonData['features'][i]['properties']['max_lat'] ?? 0;
    double min_lon = jsonData['features'][i]['properties']['min_lon'] ?? 180;
    double max_lon = jsonData['features'][i]['properties']['max_lon'] ?? 0;

    if (min_lat > ne.latitude || min_lon > ne.longitude) {
      developer.log(
          "OUTSIDE FENCE - Feature: $i - Object's sw corner must be further south and west than the fence's ne corner",
          name: "_x_x_");
    } else if (max_lat < sw.latitude || max_lon < sw.longitude) {
      developer.log(
          "OUTSIDE FENCE - Feature: $i - Object's ne corner must be further north and east than the fence's sw corner",
          name: "_x_x_");
    } else {
      developer.log("Feature: $i - INSIDE FENCE OK ", name: "_x_x_");
    }
  }
  return;
}

/// stateFilter() is to allow features to be hidden if the TripState is inappropriate
/// The geoJson has 3 possible state properties that matches a TripState.name where
/// the filtered item should be exposed.

List tripStateFilter({TripState tripState = TripState.none}) {
  List filter = [
    "any", // <- any conditions must be met so NOT "all"
    [
      "==",
      ["get", "trip-state-1"], // <- option 1
      tripState.name
    ],
    [
      "==",
      ["get", "trip-state-2"], // <- option 2
      tripState.name
    ],
    [
      "==",
      ["get", "trip-state-3"], // <- option 3
      tripState.name
    ]
  ];
  return filter;
}

List<Map<String, dynamic>> routesToGeoJson(
    {List<Route>? routes,
    int index = -1,
    String? colour,
    String? indexColour,
    bool? highlighted}) {
  colour ??= Setup().routeColourHex();
  routes ??= CurrentTripItem().routes;
  highlighted ??= false;
  indexColour = indexColour ?? Setup().highlightedColourHex();

  List<Map<String, dynamic>> features = [];
  if (routes.isNotEmpty) {
    for (int i = 0; i < routes.length; i++) {
      features.add({
        "type": "Feature",
        "geometry": {"type": "LineString", "coordinates": routes[i].lines},
        "id": i,
        "properties": {
          "group": 'route',
          "width": 2,
          "color": i == index ? indexColour : colour,
        }
      });
    }
  }
  developer.log('routesToGeoJson() features.length: ${features.length}',
      name: '_geoJson*_');
  return features;
}

List<Map<String, dynamic>> goodRoadsToGeoJson(
    {List<Route>? routes,
    int index = -1,
    String? colour,
    String? indexColour,
    bool? highlighted}) {
  colour ??= Setup().goodRouteColourHex();
  routes ??= CurrentTripItem().goodRoads;
  highlighted ??= false;
  indexColour = indexColour ?? Setup().highlightedColourHex();
  List<Map<String, dynamic>> features = [];
  if (routes.isNotEmpty) {
    for (int i = 0; i < routes.length; i++) {
      features.add({
        "type": "Feature",
        "geometry": {"type": "LineString", "coordinates": routes[i].lines},
        "id": i,
        "properties": {
          "group": 'route',
          "width": 2,
          "highlighted": true,
          "color": i == index ? indexColour : colour,
        }
      });
    }
  }
  developer.log('goodRoadsToGeoJson() features.length: ${features.length}',
      name: '_geoJson*_');
  return features;
}

List<List<double>> dynamicToDouble({required List<dynamic> dynamicList}) {
  List<List<double>> newList = List<List<double>>.from(dynamicList
      .map((xy) => List<double>.from(xy.map((val) => val.toDouble()))));
  return newList;
}

/// pointsOfInterestToGeoJSON  returns a list of GeoJson Features

List<Map<String, dynamic>> pointsOfInterestToGeoJson(
    {List<PointOfInterest>? pointsOfInterest,
    String? colour,
    List<int>? exclude,
    rated = 0}) {
  pointsOfInterest ??= CurrentTripItem().pointsOfInterest;
  exclude ??= [12, 14, 17, 18, 19];
  List<Map<String, dynamic>> geoJson = [];
  if (pointsOfInterest.isNotEmpty) {
    try {
      developer.log(
          'pointsOfInterestToGeoJson() pointsOfInterest.length.length: ${pointsOfInterest.length}',
          name: '_mapUpdates_');
      for (int i = 0; i < pointsOfInterest.length; i++) {
        if (!exclude.contains(pointsOfInterest[i].type)) {
          geoJson.add(pointsOfInterest[i].toGeoJson(index: i));
        }
      }
    } catch (e) {
      developer.log('Error pointsOfInterestToGeoJson(): ${e.toString()}',
          name: '_mapUpdates_');
    }
  }
  developer.log(
      'pointsOfInterestToGeoJson() geoJson.length.length: ${geoJson.length}',
      name: '_mapUpdates_');
  return geoJson;
}

List<Map<String, dynamic>> followersToGeoJson({List<Follower>? followers}) {
  followers ??= CurrentTripItem().followers;
  List<Map<String, dynamic>> geoJson = [];
  if (followers.isNotEmpty) {
    try {
      developer.log(
          'pointsOfInterestToGeoJson() pointsOfInterest.length.length: ${followers.length}',
          name: '_repaint_');
      for (int i = 0; i < followers.length; i++) {
        // geoJson.add(followers[i].toGeoJson(index: i));
      }
    } catch (e) {
      developer.log('Error pointsOfInterestToGeoJson(): ${e.toString()}',
          name: '_g_j_');
    }
  }
  return geoJson;
}

String toStars({double rating = 5}) {
  int rated = rating.toInt();
  return '${'★' * rated}${'☆' * (5 - rated)}';
}

List<Map<String, dynamic>> waypointsToGeoJson(
    {List<Waypoint>? waypoints,
    int index = -1,
    String? colour,
    String? indexColour,
    List? lastPoint}) {
  List<Map<String, dynamic>> features = [];

  try {
    waypoints ??= CurrentTripItem().routes.last.waypoints;
    lastPoint = lastPoint ?? [];
    colour = colour ?? Setup().routeColourHex();
    indexColour = indexColour ?? Setup().highlightedColourHex();
    developer.log('waypointsToGeoJson() routes.length: ${waypoints.length}',
        name: '_g_j_');
    if (CurrentTripItem().routes.isNotEmpty) {
      for (int h = 0; h < CurrentTripItem().routes.length; h++) {
        waypoints = CurrentTripItem().routes[h].waypoints;

        for (int i = 0; i < waypoints.length; i++) {
          developer.log(
              'Getting route[$h] geoJson for waypoint # $i point ${waypoints[i].point}',
              name: '_geo_json_');
          features.add({
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": i == waypoints.length - 1 && lastPoint.isNotEmpty
                  ? lastPoint
                  : [waypoints[i].point.x, waypoints[i].point.y]
            },
            "id": i,
            "properties": {
              "group": 'waypoint',
              "trip-state-1": "manual",
              "trip-state-2": "editing",
              "trip-state-3": "goodRoadStart",
              "number": i + 1,
              "color": waypoints[i].selected ?? false ? indexColour : colour,
            }
          });
        }
      }
    }
  } catch (e) {
    developer.log('Error :${e.toString}', name: '_map_');
  }
  return features;
}

List<Map<String, dynamic>> goodRoadWaypointsToGeoJson(
    {List<Waypoint>? waypoints,
    int index = -1,
    String? colour,
    String? indexColour,
    List? lastPoint}) {
  List<Map<String, dynamic>> features = [];

  try {
    waypoints ??= CurrentTripItem().goodRoads.last.waypoints;
    lastPoint = lastPoint ?? [];
    colour = colour ?? Setup().goodRouteColourHex();
    indexColour = indexColour ?? Setup().highlightedColourHex();
    developer.log(
        'goodRoadsWaypointsToGeoJson() routes.length: ${waypoints.length}',
        name: '_g_j_');
    if (CurrentTripItem().goodRoads.isNotEmpty) {
      for (int h = 0; h < CurrentTripItem().goodRoads.length; h++) {
        waypoints = CurrentTripItem().goodRoads[h].waypoints;
        for (int i = 0; i < waypoints.length; i++) {
          features.add({
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": i == waypoints.length - 1 && lastPoint.isNotEmpty
                  ? lastPoint
                  : [waypoints[i].point.x, waypoints[i].point.y]
            },
            "id": i,
            "properties": {
              "group": 'good_road_waypoint',
              "item_type": "good_road",
              "trip-state-1": "manual",
              "trip-state-2": "editing",
              "trip-state-3": "goodRoadStart",
              "number": i + 1,
              "color": i == index ? indexColour : colour,
            }
          });
        }
      }
    }
  } catch (e) {
    developer.log('Error :${e.toString}', name: '_map_');
  }
  return features;
}

Point latLngToPoint({required LatLng latLng}) {
  return Point(latLng.longitude, latLng.latitude);
}
