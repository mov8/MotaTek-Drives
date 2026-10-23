import 'dart:math';
import 'package:drives/classes/classes.dart';

import '/models/models.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:latlong2/latlong.dart';
import 'package:flutter/widgets.dart';

Future<Position> getPosition() async {
  bool serviceEnabled;
  gl.LocationPermission permission;

  serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services not enabled.');
  }

  permission = await gl.Geolocator.checkPermission();
  if (permission == gl.LocationPermission.denied) {
    permission = await gl.Geolocator.requestPermission();
    if (permission == gl.LocationPermission.denied) {
      return Future.error('Location permissions denied.');
    }
    if (permission == gl.LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied. Check your settings');
    }
  }
  try {
    gl.Position glPosition = await gl.Geolocator.getCurrentPosition();
    Setup().lastPosition.pointXYList = [
      glPosition.longitude,
      glPosition.latitude
    ];
  } catch (e) {
    debugPrint('utilities.getPosition() error: ${e.toString()}');
  }
  return Setup().lastPosition;
}

double distanceBetween(Point point1, Point point2,
    {bool miles = true, bool meters = false}) {
  double distance = gl.Geolocator.distanceBetween(point1.y.toDouble(),
      point1.x.toDouble(), point2.y.toDouble(), point2.x.toDouble());
  if (meters) {
    return distance;
  }
  distance = distance / 1000;
  return miles ? distance / 8 * 5 : distance;
}

/// insertWaypointAt
///  Finds the correct position to put a waypoint in _pointsOfInterest when the user cuts the route
///  Only used when there are more than 2 waypoints
///  1  Finds the closest waypoint to the cut position
///  2  Checks is cut position is closer or further away from the waypoint before the closest to cut position
///
///   O-----------------O----X-----------------O

String unList(String listString) {
  if (listString.length > 2) {
    return listString.substring(1, listString.length - 1);
  } else {
    return listString;
  }
}

String getInitials({required String name}) {
  String initials = 'NA';
  while (name.contains('  ')) {
    name = name.replaceAll('  ', ' ');
  }
  try {
    initials = name.trim().split(' ').map((l) => l[0]).take(2).join();
  } catch (e) {
    debugPrint('getInitials error:[$name]');
  }
  return initials;
}

double roundDouble({required double value, required int places}) {
  var mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}

bool samePosition({required LatLng pos1, required LatLng pos2, places = 6}) {
  return (roundDouble(value: pos1.latitude, places: places) ==
          roundDouble(value: pos2.latitude, places: places) &&
      roundDouble(value: pos2.longitude, places: places) ==
          roundDouble(value: pos2.longitude, places: places));
}

List<int> closestWaypoints(
    {required List<Waypoint> waypoints, required Point point}) {
  List<int> idx = [-1, -1];
  List<double> distance = [999999999, 999999999];
  for (int i = 0; i < waypoints.length; i++) {
    double gap = distanceBetween(waypoints[i].point, point);
    if (gap < distance[0]) {
      idx[1] = idx[0];
      idx[0] = i;
      distance[1] = distance[0];
      distance[0] = gap;
    } else if (gap < distance[1]) {
      idx[1] = i;
      distance[1] = gap;
    }
  }
  return idx;
}
