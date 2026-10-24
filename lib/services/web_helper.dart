import 'dart:async';
import 'package:universal_io/universal_io.dart';
import 'dart:convert';
import 'dart:typed_data';
import '/constants.dart';
import '/classes/classes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '/models/models.dart';
import '/services/services.dart';
import '/classes/route.dart' as mt;
import 'dart:developer' as developer;

Map<String, String> webHeader({bool secure = false}) {
  Map<String, String> header = {'Content-Type': 'application/json'};
  if (secure) {
    header['Authorization'] = 'Bearer ${Setup().jwt}';
  }
  return header;
}

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
    {String type = 'email', String value = '', bool secure = true}) async {
  List<dynamic> results = [];
  if (value.isNotEmpty) {
    try {
      final http.Response response = await getWebData(
          uri: Uri.parse('$urlUser/emails/$value/${secure ? 'True' : 'False'}'),
          secure: secure);
      if ([200, 201].contains(response.statusCode)) {
        results = jsonDecode(response.body);
      }
    } catch (e) {
      developer.log(
          'Error WebHelpers getApiOptions() getting api list ${e.toString()}, results.length() ${results.length}',
          name: 'error');
    }
  }
  return List<String>.from(results);
}

Future<List<String>> getApiContacts(
    {String type = 'email', String value = ''}) async {
  List<dynamic> results = [];
  if (value.isNotEmpty) {
    try {
      final http.Response response = await getWebData(
          uri: Uri.parse('$urlUser/contact_email/$value'), secure: true);
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

Future<Map<String, dynamic>> postUser(
    {required User user, bool register = false}) async {
  int code = 500;
  try {
    var uri = Uri.parse('$urlUser/${register ? "register" : "login"}');
    http.Response response =
        await postWebData(uri: uri, body: jsonEncode(user.toMapApi()));
    Map<String, dynamic> map = jsonDecode(response.body);
    code = response.statusCode;
    if ([200, 201].contains(code)) {
      Setup().jwt = map['token'];
      Setup().save();
      return {'msg': 'OK', 'code': code};
    } else {
      map['msg'] = 'error';
      map['code'] = 404;
      return map;
    }
  } catch (e) {
    debugPrint('Login error: ${e.toString()}');
  }
  return {'msg': 'error', 'code': code};
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
      Setup().save();
      return {'msg': 'OK'};
    } else {
      return map;
    }
  } catch (e) {
    debugPrint('Login error: ${e.toString()}');
  }
  return {'message': 'error'};
}

/// A fresh token for the saved one: the new token, '' if the server rejected
/// it (expired or invalid - the user has to log in again), or null if the
/// server couldn't be reached (offline - keep the saved one)
Future<String?> refreshToken() async {
  try {
    final http.Response response =
        await getWebData(uri: Uri.parse('$urlUser/token'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      Map<String, dynamic> data = jsonDecode(response.body);
      return data['token'] ?? '';
    }
    // The API answers 408 'jwt invalid' for a token it doesn't accept
    return [401, 403, 408, 422].contains(response.statusCode) ? '' : null;
  } catch (e) {
    developer.log('Error refreshing jwt token: ${e.toString()}', name: 'error');
    return null;
  }
}

Future<void> getUserDetails({required String email}) async {
  final http.Response response =
      // your own details - the API needs the login token
      await getWebData(uri: Uri.parse('$urlUser/user/$email'), secure: true);
  if ([200, 201].contains(response.statusCode)) {
    try {
      Map<String, dynamic> data = jsonDecode(response.body);
      // (it set Setup().jwt from a 'token' this route never sends, which
      // logged you out)
      Setup().user.forename = data['forename'] ?? '';
      Setup().user.surname = data['surname'] ?? '';
      Setup().user.email = email;
      Setup().user.phone = data['phone'] ?? '';
      Setup().user.type = data['type'] ?? 1;
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
      Setup().messageCount = data['messages'] ?? 0;
      Setup().tripCount = data['trips'] ?? 0;
      Setup().shopCount = data['shop'] ?? 0;
    } catch (e) {
      debugPrint('Error getting stats: ${e.toString()}');
    }
  }
}

Future<Map<String, dynamic>> tryLogin({required User user}) async {
  bool register = user.password.length <= 6;
  var uri = Uri.parse('$urlUser/${register ? "register" : "login"}');
  int code = 500;
  Map<String, dynamic> map = {};

  try {
    http.Response response =
        await postWebData(uri: uri, body: jsonEncode(user.toMap()));
    code = response.statusCode;

    if (response.body.isNotEmpty) {
      map = jsonDecode(response.body);
      if (code == 200) {
        Setup().user.forename = map['forename'];
        Setup().user.surname = map['surname'];
        Setup().user.phone = map['phone'];
        Setup().user.type = map['type'];
        Setup().jwt = map['token'];
        Setup().saveUser();
        Setup().save();
        return {'msg': 'OK'};
      } else if (map.isNotEmpty) {
        return {'msg': map['msg'] ?? 'error', 'response_status_code': code};
      }
    } else {
      return {'msg': 'Data is empty'};
    }
  } catch (e) {
    developer.log(
        'Login error: ${e.toString()} status code: $code uri: $uri map: ${map.toString()}',
        name: 'error');
    return {'msg': map['msg'] ?? 'error', 'response_status_code': code};
  }
  return {'msg': 'Data is empty'};
}

Future<Map<String, dynamic>> getSetup(int id) async {
  var uri = Uri.parse('$urlUser/settings');
  final http.Response response = await getWebData(uri: uri, secure: true);
  if ([200, 201].contains(response.statusCode)) {
    try {
      Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      developer.log(
          'Error WebHelpers getSetup() http error getSetup(): ${e.toString()}',
          name: 'error');
    }
  }
  return {};
}

Future<dynamic> publish(MyTripItem tripItem) async {
  Map<String, dynamic> apiData = tripItem.toJson();
  dynamic response;
  try {
    /// The MyTripItem List<Image> images contains all the images for the whole drive including
    /// the points of interest. This is so that all images can be displayed in the MyTripTile
    /// As the whole trip is being published as a single Json object it makes sense to upload all
    /// the images in a single MultiPart.
    /// On the API as Drives are now downloaded as a single Json Object too it makes sense to again
    /// down load the images in a single MultiPart.
    /// To make life easier, and ensure that the order of the PointOfInterest images is correct they are to be named
    /// as {pointOfInterest.uri}_{imageNumber}.jpg. The pointOfInterest.uri will be generated on creation.
    /// On the API the POI files should have a new safe name generated, and both the
    /// The PointsOfInterest.Images can still hold the references to their own images to help reduce the
    /// work done by the app.
    /// Start the images list with the Drive map
    /// request.files.add(await http.MultipartFile.fromPath('map', photos[0].url));

    /// Images are stored in Hive (ImageRepository) - only trips saved before
    /// that have them as files - so each is read by its key.
    ImageRepository imageRepository = ImageRepository();
    List<http.MultipartFile> files = [];

    // The trip's first image is its map
    List<Photo> tripPhotos = tripItem.images.isEmpty
        ? []
        : photosFromJson(photoString: tripItem.images);
    if (tripPhotos.isNotEmpty) {
      Uint8List? bytes = await _photoBytes(tripPhotos.first, imageRepository);
      if (bytes != null) {
        files.add(
          http.MultipartFile.fromBytes(
              'files', // <-- Must have this as it is used on api request.files.getlist('files')
              bytes,
              filename: 'map.png'),
        );
      }
    }

    for (PointOfInterest pointOfInterest in tripItem.pointsOfInterest) {
      List<Photo> photos = pointOfInterest.photos.isNotEmpty
          ? pointOfInterest.photos
          : pointOfInterest.images.isEmpty
              ? []
              : photosFromJson(photoString: pointOfInterest.images);
      for (int j = 0; j < photos.length; j++) {
        try {
          Uint8List? bytes = await _photoBytes(photos[j], imageRepository);
          if (bytes != null) {
            files.add(
              http.MultipartFile.fromBytes(
                'files',
                bytes,
                filename: '${pointOfInterest.uuid}_${j + 1}.jpg',
              ),
            );
          }
        } catch (e) {
          developer.log('Error WebHelper publish() ${e.toString()}',
              name: 'error');
        }
      }
    }
    var request = http.MultipartRequest('POST', Uri.parse('$urlDrive/publish'));
    request.headers['Authorization'] = 'Bearer ${Setup().jwt}';
    request.fields['data'] = jsonEncode(apiData);
    request.files.addAll(files);
    response = await request.send().timeout(const Duration(seconds: 30));
    return response.statusCode;
  } catch (e) {
    developer.log(
        'Error WebHelper publish() ${e.toString()} ${response?.statusCode}',
        name: 'error');
  }
  return ' ';
}

/// A photo's image bytes - from Hive by its key (photo.key, or the 32
/// character name in its url), or from its file for a trip saved before
/// images were kept in Hive. Null if it can't be found.
Future<Uint8List?> _photoBytes(
    Photo photo, ImageRepository imageRepository) async {
  String key = photo.key.isNotEmpty ? photo.key : getFileName(url: photo.url);
  Uint8List? bytes = await imageRepository.imageBytes(key);
  if (bytes != null) return bytes;
  if (!kIsWeb && photo.url.isNotEmpty && await File(photo.url).exists()) {
    return await File(photo.url).readAsBytes();
  }
  return null;
}

Future<String> postWithPhotos(
    {required String url,
    Map<String, dynamic> fields = const {},
    List<Photo> photos = const [],
    int timeout = 20}) async {
  var request = http.MultipartRequest('POST', Uri.parse(url));

  dynamic response;
  try {
    request.headers['Authorization'] = 'Bearer ${Setup().jwt}';
    fields.forEach((key, value) => request.fields[key] = value.toString());
    // Images are in Hive (or files for older ones) - see _photoBytes()
    ImageRepository imageRepository = ImageRepository();
    for (Photo photo in photos) {
      Uint8List? bytes = await _photoBytes(photo, imageRepository);
      if (bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('files', bytes,
            filename: photo.url.split('/').last));
      }
    }
    response = await request.send().timeout(Duration(seconds: timeout));
    if (response.statusCode == 201) {
      dynamic responseData = await response.stream.bytesToString();
      return jsonEncode(responseData);
    } else {
      return jsonEncode({'token': '', 'code': response.statusCode});
    }
  } catch (e) {
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting trip: ${e.toString()}');
    }
  }
  return '';
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

mt.Route polylineFromMap(
    {required Map<String, dynamic> map,
    bool goodRoad = false,
    int driveKey = -1}) {
  return mt.Route(
    lines: [],
    id: -1,
  );
}

Future<List<PointOfInterest>> getPointsOfInterest(ne, sw) async {
  List<PointOfInterest> pointsOfInterest = [];

  final http.Response response = await http
      .get(
        Uri.parse(
            '$urlPointOfInterest/location/${sw.latitude}/${ne.latitude}/${sw.longitude}/${ne.longitude}'),
        headers: webHeader(),
      )
      .timeout(const Duration(seconds: 20));
  if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
    List pois = jsonDecode(response.body);
    for (int i = 0; i < pois.length; i++) {
      pointsOfInterest.add(PointOfInterest.fromMap(map: pois[i]));
    }
  }

  return pointsOfInterest;
}

Future<bool> postOsmReview({required Map<String, dynamic> reviewMap}) async {
  http.Response response = await postWebData(
      uri: Uri.parse('$urlOsmReview/add'),
      body: jsonEncode(reviewMap),
      secure: true,
      timeout: 5);

  return (response.statusCode == 201);
}

Future<List<dynamic>> getOsmReviews({required String osmId}) async {
  http.Response response =
      await getWebData(uri: Uri.parse('$urlOsmReview/$osmId'));
  if (response.statusCode == 200) {
    try {
      List<dynamic> dataJson = jsonDecode(response.body);
      return dataJson;
    } catch (e) {
      debugPrint('Error ${e.toString()}');
      return [];
    }
  } else {
    return [];
  }
}

Future<PointOfInterest> getPointOfInterest(
    {String uri = '', int index = 0}) async {
  final http.Response response = await http
      .get(
        Uri.parse('$urlPointOfInterest/$uri'),
        headers: webHeader(),
      )
      .timeout(const Duration(seconds: 10));
  if ([200, 201].contains(response.statusCode) && response.body.length > 10) {
    dynamic map = jsonDecode(response.body);
    PointOfInterest pointOfInterest = PointOfInterest.fromMap(map: map);
    return pointOfInterest;
  } else {
    return PointOfInterest(name: '');
  }
}

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
    if (urls.isNotEmpty) {}
    return urls;
  }
  return [];
}

Future<String> postManeuver(Maneuver maneuver, String driveUid) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlManeuver/add'),
      body: jsonEncode(maneuver.toMap(driveUid: driveUid)));
  if ([200, 201].contains(response.statusCode)) {
    return jsonEncode({'code': response.statusCode});
  } else {
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

Future<String> postManeuvers(List<Maneuver> maneuvers, String driveUid) async {
  List<Map<String, dynamic>> maps = [];
  for (int i = 0; i < maneuvers.length; i++) {
    maps.add(maneuvers[i].toMap(driveUid: driveUid));
  }

  if (maps.isEmpty) {
    return jsonEncode({'message': 'no maneuvers to post'});
  }
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlManeuver/add'), body: jsonEncode(maps), secure: true);
  if (response.statusCode == 201) {
    return jsonEncode({'code': response.statusCode});
  } else {
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}

/// getFeatures returns all the features from the API
/// type 1: drives
/// type 2: points of interest excluding type 12 ad 16
/// type 3: good roads

/// Every published trip, newest first - for the admin screens (admins only)
Future<List<TripSummary>> getTripSummaries() async {
  List<TripSummary> summaries = [];
  try {
    final http.Response response =
        await getWebData(uri: Uri.parse('$urlDrive/summaries'), secure: true);
    if (response.statusCode == 200) {
      for (Map<String, dynamic> trip in jsonDecode(response.body)) {
        summaries.add(TripSummary.fromMap(map: trip));
      }
    } else {
      developer.log('getTripSummaries(): ${response.statusCode}', name: 'error');
    }
  } catch (e) {
    developer.log('getTripSummaries(): ${e.toString()}', name: 'error');
  }
  return summaries;
}

Future<List<TripItem>> getTrips() async {
  List<TripItem> trips = [];
  return trips;
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
  List<Photo> photos = [];
  if (tripId.length == 32) {
    final http.Response response = await http
        .get(
          Uri.parse('$urlDrive/summary/$tripId'),
          headers: webHeader(secure: true),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      var trip = jsonDecode(response.body);
      List<String> images = [Uri.parse('${trip['id']}/map.png').toString()];
      photos.add(Photo(
          url: '$urlDrive/images/${trip['id']}/map.png',
          endPoint: '$urlDrive/${trip['id']}/'));
      try {
        int distance = 99999;
        for (int i = 0; i < trip['points_of_interest'].length; i++) {
          if (trip['points_of_interest'][i]['images'].length > 0) {
            photos.addAll(
              photosFromJson(
                photoString: trip['points_of_interest'][i]['images'],
                endPoint:
                    '$urlDrive/images/${trip['id']}/${trip['points_of_interest'][i]['id']}/',
              ),
            );
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
              title: trip['title'],
              subTitle: trip['sub_title'],
              body: (trip['body'] ?? '').replaceAll("\n", " "),
              author: trip['author'],
              published: trip['added'],
              photos: photos,
              imageUrls: imageListToString(imageList: images),
              score: trip['average_rating'].toDouble() ?? 5.0,
              distance: trip['distance'],
              pointsOfInterestCount: trip['points_of_interest'].length,
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
    // Construct the file path for saving the image

    // Write the image data to the file
    // "/data/user/0/com.example.drives/app_flutter/drive3/3f6c5f2e-d164-4349-8a30-1085d643387c.jpg"
    try {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      if (file.existsSync()) {}
    } catch (e) {}
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
  if ([200, 201].contains(response.statusCode)) {}
}

putPointOfInterestRating(String uri, double score) async {
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
  if ([200, 201].contains(response.statusCode)) {}
}

Future<Map<String, dynamic>> getPointOfInterestRating(String uri) async {
  Map<String, dynamic> rating = {'rating': '0.0'};
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

/// Gets all the information about a trip in one json object from the api
/// Drive - {id, title, sub_title, body, added, images, score, scored, distance, [routes], [maneuvers], [pointsOfInterest]}
/// [routes] uri drive_uri point_of_interest_uri points
/// [maneuvers] uri road_from road_to exit bearing_before bearing_after location modifier type distance
/// [pointsOfInterest] uri drive_id type name description images point
///
///
/// A whole published trip - routes, turn-by-turn instructions and points of
/// interest - e.g. a group drive's
Future<MyTripItem> getMyTrip(String tripUuid) async {
  try {
    final http.Response response = await http.get(
      Uri.parse('$urlDrive/$tripUuid'),
      headers: webHeader(secure: false),
    );
    if (response.statusCode == 200) {
      return MyTripItem.fromApiJson(jsonDecode(response.body));
    }
    developer.log('getMyTrip(): ${response.statusCode}', name: 'error');
  } catch (e) {
    developer.log('getMyTrip(): ${e.toString()}', name: 'error');
  }
  return MyTripItem(title: '', subTitle: '');
}

Future<String> getSpeech(
    {String text = 'hello', String fileName = 'speech.mp3'}) async {
  final String directory = '${Setup().appDocumentDirectory}/sounds';
  File file = File('$directory/$fileName');

  final http.Response response = await http.post(
      Uri.parse('$urlTextToSpeech/send'),
      headers: webHeader(secure: false),
      body: jsonEncode(
          {'input': text, 'voice': Setup().maleVoice, 'file': fileName}));
  if ([200, 201].contains(response.statusCode)) {
    var bytes = response.bodyBytes;
    await file.writeAsBytes(bytes);
    return file.path;
  } else {
    return '';
  }
}

Future<String> getDocs() async {
  final response = await http.get(Uri.parse(
      'http://127.0.0.1:1313/docs/')); //Uri.parse(urlDocs)); //'https://motatek.com'));

  if (response.statusCode == 200) {
    return response.body;
  }
  return 'error: ${response.statusCode}';
}

Future<bool> putIntroduced(Map<String, dynamic> invitee) async {
  final http.Response response = await http.post(
      Uri.parse('$urlIntroduced/put'),
      headers: webHeader(secure: true),
      body: jsonEncode(invitee));
  return [200, 201].contains(response.statusCode);
}

deleteWebImage(String url) async {
  final http.Response response = await http.post(Uri.parse(url),
      headers: webHeader(), body: jsonEncode('"id": "delete_image"'));
  if ([200, 201].contains(response.statusCode)) {}
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
      child: Image.network(
        imageUrl,
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
  );
}

Future<File> downloadImage({String apiUrl = '', String targetFile = ''}) async {
  File file = File(targetFile);

  if (file.existsSync()) {
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
      }
    } catch (e) {
      debugPrint('Error writing to image file: ${e.toString}');
    }
  }
  return file;
}

bool canDelete(bool ok, String url, int index) {
  if (ok) {
    return true;
  } else {
    return false;
  }
}

Future<List<Group>> getManagedGroups() async {
  List<Group> groups = [];
  try {
    final http.Response response =
        await getWebData(uri: Uri.parse('$urlGroup/managed'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var groupsData = jsonDecode(response.body);
      for (Map<String, dynamic> groupData in groupsData) {
        Group group = Group(
            id: groupData['id'],
            name: groupData['name'],
            userId: groupData['user_id']);
        List<GroupMember> members = [];
        for (Map<String, dynamic> memberData in groupData['members']) {
          GroupMember member = GroupMember(
              id: memberData['id'],
              groupId: groupData['id'],
              forename: memberData['forename'],
              surname: memberData['surname'],
              phone: memberData['phone'],
              email: memberData['email']);
          members.add(member);
        }
        group.setGroupMembers(members);
        groups.add(group);
      }
      return groups;
    } else {
      return [];
    }
  } catch (e) {
    debugPrint("Can't access data on the web");
    return [];
  }
}

Future<bool> serverListening() async {
  try {
    final http.Response response = await http
        .get(
          Uri.parse('$urlUser/test'),
        )
        .timeout(const Duration(seconds: 10));
    return (response.statusCode == 200);
  } catch (e) {
    developer.log(
        'WebHelper serverListening() Error checking for server: ${e.toString()}',
        name: 'error');
    return false;
  }
}

Future<bool> apiListening() async {
  try {
    final http.Response response = await http
        .get(
          Uri.parse('$urlUser/test'),
        )
        .timeout(const Duration(seconds: 10));
    return (response.statusCode == 200);
  } catch (e) {
    debugPrint('Error checking for server: ${e.toString()}');
    return false;
  }
}

Future<String> getStyle({required String url}) async {
  try {
    final http.Response response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    return response.body;
  } catch (e) {
    debugPrint('Error ${e.toString()}');
    return 'Error ${e.toString()}';
  }
}

Future<List<Group>> getMyGroups() async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlGroup/mine'), secure: true, timeout: 5);
    if (response.statusCode == 200) {
      var groups = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> groupData in groups)
          Group.fromMyGroupsMap(groupData)
      ];
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}

Future<Map<String, dynamic>> updateGroups(
    {required List<Group> groups, required GroupAction action}) async {
  List<Map<String, dynamic>> groupsMaps = [];
  for (int i = 0; i < groups.length; i++) {
    groupsMaps.add(groups[i].toMap());
  }
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlGroup/${action.name}'),
      body: jsonEncode(groupsMaps),
      secure: true,
      timeout: 5);
  if ([200, 201].contains(response.statusCode)) {
    return {'msg': 'OK'};
  }
  return {'msg': 'error'};
}

Future<List<MailItem>> getMessagesByGroup() async {
  List<MailItem> mailItems = [];
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlMessage/all_messages'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var groups = jsonDecode(response.body);
      for (Map<String, dynamic> groupData in groups) {
        mailItems.add(MailItem.fromMap(groupData));
      }
      return mailItems;
    } else {
      developer.log(
          'getMessagesByGroup(): ${response.statusCode} ${response.body}',
          name: 'error');
      return mailItems;
    }
  } catch (e) {
    debugPrint("Can't access message data on the web ${e.toString()}");
    return mailItems;
  }
}

Future<List<Message>> getGroupMessages(String groupId) async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlMessage/group/$groupId'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var messages = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> messageData in messages)
          Message.fromMap(
            messageData,
          )
      ];
    } else {
      return [];
    }
  } catch (e) {
    developer.log(
        'Error WebHelper getGroupMessages() retuning NO data from api',
        name: 'error');
    return [];
  }
}

Future<List<Message>> getUserMessages(String userId) async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlMessage/user/$userId'), secure: true);
    if ([200, 201].contains(response.statusCode)) {
      var messages = jsonDecode(response.body);
      List<Message> messageList = [];
      for (Map<String, dynamic> messageData in messages) {
        messageList.add(
          Message.fromMap(
            messageData,
          ),
        );
      }
      return messageList;
    } else {
      return [];
    }
  } catch (e) {
    developer.log(
        'Error WebHelper getUserMessages() retuning NO data from api ${e.toString()}',
        name: 'error');
    return [];
  }
}

/// getHomeItems gets a list of home articles for the home screen
/// The scope parameter isn't yet implemented, but is to allow
/// some selection of who sees what on the home page
/// This has been removed since the json version of homeItems was implemented

dynamic getGeoJson(
    {Map<String, dynamic> boundingBox = const {},
    List exclude = const [],
    double zoom = 14}) async {
  Map<String, dynamic> data = {
    "exclude": exclude,
    "zoom": zoom,
    "b_box": boundingBox
  };

  Uri uri = Uri.parse('$urlDrive/great_drives');
  http.Response response = await postWebData(uri: uri, body: jsonEncode(data));
  if ([200, 201].contains(response.statusCode)) {
    return response.body;
  }
  return {};
}

dynamic getGoodRoadsGeoJson(
    {Map<String, dynamic> boundingBox = const {},
    List exclude = const [],
    double zoom = 14}) async {
  Map<String, dynamic> data = {
    "exclude": exclude,
    "zoom": zoom,
    "b_box": boundingBox,
    "color": Setup().goodRouteColourHex()
  };

  Uri uri = Uri.parse('$urlDrive/good_roads');
  http.Response response = await postWebData(uri: uri, body: jsonEncode(data));
  if ([200, 201].contains(response.statusCode)) {
    return response.body;
  }
  return {};
}

dynamic getPointsOfInterestGeoJson(
    {Map<String, dynamic> boundingBox = const {},
    List exclude = const [],
    double zoom = 14,
    String driveId = '',
    List types = const []}) async {
  Map<String, dynamic> data = {
    "exclude": exclude,
    "zoom": zoom,
    "b_box": boundingBox,
    "types": types,
    "drive_id": driveId
  };

  Uri uri = Uri.parse('$urlDrive/points_of_interest');
  http.Response response = await postWebData(uri: uri, body: jsonEncode(data));
  if ([200, 201].contains(response.statusCode)) {
    return response.body;
  }
  return {};
}

dynamic getTripDetails({required String uuid}) async {
  Uri uri = Uri.parse('$urlDrive/details/$uuid');
  http.Response response = await getWebData(uri: uri);
  var detail;
  if ([200, 201].contains(response.statusCode)) {
    try {
      detail = jsonDecode(response.body);
    } catch (e) {
      debugPrint('error decoding json: ${e.toString()}');
    }
  } else {
    developer.log(
        'Error WebHelper getTripDetails() http error trying to fetch trip details status code: ${response.statusCode}',
        name: 'error');
  }
  return detail;
}

Future<List<Map<String, dynamic>>> getMarkdownItems(
    {required String type}) async {
  String url = type == 'home' ? urlHomeItem : urlShopItem;
  http.Response response =
      await getWebData(uri: Uri.parse('$url/get'), secure: true);
  if (response.statusCode == 200) {
    try {
      List<dynamic> items = jsonDecode(response.body);
      List<Map<String, dynamic>> mapList =
          List<Map<String, dynamic>>.from(items);
      return mapList;
    } catch (e) {
      debugPrint('Error processing summaries: ${e.toString()}');
    }
  }
  return [];
}

Future<bool> deleteMarkdownItem(type, uri) async {
  String markdownUri =
      type == 'home' ? '$urlHomeItem/delete' : '$urlShopItem/delete';
  // The request was built and thrown away, so delete never sent anything
  var request = http.MultipartRequest('POST', Uri.parse(markdownUri));
  try {
    request.headers['Authorization'] = 'Bearer ${Setup().jwt}';
    request.fields['uri'] = uri;
    http.StreamedResponse response =
        await request.send().timeout(const Duration(seconds: 30));
    if ([200, 201].contains(response.statusCode)) {
      return true;
    }
  } catch (e) {
    if (e is TimeoutException) {
      debugPrint('Request timed out');
    } else {
      debugPrint('Error posting $type markdown to api: ${e.toString()}');
    }
  }

  return false;
}

Future<String> postMarkdownItem(
    String uri, String type, Map<String, dynamic> mapItem) async {
  // A new item or an edited one - publish saves either
  String markdownUri =
      type == 'home' ? '$urlHomeItem/publish' : '$urlShopItem/publish';
  var request = http.MultipartRequest('POST', Uri.parse(markdownUri));

  try {
    request.headers['Authorization'] = 'Bearer ${Setup().jwt}';
    request.fields['data'] = jsonEncode(mapItem);
    if (mapItem['images']!.isNotEmpty) {
      for (int i = 0; i < mapItem['images']!.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            MarkdownService().imageRepository.getBytes(
                  key: mapItem['images']![i]['key'],
                ),
            filename: mapItem['images']![i]['url'],
          ),
        );
      }
    }
    await request.send().timeout(const Duration(seconds: 30));
    return 'OK';
  } catch (e) {
    if (e is TimeoutException) {
      developer.log('Request timed out', name: 'error');
    } else {
      developer.log('Error posting article: ${e.toString()}', name: 'error');
    }
    return 'error posting $type markdown: ${e.toString()}';
  }
}

Future<List<EventInvitation>> getInvitationsByUser({int state = 0}) async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlGroupDriveInvitation/user/$state'), secure: true);

    if ([200, 201].contains(response.statusCode)) {
      var invitations = jsonDecode(response.body);
      return [
        for (Map<String, dynamic> invitation in invitations)
          EventInvitation.fromByUserMap(invitation)
      ];
    }
  } catch (e) {}
  return [];
}

Future<bool> respondToInvitations(
    {required Map<String, dynamic> responses}) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlGroupDriveInvitation/respond'),
      body: jsonEncode(responses),
      secure: true);
  if ([200, 201].contains(response.statusCode)) {
    return true;
  } else {
    return false;
  }
}

Future<int> inviteWebUser({required String body}) async {
  var uri = Uri.parse('$urlUser/apk_request');
  http.Response response =
      await postWebData(uri: uri, body: body, secure: true);
  return response.statusCode;
}

Future<List<GroupDriveByGroup>> getMembersByGroup() async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlGroupDrive/group'), secure: true, timeout: 3);
    if ([200, 201].contains(response.statusCode)) {
      var drivers = jsonDecode(response.body);
      List<GroupDriveByGroup> drives = [];
      for (Map<String, dynamic> driver in drivers) {
        drives.add(GroupDriveByGroup.fromMap(map: driver));
      }
      return drives;
    }
  } catch (e) {
    debugPrint("Can't access data on the web: ${e.toString()}");
  }
  return [];
}

Future<List<GroupEvent>> getMembersByDrive({DateTime? startDate}) async {
  try {
    startDate = startDate ?? DateTime.now();
    final http.Response response = await getWebData(
        uri: Uri.parse(
            '$urlGroupDrive/my_drives/${dateFormatSQL.format(startDate)}'),
        secure: true,
        timeout: 3);
    if ([200, 201].contains(response.statusCode)) {
      var drivers = jsonDecode(response.body);
      List<GroupEvent> drives = [];
      for (Map<String, dynamic> driver in drivers) {
        drives.add(GroupEvent.fromMap(map: driver));
      }
      return drives;
    } else {
      return [];
    }
  } catch (e) {
    debugPrint("Can't access data on the web: ${e.toString()}");
    return [];
  }
}

Future<String> postGroupDrive(
    {required Map<String, dynamic> invitations}) async {
  final http.Response response = await postWebData(
      uri: Uri.parse('$urlGroupDrive/add'),
      body: jsonEncode(invitations),
      secure: true);
  if ([200, 201].contains(response.statusCode)) {
    return response.body;
  }
  return '';
}

Future<List<Follower>> getDrivers(
    {required String groupDriveId, int accepted = 2}) async {
  List<Follower> followers = [];
  final http.Response response = await getWebData(
      uri: Uri.parse(
          '$urlGroupDriveInvitation/$groupDriveId/${accepted.toString()}'),
      secure: true);
  if (response.statusCode == 201) {
    var followersMap = jsonDecode(response.body);

    for (Map<String, dynamic> followerMap in followersMap) {
      followers.add(Follower.fromParticipantMap(map: followerMap));
    }
    return followers;
  } else {
    return [];
  }
}

Future<GroupMember> getUserByEmail(String email) async {
  try {
    final http.Response response = await postWebData(
        uri: Uri.parse('$urlUser/get_user_by_email'),
        body: jsonEncode({"email": email}));

    if (response.statusCode == 200) {
      return GroupMember.fromUserMap(jsonDecode(response.body));
    } else {
      return GroupMember(forename: 'Not', surname: 'Registered', email: email);
    }
  } catch (e) {
    debugPrint("Can't access data on the web: ${e.toString()}");
    return GroupMember(forename: 'Not', surname: 'Registered', email: email);
  }
}

Future<bool> checkEmail({required String email}) async {
  try {
    final http.Response response = await getWebData(
        uri: Uri.parse('$urlUser/check/${email.toLowerCase()}'), secure: false);
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('Error ${e.toString()}');
    return false;
  }
}
