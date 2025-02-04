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
