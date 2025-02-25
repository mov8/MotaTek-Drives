import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:drives/constants.dart';
import 'package:drives/classes/utilities.dart' as ut;
import 'package:drives/services/services.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/models/other_models.dart';
import 'package:drives/services/web_helper.dart' as wh;
// import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';

class MyTripItem {
  int _id = -1;
  int _driveId = -1;
  int _index = -1;
  bool _groupTrip = false;
  String _driveUri = '';
  String _heading = '';
  String _subHeading = '';
  String _body = '';
  String _published = '';
  String _publisher = '';
  List<PointOfInterest> _pointsOfInterest = [];
  List<Maneuver> _maneuvers = [];
  List<mt.Route> _routes = [];
  List<mt.Route> _goodRoads = [];
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
    String publisher = '',
    List<PointOfInterest> pointsOfInterest = const [],
    List<Maneuver> maneuvers = const [],
    List<mt.Route> routes = const [],
    List<mt.Route> goodRoads = const [],
    String images = '',
    double score = 5,
    double distance = 0,
    int closest = 12,
    groupTrip = false,
  })  : _id = id,
        _driveId = driveId,
        _driveUri = driveUri,
        _groupTrip = groupTrip,
        _heading = heading,
        _subHeading = subHeading,
        _body = body,
        _published = published,
        _publisher = publisher,
        _pointsOfInterest = List.from(pointsOfInterest),
        _maneuvers = List.from(maneuvers),
        _routes = List.from(routes),
        _goodRoads = List.from(goodRoads),
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
    _goodRoads.clear();
    _images = '';
    _score = 0;
    _distance = 0;
  }

  // DateFormat dateFormat = DateFormat("dd MMM yyyy");

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

  void setGroupTrip(bool groupTrip) {
    _groupTrip = groupTrip;
  }

  bool getGroupTrip() {
    return _groupTrip;
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

  void setRouteColour(int index, Color colour) {
    _routes[index].color = colour;
  }

  String getBody() {
    return _body;
  }

  String getPublished() {
    return _published;
  }

  String getPublisher() {
    return _publisher;
  }

  String getPublishedDate(
      {String yesPrompt = 'published on', String noPrompt = 'not published'}) {
    try {
      return '$yesPrompt ${dateFormat.format(DateTime.parse(_published))}';
    } catch (e) {
      return noPrompt;
    }
  }

  void setPublished(String published) {
    _published = published;
  }

  void setPublisher(String publisher) {
    _publisher = publisher;
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

  List<mt.Route> goodRoads() {
    return _goodRoads;
  }

  void addGoodRoad(mt.Route route) {
    _goodRoads.add(route);
  }

  void clearGoodRoads() {
    _goodRoads.clear();
  }

  void insertGoodRoad(mt.Route route, int index) {
    _goodRoads.insert(index, route);
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
      // final directory = Setup().appDocumentDirectory;
      // (await getApplicationDocumentsDirectory()).path;
      Uint8List? pngBytes = Uint8List.fromList([]);
      if (_driveUri.isEmpty) {
        final byteData =
            await _mapImage.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData?.buffer.asUint8List();
      } else {
        String url =
            Uri.parse('$urlDrive/images/$_driveUri/map.png').toString();
        pngBytes = await wh.getImageBytes(url: url);
      }
      String url = '${Setup().appDocumentDirectory}/drive$_driveId.png';
      final imgFile = File(url);
      imgFile.writeAsBytes(pngBytes!);
      if (imgFile.existsSync()) {
        result = 1;
        debugPrint('Image file $url exists');
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
    int distance = 99999;

    await ut.getPosition().then((currentPosition) {
      pos = LatLng(currentPosition.latitude, currentPosition.longitude);
    });

    final directory = Setup().appDocumentDirectory;
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
          ut.distanceBetween(_pointsOfInterest[i].point, pos).toInt(),
          distance);
      if (_pointsOfInterest[i].getImages().isNotEmpty) {
        _images = '$_images,${ut.unList(_pointsOfInterest[i].getImages())}';
      }
    }
    _closest = distance;
    _images = '[$_images]';
    _maneuvers = await loadManeuversLocal(driveId);
    List<mt.Route> polyLines = await loadPolyLinesLocal(driveId, type: 0);
    for (int i = 0; i < polyLines.length; i++) {
      _routes.add(
        mt.Route(
            id: -1,
            points: polyLines[i].points,
            color: polyLines[i].color,
            borderColor: polyLines[i].color,
            strokeWidth: polyLines[i].strokeWidth),
      );
    }
    polyLines = await loadPolyLinesLocal(driveId, type: 1);
    for (int i = 0; i < polyLines.length; i++) {
      // pointsOfInterest[polylines[i].pointOfInterestIndex].id
      // polyLines.pointOfInterestIndex is its pointOfInterest.id
      _goodRoads.add(
        mt.Route(
            id: -1,
            points: polyLines[i].points,
            color: polyLines[i].color,
            borderColor: polyLines[i].color,
            strokeWidth: polyLines[i].strokeWidth,
            pointOfInterestIndex: polyLines[i].pointOfInterestIndex), // id
      );
    }
  }

  Future<bool> publish({bool fromLocal = true}) async {
    if (fromLocal) {
      await loadLocal(_id);
    }
    var uuid = const Uuid();
    Map<String, dynamic> response = await postDriveHeader();
    if (response['status'] == 'OK') {
      _driveUri = response['uri'];

      for (PointOfInterest pointOfInterest in _pointsOfInterest) {
        pointOfInterest.driveUri = _driveUri;
        // need to link the point of interest to the good road
        // so will put the uuid in here rather than API
        // uuid.v7() returns a uuid with -s 019523a6-a2ed-7a9a-8635-f003daee7f5e
        // so have to remove them with a replaceAll
        if (pointOfInterest.getType() == 13) {
          String uuidString = uuid.v7();
          pointOfInterest.url = uuidString.replaceAll(RegExp(r'-'), '');
          debugPrint('Point of interest url set to ${pointOfInterest.url}');
        }

        await postPointOfInterest(pointOfInterest, _driveUri);
      }

      // pointsOfInterest[polylines[i].pointOfInterestIndex].id
      // polyLines.pointOfInterestIndex is its pointOfInterest.id
      for (mt.Route route in _goodRoads) {
        for (PointOfInterest pointOfInterest in _pointsOfInterest) {
          if (pointOfInterest.id == route.pointOfInterestIndex) {
            // pick up the point of interest uuid
            route.pointOfInterestUri = pointOfInterest.url;
            debugPrint('route.interestUri set to ${pointOfInterest.url}');
            break;
          }
        }
      }

      for (int i = 0; i < 2; i++) {
        await postPolylines(
            polylines: i == 0 ? _routes : _goodRoads,
            driveUid: _driveUri,
            type: i);
      }

      postManeuvers(_maneuvers, _driveUri);

      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> postDriveHeader() async {
    List<Photo> photos = photosFromJson(_images);
    double maxLat = -90;
    double minLat = 90;
    double maxLong = -180;
    double minLong = 180;
    for (mt.Route polyline in routes()) {
      for (LatLng point in polyline.points) {
        maxLat = point.latitude > maxLat ? point.latitude : maxLat;
        minLat = point.latitude < minLat ? point.latitude : minLat;
        maxLong = point.longitude > maxLong ? point.longitude : maxLong;
        minLong = point.longitude < minLong ? point.longitude : minLong;
      }
    }

    var request = http.MultipartRequest('POST', Uri.parse('$urlDrive/add'));

    dynamic response;

    try {
      request.headers['Authorization'] = 'Bearer ${Setup().jwt}';
      request.files
          .add(await http.MultipartFile.fromPath('file', photos[0].url));
      request.fields['title'] = _heading;
      request.fields['sub_title'] = _subHeading;
      request.fields['body'] = _body;
      request.fields['distance'] = _distance.toString();
      request.fields['pois'] = _pointsOfInterest.length.toString();
      request.fields['score'] = '5';
      request.fields['max_lat'] = maxLat.toString();
      request.fields['min_lat'] = minLat.toString();
      request.fields['max_long'] = maxLong.toString();
      request.fields['min_long'] = minLong.toString();
      request.fields['added'] = DateTime.now().toString();

      response = await request.send().timeout(const Duration(seconds: 30));
    } catch (e) {
      if (e is TimeoutException) {
        return {'status': 'failed', 'error': 'timed out'};
      } else {
        return {'status': 'failed', 'error': e.toString()};
      }
    }

    if ([200, 201].contains(response.statusCode)) {
      // 201 = Created
      dynamic responseData = await response.stream.bytesToString();
      // debugPrint('Server response: $responseData');
      return jsonDecode(responseData);
    } else {
      return {
        'status': 'failed',
        'error': 'status code ${response.statusCode}'
      };
    }
  }
}
