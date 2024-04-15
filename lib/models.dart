// import 'package:flutter/cupertino.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// https://api.flutter.dev/flutter/material/Icons-class.html  get the icon codepoint from here
/// https://api.flutter.dev/flutter/material/Icons/add_road-constant.html

enum UserMode {
  home,
  routes,
  explore,
  profile,
  shop,
}

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

const List<LatLng> testRoutePoints = [
  LatLng(51.478815, -0.611477),
  LatLng(51.478807, -0.611422),
  LatLng(51.478666, -0.610359),
  LatLng(51.478452, -0.61045),
  LatLng(51.478211, -0.610624),
  LatLng(51.478062, -0.610679),
  LatLng(51.477608, -0.610845),
  LatLng(51.477433, -0.610909),
  LatLng(51.477404, -0.610923),
  LatLng(51.477401, -0.610994),
  LatLng(51.477374, -0.610999),
  LatLng(51.47694, -0.611088),
  LatLng(51.476818, -0.611093),
  LatLng(51.47639, -0.611103),
  LatLng(51.47559, -0.611387),
  LatLng(51.475477, -0.611411),
  LatLng(51.475419, -0.611412),
  LatLng(51.475366, -0.611403),
  LatLng(51.475326, -0.611377),
  LatLng(51.475259, -0.611294),
  LatLng(51.475183, -0.611506),
  LatLng(51.475099, -0.611732),
  LatLng(51.475046, -0.61181),
  LatLng(51.474999, -0.611918),
  LatLng(51.474974, -0.611974),
  LatLng(51.474949, -0.612013),
  LatLng(51.474884, -0.612078),
  LatLng(51.474856, -0.612042),
  LatLng(51.474835, -0.612008),
  LatLng(51.474803, -0.611945),
  LatLng(51.474764, -0.611855),
  LatLng(51.474752, -0.611809),
  LatLng(51.474612, -0.611318),
  LatLng(51.474348, -0.610374),
  LatLng(51.474229, -0.609968),
  LatLng(51.474133, -0.609666),
  LatLng(51.4739, -0.609047),
  LatLng(51.473705, -0.608537),
  LatLng(51.47354, -0.608201),
  LatLng(51.47333, -0.607775),
  LatLng(51.47306, -0.607282),
  LatLng(51.472955, -0.606992),
  LatLng(51.472917, -0.606805),
  LatLng(51.472904, -0.606586)
];

void myFunc() {}

class WayPoint {
  int id;
  int userId;
  int driveId;
  int type;
  String description;
  String hint;
  LatLng markerPoint;
  WayPoint(
      {required this.id,
      required this.userId,
      required this.driveId,
      required this.type,
      required this.description,
      required this.hint,
      required this.markerPoint});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'useId': userId,
      'driveId': driveId,
      'type': type,
      'description': description,
      'hint': hint,
      'latitude': markerPoint.latitude,
      'longitude': markerPoint.longitude,
    };
  }
}

class PointOfInterest extends Marker {
  int id;
  List<String> imageURIs;
  int userId;
  int driveId;
  int type;
  String description;
  String hint;

  LatLng markerPoint = const LatLng(52.05884, -1.345583);

  WidgetBuilder markerBuilder = (ctx) => RawMaterialButton(
        onPressed: () => myFunc(),
        elevation: 1.0,
        fillColor: Colors.amber,
        padding: const EdgeInsets.all(2.0),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.pin_drop,
          size: 50,
          color: Colors.blueAccent,
        ),
      );

  PointOfInterest(
      BuildContext ctx,
      this.id,
      this.userId,
      this.driveId,
      this.type,
      this.description,
      this.hint,
      double width,
      double height,
      this.imageURIs,
      {required LatLng markerPoint})
      : super(
          child: RawMaterialButton(
              onPressed: () => Utility().showAlertDialog(
                  ctx, poiTypes.toList()[type]['name'], description),
              elevation: 2.0,
              fillColor: const Color.fromARGB(255, 224, 132, 10),
              // padding: const EdgeInsets.all(5.0),
              shape: const CircleBorder(),
              child: Icon(
                markerIcon(type),
                size: type > 12 ? 10 : width * 0.75,
                color: Colors.blueAccent,
              )),
          point: markerPoint,
//            draggable: true,fl
          width: width,
          height: height,
        );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'useId': userId,
      'driveId': driveId,
      'type': type,
      'description': description,
      'hint': hint,
      'latitude': markerPoint.latitude,
      'longitude': markerPoint.longitude,
    };
  }

  /// The : super keyword means we are referring to base class - Marker - parameters
  /// The point and builder are both required
}

IconData markerIcon(int type) {
  return IconData(poiTypes.toList()[type]['iconMaterial'],
      fontFamily: 'MaterialIcons');
}

/*
class User {
  int id;
  String forename;
  String surname;
  String email;
  User(this.id, this.forename, this.surname, this.email);
}
*/

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

class MyTripItem {
  int id = 0;
  String heading = '';
  String subHeading = '';
  String body = '';
  String published = '';
  List<PointOfInterest> pointsOfInterest = [];
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
      'score': score,
      'distance': distance,
      'closest': closest,
    };
  }
}

/// class User

class Drive {
  int id = 0;
  int userId = 0;
  String name;
  String description;
  DateTime date = DateTime.now();
  double maxLat = 0;
  double minLat = 0;
  double maxLong = 0;
  double minLong = 0;

  Drive({
    this.id = 0,
    required this.userId,
    required this.name,
    required this.description,
    required this.date,
    this.maxLat = 0,
    this.minLat = 0,
    this.maxLong = 0,
    this.minLong = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'date': date,
      'maxLat': maxLat,
      'minLat': minLat,
      'maxLong': maxLong,
      'minLong': minLong,
    };
  }
}

class PopupValue {
  int dropdownIdx = -1;
  String text1 = '';
  String text2 = '';
  PopupValue(this.dropdownIdx, this.text1, this.text2);
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
/*
class Trip {
  int id;
  int driveId;
  List<User> users;
  Trip(this.id, this.driveId, this.users);
}
*/
