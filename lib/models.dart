// import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// https://api.flutter.dev/flutter/material/Icons-class.  get the icon codepoint from here
///
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
    'name': 'Great road',
    'icon': 'Icons.add_road',
    'iconMaterial': 0xe059,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 4,
    'name': 'Historic building',
    'icon': 'Icons.castle',
    'iconMaterial': 0xf02e5,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 5,
    'name': 'Monument',
    'icon': 'Icons.account_balance',
    'iconMaterial': 0xe040,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 6,
    'name': 'Museum',
    'icon': 'Icons.museum',
    'iconMaterial': 0xe414,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 7,
    'name': 'Park',
    'icon': 'Icons.park',
    'iconMaterial': 0xe478,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 8,
    'name': 'Parking',
    'icon': 'Icons.local_parking',
    'iconMaterial': 0xe39d,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 9,
    'name': 'Other',
    'icon': 'Icons.pin_drop',
    'iconMaterial': 0xe4c7,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 10,
    'name': 'Start',
    'icon': 'Icons.assistant_navigation',
    'iconMaterial': 0xe0ad,
    'colour': 'Colors.blue',
    'colourMaterial': 0xff4CAF50
  },
  {
    'id': 11,
    'name': 'End',
    'icon': 'Icons.assistant_photo_outlined',
    'iconMaterial': 0xee9e,
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
  }
];

List<LatLng> testRoutePoints = [
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

class PointOfInterest extends Marker {
  int id;

  int userId;
  int driveId;
  int type;
  String description;
  LatLng markerPoint = LatLng(52.05884, -1.345583);
  /*
  WidgetBuilder markerBuilder = (ctx) => const Icon(
        Icons.pin_drop,
        size: 50,
        color: Colors.blueAccent,
      );
*/
  WidgetBuilder markerBuilder = (ctx) => RawMaterialButton(
        onPressed: () =>
            myFunc(), // Utility() .showAlertDialog(ctx, 'Hello', 'you'), // myFunc<void>(ctx),
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

  PointOfInterest(this.id, this.userId, this.driveId, this.type,
      this.description, double width, double height,
      {required LatLng markerPoint, required WidgetBuilder markerBuilder})
      : super(
            point: markerPoint,
            width: width,
            height: height,
            builder: markerBuilder);

/*
                              RawMaterialButton(
                                onPressed: () {},
                                elevation: 2.0,
                                fillColor: Colors.white,

                                padding: EdgeInsets.all(15.0),
                                shape: CircleBorder(),
                                child: Icon(
                                  IconData(item['iconMaterial'],
                                      fontFamily: 'MaterialIcons'),
                                  color: Color(item['colourMaterial']),
                                  size: 35.0,
                                ),
                              )
 */

  /// The : super keyword means we are referring to base class - Marker - parameters
  /// The point and builder are both required
  ///
  ///
  ///
  ///
  ///
}

class User {
  int id;
  String forename;
  String surname;
  String email;
  User(this.id, this.forename, this.surname, this.email);
}

class PopupValue {
  int dropdownIdx = -1;
  String text1 = '';
  String text2 = '';
  PopupValue(this.dropdownIdx, this.text1, this.text2);
}

class Drive {
  int id;
  int userId;
  String name;
  String description;
  DateTime dateEntered;
  Drive(this.id, this.userId, this.name, this.description, this.dateEntered);
}

class Trip {
  int id;
  int driveId;
  List<User> users;
  Trip(this.id, this.driveId, this.users);
}
