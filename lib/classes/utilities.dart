import 'dart:math';
import 'package:drives/classes/classes.dart';

import '/models/models.dart';
import '/classes/route.dart' as mt_rt;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/widgets.dart';

Future<Position> getPosition() async {
  // debugPrint('Starting getPosition...');
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services not enabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied. Check your settings');
    }
  }
  try {
    Setup().lastPosition = await Geolocator.getCurrentPosition();
    //  debugPrint('utilities.getPosition() retuning position');
  } catch (e) {
    debugPrint('utilities.getPosition() error: ${e.toString()}');
  }
  return Setup().lastPosition;
}

double distanceBetween(Point point1, Point point2,
    {bool miles = true, bool meters = false}) {
  double distance = Geolocator.distanceBetween(point1.y.toDouble(),
      point1.x.toDouble(), point2.y.toDouble(), point2.x.toDouble());
  if (meters) {
    return distance;
  }
  distance = distance / 1000;
  return miles ? distance / 8 * 5 : distance;

  /*
  double earthRadius =
      miles ? 3959 : 6371; // earth's radius in miles / kilometers
  double dist = 1 -
      cos((point2.latitude - point1.latitude) * degreeToRadians) +
      cos(point1.latitude * degreeToRadians) *
          cos(point2.latitude) *
          (1 - cos((point2.longitude - point1.longitude) * degreeToRadians));

  dist = earthRadius * asin(sqrt(dist));

  return dist;
  */
}

/// insertWaypointAt
///  Finds the correct position to put a waypoint in _pointsOfInterest when the user cuts the route
///  Only used when there are more than 2 waypoints
///  1  Finds the closest waypoint to the cut position
///  2  Checks is cut position is closer or further away from the waypoint before the closest to cut position
///
///   O-----------------O----X-----------------O

/*
int insertWayointAt(
    {required List<PointOfInterest> pointsOfInterest,
    required LatLng pointToFind}) {
  int index = 0;
  int j = 0;
  double distance = 9999999;
  double temp;

  if (pointsOfInterest.length < 2) {
    return -1;
  } else if (pointsOfInterest.length == 2) {
    return 0;
  } else {
    /// 1 Iterate down pointsOfInterst to find nearest POI to target position - pointToFind
    /// 2 If target position <
    for (PointOfInterest poi in pointsOfInterest) {
      temp = distanceBetween(poi.point, pointToFind);

      //   debugPrint('Distance between points $temp');
      if (temp < distance) {
        distance = temp;
        index = j;
      }
      j++;
    }
  }
  

  ///   O--------------X--O---------------------O    cut nearest next waypoint      index = j - 1
  ///   O-----------------O--X------------------O    cut nearest previous waypoint  index = j + 1

  if (index == 0) return 0;

  if (index == pointsOfInterest.length - 1) return index - 1;

  if (distanceBetween(pointsOfInterest[index - 1].point, pointToFind) >
      distanceBetween(
          pointsOfInterest[index - 1].point, pointsOfInterest[index].point)) {
    index++;
  }

  return index - 1;
}
*/

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

/*
int closestWWaypoint({required List<Waypooint> waypoints, required Point point}) {
  int idx = -1;
  double distance = 999999999;
  for (int i = 0; i < waypoints.length; i++) {
    double gap = distanceBetween(waypoints[i].point, point);
    if (gap < distance) {
      idx = i;
      distance = gap;
    }
  }
  return idx;
}
*/
List<int> closestWaypoints(
    {required List<Point> waypoints, required Point point}) {
  List<int> idx = [-1, -1];
  List<double> distance = [999999999, 999999999];
  for (int i = 0; i < waypoints.length; i++) {
    double gap = distanceBetween(waypoints[i], point);
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

/*
double closestWaypoint(
    {required List<PointOfInterest> pointsOfInterest,
    required LatLng location}) {
  double distance = 9999;
  for (int i = 0; i < pointsOfInterest.length; i++) {
    distance =
        min(distanceBetween(pointsOfInterest[i].point, location), distance);
  }
  return distance;
}

*/
/*
double distanceAlongRoute({required List<mt_rt.Route> routes}) {
  double distance = 0;
  for (mt_rt.Route root in routes) {
    for (int i = 1; i < root.points.length; i++) {
      distance += distanceBetween(root.points[i], root.points[i - 1]);
    }
  }
  return distance;
}
*/
