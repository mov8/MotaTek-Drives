import 'package:drives/models/models.dart'; //my_trip_item.dart';
import 'package:latlong2/latlong.dart';

class TripArguments {
  final MyTripItem trip;
  final String origin;
  TripArguments(this.trip, this.origin);
}

/// List from OSRM car.lua preferences file
///    excludable = Sequence {
///        Set {'toll'},
///        Set {'motorway'},      -- motorway
///        Set {'trunk'},         -- A-road
///        Set {'primary'},       -- A-road
///        Set {'secondary'},     -- B-road
///        Set {'tertiary'},      -- B-road
///        Set {'unclassified'},  -- B-road
///        Set {'ferry'}
///    },
///
///

class TripPreferences {
  bool avoidMotorways;
  // bool avoidMainRoads;
  // bool avoidMinorRoads;
  bool avoidFerries;
  bool avoidTollRoads;
  int maxSpeed;
  bool isLeft = true;
  bool isRight = false;
  TripPreferences(
      {this.avoidMotorways = false,
      // this.avoidMainRoads = false,
      // this.avoidMinorRoads = false,
      this.avoidFerries = false,
      this.avoidTollRoads = false,
      this.maxSpeed = 70});
}

class TripsPreferences {
  bool northWest;
  bool northEast;
  bool southWest;
  bool southEast;
  bool currentLocation;
  bool isLeft = true;
  bool isRight = false;
  TripsPreferences({
    this.northWest = false,
    this.northEast = false,
    this.southWest = false,
    this.southEast = false,
    this.currentLocation = false,
  });
}

class ViewportFence {
  LatLng topRight;
  LatLng bottomLeft;
  double margin;
  bool refresh = false;
  ViewportFence(
      {required LatLng topRight, required LatLng bottomLeft, this.margin = 0.5})
      : topRight = setFence(location: topRight, margin: margin),
        bottomLeft = setFence(location: bottomLeft, margin: margin * -1);

  bool fenceUpdated({required LatLng northEast, required LatLng southWest}) {
    if (isOutside(fence: topRight, location: northEast) ||
        isOutside(fence: bottomLeft, location: southWest)) {
      topRight = setFence(location: northEast, margin: margin);
      bottomLeft = setFence(location: southWest, margin: margin * -1);
      return true;
    }
    return false;
  }

  bool isOutside({required LatLng fence, required LatLng location}) {
    return ((location.latitude < fence.latitude ||
                location.longitude < fence.longitude) &&
            fence == bottomLeft) ||
        ((location.latitude > fence.latitude ||
                location.longitude > fence.longitude) &&
            fence == topRight);
  }
}

LatLng setFence({required LatLng location, required double margin}) {
  /// One degree latitude is ~ 69.172 miles
  /// One degree longitude at the Equator is ~ 69.172 miles
  /// E-W delta * degree long = (Lat degrees decimal - 90) * Pi / 180
  double longMargin =
      1 / ((90 - (location.latitude + margin)) * pi / 180).abs() * margin;
  return LatLng(location.latitude + margin, location.longitude + longMargin);
}
