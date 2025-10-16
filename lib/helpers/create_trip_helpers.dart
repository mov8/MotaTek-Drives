import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/models.dart';
import 'package:drives/constants.dart';
import 'package:drives/classes/route.dart' as mt;

enum ChipRequest { none, arrow, burger, details }

Map<String, dynamic> chipRequests = {
  'ledingWidget': -1,
  'getTripDetails': false
};

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
          child: MarkerWidget(
            type: 18,
            description: 'Trip end',
            angle: 1 * pi / 180,
          ),
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
          child: MarkerWidget(
            type: 17,
            description: 'Trip start',
            angle: 1 * pi / 180,
          ),
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

Future<String> waypointsFromManeuvers(
    {int points = 50, reverse = false}) async {
  List<LatLng> latLongs = [];

  /// Only going to add the start, end, and any turns. The Router will do the rest

  /*
  for (int i = 0; i < CurrentTripItem().maneuvers.length; i++) {
    if (i == 0 ||
        i == CurrentTripItem().maneuvers.length - 1 ||
        CurrentTripItem().maneuvers[i].type == 'turn' ||
        CurrentTripItem().maneuvers[i].type.contains('exit')) {
      latLongs.add(CurrentTripItem().maneuvers[i].location);
    }
  }
  */
  latLongs.add(CurrentTripItem().maneuvers[0].location);
  latLongs.add(CurrentTripItem()
      .maneuvers[CurrentTripItem().maneuvers.length - 1]
      .location);

  if (reverse) {
    latLongs = latLongs.reversed.toList();
    return '${latLongs[0].longitude},${latLongs[0].latitude};${latLongs[1].longitude},${latLongs[1].latitude}';
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
      waypoints =
          '$waypoints$delimiter${latLongs[idx].longitude},${latLongs[idx].latitude}';
      delimiter = ';';
    } else {
      debugPrint('Index overflow');
    }
  }

  return waypoints;
}

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
    // int idx = (gap + 1) * (i + 1);
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
    child: MarkerWidget(
      type: markerType,
      description: '',
      angle: 1 * pi / 180,
      list: idx,
      listIndex: 0,
    ),
  );
  if (before) {
    CurrentTripItem().pointsOfInterest.insert(0, waypoint);
  } else {
    CurrentTripItem().pointsOfInterest.add(waypoint);
  }
}

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

Future<Map<String, dynamic>> getRoutePoints(
    {required List<LatLng> points, bool addPoints = true}) async {
  dynamic jsonResponse;
  String delim = '';
  String waypoints = '';
  int i;
  int jump = points.length > 50 ? (points.length ~/ 50) : 1;
  jump = jump > 1 && jump * 50 > points.length ? jump - 1 : jump;

  for (i = 0; i < points.length; i += jump) {
    waypoints = '$waypoints$delim${points[i].longitude},${points[i].latitude}';
    delim = ';';
  }

  String avoid = setAvoiding();
  var url = Uri.parse(
      '$urlRouter$waypoints?steps=true&annotations=true&geometries=geojson&overview=full$avoid');
  try {
    var response = await http.get(url).timeout(const Duration(seconds: 5));
    if ([200, 201].contains(response.statusCode)) {
      jsonResponse = jsonDecode(response.body);
      if (jsonResponse == null) {
        return {'msg': 'Error'};
      }
    } else {
      return {'msg': 'Error'};
    }
  } catch (e) {
    debugPrint('Http error: ${e.toString()}');
    return {'msg': 'Error'};
  }
  List<LatLng> routePoints = [];
  List<Maneuver> maneuvers = [];
  final Map<String, dynamic> result = {
    "name": '',
    "distance": '0.0',
    "duration": 0,
    "summary": '',
    "maneuvers": maneuvers,
    "points": routePoints,
  };

  double distance = 0;
  double duration = 0;
  try {
    distance = jsonResponse['routes'][0]['distance'].toDouble();
    duration = jsonResponse['routes'][0]['duration'].toDouble();
    distance = distance / 1000 * 5 / 8;
  } catch (e) {
    debugPrint('Error: $e');
  }
  String summary =
      '${distance.toStringAsFixed(1)} miles - (${(duration / 60).floor()} minutes)';

  /// ToDo: handling turn by turn:
  /// ...['steps'][n]['name'] => the current road name
  /// ...['steps'][n]['maneuver'][bearing_before'] => approach bearing
  /// ...['steps'][n]['maneuver'][bearing_after] => exit bearing
  /// ...['steps'][n]['maneuver']['location'] => latLng of intersection
  /// ...['steps'][n]['maneuver']['modifier'] => 'right', 'left' etc
  /// ...['steps'][n]['maneuver']['type'] => 'turn' etc
  /// ...['steps'][n]['maneuver']['name'] => 'Alexandra Road'
  ///
  /// jsonResponse['routes'][0]['legs'][0]['steps'].length gives number of steps
  /// Maybe use flutter_tts to provide voice
  /// var parts = str.split(':');
  /// var prefix = parts[0]

  // List<String> waypointList = waypoints.split(';');
  // CurrentTripItem().maneuvers.clear();

  // if (waypointList.length > 1 && waypointList[0] != waypointList[1]) {
  // includeWaypoints = true;  String lastRoad = name;

  String type = '';

  if (addPoints) {
    var router = jsonResponse['routes'][0]['geometry']['coordinates'];
    for (int i = 0; i < router.length; i++) {
      routePoints.add(LatLng(router[i][1], router[i][0]));
    }
  }

  try {
    List<dynamic> legs = jsonResponse['routes'][0]['legs'];
    String lastRoad = legs[0]['steps'][0]['name'];
    String name =
        '$lastRoad - ${legs[0]['steps'][legs[0]['steps'].length - 1]['name']}';
    for (int j = 0; j < legs.length; j++) {
      List<dynamic> steps = legs[j]["steps"];
      //  String _roadFrom = '';
      //  String _roadTo = '';
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

            List<dynamic> lngLat = maneuver['location'];
            distance += steps[k]['distance'].toDouble();
            maneuvers.add(
              Maneuver(
                roadFrom: steps[k]['name'],
                roadTo: lastRoad,
                bearingBefore: bearingBefore,
                bearingAfter: bearingAfter,
                exit: maneuver['exit'] ?? 0,
                location: LatLng(lngLat[1].toDouble(), lngLat[0].toDouble()),
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
          developer.log('lastRoad $lastRoad', name: '_roundabout');
          maneuvers[maneuvers.length - 1].type = maneuvers[maneuvers.length - 1]
              .type
              .replaceAll('rotary', 'roundabout');
        }
      }
    }
    result["name"] = name;
    result["distance"] = distance.toStringAsFixed(1);
    result["duration"] = jsonResponse['routes'][0]['duration'];
    result["summary"] = summary;
    result["maneuvers"] = maneuvers;
    result["points"] = routePoints;
  } catch (e) {
    debugPrint('Error processing router data: ${e.toString()}');
  }
  return result;
}

RouteDelta distanceFromRoute(
    {required List<mt.Route> routes,
    required LatLng position,
    RouteDelta? routeDelta,
    int trigger = 100}) {
  int distance = 200000;
  routeDelta ??= RouteDelta();
  routeDelta.point = position;
  routeDelta.distance = 200000;
  routeDelta.pointIndex = -1;
  for (int i = 0; i < routes.length; i++) {
    mt.Route route = routes[i];
    for (int j = 0; j < route.points.length; j++) {
      distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              route.points[j].latitude,
              route.points[j].longitude)
          .toInt();
      if (distance < routeDelta.distance) {
        routeDelta.distance = distance;
        routeDelta.pointIndex = j;
        routeDelta.routeIndex = i;
        routeDelta.point = route.points[j];
      } else if (distance <= trigger) {
        break;
      }
    }
  }
  return routeDelta;
}

/*

  void checkWaypoints({required List<PointOfInterest> pointsOfInterest}) {
    LatLng start = LatLng(0, 0);
    LatLng end = LatLng(0, 0);
    int wayPoints = 0;
    for (int i = 0; i < pointsOfInterest.length; i++) {
      if (pointsOfInterest[i].getType() == 17) {
        start = pointsOfInterest[i].point;
      }
      if (pointsOfInterest[i].getType() == 18) {
        end = pointsOfInterest[i].point;
      }
      if ([12, 17, 18, 19].contains(pointsOfInterest[i].getType())) {
        ++wayPoints;
      }
    }
    if (start == LatLng(0, 0)) {
      pointsOfInterest.insert(
        0,
        PointOfInterest(
          id: id,
          driveId: CurrentTripItem().driveId,
          type: 17,
          markerPoint: CurrentTripItem().routes[0].points[0],
          marker: MarkerWidget(
            type: 17,
            angle: -_mapRotation * pi / 180, // degrees to radians
            list: 0,
            listIndex: 0,
          ),
        ),
      );
    }
    if (end == LatLng(0, 0)) {
      pointsOfInterest.add(
        PointOfInterest(
          id: id,
          driveId: CurrentTripItem().driveId,
          type: 18,
          markerPoint: CurrentTripItem()
              .routes[0]
              .points[CurrentTripItem().routes.length],
          marker: MarkerWidget(
            type: 18,
            angle: -_mapRotation * pi / 180, // degrees to radians
            list: 0,
            listIndex: wayPoints - 1,
          ),
        ),
      );
    }
  }

  */

/*
Future<bool> changeTripStart(
    BuildContext context, Position currentPosition, LatLng screenCenter) async {
  final List<bool> values = [false, false, false, false, false];
  bool changed = await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("Change trip's start or end",
            style: TextStyle(fontSize: 26)),
        content: SizedBox(
          height: 350,
          child: Column(
            children: [
              CheckboxListTile(
                title: Text('Swap trip start with trip end',
                    style: TextStyle(fontSize: 18)),
                value: values[0],
                onChanged: (_) => setState(() => (values[0] = !values[0])),
              ),
              CheckboxListTile(
                title: Text('Join trip from your current position',
                    style: TextStyle(fontSize: 18)),
                value: values[1],
                onChanged: (_) => setState(() {
                  values[1] = !values[1];
                  values[2] = values[1] ? false : values[2];
                }),
              ),
              CheckboxListTile(
                title: Text('Join trip from position at screen centre',
                    style: TextStyle(fontSize: 18)),
                value: values[2],
                onChanged: (_) => setState(() {
                  values[2] = !values[2];
                  values[1] = values[2] ? false : values[1];
                }),
              ),
              CheckboxListTile(
                title: Text('Finish trip at your current position',
                    style: TextStyle(fontSize: 18)),
                value: values[3],
                onChanged: (_) => setState(() {
                  values[3] = !values[3];
                  values[4] = values[3] ? false : values[4];
                }),
              ),
              CheckboxListTile(
                title: Text('Finish trip from position at screen centre',
                    style: TextStyle(fontSize: 18)),
                value: values[4],
                onChanged: (_) => setState(() {
                  values[4] = !values[4];
                  values[3] = values[4] ? false : values[3];
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                bool changed = values[0] ||
                    values[1] ||
                    values[2] ||
                    values[3] ||
                    values[4];
                List<LatLng> points = [];
                LatLng newPoint;

                /// Now look at the waypoints
                /// 1 Reverse the current waypoints if required
                /// 2 Add the new waypoint for added start or end

                Map<String, dynamic> tripData = {};
                if (CurrentTripItem().routes.isNotEmpty && changed) {
                  List<LatLng> currentPoints = CurrentTripItem()
                      .routes[CurrentTripItem().routes.length - 1]
                      .points;

                  if (values[0]) {
                    points = waypointsFromPointsOfInterest(reversed: true);
                    tripData = await getRoutePoints(points: points);
                    currentPoints.clear();
                    currentPoints.addAll(tripData['points']);

                    CurrentTripItem().maneuvers.clear();
                    CurrentTripItem().maneuvers = tripData['maneuvers'];
                  }
                  if (values[1] || values[2] || values[3] || values[4]) {
                    /// 1 / 3 start  2 / 4 finish from current position / screenCentre
                    points = waypointsFromPointsOfInterest();
                    newPoint = values[1] || values[3]
                        ? LatLng(
                            currentPosition.latitude, currentPosition.longitude)
                        : LatLng(screenCenter.latitude, screenCenter.longitude);
                    if (values[1] || values[3]) {
                      tripData =
                          await getRoutePoints(points: [newPoint, points[0]]);
                      CurrentTripItem().routes.insert(
                            0,
                            mt.Route(
                                points: tripData['points'],
                                color: colourList[Setup().routeColour]),
                          );
                      tripData['maneuvers'].addAll(CurrentTripItem().maneuvers);
                      CurrentTripItem().maneuvers = tripData['maneuvers'];
                    } else {
                      tripData = await getRoutePoints(
                          points: [points[points.length - 1], newPoint]);
                      CurrentTripItem().routes.add(
                            mt.Route(
                                points: tripData['points'],
                                color: colourList[Setup().routeColour],
                                strokeWidth: 5),
                          );
                      CurrentTripItem().maneuvers.addAll(tripData['maneuvers']);
                    }
                  }
                }
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Ok', style: TextStyle(fontSize: 22))),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    ),
  );
  return changed;
}
*/
