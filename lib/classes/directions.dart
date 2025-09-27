// import 'package:flutter/material.dart';
import 'package:drives/models/models.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

/// Class to handle the directions.
/// The index returned of the current Maneuver should:
/// 1 Initially be the closest to the current position
/// 2 Should change to the next one when the current one is reached.
///   This could be achied by recording the how far away the nearest
///   Maneuver is. When the distance changes from decreasing to increasing
///   then the currentIndex should point to that one.
/// 3 Directions will also return the distance as the crow flies
///   to the next Maneuver

class Directions {
  List<Maneuver> maneuvers = [];
  int startIndex = -1;
  int currentIndex = -1;
  int increment = 0;
  int passed = 0;
  double distance = 999999999;
  LatLng _position = const LatLng(0, 0);
  Function(int, int)? onDiverge; // = (idx, dist) => ();
  Directions();
  //     {required this.maneuvers,
  //     this.startIndex = 0,
  //     required this.position,
  //     required this.onDiverge});

  int nextManeuverIndex() {
    return currentIndex;
  }

  update({required LatLng position}) {
    _position = position;
    if (currentIndex == -1) {
      findNextManeuver(position: position);
    }
    double delta = getDistance(currentIndex);

    passed = delta > distance ? ++passed : 0;
    if (passed > 5) {
      distance = 999999;
      if (currentIndex == 0) {
        currentIndex++;
        increment = 1;
      } else {
        if (increment != 0) {
          currentIndex = currentIndex + increment;
          currentIndex = currentIndex < 0 ? 0 : currentIndex;
          currentIndex = currentIndex > maneuvers.length - 1
              ? maneuvers.length - 1
              : currentIndex;
        } else {
          findNextManeuver(position: position);
        }
      }
      delta = getDistance(currentIndex);
    }
    distance = distance > delta ? delta : distance;
    developer.log('directions.dart currentIndex : $currentIndex',
        name: '_maneuvers');
  }

  void findNextManeuver({required LatLng position}) {
    int oldIndex = currentIndex;
    for (int i = 0; i < maneuvers.length; i++) {
      double delta = getDistance(i);
      if (distance > delta && i != currentIndex) {
        if (currentIndex > -1) {}
        currentIndex = i;
        distance = delta;
      }
    }
    if (oldIndex > -1 && increment == 0) {
      increment = currentIndex > oldIndex ? 1 : -1;
    }
  }

  double getDistance(int i) {
    if (i < maneuvers.length && i > -1) {
      return Geolocator.distanceBetween(_position.latitude, _position.longitude,
          maneuvers[i].location.latitude, maneuvers[i].location.longitude);
    }
    return 0;
  }
}
