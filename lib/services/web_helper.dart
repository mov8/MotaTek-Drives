import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:drives/models.dart';
import 'package:drives/services/db_helper.dart';
import 'package:drives/route.dart' as mt;

/// Autocomplete API uses https://photon.komoot.io
/// eg - https://photon.komoot.io/api/?q=staines
///
///

// Future<Map<String, dynamic>> getSuggestions(String value) async {

const List<String> settlementTypes = ['city', 'town', 'village', 'hamlet'];
DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');

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
    request.fields['pois'] = map['pointsOfInterest'].length.toString();
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
  String jwToken = Setup().jwt;
  final http.Response response = await http.get(
    Uri.parse('${urlBase}v1/drive/all'),
    headers: {
      'Authorization': 'Bearer $jwToken', // $Setup().jwt',
      'Content-Type': 'application/json',
    },
  );
  if (response.statusCode == 200) {
    List<dynamic> tripsJson = jsonDecode(response.body);
    //  List<String> images = ['map'];

    for (Map<String, dynamic> trip in tripsJson) {
      List<String> images = [
        Uri.parse('${urlBase}v1/drive/images/${trip['id']}/map.png').toString()
      ];
      try {
        for (int i = 0; i < trip['points_of_interest'].length; i++) {
          if (trip['points_of_interest'][i]['images'].length > 0) {
            var pics = jsonDecode(trip['points_of_interest'][i]['images']);
            for (int j = 0; j < pics.length; j++) {
              images.add(Uri.parse(
                      '${urlBase}v1/drive/images/${trip['id']}/${trip['points_of_interest'][i]['id']}/${pics[j]}')
                  .toString());
              debugPrint(images[images.length - 1]);
            }
          }
        }
        trips.add(TripItem(
            heading: trip['title'],
            subHeading: trip['sub_title'],
            body: trip['body'],
            author: trip['author'],
            published: trip['added'],
            imageUrls: images,
            score: trip['score'] ?? 5.0,
            distance: trip['distance'],
            pointsOfInterest: trip['points_of_interest'].length,
            closest: 12,
            scored: trip['scored'] ?? 1,
            downloads: trip['downloads'] ?? 0,
            uri: trip['id']));
      } catch (e) {
        String err = e.toString();
        debugPrint('Error: $err');
      }
    }
  }
  return trips;
}

Future<MyTripItem> getTrip(String tripUuid) async {
  MyTripItem trip = MyTripItem(heading: '', subHeading: '');
  String jwToken = Setup().jwt;
  final http.Response response = await http.get(
    Uri.parse('${urlBase}v1/drive/$tripUuid'),
    headers: {
      'Authorization': 'Bearer $jwToken', // $Setup().jwt',
      'Content-Type': 'application/json',
    },
  );
  if (response.statusCode == 200) {
    Map<String, dynamic> trip = jsonDecode(response.body);
    List<mt.Route> gotRoutes = [];

    for (int i = 0; i < trip['polylines'].length; i++) {
      gotRoutes.add(mt.Route(
          id: -1,
          points:
              stringToPoints(trip['polylines'][i]['points']), // routePoints,
          color: uiColours.keys.toList()[trip['polylines'][i]['colour']],
          borderColor: uiColours.keys.toList()[trip['polylines'][i]['colour']],
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
          Widget marker =
              MarkerWidget(type: trip['points_of_interest'][i]['_type']);
          gotPointsOfInterest.add(PointOfInterest(
            -1,
            -1,
            -1,
            trip['points_of_interest'][i]['_type'],
            trip['points_of_interest'][i]['name'],
            trip['points_of_interest'][i]['description'],
            trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            trip['points_of_interest'][i]['images'],
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
  return trip;
}
