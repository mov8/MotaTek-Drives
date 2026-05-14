//import '/models/models.dart'; //my_trip_item.dart';
import 'dart:math';
import '/classes/classes.dart';
import '/helpers/helpers.dart';
import '../models/other_models.dart';
// import 'package:flutter/widgets.dart';
import '/constants.dart';
import 'package:latlong2/latlong.dart';
/*
            id: groupData['id'],
            name: groupData['name'],
            unreadMessages:
                groupData['messages'] - int.parse(groupData['read']),
            messages: groupData['messages'],
*/

class MailItem {
  final String id;
  final String name;
  final int unreadMessages;
  final int received;
  final int sent;
  final int read;
  final int messages;
  final bool isGroup;
  final String email;
  MailItem({
    this.id = '',
    this.name = '',
    this.unreadMessages = 0,
    this.received = 0,
    this.sent = 0,
    this.read = 0,
    this.messages = 0,
    this.isGroup = false,
    this.email = '',
  });
}

class TripArguments {
  final MyTripItem trip;
  final String origin;
  final String groupDriveId;
  TripArguments(this.trip, this.origin, {this.groupDriveId = ''});
}

class MutableInt {
  int value;
  MutableInt({this.value = -1});
}

class Position {
  double _longitude;
  double _latitude;
  Point _pointXY;
  List<double> _pointXYList;
  Position(
      {double? longitude,
      double? latitude,
      Point? pointXY,
      List<double>? pointXYList})
      : _longitude = longitude ?? 0,
        _latitude = latitude ?? 0,
        _pointXY = pointXY ?? Point(0, 0),
        _pointXYList = pointXYList ?? [0, 0];

  double get longitude => _longitude + _pointXY.x + _pointXYList[0];
  double get latitude => _latitude + _pointXY.y + _pointXYList[1];
  Point get pointXY => Point(_longitude + _pointXY.x + _pointXYList[0],
      _latitude + _pointXY.y + _pointXYList[1]);
  List<double> get pointXYList => [
        _longitude + _pointXY.x + _pointXYList[0],
        _latitude + _pointXY.y + _pointXYList[1]
      ];
  set latitude(double value) {
    _latitude = value;
    _pointXY = Point(_pointXY.x, 0);
    _pointXYList[1] = 0;
  }

  set longitude(double value) {
    _longitude = value;
    _pointXY = Point(0, _pointXY.y);
    _pointXYList[0] = 0;
  }

  set pointXY(Point value) {
    _latitude = 0;
    _longitude = 0;
    _pointXY = value;
    _pointXYList = [0, 0];
  }

  set pointXYList(List<double> value) {
    _latitude = 0;
    _longitude = 0;
    _pointXY = Point(0, 0);
    _pointXYList = value;
  }
}

class Waypoint {
  final int value;
  final Point point;
  bool? selected;
  final bool isGoodRoad;
  String colour;
  Waypoint(
      {this.value = 0,
      Point? point,
      bool? selected,
      this.isGoodRoad = false,
      String? colour})
      : point = point ?? Point(0, 0),
        colour = colour ?? Setup().routeColourHex(),
        selected = selected ?? false;

  Map<String, dynamic> toMap() {
    return {
      "point": [point.x, point.y],
      "selected": false,
      "colour":
          isGoodRoad ? Setup().goodRouteColourHex : Setup().routeColourHex(),
      "is_good_road": isGoodRoad,
    };
  }

  factory Waypoint.fromMap({required Map<String, dynamic> map}) {
    return Waypoint(
        colour: map["colour"],
        point: Point((map["point"] ?? [0, 0])[0], (map["point"] ?? [0, 0])[1]),
        selected: false,
        isGoodRoad: map["is_good_road"] ?? false);
  }

  factory Waypoint.clone({required Waypoint waypoint}) {
    return Waypoint(
      colour: waypoint.colour,
      point: waypoint.point,
      selected: false,
      isGoodRoad: waypoint.isGoodRoad,
    );
  }
}

class RouteDelta {
  double distance;
  int routeIndex;
  int pointIndex;
  Point point;
  RouteDelta(
      {this.distance = 0,
      this.routeIndex = -1,
      this.pointIndex = -1,
      this.point = const Point(0, 0)});
}

class RouterData {
  final String message;
  final String name;
  final String summary;
  final double distance;
  final double duration;
  final List<Maneuver> maneuvers;
  final List<Route> routes;
  RouterData(
      {this.message = 'OK',
      this.name = '',
      this.summary = '',
      this.distance = 0,
      this.duration = 0,
      List<Maneuver>? maneuvers,
      List<Route>? routes})
      : maneuvers = maneuvers ?? [],
        routes = routes ?? [];

  factory RouterData.fromGeoJson(
      {required Map<String, dynamic> geoJson, List<Waypoint>? waypoints}) {
    waypoints ??= [];
    List<Maneuver> maneuvers = getManeuversFromJson(routes: geoJson['routes']);
    double distance = getRouteLengthFromGeoJson(geoJson: geoJson);
    double duration = getRouteDurationFromGeoJson(geoJson: geoJson);
    List<Route> routes = [];
    for (int i = 0; i < geoJson['routes'].length; i++) {
      routes.add(Route.fromGeoJson(
          geoJsonMap: geoJson['routes'][i], waypoints: waypoints));
    }
    String summary =
        '${distance.toStringAsFixed(1)} miles - (${(duration / 60).floor()} minutes)';
    return RouterData(
      summary: summary,
      distance: distance,
      duration: duration,
      maneuvers: maneuvers,
      routes: routes,
    );
  }
}

class MutableDouble {
  double value;
  MutableDouble({this.value = -1.0});
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

/*
amenities = ["bar","biergarten", "pub", "cafe", "fast_food", "food_court", "ice_cream", "restaurant", "toilets", "Atm", "fuel", "charging-station"]
#key: place
settlement = ["city", "town", "village", "hamlet"]
Local Bar 0xfe540
Sports Bar 0xff1f3
Restaurant 0xfe56c
Fastfood 0xfe842
Coffee / Local Cafe 0xfefef
Lunch Dining 0xfea61
Icecream 0xfea69
Wc 0xfe63d
Local Atm 0xfe53e
Local Gas Station 0xfe546
Ev Station 0xfe56d

Location City 0xfe7f1
Holiday Village 0xfe58a
Other Houses 0xfe58c
Cottage 0xfe587
*/

class Place {
  String name;
  String tag;
  String key;
  double lat;
  double lng;
  String street;
  String town;
  String region;
  String postcode;
  int iconData;

  Place({
    this.name = '',
    this.tag = '',
    this.key = '',
    this.lat = 0.0,
    this.lng = 0.0,
    this.street = '',
    this.town = '',
    this.region = '',
    this.postcode = '',
    this.iconData = 0xe149,
  });

  factory Place.fromMap({required Map<String, dynamic> map}) {
    String tag = map['osm_tag'];
    int iconCodePoint = iconMap[tag] ?? 12;

    if (map['town'] == null || map['town'] == '' || map['town'] == 'None') {
      map['town'] = map['region'];
    }
    return Place(
        name: map['name'] ?? '',
        tag: tag,
        key: map['osm_key'] ?? '',
        lat: map['lat'] ?? 0.0,
        lng: map['lng'] ?? 0.0,
        street: map['street'] ?? '',
        town: map['town'] ?? '',
        region: map['region'] ?? '',
        postcode: map['postcode'] ?? '',
        iconData: iconCodePoint);
  }
}
/*
    final List<IconData> avatars = [
      Icons.touch_app,
 */
