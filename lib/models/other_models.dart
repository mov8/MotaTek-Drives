import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:drives/helpers/create_trip_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:universal_io/universal_io.dart';
import 'package:uuid/uuid.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '/constants.dart';
import '/screens/screens.dart';
import '/classes/route.dart' as mt;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as fm;
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:geolocator/geolocator.dart';

/// https://api.flutter.dev/flutter/material/Icons-class.html  get the icon codepoint from here
/// https://api.flutter.dev/flutter/material/Icons/add_road-constant.html

const List<Map> poiTypes = [
  {
    'id': 0,
    'name': 'Beauty spot',
    'icon': 'Icons.nature_people',
    'iconMaterial': 0xe41b,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 1,
    'name': 'Pub',
    'icon': 'Icons.local_drink',
    'iconMaterial': 0xe391,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 2,
    'name': 'Cafe',
    'icon': 'Icons.local_cafe',
    'iconMaterial': 0xe38d,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 3,
    'name': 'Historic building',
    'icon': 'Icons.castle',
    'iconMaterial': 0xf02e5,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 4,
    'name': 'Monument',
    'icon': 'Icons.account_balance',
    'iconMaterial': 0xe040,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 5,
    'name': 'Museum',
    'icon': 'Icons.museum',
    'iconMaterial': 0xe414,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 6,
    'name': 'Park',
    'icon': 'Icons.park',
    'iconMaterial': 0xe478,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 7,
    'name': 'Parking',
    'icon': 'Icons.local_parking',
    'iconMaterial': 0xe39d,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 8,
    'name': 'Other',
    'icon': 'Icons.pin_drop',
    'iconMaterial': 0xe4c7,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 9,
    'name': 'Start',
    'icon': 'Icons.assistant_navigation',
    'iconMaterial': 0xe0ad,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 10,
    'name': 'End',
    'icon': 'Icons.assistant_photo_outlined',
    'iconMaterial': 0xee9e,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 11,
    'name': 'Routepoint',
    'icon': 'Icons.nature_people',
    'iconMaterial': 0xe696,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 12,
    'name': 'Waypoint',
    'icon': 'Icons.constant_moving',
    'iconMaterial': 0xe410,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 13,
    'name': 'Great road start',
    'icon': 'Icons.add_road',
    'iconMaterial': 0xe059,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 14,
    'name': 'Great road', // Great road end
    'icon': 'Icons.add_road',
    'iconMaterial': 0xe059, // 0xf07bb,
    'colour': 'Colors.red',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 15,
    'name': 'New point of interest',
    'icon': 'Icons.add_phot_alternate',
    'iconMaterial': 0xee48,
    'colour': 'Colors.red',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 16,
    'name': 'follower',
    'icon': 'Icons.directions_car',
    'iconMaterial': 0xe1d7,
    'colour': 'Colors.red',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 17,
    'name': 'Start',
    'icon': 'Icons.tour',
    'iconMaterial': 0xe671,
    'colour': 'Colors.red',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 18,
    'name': 'End',
    'icon': 'Icons.sports_score',
    'iconMaterial': 0xe5f1,
    'colour': 'Colors.red',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 19,
    'name': 'End',
    'icon': 'Icons.sports_score',
    'iconMaterial': 0xe5f1,
    'colour': 'Colors.transparent',
    'colourMaterial': 0xff4CAF50
  }
];

int getIconIndex({required int iconIndex, int fallback = 0}) {
  if (iconIndex == -1) {
    iconIndex = fallback;
  }
  return iconIndex;
}

const List<String> manufacturers = ['Triumph', 'MG', 'Reliant'];
const List<String> models = ['TR2', 'TR3', 'TR5', 'TR6', 'TR7', 'Stag'];

Map<Color, String> uiColours = {
  Colors.white: 'white',
  const Color.fromARGB(255, 28, 77, 30): 'olive',
  const Color.fromRGBO(105, 8, 1, 1): 'maroon',
  Colors.red: 'red',
  Colors.orange: 'orange',
  Colors.amber: 'amber',
  Colors.lime: 'lime',
  Colors.yellow: 'yellow',
  Colors.green: 'green',
  Colors.lightGreenAccent: 'light green',
  Colors.blue: 'blue',
  Colors.indigo: 'indigo',
  Colors.deepPurple: 'purple',
  Colors.cyan: 'cyan',
  Colors.grey: 'grey',
  Colors.brown: 'brown',
  Colors.black: 'black',
  Colors.transparent: 'transparent',
};

List<Color> colourList = uiColours.keys.toList();
// List<String> colourListHex = uiColours.keys.toHexStringRGB().toList();
List<String> colorNameList = uiColours.values.toList();

const List<Color> pinColours = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange
];

String? colourToHex({Color? color}) {
  return color!.toHexStringRGB();
}

String? colourIntToHex({int index = 0}) {
  return uiColours.keys.toList()[index].toHexStringRGB();
}

void myFunc() {}

Future<String> distanceFromMe(
    {required fm.LatLng position, decimalPlaces = 1, metric = false}) async {
  Position pos = await Geolocator.getCurrentPosition();
  double meters = Geolocator.distanceBetween(
      pos.latitude, pos.longitude, position.latitude, position.longitude);
  String unit = metric ? 'Km' : 'miles';
  double factor = metric ? .001 : metersToMiles;
  return '${(meters * factor).toStringAsFixed(decimalPlaces)} $unit';
}

class CutRoute {
  int routeIndex = 0; // holds the polyLine Index in Routes
  int pointIndex = 0; // holds the index of fm.LatLng on the above polyLine
  int precedingPointIndex =
      0; // holds the index of the previous POI in _routes[routeIndex].points[]
  int precedingPoiIndex; // holds the index in _pointsOfInterest of the preceding POI
  fm.LatLng poiPosition =
      const fm.LatLng(0, 0); // The fm.LatLng of the POI to be inserted

  CutRoute(
      {required this.routeIndex,
      required this.pointIndex,
      required this.poiPosition,
      this.precedingPoiIndex = 0,
      this.precedingPointIndex = 0});
}

class Setup {
  int id = 0;
  int routeColour = 12;
  int goodRouteColour = 3;
  int waypointColour = 2;
  int pointOfInterestColour = 8;
  int waypointColour2 = 14;
  int pointOfInterestColour2 = 14;
  int selectedColour = 7;
  int highlightedColour = 13;
  int publishedTripColour = 10;
  int bottomNavIndex = 0;
  int recordDetail = 5;
  bool allowNotifications = true;
  bool serverUp = false;
  bool hasLoggedIn = false;
  bool loggingIn = false;
  bool hasRefreshedShop = false;
  bool hasRefreshedTrips = false;
  bool dark = false;
  bool rotateMap = false;
  bool avoidMotorways = false;
  bool avoidAroads = false;
  bool avoidBroads = false;
  bool avoidTollRoads = false;
  bool avoidFerries = false;
  bool osmPubs = false;
  bool osmRestaurants = false;
  bool osmFuel = false;
  bool osmToilets = false;
  bool osmAtms = false;
  bool osmHistorical = false;
  int tripCount = 0;
  int shopCount = 0;
  int messageCount = 0;
  bool isWeb = kIsWeb;
  bool isIOS = Platform.isIOS;
  bool maleVoice = false;
  MyTripItem? currentTrip;
  Position lastPosition = Position(
    longitude: 0.0,
    latitude: 0.0,
    timestamp: DateTime.timestamp(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    floor: 0,
    isMocked: false,
  );

  String jwt = '';
  User user = User(
      id: 0, forename: '', surname: '', password: '', email: '', phone: '');
  bool? _loaded;
  String appDocumentDirectory = '';
  late Directory cacheDirectory;
  late Directory soundsDirectory;
  late String appState = '';

  Setup._privateConstructor();
  static final _instance = Setup._privateConstructor();
  factory Setup() {
    return _instance;
  }

  Future<bool> get loaded async {
    if (kIsWeb) {
      user.forename = 'James';
      user.surname = 'Seddon';
      user.email = 'james@staintonconsultancy.com';
      user.password = 'rubberduck';
      user.phone = '07761632236';
      return true;
    }

    appDocumentDirectory = (await getApplicationDocumentsDirectory()).path;
    cacheDirectory = Directory('$appDocumentDirectory/cache');
    if (!await cacheDirectory.exists()) {
      await Directory('$appDocumentDirectory/cache').create();
    }
    soundsDirectory = Directory('$appDocumentDirectory/sounds');
    if (!await soundsDirectory.exists()) {
      await Directory('$appDocumentDirectory/sounds').create();
    }

    return _loaded ??= await setupFromDb();
  }

  Future<bool> setupFromDb() async {
    //  var setupRecords = await recordCount('setup');
    //  debugPrint('Setup contains $setupRecords records');
    List<Map<String, dynamic>> maps = await getPrivateRepository().getSetup(0);
    if (maps.isNotEmpty) {
      try {
        id = maps[0]['id'];
        routeColour = maps[0]['route_colour'];
        goodRouteColour = maps[0]['good_route_colour'];
        waypointColour = maps[0]['waypoint_colour'];
        pointOfInterestColour = maps[0]['point_of_interest_colour'];
        waypointColour2 = maps[0]['waypoint_colour_2'];
        pointOfInterestColour2 = maps[0]['point_of_interest_colour_2'];
        selectedColour = maps[0]['selected_colour'];
        highlightedColour = maps[0]['highlighted_colour'];
        publishedTripColour = maps[0]['published_trip_colour'] ?? 10;
        recordDetail = maps[0]['record_detail'];
        allowNotifications = maps[0]['allow_notifications'] == 1;
        jwt = maps[0]['jwt'];
        dark = maps[0]['dark'] == 1;
        rotateMap = maps[0]['rotate_map'] == 1;
        avoidMotorways = maps[0]['avoid_motorways'] == 1;
        avoidAroads = maps[0]['avoid_a_roads'] == 1;
        avoidBroads = maps[0]['avoid_b_roads'] == 1;
        avoidTollRoads = maps[0]['avoid_toll_roads'] == 1;
        avoidFerries = maps[0]['avoid_ferries'] == 1;
        osmPubs = maps[0]['osm_pubs'] == 1;
        osmRestaurants = maps[0]['osm_restaurants'] == 1;
        osmFuel = maps[0]['osm_fuel'] == 1;
        osmToilets = maps[0]['osm_toilets'] == 1;
        osmAtms = maps[0]['osm_atms'] == 1;
        osmHistorical = maps[0]['osm_historical'] == 1;
        bottomNavIndex = maps[0]['bottom_nav_index'];
        appState = maps[0]['app_state'];
        maleVoice = (maps[0]['male_voice'] ?? 0) == 1;
      } catch (e) {
        debugPrint('Failed to load Setup() from db: ${e.toString()}');
      }
    }
    user = await getPrivateRepository().getUser();
    return true;
  }

  Future<void> setupToDb() async {
    await getPrivateRepository().insertSetup(this);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_colour': routeColour,
      'good_route_colour': goodRouteColour,
      'waypoint_colour': waypointColour,
      'point_of_interest_colour': pointOfInterestColour,
      'waypoint_colour_2': waypointColour2,
      'point_of_interest_colour_2': pointOfInterestColour2,
      'highlighted_colour': highlightedColour,
      'published_trip_colour': publishedTripColour,
      'selected_colour': selectedColour,
      'record_detail': recordDetail,
      'jwt': jwt,
      'allow_notifications': allowNotifications ? 1 : 0,
      'dark': dark ? 1 : 0,
      'rotate_map': rotateMap ? 1 : 0,
      'avoid_motorways': avoidMotorways ? 1 : 0,
      'avoid_a_roads': avoidAroads ? 1 : 0,
      'avoid_b_roads': avoidBroads ? 1 : 0,
      'avoid_toll_roads': avoidTollRoads ? 1 : 0,
      'avoid_ferries': avoidFerries ? 1 : 0,
      'osm_pubs': osmPubs ? 1 : 0,
      'osm_restaurants': osmRestaurants ? 1 : 0,
      'osm_fuel': osmFuel ? 1 : 0,
      'osm_toilets': osmToilets ? 1 : 0,
      'osm_atms': osmAtms ? 1 : 0,
      'osm_historical': osmHistorical ? 1 : 0,
      'bottom_nav_index': bottomNavIndex,
      'app_state': appState,
    };
  }

  String routeColourHex() {
    return colourList[routeColour].toHexStringRGB();
  }

  String goodRouteColourHex() {
    return colourList[goodRouteColour].toHexStringRGB();
  }

  String waypointColourHex() {
    return colourList[waypointColour].toHexStringRGB();
  }

  String pointOfInterestColourHex() {
    return colourList[pointOfInterestColour].toHexStringRGB();
  }

  String waypointColour2Hex() {
    return colourList[waypointColour2].toHexStringRGB();
  }

  String pointOfInterestColour2Hex() {
    return colourList[pointOfInterestColour2].toHexStringRGB();
  }

  String selectedColourHex() {
    return colourList[selectedColour].toHexStringRGB();
  }

  String highlightedColourHex() {
    return colourList[highlightedColour].toHexStringRGB();
  }

  String publishedTripColourHex() {
    return colourList[publishedTripColour].toHexStringRGB();
  }
}

class PointOfInterest {
  // GlobalKey? handle;
  int id;
  String? uuid;
  Point point;
  String images;
  String name;
  String description;
  String sounds;
  double score;
  int scored;
  int type;

  PointOfInterest({
    this.id = -1,
    uuid,
    this.point = const Point(0, 0),
    this.type = -1,
    this.name = '',
    this.description = '',
    this.images = '',
    this.score = 0,
    this.scored = 0,
    this.sounds = '',
  }) : uuid = uuid ?? getUuid();

  factory PointOfInterest.fromMap({required Map<String, dynamic> map}) {
    return PointOfInterest(
      id: map['id'] ?? -1,
      uuid: map['uuid'],
      point: Point(map['point']['long'], map['point']['lat']),
      type: map['type'] ?? 0,
      name: map['name'],
      description: map['description'],
      images: map['images'],
      score: map['score'] ?? 0,
      scored: map["scored"] ?? 0,
      sounds: '',
    );
  }
  Map<String, dynamic> toMap({String driveUid = ''}) {
    return {
      "id": id,
      "uuid": uuid,
      "drive_id": driveUid,
      "type": type,
      "name": name,
      "description": description,
      "images": images,
      "score": score,
      "scored": scored,
      "point": {
        "lat": point.y,
        "long": point.x
      }, // Standardise for local storage as a map
    };
  }

  get photos => [];

  get published => '';
/*
  Map<String, dynamic> toApiMap() {
    List<Map<String, dynamic>> photosMap = [];

    for (Photo photo in photos) {
      String uuidString = Uuid().v7();
      uuidString = uuidString.replaceAll(RegExp(r'-'), '');
      photosMap.add({
        'url': uuidString,
        'caption': photo.caption,
        'rotation': photo.rotation,
        'file': photo.url
      });
    }
    return {
      'url': url,
      'type': type,
      'name': name,
      'score': score,
      'scored': scored,
      'images': photosMap,
      'description': description,
      'latitude': point[1],
      'longitude': point[0],
    };
  }
  */
}

List<PointOfInterest> pointsOfInterestFromJson(
    {required List<dynamic> jsonList}) {
  return [
    for (Map<String, dynamic> json in jsonList)
      //  if (![12, 17, 18].contains(json['type'] ?? 0))
      PointOfInterest.fromMap(map: json)
  ];
}

List<Map<String, dynamic>> jsonFromPointsOfInterest(
    {required List<PointOfInterest> pointsOfInterestList}) {
  return [
    for (PointOfInterest pointOfInterest in pointsOfInterestList)
      pointOfInterest.toMap()
  ];
}

class Group {
  String id = '';
  String name = '';
  String description = '';
  String ownerForename;
  String ownerSurname;
  String ownerPhone;
  String ownerEmail;
  int memberCount;
  List<GroupMember> _members = [];
  DateTime created = DateTime.now();
  bool edited = false;
  bool selected = true;
  String userId = '';
  int messages = 0;
  int unreadMessages = 0;
  Group(
      {this.id = '',
      required this.name,
      this.description = '',
      List<GroupMember> members = const [],
      DateTime? created,
      this.edited = false,
      this.userId = '',
      this.messages = 0,
      this.unreadMessages = 0,
      this.ownerForename = '',
      this.ownerSurname = '',
      this.ownerPhone = '',
      this.ownerEmail = '',
      this.memberCount = 0})
      : created = created ?? DateTime.now(),
        _members = List.from(members);

  set groupName(String value) => name = value;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'members': _members.map((member) => member.toMap()).toList(),
      'created': created.toString(),
      //  'edited': edited ? 1 : 0,
      'user_id': userId,
    };
  }

  factory Group.fromMap(var map) {
    return Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      userId: map['user_id'] ?? '', // group owner
      description: map['description'] ?? '',
      members: <GroupMember>[
        for (Map<String, dynamic> memberMap in map['members'])
          GroupMember.fromMap(memberMap,
              userId: map['user_id'] ?? '', groupId: map['id'] ?? '')
      ],
      created: DateTime.parse(map['created'] ?? '01/01/2000'),
    );
  }

  factory Group.fromGroupSummaryMap(var map) {
    List<GroupMember> members = [];
    for (Map<String, dynamic> member in map['members']) {
      members.add(GroupMember(
          id: member['id'],
          forename: member['forename'],
          surname: member['surname'],
          phone: member['phone'],
          email: member['email']));
    }
    return Group(
      id: map['id'],
      userId: map['user_id'],
      edited: false,
      name: map['name'],
      members: members,
      memberCount: members.length,
    );
  }

  factory Group.fromMyGroupsMap(var map) {
    return Group(
      id: map['group_id'],
      name: map['group_name'],
      ownerForename: map['owner_forename'],
      ownerSurname: map['owner_surname'],
      ownerPhone: map['owner_phone'],
      ownerEmail: map['owner_email'],
      memberCount: int.parse(map['members']),
    );
  }

  List<GroupMember> membersFromMap(List<Map<String, dynamic>> maps) {
    List<GroupMember> members = [];
    for (Map<String, dynamic> map in maps) {
      members.add(GroupMember.fromMap(map));
    }
    return members;
  }

  void addMember(GroupMember member) {
    _members.add(member);
    memberCount = _members.length;
  }

  void removeMember(int index) {
    _members.removeAt(index);
    memberCount = _members.length;
  }

  List<GroupMember> groupMembers() {
    return _members;
  }

  void setGroupMembers(List<GroupMember> members) {
    _members = members;
    memberCount = _members.length;
  }
}

class GroupMember {
  String id = '';
  String stId = '-1';
  String userId = '';
  String groupIds = '';
  String groupId = '';
  String forename = '';
  String surname = '';
  String email = '';
  String phone = '';
  String isEdited = 'false';
  bool selected = false;
  int index = 0;
  GroupMember(
      {required this.forename,
      required this.surname,
      this.id = '',
      this.userId = '',
      this.groupId = '',
      this.email = '',
      this.phone = '',
      this.selected = false});

  factory GroupMember.fromMap(Map<String, dynamic> map,
      {String userId = '', groupId = ''}) {
    return GroupMember(
      id: map['id'],
      userId: map['member'] ?? userId,
      groupId: map['groups'] ?? groupId,
      forename: map['forename'],
      surname: map['surname'],
      email: map['email'],
      phone: map['phone'],
    );
  }

  factory GroupMember.fromUserMap(Map<String, dynamic> map) {
    return GroupMember(
      id: '', // It's not yet defined as a group member
      userId: map['userId'],
      forename: map['forename'],
      surname: map['surname'],
      email: map['email'],
      phone: map['phone'],
    );
  }

  factory GroupMember.fromApiMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['group_member_id'],
      userId: map['user_id'],
      groupId: map['group_id'],
      forename: map['member_forename'],
      surname: map['member_surname'],
      email: map['member_email'],
      phone: map['member_phone'] ?? '',
      selected: (map['registered'] ?? 1) == 1,
    );
  }

// Getter for edited have to use this because ints are passed by value not by reference
  bool get edited => isEdited == 'true';
// Setter for edited
  set edited(bool value) => isEdited = value ? 'true' : 'false';

  Map<String, dynamic> toMap() {
    return {'user_id': userId, 'group_id': groupId, 'email': email};
  }

  Map<String, dynamic> toFullMap() {
    return {
      // 'id': stId,
      'user_id': userId,
      'forename': forename,
      'surname': surname,
      'email': email,
      'phone': phone,
      'id': userId
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'user_id': '',
      'forename': forename,
      'surname': surname,
      'email': email,
      'phone': phone,
      'added': DateTime.now().toIso8601String(),
    };
  }
}

class GroupDrive {
  String driveId;
  String groupDriveId;
  String name;
  int accepted;
  int pending;
  DateTime driveDate;
  int index = 0;
  bool selected = false;
  GroupDrive(
      {this.driveId = '',
      this.groupDriveId = '',
      this.name = '',
      this.accepted = 0,
      this.pending = 0,
      driveDate})
      : driveDate = driveDate ?? DateTime.now();

  factory GroupDrive.fromMap(Map<String, dynamic> map) {
    return GroupDrive(
      driveId: map['drive_id'],
      groupDriveId: map['group_drive_id'],
      name: map['drive_name'],
      accepted: int.parse(map['accepted']),
      pending: int.parse(map['pending']),
      driveDate: DateTime.parse(map['drive_date']),
    );
  }
}

class GroupEvent {
  String eventId;
  String driveId;
  String eventName;
  String eventDate;
  int invited;
  int accepted;
  bool selected;
  int count;
  List<dynamic> invitees;
  GroupEvent({
    this.eventId = '',
    this.driveId = '',
    this.eventName = '',
    this.eventDate = '',
    this.count = 0,
    this.invited = 0,
    this.selected = false,
    this.accepted = 0,
    this.invitees = const [{}],
    //    {'forename': '', 'surname': '', 'email': '', 'status': 0},
    //  ],
  });

  factory GroupEvent.fromMap({required Map<String, dynamic> map}) {
    return GroupEvent(
        eventId: map['id'],
        driveId: map['drive_id'],
        eventName: map['name'],
        eventDate: map['date'],
        count: map['count'],
        invited: map['invited'],
        accepted: map['accepted'],
        invitees: map['members']);
  }
}

/// GroupDriveByGroup returns all the groups a user has organises
/// with all the group members details plus the invitation
/// status for the group drive in question
///

class GroupDriveByGroup {
  String groupId;
  String name;
  bool selected;
  int count;
  int invited;
  int accepted;
  List<dynamic> invitees;
  GroupDriveByGroup({
    this.groupId = '',
    this.name = '',
    this.selected = false,
    this.count = 0,
    this.invited = 0,
    this.accepted = 0,
    this.invitees = const [{}],
    //   {'forename': '', 'surname': '', 'email': '', 'status': 0},
    // ],
  });

  factory GroupDriveByGroup.fromMap({required Map<String, dynamic> map}) {
    return GroupDriveByGroup(
        groupId: map['id'],
        name: map['name'],
        count: map['count'],
        invited: map['invited'],
        accepted: map['accepted'],
        invitees: map['members']);
  }
}

class EventInvitation {
  String driveId;
  String groupDriveId;
  String name;
  DateTime eventDate;
  String forename;
  String surname;
  String phone;
  String email;
  String id;
  DateTime invitationDate;
  int accepted;
  int index = 0;
  bool selected;
  EventInvitation({
    this.driveId = '',
    this.groupDriveId = '',
    this.name = '',
    eventDate,
    this.forename = '',
    this.surname = '',
    this.phone = '',
    this.email = '',
    this.id = '',
    invitationDate,
    this.accepted = 0,
    this.selected = false,
  })  : eventDate = eventDate ?? DateTime.now(),
        invitationDate = invitationDate ?? DateTime.now();

  factory EventInvitation.fromByUserMap(Map<String, dynamic> map) {
    return EventInvitation(
      driveId: map['event_id'],
      groupDriveId: map['group_drive_id'],
      name: map['event_name'],
      eventDate: DateTime.parse(map['event_date']),
      forename: map['inviter_forename'],
      surname: map['inviter_surname'],
      email: map['inviter_email'],
      id: map['invitation_id'] ?? '',
      invitationDate: DateTime.parse(map['invitation_date']),
      accepted: int.parse(map['accepted']),
    );
  }

  factory EventInvitation.fromByEventMap(Map<String, dynamic> map) {
    return EventInvitation(
      forename: map['invitee_forename'],
      surname: map['invitee_surname'],
      phone: map['invitee_phone'],
      email: map['invitee_email'],
      id: map['invitation_id'] ?? '',
      invitationDate: DateTime.parse(map['invitation_date']),
      accepted: int.parse(map['accepted']),
    );
  }
  factory EventInvitation.fromByUserToAlterMap(Map<String, dynamic> map) {
    return EventInvitation(
      forename: map['invitee_forename'],
      surname: map['invitee_surname'],
      phone: map['invitee_phone'],
      email: map['invitee_email'],
      id: map['invitation_id'] ?? '',
      accepted: int.parse(map['accepted']),
      driveId: map['group_drive_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': name,
      'forname': forename,
      'surname': surname,
      'email': email,
      'invitation_id': id,
      'drive_id': driveId,
      'drive_date': eventDate.toString(),
      'invited': invitationDate.toString(),
    };
  }
}

class GroupDriveInvitation {
  String driveId;
  String title;
  String message;
  DateTime invitationDate;
  DateTime driveDate;
  List<Map<String, dynamic>> invited;

  GroupDriveInvitation(
      {required this.driveId,
      required this.title,
      this.message = '',
      invitationDate,
      driveDate,
      this.invited = const []})
      : invitationDate = invitationDate ?? DateTime.now(),
        driveDate = driveDate ?? DateTime.now();

  factory GroupDriveInvitation.fromMap(Map<String, dynamic> map) {
    return GroupDriveInvitation(
        driveId: map['drive_id'],
        title: map['title'],
        message: map['message'],
        invitationDate: DateTime.parse(map['invitation_date']),
        driveDate: DateTime.parse(map['drive_date']));
  }

  Map<String, dynamic> toMap() {
    return {
      'drive_id': driveId,
      'title': title,
      'message': message,
      'invitation_date': invitationDate.toString(),
      'drive_date': driveDate.toString(),
      'invited': invited
    };
  }
}

class Photo {
  String url;
  int id;
  int key;
  int index;
  int rotation;
  String caption;
  String endPoint;

  Photo(
      {required this.url,
      this.id = -1,
      this.key = -1,
      this.index = -1,
      this.caption = '',
      this.rotation = 0,
      this.endPoint = ''});

  factory Photo.fromJson(Map<String, dynamic> json,
      {int index = -1, String endPoint = ''}) {
    String url = json['url'].contains(Setup().appDocumentDirectory) ||
            json['url'] == "" ||
            json['url'].contains('http')
        ? json['url']
        : '$endPoint${json['url']}';
    return Photo(
        url: url,
        id: json['id'] ?? -1,
        caption: json['caption'] ?? '',
        rotation: json['rotation'] ?? 0,
        key: -1,
        index: index);
  }

  factory Photo.fromJsonMap(Map<String, String> json) {
    return Photo(
      url: json['url'] ?? '',
      id: int.parse(json['id'] ?? '-1'),
      caption: json['caption'] ?? '',
      rotation: int.parse(json['rotation'] ?? '0'),
    );
  }

  String toJson() {
    return '{"url": $url, "caption": $caption, "rotation": $rotation}';
  }

  String toMapString() {
    if (url.contains('http')) {
      return '{"url": "${url.substring(url.lastIndexOf('/') + 1)}", "caption": "$caption", "rotation": $rotation}';
    } else {
      return '{"url": "$url", "caption": "$caption", "rotation": $rotation}';
    }
  }

  String toEscapedString() {
    Map<String, dynamic> json = {
      'url': url,
      'caption': caption,
      'rotation': rotation
    };
    return jsonEncode(json);
  }
}

class ImageCacheItem {
  int index;
  int localId;
  String url;
  double lat;
  double lng;
  ImageCacheItem(
      {this.localId = -1,
      this.url = '',
      this.lat = 0,
      this.lng = 0,
      this.index = -1});

  factory ImageCacheItem.fromMap(
      {required Map<String, dynamic> map, row = -1}) {
    return ImageCacheItem(
        index: row,
        localId: map['id'] ?? -1,
        url: map['uri'] ?? '',
        lat: map['lat'] ?? 50.0,
        lng: map['lng'] ?? 0);
  }
}

class GoodRoadCacheItem {
  int index;
  int localId;
  String url;
  fm.LatLng northEast;
  fm.LatLng southWest;
  GoodRoadCacheItem(
      {this.localId = -1,
      this.url = '',
      this.northEast = const fm.LatLng(50, 0),
      this.southWest = const fm.LatLng(50, 0),
      this.index = -1});

  factory GoodRoadCacheItem.fromMap(
      {required Map<String, dynamic> map, row = -1}) {
    return GoodRoadCacheItem(
      index: row,
      localId: map['id'] ?? -1,
      url: map['uri'] ?? '',
      northEast: fm.LatLng(map['max_lat'] ?? 50.0, map['max_lng'] ?? 0),
      southWest: fm.LatLng(map['min_lat'] ?? 50.0, map['min_lng'] ?? 0),
    );
  }
}

class User {
  int id = 0;
  String uri;
  String forename;
  String surname;
  String password;
  String newPassword = '';
  String phone;
  String email;
  String imageUrl;

  User({
    this.id = 0,
    this.forename = '',
    this.surname = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.uri = '',
    this.imageUrl = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        id: json['id'],
        forename: json['forename'],
        surname: json['surname'],
        email: json['email'],
        phone: json['phone'],
        password: json['password'],
        imageUrl: json['imageUrl']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'forename': forename,
      'surname': surname,
      'email': email,
      'phone': phone,
      'password': newPassword.isEmpty ? password : newPassword,
      'imageUrl': imageUrl,
    };
  }

  Map<String, dynamic> toMapApi() {
    return {
      'id': id,
      'forename': forename,
      'surname': surname,
      'email': email,
      'phone': phone,
      'password': password,
      'new_password': newPassword,
      'imageUrl': imageUrl,
    };
  }
}

class PoiImage {
  int id = -1;
  String url = '';
  PoiImage(this.id, this.url);
}

class UiColour {
  int id = -1;
  Color colour = Colors.black;
  String name = 'black';
  UiColour(this.id, this.colour, this.name);
}

class Maneuver {
  int id = 0;
  String? uuid;
  int driveId = 0;
  String roadFrom = '';
  String roadTo = '';
  int exit = 0;
  int bearingBefore = 0;
  int bearingAfter = 0;
  Point point = const Point(0, 0);
  String modifier = '';
  String type = '';
  double distance = 0.0;
  Maneuver({
    this.id = 0,
    this.driveId = 0,
    uuid,
    required this.roadFrom,
    required this.roadTo,
    required this.exit,
    required this.bearingBefore,
    required this.bearingAfter,
    required this.point,
    required this.modifier,
    required this.type,
    required this.distance,
  }) : uuid = uuid ??= getUuid();

  factory Maneuver.fromMap({required Map<String, dynamic> map}) {
    Map<String, dynamic> pos =
        jsonDecode(map["location"]) ?? {'lat': 0, 'long': 0};
    return Maneuver(
      id: map["id"] ?? -1,
      roadFrom: map["road_from"] ?? " ",
      roadTo: map["road_to"] ?? " ",
      exit: map["exit"] ?? 1,
      bearingBefore: map["bearing_before"] ?? 0,
      bearingAfter: map["bearing_after"] ?? 0,
      point: Point((pos["long"] ?? 0), (pos["lat"] ?? 0)),
      modifier: map["modifier"] ?? " ",
      type: map["type"] ?? " ",
      distance: map["distance"] ?? 0,
    );
  }

  Map<String, dynamic> toMap({String driveUid = ''}) {
    return {
      "id": id,
      "uuid": uuid,
      'drive_uid': driveUid,
      "road_from": roadFrom,
      "road_to": roadTo,
      "exit": exit,
      "bearing_before": bearingBefore,
      "bearing_after": bearingAfter,
      "location": '{"lat":${point.y},"long":${point.x}}',
      "modifier": modifier,
      "type": type,
      "distance": distance,
    };
  }
}

List<Maneuver> maneuversFromJson({required List<dynamic> jsonList}) {
  return [
    for (Map<String, dynamic> json in jsonList) Maneuver.fromMap(map: json)
  ];
}

List<Map<String, dynamic>> jsonFromManeuvers(
    {required List<Maneuver> maneuvers}) {
  return [for (Maneuver maneuver in maneuvers) maneuver.toMap()];
}

class IntIm {
  int value = -1;
  IntIm({this.value = -1});
  set setValue(int val) => value = val;
  int get getValue {
    return value;
  }
}

/// class OsmAmenity
///

class Follower {
  String uri;
  String userId;
  String driveId;
  String driveName;
  String forename;
  String surname;
  String email;
  String phoneNumber;
  String manufacturer;
  String model;
  String registration;
  String carColour;
  int iconColour;
  int routeIndex;
  int accepted;
  bool track;
  List<double> position; // = const fm.LatLng(0, 0);
  DateTime reported = DateTime.now();
  int index = -1;
  Follower({
    this.uri = '',
    this.userId = '',
    this.driveId = '',
    this.driveName = '',
    this.forename = '',
    this.surname = '',
    this.email = '',
    this.phoneNumber = '',
    this.manufacturer = '',
    this.model = '',
    this.registration = '',
    this.carColour = '',
    this.iconColour = 0,
    this.routeIndex = -1,
    this.accepted = 0,
    this.track = true,
    required this.position,
  });

  factory Follower.fromMap({required Map<String, dynamic> map}) {
    return Follower(
      uri: map["uri"] ?? "",
      userId: map["users_id"] ?? "",
      driveId: map["drive_id"] ?? "",
      driveName: map["drive_name"] ?? "",
      forename: map["forename"] ?? "",
      surname: map["surname"] ?? "",
      email: map["email"] ?? "",
      phoneNumber: map["phone_number"] ?? "",
      manufacturer: map["manufacturer"] ?? "",
      model: map["model"] ?? "",
      registration: map["registration"] ?? "",
      carColour: map["car_colour"] ?? "",
      iconColour: map["icon_colour"] ?? 0,
      routeIndex: map["route_index"] ?? -1,
      accepted: map["accepted"] ?? 0,
      track: map["track"] ?? true,
      position: map["position"] ?? [0, 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uri": uri,
      "users_id": userId,
      "drive_id": driveId,
      "drive_name": driveName,
      "forename": forename,
      "surname": surname,
      "email": email,
      "phone_number": phoneNumber,
      "manufacturer": manufacturer,
      "model": model,
      "registration": registration,
      "car_colour": carColour,
      "icon_colour": iconColour,
      "route_index": routeIndex,
      "accepted": accepted,
      "track": track,
      "position": position,
    };
  }
}

/// class HomeItem
///

/// Api sends image urls as a list of filenames
/// To simplify handling of local and web images the
/// API url list is converted to {"url": "uuid.jpg", "caption": ""}, {...}
String handleWebImages(String urls) {
  String mappedUrls = urls;
  if (urls.isNotEmpty &&
      !urls.contains('{') &&
      !urls.contains('assets') &&
      !urls.contains('caption_')) {
    mappedUrls = urls.replaceAll(RegExp(r','), ', "caption":""},{"url": ');
    mappedUrls =
        '[{"url":${mappedUrls.substring(1, mappedUrls.length - 1)}, "caption": ""}]';
  }
  return mappedUrls;
}

class HomeItem {
  int id;
  String uri;
  String heading;
  String subHeading;
  String body;
  String imageUrls;
  int score;
  String coverage;
  DateTime added;
  HomeItem(
      {this.id = -1,
      this.uri = '',
      required this.heading,
      this.subHeading = '',
      this.body = '',
      imageUrls = '',
      this.score = 5,
      this.coverage = 'all',
      DateTime? added})
      : added = added ?? DateTime.now(),
        imageUrls = handleWebImages(imageUrls);

  /// Need to be able to change the URL as the API doesn't
  /// send the endpoint address to save web traffic, The app
  /// adds in the appropriale address as it processes the data
  /// which is sent as  by the API and read as a map.
  /// As the fromMap method has to cope with data from both the
  /// API and the local SQLite db all integer values have to be
  /// sent as integers and not strings to parse to integer.

  factory HomeItem.fromMap(
      {required Map<String, dynamic> map, String url = ''}) {
    return HomeItem(
      id: map['id'] ?? -1,
      uri: '$url${map['uri']}',
      heading: map['heading'],
      subHeading: map['sub_heading'],
      body: map['body'],
      imageUrls: map['image_urls'], //jsonEncode(map['imageUrl']),
      coverage: map['coverage'],
      score: map['score'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.toString(),
      'uri': uri,
      'heading': heading,
      'sub_heading': subHeading,
      'body': body,
      'image_urls': imageUrls,
      'coverage': coverage,
      'score': score.toString(),
    };
  }
}

class ShopItem {
  int id = -1;
  String uri = '';
  String heading = '';
  String subHeading = '';
  String body = '';
  String imageUrls = '';
  String coverage;
  int score = 5;
  String buttonText1;
  String url1;
  String buttonText2;
  String url2;
  int links;
  ShopItem(
      {this.id = -1,
      this.uri = '',
      required this.heading,
      this.subHeading = '',
      this.body = '',
      imageUrls = '',
      this.coverage = 'all',
      this.score = 5,
      this.buttonText1 = '',
      this.url1 = '',
      this.buttonText2 = '',
      this.url2 = '',
      this.links = 0})
      : imageUrls = handleWebImages(imageUrls);

  factory ShopItem.fromMap(
      {required Map<String, dynamic> map, String url = ''}) {
    return ShopItem(
        id: map['id'] ?? -1,
        uri: '$url${map['uri']}',
        heading: map['heading'],
        subHeading: map['sub_heading'],
        body: map['body'],
        coverage: map['coverage'],
        imageUrls: map['image_urls'],
        score: map['score'] ?? 5,
        buttonText1: map['button_text_1'],
        url1: map['url_1'],
        buttonText2: map['button_text_2'],
        url2: map['url_2'],
        links: map['url_1'] == ''
            ? 0
            : map['url_2'] == ''
                ? 1
                : 2);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.toString(),
      'uri': uri,
      'heading': heading,
      'sub_heading': subHeading,
      'body': body,
      'coverage': coverage,
      'image_urls': imageUrls,
      'score': score.toString(),
      'button_text_1': buttonText1,
      'url_1': url1,
      'button_text_2': buttonText2,
      'url_2': url2,
    };
  }
}

/// class TripItem
///

class TripSummary extends Marker {
  int cacheKey;
  int id = -1;
  final String uri;
  final String title;
  final String subTitle;
  final double minLat;
  final double maxLat;
  final double minLong;
  final double maxLong;
  final double score;
  int scored;

  // late final Widget marker;
  // late fm.LatLng markerPoint = const fm.LatLng(52.05884, -1.345583);
  TripSummary(
      {this.cacheKey = -1,
      this.uri = '',
      this.title = '',
      this.subTitle = '',
      this.minLat = -180.0,
      this.maxLat = 180,
      this.minLong = -180,
      this.maxLong = 180,
      this.score = 5.0,
      this.scored = 1,
      super.child = const Icon(Icons.location_pin),
      super.point = const fm.LatLng(-50.0, -0.2),
      super.width = 20,
      super.height = 20});

  factory TripSummary.fromMap({required Map<String, dynamic> map}) {
    return TripSummary(
      uri: map['uri'],
      title: map['title'] ?? ' ',
      subTitle: map['sub_title'] ?? ' ',
      minLat: map['sw_lat'] ?? 0,
      maxLat: map['ne_lat'] ?? 0,
      minLong: map['sw_lng'] ?? 0,
      maxLong: map['ne_lng'] ?? 0,
      score: map['score'] ?? 0,
      scored: map['scored'] ?? 0,
      point: fm.LatLng(map['sw_lat'] ?? 0, map['sw_log'] ?? 0),
    );
  }
}

class TripItem {
  GlobalKey? handle;
  int key = 0;
  int id = 0;
  String title = '';
  String uri = '';
  String driveUri = '';
  String subTitle = '';
  String body = '';
  String author = '';
  String authorUrl = '';
  bool published = false;
  String imageUrls = '';
  List<Photo> photos;
  double score = 5;
  double distance = 0;
  double distanceAway = 0;
  int pointsOfInterestCount = 0;
  int closest = 12;
  int scored = 10;
  int downloads = 18;
  String added = '';
  List<Polyline> polylines;
  TripItem(
      {this.handle,
      this.id = 0,
      this.driveUri = '',
      this.title = '',
      this.subTitle = '',
      this.body = '',
      this.author = '',
      this.authorUrl = '',
      this.published = false,
      this.imageUrls = '',
      this.score = 5,
      this.distance = 0,
      this.distanceAway = 0,
      this.pointsOfInterestCount = 0,
      this.closest = 12,
      this.scored = 10,
      this.downloads = 18,
      this.added = '',
      this.photos = const [],
      this.uri = '',
      this.polylines = const []});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'sub_title': subTitle,
      'body': body,
      'author': author,
      'author_url': authorUrl,
      'published': published,
      'image_urls': imageUrls,
      'score': score,
      'distance': distance,
      'points_of_interest': pointsOfInterestCount,
      'closest': closest,
      'scored': scored,
      'downloads': downloads,
    };
  }

  Map<String, dynamic> toMapLocal() {
    return {
      'id': id,
      'title': title,
      'sub_heading': subTitle,
      'body': body,
      'author': author,
      'author_url': authorUrl,
      'published': published,
      'image_urls': imageUrls,
      'score': score,
      'distance': distance,
      'points_of_interest': pointsOfInterestCount,
      'closest': closest,
      'scored': scored,
      'downloads': downloads,
    };
  }

  factory TripItem.fromMap(
      {required Map<String, dynamic> map,
      String endpoint = '',
      String imageUrls = ''}) {
    Map<String, dynamic> tripMap = jsonDecode(map['trip']);
    return TripItem(
      id: tripMap['id'] ?? -1,
      uri: '$endpoint${tripMap['uri'] ?? ''}',
      driveUri: tripMap['uri'] ?? '',
      title: tripMap['title'] ?? '',
      subTitle: tripMap['sub_title'] ?? '',
      body: tripMap['body'] ?? '',
      pointsOfInterestCount: tripMap['pois'] ?? 0,
      distance: tripMap['distance'].toDouble() ?? 0.0,
      added: tripMap['added'] ?? '',
      closest: 0, // has to be calculated
      imageUrls: tripMap['images'] ?? '',
      //    imageUrls: imageUrls.isEmpty
      //        ? tripMap['image_urls'] ?? ''
      //        : imageUrls, // has to be calculated
      score: tripMap['average_rating'] ??
          5.0, // tripMap['average_rating'].toDouble() ?? 5.0,
      scored: tripMap['ratings_count'] ?? 1,
      downloads: tripMap['downloads'] ?? 0,
    );
  }

/*

      id: map['id'] is int ? map['id'] : -1,
      driveUri: map['id'] is String
          ? map['id']
          : '', // The API sends back the uri as id
      heading: map['title'] ?? map['heading'],
      subHeading: map['sub_title'] ?? map['sub_heading'],
      body: map['body'],
      author: map['author'] ?? '',
      published: map['added'] ?? DateTime.now().toIso8601String(),
      imageUrls: imageUrls.isEmpty
          ? map['image_urls'] ?? ''
          : imageUrls, // has to be calculated
      score: map['average_rating'] ?? 5,
      distance: map['distance'] ?? 0,
      pointsOfInterest: map['points_of_interest'] is int
          ? map['points_of_interest'] ?? 0
          : (map['points_ofInterest'] ?? []).length,
      closest: 0, // has to be calculated
      scored: map['ratings_count'] ?? 1,
      downloads: map['downloads'] ?? 0,
      uri: '$endpoint${map['uri'] ?? ''}',

    );
  }
*/
  factory TripItem.from3DCache(
      {required Map<String, dynamic> map,
      String endpoint = '',
      String imageUrls = ''}) {
    return TripItem(
      id: -1,
      driveUri: '',
      title: map['title'] ?? ' ',
      subTitle: 'sub_title',
      body: 'body',
      author: map['author'],
      published: map['published'], // ?? DateTime.now().toIso8601String(),
      score: map['rating'].toDouble(),
      distance: map['distance'],
      pointsOfInterestCount: map['points_of_interest'],
      closest: 0, // has to be calculated
      scored: map['rated'],
      downloads: map['downloads'] ?? 0,
      uri: '',
    );
  }
}

class Drive {
  int id = 0;
  int userId = 0;
  String title;
  String subTitle;
  String body;
  DateTime added = DateTime.now();
  double distance = 0;
  int pois = 0;
  String images = '';
  List<PointOfInterest> pointsOfInterest = [];
  Drive({
    this.id = 0,
    required this.userId,
    required this.title,
    required this.subTitle,
    required this.body,
    required this.added,
    this.images = '',
    this.distance = 0,
    this.pois = 0,
  });

  Future<bool> saveLocally() async {
    try {
      id = await getPrivateRepository().saveDrive(drive: this);
    } catch (e) {
      debugPrint('Error saving trip: ${e.toString()}');
    }
    return true;
  }

  Future<bool> publish() async {
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'sub_title': subTitle,
      'body': body,
      'added': added.toString(),
      'map_image': images,
      'distance': distance,
      'points_of_interest': pois,
    };
  }

  Future<bool> getDetailsLocal() async {
    return true;
  }

  Future<bool> getDetailsApi() async {
    return true;
  }
}

class TripMessage {
  String id;
  String type;
  String sender;
  String email;
  String message;
  double lat;
  double lng;
  String manufacturer;
  String model;
  String carColour;
  String registration;
  String phoneNumber;
  int accepted;
  TripMessage(
      {this.id = '',
      this.type = '',
      this.sender = '',
      this.email = '',
      this.message = '',
      this.lat = 0.0,
      this.lng = 0.0,
      this.manufacturer = '',
      this.model = '',
      this.carColour = '',
      this.registration = '',
      this.phoneNumber = '',
      this.accepted = 0});
  factory TripMessage.fromSocketMap(Map<String, dynamic> map) {
    return TripMessage(
        id: map['id'] ?? '',
        type: map['type'] ?? '',
        email: map['email'] ?? '',
        sender: map['sender'] ?? '',
        message: map['message'] ?? '',
        lat: map['lat'] ?? 0.0,
        lng: map['lng'] ?? 0.0,
        manufacturer: map['make'] ?? '',
        model: map['model'] ?? '',
        carColour: map['colour'] ?? '',
        registration: map['reg'] ?? '',
        phoneNumber: map['phone'] ?? '',
        accepted: map['accepted'] ?? 0);
  }
}

class Message {
  String id;
  String senderId = '';
  String sender;
  String message;
  String userTargetId;
  String groupTargetId;
  String email;
  bool read;
  bool sent;
  String dated = '';
  DateTime received; // = DateTime.now();
  // DateFormat dateFormat = DateFormat("dd MMM yyyy");

  Message(
      {required this.id,
      required this.sender,
      required this.message,
      this.read = false,
      this.sent = false,
      this.userTargetId = '',
      this.groupTargetId = '',
      this.email = '',
      this.dated = '',
      DateTime? received})
      : received = received ?? DateTime.now();

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      sender: map['sender'] ?? '',
      sent: (map['sent'] ?? 0) == 1,
      email: map['email'] ?? '',
      message: map['message'] ?? '',
      read: (map['is_read'] ?? 0) == 1,
      userTargetId: map['target_id'] ?? '',
      groupTargetId: map['group_target_id'] ?? '',
      dated: map['received'] ?? '',
      received: DateTime.now(),
    );
  }

  factory Message.fromSocketMap(Map<String, dynamic> map) {
    String email = map['email'] ?? '';
    return Message(
      id: '',
      sender: map['sender'] ?? 'unknown sender',
      message: map['message'] ?? 'test',
      email: email,
      sent: email == Setup().user.email ? true : false,
      dated: DateFormat("dd MMM yy HH:mm").format(DateTime.now()),
      received: DateTime.now(),
      read: false,
    );
  }
}

class MessageLocal {
  int id = -1;
  GroupMember groupMember;
  String message = '';
  bool read = false;
  bool selected = false;
  int targetId = 0;
  DateTime received = DateTime.now();
  int index = 0;
  MessageLocal(
      {required this.id,
      required this.groupMember,
      required this.message,
      this.read = false,
      this.selected = false}) {
    received = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': groupMember.id,
      'target_id': targetId,
      'message': message,
      'read': read ? 1 : 0,
      'received': received.toString(),
    };
  }
}

class PopupValue {
  int dropdownIdx = -1;
  String text1 = '';
  String text2 = '';
  PopupValue(this.dropdownIdx, this.text1, this.text2);
}

/// lines and shields geometry format for MapLibre [[lng, lat], [lng, lat], ...]
/// have to be defined in Flutter a List<dynamic> rather than List<List<double>>
class GoodRoad {
  final int id; // SqLite id
  final String uri; // api uri
  List<dynamic> lines;
  List<dynamic> shields;
  List<Point> waypoints;
  String pointOfInterestUri;
  GoodRoad({
    this.id = -1,
    this.uri = '',
    List<dynamic>? lines,
    List<dynamic>? shields,
    List<Point>? waypoints,
    this.pointOfInterestUri = '',
  })  : lines = lines ?? [],
        shields = shields ?? [],
        waypoints = waypoints ?? [];

  /// Bundling everything up int a single class simplified the
  /// separating of the Route and GoodRoad geoJSON data - good-road-data

  factory GoodRoad.fromMap({required Map<String, dynamic> map}) {
    return GoodRoad(
      id: map["id"] ?? -1,
      uri: map["uri"] ?? "",
      lines: map["lines"] ?? [],
      shields: map["shields"] ?? [],
      waypoints: map["waypoints"] ?? [],
      pointOfInterestUri: map["point_of_interest_uri"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "uri": uri,
      "lines": lines,
      "shields": shields,
      "waypoints": waypoints,
      "point_of_interest_uri": pointOfInterestUri,
    };
  }

  Map<String, dynamic> toJSON({PointOfInterest? pointOfInterest}) {
    pointOfInterest = pointOfInterest ?? PointOfInterest();
    pointOfInterest.uuid = pointOfInterest.uuid ?? getUuid();
    pointOfInterestUri = pointOfInterest.uuid!;
    List<Map<String, dynamic>> waypointsJSON = [
      for (int i = 0; i < waypoints.length; i++)
        {
          'point': {'lat': waypoints[i].y, 'long': waypoints[i].x}
        }
    ];
    return {
      "id": id,
      "uri": uri.isNotEmpty ? uri : getUuid(),
      "line_h": lines,
      "shields": shields,
      "waypoints": waypointsJSON,
      "point_of_interest_uri": pointOfInterestUri,
      "point_of_interest": pointOfInterest.toMap()
    };
  }
}

List<Map<String, dynamic>> jsonFromGoodRoads(
    {required List<GoodRoad> goodRoadList}) {
  List<Map<String, dynamic>> json = [];
  for (int i = 0; i < goodRoadList.length; i++) {
    json.add(goodRoadList[i].toMap());
  }
  return json;
}

List<GoodRoad> goodRoadsFromJson({required jsonList}) {
  List<GoodRoad> goodRoads = [];
  for (int i = 0; i < jsonList.length; i++) {
    goodRoads.add(GoodRoad.fromMap(map: jsonList[i]));
  }
  return goodRoads;
}
