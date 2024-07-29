// import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:ffi';
import 'package:drives/utilities.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:drives/screens/painters.dart';
import 'package:drives/services/db_helper.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
import 'route.dart' as mt;
// import 'dart:ui' as ui;

/// https://api.flutter.dev/flutter/material/Icons-class.html  get the icon codepoint from here
/// https://api.flutter.dev/flutter/material/Icons/add_road-constant.html

/*
enum UserMode {
  home,
  routes,
  explore,
  profile,
  shop,
}
*/
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
    'name': 'Great road end',
    'icon': 'Icons.remove_road',
    'iconMaterial': 0xf07bb,
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
  }
];

const List<String> manufacturers = ['Triumph', 'MG', 'Reliant'];
const List<String> models = ['TR2', 'TR3', 'TR5', 'TR6', 'TR7', 'Stag'];
/*
const List<Color> uiColours.keys.toList() = [
  Colors.white,
  Color.fromARGB(255, 25, 65, 26),
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.lime,
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.indigo,
  Colors.deepPurple,
  Colors.cyan,
  Colors.grey,
  Colors.brown,
  Colors.black,
];
*/
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
};

// const List<UiColour> uiColours = [
//  UiColour(0, uiColours.keys.toList()[0], uiColours.keys.toList()[0].toString())
//]

void myFunc() {}

class CutRoute {
  int routeIndex = 0; // holds the polyLine Index in Routes
  int pointIndex = 0; // holds the index of LatLng on the above polyLine
  int precedingPointIndex =
      0; // holds the index of the previous POI in _routes[routeIndex].points[]
  int precedingPoiIndex; // holds the index in _pointsOfInterest of the preceding POI
  LatLng poiPosition =
      const LatLng(0, 0); // The LatLng of the POI to be inserted

  CutRoute(
      {required this.routeIndex,
      required this.pointIndex,
      required this.poiPosition,
      this.precedingPoiIndex = 0,
      this.precedingPointIndex = 0});
}

class Setup {
  int id = 0;
  int routeColour = 5;
  int goodRouteColour = 6;
  int waypointColour = 2;
  int pointOfInterestColour = 3;
  int waypointColour2 = 14;
  int pointOfInterestColour2 = 14;
  int selectedColour = 7;
  int highlightedColour = 8;
  int recordDetail = 5;
  bool allowNotifications = true;
  bool dark = false;
  bool rotateMap = true;

  String jwt = '';
  User user = User(
      id: 0, forename: '', surname: '', password: '', email: '', phone: '');
  bool? _loaded;
  Setup._privateConstructor();
  static final _instance = Setup._privateConstructor();
  factory Setup() {
    return _instance;
  }

  Future<bool> get loaded async {
    return _loaded ??= await setupFromDb();
  }

  Future<bool> setupFromDb() async {
    List<Map<String, dynamic>> maps = await getSetup(0);
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
        recordDetail = maps[0]['record_detail'];
        allowNotifications = maps[0]['allow_notifications'] == 1;
        dark = maps[0]['dark'] == 1;
        rotateMap = maps[0]['rotate_map'] == 1;
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    user = await getUser();
    return true;
  }

  Future<void> setupToDb() async {
    await updateSetup();
  }

  Future<List<Map<String, dynamic>>> getSetupById(int id) async {
    final db = await dbHelper().db;
    List<Map<String, dynamic>> maps = await db.query(
      'setup',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps;
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
      'selected_colour': selectedColour,
      'record_detail': recordDetail,
      'allow_notifications': allowNotifications ? 1 : 0,
      'dark': dark ? 1 : 0,
      'rotate_map': rotateMap ? 1 : 0,
    };
  }

  Future<void> deleteSetupById(int id) async {
    final db = await dbHelper().db;
    await db.delete(
      'setup',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class MarkerLabel extends Marker {
  final int id;
  final int userId;
  final int driveId;
  final int type;
  final String description;
  late final BuildContext ctx;
  late final MarkerWidget marker;
  late final LatLng markerPoint;
  // @override
  // late final Widget child;

  MarkerLabel(this.ctx, this.id, this.userId, this.driveId, this.type,
      this.description, double width, double height,
      {required LatLng markerPoint, required Widget marker})
      : super(child: marker, point: markerPoint, width: width, height: height);

  // Future<Bitma
}

// class PolyLine

class PointOfInterest extends Marker {
  int id;
  String images;

  /// Json [{'image': imageUrl, 'caption': imageCaption}, ...]
  int userId;
  int driveId;
  int type;
  String name;
  String description;
  // IconData iconData;
  // late BuildContext ctx;
  late Widget marker;

  /*
  @override
  late Widget child;
  */
  LatLng markerPoint = const LatLng(52.05884, -1.345583);
  // @override
/*
  WidgetBuilder markerBuilder = (ctx) => RawMaterialButton(
      onPressed: () => myFunc(),
      elevation: 1.0,
      fillColor: uiColours.keys.toList()[Setup().waypointColour],
      padding: const EdgeInsets.all(2.0),
      shape: const CircleBorder(),
      child: const Icon(
        Icons.pin_drop,
        size: 60,
        color: Colors.blueAccent,
      ));
 */
  PointOfInterest(
      //  this.ctx,
      this.id,
      this.userId,
      this.driveId,
      this.type,
      this.name,
      this.description,
      double width,
      double height,
      this.images,
      // RawMaterialButton button,
      //    this.iconData,
      // Key key,
      {required LatLng markerPoint,
      required Widget marker

      /*required this.xchild*/
      })
      : super(
          child: marker,
          point: markerPoint,
          width: width,
          height: height, /*key: key*/
        );

  IconData setIcon({required type}) {
    return markerIcon(type);
  }

  set position(LatLng pos) {
    markerPoint = pos;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'useId': userId,
      'driveId': driveId,
      'type': type,
      'name': name,
      'description': description,
      'latitude': markerPoint.latitude,
      'longitude': markerPoint.longitude,
    };
  }

  /// The : super keyword means we are referring to base class - Marker - parameters
  /// The point and builder are both required
}
/*
Marker(
  width: 55,
  height: 55,
  point: LatLng(0, 0),
  builder: (_) => Transform.rotate(
    angle: -this._rotation * math.pi / 180,
    child: Container()
)
*/

class MarkerWidget extends StatelessWidget {
  set iconType(int poiType) {
    // setState(() {
    type = poiType;
    // });
    // _context = context;
  }

  int type = 12; // default type 12 => waypoint
  String description;
  double angle = 0;
  int colourIdx = -1;

  MarkerWidget(
      {super.key,
      required this.type,
      this.description = '',
      this.angle = 0,
      this.colourIdx = -1});

  @override
  Widget build(BuildContext context) {
    int width = 30;
    double iconWidth = width * 0.75;
    Color buttonFillColor =
        uiColours.keys.toList()[Setup().pointOfInterestColour];
    Color iconColor = Colors.blueAccent;
    switch (type) {
      case 12:
        buttonFillColor = uiColours.keys.toList()[Setup().waypointColour];
        iconWidth = 10;
        break;
      case 16:
        buttonFillColor = Colors.transparent;
        iconColor = uiColours.keys.toList()[colourIdx < 0 ? 0 : colourIdx];
        iconWidth = 22;
        break;
    }
    // Want to counter rotate the icons so that they are vertical when the map rotates
    // -_mapRotation * pi / 180 to convert from _mapRotation in degrees to radians
    return Transform.rotate(
        angle: angle,
        child: RawMaterialButton(
            onPressed: () => Utility().showAlertDialog(
                context, poiTypes.toList()[type]['name'], description),
            elevation: 2.0,
            fillColor: buttonFillColor,
            shape: const CircleBorder(),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 1, 2),
                child: Icon(
                  markerIcon(type),
                  size: iconWidth,
                  color: iconColor,
                ))));
  }
}

class LabelWidget extends StatelessWidget {
  String description;
  int top;
  int left;
  LabelWidget(
      {super.key,
      required this.top,
      required this.left,
      required this.description});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: MapLabelPainter(
            top: top, left: left, labelText: description, pixelRatio: 1));
  }
}

IconData markerIcon(int type) {
  return IconData(poiTypes.toList()[type]['iconMaterial'],
      fontFamily: 'MaterialIcons');
}
/*
            '''CREATE TABLE groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, 
            created DATETIME)'''); //, locationId INTEGER, vehicleId INTEGER)');
        await db.execute(
            '''CREATE TABLE group_members(id INTEGER PRIMARY KEY AUTOINCREMENT, forename TEXT, surname TEXT, 
            email TEXT, status Integer, joined DATETIME, note TEXT, uri TEXT)''');
*/

class Group {
  int id = -1;
  String name = '';
  String description = '';
  DateTime created = DateTime.now();
  bool edited = false;
  Group(
      {this.id = 0,
      required this.name,
      this.description = '',
      this.edited = false});
  set groupName(String value) => name = value;
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created': created.toString(),
    };
  }
}

class GroupMember {
  // int id = -1;
  String stId = '-1';
  String groupIds = '';
  String forename = '';
  String surname = '';
  String email = '';
  String phone = '';
  String status = '';
  DateTime joined = DateTime.now();
  String note = '';
  String uri = '';
  String isEdited = 'false';
  bool selected = false;
  int index = 0;
  GroupMember(
      {required this.groupIds,
      required this.forename,
      required this.surname,
      this.email = '',
      this.phone = '',
      this.status = '',
      this.stId = '-1',
      note = ''});
// Getter for edited have to use this because ints are passed by value not by reference
  bool get edited => isEdited == 'true';
// Setter for edited
  set edited(bool value) => isEdited = value ? 'true' : 'false';
// Getter for id
  int get id => int.parse(stId);
// Setter for id
  set id(int value) => stId = value.toString();
  Map<String, dynamic> toMap() {
    return {
      'id': stId,
      'group_ids': groupIds,
      'forename': forename,
      'surname': surname,
      'email': email,
      'phone': phone,
      'status': status,
      'joined': joined.toString(),
      'note': note,
      'uri': uri
    };
  }
}

class Photo {
  String url;
  String caption;
  Photo({required this.url, this.caption = ''});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(url: json['url'], caption: json['caption']);
  }

  String toJson() {
    return '{"url": $url, "caption": $caption}';
  }
}

/// Creates a list of photos from a json string of the following format:
///  '[{"url": "assets/images/map.png", "caption": ""}, {"url": "assets/images/splash.png", "caption": ""},
///   {"url": "assets/images/CarGroup.png", "caption": "" }]',
///
///  for some strange reason the string must start with a single quote.

List<Photo> photosFromJson(String photoString) {
  List<Photo> photos = [];
  try {
    photos = (json.decode(photoString) as List<dynamic>)
        .map((jsonObject) => Photo.fromJson(jsonObject))
        .toList();
  } catch (e) {
    String err = e.toString();
    debugPrint('Error converting image data: $err ($photoString)');
  }
  return photos;
}

String photosToJson(List<Photo> photos) {
  String photoString = '';
  for (int i = 0; i < photos.length; i++) {
    photoString = '$photoString, ${photos[i].toJson()} ';
  }
  photoString = '[${photoString.substring(1, photoString.length)}]';
  return photoString;
}

class User {
  int id = 0;
  String forename;
  String surname;
  String password;
  String phone;
  String email;
  String imageUrl;

  User({
    this.id = 0,
    required this.forename,
    required this.surname,
    required this.email,
    required this.phone,
    required this.password,
    this.imageUrl = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final forename = json['forename'];
    final surname = json['surname'];
    final email = json['email'];
    final phone = json['phone'];
    final password = json['password'];
    return User(
        id: id,
        forename: forename,
        surname: surname,
        email: email,
        phone: phone,
        password: password,
        imageUrl: json['imageUrl']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'forename': forename,
      'surname': surname,
      'email': email,
      'phone': phone,
      'password': password,
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
  int driveId = 0;
  String roadFrom = '';
  String roadTo = '';
  int exit = 0;
  int bearingBefore = 0;
  int bearingAfter = 0;
  LatLng location = const LatLng(0, 0);
  String modifier = '';
  String type = '';
  double distance = 0.0;
  Maneuver({
    this.id = 0,
    this.driveId = 0,
    required this.roadFrom,
    required this.roadTo,
    required this.exit,
    required this.bearingBefore,
    required this.bearingAfter,
    required this.location,
    required this.modifier,
    required this.type,
    required this.distance,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drive_id': driveId,
      'road_from': roadFrom,
      'road_to': roadTo,
      'exit': exit,
      'bearing_before': bearingBefore,
      'bearing_after': bearingAfter,
      'location': '{"lat":${location.latitude},"long":${location.longitude}}',
      'modifier': modifier,
      'type': type,
      'distance': distance,
    };
  }

  /// ...['steps'][n]['name'] => the current road name
  /// ...['steps'][n]['maneuver'][bearing_before'] => approach bearing
  /// ...['steps'][n]['maneuver'][bearing_after] => exit bearing
  /// ...['steps'][n]['maneuver']['location'] => latLng of intersection
  /// ...['steps'][n]['maneuver']['modifier'] => 'right', 'left' etc
  /// ...['steps'][n]['maneuver']['type'] => 'turn' etc
  /// ...['steps'][n]['maneuver']['name'] => 'Alexandra Road'
}

/// class Follower

class Follower extends Marker {
  int id = 0;
  int driveId = 0;
  String forename = '';
  String surname = '';
  String phoneNumber = '';
  String car = '';
  String registration = '';
  int iconColour = 0;
  LatLng position = const LatLng(0, 0);
  DateTime reported = DateTime.now();
  int index = -1;
  double width;
  double height;
  Follower(
      {this.id = 0,
      this.driveId = 0,
      this.forename = '',
      this.surname = '',
      this.phoneNumber = '',
      this.car = '',
      this.registration = '',
      this.width = 20,
      this.height = 20,
      this.iconColour = 0,
      required position,
      required Widget marker})
      : super(
          child: marker,
          point: position, // markerPoint,
          width: width,
          height: height, /*key: key*/
        ) {
    reported = DateTime.now();
  }

/**
 *       {required LatLng markerPoint,
      required Widget marker

      /*required this.xchild*/
      })
      : super(
          child: marker,
          point: markerPoint,
          width: width,
          height: height, /*key: key*/
        );
 */

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drive_id': driveId,
      'forename': forename,
      'surname': surname,
      'phone_number': phoneNumber,
      'car': car,
      'registration': registration,
      'icon_colour': iconColour,
      'position':
          '{"lat": ${position.latitude}, "long": ${position.longitude}}',
      'reported': reported.toString()
    };
  }
}

/// class HomeItem

class HomeItem {
  int id = 0;
  String heading = '';
  String subHeading = '';
  String body = '';
  String imageUrl = '';
  int score = 5;
  HomeItem({
    this.id = 0,
    required this.heading,
    this.subHeading = '',
    this.body = '',
    this.imageUrl = '',
    this.score = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'heading': heading,
      'subHeading': subHeading,
      'body': body,
      'imageUrl': imageUrl,
      'score': score,
    };
  }
}

/// class TripItem

class TripItem {
  int id = 0;
  String heading = '';
  String subHeading = '';
  String body = '';
  String author = '';
  String authorUrl = '';
  String published = '';
  List<String> imageUrls = [];
  double score = 5;
  double distance = 0;
  int pointsOfInterest = 0;
  int closest = 12;
  int scored = 10;
  int downloads = 18;
  TripItem({
    this.id = 0,
    required this.heading,
    this.subHeading = '',
    this.body = '',
    this.author = '',
    this.authorUrl = '',
    this.published = '',
    this.imageUrls = const [],
    this.score = 5,
    this.distance = 0,
    this.pointsOfInterest = 0,
    this.closest = 12,
    this.scored = 10,
    this.downloads = 18,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'heading': heading,
      'subHeading': subHeading,
      'body': body,
      'author': author,
      'authorUrl': authorUrl,
      'published': published,
      'imageUrls': imageUrls,
      'score': score,
      'distance': distance,
      'pointsOfInterest': pointsOfInterest,
      'closest': closest,
      'scored': scored,
      'downloads': downloads,
    };
  }
}

/// class MyTripItem
/// covers both points of interest and waypoints

class MyTripItem {
  int id = 0;
  int driveId = 0;
  String heading = '';
  String subHeading = '';
  String body = '';
  String published = '';
  List<PointOfInterest> pointsOfInterest = [];
  List<mt.Route> routes = [];
  String images = '';
  double score = 5;
  double distance = 0;
  int closest = 12;
  int highlights = 0;
  bool showMethods = true;

  MyTripItem({
    this.id = 0,
    this.driveId = 0,
    required this.heading,
    this.subHeading = '',
    this.body = '',
    this.published = '',
    this.pointsOfInterest = const [],
    this.routes = const [],
    this.images = '',
    this.score = 5,
    this.distance = 0,
    this.closest = 12,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'heading': heading,
      'subHeading': subHeading,
      'body': body,
      'published': published,
      'pointsOfInterest': pointsOfInterest,
      'images': images,
      'score': score,
      'distance': distance,
      'closest': closest,
    };
  }

  Future<int> saveLocally() async {
    return -1;
  }

  Future<bool> publish() async {
    return false;
  }
}

/*

SELECT * FROM drives 
JOIN points_of_interest ON drives.id = points_of_interest.drive_id 

QueryResultSet ([{id: 1, user_id: -1, title: Trip Name, sub_title: Trip summary , body: Trip details, 
images: , max_lat: 0.0, min_lat: 0.0, max_long: 0.0, min_long: 0.0, added: 2024-05-18 22:57:56.570120, 
drive_id: 0, type: 12, name: Albany Road, description: 0 miles - (0 minutes), latitude: 52.05884, longitude: -1.345583}, 

{id: 2, user_id: -1, title: Trip Name, sub_title: Trip summary , body: Trip details, 
images: , max_lat: 0.0, min_lat: 0.0, max_long: 0.0, min_long: 0.0, added: 2024-05-18 22:57:56.570120, 
drive_id: 0, type: 12, name: Church Street, description: 6.1 miles - (13 minutes), latitude: 52.05884, longitude: -1.345583}, 

{id: 3, user_id: -1, title: Trip Name, sub_title: Trip summary , body: Trip details, 
images: , max_lat: 0.0, min_lat: 0.0, max_long: 0.0, min_long: 0.0, added: 2024-05-18 22:57:56.570120, 
drive_id: 0, type: 15, name: Point of Interest name, description: Point of Interest description , latitude: 52.05884, longitude: -1.345583}])

*/

Future<List<MyTripItem>> tripItemFromDb({int driveId = -1}) async {
  final db = await dbHelper().db;
  // int records = await recordCount('setup');
  // if (records > 0){
  /*
  const String drivesQuery = '''
      SELECT * FROM drives 
      JOIN points_of_interest ON drives.id = points_of_interest.drive_id 
      JOIN polylines ON drives.id = polylines.drive_id
      ''';
   */
  LatLng pos = const LatLng(0, 0);

  await getPosition().then((currentPosition) {
    pos = LatLng(currentPosition.latitude, currentPosition.longitude);
  });
  String drivesQuery =
      '''SELECT drives.title, drives.sub_title, drives.body, drives.map_image, drives.distance, drives.points_of_interest,
    points_of_interest.*  
    FROM drives
    JOIN points_of_interest 
    ON drives.id = points_of_interest.drive_id''';
  if (driveId > -1) {
    drivesQuery = '$drivesQuery WHERE drives.id = $driveId';
  }

  List<MyTripItem> trips = [];
  try {
    List<Map<String, dynamic>> maps = await db.rawQuery(drivesQuery);
    int driveId = -1;
    int highlights = 0;
    String tripImages = '';

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['drive_id'] != driveId) {
        if (trips.isNotEmpty) {
          trips[trips.length - 1].closest = closestWaypoint(
                  pointsOfInterest: trips[trips.length - 1].pointsOfInterest,
                  location: pos)
              .toInt();
          if (tripImages.isNotEmpty) {
            trips[trips.length - 1].images = '[$tripImages]';
          }
          trips[trips.length - 1].highlights = highlights;
        }
        driveId = maps[i]['drive_id'];
        tripImages = unList(maps[i]['map_image']);
        trips.add(MyTripItem(
            driveId: driveId,
            heading: maps[i]['title'],
            subHeading: maps[i]['sub_title'],
            body: maps[i]['body'],
            images: maps[i]['map_image'],
            distance: double.parse(maps[i]['distance'].toString()),
            pointsOfInterest: [
              PointOfInterest(
                  maps[i]['id'],
                  maps[i]['user_id'],
                  driveId,
                  maps[i]['type'],
                  maps[i]['name'],
                  maps[i]['description'],
                  maps[i]['type'] == 12 ? 10 : 30,
                  maps[i]['type'] == 12 ? 10 : 30,
                  maps[i]['images'],
                  markerPoint:
                      LatLng(maps[i]['latitude'], maps[i]['longitude']),
                  marker: MarkerWidget(type: maps[i]['type']))
            ],
            closest: 15));
        if (maps[i]['type'] != 12) highlights++;
      } else {
        trips[trips.length - 1].pointsOfInterest.add(PointOfInterest(
            maps[i]['id'],
            maps[i]['user_id'],
            driveId,
            maps[i]['type'],
            maps[i]['name'],
            maps[i]['description'],
            maps[i]['type'] == 12 ? 10 : 30,
            maps[i]['type'] == 12 ? 10 : 30,
            maps[i]['images'],
            markerPoint: LatLng(maps[i]['latitude'], maps[i]['longitude']),
            marker: MarkerWidget(type: maps[i]['type'])));
        if (maps[i]['type'] != 12) highlights++;
      }
      if (maps[i]['images'].isNotEmpty) {
        tripImages =
            '${tripImages.isNotEmpty ? '$tripImages,' : ''}${unList(maps[i]['images'])}';
      }
    } //
    if (trips.isNotEmpty) {
      trips[trips.length - 1].closest = closestWaypoint(
              pointsOfInterest: trips[trips.length - 1].pointsOfInterest,
              location: pos)
          .toInt();
      if (tripImages.isNotEmpty) {
        trips[trips.length - 1].images = '[$tripImages]';
      }
      trips[trips.length - 1].highlights = highlights;
    }
    // for maps;
  } catch (e) {
    String err = e.toString();
    debugPrint('Error loading Drive $err');
  }
  return trips;
}

/// class User
/// "DatabaseException(ambiguous column name: id (code 1 SQLITE_ERROR): , while compiling: SELECT id as drive_id, title, sub_title, b…"

class Drive {
  int id = 0;
  int userId = 0;
  String title;
  String subTitle;
  String body;
  DateTime added = DateTime.now();
  double distance = 0;
  int pois = 0;
  String images = ''; // To s
  List<PointOfInterest> pointsOfInterest = [];
  List<Polyline> polyLines = [];

/* 
            '''CREATE TABLE drives(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, title TEXT, sub_title TEXT, body TEXT, 
          images TEXT, max_lat REAL, min_lat REAL, max_long REAL, min_long REAL, added DATETIME)''');
*/

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
      id = await saveDrive(drive: this);
    } catch (e) {
      debugPrint('Error saving trip: ${e.toString()}');
    }
    try {
      //   await savePointsOfInterestLocal(pointsOfInterest);
    } catch (e) {
      debugPrint('Error savePointsOfInterest: ${e.toString()}');
    }

    try {
      await savePolylinesLocal(id: 0, driveId: id, polylines: polyLines);
    } catch (e) {
      debugPrint('Error in savePolyLinesLocal: ${e.toString()}');
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

class Message {
  int id = -1;
  GroupMember groupMember;
  String message = '';
  bool read = false;
  bool selected = false;
  int targetId = 0;
  DateTime received = DateTime.now();
  int index = 0;
  Message(
      {required this.id,
      required this.groupMember,
      required this.message,
      this.read = false,
      this.selected = false}) {
    received = DateTime.now();
  }
/*
            '''CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, target_id INTEGER, message TEXT, 
        read INTEGER, received DATETIME)''');
*/

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

Future<List<Message>> messagesFromDb({int driveId = -1}) async {
  final db = await dbHelper().db;
  // int records = await recordCount('setup');
  // if (records > 0){
  /*
  const String drivesQuery = '''
      SELECT * FROM drives 
      JOIN points_of_interest ON drives.id = points_of_interest.drive_id 
      JOIN polylines ON drives.id = polylines.drive_id

      TABLE group_members(id INTEGER PRIMARY KEY AUTOINCREMENT, group_ids STRING, forename TEXT, surname TEXT, 
            email TEXT, phone TEXT, status Integer, joined DATETIME, note TEXT, uri TEXT)'''); 
      ''';messages(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, target_id INTEGER, message TEXT, 
        read INTEGER, received DATETIME)''');

   */

  String messagesQuery =
      '''SELECT group_members.forename, group_members.surname, group_members.group_ids, group_members.id, 
      group_members.phone, group_members.email,  messages.*  
    FROM group_members
    JOIN messages 
    ON group_members.id = messages.user_id''';

  List<Message> messages = [];
  try {
    List<Map<String, dynamic>> maps = await db.rawQuery(messagesQuery);
    int memberId = -1;

    for (int i = 0; i < maps.length; i++) {
      try {
        memberId = maps[i]['user_id'];
        messages.add(Message(
          id: maps[i]['id'],
          groupMember: GroupMember(
              forename: maps[i]['forename'],
              surname: maps[i]['surname'],
              groupIds: maps[i]['group_ids'],
              email: maps[i]['email'],
              phone: maps[i]['phone']),
          message: maps[i]['message'],
          read: maps[i]['read'] == 1,
        ));

        // for maps;
      } catch (e) {
        String err = e.toString();
        debugPrint('Error loading User $err');
      }
    }
  } catch (e) {
    debugPrint('Error: loading Message ${e.toString()}');
  }
// E/SQLiteLog( 3905): (1) near ".": syntax error in "SELECT group_members.forename, group_members.surname, group_members.group_ids, group_members.id,

  return messages;
}

class PopupValue {
  int dropdownIdx = -1;
  String text1 = '';
  String text2 = '';
  PopupValue(this.dropdownIdx, this.text1, this.text2);
}

class SearchHelper {
  int poiIndex = -1;
  //List<Polyline> = [];
}

class GoodRoad {
  bool _isGood = false;
  int routeIdx1 = -1;
  int routeIdx2 = -1;
  int pointIdx1 = -1;
  int pointIdx2 = -1;
  int markerIdx = -1;
  GoodRoad();
  bool get isGood => _isGood;
  set isGood(bool value) {
    _isGood = value;
    routeIdx1 = -1;
    routeIdx2 = -1;
    pointIdx1 = -1;
    pointIdx2 = -1;
    markerIdx = -1;
  }
}

class Drive1 {
  int id;
  int userId;
  String name;
  String description;
  DateTime published;
  double startLong;
  double startLat;
  Drive1(this.id, this.userId, this.name, this.description, this.published,
      this.startLong, this.startLat);
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'published': published,
      'startLong': startLong,
      'startLat': startLat,
    };
  }
}
