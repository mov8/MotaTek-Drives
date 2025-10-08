import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:drives/constants.dart';
import 'package:drives/classes/utilities.dart' as ut;
import 'package:image_picker/image_picker.dart';
import 'package:drives/services/services.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/models/other_models.dart';
import 'package:drives/services/web_helper.dart' as wh;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
// import 'package:drives/classes/directions.dart';

class CurrentTripItem extends MyTripItem {
  CurrentTripItem._privateConstructor();
  bool isSaved = false;
  bool isTracking = false;
  TripState tripState = TripState.none;
  TripActions tripActions = TripActions.none;
  TripType tripType = TripType.none;
  HighliteActions highliteActions = HighliteActions.none;
  XFile? imageFile;
  //late Directions _directions;

  static final _instance = CurrentTripItem._privateConstructor();

  factory CurrentTripItem() {
    return _instance;
  }

  fromMyTripItem({required MyTripItem myTripItem}) {
    id = myTripItem.id;
    driveId = myTripItem.driveId;
    index = myTripItem.index;
    groupDriveId = myTripItem.groupDriveId;
    driveUri = myTripItem.driveUri;
    heading = myTripItem.heading;
    subHeading = myTripItem.subHeading;
    body = myTripItem.body;
    published = myTripItem.published;
    publisher = myTripItem.publisher;
    pointsOfInterest = myTripItem.pointsOfInterest;
    maneuvers = myTripItem.maneuvers;
    this.routes = myTripItem.routes;
    goodRoads = myTripItem.goodRoads;
    images = myTripItem.images;
    score = myTripItem.score;
    distance = myTripItem.distance;
    closest = myTripItem.closest;
    highlights = myTripItem.highlights;
    showMethods = myTripItem.showMethods;
    mapImage = myTripItem.mapImage;
    tripState = TripState.loaded;
    tripType = TripType.none;
  }

  MyTripItem clone() {
    MyTripItem myTripItem = MyTripItem(
      id: id,
      driveId: driveId,
      index: index,
      groupDriveId: groupDriveId,
      driveUri: driveUri,
      heading: heading,
      subHeading: subHeading,
      body: body,
      published: published,
      publisher: publisher,
      pointsOfInterest: pointsOfInterest,
      maneuvers: maneuvers,
      routes: this.routes,
      goodRoads: goodRoads,
      images: images,
      score: score,
      distance: distance,
      closest: closest,
      highlights: highlights,
      showMethods: showMethods,
    );
    myTripItem.mapImage = mapImage;
    return myTripItem;
  }

  @override
  clearAll() {
    isSaved = false;
    driveUri = '';
    images = '';
    groupDriveId = '';
    isTracking = false;
    tripType = TripType.none;
    tripState = TripState.none;
    tripActions = TripActions.none;
    highliteActions = HighliteActions.none;
    return super.clearAll();
  }

  Future<bool> saveState() async {
    try {
      await saveLocal();
      Setup().appState =
          '{"route": 2, "id": $driveId, "saved": ${isSaved ? 1 : 0}, "isTracking": ${isTracking ? 1 : 0}, "tripState": ${tripState.index}, "tripActions": ${tripActions.index}}';
      Setup().setupToDb();
    } catch (e) {
      debugPrint("Can't save CurrentTrip state: ${e.toString}");
      return false;
    }
    return true;
  }

  Future<bool> restoreState() async {
    Map<String, dynamic> stateMap = jsonDecode(Setup().appState);
    if ((stateMap['route'] ?? -1) == 2) {
      try {
        await loadLocal(stateMap['id']);
        isSaved = (stateMap['isSaved'] ?? 0) == 1;
        isTracking = (stateMap['isTracking'] ?? 0) == 1;
        tripState = TripState.values[(stateMap['tripState'] ?? 0)];
        tripActions = TripActions.values[(stateMap['tripActions'] ?? 0)];
      } catch (e) {
        debugPrint('Error restoring State: ${e.toString()}');
      }
      final ImagePicker picker = ImagePicker();
      final LostDataResponse response = await picker.retrieveLostData();
      if (!response.isEmpty) {
        imageFile = response.files![0];
        if (imageFile != null) {
          //    debugPrint('Image file recovered');
        }
      }
      Setup().appState = '';
      Setup().setupToDb();
    }
    return true;
  }
}

class MyTripItem {
  int id;
  int driveId;
  int index;
  String groupDriveId;
  String driveUri;
  String heading;
  String subHeading;
  String body;
  String published;
  String publisher;
  List<PointOfInterest> pointsOfInterest = [];
  List<Maneuver> maneuvers = [];
  List<mt.Route> routes = [];
  List<mt.Route> goodRoads = [];
  List<Follower> following = [];
  String images;
  double score;
  double distance;
  double distanceAway;
  int closest;
  int highlights;
  bool showMethods;
  bool selected;
  ui.Image? mapImage;

  MyTripItem({
    this.id = -1,
    this.driveId = -1,
    this.index = -1,
    this.driveUri = '',
    this.heading = '',
    this.subHeading = '',
    this.body = '',
    this.published = '',
    this.publisher = '',
    pointsOfInterest,
    following,
    maneuvers,
    routes,
    goodRoads,
    this.images = '',
    this.score = 5,
    this.distance = 0,
    this.distanceAway = 0,
    this.closest = 12,
    this.highlights = 0,
    this.groupDriveId = '',
    this.showMethods = false,
    this.selected = false,
  })  : pointsOfInterest = pointsOfInterest ?? [],
        maneuvers = maneuvers ?? [],
        routes = routes ?? [],
        following = following ?? [],
        goodRoads = goodRoads ?? [];

  clearAll() {
    id = -1; // These 2 lines were commented out
    driveId = -1; // Not sure why
    heading = '';
    subHeading = '';
    body = '';
    published = '';
    pointsOfInterest.clear();
    maneuvers.clear();
    routes.clear();
    goodRoads.clear();
    images = '';
    score = 0;
    distance = 0;
  }

  loadGroup() async {}

  // clearRoutes() {
  //   routes.clear();
//  }

  initialise(pointsOfInterest, maneuvers, routes, goodRoads) {
    this.pointsOfInterest = pointsOfInterest;
    this.maneuvers = maneuvers;
    this.routes = routes;
    this.goodRoads = goodRoads;
  }

  // DateFormat dateFormat = DateFormat("dd MMM yyyy");

  String getPublishedDate(
      {String yesPrompt = 'saved on', String noPrompt = 'not published'}) {
    try {
      return "$yesPrompt ${dateFormat.format(DateTime.parse(published))} ${driveUri.isEmpty ? 'but not published' : 'and published'}";
    } catch (e) {
      return noPrompt;
    }
  }

  void addPointOfInterest(PointOfInterest pointOfInterest) {
    pointsOfInterest.add(pointOfInterest);
  }

  void insertPointOfInterest(PointOfInterest pointOfInterest, int index) {
    pointsOfInterest.insert(index, pointOfInterest);
  }

  void removePointOfInterestAt(int index) {
    int id = pointsOfInterest[index].id;
    pointsOfInterest.removeAt(index);
    if (id > -1) {
      deletePointOfInterestById(id);
    }
  }

  void movePointOfInterest(int oldIndex, int newIndex) {
    PointOfInterest pointOfInterest = pointsOfInterest.removeAt(oldIndex);
    pointsOfInterest.insert(newIndex, pointOfInterest);
  }

  void clearPointsOfInterest() {
    pointsOfInterest.clear();
  }

  void addManeuver(Maneuver maneuver) {
    maneuvers.add(maneuver);
  }

  void addManeuvers(List<Maneuver> maneuvers) {
    maneuvers = maneuvers;
  }

  void clearManeuvers() {
    maneuvers.clear();
  }

  void addRoute(mt.Route route) {
    routes.add(route);
  }

  void clearRoutes() {
    routes.clear();
  }

  void insertRoute(mt.Route route, int index) {
    routes.insert(index, route);
  }

  void addGoodRoad(mt.Route route) {
    goodRoads.add(route);
  }

  void clearGoodRoads() {
    goodRoads.clear();
  }

  void insertGoodRoad(mt.Route route, int index) {
    goodRoads.insert(index, route);
  }

  double updateDistance() {
    double distance = 0;
    for (int i = 0; i < maneuvers.length; i++) {
      distance += maneuvers[i].distance;
    }
    distance = distance * metersToMiles;
    this.distance = double.parse(distance.toStringAsFixed(2));
    return this.distance;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driveUri': driveUri,
      //   'groupUri': groupUri,
      'heading': heading,
      'subHeading': subHeading,
      'body': body,
      'published': published,
      'pointsOfInterest': pointsOfInterest.length,
      'images': images,
      'score': score,
      'distance': distance,
      'closest': closest,
    };
  }

  /*
            '''CREATE TABLE drives(id INTEGER PRIMARY KEY AUTOINCREMENT, uri INTEGER, title TEXT, sub_title TEXT, body TEXT, 
          map_image TEXT, distance REAL, points_of_interest INTEGER, added DATETIME)''');
  */

  Map<String, dynamic> toDrivesMap() {
    return {
      'id': id,
      'uri': driveUri,
      'title': heading,
      'sub_title': subHeading,
      'body': body,
      'added': DateTime.now().toIso8601String(),
      'points_of_interest': pointsOfInterest.length,
      'distance': distance,
    };
  }

  Future<int> saveLocal() async {
    int result = -1;
    updateDistance();
    driveId = await saveMyTripItem(this);
    try {
      Uint8List? pngBytes = Uint8List.fromList([]);
      if (driveUri.isEmpty) {
        if (mapImage != null) {
          final byteData =
              await mapImage!.toByteData(format: ui.ImageByteFormat.png);
          pngBytes = byteData?.buffer.asUint8List();
        }
      } else {
        String url = Uri.parse('$urlDrive/images/$driveUri/map.png').toString();
        pngBytes = await wh.getImageBytes(url: url);
      }
      if (pngBytes != null) {
        String url = '${Setup().appDocumentDirectory}/drive$driveId.png';
        final imgFile = File(url);
        imgFile.writeAsBytes(pngBytes);
        if (imgFile.existsSync()) {
          result = 1;
          //   debugPrint('Image file $url exists');
        }
      }
    } catch (e) {
      String err = e.toString();
      debugPrint('saveLocal().Error: $err');
    }
    //  loadLocal(_driveId);
    return result;
  }

  Future<void> loadLocal(int driveId) async {
    clearAll();
    Map<String, dynamic> map = await getDrive(driveId);
    LatLng pos = const LatLng(0, 0);
    // double distance = 99999;
    try {
      await ut.getPosition().then((currentPosition) {
        pos = LatLng(currentPosition.latitude, currentPosition.longitude);
      });

      final directory = Setup().appDocumentDirectory;
      id = driveId;
      driveId = driveId;
      heading = map['title'];
      subHeading = map['subTitle'];
      body = map['body'];
      published = map['added'].toString();
      distance = map['distance'];
      images = '{"url": "$directory/drive$id.png", "caption": ""}';
      pointsOfInterest = await loadPointsOfInterestLocal(driveId);
      for (int i = 0; i < pointsOfInterest.length; i++) {
        if (pointsOfInterest[i].getImages().isNotEmpty) {
          images = '$images,${ut.unList(pointsOfInterest[i].getImages())}';
        }
      }
      closest = distance.toInt();
      images = '[$images]';
      maneuvers = await loadManeuversLocal(driveId);
      if (maneuvers.isNotEmpty) {
        distanceAway = Geolocator.distanceBetween(pos.latitude, pos.longitude,
            maneuvers[0].location.latitude, maneuvers[0].location.longitude);
      }
      List<mt.Route> polyLines = await loadPolyLinesLocal(driveId, type: 0);
      for (int i = 0; i < polyLines.length; i++) {
        routes.add(
          mt.Route(
              id: -1,
              points: polyLines[i].points,
              color: colourList[Setup().routeColour], //  polyLines[i].color,
              borderColor:
                  colourList[Setup().routeColour], //polyLines[i].color,
              strokeWidth: polyLines[i].strokeWidth),
        );
      }
      polyLines = await loadPolyLinesLocal(driveId, type: 1);
      for (int i = 0; i < polyLines.length; i++) {
        // pointsOfInterest[polylines[i].pointOfInterestIndex].id
        // polyLines.pointOfInterestIndex is its pointOfInterest.id
        goodRoads.add(
          mt.Route(
              id: -1,
              points: polyLines[i].points,
              color: polyLines[i].color,
              borderColor: polyLines[i].color,
              strokeWidth: polyLines[i].strokeWidth,
              pointOfInterestIndex: polyLines[i].pointOfInterestIndex), // id
        );
      }
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }

  Future<bool> publish({bool fromLocal = true}) async {
    if (fromLocal) {
      await loadLocal(id);
    }
    // var uuid = const Uuid();
    await postTrip(this);
    return true;
  }
/*
    Map<String, dynamic> response = await postDriveHeader();
    if (response['status'] == 'OK') {
      driveUri = response['uri'];

      for (PointOfInterest pointOfInterest in pointsOfInterest) {
        pointOfInterest.driveUri = driveUri;
        // need to link the point of interest to the good road
        // so will put the uuid in here rather than API
        // uuid.v7() returns a uuid with -s 019523a6-a2ed-7a9a-8635-f003daee7f5e
        // so have to remove them with a replaceAll
        if (pointOfInterest.getType() == 13) {
          String uuidString = uuid.v7();
          pointOfInterest.url = uuidString.replaceAll(RegExp(r'-'), '');
          //  debugPrint('Point of interest url set to ${pointOfInterest.url}');
        }

        await postPointOfInterest(pointOfInterest, driveUri);
      }

      // pointsOfInterest[polylines[i].pointOfInterestIndex].id
      // polyLines.pointOfInterestIndex is its pointOfInterest.id
      for (mt.Route route in goodRoads) {
        for (PointOfInterest pointOfInterest in pointsOfInterest) {
          if (pointOfInterest.id == route.pointOfInterestIndex) {
            // pick up the point of interest uuid
            route.pointOfInterestUri = pointOfInterest.url;
            //     debugPrint('route.interestUri set to ${pointOfInterest.url}');
            break;
          }
        }
      }

      for (int i = 0; i < 2; i++) {
        await postPolylines(
            polylines: i == 0 ? routes : goodRoads,
            driveUid: driveUri,
            type: i);
      }

      postManeuvers(maneuvers, driveUri);

      return true;
    } else {
      return false;
    }
  }

  int tripDistanceMeters(List<Maneuver> maneuvers) {
    double meters = 0;
    for (int i = 0; i < maneuvers.length; i++) {
      meters += maneuvers[i].distance;
    }
    return meters.toInt();
  }
  */
}
