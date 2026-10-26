import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;

import '/helpers/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:universal_io/universal_io.dart';
import '/services/services.dart' hide getPosition;
import '/classes/classes.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '/constants.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:universal_io/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// https://api.flutter.dev/flutter/material/Icons-class.html  get the icon codepoint from here
/// https://api.flutter.dev/flutter/material/Icons/add_road-constant.html eeaf

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

String colourIntToHex({int index = 0}) {
  return uiColours.keys.toList()[index].toHexStringRGB();
}

void myFunc() {}

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
  int aiRouteColour = 5; // <-- a trip AI assist suggested, until it's saved
  int bottomNavIndex = 0;
  int recordDetail = 5;
  int nextScreen = 1;

  /// Following a published trip counts it as driven - only a summary is
  /// sent (DrivenLog), and only if the user turns this on
  bool verifyDriven = false;
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
  Position lastPosition = Position();

  String jwt = '';
  User user = User(
      id: 0, forename: '', surname: '', password: '', email: '', phone: '');
  String appDocumentDirectory = '';
  late Directory cacheDirectory;
  late Directory soundsDirectory;
  late String appState = '';

  Setup._privateConstructor();
  static final _instance = Setup._privateConstructor();
  factory Setup() {
    return _instance;
  }
  final FlutterSecureStorage _storage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'MotatekSecure',
      publicKey: 'Config',
    ),
    // iOS-specific configuration
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// The saved login token. Start-up waits for this - and only this, as the
  /// rest of loaded can take a while - so the first pages ask the API with
  /// it: Home asked before it was read, so a club's items didn't show
  Future<void> loadToken() async {
    try {
      jwt = await _storage.read(key: 'jwt') ?? '';
    } catch (e) {
      developer.log('Error reading the saved token: ${e.toString()}',
          name: 'error');
    }
  }

  /// Setup().loaded ensures Setup singleton has been instantiated, and looks to see if a
  /// silent login is possible by retrieving the jwt either from secure storage on
  /// the Web version or SQLite for the mobile.
  /// If the jwt logs in OK then the Web version has to retrieve the settings from the api, and the
  /// mobile version from SQLite.
  /// If the jwt isn't available or valid then a login will be initiated through dialogs.dart
  /// LoginDialog Class.

  Future<bool> get loaded async {
    // Images, the cache and voice memos are stored under the documents
    // directory - this was lost in the move from SQLite to Hive
    if (!kIsWeb) {
      try {
        appDocumentDirectory = (await getApplicationDocumentsDirectory()).path;
        for (String folder in ['cache', 'sounds']) {
          await Directory('$appDocumentDirectory/$folder')
              .create(recursive: true);
        }
      } catch (e) {
        developer.log('Error Setup() loaded() directories: ${e.toString()}',
            name: 'error');
      }
    }
    lastPosition = await getPosition();

    try {
      jwt = await _storage.read(key: 'jwt') ?? '';
      if (jwt.isNotEmpty) {
        String? newJwt = await refreshToken();
        if (newJwt == null) {
          // Offline - keep the saved token
        } else if (newJwt.isEmpty) {
          // Expired or invalid - forget it, so the app doesn't treat the
          // user as registered (e.g. offering Publish, which the server
          // would refuse) until they log in again
          jwt = '';
          await _storage.delete(key: 'jwt');
        } else {
          jwt = newJwt;
          hasLoggedIn = true;
          await _storage.write(key: 'jwt', value: jwt);
        }
        MapService().persistentAppBarController?.update('');
      }
      UserRepository userRepository = UserRepository();
      await userRepository.getSetup();
      user = await userRepository.getUser() ?? user;
    } catch (e) {
      developer.log('Error Setup() loaded() retrieving jwt: ${e.toString()}',
          name: 'error');
    }

    /// Have to add the get setup data from the api.

    return jwt.isEmpty;
  }

  /// A missing setting keeps its current value - settings saved before a
  /// field was added, or in the old format, mustn't stop the rest loading
  fromJson({required Map<String, dynamic> map}) {
    id = 0;
    routeColour = map['routeColour'] ?? routeColour;
    goodRouteColour = map['goodRouteColour'] ?? goodRouteColour;
    waypointColour = map['waypointColour'] ?? waypointColour;
    pointOfInterestColour =
        map['pointOfInterestColour'] ?? pointOfInterestColour;
    waypointColour2 = map['waypointColour2'] ?? waypointColour2;
    pointOfInterestColour2 =
        map['pointOfInterestColour2'] ?? pointOfInterestColour2;
    selectedColour = map['selectedColour'] ?? selectedColour;
    highlightedColour = map['highlightedColour'] ?? highlightedColour;
    publishedTripColour = map['publishedTripColour'] ?? publishedTripColour;
    aiRouteColour = map['aiRouteColour'] ?? aiRouteColour;
    verifyDriven = map['verifyDriven'] ?? verifyDriven;
    dark = map['dark'] ?? dark;
    rotateMap = map['rotateMap'] ?? rotateMap;
    avoidMotorways = map['avoidMotorways'] ?? avoidMotorways;
    avoidAroads = map['avoidAroads'] ?? avoidAroads;
    avoidBroads = map['avoidBroads'] ?? avoidBroads;
    avoidTollRoads = map['avoidTollRoads'] ?? avoidTollRoads;
    avoidFerries = map['avoidFerries'] ?? avoidFerries;
    osmPubs = map['osmPubs'] ?? osmPubs;
    osmRestaurants = map['osmRestaurants'] ?? osmRestaurants;
    osmFuel = map['osmFuel'] ?? osmFuel;
    osmToilets = map['osmToilets'] ?? osmToilets;
    osmAtms = map['osmAtms'] ?? osmAtms;
    osmHistorical = map['osmHistorical'] ?? osmHistorical;
    maleVoice = map['maleVoice'] ?? maleVoice;
  }

  Map<String, dynamic> toJson() {
    return {
      'routeColour': routeColour,
      'goodRouteColour': goodRouteColour,
      'waypointColour': waypointColour,
      'pointOfInterestColour': pointOfInterestColour,
      'waypointColour2': waypointColour2,
      'pointOfInterestColour2': pointOfInterestColour2,
      'selectedColour': selectedColour,
      'highlightedColour': highlightedColour,
      'publishedTripColour': publishedTripColour,
      'aiRouteColour': aiRouteColour,
      'verifyDriven': verifyDriven,
      'dark': dark,
      'rotateMap': rotateMap,
      'avoidMotorways': avoidMotorways,
      'avoidAroads': avoidAroads,
      'avoidBroads': avoidBroads,
      'avoidTollRoads': avoidTollRoads,
      'avoidFerries': avoidFerries,
      'osmPubs': osmPubs,
      'osmRestaurants': osmRestaurants,
      'osmFuel': osmFuel,
      'osmToilets': osmToilets,
      'osmAtms': osmAtms,
      'osmHistorical': osmHistorical,
      'maleVoice': maleVoice,
    };
  }

  /// Saves the login token, the user and the settings. The writes weren't
  /// awaited, and the settings weren't saved at all.
  Future<void> save() async {
    await _storage.write(key: 'jwt', value: jwt);
    UserRepository userRepository = UserRepository();
    await userRepository.saveUser(user);
    await userRepository.saveSetup();
  }

  /// If the user has logged in correctly then the api will contain the
  /// user's details.
  /// The Mobile version will store the user details in SQLite
  /// The Web version will only save the JWT but will have to retrieve the
  /// setup Json Object from the api that contains full user details and colours etc
  Future<void> saveUser() async {
    await _storage.write(key: 'jwt', value: jwt);
    saveUserLocally(user);
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

  String aiRouteColourHex() {
    return colourList[aiRouteColour].toHexStringRGB();
  }

  int debugIndex = 0;
}

class PointOfInterest {
  int id;
  String uuid;
  Point point;
  String images;
  String name;
  String description;
  String sounds;
  double score;
  int scored;
  int type;
  List<Photo> photos;

  PointOfInterest({
    this.id = -1,
    String? uuid,
    this.point = const Point(0, 0),
    this.type = -1,
    this.name = '',
    this.description = '',
    this.images = '',
    this.score = 0,
    this.scored = 0,
    this.sounds = '',
    List<Photo>? photos,
  })  : uuid = uuid ?? getUuid(),
        photos = photos ?? <Photo>[];

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

  factory PointOfInterest.fromJson({required Map<String, dynamic> map}) {
    String uploadEndPoint = '${urlBase}api/static/images';
    Map<String, dynamic> point = jsonDecode(map['point']);
    List images = jsonDecode(map['images']);

    List<Photo> photos = [];
    for (int i = 0; i < images.length; i++) {
      images[i] = images[i] is String ? jsonDecode(images[i]) : images[i];
      images[i]['url'] = '$uploadEndPoint/${map['drive_id']}/${map['id']}.jpg';
      photos.add(Photo.fromJson(images[i]));
    }

    debugPrint('images: $images');

    return PointOfInterest(
      id: -1,
      uuid: map['id'],
      point: Point(point['coordinates'][0], point['coordinates'][1]),
      type: map['type'] ?? 0,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      images: map['images'] ?? '[]',
      score: (map['rating'] ?? 0).toDouble(),
      scored: map["rated"] ?? 0,
      sounds: '',
      photos: photos,
    );
  }

  List<Photo> getPhotos({required String driveId, bool fromWeb = true}) {
    String endPoint = fromWeb
        ? '$staticImagesFolder/$driveId/'
        : '${Setup().appDocumentDirectory}/$driveId/';

    List<Photo> photos = photosFromJson(
      photoString: images, // imagesString,
      id: id,
      endPoint: endPoint,
    );
    return photos;
  }

  /// Adds a photo and rebuilds images as one flat JSON list. Wrapping the old
  /// string ('[$images, $photo]') nested a third photo as [[a, b], c], which
  /// photosFromJson() couldn't read, losing the photos.
  void addPhoto({required Photo photo}) {
    if (photos.isEmpty && images.isNotEmpty) {
      photos.addAll(photosFromJson(photoString: images));
    }
    photos.add(photo);
    images = '[${photos.map((p) => p.toString()).join(', ')}]';
  }

  /// complete returns the data state of the PointOfInterest:
  /// 0 is nothing added
  /// 1 is      name complete
  /// 1 << 1    description complete
  /// -> 0 nothing 1 name complete 2 description complete 3 all complete

  int complete() {
    return (name.isEmpty ? 0 : 1) | (description.isEmpty ? 0 : 1 << 1);
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

  get published => '';

  Map<String, dynamic> toGeoJson(
      {int index = 0, String? colour, String author = '', int rated = 0}) {
    colour ??= Setup().pointOfInterestColourHex();
    Map<String, dynamic> geoJson = {};
    try {
      geoJson = {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [point.x, point.y]
        },
        "id": 'poi$index',
        'properties': {
          "group": "point_of_interest", // <- For filtering
          "icon": "shield",
          "color": type == 13
              ? Setup().goodRouteColourHex()
              : Setup().pointOfInterestColourHex(),
          'drive_id': id,
          'uri': uuid,
          'name': name,
          'description': description,
          'type': type,
          'images': images,
          'rated': rated,
          'rating': '${'★' * score.toInt()}${'☆' * (5 - score.toInt())}',
          'author': author
        }
      };
    } catch (e) {
      developer.log('Error calling PointOfInterest.toGeoJson()', name: 'error');
    }
    return geoJson;
  }
}

List<PointOfInterest> pointsOfInterestFromJson(
    {required List<dynamic> jsonList}) {
  return [
    for (Map<String, dynamic> json in jsonList)
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

// Getter for edited have to use this because ints are passed by value not by reference
  bool get edited => isEdited == 'true';
// Setter for edited
  set edited(bool value) => isEdited = value ? 'true' : 'false';

  Map<String, dynamic> toMap() {
    return {'user_id': userId, 'group_id': groupId, 'email': email};
  }

  Map<String, dynamic> toFullMap() {
    return {
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

/// The Photo class is used to present the ImageArranger with the data required
/// It takes the raw file name and adds the endpoint to give the full url

class Photo {
  String url;
  int id;
  String key;
  int index;
  int rotation;
  double width;
  String align;
  String caption;
  String endPoint;
  Photo(
      {required this.url,
      this.id = -1,
      this.key = '',
      this.index = -1,
      this.align = 'center',
      this.caption = '',
      this.rotation = 0,
      this.width = 200,
      this.endPoint = ''});

  factory Photo.fromJson(Map<String, dynamic> json,
      {int index = -1, String endPoint = ''}) {
    String url = json['url'] ?? '';
    var key = json['key'] ?? '';
    key = key is String ? key : '';
    url = endPoint.isNotEmpty ? url.split("/").last : url;
    url = (Setup().appDocumentDirectory.isNotEmpty &&
                url.contains(Setup().appDocumentDirectory)) ||
            url.isEmpty ||
            url.contains('http') /* ||
            key.isNotEmpty */
        ? url
        : '$endPoint/$url';

    // Numbers as either (a width of 200 threw, as it isn't a double, and
    // the photos weren't shown)
    return Photo(
        url: url,
        id: json['id'] ?? -1,
        caption: json['caption'] ?? '',
        align: json['align'] ?? 'center',
        rotation: (json['rotation'] as num? ?? 0).toInt(),
        width: (json['width'] as num? ?? 200).toDouble(),
        key: key,
        index: index);
  }

  factory Photo.fromJsonMap(Map<String, dynamic> json) {
    return Photo(
      url: json['url'] ?? '',
      id: int.parse(json['id'] ?? '-1'),
      caption: json['caption'] ?? '',
      align: json['align'] ?? 'center',
      rotation: json['rotation'] ?? 0,
      width: json['width'] ?? 200,
    );
  }

  /// Photo.toJson() will only ever be used for sending photo data to the api so the key should be empty
  String toJson() {
    return '{"url": "$url", "caption": "$caption", "align": "$align", "rotation": $rotation, "width": $width, "key": ""}';
  }

  String toMapString() {
    if (url.contains('http')) {
      return '{"url": "${url.substring(url.lastIndexOf('/') + 1)}", "caption": "$caption", "rotation": $rotation, "width": $width, "key": "$key"}';
    } else {
      return '{"url": "$url", "caption": "$caption",  "align": "$align","rotation": $rotation,  "width": $width, "key": "$key"}';
    }
  }

  String toString() {
    return '{"url": "$url", "caption": "$caption",  "align": "$align", "rotation": $rotation,  "width": $width,"key": "$key"}';
  }

  String toEscapedString() {
    Map<String, dynamic> json = {
      'url': url,
      'caption': caption,
      'align': align,
      'rotation': rotation,
      'width': width,
    };
    return jsonEncode(json);
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
  int type;

  User({
    this.id = 0,
    this.forename = '',
    this.surname = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.uri = '',
    this.imageUrl = '',
    this.type = 1,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        id: json['id'],
        forename: json['forename'],
        surname: json['surname'],
        email: json['email'],
        phone: json['phone'],
        password: json['password'],
        imageUrl: json['imageUrl'],
        type: json['type']);
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
      'type': type,
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
      'type': type,
    };
  }
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
  bool? calculated;
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
    this.calculated,
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
      "lat": '${point.y}',
      "lon": '${point.x}',
      "modifier": modifier,
      "type": type,
      "distance": distance,
    };
  }
}

List<Waypoint> waypointsFromJson({required List<dynamic> jsonList}) {
  return [
    for (Map<String, dynamic> json in jsonList) Waypoint.fromMap(map: json)
  ];
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

  /// A participant from the API's group drive invitations
  /// (group_drive_invitation/<group drive>/<state>)
  factory Follower.fromParticipantMap({required Map<String, dynamic> map}) {
    double lat = double.tryParse('${map["lat"] ?? 0}') ?? 0;
    double lng = double.tryParse('${map["lng"] ?? 0}') ?? 0;
    return Follower(
      uri: map["invitation_id"] ?? "",
      driveId: map["group_drive_id"] ?? "",
      driveName: map["drive_name"] ?? "",
      forename: map["user_forename"] ?? "",
      surname: map["user_surname"] ?? "",
      email: map["user_email"] ?? "",
      phoneNumber: map["user_phone"] ?? "",
      manufacturer: map["manufacturer"] ?? "",
      model: map["model"] ?? "",
      registration: map["registration"] ?? "",
      carColour: map["colour"] ?? "",
      accepted: int.tryParse('${map["accepted"] ?? 0}') ?? 0,
      position: [lng, lat],
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

  Follower moveFollower({List<double>? newPosition}) {
    return Follower(
      uri: uri,
      userId: userId,
      driveId: driveId,
      driveName: driveName,
      forename: forename,
      surname: surname,
      email: email,
      phoneNumber: phoneNumber,
      manufacturer: manufacturer,
      model: model,
      registration: registration,
      carColour: carColour,
      iconColour: iconColour,
      routeIndex: routeIndex,
      accepted: accepted,
      track: track,
      position: newPosition ?? position,
    );
  }

  void moveFollower2({List<double>? position}) {
    if (position != null) {
      position = position;
    }
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
        '[{"url":${mappedUrls.substring(1, mappedUrls.length - 1)}, "caption": "", "rotation": 0}]';
  }
  return mappedUrls;
}

class HomeItem {
  int id;
  String markdown;
  Map<String, dynamic>? style;
  int score;
  List<Map<String, dynamic>>? images;
  String heading;
  String subheading;
  String url;
  String added;
  String author;

  HomeItem({
    this.id = 0,
    this.url = '',
    this.markdown = '',
    this.style,
    this.images,
    this.score = 5,
    this.heading = 'Heading',
    this.subheading = 'Subheading',
    added,
    this.author = ' ',
  }) : added = added ?? dateFormatDoc.format(DateTime.now());

  factory HomeItem.fromMap({required Map<String, dynamic> map}) {
    try {
      List<Map<String, dynamic>> images = [{}];
      if (map['images'].isNotEmpty) {
        List dynamicMap = jsonDecode(map['images']);
        for (Map image in dynamicMap) {
          images.add(Map<String, dynamic>.from(image));
        }
      }
      HomeItem homeItem = HomeItem(
          url: map['id'], //<-- on api the uri is id the primary column
          heading: map['heading'],
          subheading: map['subheading'],
          markdown: map['markdown'],
          style: Map<String, dynamic>.from(jsonDecode(map['style'])),
          images: images,
          added: dateFormatDoc.format(DateTime.parse(map['added'])),
          author: map['author'],
          score: map['score'] ?? 5);
      return homeItem;
    } catch (e) {
      developer.log('error getting HomeItem.fromMap(): ${e.toString()}',
          name: 'error');
    }
    return (HomeItem());
  }
  String uri = getUuid();

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'heading': heading,
      'subheading': subheading,
      'markdown': markdown,
      'style': style,
      'score': score,
      'images': images,
      'added': added,
      'author': author,
    };
  }
}

/// ShopItem that uses Markdown version. The only data that it uses is the Markdown text, the
/// stylesheet, and the images. The titles, subtitles and links remain in the Markdown and
/// don't have to be handled separately.

class ShopItem {
  int id;
  String markdown;
  Map<String, dynamic>? style;
  int score;
  List<Map<String, dynamic>>? images;
  String heading;
  String subheading;
  String url;
  String added;
  String author;

  ShopItem({
    this.id = 0,
    this.url = '',
    this.markdown = '',
    this.style,
    this.images,
    this.score = 5,
    this.heading = 'Heading',
    this.subheading = 'Subheading',
    added,
    this.author = ' ',
  }) : added = added ?? dateFormatDoc.format(DateTime.now());

  factory ShopItem.fromMap({required Map<String, dynamic> map}) {
    try {
      List<Map<String, dynamic>> images = [{}];
      if (map['images'].isNotEmpty) {
        List dynamicMap = jsonDecode(map['images']);
        for (Map image in dynamicMap) {
          images.add(Map<String, dynamic>.from(image));
        }
      }
      ShopItem shopItem = ShopItem(
          url: map['id'], //<-- on api the uri is id the primary column
          heading: map['heading'],
          subheading: map['subheading'],
          markdown: map['markdown'],
          style: Map<String, dynamic>.from(jsonDecode(map['style'])),
          images: images,
          added: dateFormatDoc.format(DateTime.parse(map['added'])),
          author: map['author'],
          score: map['score'] ?? 5);
      return shopItem;
    } catch (e) {
      developer.log('error getting ShopItem.fromMap(): ${e.toString()}',
          name: 'error');
    }
    return (ShopItem());
  }
  String uri = getUuid();

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'heading': heading,
      'subheading': subheading,
      'markdown': markdown,
      'style': style,
      'score': score,
      'images': images,
      'added': added,
      'author': author,
    };
  }
}

/// class TripItem
///

class TripSummary {
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
  final String author; // who published it - shown to admins

  TripSummary(
      {this.cacheKey = -1,
      this.uri = '',
      this.title = '',
      this.subTitle = '',
      this.author = '',
      this.minLat = -180.0,
      this.maxLat = 180,
      this.minLong = -180,
      this.maxLong = 180,
      this.score = 5.0,
      this.scored = 1});

  factory TripSummary.fromMap({required Map<String, dynamic> map}) {
    return TripSummary(
      uri: map['uri'],
      title: map['title'] ?? ' ',
      subTitle: map['sub_title'] ?? ' ',
      author: map['author'] ?? '',
      minLat: map['sw_lat'] ?? 0,
      maxLat: map['ne_lat'] ?? 0,
      minLong: map['sw_lng'] ?? 0,
      maxLong: map['ne_lng'] ?? 0,
      score: ((map['score'] ?? 0) as num).toDouble(),
      scored: ((map['scored'] ?? 0) as num).toInt(),
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
  List<Photo>? photos;
  String score = '';
  double rating = 5;
  double distance = 0;
  double distanceAway = 0;
  int pointsOfInterestCount = 0;
  int closest = 12;
  int scored = 10;
  int downloads = 18;

  /// How many people have driven it (following it - DrivenLog)
  int driven = 0;
  String added = '';
  List polylines;

  /// [lng, lat] of the start of the route - published trips, from their
  /// line on the map, so the map can pan to it
  List startPoint = const [];
  TripItem({
    this.handle,
    this.id = 0,
    this.driveUri = '',
    this.title = '',
    this.subTitle = '',
    this.body = '',
    this.author = '',
    this.authorUrl = '',
    this.published = false,
    this.imageUrls = '',
    this.score = '',
    this.rating = 5,
    this.distance = 0,
    this.distanceAway = 0,
    this.pointsOfInterestCount = 0,
    this.closest = 12,
    this.scored = 10,
    this.downloads = 18,
    this.driven = 0,
    this.added = '',
    List<Photo>? photos,
    this.uri = '',
    this.polylines = const [],
  }) : photos = photos ?? <Photo>[];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uri': uri,
      'title': title,
      'sub_title': subTitle,
      'body': body,
      'author': author,
      'author_url': authorUrl,
      'published': published,
      'image_urls': imageUrls,
      'score': score,
      'rating': rating,
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
      'uri': uri,
      'title': title,
      'sub_heading': subTitle,
      'body': body,
      'author': author,
      'author_url': authorUrl,
      'published': published,
      'image_urls': imageUrls,
      'score': score,
      'rating': rating,
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
      //        : imageUrls, // has to be calculated
      rating: tripMap['average_rating'] ??
          5.0, // tripMap['average_rating'].toDouble() ?? 5.0,
      score:
          "${'★' * (tripMap['average_rating'] ?? 5).toInt()}${'☆' * (5 - (tripMap['average_rating'] ?? 5)).toInt()}",
      scored: tripMap['ratings_count'] ?? 1,
      downloads: tripMap['downloads'] ?? 0,
    );
  }

  List<Photo> get tripPhotos => photos ?? <Photo>[];

  set addPhotos(List<Photo> photos) => photos = photos;

  String toStars({var value}) {
    int starValue = value.toInt();
    return ("${'★' * starValue}${'☆' * (5 - starValue)}");
  }

  factory TripItem.from3DCache(
      {required Map<String, dynamic> map,
      String uri = '',
      String endpoint = '',
      String imageUrls = ''}) {
    TripItem tripItem = TripItem();
    try {
      tripItem = TripItem(
        id: -1,
        uri: uri,
        driveUri: '',
        title: map['title'] ?? ' ',
        subTitle: map['sub_title'], //'sub_title',
        body: map['body'], //'body',
        author: map['author'] ?? '',
        published: true, //
        added: map['published'], // ?? DateTime.now().toIso8601String(),
        score: map['rating'], //.toDouble(),
        distance: map['distance'],
        pointsOfInterestCount: map['points_of_interest'],
        closest: 0, // has to be calculated
        scored: map['rated'],
        downloads: map['downloads'] ?? 0,
        driven: map['driven'] ?? 0,
      );
    } catch (e) {
      debugPrint('Error creating TripItem from map');
    }
    return tripItem;
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

class PopupValue {
  int dropdownIdx = -1;
  String text1 = '';
  String text2 = '';
  PopupValue(this.dropdownIdx, this.text1, this.text2);
}

Map<String, dynamic> toGeoJson(
    {int index = 0, required List<int> point, bool highlighted = false}) {
  String colour =
      highlighted ? Setup().highlightedColourHex() : Setup().routeColourHex();
  return {
    "id": 'wp$index',
    "type": "Feature",
    "group": "waypoint",
    "geometry": {"type": "Point", "coordinates": point},
    "properties": {
      "item": "waypoint",
      "number": index + 1,
      "group": 'shield',
      "color": colour,
    }
  };
}

List<Map<String, dynamic>> jsonFromGoodRoads(
    {required List<Route> goodRoadList}) {
  List<Map<String, dynamic>> json = [];
  for (int i = 0; i < goodRoadList.length; i++) {
    json.add(goodRoadList[i].toMap());
  }
  return json;
}

List<Route> goodRoadsFromJson({required jsonList}) {
  List<Route> goodRoads = [];
  for (int i = 0; i < jsonList.length; i++) {
    goodRoads.add(Route.fromMap(map: jsonList[i]));
  }
  return goodRoads;
}
