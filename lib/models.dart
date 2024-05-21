// import 'package:flutter/cupertino.dart';
import 'dart:convert';

import 'package:drives/screens/dialogs.dart';
import 'package:drives/screens/painters.dart';
import 'package:drives/services/db_helper.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

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

  String jwt = '';
  User user = User(id: 0, forename: '', surname: '', password: '', email: '');
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
  int id;
  int userId;
  int driveId;
  int type;
  String description;
  late BuildContext ctx;
  late MarkerWidget marker;
  late LatLng markerPoint;

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
          /*         child: RawMaterialButton(
              onPressed: () => Utility().showAlertDialog(
                  ctx, poiTypes.toList()[type]['name'], description),
              elevation: 2.0,
              fillColor: width < 30
                  ? uiColours.keys.toList()[Setup().waypointColour]
                  : uiColours.keys.toList()[Setup().pointOfInterestColour],
              // padding: const EdgeInsets.all(5.0),
              shape: const CircleBorder(),
              child: Icon(
                // iconData, //
                markerIcon(type),
                size: width < 30 ? 10 : width * 0.75,
                color: Colors.blueAccent,
              )),
*/
          point: markerPoint,
//            draggable: true,fl
          width: width,
          height: height, /*key: key*/
        );

  IconData setIcon({required type}) {
    return markerIcon(type);
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

class MarkerWidget extends StatelessWidget {
  set iconType(int poiType) {
    // setState(() {
    type = poiType;
    // });
    // _context = context;
  }

  int type = 12; // default type 12 => waypoint
  String description;
  MarkerWidget({super.key, required this.type, this.description = ''});

  @override
  Widget build(BuildContext context) {
    int width = type == 12 ? 10 : 30;
    return RawMaterialButton(
        onPressed: () => Utility().showAlertDialog(
            context, poiTypes.toList()[type]['name'], description),
        elevation: 2.0,
        fillColor: width < 30
            ? uiColours.keys.toList()[Setup().waypointColour]
            : uiColours.keys.toList()[Setup().pointOfInterestColour],
        // padding: const EdgeInsets.all(5.0),
        shape: const CircleBorder(),
        child: Icon(
          // iconData, //
          markerIcon(type),
          size: width < 30 ? 10 : width * 0.75,
          color: Colors.blueAccent,
        ));
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

  // MapLabelPainter(text: 'Test Label', pixe

  //);
}

IconData markerIcon(int type) {
  return IconData(poiTypes.toList()[type]['iconMaterial'],
      fontFamily: 'MaterialIcons');
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
  String email;
  String imageUrl;

  User({
    this.id = 0,
    required this.forename,
    required this.surname,
    required this.email,
    required this.password,
    this.imageUrl = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final forename = json['forename'];
    final surname = json['surname'];
    final email = json['email'];
    final password = json['password'];
    return User(
        id: id,
        forename: forename,
        surname: surname,
        email: email,
        password: password,
        imageUrl: json['imageUrl']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'forename': forename,
      'surname': surname,
      'email': email,
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
  int distance = 10;
  int pointsOfInterest = 3;
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
    this.distance = 10,
    this.pointsOfInterest = 3,
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
      'scrored': scored,
      'downloads': downloads,
    };
  }
}

/// class MyTripItem
/// covers both points of interest and waypoints

class MyTripItem {
  int id = 0;
  String heading = '';
  String subHeading = '';
  String body = '';
  String published = '';
  List<PointOfInterest> pointsOfInterest = [];
  String images = '';
  double score = 5;
  int distance = 10;
  int closest = 12;
  MyTripItem({
    this.id = 0,
    required this.heading,
    this.subHeading = '',
    this.body = '',
    this.published = '',
    this.pointsOfInterest = const [],
    this.images = '',
    this.score = 5,
    this.distance = 10,
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

Future<List<MyTripItem>> tripItemFromDb() async {
  final db = await dbHelper().db;
  // int records = await recordCount('setup');
  // if (records > 0){
  /*
  const String drivesQuery = '''
      SELECT * FROM drives 
      JOIN points_of_interest ON drives.id = points_of_interest.drive_id 
      JOIN polylines ON drives.id = polylines.drive_id
      ''';
   db.rawQuery(drivesQuery); 
  */
  const String drivesQuery = '''
    SELECT * FROM drives 
    JOIN points_of_interest ON drives.id = points_of_interest.drive_id 
    ''';

  List<MyTripItem> trips = [];
  try {
    List<Map<String, dynamic>> maps = await db.rawQuery(drivesQuery);
    // List<Map<String, dynamic>> maps = await db.query('drives');

    int driveId = -1;

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['drive_id'] != driveId) {
        driveId = maps[i]['drive_id'];
        trips.add(MyTripItem(
            heading: maps[i]['title'],
            subHeading: maps[i]['sub_title'],
            body: maps[i]['body'],
            images: maps[i]['images'],
            pointsOfInterest: [
              PointOfInterest(
                  // context,
                  -1,
                  maps[i]['user_id'],
                  driveId,
                  maps[i]['type'],
                  maps[i]['name'],
                  maps[i]['description'],
                  30,
                  30,
                  'images',
                  // iconData,
                  markerPoint:
                      LatLng(maps[i]['latitude'], maps[i]['longitude']),
                  marker: MarkerWidget(type: maps[i]['type']))
            ],
            distance: 10,
            closest: 15));
      } else {
        trips[trips.length - 1].pointsOfInterest.add(PointOfInterest(
            // context,
            -1,
            maps[i]['user_id'],
            driveId,
            maps[i]['type'],
            maps[i]['name'],
            maps[i]['description'],
            30,
            30,
            'images',
            // iconData,
            markerPoint: LatLng(maps[i]['latitude'], maps[i]['longitude']),
            marker: MarkerWidget(type: maps[i]['type'])));
      }
    }

    // for maps;
  } catch (e) {
    debugPrint('Error loading Setup ${e.toString()}');
  }

  return trips;
  // }
  // throw ('Error ');
}

/// class User
///

class Drive {
  int id = 0;
  int userId = 0;
  String title;
  String subTitle;
  String body;
  DateTime added = DateTime.now();
  double maxLat = 0;
  double minLat = 0;
  double maxLong = 0;
  double minLong = 0;
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
    // this.images,
    this.maxLat = 0,
    this.minLat = 0,
    this.maxLong = 0,
    this.minLong = 0,
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
      await savePolylinesLocal(
          id: 0, userId: userId, driveId: id, polylines: polyLines);
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
      'images': images,
      'max_lat': maxLat,
      'min_lat': minLat,
      'max_long': maxLong,
      'min_long': minLong,
    };
  }

  Future<bool> getDetailsLocal() async {
    return true;
  }

  Future<bool> getDetailsApi() async {
    return true;
  }
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
