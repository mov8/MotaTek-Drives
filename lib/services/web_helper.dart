import 'dart:async';
// import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:drives/constants.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/screens/dialogs.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
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

Map<String, String> webHeader({bool secure = false}) {
  Map<String, String> header = {'Content-Type': 'application/json'};
  if (secure) {
    header['Authorization'] = 'Bearer ${Setup().jwt}';
  }
  return header;
}

/*
  String jwToken = Setup().jwt;
  Map<String, String> header = {'Content-Type': 'application/json'};
  if (secure) {
    header['Autorization'] = 'Bearer $jwToken';
  }

  String jwToken = Setup().jwt;
  header['Autorization'] = 'Bearer $jwToken';
  http.Response response = await http.post(uri, headers: headers, body)

*/

Future<http.Response> getWebData(
    {required Uri uri, bool secure = false, int timeout = 10}) async {
  http.Response response = await http
      .get(uri, headers: webHeader(secure: secure))
      .timeout(Duration(seconds: timeout));
  return response;
}

Future<http.Response> postWebData(
    {required Uri uri,
    required String body,
    bool secure = true,
    int timeout = 10}) async {
  Map<String, String> headers = webHeader(secure: secure);
  final http.Response response = await http
      .post(uri, headers: headers, body: body)
      .timeout(Duration(seconds: timeout));
  return response;
}

const List<String> settlementTypes = ['city', 'town', 'village', 'hamlet'];
DateFormat dateFormat = DateFormat('dd/MM/yy HH:mm');
RegExp emailRegex = RegExp(r'[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

// enum LoginState { ok, badPassword, badEmail }

Future<List<String>> getSuggestions(String value) async {
  String baseURL = 'https://photon.komoot.io/api/?q=$value';
  List<String> suggestions = [''];
  var url = Uri.parse(baseURL);
  if (value.length > 2) {
    dynamic response = await http.get(url);
    if (response.statusCode == 200) {
      dynamic jResponse = json.decode(response.body);
      for (int i = 0; i < jResponse["features"].length; i++) {
        if (settlementTypes
            .contains(jResponse["features"][i]["properties"]["type"])) {
          suggestions.add(
              'jResponse["features"][i]["properties"]["name"] ${jResponse["features"][i]["properties"]["county"] ?? ""} ${jResponse["features"][i]["properties"]["state"] ?? ""}');
        }
      }
    }
  }
  return suggestions;
}

Future<List<String>> getApiOptions(
    {String type = 'email', String value = ''}) async {
  List<dynamic> results = [];
  if (value.isNotEmpty) {
    try {
      final http.Response response = await getWebData(
          uri: Uri.parse('$urlUser/emails/$value'), secure: true);
      if ([200, 201].contains(response.statusCode)) {
        results = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint(
          'Error getting api list ${e.toString()}, results.length() ${results.length}');
    }
  }
  return List<String>.from(results);
}

Future<List<Place>> getPlaces({String value = ''}) async {
  List<Place> results = [];
  if (value.isNotEmpty) {
    try {
      final http.Response response = await getWebData(
          uri: Uri.parse('$urlPointOfInterest/places/$value'), secure: false);
      if ([200, 201].contains(response.statusCode)) {
        dynamic maps = jsonDecode(response.body);
        for (Map<String, dynamic> map in maps) {
          results.add(Place.fromMap(map: map));
        }
      }
    } catch (e) {
      debugPrint(
          'Error getting api list ${e.toString()}, results.length() ${results.length}');
    }
  }
  return results;
}

Future<LatLng> getPosition(String value) async {
  String baseURL = 'https://photon.komoot.io/api/?q=$value&limit=1';
  LatLng pos = const LatLng(0.00, 0.00);
  var url = Uri.parse(baseURL);
  if (value.length > 2) {
    try {
      dynamic response = await http.get(url);
      if (response.statusCode == 200) {
        dynamic jResponse = json.decode(response.body);
        pos = LatLng(jResponse["features"][0]["geometry"]["coordinates"][1],
            jResponse["features"][0]["geometry"]["coordinates"][0]);
      }
    } catch (e) {
      debugPrint('web_helper.getPosition() error: ${e.toString()}');
    }
  }
  return pos;
}

class SearchLocation extends StatefulWidget {
  final Function onSelect;
  const SearchLocation({super.key, required this.onSelect});
  @override
  State<SearchLocation> createState() => _SearchLocationState();
}

class _SearchLocationState extends State<SearchLocation> {
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
                        hintText: 'Search for place name'),
                  );
                },
                onSelected: (String selection) async {
                  clearSelections();
                  LatLng pos = await getPosition(selection);
                  widget.onSelect(pos);
                },
              ),
            ),
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

Future<Map<String, dynamic>> postUser(
    {required User user, bool register = false}) async {
  try {
    var uri = Uri.parse('$urlUser/${register ? "register" : "login"}');
    http.Response response =
        await postWebData(uri: uri, body: jsonEncode(user.toMapApi()));
    Map<String, dynamic> map = jsonDecode(response.body);
    if ([200, 201].contains(response.statusCode)) {
      Setup().jwt = map['token'];
      return {'msg': 'OK'};
    } else {
      return map;
    }
  } catch (e) {
    // debugPrint('Login error: ${e.toString()}');
  }
  return {'message': 'error'};
}

Future<bool> postValidateUser({required User user}) async {
  try {
    var uri = Uri.parse('$urlUser/validate');
    Map<String, String> data = {"email": user.email, "name": user.forename};
    http.Response response =
        await postWebData(uri: uri, body: jsonEncode(data));
    if (response.statusCode != 201) {
      return false;
    }
  } catch (e) {
    debugPrint('Error sending validation request: ${e.toString()}');
    return false;
  }

  return true;
}

Future<Map<String, dynamic>> postContacts(
    {required List<Map<String, dynamic>> data}) async {
  try {
    var uri = Uri.parse('$urlUser/survey');
    http.Response response =
        await postWebData(uri: uri, body: jsonEncode(data));
    Map<String, dynamic> map = jsonDecode(response.body);
    if ([200, 201].contains(response.statusCode)) {
      Setup().jwt = map['token'];
      return {'msg': 'OK'};
    } else {
      return map;
    }
  } catch (e) {
    debugPrint('Login error: ${e.toString()}');
  }
  return {'message': 'error'};
}

Future<void> getUserDetails({required String email}) async {
  final http.Response response =
      await getWebData(uri: Uri.parse('$urlUser/user/$email'));
  if ([200, 201].contains(response.statusCode)) {
    try {
      Map<String, dynamic> data = jsonDecode(response.body);
      Setup().jwt = data['token'] ?? '';
      Setup().user.forename = data['forename'] ?? '';
      Setup().user.surname = data['surname'] ?? '';
      Setup().user.email = email;
      Setup().user.phone = data['phone'] ?? '';
      Setup().setupToDb();
    } catch (e) {
      debugPrint('Error retrieving user data: ${e.toString()}');
    }
  }
}

Future<void> getStats() async {
  final http.Response response =
      await getWebData(uri: Uri.parse('$urlUser/stats'), secure: true);
  if ([200, 201].contains(response.statusCode)) {
    try {
      Map<String, dynamic> data = jsonDecode(response.body);
      Setup().messageCount = data['messages'];
      Setup().tripCount = data['trips'];
      Setup().shopCount = data['shop'];
    } catch (e) {
      debugPrint('Error getting stats: ${e.toString()}');
    }
  }
}

Future<Map<String, dynamic>> tryLogin({required User user}) async {
  bool register = user.password.length <= 6;
  try {
    var uri = Uri.parse('$urlUser/${register ? "register" : "login"}');
    final http.Response response =
        await postWebData(uri: uri, body: jsonEncode(user.toMap()));

    Map<String, dynamic> map = jsonDecode(response.body);
    if (response.statusCode == 200) {
      Setup().jwt = map['token'];
      Setup().setupToDb();
      return {'msg': 'OK'};
    } else {
      return {'msg': map['message'] ?? 'error'};
    }
  } catch (e) {
    debugPrint('Login error: ${e.toString()}');
  }
  return {'message': 'error'};
}

Future<dynamic> postTrip(MyTripItem tripItem) async {
  Map<String, dynamic> map = tripItem.toMap();
  List<Photo> photos = photosFromJson(tripItem.images);
  double maxLat = -90;
  double minLat = 90;
  double maxLong = -180;
  double minLong = 180;
  for (mt.Route polyline in tripItem.routes) {
    for (LatLng point in polyline.points) {
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLong = point.longitude > maxLong ? point.longitude : maxLong;
      minLong = point.longitude < minLong ? point.longitude : minLong;
    }
  }

  var request = http.MultipartRequest('POST', Uri.parse('$urlDrive/add'));

  ///  for (Photo photo in photos) {
  ///    request.files.add(await http.MultipartFile.fromPath('files', photo.url));
  /// "ClientException with SocketException: Broken pipe (OS Error: Broken pipe, errno = 32), address = 10.101.1.150, port = 58368, uri…"
  /// }
  dynamic response;
  // String jwToken = Setup().jwt;
  try {
    request.headers['Authorization'] = 'Bearer ${Setup().jwt}';
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

    // request.headers['Authorization'] = 'Bearer ${Setup().jwt}';

    //   request.headers['Authorization'] = 'Bearer $jwToken';

    response = await request.send().timeout(const Duration(seconds: 30));
  } catch (e) {
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting trip: ${e.toString()}');
    }
  }

  if ([200, 201].contains(response.statusCode)) {
    // 201 = Created
    dynamic responseData = await response.stream.bytesToString();
    // debugPrint('Server response: $responseData');
    return jsonDecode(responseData);
  } else {
    // debugPrint('Failed to post trip: ${response.statusCode}');
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
  var request =
      http.MultipartRequest('POST', Uri.parse('$urlPointOfInterest/add'));

  for (Photo photo in photos) {
    request.files.add(await http.MultipartFile.fromPath('files', photo.url));
  }
  dynamic response;
  // String jwToken = Setup().jwt;
  try {
    // request.fields['id'] = map['id'].toString();
//if (map['url'].length > 30) {
    request.fields['url'] = map['url'];
    //   }
    request.fields['drive_id'] = tripUri;
    request.fields['name'] = map['name'];
    request.fields['description'] = map['description'];
    request.fields['type'] = map['type'].toString();
    request.fields['latitude'] = map['latitude'].toString();
    request.fields['longitude'] = map['longitude'].toString();
    response = await request.send().timeout(const Duration(seconds: 30));
    debugPrint("Point of interest map['url'] sent as ${map['url']}");
    if (response.statusCode == 201) {
      dynamic responseData = await response.stream.bytesToString();
      // debugPrint('Server response: $responseData');
      return jsonEncode(responseData);
    } else {
      // debugPrint('Failed to post point_of_interest: ${response.statusCode}');
      return jsonEncode({'token': '', 'code': response.statusCode});
    }
  } catch (e) {
    String err = e.toString();
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting trip: $err');
    }
  }
  return jsonEncode({'code': '${response.statusCode}'});
}

Future<String> postPolylines(
    {required List<mt.Route> polylines,
    required String driveUid,
    int type = 0}) async {
  List<Map<String, dynamic>> maps = [];
  for (mt.Route polyline in polylines) {
    maps.add({
      'drive_id': driveUid,
      'points': pointsToString(polyline.points),
      'stroke': polyline.strokeWidth,
      'colour':
          uiColours.keys.toList().indexWhere((col) => col == polyline.color),
    });
    if (type == 1) {
      Fence fence = fenceFromPolylines(polyline: polyline);
      maps[maps.length - 1]['max_lat'] = fence.northEast.latitude.toString();
      maps[maps.length - 1]['min_lat'] = fence.southWest.latitude.toString();
      maps[maps.length - 1]['max_long'] = fence.northEast.longitude.toString();
      maps[maps.length - 1]['min_long'] = fence.southWest.longitude.toString();
      maps[maps.length - 1]['point_of_interest_id'] =
          polyline.pointOfInterestUri;
    }
  }
  if (polylines.isEmpty) {
    return jsonEncode({'message': 'no polylines to post'});
  }
  final http.Response response =
      await http.post(Uri.parse('${type == 0 ? urlPolyline : urlGoodRoad}/add'),
          headers: <String, String>{
            "Content-Type": "application/json; charset=UTF-8",
          },
          body: jsonEncode(maps));
  if (response.statusCode == 201) {
    // 201 = Created
    // debugPrint('Polyline posted OK');
    return jsonEncode({'code': response.statusCode});
  } else {
    // debugPrint('Failed to post user');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

/*
Future<List<DriveCacheItem>> getDriveCacheItems(
    {LatLng northEast = ukNorthEast,
    LatLng southWest = ukSouthWest,
    double iconSize = 60}) async {
  try {
    final Uri uri = Uri.parse(
        '$urlDrive/cache/${southWest.latitude}/${northEast.latitude}/${southWest.longitude}/${northEast.longitude}');
    final http.Response response = await getWebData(uri: uri);
    if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
      List<dynamic> maps = jsonDecode(response.body);
      Color iconColor = uiColours.keys.toList()[Setup().routeColour];
      return [
        for (Map<String, dynamic> map in maps)
          DriveCacheItem.fromMap(
              map: map, iconColor: iconColor, iconSize: iconSize, size: 60)
      ];
    }
  } catch (e) {
    // debugPrint('Error fetching DriveCacheItems: ${e.toString()}');
  }
  return [];
}
*/
Future<List<mt.Route>> getDriveRoutes(
    {required String driveUri, driveKey = -1}) async {
  final http.Response response =
      await getWebData(uri: Uri.parse('$urlPolyline/drive/$driveUri'));
  if ([200, 201].contains(response.statusCode)) {
    try {
      List<dynamic> maps = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> map in maps)
          polylineFromMap(map: map, goodRoad: false, driveKey: driveKey)
      ];
    } catch (e) {
      debugPrint('Error getPolylines: ${e.toString()}');
      return [];
    }
  } else {
    return [];
  }
}

Future<List<mt.Route>> getGoodRoads(LatLng ne, LatLng sw) async {
  final Uri uri = Uri.parse(
      '$urlGoodRoad/location/${sw.latitude}/${ne.latitude}/${sw.longitude}/${ne.longitude}');

  final http.Response response = await getWebData(uri: uri);
  if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
    List<dynamic> maps = jsonDecode(response.body);
    return [
      for (Map<String, dynamic> map in maps)
        polylineFromMap(map: map, goodRoad: true)
    ];
  }
  return [];
}

Future<mt.Route?> getRoute(
    {required String uriString, bool goodRoad = false}) async {
  String stringUri =
      goodRoad ? '$urlGoodRoad/$uriString' : '$urlPolyline/$uriString';
  final http.Response response = await getWebData(uri: Uri.parse(stringUri));
  if ([200, 201].contains(response.statusCode)) {
    Map<String, dynamic> map = jsonDecode(response.body);
    return polylineFromMap(map: map, goodRoad: goodRoad);
  }
  return null;
  // Polyline(points: [const LatLng(0, 0)]);
}

// Future<List<mt.Route?>> getRoutes({required String driveUri}) {

// }

mt.Route polylineFromMap(
    {required Map<String, dynamic> map,
    bool goodRoad = false,
    int driveKey = -1}) {
  int colour = goodRoad ? Setup().goodRouteColour : Setup().publishedTripColour;
  // map['colour'];
  Color routeColor = uiColours.keys.toList()[colour];
  return mt.Route(
    id: -1,
    driveKey: driveKey,
    points: stringToPoints(map['points']), // routePoints,
    color: routeColor,
    borderColor: routeColor,
    strokeWidth: (map['stroke']).toDouble(),
    pointOfInterestIndex: -1,
    pointOfInterestUri: map['point_of_interest_id'] ?? '',
    rating: map['average_rating'] ?? 1,
  );
}

Future<List<PointOfInterest>> getPointsOfInterest(ne, sw) async {
  List<PointOfInterest> pointsOfInterest = [];

  final http.Response response = await http
      .get(
        Uri.parse(
            '$urlPointOfInterest/location/${sw.latitude}/${ne.latitude}/${sw.longitude}/${ne.longitude}'),
        //'/location/<min_lat>/<max_lat>/<min_long>/<max_long>'
        headers: webHeader(),
      )
      .timeout(const Duration(seconds: 20));
  if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
    List pois = jsonDecode(response.body);
    for (int i = 0; i < pois.length; i++) {
      pointsOfInterest.add(
        PointOfInterest(
          type: pois[i]['_type'],
          name: pois[i]['name'],
          description: pois[i]['description'],
          width: 30,
          height: 30,
          images: pois[i]['images'],
          markerPoint: LatLng(pois[i]['latitude'], pois[i]['longitude']),
          driveUri: pois[i]['drives'] ?? '',
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

Future<OsmAmenity> getOsmAmenity({required int osmId}) async {
  OsmAmenity amenity =
      OsmAmenity(position: LatLng(0, 0), marker: MarkerWidget(type: 1));
  final http.Response response = await http
      .get(
        Uri.parse('$urlPointOfInterest/amenity/$osmId'),
        //'/location/<min_lat>/<max_lat>/<min_long>/<max_long>'
        headers: webHeader(),
      )
      .timeout(const Duration(seconds: 20));
  if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
    dynamic map = jsonDecode(response.body);
    amenity = OsmAmenity(
      osmId: map['osm_id'],
      position: LatLng(map['lat'], map('lng')),
      name: map['name'],
      amenity: map['amenity'],
      postcode: map['postcode'],
      marker: MarkerWidget(type: 1, name: map['name']),
    );
  }
  return amenity;
}

Future<List<OsmAmenity>> getOsmAmenities({
  required String polygon,
}) async {
  List<OsmAmenity> osmAmenities = [];
  String delimiter = '';
  String including = '';
  if (Setup().osmPubs) {
    including = amenitiesMap['pubs'] ?? '';
    delimiter = ', ';
  }
  if (Setup().osmRestaurants) {
    including = '$including$delimiter${amenitiesMap['restaurants'] ?? ''}';
    delimiter = ', ';
  }
  if (Setup().osmFuel) {
    including = '$including$delimiter${amenitiesMap['fuel'] ?? ''}';
    delimiter = ', ';
  }
  if (Setup().osmToilets) {
    including = '$including$delimiter${amenitiesMap['toilets'] ?? ''}';
    delimiter = ', ';
  }
  /*
  if (Setup().osmHistorical) {
    including = '$including$delimiter${amenitiesMap['historical'] ?? ''}';
    delimiter = ', ';
  }
  */
  if (Setup().osmAtms) {
    including = '$including$delimiter${amenitiesMap['atms'] ?? ''}';
    delimiter = ', ';
  }
  if (including.isEmpty) {
    return [];
  }
  final http.Response response = await http
      .get(
        Uri.parse('$urlPointOfInterest/amenities/$polygon/$including'),
        headers: webHeader(),
      )
      .timeout(const Duration(seconds: 20));
  if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
    List amenities = jsonDecode(response.body);
    for (int i = 0; i < amenities.length; i++) {
      try {
        osmAmenities.add(
          OsmAmenity(
            id: IntIm(value: amenities[i]['id'] ?? -1),
            osmId: amenities[i]['osm_id'],
            position: LatLng(amenities[i]['lat'], amenities[i]['lng']),
            name: amenities[i]['name'],
            amenity: amenities[i]['amenity'],
            postcode: amenities[i]['postcode'],
            width: 30,
            height: 30,
            marker: OSMMarkerWidget(
              osmId: amenities[i]['osm_id'],
              name: amenities[i]['name'],
              amenity: amenities[i]['amenity'],
              postcode: amenities[i]['postcode'],
              angle: 0, // degrees to radians
              index: i,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error adding OSM amenity ${e.toString()}');
      }
    }
  }

  return osmAmenities;
}

Future<PointOfInterest> getPointOfInterest(
    {String uri = '', int index = 0}) async {
  final http.Response response = await http
      .get(
        Uri.parse('$urlPointOfInterest/$uri'),
        headers: webHeader(),
      )
      .timeout(const Duration(seconds: 5));
  if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
    dynamic map = jsonDecode(response.body);
    PointOfInterest pointOfInterest = PointOfInterest(
      type: map['_type'],
      name: map['name'],
      description: map['description'],
      images: map['images'],
      markerPoint: LatLng(map['latitude'], map['longitude']),
      score: map["average_rating"],
      scored: map["ratings_count"],
      driveUri: map['drives'],
      url: map['id'],
      marker: MarkerWidget(
        type: map['_type'],
      ),
    );

    return pointOfInterest;
  } else {
    return PointOfInterest(
        name: '',
        marker: MarkerWidget(type: 1),
        markerPoint: const LatLng(0, 0));
  }
}

// List<Photo> photsFromString()

String endpoint(
    {required String driveUri,
    required String pointOfInterestUri,
    String images = ''}) {
  return '$urlDriveImages/$driveUri/$pointOfInterestUri/';
}

List<String> webUrls(
    String driveUri, String pointOfInterestUri, String uriString) {
  if (uriString.length > 4) {
    List<String> files = [uriString.substring(2, uriString.length - 2)];
    List<String> urls = [
      for (String file in files)
        '$urlDrive/images/$driveUri/$pointOfInterestUri/$file'
    ];
    if (urls.isNotEmpty) {
      // debugPrint('webUrls urls.length: ${urls.length}');
    }
    return urls;
  }
  return [];
}

// "http://10.101.1.150:5000/v1/drive/images/712c8d58e7d84491bba6fdb5507ea5ac/0081b165074f4d218c2db5ecafffd1b3/e9cbc367-236b-4dde-994d-e19fb43c1092.jpg"
Future<String> postManeuver(Maneuver maneuver, String driveUid) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlManeuver/add'),
      body: jsonEncode(maneuver.toMap(driveUid: driveUid)));
  if ([200, 201].contains(response.statusCode)) {
    // debugPrint('Maneuver posted OK');
    return jsonEncode({'code': response.statusCode});
  } else {
    // debugPrint('Failed to post maneuver');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

Future<String> postManeuvers(List<Maneuver> maneuvers, String driveUid) async {
  List<Map<String, dynamic>> maps = [
    for (Maneuver maneuver in maneuvers) maneuver.toMap(driveUid: driveUid)
  ];
  if (maps.isEmpty) {
    return jsonEncode({'message': 'no maneuvers to post'});
  }
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlManeuver/add'), body: jsonEncode(maps), secure: true);
  if (response.statusCode == 201) {
    // debugPrint('Maneuver posted OK');
    return jsonEncode({'code': response.statusCode});
  } else {
    // debugPrint('Failed to post maneuver');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

/// getFeatures returns all the features from the API
/// type 1: drives
/// type 2: points of interest excluding type 12 ad 16
/// type 3: good roads

Future<List<Feature>> getFeatures(
    {double zoom = 12,
    required Function onTap,
    Map<String, int>? pointOfInterestLookup}) async {
  http.Response response =
      await getWebData(uri: Uri.parse('$urlDrive/features'));
  if (response.statusCode == 200) {
    List<dynamic> dataJson = jsonDecode(response.body);
    int row = 0;
    List<Feature> features = [];
    for (Map<String, dynamic> map in dataJson) {
      Feature feature = Feature.fromMap(
          map: map, row: row++, size: zoom * 5, onTap: () => onTap);
      if (pointOfInterestLookup != null && feature.poiType == 13) {
        try {
          pointOfInterestLookup[feature.uri] = feature.row;
        } catch (e) {
          debugPrint('Error updating lookup: ${e.toString()}');
        }
      }
      features.add(feature);
    }
    return features;
  }
  return [];
}

Future<List<ImageCacheItem>> getImages() async {
  http.Response response = await getWebData(uri: Uri.parse('$urlDrive/images'));
  if (response.statusCode == 200) {
    List<dynamic> dataJson = jsonDecode(response.body);
    int row = 0;
    return [
      for (Map<String, dynamic> map in dataJson)
        ImageCacheItem.fromMap(map: map, row: row++)
    ];
  }
  return [];
}

Future<List<TripSummary>> getTripSummaries(
    {required LatLng northEast,
    required LatLng southWest,
    double zoom = 8}) async {
  List<TripSummary> summaries = [];

  final http.Response response = await http
      .get(
        Uri.parse('$urlDrive/summary/-90/90/-180/180/$zoom'),
        // '$urlDrive/summary/${southWest.latitude}/${northEast.latitude}/${southWest.longitude}/${northEast.longitude}/$zoom'),
      )
      .timeout(const Duration(seconds: 5));

  if (response.statusCode == 200) {
    try {
      List<dynamic> tripsJson = jsonDecode(response.body);
      for (Map<String, dynamic> trip in tripsJson) {
        summaries.add(TripSummary.fromMap(map: trip));
      }
    } catch (e) {
      // debugPrint('Error processing summaries: ${e.toString()}');
    }
  }
  // debugPrint('Summaries returned from API: ${summaries.length}');
  return summaries;
}

Future<List<TripItem>> getTrips() async {
  List<TripItem> trips = [];
  LatLng pos = const LatLng(-52, 0);
  try {
    var currentPosition = Setup().lastPosition; //await utils.getPosition();
    pos = LatLng(currentPosition.latitude, currentPosition.longitude);
  } catch (e) {
    // debugPrint('getPosition() error: ${e.toString()}');
  }

  final http.Response response = await http
      .get(
        Uri.parse('$urlDrive/all'),
        headers: webHeader(),
      )
      .timeout(const Duration(seconds: 20));
  if (response.statusCode == 200) {
    List<dynamic> tripsJson = jsonDecode(response.body);
    for (Map<String, dynamic> trip in tripsJson) {
      String images = '{"url": "map.png","caption":""}';
      try {
        int distance = 99999;
        for (int i = 0; i < trip['points_of_interest'].length; i++) {
          if (trip['points_of_interest'][i]['images'].length > 0) {
            var pics = jsonDecode(trip['points_of_interest'][i]['images']);
            for (int j = 0; j < pics.length; j++) {
              images =
                  '$images, {"url": "${trip['points_of_interest'][i]['id']}/${pics[j]}", "caption": ""}';
            }
          }
          LatLng poiPos = LatLng(trip['points_of_interest'][i]['latitude'],
              trip['points_of_interest'][i]['longitude']);
          distance = min(utils.distanceBetween(poiPos, pos).toInt(), distance);
        }
        trips.add(TripItem.fromMap(
            map: trip, endpoint: '$urlDrive/', imageUrls: '[$images]'));
      } catch (e) {
        String err = e.toString();
        debugPrint('Error: $err');
      }
    }
  }
  return trips;
}

/*
Future<String> postManeuver(Maneuver maneuver, String driveUid) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlManeuver/add'),
      body: jsonEncode(maneuver.toMap(driveUid: driveUid)));
  if ([200, 201].contains(response.statusCode)) {

*/

Future<bool> deleteWebTrip2({required List<Map<String, String>> uriMap}) async {
  // var json = jsonEncode(uriList.map((e) => e.toJson()).toList());
  final http.Response response = await postWebData(
          uri: Uri.parse('$urlDrive/delete'),
          body: jsonEncode(uriMap),
          secure: true)
      .timeout(const Duration(seconds: 20));
  return (response.statusCode == 200);
}

Future<bool> deleteWebTrip({required List<Map<String, String>> uriMap}) async {
  Map<String, String> headers = {
    'Authorization': 'Bearer ${Setup().jwt}',
    "Content-Type": "application/json; charset=UTF-8"
  };
  var body = jsonEncode(uriMap);

  final http.Response response = await http
      .post(Uri.parse('$urlDrive/delete'), headers: headers, body: body)
      .timeout(const Duration(seconds: 20));
  return response.statusCode == 200;
}

Future<bool> deleteWebUser({required Map<String, dynamic> uriMap}) async {
  Map<String, String> headers = {
    'Authorization': 'Bearer ${Setup().jwt}',
    "Content-Type": "application/json; charset=UTF-8"
  };
  var body = jsonEncode(uriMap);

  final http.Response response = await http
      .post(Uri.parse('$urlUser/delete'), headers: headers, body: body)
      .timeout(const Duration(seconds: 20));
  return response.statusCode == 200;
}

/// getTrip() Gets the trip details for the tripTile - doesn't include any
/// routing data

Future<TripItem?> getTrip(
    {required tripId, bool updateImageUris = false}) async {
  if (tripId.length == 32) {
    final http.Response response = await http
        .get(
          Uri.parse('$urlDrive/summary/$tripId'),
          headers: webHeader(secure: true),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      var trip = jsonDecode(response.body);
      List<String> images = [
        //  Uri.parse('$urlDrive/images/${trip['id']}/map.png').toString()
        Uri.parse('${trip['id']}/map.png').toString()
      ];
      try {
        int distance = 99999;
        for (int i = 0; i < trip['points_of_interest'].length; i++) {
          if (trip['points_of_interest'][i]['images'].length > 0) {
            var pics = jsonDecode(trip['points_of_interest'][i]['images']);
            for (int j = 0; j < pics.length; j++) {
              images.add(Uri.parse(
                      '${trip['id']}/${trip['points_of_interest'][i]['id']}/${pics[j]}')
                  .toString());
            }
          }
        }
        try {
          TripItem tripItem = TripItem(
              heading: trip['title'],
              subHeading: trip['sub_title'],
              body: trip['body'],
              author: trip['author'],
              published: trip['added'],
              imageUrls: imageListToString(
                  imageList:
                      images), // images.toString(), // trip['image_urls'] ?? '',
              score: trip['average_rating'].toDouble() ?? 5.0,
              distance: trip['distance'],
              pointsOfInterest: trip['points_of_interest'].length,
              closest: distance,
              scored: trip['ratings_count'] ?? 1,
              downloads: trip['download_count'] ?? trip['downloads'] ?? 0,
              uri: trip['id']);
          return tripItem;
        } catch (e) {
          debugPrint('Error ${e.toString}');
        }
      } catch (e) {
        String err = e.toString();
        debugPrint('Error: $err');
      }
    }
  }
  return null;
}

//"d663bed13ef54cd386bc8e5582803c80/map.png"
//"d663bed13ef54cd386bc8e5582803c80/65e84e4ba58a49a7aa020a55a42c12db/bdb84cab-351c-48f0-ba4c-d6a46a560bc0.jpg"
String imageListToString({required imageList}) {
  String images = '';
  for (String image in imageList) {
    images = '{"url": "$image", "caption": ""}, ';
  }
  return '[${images.substring(images.substring(0) == '[' ? 1 : 0, images.length - 2)}]';
}

Future<Uint8List> getImageBytes({required String url}) async {
  Uint8List data = Uint8List.fromList([]);
  final response =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
  if (response.statusCode == 200) {
    data = response.bodyBytes;
  }
  return data;
}
// ImageCache

Future<void> getAndSaveImage(
    {required String url, required String filePath}) async {
  final response =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
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
        // debugPrint('Image file $url exists');
      }
    } catch (e) {
      // debugPrint('Error writing image file: ${e.toString()}');
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
      Uri.parse('$urlDriveRating/add'),
      headers: webHeader(secure: true),
      body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    // debugPrint('Score added OK: ${response.statusCode}');
  }
}

putPointOfInterestRating(String uri, double score) async {
  // uri = uri.substring(1, uri.length - 1);
  uri = uri.substring(uri.indexOf('/') + 1);
  Map<String, dynamic> map = {
    'point_of_interest_id': uri,
    'rating': score,
    'comment': '',
    'rated': DateTime.now().toString()
  };
  final http.Response response = await http.post(
      Uri.parse('$urlPointOfInterestRating/add'),
      headers: webHeader(secure: true),
      body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    // debugPrint('Score added OK: ${response.statusCode}');
  }
}

Future<Map<String, dynamic>> getPointOfInterestRating(String uri) async {
  Map<String, dynamic> rating = {'rating': '0'};
  final http.Response response = await http
      .get(
        Uri.parse('$urlPointOfInterestRating/$uri'),
        headers: webHeader(),
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
    Uri.parse('$urlDrive/$tripUuid'),
    headers: webHeader(),
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
            type: trip['points_of_interest'][i]['_type'],
            name: trip['points_of_interest'][i]['name'],
            description: trip['points_of_interest'][i]['description'],
            width: trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            height: trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            images: trip['points_of_interest'][i]['images'],
            url: '/${trip['id']}/${trip['points_of_interest'][i]['id']}/',
            score: trip['points_of_interest'][i]['average_rating'] ?? 1,
            scored: trip['points_of_interest'][i]['ratings_count'] ?? 0,
            markerPoint: posn,
            marker: marker,
          ));
        } catch (e) {
          // debugPrint('Error: ${e.toString()}');
        }
      }
    } catch (e) {
      debugPrint('PointsOfInterest error: ${e.toString()}');
    }
    try {
      MyTripItem myTripItem = MyTripItem(
        heading: trip['title'],
        driveUri: tripUuid,
        subHeading: trip['sub_title'],
        body: trip['body'],
        published: trip['added'],
        images: Uri.parse('$urlDrive/images/${trip['id']}/map.png').toString(),
        score: trip['score'] ?? 5.0,
        distance: trip['distance'],
        pointsOfInterest: gotPointsOfInterest,
        closest: 12,
      );
      return myTripItem;
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }
  return myTrip;
}

Future<MyTripItem> getMyTrip(String tripUuid) async {
  MyTripItem myTrip = MyTripItem(heading: '', subHeading: '');

  final http.Response response = await http.get(
    Uri.parse('$urlDrive/$tripUuid'),
    headers: webHeader(secure: true),
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
        // debugPrint('Error maneuvers: ${e.toString()}');
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
            type: trip['points_of_interest'][i]['_type'],
            name: trip['points_of_interest'][i]['name'],
            description: trip['points_of_interest'][i]['description'],
            width: trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            height: trip['points_of_interest'][i]['_type'] == 12 ? 10 : 30,
            images: trip['points_of_interest'][i]['images'],
            url: '/${trip['id']}/${trip['points_of_interest'][i]['id']}/',
            score: trip['points_of_interest'][i]['average_rating'] ?? 1,
            scored: trip['points_of_interest'][i]['ratings_count'] ?? 0,
            markerPoint: posn,
            marker: marker,
          ));
        } catch (e) {
          // debugPrint('Error: ${e.toString()}');
        }
      }
    } catch (e) {
      debugPrint('PointsOfInterest error: ${e.toString()}');
    }
    try {
      MyTripItem myTripItem = MyTripItem(
        heading: trip['title'],
        driveUri: tripUuid,
        subHeading: trip['sub_title'],
        body: trip['body'],
        published: trip['added'],
        images: Uri.parse('$urlDrive/images/${trip['id']}/map.png').toString(),
        score: trip['score'] ?? 5.0,
        distance: trip['distance'].toDouble(),
        routes: gotRoutes,
        maneuvers: gotManeuvers,
        pointsOfInterest: gotPointsOfInterest,
        closest: 12,
      );
      return myTripItem;
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
    }
  }
  return myTrip;
}

Future<List<GroupMember>> getIntroduced() async {
  List<GroupMember> introduced = [];
  try {
    final http.Response response = await http
        .get(
          Uri.parse('$urlIntroduced/get'),
          headers: webHeader(),
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
    // debugPrint("Can't access data on the web");
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
      Uri.parse('$urlIntroduced/put'),
      headers: webHeader(),
      body: jsonEncode(maps));
  if ([200, 201].contains(response.statusCode)) {
    // debugPrint('Member added OK: ${response.statusCode}');
  }
}

deleteWebImage(String url) async {
  final http.Response response = await http.post(Uri.parse(url),
      headers: webHeader(), body: jsonEncode('"id": "delete_image"'));
  if ([200, 201].contains(response.statusCode)) {
    // debugPrint('Member added OK: ${response.statusCode}');
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
          errorBuilder:
              (BuildContext context, Object exception, StackTrace? stackTrace) {
            return ImageMissing(width: width);
          },
        ),
      ),
    ),
  );
}

Future<File> downloadImage({String apiUrl = '', String targetFile = ''}) async {
  // String dir = (await getApplicationDocumentsDirectory()).path;
  File file = File(targetFile);

  if (file.existsSync()) {
    // debugPrint('file already exist');
    return file;
  } else {
    try {
      Uri url = Uri.parse(apiUrl);
      http.Response request = await http.get(
        url,
      );
      if ([200, 201].contains(request.statusCode)) {
        var bytes = request.bodyBytes; //close();
        await file.writeAsBytes(bytes);
        // debugPrint(file.path);
      }
    } catch (e) {
      debugPrint('Error writing to image file: ${e.toString}');
    }
  }
  return file;
}

bool canDelete(bool ok, String url, int index) {
  if (ok) {
    // debugPrint('Can delete');
    return true;
  } else {
    // debugPrint("Can't delete");
    return false;
  }
}

Future<List<Group>> getManagedGroups() async {
  try {
    final http.Response response =
        await getWebData(uri: Uri.parse('$urlGroup/managed'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var groups = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> groupData in groups)
          Group.fromGroupSummaryMap(groupData)
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web");
  }
  return [];
}

Future<List<GroupMember>> getManagedGroupMembers(String groupId) async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlGroupMember/members/$groupId'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var groups = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> groupData in groups)
          GroupMember.fromApiMap(groupData)
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web");
  }
  return [];
}

Future<List<Group>> getGroups() async {
  try {
    final http.Response response =
        await getWebData(uri: Uri.parse('$urlGroup/get'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var groups = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> groupData in groups) Group.fromMap(groupData)
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web");
  }
  return [];
}

Future<bool> serverListening() async {
  try {
    final http.Response response = await http
        .get(
          Uri.parse('$urlUser/test'),
        )
        .timeout(const Duration(seconds: 20));
    return (response.statusCode == 200);
  } catch (e) {
    debugPrint('Error checking for server: ${e.toString()}');
    return false;
  }
}

Future<List<Group>> getMyGroups() async {
  try {
    final http.Response response =
        await getWebData(uri: Uri.parse('$urlGroup/mine'), secure: true);
    if (response.statusCode == 200) {
      var groups = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> groupData in groups)
          Group.fromMyGroupsMap(groupData)
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web");
  }
  return [];
}

Future<List<GroupDrive>> getGroupDrives() async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlGroupDrive/pending'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      List<dynamic> groups = jsonDecode(response.body);
      return [for (Map<String, dynamic> map in groups) GroupDrive.fromMap(map)];
    }
  } catch (e) {
    // debugPrint("getGroupDrives error: ${e.toString()}");
  }
  return [];
}

Future<Map<String, dynamic>> deleteGroupDrive(
    {required String groupDriveId}) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlGroupDrive/delete'),
      body: jsonEncode({'group_drive_id': groupDriveId}));
  if ([200, 201].contains(response.statusCode)) {
    return {'msg': 'OK'};
  }
  return {'msf': 'error'};
}

Future<List<MailItem>> getMessagesByGroup() async {
  List<MailItem> mailItems = [];
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlMessage/all_messages'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var groups = jsonDecode(response.body);

      for (Map<String, dynamic> groupData in groups) {
        mailItems.add(MailItem(
          id: groupData['id'],
          name: groupData['name'],
          unreadMessages: groupData['messages'] - int.parse(groupData['read']),
          messages: groupData['messages'],
          isGroup: groupData['group'] == 1,
        ));
      }
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
  }
  return mailItems;
}

Future<List<Message>> getGroupMessages(Group group) async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlMessage/group/${group.id}'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var messages = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> messageData in messages)
          Message.fromMap(
            messageData,
          )
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web");
  }
  return [];
}

Future<List<Message>> getUserMessages(User user) async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlMessage/user/${user.uri}'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var messages = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> messageData in messages)
          Message.fromMap(
            messageData,
          )
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web");
  }
  return [];
}

Future<String> putMessage(Group group, Message message) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlMessage/add'),
      body: '{"group_id": ${group.id}, "message": ${message.message}}');
  if ([200, 201].contains(response.statusCode)) {
    return jsonDecode(response.body);
  }
  return '';
}

Future<String> putGroup(Group group) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('${urlBase}v1/group/add'),
      body: jsonEncode(group.toMap()));
  if ([200, 201].contains(response.statusCode)) {
    dynamic responseData = jsonDecode(response.body);
    group.id = responseData['id'];
    return responseData.toString();
  }
  return '';
}

/// getHomeItems gets a list of home articles for the home screen
/// The scope parameter isn't yet implemented, but is to allow
/// some selection of who sees what on the home page

Future<List<HomeItem>> getHomeItems(int scope) async {
  try {
    final http.Response response =
        await getWebData(uri: Uri.parse('$urlHomePageItem/get/$scope'));
    if ([200, 201].contains(response.statusCode)) {
      List<dynamic> items = jsonDecode(response.body);
      if (items.isNotEmpty) {
        return [
          for (Map<String, dynamic> map in items)
            HomeItem.fromMap(map: map, url: '$urlHomePageItem/images/')
        ];
      }
    }
  } catch (e) {
    // debugPrint("getHomeItems error: ${e.toString()}");
  }
  return [];
}

Future<String> postHomeItem(HomeItem homeItem) async {
  Map<String, dynamic> map = homeItem.toMap();
  List<Photo> photos = photosFromJson(homeItem.imageUrls);

  var request =
      http.MultipartRequest('POST', Uri.parse('$urlHomePageItem/add'));

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
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting article: ${e.toString()}');
    }
  }

  if (response.statusCode == 201) {
    // 201 = Created
    // debugPrint('Home article posted OK');
    dynamic responseData = await response.stream.bytesToString();
    // debugPrint('Server response: $responseData');
    return jsonEncode(responseData);
  } else {
    // debugPrint('Failed to post home article: ${response.statusCode}');
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
          Uri.parse('$urlShopItem/get/$scope'),
          headers: webHeader(),
        )
        .timeout(const Duration(seconds: 30));
    if ([200, 201].contains(response.statusCode)) {
      List<dynamic> items = jsonDecode(response.body);
      if (items.isNotEmpty) {
        itemsSent = [
          for (Map<String, dynamic> map in items)
            ShopItem.fromMap(
                map: map,
                url: '$urlShopItem/images/') //  url: '$urlShopItem/images/')

          //  url: '$urlHomePageItem/images/'
        ];
      }
    }
  } catch (e) {
    // debugPrint("getGroupDrives error: ${e.toString()}");
  }
  return itemsSent;
}

Future<String> postShopItem(ShopItem shopItem) async {
  Map<String, dynamic> map = shopItem.toMap();
  List<Photo> photos = photosFromJson(shopItem.imageUrls);

  var request = http.MultipartRequest('POST', Uri.parse('$urlShopItem/add'));

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
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting article: ${e.toString()}');
    }
  }

  if (response.statusCode == 201) {
    // 201 = Created
    // debugPrint('Shop item posted OK');
    dynamic responseData = await response.stream.bytesToString();
    // debugPrint('Server response: $responseData');
    return jsonEncode(responseData);
  } else {
    // debugPrint('Failed to post shop item: ${response.statusCode}');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

Future<List<EventInvitation>> getInvitationssByUser() async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlGroupDriveInvitation/user'), secure: true);

    if ([200, 201].contains(response.statusCode)) {
      var invitations = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> invitation in invitations)
          EventInvitation.fromByUserMap(invitation)
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web");
  }
  return [];
}

Future<List<EventInvitation>> getInvitationsByEvent(
    {String eventId = ''}) async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlGroupDriveInvitation/trip/$eventId'));
    if ([200, 201].contains(response.statusCode)) {
      var invitations = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> invitation in invitations)
          EventInvitation.fromByEventMap(invitation)
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web: ${e.toString()}");
  }
  return [];
}

Future<List<EventInvitation>> getInvitationsToAlter(
    {String eventId = ''}) async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlGroupDriveInvitation/alter/$eventId'));
    if ([200, 201].contains(response.statusCode)) {
      var invitations = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> invitation in invitations)
          EventInvitation.fromByUserToAlterMap(invitation)
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web: ${e.toString()}");
  }
  return [];
}

Future<String> postGroupDriveInvitations(
    List<EventInvitation> invitations) async {
  List<Map<String, dynamic>> map = [
    for (EventInvitation invite in invitations)
      if (invite.selected) invite.toMap()
  ];
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlGroupDriveInvitation/update'), body: jsonEncode(map));
  if ([200, 201].contains(response.statusCode)) {
    return response.body;
  }
  return '';
}

Future<String> postGroupDrive(GroupDriveInvitation invitation) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlGroupDrive/add'),
      body: jsonEncode(invitation.toMap()),
      secure: true);
  if ([200, 201].contains(response.statusCode)) {
    return response.body;
  }
  return '';
}

Future<bool> answerInvitation(EventInvitation invitation) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlGroupDriveInvitation/respond'),
      secure: true,
      body: jsonEncode(
          {"invitation_id": invitation.id, "response": invitation.accepted}));
  return [200, 201].contains(response.statusCode);
}

Future<List<Map<String, dynamic>>> getDrivers(
    {required String driveId,
    String driveDate = '01-01-2000',
    int accepted = 2}) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlGroupDrive/drivers'),
      secure: true,
      body: jsonEncode({
        "drive_id": driveId,
        "drive_date": driveDate,
        "accepted": accepted
      }));
  debugPrint("Response code: ${response.statusCode}");
  var drivers = jsonDecode(response.body);

  return [for (Map<String, dynamic> driver in drivers) driver];
}

Future<GroupMember> getUserByEmail(String email) async {
  try {
    final http.Response response = await postWebData(
        uri: Uri.parse('$urlUser/get_user_by_email'),
        body: jsonEncode({"email": email}));

    if (response.statusCode == 200) {
      return GroupMember.fromUserMap(jsonDecode(response.body));
    }
  } catch (e) {
    debugPrint("Can't access data on the web: ${e.toString()}");
  }
  return GroupMember(forename: 'Not', surname: 'Registered', email: email);
}

Future<List<GroupMember>> getGroupMembers() async {
  try {
    final http.Response response =
        await getWebData(uri: Uri.parse('$urlIntroduced/get'), secure: true);
    if (response.statusCode == 200) {
      var members = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> memberMap in members)
          GroupMember.fromMap(memberMap)
      ];
    }
  } catch (e) {
    // debugPrint("Can't access data on the web");
  }
  return [];
}
