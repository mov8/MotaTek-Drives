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

String getInitials({required String name}) {
  return name.isEmpty
      ? 'NA'
      : name.trim().split(' ').map((l) => l[0]).take(2).join();
}

double roundDouble({required double value, required int places}) {
  var mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}
