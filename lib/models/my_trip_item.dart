// import 'dart:convert';
//import 'dart:ffi';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:drives/utilities.dart';
// import 'package:drives/screens/dialogs.dart';
// import 'package:drives/screens/painters.dart';
import 'package:drives/services/db_helper.dart';
import 'package:drives/services/web_helper.dart' as wh;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:drives/route.dart' as mt;
import 'package:drives/models/other_models.dart';

class MyTripItem {
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

  MyTripItem({
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
    _driveId = await saveMyTripItem(this);
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
          color: polyLines[i].color,
          borderColor: polyLines[i].color,
          strokeWidth: polyLines[i].strokeWidth));
    }
  }

  Future<bool> publish() async {
    return false;
  }
}