import 'dart:math';
import 'dart:developer' as developer;
import '../models/models.dart';
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

void routesToGeoJson(
    {required List<Map<String, dynamic>> routes,
    required List<Map<String, dynamic>> geoJsonFeatures,
    int index = -1,
    String? colour,
    String? indexColour}) {
  colour = colour ?? Setup().routeColourHex();
  indexColour = indexColour ?? Setup().highlightedColourHex();
  for (int i = 0; i < routes.length; i++) {}
}

void pointsOfInterestToGeoJSON(
    {required List<PointOfInterest> pointsOfInterest,
    required List<Map<String, dynamic>> geoJsonFeatures,
    int index = -1,
    String? colour,
    String? indexColour}) {
  colour = colour ?? Setup().pointOfInterestColourHex();
  indexColour = indexColour ?? Setup().pointOfInterestColour2Hex();

  for (int i = 0; i < pointsOfInterest.length; i++) {
    if (![12, 17, 18, 19].contains(pointsOfInterest[i].type)) {
      geoJsonFeatures.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [
            pointsOfInterest[i].point.x,
            pointsOfInterest[i].point.y
          ]
        },
        "id": 'poi${i + 1}',
        "group": "shield",
        "properties": {
          "item": "point_of_interest",
          "icon": "point_of_interest",
          "color": i == index ? indexColour : colour,
          "number": i + 1,
          "group": 'shield'
        }
      });
    }
  }
}

void waypointsToGeoJSON(
    {required List<Point> waypoints,
    required List geoJsonFeatures,
    int index = -1,
    String? colour,
    String? indexColour,
    List? lastPoint}) {
  try {
    lastPoint = lastPoint ?? [];
    colour = colour ?? Setup().routeColourHex();
    indexColour = indexColour ?? Setup().highlightedColourHex();
    geoJsonFeatures
        .removeWhere((feature) => feature['properties']['item'] == 'waypoint');
    for (int i = 0; i < waypoints.length; i++) {
      geoJsonFeatures.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": i == waypoints.length - 1 && lastPoint.isNotEmpty
              ? lastPoint
              : [waypoints[i].x, waypoints[i].y]
        },
        "id": i,
        "group": "waypoint",
        "properties": {
          "item": "waypoint",
          "item_type": "good_road",
          "number": i + 1,
          "group": 'waypoint',
          "color": i == index ? indexColour : colour,
        }
      });
    }
  } catch (e) {
    developer.log('Error :${e.toString}', name: '_map_');
  }
  return;
}

void goodRoadWaypointsToGeoJSON(
    {required List<GoodRoad> goodRoads,
    required List<Map<String, dynamic>> geoJsonFeatures,
    int index = -1,
    String? colour,
    String? indexColour,
    List? lastPoint}) {
  lastPoint = lastPoint ?? [];
  colour = colour ?? Setup().goodRouteColourHex();
  indexColour = indexColour ?? Setup().highlightedColourHex();
  for (int i = 0; i < goodRoads.length; i++) {
    for (int j = 0; j < goodRoads[i].waypoints.length; j++) {
      List<Point> waypoints = goodRoads[i].waypoints;
      geoJsonFeatures.add(
        {
          "id": '${i}_$j',
          "type": "Feature",
          "group": "waypoint",
          "geometry": {
            "type": "Point",
            "coordinates": i == waypoints.length - 1 && lastPoint.isNotEmpty
                ? lastPoint
                : [waypoints[j].x, waypoints[j].y]
          },
          "properties": {
            "item": "waypoint",
            "number": j + 1,
            "group": 'shield',
            "color": i == index ? indexColour : colour,
          }
        },
      );
    }
  }
  return;
}

Point latLngToPoint({required LatLng latLng}) {
  return Point(latLng.longitude, latLng.latitude);
}
