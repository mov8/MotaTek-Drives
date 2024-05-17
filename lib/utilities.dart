import 'dart:math';
import 'package:drives/models.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/widgets.dart';

Future<Position> getPosition() async {
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
  return await Geolocator.getCurrentPosition();
}

double distanceBetween(LatLng point1, LatLng point2, {bool miles = true}) {
  const double degreeToRadians = 0.0174532925; // degrees to radians pi/180
  double earthRadius =
      miles ? 3959 : 6371; // earth's radius in miles / kilometers
  double dist = 1 -
      cos((point2.latitude - point1.latitude) * degreeToRadians) +
      cos(point1.latitude * degreeToRadians) *
          cos(point2.latitude) *
          (1 - cos((point2.longitude - point1.longitude) * degreeToRadians));

  dist = earthRadius * asin(sqrt(dist));

  return dist;
}

/// insertWaypointAt
///  Finds the correct position to put a waypoint in _pointsOfInterest when the user cuts the route
///  Only used when there are more than 2 waypoints
///  1  Finds the closest waypoint to the cut position
///  2  Checks is cut position is closer or further away from the waypoint before the closest to cut position
///
///   O-----------------O----X-----------------O

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

      debugPrint('Distance between points $temp');
      if (temp < distance) {
        distance = temp;
        index = j - 1;
      }
      j++;
    }
  }
  if (index == 0) return 0;

  if (distanceBetween(pointsOfInterest[index - 1].point, pointToFind) >
      distanceBetween(
          pointsOfInterest[index - 1].point, pointsOfInterest[index].point)) {
    index++;
  }

  return index;
}

String getInitials({required String name}) {
  return name.isEmpty
      ? 'NA'
      : name.trim().split(' ').map((l) => l[0]).take(2).join();
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
