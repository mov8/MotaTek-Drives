//import 'package:drives/models/models.dart'; //my_trip_item.dart';
import 'package:drives/classes/classes.dart';
import 'package:flutter/widgets.dart';
// import 'package:latlong2/latlong.dart';
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
  final int messages;
  final bool isGroup;
  MailItem({
    this.id = '',
    this.name = '',
    this.unreadMessages = 0,
    this.messages = 0,
    this.isGroup = false,
  });
}

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
  String postcode;
  int iconData;

  Place({
    this.name = '',
    this.tag = '',
    this.key = '',
    this.lat = 0.0,
    this.lng = 0.0,
    this.street = '',
    this.postcode = '',
    this.iconData = 0xe149,
  });

  factory Place.fromMap({required Map<String, dynamic> map}) {
    Map<String, int> iconMap = {
      "bar": 0xe38c,
      "biergarten": 0xe5e4,
      "pub": 0xe5e4,
      "cafe": 0xe38d,
      "fast_food": 0xe25a,
      "food_court": 0xe25a,
      "ice_cream": 0xe331,
      "restaurant": 0xe532,
      "toilets": 0xe6dc,
      "Atm": 0xe0af,
      "fuel": 0xea8e,
      "charging-station": 0xe939,
      "city": 0xe3a8,
      "town": 0xe317,
      "village": 0xe45f,
      "hamlet": 0xe19b
    };
    String tag = map['osm_tag'];
    int iconCodePoint = iconMap[tag] ?? 12;

    return Place(
        name: map['name'] ?? '',
        tag: tag,
        key: map['osm_key'] ?? '',
        lat: map['lat'] ?? 0.0,
        lng: map['lng'] ?? 0.0,
        street: map['street'] ?? '',
        postcode: map['postcode'] ?? '',
        iconData: iconCodePoint);
  }
}
/*
    final List<IconData> avatars = [
      Icons.touch_app,
 */
