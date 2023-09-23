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
  }
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
