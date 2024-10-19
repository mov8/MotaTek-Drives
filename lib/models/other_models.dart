// import 'package:flutter/cupertino.dart';
import 'dart:convert';
//import 'dart:ffi';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
// import 'package:drives/services/services.dart';
import 'package:intl/intl.dart';
import 'package:drives/classes/utilities.dart';
import 'package:drives/screens/screens.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/tiles/tiles.dart';
//import 'package:drives/screens/dialogs.dart';
//import 'package:drives/screens/painters.dart';
import 'package:drives/services/db_helper.dart';
import 'package:drives/services/web_helper.dart' as wh;
import 'package:drives/models/my_trip_item.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

// import 'package:geolocator/geolocator.dart';

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
  int routeColour = 12;
  int goodRouteColour = 3;
  int waypointColour = 2;
  int pointOfInterestColour = 8;
  int waypointColour2 = 14;
  int pointOfInterestColour2 = 14;
  int selectedColour = 7;
  int highlightedColour = 13;
  int recordDetail = 5;
  bool allowNotifications = true;
  bool dark = false;
  bool rotateMap = false;
  bool avoidMotorways = false;
  bool avoidAroads = false;
  bool avoidBroads = false;
  bool avoidTollRoads = false;
  bool avoidFerries = false;

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
        jwt = maps[0]['jwt'];
        dark = maps[0]['dark'] == 1;
        rotateMap = maps[0]['rotate_map'] == 1;
        avoidMotorways = maps[0]['avoid_motorways'] == 1;
        avoidAroads = maps[0]['avoid_a_roads'] == 1;
        avoidBroads = maps[0]['avoid_b_roads'] == 1;
        avoidTollRoads = maps[0]['avoid_toll_roads'] == 1;
        avoidFerries = maps[0]['avoid_ferries'] == 1;
      } catch (e) {
        debugPrint('Failed to load Setup() from db: ${e.toString()}');
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
      'jwt': jwt,
      'allow_notifications': allowNotifications ? 1 : 0,
      'dark': dark ? 1 : 0,
      'rotate_map': rotateMap ? 1 : 0,
      'avoid_motorways': avoidMotorways ? 1 : 0,
      'avoid_a_roads': avoidAroads ? 1 : 0,
      'avoid_b_roads': avoidBroads ? 1 : 0,
      'avoid_toll_roads': avoidTollRoads ? 1 : 0,
      'avoid_ferries': avoidFerries ? 1 : 0,
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
  final int id;
  String _images;
  final int driveId;
  int _type;
  String _name;
  String _description;
  String url;
  double _score;
  int scored;
  late final Widget marker;
  late LatLng markerPoint = const LatLng(52.05884, -1.345583);

  PointOfInterest(
      //  this.ctx,
      this.id,
      this.driveId,
      int type,
      String name,
      String description,
      double width,
      double height,
      {String images = '',
      required LatLng markerPoint,
      required Widget marker,
      this.url = '',
      double score = 1,
      this.scored = 0})
      : _images = images,
        _type = type,
        _name = name,
        _description = description,
        _score = score,
        super(
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

  void setImages(String images) {
    _images = images;
  }

  String getImages() {
    return _images;
  }

  void setType(int type) {
    _type = type;
  }

  int getType() {
    return _type;
  }

  String getName() {
    return _name;
  }

  void setName(String name) {
    _name = name;
  }

  String getDescription() {
    return _description;
  }

  void setDescription(String description) {
    _description = description;
  }

  void setScore(double score) {
    _score = score;
  }

  double getScore() {
    return _score;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driveId': driveId,
      'type': _type,
      'name': _name,
      'description': _description,
      'latitude': point.latitude, //markerPoint.latitude,
      'longitude': point.longitude, //markerPoint.longitude,
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
  final int type; // default type 12 => waypoint
  String name;
  String description;
  String images;
  String url;
  List<String> imageUrls;
  final double angle;
  double score;
  int scored;
  final int colourIdx;
  int list;
  int listIndex;

  MarkerWidget(
      {super.key,
      required this.type,
      this.name = '',
      this.description = '',
      this.images = '',
      this.url = ' ',
      this.imageUrls = const [],
      this.angle = 0,
      this.score = 0,
      this.scored = 0,
      this.colourIdx = -1,
      this.list = -1,
      this.listIndex = -1});

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
        onPressed: () {
          //   if (list == -1) {
          //     Utility().showAlertDialog(
          //         context, poiTypes.toList()[type]['name'], description);
          //   } else if (pointOfInterest != null) {
          pointOfInterestDialog(context, name, description, images, url,
              imageUrls, score, scored, type);
          //   }
        },
        elevation: 2.0,
        fillColor: buttonFillColor,
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 1, 2),
          child: Icon(
            markerIcon(type),
            size: iconWidth,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

pointOfInterestDialog(
    BuildContext context,
    String name,
    String description,
    String images,
    String url,
    List<String> imageUrls,
    double score,
    int scored,
    int type) async {
  // bool result = false;
  // set up the buttons
  Widget okButton = TextButton(
    child: const Text("Ok"),
    onPressed: () {
      Navigator.pop(context, true);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(
      name,
      style: const TextStyle(fontSize: 20),
      textAlign: TextAlign.center,
    ),
    // scrollable: true,
    elevation: 5,
    content: // SingleChildScrollView(
        //child:
        MarkerTile(
      index: -1,
      name: name,
      description: description,
      images: images,
      url: url,
      imageUrls: imageUrls,
      type: type,
      score: score,
      scored: scored,
      //  onIconTap: () => {},
      //  onExpandChange: () => {},
      //  onDelete: () => {},
      onRated: () => {},
      canEdit: false,
      expanded: false,
    ),

    //     child: ListBody(
    //       children: <Widget>[Text(alertMessage)],
    // ),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      // result = alert;

      return alert;
    },
  );
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
        name: map['name'],
        description: map['description'],
        members: <GroupMember>[
          for (Map<String, dynamic> memberMap in map['members'])
            GroupMember.fromMap(memberMap)
        ],
        created: DateTime.parse(map['created']),
        userId: map['user_id'],
        id: map['id']);
  }

  factory Group.fromGroupSummaryMap(var map) {
    return Group(
      id: map['group_id'],
      name: map['group_name'],
      created: DateTime.parse(map['created']),
      memberCount: int.parse(map['members']),
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
  }

  void removeMember(int index) {
    _members.removeAt(index);
  }

  List<GroupMember> groupMembers() {
    return _members;
  }

  void setGroupMembers(List<GroupMember> members) {
    _members = members;
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

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'],
      userId: map['member'],
      groupId: map['groups'],
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
      phone: map['member_phone'],
      selected: true,
    );
  }

// Getter for edited have to use this because ints are passed by value not by reference
  bool get edited => isEdited == 'true';
// Setter for edited
  set edited(bool value) => isEdited = value ? 'true' : 'false';

  Map<String, dynamic> toMap() {
    return {'user_id': userId, 'group_id': groupId};
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

class EventInvitation {
  String driveId;
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
      name: map['event_name'],
      eventDate: DateTime.parse(map['event_date']),
      forename: map['inviter_forename'],
      surname: map['inviter_surname'],
      email: map['inviter_email'],
      id: map['invitation_id'],
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
      id: map['invitation_id'],
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
      id: map['invitation_id'],
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
  if (photoString.isNotEmpty) {
    try {
      photos = (json.decode(photoString) as List<dynamic>)
          .map((jsonObject) => Photo.fromJson(jsonObject))
          .toList();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error converting image data: $err ($photoString)');
    }
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
  String newPassword = '';
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
  String uri = '';
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
    this.uri = '',
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
///
/// class StudentsList extends StatefulWidget {

class MyTripItem2 {
  int _id = -1;
  int _driveId = -1;
  int _index = -1;
  String _driveUri = '';
  String _heading = '';
  String _subHeading = '';
  String _body = '';
  String _published = '';
  List<PointOfInterest> _pointsOfInterest = [];
  List<Maneuver> _maneuvers = [];
  List<mt.Route> _routes = [];
  String _images = '';
  double _score = 5;
  double _distance = 0;
  int _closest = 12;
  int highlights = 0;
  bool showMethods = true;
  late ui.Image _mapImage;

  MyTripItem2({
    int id = -1,
    int driveId = -1,
    String driveUri = '',
    required String heading,
    String subHeading = '',
    String body = '',
    String published = '',
    List<PointOfInterest> pointsOfInterest = const [],
    List<Maneuver> maneuvers = const [],
    List<mt.Route> routes = const [],
    String images = '',
    double score = 5,
    double distance = 0,
    int closest = 12,
  })  : _id = id,
        _driveId = driveId,
        _heading = heading,
        _subHeading = subHeading,
        _body = body,
        _published = published,
        _pointsOfInterest = List.from(pointsOfInterest),
        _maneuvers = List.from(maneuvers),
        _routes = List.from(routes),
        _images = images,
        _score = score,
        _distance = distance,
        _closest = closest;

  void clearAll() {
    _driveId = -1;
    _heading = '';
    _subHeading = '';
    _body = '';
    _published = '';
    _pointsOfInterest.clear();
    _maneuvers.clear();
    _routes.clear();
    _images = '';
    _score = 0;
    _distance = 0;
  }

  int getId() {
    return _id;
  }

  void setId(int id) {
    _id = id;
  }

  int getIndex() {
    return _index;
  }

  void setIndex(int index) {
    _index = index;
  }

  int getDriveId() {
    return _driveId;
  }

  void setDriveId(int driveId) {
    _driveId = driveId;
  }

  String getDriveUri() {
    return _driveUri;
  }

  void setDriveUri(String driveUri) {
    _driveUri = driveUri;
  }

  String getHeading() {
    return _heading;
  }

  void setHeading(String heading) {
    _heading = heading;
  }

  String getSubHeading() {
    return _subHeading;
  }

  void setSubHeading(String subHeading) {
    _subHeading = subHeading;
  }

  void setBody(String body) {
    _body = body;
  }

  String getBody() {
    return _body;
  }

  String getPublished() {
    return _published;
  }

  void setPublished(String published) {
    _published = published;
  }

  String getImages() {
    return _images;
  }

  void setImages(String images) {
    _images = images;
  }

  double getScore() {
    return _score;
  }

  void setScore(double score) {
    _score = score;
  }

  int getClosest() {
    return _closest;
  }

  void setClosest(int closest) {
    _closest = closest;
  }

  double getDistance() {
    return _distance;
  }

  void setDistance(double distance) {
    _distance = distance;
  }

  List<PointOfInterest> pointsOfInterest() {
    return _pointsOfInterest;
  }

  void addPointOfInterest(PointOfInterest pointOfInterest) {
    _pointsOfInterest.add(pointOfInterest);
  }

  void insertPointOfInterest(PointOfInterest pointOfInterest, int index) {
    _pointsOfInterest.insert(index, pointOfInterest);
  }

  void removePointOfInterestAt(int index) {
    int id = _pointsOfInterest[index].id;
    _pointsOfInterest.removeAt(index);
    if (id > -1) {
      deletePointOfInterestById(id);
    }
  }

  void movePointOfInterest(int oldIndex, int newIndex) {
    PointOfInterest pointOfInterest = _pointsOfInterest.removeAt(oldIndex);
    _pointsOfInterest.insert(newIndex, pointOfInterest);
  }

  void clearPointsOfInterest() {
    _pointsOfInterest.clear();
  }

  List<Maneuver> maneuvers() {
    return _maneuvers;
  }

  void addManeuver(Maneuver maneuver) {
    _maneuvers.add(maneuver);
  }

  void addManeuvers(List<Maneuver> maneuvers) {
    _maneuvers = maneuvers;
  }

  void clearManeuvers() {
    _maneuvers.clear();
  }

  List<mt.Route> routes() {
    return _routes;
  }

  void addRoute(mt.Route route) {
    _routes.add(route);
  }

  void clearRoutes() {
    _routes.clear();
  }

  void insertRoute(mt.Route route, int index) {
    _routes.insert(index, route);
  }

  void setImage(ui.Image image) {
    _mapImage = image;
  }

  ui.Image getImage() {
    return _mapImage;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'driveUri': _driveUri,
      'heading': _heading,
      'subHeading': _subHeading,
      'body': _body,
      'published': _published,
      'pointsOfInterest': _pointsOfInterest.length,
      'images': _images,
      'score': _score,
      'distance': _distance,
      'closest': _closest,
    };
  }

  /*
            '''CREATE TABLE drives(id INTEGER PRIMARY KEY AUTOINCREMENT, uri INTEGER, title TEXT, sub_title TEXT, body TEXT, 
          map_image TEXT, distance REAL, points_of_interest INTEGER, added DATETIME)''');
  */

  Map<String, dynamic> toDrivesMap() {
    return {
      'id': _id,
      'uri': _driveUri,
      'title': _heading,
      'sub_title': _subHeading,
      'body': _body,
      'added': DateTime.now().toIso8601String(),
      'points_of_interest': _pointsOfInterest.length,
      'distance': _distance,
    };
  }

  Future<int> saveLocal() async {
    int result = -1;
    // _driveId = await saveMyTripItem(this);
    try {
      final directory = (await getApplicationDocumentsDirectory()).path;
      Uint8List? pngBytes = Uint8List.fromList([]);
      if (_driveUri.isEmpty) {
        final byteData =
            await _mapImage.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData?.buffer.asUint8List();
      } else {
        String url =
            Uri.parse('${wh.urlBase}v1/drive/images/$_driveUri/map.png')
                .toString();
        pngBytes = await wh.getImageBytes(url: url);
      }
      String url = '$directory/drive$_driveId.png';
      final imgFile = File(url);
      imgFile.writeAsBytes(pngBytes!);
      if (imgFile.existsSync()) {
        result = 1;
        debugPrint('Image file $url exists');
      }
    } catch (e) {
      String err = e.toString();
      debugPrint('Error: $err');
    }
    //  loadLocal(_driveId);
    return result;
  }

  Future<void> loadLocal(int driveId) async {
    clearAll();
    Map<String, dynamic> map = await getDrive(driveId);
    LatLng pos = const LatLng(0, 0);
    int distance = 99999;
    await getPosition().then((currentPosition) {
      pos = LatLng(currentPosition.latitude, currentPosition.longitude);
    });
    final directory = (await getApplicationDocumentsDirectory()).path;
    _id = driveId;
    _driveId = driveId;
    _heading = map['title'];
    _subHeading = map['subTitle'];
    _body = map['body'];
    _published = map['added'].toString();
    _distance = map['distance'];
    _images = '{"url": "$directory/drive$_id.png", "caption": ""}';
    _pointsOfInterest = await loadPointsOfInterestLocal(driveId);
    for (int i = 0; i < _pointsOfInterest.length; i++) {
      distance = min(
          distanceBetween(_pointsOfInterest[i].point, pos).toInt(), distance);
      if (_pointsOfInterest[i].getImages().isNotEmpty) {
        _images = '$_images,${unList(_pointsOfInterest[i].getImages())}';
      }
    }
    _closest = distance;
    _images = '[$_images]';
    _maneuvers = await loadManeuversLocal(driveId);
    List<Polyline> polyLines = await loadPolyLinesLocal(driveId);
    for (int i = 0; i < polyLines.length; i++) {
      addRoute(mt.Route(
          id: -1,
          points: polyLines[i].points,
          colour: polyLines[i].color,
          borderColour: polyLines[i].color,
          strokeWidth: polyLines[i].strokeWidth));
    }
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
      '''SELECT drives.id, drives.uri, drives.title, drives.sub_title, drives.body, drives.distance, drives.points_of_interest, drives.added,
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
    final directory = (await getApplicationDocumentsDirectory()).path;
    int driveId = -1;
    int highlights = 0;
    String tripImages = '';

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['drive_id'] != driveId) {
        if (trips.isNotEmpty) {
          int distance = closestWaypoint(
                  pointsOfInterest: trips[trips.length - 1].pointsOfInterest(),
                  location: pos)
              .toInt();
          trips[trips.length - 1].setClosest(distance);
          if (tripImages.isNotEmpty) {
            trips[trips.length - 1].setImages('[$tripImages]');
          }
          trips[trips.length - 1].highlights = highlights;
        }
        driveId = maps[i]['drive_id'];
        tripImages = '{"url": "$directory/drive$driveId.png", "caption": ""}';
        //  '$directory/drive$driveId.png'; //unList(maps[i]['map_image']);
        trips.add(MyTripItem(
            id: driveId,
            driveId: driveId,
            driveUri: maps[i]['uri'],
            heading: maps[i]['title'],
            subHeading: maps[i]['sub_title'],
            body: maps[i]['body'],
            published: maps[i]['added'],
            images:
                '{"url": "$directory/drive$driveId.png", "caption": ""}', //maps[i]['map_image'],
            distance: double.parse(maps[i]['distance'].toString()),
            pointsOfInterest: [
              PointOfInterest(
                maps[i]['id'],
                driveId,
                maps[i]['type'],
                maps[i]['name'],
                maps[i]['description'],
                maps[i]['type'] == 12 ? 10 : 30,
                maps[i]['type'] == 12 ? 10 : 30,
                images: maps[i]['images'],
                markerPoint: LatLng(maps[i]['latitude'], maps[i]['longitude']),
                marker: MarkerWidget(
                  type: maps[i]['type'],
                  list: -1,
                  listIndex: i,
                  name: maps[i]['name'],
                  description: maps[i]['description'],
                  images: maps[i]['images'],
                ),
              ),
            ],
            closest: 15));
        if (maps[i]['type'] != 12) highlights++;
      } else {
        trips[trips.length - 1].addPointOfInterest(PointOfInterest(
            maps[i]['id'],
            driveId,
            maps[i]['type'],
            maps[i]['name'],
            maps[i]['description'],
            maps[i]['type'] == 12 ? 10 : 30,
            maps[i]['type'] == 12 ? 10 : 30,
            images: maps[i]['images'],
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
      int distance = closestWaypoint(
              pointsOfInterest: trips[trips.length - 1].pointsOfInterest(),
              location: pos)
          .toInt();
      trips[trips.length - 1].setClosest(distance);
      if (tripImages.isNotEmpty) {
        trips[trips.length - 1].setImages('[$tripImages]');
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
      // await savePolylinesLocal(id: 0, driveId: id, polylines: polyLines);
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
  String id = '';
  String senderId = '';
  String sender = '';
  String message = '';
  String userTargetId = '';
  String groupTargetId = '';
  bool read = false;
  String dated = '';
  DateTime received; // = DateTime.now();
  DateFormat dateFormat = DateFormat("dd MMM yyyy");

  Message(
      {required this.id,
      required this.sender,
      required this.message,
      this.read = false,
      this.userTargetId = '',
      this.groupTargetId = '',
      this.dated = '',
      DateTime? received})
      : received = received ?? DateTime.now();

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      sender: map['sender'],
      message: map['message'],
      read: map['read'] == 0,
      userTargetId: map['target_id'] ?? '',
      groupTargetId: map['group_target_id'] ?? '',
      dated: map['received'],
      received: DateTime.now(),
    );
  }

  factory Message.fromSocketMap(Map<String, dynamic> map) {
    return Message(
      id: '',
      sender: map['sender'] ?? 'unknown sender',
      message: map['message'] ?? 'test',
      dated: DateFormat("dd MMM yy HH:mm").format(DateTime.now()),
      received: DateTime.now(),
      read: false,
    );
  }
}

/*
  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'],
*/
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

Future<List<MessageLocal>> messagesFromDb({int driveId = -1}) async {
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

  List<MessageLocal> messages = [];
  try {
    List<Map<String, dynamic>> maps = await db.rawQuery(messagesQuery);
    int memberId = -1;

    for (int i = 0; i < maps.length; i++) {
      try {
        memberId = maps[i]['user_id'];
        messages.add(MessageLocal(
          id: maps[i]['id'],
          groupMember: GroupMember(
              forename: maps[i]['forename'],
              surname: maps[i]['surname'],
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
  mt.Route? route;
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
