import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:drives/models.dart';
import 'package:drives/services/db_helper.dart';

/// Autocomplete API uses https://photon.komoot.io
/// eg - https://photon.komoot.io/api/?q=staines
///
///

// Future<Map<String, dynamic>> getSuggestions(String value) async {

const List<String> settlementTypes = ['city', 'town', 'village', 'hamlet'];

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
            child: Row(children: [
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
            ])));
  }

  void clearSelections() {
    textEditingController.text = '';
    autoCompleteData.clear();
  }
}

//final apiUrl = 'http://10.101.1.150:5000/v1/user/register/';
const urlBase = 'http://10.101.1.150:5000/';

Future<String> postUser(User user) async {
  Map<String, dynamic> userMap = user.toMap();
  final http.Response response =
      await http.post(Uri.parse('${urlBase}v1/user/register/'),
          headers: <String, String>{
            "Content-Type": "application/json; charset=UTF-8",
          },
          body: jsonEncode(userMap));
  if (response.statusCode == 201) {
    // 201 = Created
    debugPrint('User posted OK');
    Map<String, dynamic> map = jsonDecode(response.body);
    Setup().jwt = map['token'];
    await updateSetup();

    return jsonEncode({'token': Setup().jwt, 'code': response.statusCode});
  } else {
    debugPrint('Failed to post user');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

/*
      'id': id,
      'user_id': userId,
      'title': title,
      'sub_title': subTitle,
      'body': body,
      'added': added.toString(),
      'map_image': images,
      'distance': distance,
      'points_of_interest': pois,

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
*/

Future<dynamic> postTrip(MyTripItem tripItem) async {
  Map<String, dynamic> map = tripItem.toMap();
  List<Photo> photos = photosFromJson(tripItem.images);

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
    request.fields['points_of_interest'] =
        map['pointsOfInterest'].length.toString();
    request.fields['score'] = '5';
    // map['scored'] ?? '5';
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
  List<Photo> photos = photosFromJson(pointOfInterest.images);

  var request = http.MultipartRequest(
      'POST', Uri.parse('${urlBase}v1/point_of_interest/add'));

  for (Photo photo in photos) {
    request.files.add(await http.MultipartFile.fromPath('files', photo.url));
  }
  var response;
  String jwToken = Setup().jwt;
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

///      'drive_id': driveId,
///      'points': pointsToString(polylines[i].points),
///      'stroke': polylines[i].strokeWidth,
///      'color': uiColours.keys

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

Future<String> postPolylines(List<Polyline> polylines, String driveUid) async {
  List<Map<String, dynamic>> maps = [];
  for (Polyline polyline in polylines) {
    maps.add({
      'drive_id': driveUid,
      'points': pointsToString(polyline.points),
      'stroke': polyline.strokeWidth,
      'colour':
          uiColours.keys.toList().indexWhere((col) => col == polyline.color),
    });
  }
  if (polylines.isEmpty) {
    return jsonEncode({'message': 'no polylines to post'});
  }
  final http.Response response =
      await http.post(Uri.parse('${urlBase}v1/polyline/add'),
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
  if (response.statusCode == 201) {
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
    maps.add({
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
