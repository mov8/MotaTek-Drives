//import '/classes/classes.dart';
// import '/classes/other_classes.dart';
import '/helpers/create_trip_helpers.dart';

import '/models/models.dart';
import '/constants.dart';
import '/classes/route.dart' as mt;
// import '/helpers/create_trip_helpers.dart';
// import '/classes/classes.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;
//import 'dart:math';

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
  int nextIndex = -1;

  LatLng _position = const LatLng(0, 0);
  Function(int, int)? onDiverge;
  Directions();
  int nextManeuverIndex() {
    return currentIndex;
  }

  update({required LatLng position}) {
    _position = position;
    if (currentIndex == -1) {
      findNextManeuver(position: position);
    }
    double delta = getDistance(currentIndex);
    if (delta > distance) {
      passed++;
    } else {
      distance = delta;
      passed = 0;
    }
    if (passed > 5) {
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
      passed = 0;
      distance = 999999999;
      delta = getDistance(currentIndex);
    }
    distance = distance > delta ? delta : distance;
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

class PositionData {
  int pointIndex = 0;
  int routeIndex = 0;
  int metersToNextManeuver = 0;
  int metersToLastManeuver = 0;
  int metersToRoute = 0;
  PositionData(this.pointIndex, this.routeIndex, this.metersToRoute,
      this.metersToNextManeuver, this.metersToLastManeuver);
}

class DirectionDescriptors {
  List<Maneuver> maneuvers = [];
  String driveId;
  List<mt.Route> routes;
  DirectionDescriptors(
      {required this.driveId, required this.maneuvers, required this.routes});
  List<String> promptFiles = [];
  bool mp3sLoaded = false;
  int _sweepAngle = 0;
  int _roundabout = -1;
  String _roadTo = '';
  String _roadFrom = '';
  double nextDistance = -1;
  bool addSpeech = false;
  int soundIndex = 0;

  final List<String> type = [
    "depart",
    "continue",
    "turn",
    "roundabout",
    "exit roundabout",
    "end of road",
    "new name",
    "fork",
    "arrive"
  ];

  final List<String> modifier = [
    "left",
    "right",
    "straight",
    "slight left",
    "slight right"
  ];
  int soundTrigger = 3; // 2 = 0.5 miles, 1 = 0.1 miles, 0 = 10 meters

  List<String> getDescriptors() {
    List<String> descriptors = [];
    for (int i = 0; i < maneuvers.length; i++) {
      descriptors.add(getDirections(maneuverIndex: i)['heading'] ?? '');
    }
    return descriptors;
  }

  /// When the next maneuver is a roundabout have to calculate the correct
  /// approach and leave angles. The problem is cased by tangential lead-ins
  /// and lead-outs which OSM Maps uses for the angleBefore and angleAfter
  /// this gives misleading sweepAngles that won't correspond to the signs
  /// that the driver sees.
  /// The solution is to take two points before and two points after the
  /// roundabout and calculate the direction change angle.
  /// Will try taking a point 50m away and the next furthest point for the
  /// two lines to calculate the angle.

  Map<String, dynamic> getDirections(
      {int maneuverIndex = 0,
      double metersToManeuver = 9999999999,
      LatLng position = const LatLng(0, 0),
      int error = 0}) {
    Map<String, dynamic> directions = {};

    /// Errors  0 = on-track
    ///         1 = Left route
    ///         2 = Still off route
    ///         3 = Request re-route
    ///         4 = Still off route

    /// maneuvers structure:
    /// bearingAfter = 36
    /// bearingBefore = 0
    /// distance =  42.7
    /// driveId = 5
    /// exit = 0
    /// hashCode = 86790978
    /// id = 64
    /// location = LatLng (LatLng(latitude:52.972026, longitude:-0.024118))
    /// modifier = ["left", "right", "straight", "slight left", "slight right"
    /// roadFrom = "Oxford Street" <- road before maneuvers
    /// roadTo = "Oxford Street" <- road after maneuver
    /// runtimeType = Type (Maneuver)
    /// type = ["depart", "continue", "turn", "roundabout", "exit roundabout", "end of road", "new name", "fork", "arrive"]
    ///

    /// type is the key determinator of the descriptor
    ///   1 depart: "depart from {roadFrom} and drive {distance} {roadFrom != roadTo => towards roadTo} "
    ///   2 continue: (haven't changed roads but modifier is actioned)
    ///   3 turn: roadFrom is the road about to tun into roadTo is the road heading towards -
    ///           "turn {modifier} into {roadFrom}  {roadFrom != roadTo => towards roadTo} "
    ///   4 roundabout: "at the roundabout in {distance} take the {exit} exit"
    ///   5 exit roundabout: "exit the roundabout {roadFrom != roadTo => towards roadTo}"
    ///   6 end of road: "at end of road turn {modifier} {roadFrom != roadTo => towards roadTo}"
    ///   7 new name: "continue {modifier} {roadFrom != roadTo => towards roadTo}"
    ///   8 turn: "turn {modifier} {roadFrom != roadTo => towards roadTo}"
    ///   9 fork: "fork {modifier} {roadFrom != roadTo => towards roadTo}"
    ///  10 arrive: "arrive at your destination {roadTo}"

    /// When the _nextManeuverIndex changes it's then pointing to the next waypoint
    /// so the next waypoint's road_from is our next destination
    ///
    /// For the sound prompts will use the strategy of:
    ///   When the maneuver changed then prompt the next maneuver
    ///   If the maneuver change prompt was > 500m before the maneuver then prompt at 100m
    if (error == 0) {
      int nextManeuverIndex = maneuverIndex < maneuvers.length - 2
          ? maneuverIndex + 1
          : maneuverIndex;
      if (maneuvers[nextManeuverIndex].type == 'roundabout' &&
          nextManeuverIndex != _roundabout) {
        _sweepAngle = getRoundaboutAngle(
            maneuvers: maneuvers, index: nextManeuverIndex, routes: routes);
        _roundabout = nextManeuverIndex;
      }
      Maneuver? maneuver;
      if (maneuverIndex >= 0) {
        maneuver = maneuvers[maneuverIndex];
      }
      if (maneuver != null) {
        if (_roadTo.isEmpty) {
          _roadTo = maneuver.roadTo;
        }
        if (_roadFrom.isEmpty) {
          _roadFrom = maneuver.roadFrom;
        }
        if (_roadTo != maneuver.roadFrom) {
          _roadFrom = _roadTo;
          _roadTo = maneuver.roadFrom;
        }
      }
      soundIndex = maneuverIndex > soundIndex ? maneuverIndex + 1 : soundIndex;
      directions['heading'] = prompts(
              maneuver: maneuver!,
              metersToManeuver: metersToManeuver,
              maneuverIndex: maneuverIndex)["heading"] ??
          "";
      directions['subheading'] = prompts(
              maneuver: maneuver,
              metersToManeuver: metersToManeuver,
              maneuverIndex: maneuverIndex)["subheading"] ??
          "";

      directions['speech'] = sounds(
          maneuver: maneuver,
          metersToManeuver: metersToManeuver,
          maneuverIndex: maneuverIndex);
    } else {
      directions['speech'] = {'sound': '', 'file': ''};
      if (error < 3) {
        directions['heading'] = 'you have left the route - turn around';
        directions['subheading'] = 'turn around and rejoin the route';
        if (error == 1) {
          directions['speech'] = {
            'sound': 'You have left the root. Please turn around',
            'file': 'left_route.mp3'
          };
          error = 2;
        }
      } else {
        directions['heading'] = 'tap here to re-route';
        directions['subheading'] = 're-join the route at the next waypoint';
        if (error == 3) {
          directions['speech'] = {
            'sound':
                'Tap the panel at the top of the screen to calculate a new root',
            'file': 'reroute.mp3'
          };
        }
      }
    }
    return directions;
  }

  double distanceToTurn({required int index}) {
    double distance = 0;
    for (int i = index; i < maneuvers.length; i++) {
      if (['new name', 'continue'].contains(maneuvers[i].type)) {
        distance += maneuvers[i].distance;
      } else {
        break;
      }
    }
    return distance;
  }

  double metersToNextManeuver({required index}) {
    if (index > 0 && index < maneuvers.length) {
      return Geolocator.distanceBetween(
        maneuvers[index].location.latitude,
        maneuvers[index].location.longitude,
        maneuvers[index + 1].location.latitude,
        maneuvers[index + 1].location.longitude,
      );
    } else {
      return 0;
    }
  }

  String exitName(int exit) {
    switch (exit) {
      case 1:
        return 'first exit';
      case 2:
        return 'second exit';
      case 3:
        return 'third exit';
      case 4:
        return 'fourth exit';
      case 5:
        return 'fifth exit';
      case 6:
        return 'sixth exit';
      default:
        return 'exit';
    }
  }

  String exitDescriptor({required int sweepAngle}) {
    String direction = _sweepAngle < 0 ? 'left' : 'right';
    int testAngle = _sweepAngle.abs();
    String adverb = '';
    if (testAngle < 10) {
      return 'straight on';
    } else if (testAngle < 45) {
      adverb = 'slightly ';
    } else if (testAngle < 135) {
      adverb = 'sharp ';
    } else {
      adverb = 'go right around';
      direction = '';
    }
    return '$adverb$direction';
  }

  Map<String, String> prompts(
      {required Maneuver maneuver,
      required double metersToManeuver,
      required int maneuverIndex,
      bool forSound = false}) {
    if (maneuver.type == 'depart') {
      metersToManeuver = maneuver.distance;
    }
    String distance =
        distancePrompt(meters: metersToManeuver, forSound: forSound);
    String towards = maneuver.roadFrom != maneuver.roadTo
        ? 'towards ${maneuver.roadTo}'
        : '';
    Map<String, dynamic> headingTypes = {
      'depart':
          "depart ${maneuver.roadFrom.isNotEmpty ? 'from ${maneuver.roadFrom}' : ''}'",
      'continue':
          "continue ${maneuver.modifier} for ${distancePrompt(meters: distanceToTurn(index: maneuverIndex), forSound: forSound)}",
      'turn': "in $distance turn ${maneuver.modifier}",
      'roundabout':
          "at the roundabout in $distance take the ${exitName(maneuver.exit)}",
      'exit roundabout': "exit the roundabout", // along $towards",
      'end of road': "at end of road in $distance turn ${maneuver.modifier}",
      'new name': "continue ${maneuver.modifier}",
      'fork':
          "fork ${maneuver.modifier.replaceAll('slight ', 'slightly ')} in $distance ",
      'arrive': "arrive at your destination ${maneuver.roadTo}"
    };
    Map<String, dynamic> subheadingTypes = {
      'depart':
          "depart from ${maneuver.roadFrom} turn ${maneuver.modifier} in $distance; $towards",
      'continue':
          "continue ${maneuver.modifier} for ${distancePrompt(meters: distanceToTurn(index: maneuverIndex), forSound: forSound)}",
      'turn':
          "in $distance turn ${maneuver.modifier} into ${maneuver.roadFrom}  $towards",
      'roundabout':
          "at the roundabout in $distance take the ${exitName(maneuver.exit)}",
      'exit roundabout':
          "exit the roundabout take ${maneuver.roadFrom} $towards",
      'end of road':
          "at end of road in $distance turn ${maneuver.modifier} along ${maneuver.roadFrom} $towards",
      'new name': "continue ${maneuver.modifier} $towards",
      'fork':
          "fork ${maneuver.modifier} in $distance into ${maneuver.roadFrom} $towards",
      'arrive': "arrive at your destination ${maneuver.roadTo}"
    };
    return {
      "heading": headingTypes[maneuver.type],
      "subheading": subheadingTypes[maneuver.type]
    };
  }

  /// The aim is to get a good compramise between information and cacheability. The mp3 filename will be based on:
  ///   The maneuver.type

/*
  final List<String> type = [
    "depart",
    "continue",
    "turn",
    "roundabout",
    "exit roundabout",
    "end of road",
    "new name",
    "fork",
    "arrive"
  ];

  final List<String> modifier = [
    "left",
    "right",
    "straight",
    "slight left",
    "slight right"
  ];
*/
  Map<String, String> sounds(
      {required Maneuver maneuver,
      required double metersToManeuver,
      required int maneuverIndex}) {
    /// Valid distances 0.5 miles 0.1 miles 10 meters
    /// exception is "exit roundabout" which is valid after the roundabout is entered
    /// soundTrigger = 2; // 2 = 0.5 miles, 1 = 0.1 miles, 0 = 10 meters
    /// 1609 = 1 mile  804 = half a mile  161 = a tenth
    /// file name sp_type_modifier_distance_.mp3

    //   if (maneuver.type == 'exit roundabout') {
    //     soundTrigger = 2;
    //     soundIndex++;
    //   }
    String distance = '';

    /// Want to ensure that the sound is only generated once.
    /// Can't be sure that the maneuver is any particular distance
    /// away when its first encountered.

    if (soundIndex != maneuverIndex) {
      return {"sound": "", "file": ""};
    }
    if (['turn', 'roundabout', 'end of road', 'fork'].contains(maneuver.type)) {
      if (metersToManeuver <= 10) {
        distance = "in ten yards";
        soundIndex = maneuverIndex + 1;
        soundTrigger = 3;
      } else if (metersToManeuver <= 161 &&
          metersToManeuver > 100 &&
          soundTrigger != 1) {
        distance = "in a tenth of a mile";
        soundTrigger = 1;
      } else if (metersToManeuver <= 804 &&
          metersToManeuver > 500 &&
          soundTrigger != 2) {
        distance = "in half a mile";
        soundTrigger = 2;
      } else {
        return {"sound": "", "file": ""};
      }
    } else {
      soundIndex = maneuverIndex + 1;
      soundTrigger = 3;
    }

    //  ['turn', 'roundabout', 'end of road', 'fork']

    Map<String, dynamic> directionTypes = {
      'depart': "Start your drive",
      'continue':
          "continue ${maneuver.modifier == 'straight' ? 'straight on' : maneuver.modifier}",
      'turn':
          "$distance turn ${maneuver.modifier.replaceAll('slight ', 'slightly ')}",
      'roundabout':
          "at the roundabout $distance take the ${exitName(maneuver.exit)}",
      'exit roundabout': "exit the roundabout",
      'end of road': "at end of road $distance turn ${maneuver.modifier}",
      'new name': "continue ${maneuver.modifier}",
      'fork':
          "fork ${maneuver.modifier.replaceAll('slight ', 'slightly ')} $distance",
      'arrive': "arrive at your destination"
    };

    String fileName =
        'sp_${type.indexOf(maneuver.type)}_${modifier.indexOf(maneuver.modifier)}_${soundTrigger}_${maneuver.exit}_${Setup().maleVoice}.mp3';

    developer.log(
        'directions 446 soundIndex: $soundIndex, maneuverIndex: $maneuverIndex  soundTrigger: $soundTrigger metersToManeuver: $metersToManeuver sound: ${directionTypes[maneuver.type]} file: $fileName',
        name: '_sound');

    return {"sound": directionTypes[maneuver.type], "file": fileName};
  }

  String distancePrompt({required double meters, bool forSound = false}) {
    if (forSound) {
      return doubleToSpeech(number: meters);
    }
    return modifyDistance(meters);
  }

  String modifyDistance(double distance) {
    if (distance < 5) {
      return '';
    }
    if (distance < oneTenthMile) {
      return '${(distance * metersToYards).toInt()} yards';
    }
    if (distance * metersToMiles < 0.25) {
      int tenth = distance ~/ oneTenthMile;
      if (tenth == 1) {
        return 'one tenth of a mile';
      }
      return '${distance ~/ oneTenthMile} thenths of a mile';
    }
    return '${(simplifyMiles(distance * metersToMiles)).toStringAsFixed(2)} miles';
  }

  double simplifyMiles(double number) {
    if (number > 10) {
      return number.roundToDouble();
    } else {
      double decimalPlace = number - number.truncateToDouble();
      switch (decimalPlace) {
        case < 0.15:
          return number.truncateToDouble();
        case < 0.35:
          return number.truncateToDouble() + 0.25;
        case < 0.65:
          return number.truncateToDouble() + 0.5;
        case < 0.85:
          return number.truncateToDouble() + 0.75;
        default:
          return number.truncateToDouble() + 1;
      }
    }
  }

  /// Simplified sound prompt generator to make offlike sounds possible
  /// the sounds have to be rationalised.
  /// The distance triggers are:
  ///   in one mile
  ///   in a quarter of a mile
  ///   at the maneuver
  /// The prompt will be based on the maneuver type
  /// The Map returned will have the generated mp3 file name

  Map<String, String> doubleToSound({required Maneuver maneuver}) {
    Map<String, String> sound = {};

    return sound;
  }

  String doubleToSpeech({required double number}) {
    if (number < oneTenthMile) {
      return '${(number * metersToYards).toInt()} yards';
    }

    if (number * metersToMiles < 0.25) {
      int tenth = number ~/ oneTenthMile;
      if (tenth == 1) {
        return 'one tenth of a mile';
      }
      return '${number ~/ oneTenthMile} thenths of a mile';
    }

    number = number * metersToMiles;
    number = simplifyMiles(number);
    double decimalPlace = number - number.truncateToDouble();
    String prescript = number.truncate() > 0 ? '${number.toInt()} and' : '';
    String postscript =
        number.truncate() > 0 ? 'and three quarter' : 'three quarters of a ';
    String distance = number.truncate() > 0 ? 'miles' : 'mile';
    // a quarter of a mile      10 and a quarter miles
    // three quarters of a mile 10 and three quarter miles
    switch (decimalPlace) {
      case 0.25:
        return '$prescript a quarter $distance';
      case 0.5:
        return '$prescript a half $distance';
      case 0.75:
        return '$prescript $postscript $distance';
      default:
        return '${number.toInt()} $distance';
    }
  }
}
