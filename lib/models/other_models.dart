import 'dart:convert';
import 'dart:io';
import 'package:drives/services/services.dart'; // hide getPosition;
import 'package:drives/classes/classes.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drives/constants.dart';
import 'package:drives/classes/utilities.dart' as utils;
import 'package:drives/screens/screens.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/tiles/tiles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
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
};

List<Color> colourList = uiColours.keys.toList();
List<String> colorNameList = uiColours.values.toList();

const List<Color> pinColours = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange
];

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
  int publishedTripColour = 10;
  int bottomNavIndex = 0;
  int recordDetail = 5;
  bool allowNotifications = true;
  bool hasLoggedIn = false;
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
      } catch (e) {
        debugPrint('Failed to load Setup() from db: ${e.toString()}');
      }
    }
    user = await getUser();
    return true;
  }

  Future<void> setupToDb() async {
    await insertSetup(this);
  }

  Future<List<Map<String, dynamic>>> getSetupById(int id) async {
    final db = await DbHelper().db;
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

  Future<void> deleteSetupById(int id) async {
    final db = await DbHelper().db;
    await db.delete(
      'setup',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class PointOfInterest extends Marker {
  // GlobalKey? handle;
  int id;
  String _images;
  final int driveId;
  int _type;
  String _name;
  String _description;
  String url;
  String driveUri;
  double _score;
  int scored;
  DateTime published = DateTime.now();
  late final Widget marker;
  late LatLng markerPoint = const LatLng(52.05884, -1.345583);
  List<Photo> photos;
  String sounds;

  PointOfInterest(
      //  this.ctx
      {
    // this.handle,
    this.id = -1,
    this.driveId = -1,
    int type = -1,
    String name = '',
    String description = '',
    super.width = 30,
    // double width = 30,
    super.height = 30,
    // double height = 30,
    String images = '',
    required LatLng markerPoint,
    required Widget marker,
    this.url = '',
    this.driveUri = '',
    double score = 1,
    this.scored = 0,
    this.sounds = '',
  })  : _images = handleWebImages(
          images,
        ),
        photos = photosFromJson(
            handleWebImages(
              images,
            ),
            endPoint: '$urlDriveImages/$driveUri/$url/'),
        _type = type,
        _name = name,
        _description = description,
        _score = score,
        super(
          child: marker,
          point: markerPoint,
          //    width: width,
          //    height: height, /*key: key*/
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

  String getEndpoint() {
    return '$driveUri/$url';
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
      'url': url,
      'driveId': driveId,
      'type': _type,
      'name': _name,
      'description': _description,
      'latitude': point.latitude, //markerPoint.latitude,
      'longitude': point.longitude, //markerPoint.longitude,
    };
  }
}

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
          pointOfInterestDialog(context, name, description, images, url,
              imageUrls, score, scored, type);
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

class OSMMarkerWidget extends StatelessWidget {
  final int osmId;
  final String name;
  final String amenity;
  final String postcode;
  final double angle;
  final int index;

  const OSMMarkerWidget(
      {super.key,
      required this.osmId,
      required this.name,
      required this.amenity,
      required this.postcode,
      required this.index,
      this.angle = 0});

  @override
  Widget build(BuildContext context) {
    int width = 30;
    double iconWidth = width * 0.75;
    Color buttonFillColor =
        uiColours.keys.toList()[Setup().pointOfInterestColour];
    Color iconColor = Colors.white;
    int iconCodePoint = iconMap[amenity] ?? 12;
    // Want to counter rotate the icons so that they are vertical when the map rotates
    // -_mapRotation * pi / 180 to convert from _mapRotation in degrees to radians
    return Transform.rotate(
      angle: angle,
      child: RawMaterialButton(
        onPressed: () {
          osmDataDialog(context, name, amenity, postcode, iconCodePoint, osmId);
        },
        elevation: 2.0,
        fillColor: buttonFillColor,
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 1, 2),
          child: Icon(
            IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
            size: iconWidth,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class FeatureMarker extends StatelessWidget {
  final int index;
  final double width;
  final double angle;
  final Icon icon;
  final Icon overlay;
  final Function(int)? onPress;
  const FeatureMarker({
    super.key,
    this.index = -1,
    this.width = 50,
    this.angle = 0,
    this.icon = const Icon(Icons.location_on, color: Colors.red),
    this.overlay = const Icon(Icons.location_on, color: Colors.red),
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    //double width = zoom * 4;

    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: width,
        child: FittedBox(
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: LocationPinPainter(size: 50),
              ),
              IconButton(
                iconSize: width,
                icon: const Icon(Icons.home),
                onPressed: () {
                  //   debugPrint('FeatureMarker.onPress($index)');
                  onPress!(index);
                },
              ),
            ],
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

osmDataDialog(
  BuildContext context,
  String name,
  String amenity,
  String postcode,
  int iconCodepoint,
  int osmId,
) async {
  Widget cancelButton = TextButton(
    child: const Text(
      "Cancel",
      style: TextStyle(fontSize: 20),
    ),
    onPressed: () {
      Navigator.pop(context, true);
    },
  );
  Widget okButton = TextButton(
    child: const Text(
      "Ok",
      style: TextStyle(fontSize: 20),
    ),
    onPressed: () {
      Navigator.pop(context, true);
    },
  );
  double score = 5.0;
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(
      name,
      style: const TextStyle(fontSize: 20),
      textAlign: TextAlign.center,
    ),
    // scrollable: true,
    elevation: 5,
    content: StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Icon(
                    IconData(iconCodepoint, fontFamily: 'MaterialIcons'),
                    color: Colors.black,
                    size: 40,
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Text(
                    amenity.replaceFirst(RegExp('_'), ' '),
                    style: TextStyle(fontSize: 30),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 225,
                  height: 80,
                  child: Text(
                    '$name has not yet been rated. Review it now to help other people.',
                    style:
                        TextStyle(fontSize: 20, overflow: TextOverflow.visible),
                  ),
                ),
              ],
            ),
            Row(children: [
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                    child: TextFormField(
                        readOnly: false,
                        autofocus: true,
                        maxLines: 10,
                        minLines: 3,
                        textInputAction: TextInputAction.done,

                        //     expands: true,
                        initialValue: '',
                        textAlign: TextAlign.start,
                        keyboardType: TextInputType.streetAddress,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintMaxLines: 1,
                          hintText: 'Describe $name...',
                          labelText: 'My review',
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onFieldSubmitted: (_) => ()) //body = text
                    ),
              ),
            ]),
            Row(children: [
              Expanded(
                flex: 7,
                child: SizedBox(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ActionChip(
                      label: const Text(
                        'Image',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      avatar: const Icon(Icons.photo_album,
                          size: 20, color: Colors.white),
                      onPressed: () => loadImage(),
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 8,
                child: StarRating(
                    onRatingChanged: (val) => setState(() {
                          score = val.toDouble();
                        }),
                    rating: score),
              ),
            ]),
          ],
        );
      },
    ),
    actions: [
      okButton,
      cancelButton,
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

loadImage() async {
  try {
    ImagePicker picker = ImagePicker();
    await //ImagePicker()
        picker.pickImage(source: ImageSource.gallery).then(
      (pickedFile) async {
        try {
          if (pickedFile != null) {
            // final directory = (await getApplicationDocumentsDirectory()).path;

            /// Don't know what type of image so have to get file extension from picker file
            //     int num = 1;
            /*
                if (widget.pointOfInterest.getImages().isNotEmpty) {
                  /// count number of images
                  num = '{'
                          .allMatches(widget.pointOfInterest.getImages())
                          .length +
                      1;
                }
                debugPrint('Image count: $num');
                */
            //     String imagePath =
            //         '$directory/point_of_interest_${id}_$num.${pickedFile.path.split('.').last}';
            //     File(pickedFile.path).copy(imagePath);
            /*
                setState(() {
                  widget.pointOfInterest.setImages(
                      '[${widget.pointOfInterest.getImages().isNotEmpty ? '${widget.pointOfInterest.getImages().substring(1, widget.pointOfInterest.getImages().length - 1)},' : ''}{"url":"$imagePath","caption":"image $num"}]');
                  widget.pointOfInterest.photos.add(Photo(
                      url: imagePath,
                      index: widget.pointOfInterest.photos.length));
                  debugPrint('Images: $widget.pointOfInterest.images');
                });
                */
          }
        } catch (e) {
          String err = e.toString();
          debugPrint('Error getting image: $err');
        }
      },
    );
  } catch (e) {
    String err = e.toString();
    debugPrint('Error loading image: $err');
  }
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

  String caption;
  String endPoint;
  Photo(
      {required this.url,
      this.id = -1,
      this.key = -1,
      this.index = -1,
      this.caption = '',
      this.endPoint = ''});

  factory Photo.fromJson(Map<String, dynamic> json,
      {int index = -1, String endPoint = ''}) {
    if (!json.containsKey('url')) {
      //   debugPrint("Doesn't contain 'url'");
    }
    return Photo(
        url: '$endPoint${json['url']}',
        id: json['id'] ?? -1,
        caption: json['caption'] ?? '',
        key: -1,
        index: index);
  }

  factory Photo.fromJsonMap(Map<String, String> json) {
    return Photo(
        url: json['url'] ?? '',
        id: int.parse(json['id'] ?? '-1'),
        caption: json['caption'] ?? '');
  }

  String toJson() {
    return '{"url": $url, "caption": $caption}';
  }

  String toMapString() {
    return '{"url": "$url", "caption": "$caption"}';
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
  LatLng northEast;
  LatLng southWest;
  GoodRoadCacheItem(
      {this.localId = -1,
      this.url = '',
      this.northEast = const LatLng(50, 0),
      this.southWest = const LatLng(50, 0),
      this.index = -1});

  factory GoodRoadCacheItem.fromMap(
      {required Map<String, dynamic> map, row = -1}) {
    return GoodRoadCacheItem(
        index: row,
        localId: map['id'] ?? -1,
        url: map['uri'] ?? '',
        northEast: LatLng(map['max_lat'] ?? 50.0, map['max_lng'] ?? 0),
        southWest: LatLng(map['min_lat'] ?? 50.0, map['min_lng'] ?? 0));
  }
}

/// Creates a list of photos from a json string of the following format:
///  '[{"url": "assets/images/map.png", "caption": ""}, {"url": "assets/images/splash.png", "caption": ""},
///   {"url": "assets/images/CarGroup.png", "caption": "" }]',
///  post-constructor function handleWebImages converts a simple image file name to a map to reduce web traffic
///  for some strange reason the string must start with a single quote.

List<Photo> photosFromJson(String photoString, {String endPoint = ''}) {
  if (photoString.isNotEmpty) {
    if (!photoString.contains("url")) {
      //  debugPrint('photoString: $photoString');
    }
    int index = 0;
    return [
      for (Map<String, dynamic> urlData in jsonDecode(photoString))
        Photo.fromJson(urlData, endPoint: endPoint, index: index++)
    ];
  }
  return [];
}

List<Photo> photosFromMap(String photoString) {
  List<Photo> photos = [
    for (Map<String, String> url in jsonDecode(photoString)) Photo.fromJson(url)
  ];
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
  Map<String, dynamic> toMap({String driveUid = ''}) {
    return {
      'id': id,
      'drive_uid': driveUid,
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

class OsmAmenity extends Marker {
  final IntIm? id; // = MutableInt(value: -1);
  final int osmId;
  final String name;
  final String amenity;
  final int iconColour;
  final String postcode;
  final int index;

  const OsmAmenity(
      {this.id,
      this.osmId = -1,
      this.index = -1,
      this.name = '',
      this.amenity = '',
      this.postcode = '',
      super.width = 20,
      super.height = 20,
      this.iconColour = 0,
      required LatLng position,
      required Widget marker})
      : super(
          child: marker,
          point: position, // markerPoint,
        );

  factory OsmAmenity.fromMap({required Map<String, dynamic> map}) {
    return OsmAmenity(
      id: IntIm(value: map['osm_id'] ?? -1),
      osmId: map['osm_id'],
      index: map['index'],
      name: map['name'] ?? '',
      amenity: map['amenity'] ?? '',
      postcode: map['postcode'] ?? '',
      position: LatLng(map['lat'], map['lng']),
      marker: MarkerWidget(
        type: 1,
        list: -1,
        listIndex: -1,
        name: map['name'],
        description: map['amenity'],
        images: '',
      ),
    );
  }
  /*
  marker: MarkerWidget(
    type: 16,
    description: '',
    angle: -_mapRotation * pi / 180,
    colourIdx: cIndex,
  ),
   */

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'osm_id': osmId,
      'name': name,
      'amenity': amenity,
      'postcode': postcode,
      'icon_colour': iconColour,
      'position': '{"lat": ${point.latitude}, "lng": ${point.longitude}}',
    };
  }
}

/// class Follower

class Follower extends Marker {
  String uri;
  String driveId;
  String forename = '';
  String surname = '';
  String phoneNumber = '';
  String car = '';
  String registration = '';
  int iconColour = 0;
  LatLng position = const LatLng(0, 0);
  DateTime reported = DateTime.now();
  int index = -1;
  @override
  double width;
  @override
  double height;
  Follower(
      {this.uri = '',
      this.driveId = '',
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
      'id': uri,
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
///

/// Api sends image urls as a list of filenames
/// To simplify handling of local and web images the
/// API url list is converted to {"url": "uuid.jpg", "caption": ""}, {...}
String handleWebImages(String urls) {
  String mappedUrls = urls;
  if (urls.isNotEmpty && !urls.contains('{') && !urls.contains('assets')) {
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

  /// Need to be abple to change the URL as the API doesn't
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
  // late LatLng markerPoint = const LatLng(52.05884, -1.345583);
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
      super.point = const LatLng(-50.0, -0.2),
      super.width = 20,
      super.height = 20});

  factory TripSummary.fromMap({required Map<String, dynamic> map}) {
    return TripSummary(
      uri: map['uri'],
      title: map['title'],
      subTitle: map['sub_title'],
      minLat: map['min_lat'],
      maxLat: map['max_lat'],
      minLong: map['min_long'],
      maxLong: map['max_long'],
      score: map['score'],
      scored: map['scored'],
      point: LatLng(map['min_lat'], map['min_long']),
    );
  }
}

class TripItem {
  GlobalKey? handle;
  int key = 0;
  int id = 0;
  String heading = '';
  String uri = '';
  String driveUri = '';
  String subHeading = '';
  String body = '';
  String author = '';
  String authorUrl = '';
  String published = '';
  String imageUrls = '';
  double score = 5;
  double distance = 0;
  int pointsOfInterest = 0;
  int closest = 12;
  int scored = 10;
  int downloads = 18;
  List<Polyline> polylines;
  TripItem(
      {this.handle,
      this.id = 0,
      this.driveUri = '',
      required this.heading,
      this.subHeading = '',
      this.body = '',
      this.author = '',
      this.authorUrl = '',
      this.published = '',
      this.imageUrls = '',
      this.score = 5,
      this.distance = 0,
      this.pointsOfInterest = 0,
      this.closest = 12,
      this.scored = 10,
      this.downloads = 18,
      this.uri = '',
      this.polylines = const []});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'heading': heading,
      'sub_heading': subHeading,
      'body': body,
      'author': author,
      'author_url': authorUrl,
      'published': published,
      'image_urls': imageUrls,
      'score': score,
      'distance': distance,
      'points_of_interest': pointsOfInterest,
      'closest': closest,
      'scored': scored,
      'downloads': downloads,
    };
  }

  Map<String, dynamic> toMapLocal() {
    return {
      'id': id,
      'heading': heading,
      'sub_heading': subHeading,
      'body': body,
      'author': author,
      'author_url': authorUrl,
      'published': published,
      'image_urls': imageUrls,
      'score': score,
      'distance': distance,
      'points_of_interest': pointsOfInterest,
      'closest': closest,
      'scored': scored,
      'downloads': downloads,
    };
  }

  factory TripItem.fromMap(
      {required Map<String, dynamic> map,
      String endpoint = '',
      String imageUrls = ''}) {
    return TripItem(
      id: map['id'] is int ? map['id'] : -1,
      driveUri: map['id'] is String
          ? map['id']
          : '', // The API sends back the uri as id
      heading: map['title'] ?? map['heading'],
      subHeading: map['sub_title'] ?? map['sub_heading'],
      body: map['body'],
      author: map['author'],
      published: map['added'] ?? DateTime.now().toIso8601String(),
      imageUrls: imageUrls.isEmpty
          ? map['image_urls'] ?? ''
          : imageUrls, // has to be calculated
      score: (map['average_rating'] ?? 5.0).toDouble() ?? 5.0,
      distance: map['distance'] is double ? map['distance'] : 0.0,
      pointsOfInterest: map['points_of_interest'] is int
          ? map['points_of_interest'] ?? 0
          : (map['points_ofInterest'] ?? []).length,
      closest: 0, // has to be calculated
      scored: map['ratings_count'] ?? 1,
      downloads: map['downloads'] ?? 0,
      uri: '$endpoint${map['uri'] ?? ''}',
    );
  }
}

Future<List<MyTripItem>> tripItemFromDb(
    {int driveId = -1, bool showMethods = false}) async {
  final db = await DbHelper().db;
  LatLng pos = const LatLng(0, 0);

  await utils.getPosition().then((currentPosition) {
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
                  pointsOfInterest: trips[trips.length - 1].pointsOfInterest,
                  location: pos)
              .toInt();
          trips[trips.length - 1].closest = distance;
          if (tripImages.isNotEmpty) {
            trips[trips.length - 1].images = '[$tripImages]';
          }
          trips[trips.length - 1].highlights = highlights;
        }
        driveId = maps[i]['drive_id'];
        tripImages = '{"url": "$directory/drive$driveId.png", "caption": ""}';
        //  '$directory/drive$driveId.png'; //unList(maps[i]['map_image']);
        trips.add(MyTripItem(
            id: driveId,
            driveId: driveId,
            showMethods: showMethods,
            driveUri: maps[i]['uri'],
            heading: maps[i]['title'],
            subHeading: maps[i]['sub_title'],
            body: maps[i]['body'],
            published: maps[i]['added'],
            images:
                '[{"url": "$directory/drive$driveId.png", "caption": ""}]', //maps[i]['map_image'],
            distance: double.parse(maps[i]['distance'].toString()),
            pointsOfInterest: [
              PointOfInterest(
                id: maps[i]['id'],
                driveId: driveId,
                type: maps[i]['type'],
                name: maps[i]['name'],
                description: maps[i]['description'],
                width: maps[i]['type'] == 12 ? 10 : 30,
                height: maps[i]['type'] == 12 ? 10 : 30,
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
            id: maps[i]['id'],
            driveId: driveId,
            type: maps[i]['type'],
            name: maps[i]['name'],
            description: maps[i]['description'],
            width: maps[i]['type'] == 12 ? 10 : 30,
            height: maps[i]['type'] == 12 ? 10 : 30,
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
              pointsOfInterest: trips[trips.length - 1].pointsOfInterest,
              location: pos)
          .toInt();
      trips[trips.length - 1].closest = distance;
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

class TripMessage {
  String id;
  String senderId;
  String message;
  double lat;
  double lng;
  TripMessage(
      {this.id = '',
      this.senderId = '',
      this.message = '',
      this.lat = 0.0,
      this.lng = 0.0});
  factory TripMessage.fromSocketMap(Map<String, dynamic> map) {
    return TripMessage(
      id: map['id'] ?? '',
      senderId: map['sender_id'] ?? '',
      message: map['message'] ?? '',
      lat: map['lat'] ?? 0.0,
      lng: map['lng'] ?? 0.0,
    );
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
  // DateFormat dateFormat = DateFormat("dd MMM yyyy");

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

Future<List<MessageLocal>> messagesFromDb({int driveId = -1}) async {
  final db = await DbHelper().db;
  String messagesQuery =
      '''SELECT group_members.forename, group_members.surname, group_members.group_ids, group_members.id, 
      group_members.phone, group_members.email,  messages.*  
    FROM group_members
    JOIN messages 
    ON group_members.id = messages.user_id''';

  List<MessageLocal> messages = [];
  try {
    List<Map<String, dynamic>> maps = await db.rawQuery(messagesQuery);
    for (int i = 0; i < maps.length; i++) {
      try {
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
}

class GoodRoad {
  bool _isGood = false;
  int routeIdx1 = -1;
  int routeIdx2 = -1;
  int pointIdx1 = -1;
  int pointIdx2 = -1;
  int markerIdx = -1;
  int pointOfInterestId = -1;
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
    pointOfInterestId = -1;
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
