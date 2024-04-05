import 'package:geolocator/geolocator.dart';
import 'dart:math';

import 'package:latlong2/latlong.dart';

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
  double p = 0.0174532925; // degrees to radians pi/180
  double er = miles ? 3982 : 6371; // earth's radius in miles / kilometers
/*
  double dist = sin(point1.latitude * p) * sin(point2.latitude * p);
  dist += cos(point1.latitude * p) *
      cos((point2.longitude - point1.longitude) * p) *
      er;

  dist = acos(dist).abs();
  
  double dist = acos(sin(point1.latitude * p) * sin(point2.latitude * p) +
          cos(point1.latitude * p) *
              cos((point2.longitude - point1.longitude) * p) *
              er)
      .abs(); // 6371
  */

  double dist = 0.5 -
      cos((point2.latitude - point1.latitude) * p) / 2 +
      cos(point1.latitude * p) *
          cos(point2.latitude) *
          (1 - cos((point2.longitude - point1.longitude) * p)) /
          2;
  dist = miles ? 7963.75 * asin(sqrt(dist)) : 12742 * asin(sqrt(dist));

  return dist;
}
