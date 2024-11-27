import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:drives/screens/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:drives/models/models.dart';
import 'package:drives/classes/utilities.dart' as utils;
import 'package:drives/services/db_helper.dart';
import 'package:drives/classes/route.dart' as mt;

/// Autocomplete API uses https://photon.komoot.io
/// eg - https://photon.komoot.io/api/?q=staines
///
///

// Future<Map<String, dynamic>> getSuggestions(String value) async {

Map<String, String> secureHeader() {
  String jwToken = Setup().jwt;
  return {
    'Authorization': 'Bearer $jwToken', // $Setup().jwt',
    'Content-Type': 'application/json',
  };
}

const List<String> settlementTypes = ['city', 'town', 'village', 'hamlet'];
DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
RegExp emailRegex = RegExp(r'[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

enum LoginState { ok, badPassword, badEmail }

Future<List<String>> getSuggestions(String value) async {
  String baseURL = 'https://photon.komoot.io/api/?q=$value';
  List<String> suggestions = [''];
  var url = Uri.parse(baseURL);
  if (value.length > 2) {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      dynamic jResponse = json.decode(response.body);
      for (int i = 0; i < jResponse["features"].length; i++) {
        if (settlementTypes
            .contains(jResponse["features"][i]["properties"]["type"])) {
          suggestions.add(jResponse["features"][i]["properties"]["name"] +
              ' ' +
              (jResponse["features"][i]["properties"]["county"] ?? "") +
              ' ' +
              (jResponse["features"][i]["properties"]["state"] ?? ""));
        }
      }
    }
  }
  return suggestions;
}

Future<LatLng> getPosition(String value) async {
  String baseURL = 'https://photon.komoot.io/api/?q=$value&limit=1';
  LatLng pos = const LatLng(0.00, 0.00);
  var url = Uri.parse(baseURL);
  if (value.length > 2) {
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        dynamic jResponse = json.decode(response.body);
        pos = LatLng(jResponse["features"][0]["geometry"]["coordinates"][1],
            jResponse["features"][0]["geometry"]["coordinates"][0]);
      }
    } catch (e) {
      String error = e.toString();
      debugPrint('getPosition() error: $error');
    }
  }
  return pos;
}

class SearchLocation extends StatefulWidget {
  final Function onSelect;
  const SearchLocation({super.key, required this.onSelect});
  @override
  State<SearchLocation> createState() => _searchLocationState();
}

class _searchLocationState extends State<SearchLocation> {
  List<String> autoCompleteData = [];
  String waypoint = '';
  LatLng location = const LatLng(0.00, 0.00);
  late TextEditingController textEditingController;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: MediaQuery.of(context).size.width - 50,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.blue,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(20))),
      // color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
        child: Row(
          children: [
            const Expanded(
              flex: 1,
              child: Icon(Icons.search),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
                flex: 14,
                child: Autocomplete(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    autoCompleteData =
                        await getSuggestions(textEditingValue.text);
                    setState(() {
                      waypoint = textEditingValue.text;
                    });
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    } else {
                      return autoCompleteData.where((word) => word
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    }
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                    textEditingController = controller;
                    return TextFormField(
                        textCapitalization: TextCapitalization.characters,
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                            hintText: 'Search for place name'));
                  },
                  onSelected: (String selection) async {
                    clearSelections();
                    LatLng pos = await getPosition(selection);
                    widget.onSelect(pos);
                  },
                )),
            const SizedBox(
              width: 10,
            ),
          ],
        ),
      ),
    );
  }

  void clearSelections() {
    textEditingController.text = '';
    autoCompleteData.clear();
  }
}

//final apiUrl = 'http://10.101.1.150:5000/v1/user/register/';
const urlBase = 'http://10.101.1.150:5001/'; // Home network
// const urlBase = 'http://192.168.1.13:5000/'; // Boston
// const urlBase = 'http://192.168.1.10:5000/'; // Boston
// const urlBase = 'http://192.168.68.104:5001/'; // Douglas Lodge
// const urlBase = 'http://192.168.0.10:5001/'; // Nikki's place

Future<Map<String, dynamic>> postUser(
    {required User user, bool register = false}) async {
  Map<String, dynamic> userMap = user.toMap();
  Map<String, dynamic> map = {'message': ''};
  // bool register = user.password.length <= 6;
  try {
    var url = Uri.parse('${urlBase}v1/user/${register ? "register" : "login"}');
    final http.Response response = await http
        .post(url,
            headers: <String, String>{
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: jsonEncode(userMap))
        .timeout(const Duration(seconds: 30));
    Map<String, dynamic> map = jsonDecode(response.body);
    if ([200, 201].contains(response.statusCode)) {
      Setup().jwt = map['token'];
      /*
      if (!register) {
        Setup().user
          ..forename = map['forename']
          ..surname = map['surname']
          ..email = user.email
          ..password = user.password;
          _SimpleUri (http://10.101.1.150:5001/v1/user/login)
        Setup().s etupToDb();
      }
      await insertSetup(Setup());
      */
      return {'msg': 'OK'};
    } else {
      return map;
    }
  } catch (e) {
    debugPrint('Login error: ${e.toString()}');
  }
  return map;
}

Future<Map<String, dynamic>> tryLogin({required User user}) async {
  Map<String, dynamic> userMap = user.toMap();
  Map<String, dynamic> map = {'message': ''};
  bool register = user.password.length <= 6;
  try {
    var url = Uri.parse('${urlBase}v1/user/${register ? "register" : "login"}');
    final http.Response response = await http
        .post(url,
            headers: <String, String>{
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: jsonEncode(userMap))
        .timeout(const Duration(seconds: 30));
    Map<String, dynamic> map = jsonDecode(response.body);
    if (response.statusCode == 201) {
      Setup().jwt = map['token'];
      return {'msg': 'OK'};
    } else {
      return {'msg': map['message'] ?? 'error'};
    }
  } catch (e) {
    debugPrint('Login error: ${e.toString()}');
  }
  return map;
}

Future<dynamic> postTrip(MyTripItem tripItem) async {
  Map<String, dynamic> map = tripItem.toMap();
  List<Photo> photos = photosFromJson(tripItem.getImages());
  double maxLat = -90;
  double minLat = 90;
  double maxLong = -180;
  double minLong = 180;
  for (mt.Route polyline in tripItem.routes()) {
    for (LatLng point in polyline.points) {
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLong = point.longitude > maxLong ? point.longitude : maxLong;
      minLong = point.longitude < minLong ? point.longitude : minLong;
    }
  }

  var request =
      http.MultipartRequest('POST', Uri.parse('${urlBase}v1/drive/add'));

  ///  for (Photo photo in photos) {
  ///    request.files.add(await http.MultipartFile.fromPath('files', photo.url));
  /// "ClientException with SocketException: Broken pipe (OS Error: Broken pipe, errno = 32), address = 10.101.1.150, port = 58368, uri…"
  /// }
  var response;
  String jwToken = Setup().jwt;
  try {
    request.files.add(await http.MultipartFile.fromPath('file', photos[0].url));
    request.fields['title'] = map['heading'];
    request.fields['sub_title'] = map['subHeading'];
    request.fields['body'] = map['body'];
    request.fields['distance'] = map['distance'].toString();
    request.fields['pois'] = map['pointsOfInterest'].toString();
    request.fields['score'] = '5';
    request.fields['max_lat'] = maxLat.toString();
    request.fields['min_lat'] = minLat.toString();
    request.fields['max_long'] = maxLong.toString();
    request.fields['min_long'] = minLong.toString();
    request.fields['added'] = DateTime.now().toString();

    request.headers['Authorization'] = 'Bearer $jwToken';

    response = await request.send().timeout(const Duration(seconds: 30));
  } catch (e) {
    String err = e.toString();
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting trip: $err');
    }
  }

  if ([200, 201].contains(response.statusCode)) {
    // 201 = Created
    var responseData = await response.stream.bytesToString();
    debugPrint('Server response: $responseData');
    return jsonDecode(responseData);
  } else {
    debugPrint('Failed to post trip: ${response.statusCode}');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

///      'id': id,
///      'useId': userId,
///      'driveId': driveId,
///      'type': type,
///      'name': name,
///      'description': description,
///      'latitude': markerPoint.latitude,
///      'longitude': markerPoint.longitude,

Future<String> postPointOfInterest(
    PointOfInterest pointOfInterest, String tripUri) async {
  Map<String, dynamic> map = pointOfInterest.toMap();
  List<Photo> photos = photosFromJson(pointOfInterest.getImages());

  var request = http.MultipartRequest(
      'POST', Uri.parse('${urlBase}v1/point_of_interest/add'));

  for (Photo photo in photos) {
    request.files.add(await http.MultipartFile.fromPath('files', photo.url));
  }
  dynamic response;
  // String jwToken = Setup().jwt;
  try {
    request.fields['drive_id'] = tripUri;
    request.fields['name'] = map['name'];
    request.fields['description'] = map['description'];
    request.fields['type'] = map['type'].toString();
    request.fields['latitude'] = map['latitude'].toString();
    request.fields['longitude'] = map['longitude'].toString();

    response = await request.send().timeout(const Duration(seconds: 30));
  } catch (e) {
    String err = e.toString();
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting trip: $err');
    }
  }

  if (response.statusCode == 201) {
    // 201 = Created
    debugPrint('Point of interest posted OK');
    var responseData = await response.stream.bytesToString();
    debugPrint('Server response: $responseData');
    return jsonEncode(responseData);
  } else {
    debugPrint('Failed to post point_of_interest: ${response.statusCode}');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

/*
Future<String> postPolyline(Polyline polyline, String driveUid) async {
  Map<String, dynamic> map = {
    'drive_id': driveUid,
    'points': pointsToString(polyline.points),
    'stroke': polyline.strokeWidth,
    'color': uiColours.keys.toList().indexWhere((col) => col == polyline.color),
  };

  final http.Response response =
      await http.post(Uri.parse('${urlBase}v1/polyline/add'),
          headers: <String, String>{
            "Content-Type": "application/json; charset=UTF-8",
          },
          body: jsonEncode(map));
  if (response.statusCode == 201) {
    // 201 = Created
    debugPrint('Polyline posted OK');
    return jsonEncode({'code': response.statusCode});
  } else {
    debugPrint('Failed to post user');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}
*/
Future<String> postPolylines(
    List<Polyline> polylines, String driveUid, int type) async {
  List<Map<String, dynamic>> maps = [];
  for (Polyline polyline in polylines) {
    maps.add({
      'drive_id': driveUid,
      'points': pointsToString(polyline.points),
      'stroke': polyline.strokeWidth,
      'colour':
          uiColours.keys.toList().indexWhere((col) => col == polyline.color),
    });
    if (type == 1) {
      double maxLat = -90;
      double minLat = 90;
      double maxLong = -180;
      double minLong = 180;
      for (LatLng point in polyline.points) {
        maxLat = point.latitude > maxLat ? point.latitude : maxLat;
        minLat = point.latitude < minLat ? point.latitude : minLat;
        maxLong = point.longitude > maxLong ? point.longitude : maxLong;
        minLong = point.longitude < minLong ? point.longitude : minLong;
      }
      maps[maps.length - 1]['max_lat'] = maxLat.toString();
      maps[maps.length - 1]['min_lat'] = minLat.toString();
      maps[maps.length - 1]['max_long'] = maxLong.toString();
      maps[maps.length - 1]['min_long'] = minLong.toString();
    }
  }
  if (polylines.isEmpty) {
    return jsonEncode({'message': 'no polylines to post'});
  }
  final http.Response response = await http.post(
      Uri.parse('${urlBase}v1/${type == 0 ? 'polyline' : 'good_road'}/add'),
      headers: <String, String>{
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonEncode(maps));
  if (response.statusCode == 201) {
    // 201 = Created
    debugPrint('Polyline posted OK');
    return jsonEncode({'code': response.statusCode});
  } else {
    debugPrint('Failed to post user');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

Future<List<mt.Route>> getGoodRoads(LatLng ne, LatLng sw) async {
  List<mt.Route> goodRoads = [];
  // String jwToken = Setup().jwt;
  final http.Response response = await http
      .get(
        Uri.parse(
            '${urlBase}v1/good_road/location/${sw.latitude}/${ne.latitude}/${sw.longitude}/${ne.longitude}'),
        //'/location/<min_lat>/<max_lat>/<min_long>/<max_long>'
        headers: secureHeader(),
      )
      .timeout(const Duration(seconds: 20));
  if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
    List polyline = jsonDecode(response.body);
    for (int i = 0; i < polyline.length; i++) {
      goodRoads.add(
        mt.Route(
          id: -1,
          points: stringToPoints(polyline[i]['points']), // routePoints,
          colour: uiColours.keys.toList()[Setup()
              .goodRouteColour], //     int.parse(polyline[i]['colour'])],
          borderColour: uiColours.keys.toList()[Setup().goodRouteColour],
          strokeWidth: (int.parse(polyline[i]['stroke'])).toDouble(),
        ),
      );
    }
  }

  return goodRoads;
}

Future<List<PointOfInterest>> getPointsOfInterest(ne, sw) async {
  List<PointOfInterest> pointsOfInterest = [];

  final http.Response response = await http
      .get(
        Uri.parse(
            '${urlBase}v1/point_of_interest/location/${sw.latitude}/${ne.latitude}/${sw.longitude}/${ne.longitude}'),
        //'/location/<min_lat>/<max_lat>/<min_long>/<max_long>'
        headers: secureHeader(),
      )
      .timeout(const Duration(seconds: 20));
  if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
    List pois = jsonDecode(response.body);
    for (int i = 0; i < pois.length; i++) {
      pointsOfInterest.add(
        PointOfInterest(
          -1,
          -1,
          pois[i]['_type'],
          pois[i]['name'],
          pois[i]['description'],
          30,
          30,
          images: pois[i]['images'],
          markerPoint: LatLng(pois[i]['latitude'], pois[i]['longitude']),
          marker: MarkerWidget(
            type: pois[i]['_type'],
            name: pois[i]['name'],
            description: pois[i]['description'],
            url: pois[i]['id'],
            images: pois[i]['images'],
//'${urlBase}v1/drive/images${pointOfInterest.url}$pic')
            imageUrls:
                webUrls(pois[i]['drive_id'], pois[i]['id'], pois[i]['images']),
            angle: 0, // degrees to radians
            list: 1,
            listIndex: i,
          ),
        ),
      );
    }
  }

  return pointsOfInterest;
}

List<String> webUrls(
    String driveUri, String pointOfInterestUri, String uriString) {
  if (uriString.length > 4) {
    List<String> files = [uriString.substring(2, uriString.length - 2)];
    List<String> urls = [
      for (String file in files)
        '${urlBase}v1/drive/images/$driveUri/$pointOfInterestUri/$file'
    ];
    return urls;
  }
  return [];
}

// "http://10.101.1.150:5000/v1/drive/images/712c8d58e7d84491bba6fdb5507ea5ac/0081b165074f4d218c2db5ecafffd1b3/e9cbc367-236b-4dde-994d-e19fb43c1092.jpg"
Future<String> postManeuver(Maneuver maneuver, String driveUid) async {
  Map<String, dynamic> map = {
    'drive_id': driveUid,
    'road_from': maneuver.roadFrom,
    'road_to': maneuver.roadTo,
    'bearing_before': maneuver.bearingBefore,
    'bearing_after': maneuver.bearingAfter,
    'exit': maneuver.exit,
    'location': maneuver.location.toString(),
    'modifier': maneuver.modifier,
    'type': maneuver.type,
    'distance': maneuver.distance
  };

  final http.Response response =
      await http.post(Uri.parse('${urlBase}v1/maneuver/add'),
          headers: <String, String>{
            "Content-Type": "application/json; charset=UTF-8",
          },
          body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    // 201 = Created
    debugPrint('Maneuver posted OK');
    return jsonEncode({'code': response.statusCode});
  } else {
    debugPrint('Failed to post maneuver');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

Future<String> postManeuvers(List<Maneuver> maneuvers, String driveUid) async {
  List<Map<String, dynamic>> maps = [];
  for (Maneuver maneuver in maneuvers) {
    String pos =
        '{"lat":${maneuver.location.latitude}, "long":${maneuver.location.longitude}}';
    maps.add({
      'drive_id': driveUid,
      'road_from': maneuver.roadFrom,
      'road_to': maneuver.roadTo,
      'bearing_before': maneuver.bearingBefore,
      'bearing_after': maneuver.bearingAfter,
      'exit': maneuver.exit,
      'location': pos,
      'modifier': maneuver.modifier,
      'type': maneuver.type,
      'distance': maneuver.distance
    });
  }
  if (maps.isEmpty) {
    return jsonEncode({'message': 'no maneuvers to post'});
  }
  final http.Response response =
      await http.post(Uri.parse('${urlBase}v1/maneuver/add'),
          headers: <String, String>{
            "Content-Type": "application/json; charset=UTF-8",
          },
          body: jsonEncode(maps));
  if (response.statusCode == 201) {
    // 201 = Created
    debugPrint('Maneuver posted OK');
    return jsonEncode({'code': response.statusCode});
  } else {
    debugPrint('Failed to post maneuver');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

Future<List<TripItem>> getTrips() async {
  List<TripItem> trips = [];
  var currentPosition = await utils.getPosition();
  LatLng pos = LatLng(currentPosition.latitude, currentPosition.longitude);

  final http.Response response = await http
      .get(
        Uri.parse('${urlBase}v1/drive/all'),
        headers: secureHeader(),
      )
      .timeout(const Duration(seconds: 20));
  if (response.statusCode == 200) {
    List<dynamic> tripsJson = jsonDecode(response.body);
    //  List<String> images = ['map'];
    // "http://10.101.1.150:5000/v1/drive/images/0175c09062b7485aaf8356f3770b7ca8/map.png"
    // "http://10.101.1.150:5000/v1/drive/images/0175c09062b7485aaf8356f3770b7ca8/b56dc5ebfe35450f9077cb5dce53e0d4/2a6bf728-8f4e-4993-9c…"
    // pics[j] "2a6bf728-8f4e-4993-9c00-9f2512bf0edf.jpg"
    for (Map<String, dynamic> trip in tripsJson) {
      List<String> images = [
        Uri.parse('${urlBase}v1/drive/images/${trip['id']}/map.png').toString()
      ];
      try {
        int distance = 99999;
        for (int i = 0; i < trip['points_of_interest'].length; i++) {
          if (trip['points_of_interest'][i]['images'].length > 0) {
            var pics = jsonDecode(trip['points_of_interest'][i]['images']);
            for (int j = 0; j < pics.length; j++) {
              images.add(Uri.parse(
                      '${urlBase}v1/drive/images/${trip['id']}/${trip['points_of_interest'][i]['id']}/${pics[j]}')
                  .toString());
              // debugPrint(images[images.length - 1]);
            }
          }
          LatLng poiPos = LatLng(trip['points_of_interest'][i]['latitude'],
              trip['points_of_interest'][i]['longitude']);
          distance = min(utils.distanceBetween(poiPos, pos).toInt(), distance);
        }
        trips.add(TripItem(
            heading: trip['title'],
            subHeading: trip['sub_title'],
            body: trip['body'],
            author: trip['author'],
            published: trip['added'],
            imageUrls: images,
            score: trip['average_rating'].toDouble() ?? 5.0,
            distance: trip['distance'],
            pointsOfInterest: trip['points_of_interest'].length,
            closest: distance,
            scored: trip['ratings_count'] ?? 1,
            downloads: trip['download_count'] ?? 0,
            uri: trip['id']));
      } catch (e) {
        String err = e.toString();
        debugPrint('Error: $err');
      }
    }
  }
  return trips;
}

Future<TripItem> getTrip({required tripId}) async {
  TripItem gotTrip = TripItem(heading: '');
  if (tripId.length == 32) {
    var currentPosition = await utils.getPosition();
    LatLng pos = LatLng(currentPosition.latitude, currentPosition.longitude);

    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/drive/summary/$tripId'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      var trip = jsonDecode(response.body);
      //  List<String> images = ['map'];
      // "http://10.101.1.150:5000/v1/drive/images/0175c09062b7485aaf8356f3770b7ca8/map.png"
      // "http://10.101.1.150:5000/v1/drive/images/0175c09062b7485aaf8356f3770b7ca8/b56dc5ebfe35450f9077cb5dce53e0d4/2a6bf728-8f4e-4993-9c…"
      // pics[j] "2a6bf728-8f4e-4993-9c00-9f2512bf0edf.jpg"

      List<String> images = [
        Uri.parse('${urlBase}v1/drive/images/${trip['id']}/map.png').toString()
      ];
      try {
        int distance = 99999;
        for (int i = 0; i < trip['points_of_interest'].length; i++) {
          if (trip['points_of_interest'][i]['images'].length > 0) {
            var pics = jsonDecode(trip['points_of_interest'][i]['images']);
            for (int j = 0; j < pics.length; j++) {
              images.add(Uri.parse(
                      '${urlBase}v1/drive/images/${trip['id']}/${trip['points_of_interest'][i]['id']}/${pics[j]}')
                  .toString());
              // debugPrint(images[images.length - 1]);
            }
          }
          LatLng poiPos = LatLng(trip['points_of_interest'][i]['latitude'],
              trip['points_of_interest'][i]['longitude']);
          distance = min(utils.distanceBetween(poiPos, pos).toInt(), distance);
        }
        gotTrip = TripItem(
            heading: trip['title'],
            subHeading: trip['sub_title'],
            body: trip['body'],
            author: trip['author'],
            published: trip['added'],
            imageUrls: images,
            score: trip['average_rating'].toDouble() ?? 5.0,
            distance: trip['distance'],
            pointsOfInterest: trip['points_of_interest'].length,
            closest: distance,
            scored: trip['ratings_count'] ?? 1,
            downloads: trip['download_count'] ?? 0,
            uri: trip['id']);
      } catch (e) {
        String err = e.toString();
        debugPrint('Error: $err');
      }
    }
  }
  return gotTrip;
}

Future<Uint8List> getImageBytes({required String url}) async {
  Uint8List data = Uint8List.fromList([]);
  final response =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
  if (response.statusCode == 200) {
    data = response.bodyBytes;
  }
  return data;
}

Future<void> getAndSaveImage(
    {required String url, required String filePath}) async {
  final response =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
  if (response.statusCode == 200) {
    // Get the document directory path
    // final directory = await getApplicationDocumentsDirectory();
    // Construct the file path for saving the image
    // final filePath = '${directory.path}/saved_image.png';

    // Write the image data to the file
    // "/data/user/0/com.example.drives/app_flutter/drive3/3f6c5f2e-d164-4349-8a30-1085d643387c.jpg"
    try {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      if (file.existsSync()) {
        debugPrint('Image file $url exists');
      }
    } catch (e) {
      debugPrint('Error writing image file: ${e.toString()}');
    }
  }

  return;
}

putDriveRating(String uri, int score) async {
  Map<String, dynamic> map = {
    'drive_id': uri,
    'rating': score,
    'comment': '',
    'rated': DateTime.now().toString()
  };
  final http.Response response = await http.post(
      Uri.parse('${urlBase}v1/drive_rating/add'),
      headers: secureHeader(),
      body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    debugPrint('Score added OK: ${response.statusCode}');
  }
}

putPointOfInterestRating(String uri, int score) async {
  // uri = uri.substring(1, uri.length - 1);
  uri = uri.substring(uri.indexOf('/') + 1);
  Map<String, dynamic> map = {
    'point_of_interest_id': uri,
    'rating': score,
    'comment': '',
    'rated': DateTime.now().toString()
  };
  final http.Response response = await http.post(
      Uri.parse('${urlBase}v1/point_of_interest_rating/add'),
      headers: secureHeader(),
      body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    debugPrint('Score added OK: ${response.statusCode}');
  }
}

Future<Map<String, dynamic>> getPointOfInterestRating(String uri) async {
  Map<String, dynamic> rating = {'rating': '0'};
  final http.Response response = await http
      .get(
        Uri.parse('${urlBase}v1/point_of_interest_rating/$uri'),
        headers: secureHeader(),
      )
      .timeout(const Duration(seconds: 10));
  if (response.statusCode == 200) {
    rating = jsonDecode(response.body);
  }

  return rating;
}

Future<MyTripItem> getTripSummary(String tripUuid) async {
  MyTripItem myTrip = MyTripItem(heading: '', subHeading: '');

  final http.Response response = await http.get(
    Uri.parse('${urlBase}v1/drive/$tripUuid'),
    headers: secureHeader(),
  );
  if (response.statusCode == 200) {
    Map<String, dynamic> trip = jsonDecode(response.body);
    List<PointOfInterest> gotPointsOfInterest = [];

    try {
      for (int i = 0; i < trip['points_of_interest'].length; i++) {
        try {
          LatLng posn = LatLng(trip['points_of_interest'][i]['latitude'],
              trip['points_of_interest'][i]['longitude']);
          Widget marker = MarkerWidget(
            type: trip['points_of_interest'][i]['_type'],
            list: 0,
            listIndex: i,
          );
          gotPointsOfInterest.add(PointOfInterest(
            -1,
            -1,
            trip['points_of_interest'][i]['_type'],
            trip['points_of_interest'][i]['name'],
            trip['points_of_interest'][i]['description'],
            trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            images: trip['points_of_interest'][i]['images'],
            url: '/${trip['id']}/${trip['points_of_interest'][i]['id']}/',
            score: trip['points_of_interest'][i]['average_rating'] ?? 1,
            scored: trip['points_of_interest'][i]['ratings_count'] ?? 0,
            markerPoint: posn,
            marker: marker,
          ));
        } catch (e) {
          debugPrint('Error: ${e.toString()}');
        }
      }
    } catch (e) {
      String err = e.toString();
      debugPrint('PointsOfInterest error: $err');
    }
    try {
      MyTripItem myTripItem = MyTripItem(
        heading: trip['title'],
        driveUri: tripUuid,
        subHeading: trip['sub_title'],
        body: trip['body'],
        published: trip['added'],
        images: Uri.parse('${urlBase}v1/drive/images/${trip['id']}/map.png')
            .toString(),
        score: trip['score'] ?? 5.0,
        distance: trip['distance'],
        pointsOfInterest: gotPointsOfInterest,
        closest: 12,
      );
      return myTripItem;
    } catch (e) {
      String err = e.toString();
      debugPrint('Error: $err');
    }
  }
  return myTrip;
}

Future<MyTripItem> getMyTrip(String tripUuid) async {
  MyTripItem myTrip = MyTripItem(heading: '', subHeading: '');

  final http.Response response = await http.get(
    Uri.parse('${urlBase}v1/drive/$tripUuid'),
    headers: secureHeader(),
  );
  if (response.statusCode == 200) {
    Map<String, dynamic> trip = jsonDecode(response.body);
    List<mt.Route> gotRoutes = [];

    for (int i = 0; i < trip['polylines'].length; i++) {
      gotRoutes.add(mt.Route(
          id: -1,
          points:
              stringToPoints(trip['polylines'][i]['points']), // routePoints,
          colour: uiColours.keys.toList()[trip['polylines'][i]['colour']],
          borderColour: uiColours.keys.toList()[trip['polylines'][i]['colour']],
          strokeWidth: (trip['polylines'][i]['stroke']).toDouble()));
    }

    List<Maneuver> gotManeuvers = [];
    LatLng pos = const LatLng(0, 0);
    dynamic jsonPos;
    for (int i = 0; i < trip['maneuvers'].length; i++) {
      jsonPos = jsonDecode(trip['maneuvers'][i]['location']);
      pos = LatLng(jsonPos['lat'], jsonPos['long']);
      try {
        gotManeuvers.add(Maneuver(
          id: -1,
          driveId: -1, //trip['maneuvers'][i]['driveId'],
          roadFrom: trip['maneuvers'][i]['road_from'],
          roadTo: trip['maneuvers'][i]['road_to'],
          bearingBefore: trip['maneuvers'][i]['bearing_before'],
          bearingAfter: trip['maneuvers'][i]['bearing_after'],
          exit: trip['maneuvers'][i]['exit'],
          location: pos,
          modifier: trip['maneuvers'][i]['modifier'],
          type: trip['maneuvers'][i]['type'],
          distance: trip['maneuvers'][i]['distance'],
        ));
      } catch (e) {
        debugPrint('Error maneuvers: ${e.toString()}');
      }
    }

    /*
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
    */

    List<PointOfInterest> gotPointsOfInterest = [];

    try {
      for (int i = 0; i < trip['points_of_interest'].length; i++) {
        try {
          LatLng posn = LatLng(trip['points_of_interest'][i]['latitude'],
              trip['points_of_interest'][i]['longitude']);
          Widget marker = MarkerWidget(
            type: trip['points_of_interest'][i]['_type'],
            list: 0,
            listIndex: i,
          );
          gotPointsOfInterest.add(PointOfInterest(
            -1,
            -1,
            trip['points_of_interest'][i]['_type'],
            trip['points_of_interest'][i]['name'],
            trip['points_of_interest'][i]['description'],
            trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            images: trip['points_of_interest'][i]['images'],
            url: '/${trip['id']}/${trip['points_of_interest'][i]['id']}/',
            score: trip['points_of_interest'][i]['average_rating'] ?? 1,
            scored: trip['points_of_interest'][i]['ratings_count'] ?? 0,
            markerPoint: posn,
            marker: marker,
          ));
        } catch (e) {
          debugPrint('Error: ${e.toString()}');
        }
      }
    } catch (e) {
      String err = e.toString();
      debugPrint('PointsOfInterest error: $err');
    }
    try {
      MyTripItem myTripItem = MyTripItem(
        heading: trip['title'],
        driveUri: tripUuid,
        subHeading: trip['sub_title'],
        body: trip['body'],
        published: trip['added'],
        images: Uri.parse('${urlBase}v1/drive/images/${trip['id']}/map.png')
            .toString(),
        score: trip['score'] ?? 5.0,
        distance: trip['distance'],
        routes: gotRoutes,
        maneuvers: gotManeuvers,
        pointsOfInterest: gotPointsOfInterest,
        closest: 12,
      );
      return myTripItem;
    } catch (e) {
      String err = e.toString();
      debugPrint('Error: $err');
    }
  }
  return myTrip;
}

Future<List<GroupMember>> getIntroduced() async {
  List<GroupMember> introduced = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/introduced/get'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      var members = jsonDecode(response.body);

      introduced = [
        for (Map<String, dynamic> memberMap in members)
          GroupMember.fromMap(memberMap)
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return introduced;
}

putIntroduced(List<GroupMember> members) async {
  List<Map<String, dynamic>> maps = [];
  for (int i = 0; i < members.length; i++) {
    if (members[i].selected) {
      maps.add(members[i].toApiMap());
    }
  }

  final http.Response response = await http.post(
      Uri.parse('${urlBase}v1/introduced/put'),
      headers: secureHeader(),
      body: jsonEncode(maps));
  if ([200, 201].contains(response.statusCode)) {
    debugPrint('Member added OK: ${response.statusCode}');
  }
}

deleteWebImage(String url) async {
  final http.Response response = await http.post(Uri.parse(url),
      headers: secureHeader(), body: jsonEncode('"id": "delete_image"'));
  if ([200, 201].contains(response.statusCode)) {
    debugPrint('Member added OK: ${response.statusCode}');
  }
}

/// Returns SizedBox containing Image.network
/// Implements a circularProgress indicator while loading
/// Implements a dialog to delete onDoubleTap using InkWell
/// "http://10.101.1.150:5001/v1/shop_item/images/0673901ecf1e761f8000b9ac02b722d7/6eec1ec3-2c5b-4d7e-9c3b-5a28d1016bd9.jpg"
Widget showWebImage(String imageUrl,
    {BuildContext? context,
    double width = 200,
    int index = -1,
    Function(int)? onDelete}) {
  return SizedBox(
    key: Key('swi$index'),
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onDoubleTap: () async {
          if (onDelete != null && index > -1) {
            if (context != null) {
              bool? canDelete = await showDialog<bool>(
                context: context,
                builder: (context) => const OkCancelAlert(
                  title: 'Remove image?',
                  message: 'Deletes image on server ',
                ),
              );
              if (canDelete!) {
                deleteWebImage(imageUrl);
                onDelete(index);
              }
            } else {
              deleteWebImage(imageUrl);
              onDelete(index);
            }
          }
        },
        //  String imageUrl = 'http://10.101.1.150:5001/v1/shop_item/images/0673901ecf1e761f8000b9ac02b722d7/6eec1ec3-2c5b-4d7e-9c3b-5a28d1016bd9.jpg';
        child: Image.network(
          imageUrl,
          //   "http://10.101.1.150:5001/v1/shop_item/images/0673901ecf1e761f8000b9ac02b722d7/6eec1ec3-2c5b-4d7e-9c3b-5a28d1016bd9.jpg", //imageUrl,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
          },
        ),
      ),
    ),
  );
}

bool canDelete(bool ok, String url, int index) {
  if (ok) {
    debugPrint('Can delete');
    return true;
  } else {
    debugPrint("Can't delete");
    return false;
  }
}

Future<List<Group>> getManagedGroups() async {
  List<Group> groupsSent = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/group/managed'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if ([200, 201].contains(response.statusCode)) {
      var groups = jsonDecode(response.body);
      groupsSent = [
        for (Map<String, dynamic> groupData in groups)
          Group.fromGroupSummaryMap(groupData)
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return groupsSent;
}

Future<List<GroupMember>> getManagedGroupMembers(String groupId) async {
  List<GroupMember> groupMembersSent = [];
  try {
    Uri uri = Uri.parse('${urlBase}v1/group_member/members/$groupId');
    final http.Response response = await http
        .get(
          uri,
          //  Uri.parse('${urlBase}v1/group_member/group/$groupId'),
          // "http://10.101.1.150:5000/v1/group_member/group/a9c4c22094b94dd58f852125b912487d"
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if ([200, 201].contains(response.statusCode)) {
      var groups = jsonDecode(response.body);
      for (Map<String, dynamic> groupData in groups) {
        debugPrint(groupData.toString());
      }
      groupMembersSent = [
        for (Map<String, dynamic> groupData in groups)
          GroupMember.fromApiMap(groupData)
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return groupMembersSent;
}

Future<List<Group>> getGroups() async {
  List<Group> groupsSent = [];

  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/group/get'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if ([200, 201].contains(response.statusCode)) {
      var groups = jsonDecode(response.body);
      groupsSent = [
        for (Map<String, dynamic> groupData in groups) Group.fromMap(groupData)
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return groupsSent;
}

Future<List<Group>> getMyGroups() async {
  List<Group> groupsSent = [];

  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/group/mine'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      var groups = jsonDecode(response.body);
      groupsSent = [
        for (Map<String, dynamic> groupData in groups)
          Group.fromMyGroupsMap(groupData)
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return groupsSent;
}

Future<List<GroupDrive>> getGroupDrives() async {
  List<GroupDrive> groupsSent = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/group_drive/pending'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 30));
    if ([200, 201].contains(response.statusCode)) {
      List<dynamic> groups = jsonDecode(response.body);
      groupsSent = [
        for (Map<String, dynamic> map in groups) GroupDrive.fromMap(map)
      ];
    }
  } catch (e) {
    debugPrint("getGroupDrives error: ${e.toString()}");
  }
  return groupsSent;
}

Future<Map<String, dynamic>> deleteGroupDrive(
    {required String groupDriveId}) async {
  Map<String, dynamic> resp = {'msg': 'Failed'};

  var uri = Uri.parse('${urlBase}v1/group_drive/delete');

  final http.Response response = await http
      .post(uri,
          headers: secureHeader(),
          body: jsonEncode({'group_drive_id': groupDriveId}))
      .timeout(const Duration(seconds: 10));
  if ([200, 201].contains(response.statusCode)) {
    resp = {'msg': 'OK'};
    debugPrint('Member added OK: ${response.statusCode}');
  }

  return resp;
}

Future<List<Group>> getMessagesByGroup() async {
  List<Group> groupsSent = [];

  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/message/group_messages'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if ([200, 201].contains(response.statusCode)) {
      var groups = jsonDecode(response.body);
      groupsSent = [
        for (Map<String, dynamic> groupData in groups)
          Group(
            id: groupData['id'],
            name: groupData['name'],
            unreadMessages:
                groupData['messages'] - int.parse(groupData['read']),
            messages: groupData['messages'],
          )
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return groupsSent;
}

Future<List<Message>> getGroupMessages(Group group) async {
  List<Message> messagesSent = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/message/group/${group.id}'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if ([200, 201].contains(response.statusCode)) {
      var messages = jsonDecode(response.body);
      messagesSent = [
        for (Map<String, dynamic> messageData in messages)
          Message.fromMap(
            messageData,
          )
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return messagesSent;
}

Future<String> putMessage(Group group, Message message) async {
  Map<String, dynamic> map = {'group_id': group.id, 'message': message.message};
  final http.Response response = await http.post(
      Uri.parse('${urlBase}v1/message/add'),
      headers: secureHeader(),
      body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    var responseData = jsonDecode(String.fromCharCodes(response.bodyBytes));
    debugPrint('Server response: $responseData');
    return responseData.toString();
  }
  return '';
}

Future<String> putGroup(Group group) async {
  Map<String, dynamic> map = group.toMap();
  final http.Response response = await http.post(
      Uri.parse('${urlBase}v1/group/add'),
      headers: secureHeader(),
      body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    // var responseData = jsonDecode(String.fromCharCodes(response.bodyBytes));
    var responseData = jsonDecode(response.body);
    debugPrint('Server response: $responseData');
    group.id = responseData['id'];
    return responseData.toString();
  }
  return '';
}

/// getHomeItems gets a list of home articles for the home screen
/// The scope parameter isn't yet implemented, but is to allow
/// some selection of who sees what on the home page
///
Future<List<HomeItem>> getHomeItems(int scope) async {
  List<HomeItem> itemsSent = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/home_page_item/get/$scope'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 30));
    if ([200, 201].contains(response.statusCode)) {
      List<dynamic> items = jsonDecode(response.body);
      if (items.isNotEmpty) {
        itemsSent = [
          for (Map<String, dynamic> map in items) HomeItem.fromMap(map: map)
        ];
      }
    }
  } catch (e) {
    debugPrint("getGroupDrives error: ${e.toString()}");
  }
  return itemsSent;
}

Future<String> postHomeItem(HomeItem homeItem) async {
  Map<String, dynamic> map = homeItem.toMap();
  List<Photo> photos = photosFromJson(homeItem.imageUrl);

  var request = http.MultipartRequest(
      'POST', Uri.parse('${urlBase}v1/home_page_item/add'));

  List<String> imageUris = [];
  int newImageIndex = 0;
  for (Photo photo in photos) {
    if (photo.url.length > 40) {
      request.files.add(await http.MultipartFile.fromPath('files', photo.url));
      imageUris.add('new_image_${++newImageIndex}');
    } else {
      imageUris.add(photo.url);
    }
  }
  dynamic response;
  // String jwToken = Setup().jwt;
  try {
    request.fields['id'] = map['uri'];
    request.fields['title'] = map['heading'];
    request.fields['sub_title'] = map['subHeading'];
    request.fields['body'] = map['body'];
    request.fields['added'] = map['added'] ?? DateTime.now().toString();
    request.fields['score'] = map['score'].toString();
    request.fields['coverage'] = map['coverage'];
    request.fields['image_urls'] = imageUris.toString();

    response = await request.send().timeout(const Duration(seconds: 30));
  } catch (e) {
    String err = e.toString();
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting article: $err');
    }
  }

  if (response.statusCode == 201) {
    // 201 = Created
    debugPrint('Home article posted OK');
    var responseData = await response.stream.bytesToString();
    debugPrint('Server response: $responseData');
    return jsonEncode(responseData);
  } else {
    debugPrint('Failed to post home article: ${response.statusCode}');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

/// getShopItems gets a list of shop items for the shop screen
/// The scope parameter isn't yet implemented, but is to allow
/// some selection of who sees what on the shop page
Future<List<ShopItem>> getShopItems(int scope) async {
  List<ShopItem> itemsSent = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/shop_item/get/$scope'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 30));
    if ([200, 201].contains(response.statusCode)) {
      List<dynamic> items = jsonDecode(response.body);
      if (items.isNotEmpty) {
        itemsSent = [
          for (Map<String, dynamic> map in items) ShopItem.fromMap(map: map)
        ];
      }
    }
  } catch (e) {
    debugPrint("getGroupDrives error: ${e.toString()}");
  }
  return itemsSent;
}

Future<String> postShopItem(ShopItem shopItem) async {
  Map<String, dynamic> map = shopItem.toMap();
  List<Photo> photos = photosFromJson(shopItem.imageUrl);

  var request =
      http.MultipartRequest('POST', Uri.parse('${urlBase}v1/shop_item/add'));

  request.headers['Authorization'] = 'Bearer ${Setup().jwt}';
  List<String> imageUris = [];
  int newImageIndex = 0;
  for (Photo photo in photos) {
    if (photo.url.length > 40) {
      imageUris.add('new_image_${++newImageIndex}');
      request.files.add(await http.MultipartFile.fromPath('files', photo.url));
    } else {
      imageUris.add(photo.url);
    }
  }
  dynamic response;
  // String jwToken = Setup().jwt;
  //  request.body = jsonEncode(map));
  // request.fields.map((key, value) => null) = map;
  try {
    request.fields['id'] = map['uri'];
    request.fields['title'] = map['heading'];
    request.fields['sub_title'] = map['subHeading'];
    request.fields['body'] = map['body'];
    request.fields['added'] = map['added'] ?? DateTime.now().toString();
    request.fields['score'] = map['score'].toString();
    request.fields['coverage'] = map['coverage'];
    request.fields['image_urls'] = imageUris.toString();
    request.fields['button_text_1'] = map['buttonText1'];
    request.fields['url_1'] = map['url1'];
    request.fields['button_text_2'] = map['buttonText2'];
    request.fields['url_2'] = map['url2'];

    response = await request.send().timeout(const Duration(seconds: 30));
  } catch (e) {
    String err = e.toString();
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting article: $err');
    }
  }

  if (response.statusCode == 201) {
    // 201 = Created
    debugPrint('Shop item posted OK');
    var responseData = await response.stream.bytesToString();
    debugPrint('Server response: $responseData');
    return jsonEncode(responseData);
  } else {
    debugPrint('Failed to post shop item: ${response.statusCode}');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

Future<List<EventInvitation>> getInvitationssByUser() async {
  List<EventInvitation> invitationsSent = [];

  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/group_drive_invitation/user'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if ([200, 201].contains(response.statusCode)) {
      var invitations = jsonDecode(response.body);
      invitationsSent = [
        for (Map<String, dynamic> invitation in invitations)
          EventInvitation.fromByUserMap(invitation)
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return invitationsSent;
}

Future<List<EventInvitation>> getInvitationsByEvent(
    {String eventId = ''}) async {
  List<EventInvitation> invitationsSent = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/group_drive_invitation/trip/$eventId'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if ([200, 201].contains(response.statusCode)) {
      var invitations = jsonDecode(response.body);
      invitationsSent = [
        for (Map<String, dynamic> invitation in invitations)
          EventInvitation.fromByEventMap(invitation)
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web: ${e.toString()}");
  }
  return invitationsSent;
}

Future<List<EventInvitation>> getInvitationsToAlter(
    {String eventId = ''}) async {
  List<EventInvitation> invitationsSent = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/group_drive_invitation/alter/$eventId'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if ([200, 201].contains(response.statusCode)) {
      var invitations = jsonDecode(response.body);
      invitationsSent = [
        for (Map<String, dynamic> invitation in invitations)
          EventInvitation.fromByUserToAlterMap(invitation)
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web: ${e.toString()}");
  }
  return invitationsSent;
}

Future<String> postGroupDriveInvitations(
    List<EventInvitation> invitations) async {
  List<Map<String, dynamic>> map = [
    for (EventInvitation invite in invitations)
      if (invite.selected) invite.toMap()
  ];
  final http.Response response = await http.post(
      Uri.parse('${urlBase}v1/group_drive_invitation/update'),
      headers: secureHeader(),
      body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    // var responseData = jsonDecode(String.fromCharCodes(response.bodyBytes));
    var responseData = jsonDecode(response.body);
    debugPrint('Server response: $responseData');
    // group.id = responseData['id'];
    return responseData.toString();
  }
  return '';
}

Future<String> postGroupDrive(GroupDriveInvitation invitation) async {
  Map<String, dynamic> map = invitation.toMap();
  final http.Response response = await http.post(
      Uri.parse('${urlBase}v1/group_drive/add'),
      headers: secureHeader(),
      body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    // var responseData = jsonDecode(String.fromCharCodes(response.bodyBytes));
    var responseData = jsonDecode(response.body);
    debugPrint('Server response: $responseData');
    // group.id = responseData['id'];
    return responseData.toString();
  }
  return '';
}

Future<bool> answerInvitation(EventInvitation invitation) async {
  bool result = false;
  Map<String, dynamic> map = {
    'invitation_id': invitation.id,
    'response': invitation.accepted.toString()
  };

  final http.Response response = await http.post(
      Uri.parse('${urlBase}v1/group_drive_invitation/respond'),
      headers: secureHeader(),
      body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    debugPrint('invitation status updated OK: ${response.statusCode}');
    result = true;
  }

  return result;
}

Future<GroupMember> getUserByEmail(String email) async {
  GroupMember member = GroupMember(forename: '', surname: '');
  Map<String, dynamic> map = {'email': email};
  try {
    final http.Response response = await http
        .post(Uri.parse('${urlBase}v1/user/get_user_by_email'),
            headers: secureHeader(), body: jsonEncode(map))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      // var responseData = jsonDecode(String.fromCharCodes(response.bodyBytes));
      member = GroupMember.fromUserMap(responseData);
    }
  } catch (e) {
    debugPrint("Can't access data on the web: ${e.toString()}");
  }
  return member;
}

Future<List<GroupMember>> getGroupMembers() async {
  List<GroupMember> introduced = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('${urlBase}v1/introduced/get'),
          headers: secureHeader(),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      var members = jsonDecode(response.body);
      introduced = [
        for (Map<String, dynamic> memberMap in members)
          GroupMember.fromMap(memberMap)
      ];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return introduced;
}
