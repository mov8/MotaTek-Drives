import 'package:flutter/material.dart' hide Route;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'dart:developer' as developer;
// import 'package:geolocator/geolocator.dart' as gl;
import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import '/classes/route.dart' as mt;
import 'geojson_helpers.dart';
import '/models/models.dart';
import '/constants.dart';
import '/classes/classes.dart';

enum ChipRequest { none, arrow, burger, details }

Map<String, dynamic> chipRequests = {
  'ledingWidget': -1,
  'getTripDetails': false
};

String getUuid() {
  String uuidString = Uuid().v7();
  return uuidString.replaceAll(RegExp(r'-'), '');
}

int pointsOfInterestCount(List<PointOfInterest> pointsOfInterest) {
  int count = 0;
  for (int i = 0; i < pointsOfInterest.length; i++) {
    if (![12, 17, 18].contains(pointsOfInterest[i].type)) {
      count++;
    }
  }
  return count;
}

/// Inserts a new image description into a JSONString containing an array of
/// Image descriptions - url, caption, and rotation
///
String addImageToJSONString(
    {String currentJSONString = '',
    required String newUrl,
    String newCaption = '',
    int newRotation = 0}) {
  String newString = '';
  List<Map<String, dynamic>> images;
  Map<String, dynamic> newImage = {
    'url': newUrl,
    'caption': newCaption,
    'rotation': newRotation
  };
  if (currentJSONString.isEmpty) {
    images = [newImage];
  } else {
    images = jsonDecode(CurrentTripItem().images);
    images.add(newImage);
  }
  newString = jsonEncode(images);

  return newString;
}

Map<String, dynamic> getBlTr({required Size screenSize, double factor = 1}) {
  double right = screenSize.width - (screenSize.width * factor) * 0.5;
  double bottom = screenSize.height - (screenSize.height * factor) * 0.5;
  double top = screenSize.height - bottom;
  double left = screenSize.width - right;
  return {"bl": Point(bottom, left), "tr": Point(top, right)};
}

/*
List<LatLng> waypointsFromPointsOfInterest(
    {bool reversed = false,
    double newPointLat = 0.0,
    newPointLng = 0.0,
    atEnd = false}) {
  List<LatLng> waypoints = [];
  List<PointOfInterest> pois = [];
  pois.addAll(CurrentTripItem().pointsOfInterest);
  if (reversed) {
    pois = pois.reversed.toList();
  }

  if (newPointLat + newPointLng != 0) {
    if (atEnd) {
      if (pois[pois.length - 1].type == 18) {
        pois[pois.length - 1].type = 12;
      }
      pois.add(
        PointOfInterest(
          type: 18,
          point: LatLng(newPointLat, newPointLng),
        ),
      );
    } else {
      if (pois[0].type == 17) {
        pois[0].type = 12;
      }
      pois.insert(
        0,
        PointOfInterest(
          type: 17,
          point: LatLng(newPointLat, newPointLng),
        ),
      );
    }
    CurrentTripItem().pointsOfInterest = pois;
  }

  for (int i = 0; i < pois.length; i++) {
    if ([12, 17, 18, 19].contains(pois[i].type)) {
      waypoints.add(pois[i].point);
    }
  }

  return waypoints;
}
*/
/*
Future<String> waypointsFromManeuvers(
    {int points = 50, reverse = false}) async {
  List<List<double>> latLongs = [];

  /// Only going to add the start, end, and any turns. The Router will do the rest
  latLongs.add(CurrentTripItem().maneuvers[0].location);
  latLongs.add(CurrentTripItem()
      .maneuvers[CurrentTripItem().maneuvers.length - 1]
      .location);

  if (reverse) {
    latLongs = latLongs.reversed.toList();
    return '${latLongs[0][0]},${latLongs[0][1]};${latLongs[1][0]},${latLongs[1][1]}';
  }

  int count = latLongs.length;
  final double incrementer;
  if (count <= points) {
    incrementer = 1;
  } else {
    incrementer = count / points;
  }

  String waypoints = '';
  String delimiter = '';
  for (int i = 0; i < count; i++) {
    int idx = (incrementer * i).round();
    if (idx < latLongs.length) {
      waypoints = '$waypoints$delimiter${latLongs[idx][0]},${latLongs[idx][1]}';
      delimiter = ';';
    } else {
      debugPrint('Index overflow');
    }
  }

  return waypoints;
}
*/
/*
Future<String> waypointsFromPoints(int points) async {
  List<LatLng> latLongs = [];
  for (int i = 0; i < CurrentTripItem().routes.length; i++) {
    latLongs = latLongs + CurrentTripItem().routes[i].points;
  }
  int count = latLongs.length;

  if (count / points < 10) {
    points = count ~/ 10;
  }

  int gap = (count - 2) ~/ points;

  String waypoints = '${latLongs[0].longitude},${latLongs[0].latitude}';
  for (int i = 0; i < points - 2; i++) {
    int idx = gap * (i + 1);
    try {
      waypoints =
          '$waypoints;${latLongs[idx].longitude},${latLongs[idx].latitude}';
    } catch (e) {
      debugPrint('Error getting points: ${e.toString()}');
    }
  }

  waypoints =
      '$waypoints;${latLongs[count - 1].longitude},${latLongs[count - 1].latitude}';

  return waypoints;
}
*/
/*
addWaypointAt({required LatLng pos, bool before = false}) async {
  String name = 'End';
  int idx = CurrentTripItem().pointsOfInterest.length;
  int markerType = 18;
  if (idx == 0 || before) {
    name = 'Start';
    idx = 0;
    markerType = 17;
  }
  PointOfInterest waypoint = PointOfInterest(
    id: -1,
    driveId: CurrentTripItem().driveId,
    type: markerType,
    name: name,
    description: '',
    width: 10,
    height: 10,
    point: pos,
  );
  if (before) {
    CurrentTripItem().pointsOfInterest.insert(0, waypoint);
  } else {
    CurrentTripItem().pointsOfInterest.add(waypoint);
  }
}
*/

String setAvoiding() {
  /// avoid = '&exclude=motorway,trunk,primary';
  /// The avoid categories are defined in OSRM/osrm-backend/car.lua
  String avoiding = '';
  if (Setup().avoidMotorways) {
    avoiding = '&exclude=motorway';
    if (Setup().avoidAroads) {
      avoiding = '&exclude=motorway,trunk,primary';
    }
  } else if (Setup().avoidAroads) {
    avoiding = '&exclude=trunk,primary';
  } else if (Setup().avoidFerries) {
    avoiding = '&exclude=ferry';
  } else if (Setup().avoidTollRoads) {
    avoiding = '&exclude=toll';
  }
  return avoiding;
}

/// For drives that have been generated by tracking there are no defined waypoints. The drive consists
/// of only the polylines, and hasn't been through the router to generate maneuvers. The challenge is to
/// provide calculated waypoints that the router can use to follow the route and generate the maneuvers.
/// Originally just used every nth point, but the number of points reflect the complexity of the route.
/// Roundabouts for example consume lots of points.
/// The next strategy is to look at the total length of the route by going through all the points, and
/// then space the calculated waypoints equidistant - with a target of around a mile apart for drives
/// < 50 miles 2 miles for drives > 50 < 100 etc. As long as the gaps aren't too great the router should
/// replicate the tracked trip. 50 points is the maximum number of points the router can take. Less than
/// 1 mile apart is unnecessary. As the points are calculated they should be removed from the maneuvers,
/// as they would constrain the drive in a way not defined by the user.
/// The user can then add any waypoints that are needed to control the route.
///
/// As of March 2026 for creation of a route
///   1 New Route object added to routes [Route]
///   2 All waypoints are added to the routes.waypoints[] list so even for a new route the waypoints already
///     belong to that route.

Future<RouterData> getRouterData(
    {required Route route,
    bool addPoints = true,
    bool goodRoad = false}) async {
  dynamic jsonResponse;
  int jump = 1;
  int points = route.waypoints.length;
  if (points == 0) {
    points = route.lines.length;
    jump = route.lines.length > 50 ? (points ~/ 50) : 1;
    jump = jump > 1 && jump * 50 > points ? jump - 1 : jump;
  }
  String delim = '';
  String waypoints = '';
  List<Waypoint> routeWaypoints = route.waypoints;
  for (int i = 0; i < points; i += jump) {
    if (route.waypoints.isEmpty) {
      waypoints = '$waypoints$delim${route.lines[i][0]},${route.lines[i][1]}';
      routeWaypoints
          .add(Waypoint(point: Point(route.lines[i][0], route.lines[i][1])));
    } else {
      waypoints =
          '$waypoints$delim${route.waypoints[i].point.x},${route.waypoints[i].point.y}';
    }
    delim = ';';
  }
  String avoid = setAvoiding();
  var url = Uri.parse(
      '$urlRouter$waypoints?steps=true&annotations=true&geometries=geojson&overview=full$avoid');
  try {
    var response = await http.get(url).timeout(const Duration(seconds: 8));
    if ([200, 201].contains(response.statusCode)) {
      jsonResponse = jsonDecode(response.body);
      if (jsonResponse == null) {
        return RouterData(message: 'Error');
      }
    } else {
      return RouterData(message: 'Error');
    }
  } catch (e) {
    debugPrint('Http error: ${e.toString()}');
    return RouterData(message: 'Error');
  }
  return RouterData.fromGeoJson(
      geoJson: jsonResponse, waypoints: routeWaypoints);
}

/// Processes the geoJson from the router to extract the maneuvers

List<Maneuver> getManeuversFromJson({required List routes, name = ''}) {
  List<Maneuver> maneuvers = [];

  try {
    String lastRoad = routes[0]['legs'][0]['steps'][0]['name'];
    int lastRoute = routes.length - 1;
    int lastLeg = routes[lastRoute]['legs'].length - 1;
    int lastStep = routes[lastRoute]['legs'][lastLeg]['steps'].length - 1;
    name =
        '$lastRoad - ${routes[lastRoute]['legs'][lastLeg]['steps'][lastStep]['name']}';
    String type = '';
    for (int i = 0; i < routes.length; i++) {
      List<dynamic> legs = routes[i]['legs'];

      for (int j = 0; j < legs.length; j++) {
        List<dynamic> steps = legs[j]["steps"];
        double distance = 0;

        int bearingBefore = 0;
        int bearingAfter = 0;
        for (int k = 0; k < steps.length; k++) {
          lastRoad = steps[k]['name'] ?? '';
          Map<String, dynamic> maneuver = steps[k]['maneuver'];
          try {
            type = maneuver['type'] ?? '';
            String modifier = maneuver['modifier'] ?? '';
            if ((modifier.isNotEmpty || type == 'depart')) {
              if (modifier.isEmpty) {
                debugPrint('empty');
              }

              if (type.contains('roundabout') || type.contains('rotary')) {
                try {
                  if (type.contains('exit')) {
                    bearingAfter = maneuver['bearing_after'] ?? 0;
                    modifier = bearingAfter > bearingBefore ? 'right' : 'left';
                    if ((bearingAfter - bearingBefore).abs() < 60) {
                      modifier = 'slightly $modifier';
                    }
                    //    modifier = '$modifier (${bearingAfter - bearingBefore})';
                    maneuvers[maneuvers.length - 1].modifier = modifier;
                    maneuvers[maneuvers.length - 1].bearingAfter = bearingAfter;
                  } else {
                    bearingBefore = maneuver['bearing_before'] ?? 0;
                  }
                } catch (e) {
                  developer.log('bearing error: ${e.toString()}',
                      name: '_roundabout');
                }
              } else {
                bearingBefore = maneuver['bearing_before'] ?? 0;
                bearingAfter = maneuver['bearing_after'] ?? 0;
              }

              Point lngLat =
                  Point(maneuver['location'][0], maneuver['location'][1]);

              distance += steps[k]['distance'].toDouble();
              maneuvers.add(
                Maneuver(
                  roadFrom: steps[k]['name'],
                  roadTo: lastRoad,
                  bearingBefore: bearingBefore,
                  bearingAfter: bearingAfter,
                  exit: maneuver['exit'] ?? 0,
                  point: lngLat,
                  modifier: modifier,
                  type: type,
                  distance: distance,
                ),
              );
              distance = 0;
            }
          } catch (e) {
            String err = e.toString();
            debugPrint(err);
          }
          if (maneuvers.length > 1) {
            maneuvers[maneuvers.length - 2].roadTo =
                maneuvers[maneuvers.length - 1].roadFrom;
          }
          if (maneuvers.isNotEmpty) {
            lastRoad = maneuvers[maneuvers.length - 1].roadTo;
            maneuvers[maneuvers.length - 1].type =
                maneuvers[maneuvers.length - 1]
                    .type
                    .replaceAll('rotary', 'roundabout');
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Error processing router data: ${e.toString()}');
  }
  return maneuvers;
}

/// Extracts the route length from the router geoJson

double getRouteLengthFromGeoJson(
    {required Map<String, dynamic> geoJson, String unit = 'mile'}) {
  double distance = 0;
  for (int i = 0; i < geoJson['routes'].length; i++) {
    try {
      distance += geoJson['routes'][i]['distance'].toDouble();
    } catch (e) {
      debugPrint('Error in getRoutePoints()  ${e.toString()}');
    }
  }
  distance = distance / 1000 * (unit == 'mile' ? 5 / 8 : 1);
  return double.parse(distance.toStringAsFixed(1));
}

double getRouteDurationFromGeoJson({required Map<String, dynamic> geoJson}) {
  double duration = 0;
  for (int i = 0; i < geoJson['routes'].length; i++) {
    duration += geoJson['routes'][i]['duration'].toDouble();
  }
  return duration;
}

RouteDelta distanceFromRoute(
    {required List<Route> routes,
    required Point position,
    RouteDelta? routeDelta,
    int trigger = 100}) {
  double distance = 200000;
  routeDelta ??= RouteDelta();
  routeDelta.point = position;
  routeDelta.distance = 200000;
  routeDelta.pointIndex = -1;
  for (int i = 0; i < routes.length; i++) {
    Route route = routes[i];
    for (int j = 0; j < route.lines.length; j++) {
      distance = distanceBetween(
          startXY: position, endList: route.lines[j]); //.toInt();
      if (distance < routeDelta.distance) {
        routeDelta.distance = distance;
        routeDelta.pointIndex = j;
        routeDelta.routeIndex = i;
        routeDelta.point = Point(route.lines[j][0], route.lines[j][0]);
      } else if (distance <= trigger) {
        break;
      }
    }
  }
  return routeDelta;
}

int getRoundaboutAngle(
    {required List<Maneuver> maneuvers,
    required int index,
    required List<Route> routes}) {
  int angle = 0;

  /// Next bit of code is to try and compensate for tangential lead-ins and run-offs that distort
  /// the radially aligned direction change that a roundabout sign displays.
  /// It does it by getting the angle of approach and leave angle at the distance of 25 - 100 m from
  /// the roundabout. Should help in most cases, though very large roundabouts could still be an issue.
  /// The bearingBefore and bearingAfter is at the point of joining or leaving the actual roundabout.
  try {
    if (maneuvers[index].type.contains('roundabout')) {
      if (maneuvers[index].type == 'roundabout') {
        int distance = 0;
        PositionData positionData =
            getClosestPoint(routes: routes, position: maneuvers[index].point);

        List<double> point1 = [0, 0];
        List<double> point2 = [0, 0];
        List<double> point3 = [0, 0];
        List<double> point4 = [0, 0];
/*
        Point point1 = Point(0, 0);
        Point point2 = Point(0, 0);
        Point point3 = Point(0, 0);
        Point point4 = Point(0, 0);
*/

        for (int i = positionData.pointIndex; i > 0; i--) {
          distance = distanceBetween(
                  startXY: maneuvers[index].point,
                  endList: routes[positionData.routeIndex].lines[i])
              .toInt();
          if (point2 == [0, 0] && distance > 25) {
            point2 = routes[positionData.routeIndex].lines[i];
          } else if ((point1 == [0, 0] && distance > 100) || i == 0) {
            point1 = routes[positionData.routeIndex].lines[i];
            break;
          }
        }

        positionData = getClosestPoint(
            routes: routes, position: maneuvers[index + 1].point);

        for (int i = positionData.pointIndex;
            i < routes[positionData.routeIndex].lines.length;
            i++) {
          distance = distanceBetween(
                  startXY: maneuvers[index + 1].point,
                  endList: routes[positionData.routeIndex].lines[i])
              .toInt();
          if (point3 == [0, 0] && distance > 25) {
            point3 = routes[positionData.routeIndex].lines[i];
          } else if ((point4 == [0, 0] && distance > 100) || i == 0) {
            point4 = routes[positionData.routeIndex].lines[i];
            break;
          }
        }

        int approachAngle = angleFromPoints(point1: point1, point2: point2);
        int leaveAngle = angleFromPoints(point1: point3, point2: point4);

        maneuvers[index].bearingBefore = approachAngle;
        maneuvers[index].bearingAfter = leaveAngle;

        /// Give the exit roundabout maneuver the same angles
        maneuvers[index + 1].bearingBefore = approachAngle;
        maneuvers[index + 1].bearingAfter = leaveAngle;

        // int deltaAngle = approachAngle - leaveAngle;
        // int summaryAngle = angleFromPoints(point1: point1, point2: point4);
        // leaveAngle = leaveAngle - approachAngle;

        ///   when the roundaboutPainter draws an arc it always starts at 3 O'Clock and paints clockwise
        ///   the painter describes all angles in radians but its angle parameter is degrees
        ///   the painter does the adjustment of the start from 3 O'Clock to 6 O'Clock
        ///   the painter adds the 180 degrees to represent straight on
        ///   the painter makes the adjustment from degrees to radians
        ///   approach angles will always be adjusted to N 0 degress
        ///   leave angles will adjusted to fit approach angles
        ///   the painter will be fed the arc in degrees to be transcribed from 6 O'Clock position
        ///
        ///   approach    exit     delta      painted arc (180 + delta)
        ///     |           |         0       180 degrees
        ///
        ///     |           /        45       225 degrees
        ///
        ///     |           \       -45       135 degrees
        ///
      }

      angle = maneuvers[index].bearingAfter - maneuvers[index].bearingBefore;
    }
  } catch (e) {
    debugPrint('Error calculating roundabout angle: ${e.toString()}');
  }
  return angle;
}

// getClosestPoint({int route = 0, int point = 0, bool full = true}) {
PositionData getClosestPoint(
    {List<Route> routes = const [],
    Point position = const Point(0, 0),
    int route = 0,
    int point = 0,
    bool full = true}) {
  PositionData positionData =
      PositionData(point, route, 9999999, 9999999, 99999999);
  int further = 0;
  for (int i = route; i < routes.length; i++) {
    for (int j = point; j < routes[i].lines.length; j++) {
      double distance =
          distanceBetween(startXY: position, endList: routes[i].lines[j]);
      if (distance < positionData.metersToRoute) {
        positionData.routeIndex = i;
        positionData.pointIndex = j;
        positionData.metersToRoute = distance.toInt();
        full = distance < 10 ? false : full;
        further = 0;
      } else {
        if (further++ > 10 && !full) {
          break;
        }
      }
    }
  }
  positionData.metersToRoute =
      positionData.metersToRoute == 999999999 ? 0 : positionData.metersToRoute;
  return positionData;
}

int angleFromPoints(
    {required List<double> point1, required List<double> point2}) {
  double lat1Rad = point1[1] * (pi / 180);
  double lng1Rad = point1[0] * (pi / 180);
  double lat2Rad = point2[1] * (pi / 180);
  double lng2Rad = point2[0] * (pi / 180);
  double avgLat = (lat1Rad + lat2Rad) / 2;
  double deltaLat = (lat2Rad - lat1Rad);
  double deltaLng = (lng2Rad - lng1Rad);
  double angleRad = atan2(deltaLng * cos(avgLat), deltaLat);
  return ((angleRad * 180 / pi + 360) % 360).toInt();
}

/// findManeuver finds the next / previous maneuver
///
int findManeuver(
    {required List<Maneuver> maneuvers,
    required Point position,
    currentIndex = 0,
    increment = 0}) {
  double distance = 0;
  int oldIndex = currentIndex;
  for (int i = 0; i < maneuvers.length; i++) {
    double delta = getDistance(
        maneuvers: maneuvers, position: position, index: currentIndex);
    if (distance > delta && i != currentIndex) {
      if (currentIndex > -1) {}
      currentIndex = i;
      distance = delta;
    }
  }
  if (oldIndex > -1 && increment == 0) {
    increment = currentIndex > oldIndex ? 1 : -1;
  }
  return currentIndex;
}

double getDistance(
    {required List<Maneuver> maneuvers,
    required Point position,
    int index = 0}) {
  if (index < maneuvers.length && index > -1) {
    return distanceBetween(startXY: position, endXY: maneuvers[index].point);
  }
  return 0;
}

/// Haversine calculation for the distance between two points on the globe
/// allows the locations to be specified as Point(x, y) or as [x, y]

double distanceBetween(
    {Point? startXY, Point? endXY, List? startList, List? endList}) {
  if ((startXY == null && startList == null) ||
      (endXY == null && endList == null)) {
    return 0;
  }
  double c = 0;
  var earthRadius = 6378137.0; // <-- in m   3958.8 in miles
  try {
    startXY ??= Point(startList![0], startList[1]);
    endXY ??= Point(endList![0], endList[1]);
    double startLatitude = startXY.y.toDouble();
    double startLongitude = startXY.x.toDouble();
    double endLatitude = endXY.y.toDouble();
    double endLongitude = endXY.x.toDouble();

    var dLat = _toRadians(endLatitude - startLatitude);
    var dLon = _toRadians(endLongitude - startLongitude);

    var a = pow(sin(dLat / 2), 2) +
        pow(sin(dLon / 2), 2) *
            cos(_toRadians(startLatitude)) *
            cos(_toRadians(endLatitude));
    c = 2 * asin(sqrt(a));
  } catch (e) {
    developer.log('Error calculating distance: ${e.toString()}',
        name: '_repaint_');
  }

  return earthRadius * c;
}

_toRadians(double degree) {
  return degree * pi / 180;
}
