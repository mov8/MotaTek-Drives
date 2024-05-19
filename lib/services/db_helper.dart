// import 'dart:js_interop';

// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
//import 'package:flutter/widgets.dart';
import 'package:drives/models.dart';
import 'dart:async';
import 'dart:convert';

class dbHelper {
  Database? _db;

  dbHelper.privateConstructor() {
    /// Called once
    WidgetsFlutterBinding.ensureInitialized();
  }

  static final dbHelper instance = dbHelper.privateConstructor();

  factory dbHelper() {
    return instance;
  }

  Future<Database> get db async {
    return _db ??= await initDb();
  }
}

Future<Database> initDb() async {
  var dbPath = await getDatabasesPath();
  int newVersion = 1;
  String path = join(dbPath, 'drives.db');
  var newdb = await openDatabase(
    path,
    version: newVersion,
    onCreate: (Database db, int version) async {
      try {
        await db.execute(
            'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, forename TEXT, surname TEXT, email TEXT, password TEXT, imageUrl Text)'); //, locationId INTEGER, vehicleId INTEGER)');
        await db.execute(
            'CREATE TABLE groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, created DATETIME)'); //, locationId INTEGER, vehicleId INTEGER)');
        await db.execute(
            'CREATE TABLE group_members(id INTEGER PRIMARY KEY AUTOINCREMENT, forename TEXT, surname TEXT, email TEXT, status Integer, joined DATETIME, note TEXT, uri TEXT)'); //, locationId INTEGER, vehicleId INTEGER)');
        await db.execute(
            'CREATE TABLE notifications(id INTEGER PRIMARY KEY AUTOINCREMENT, sentBy TEXT, message TEXT, received DATETIME)'); //, locationId INTEGER, vehicleId INTEGER)');

/*
      homeItems will only come from the API 
      await db.execute(
        'CREATE TABLE homeItems(id INTEGER PRIMARY KEY AUTOINCREMENT,)'
      );
*/
        await db.execute(
            '''CREATE TABLE versions(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, downloaded DATETIME, major INTEGER, 
        minor INTEGER, patch INTEGER, status INTEGER )''');

        await db.execute(
            '''CREATE TABLE setup(id INTEGER PRIMARY KEY AUTOINCREMENT, route_colour INTEGER, good_route_colour INTEGER, 
          waypoint_colour INTEGER, waypoint_colour_2 INTEGER, point_of_interest_colour INTEGER, 
          point_of_interest_colour_2 INTEGER, selected_colour INTEGER, highlighted_colour INTEGER, 
          record_detail INTEGER, allow_notifications INTEGER,
          dark INTEGER) ''');

        await db.execute(
            '''CREATE TABLE drives(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, title TEXT, sub_title TEXT, body TEXT, 
          images TEXT, max_lat REAL, min_lat REAL, max_long REAL, min_long REAL, added DATETIME)''');

        await db.execute(
            '''CREATE TABLE points_of_interest(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, drive_id INTEGER, type INTEGER, 
          name TEXT, description TEXT, images TEXT, latitude REAL, longitude REAL)''');

        /// SQLite does have JSON capabilities
        /// INSERT INTO users (name, data) VALUES ('John', '{"age:": 30, "country": "USA"});
        /// SELECT name, JSON_EXTRACT(data, '$.age') AS age FROM users; // will return all names and ages
        /// See JSON_QUERY, JSON_MODIFY
        /// SELECT * FROM users WHERE data LIKE '%"country":"USA"%';

        await db.execute(
            '''CREATE TABLE polylines(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, drive_id INTEGER, type INTEGER, points TEXT, 
    color Integer, stroke INTEGER)''');
/*
      await db.execute(
          '''CREATE TABLE images(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, drive_id INTEGER, 
      pointOfInterestId INTEGER, title TEXT, url TEXT)''');
*/
        await db.execute(
          '''CREATE TABLE log(id INTEGER PRIMARY KEY AUTOINCREMENT, monitor INTEGER, dateTime DATETIME, portNumber INTEGER, 
              value REAL, alarm INTEGER)''',
        );
      } catch (e) {
        debugPrint('Error creating tables: ${e.toString()}');
      }
    },
  );
  return newdb;
}

Future<int> recordCount(table) async {
  final db = await dbHelper().db;
  final count =
      Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT (*) FROM $table"));

  return count!;
}

alterTable() async {
  /*
  final db = await dbHelper().db;
  try {
    await db.execute('DROP TABLE IF EXISTS setup').then((_) {
      db.execute(
          '''CREATE TABLE setup(id INTEGER PRIMARY KEY AUTOINCREMENT, route_colour INTEGER, good_route_colour INTEGER, 
          waypoint_colour INTEGER, waypoint_colour_2 INTEGER, point_of_interest_colour INTEGER, 
          point_of_interest_colour_2 INTEGER, record_detail INTEGER, allow_notifications INTEGER,
          dark INTEGER) ''');
    });
  } catch (e) {
    debugPrint('Alter table error: ${e.toString()}');
  }
  */
}

Future<List<Map<String, dynamic>>> getSetup(int id) async {
  Database db = await dbHelper().db;
  // int records = await recordCount('setup');
  // if (records > 0){
  try {
    List<Map<String, dynamic>> maps =
        await db.query('setup', where: 'id >= ?', whereArgs: [id], limit: 1);
    return maps;
  } catch (e) {
    debugPrint('Error loading Setup ${e.toString()}');
  }
  // }
  throw ('Error ');
}

Future<User> getUser() async {
  final db = await dbHelper().db;
  int id = 0;
  String forename = '';
  String surname = '';
  String email = '';
  String password = '';
  String imageUrl = '';
  try {
    var maps = await db.rawQuery("SELECT * FROM Users");
    if (maps.isNotEmpty) {
      id = int.parse(maps[0]['id'].toString());
      forename = maps[0]['forename'].toString();
      surname = maps[0]['surname'].toString();
      email = maps[0]['email'].toString();
      password = maps[0]['password'].toString();
      imageUrl = maps[0]['imageUrl'].toString();
    }
  } catch (e) {
    debugPrint('Error retrieving user');
  }
  return User(
    id: id,
    forename: forename,
    surname: surname,
    email: email,
    password: password,
    imageUrl: imageUrl,
  );
}

Future<int> insertSetup(Setup setup) async {
  final db = await dbHelper().db;
  try {
    int records = await recordCount('setup');
    if (records < 1) {
      final insertedId = await db.insert(
        'setup',
        setup.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return insertedId;
    } else {
      await db.update('setup', setup.toMap(),
          where: 'id = ?', whereArgs: [setup.id]);
      return setup.id;
    }
  } catch (e) {
    debugPrint('Error witing setup : ${e.toString()}');
    return -1;
  }
}

Future<void> updateSetup() async {
  final db = await dbHelper().db;
  try {
    await db.update(
      'setup',
      Setup().toMap(),
      where: 'id = ?',
      whereArgs: [Setup().id],
    );
  } catch (e) {
    debugPrint('updateSetup error: ${e.toString()}');
  }
}

Future<int> saveUser(User user) async {
  final db = await dbHelper().db;
  var userRecords = await recordCount('users');
  try {
    if (userRecords > 0) {
      await db.update(
        'versions',
        user.toMap(), // toMap will return a SQLite friendly map
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return user.id;
    } else {
      final insertedId = await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      userRecords = await recordCount('users');
      debugPrint('Number of users: $userRecords');
      return insertedId;
    }
  } catch (e) {
    debugPrint('Error witing user : ${e.toString()}');
    return -1;
  }
}

Future<Drive> getDrive(int driveId) async {
  int id = 0;
  int userId = 0;
  String title = '';
  String subTitle = '';
  String body = '';
  DateTime added = DateTime.now();
  double maxLat = 0.0;
  double minLat = 0.0;
  double maxLong = 0.0;
  double minLong = 0.0;
  final db = await dbHelper().db;
  try {
    String query = "SELECT * FROM drives WHERE if = $driveId";
    var maps = await db.rawQuery(query);
    id = int.parse(maps[0]['id'].toString());
    userId = int.parse(maps[0]['user_id'].toString());
    title = maps[0]['title'].toString();
    subTitle = maps[0]['sub_title'].toString();
    body = maps[0]['body'].toString();
    added = DateTime.parse(maps[0]['date'].toString());
    maxLat = double.parse(maps[0]['max_lat'].toString());
    minLat = double.parse(maps[0]['min_lat'].toString());
    maxLong = double.parse(maps[0]['max_long'].toString());
    minLong = double.parse(maps[0]['min_long'].toString());
  } catch (e) {
    debugPrint('dbError:${e.toString()}');
  }
  return Drive(
      id: id,
      userId: userId,
      title: title,
      subTitle: subTitle,
      body: body,
      added: added,
      maxLat: maxLat,
      minLat: minLat,
      maxLong: maxLong,
      minLong: minLong);
}

Future<int> saveDrive({required Drive drive}) async {
  final db = await dbHelper().db;
  int id = -1;
  try {
    if (drive.id > 0) {
      id = drive.id;
      await db.update('drives', drive.toMap(),
          where: 'id = ?',
          whereArgs: [id],
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      id = await db.insert('drives', drive.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  } catch (e) {
    String err = e.toString();
    debugPrint("Database error storing drive: $err");
    return -1;
  }
  return id;
}

String pointsToString(List<LatLng> points) {
  String pointsMap = '';
  try {
    for (int i = 0; i < points.length; i++) {
      pointsMap =
          '$pointsMap{"lat":${points[i].latitude},"lon":${points[i].longitude}},';
    }
    if (pointsMap.isNotEmpty) {
      pointsMap = '[${pointsMap.substring(0, pointsMap.length - 1)}]';
    }
  } catch (e) {
    debugPrint('Serialisation error: ${e.toString()}');
  }
  return pointsMap;
}

// Save all the points of interest + their images
/* 
            '''CREATE TABLE points_of_interest(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, drive_id INTEGER, type INTEGER, 
          name TEXT, description TEXT, images TEXT, latitude REAL, longitude REAL)''');
*/

Future<bool> savePointsOfInterestLocal(
    {required int userId,
    required int driveId,
    required List<PointOfInterest> pointsOfInterest}) async {
  final db = await dbHelper().db;
  for (int i = 0; i < pointsOfInterest.length; i++) {
    int id = -1;
    Map<String, dynamic> poiMap = {
      'user_id': userId,
      'drive_id': driveId,
      'type': pointsOfInterest[i].type,
      'name': pointsOfInterest[i].name,
      'description': pointsOfInterest[i].description,
      'images': pointsOfInterest[i].images,

      /// Json [{'image': imageUrl, 'caption': imageCaption}, ...]
      'latitude': pointsOfInterest[i].markerPoint.latitude,
      'longitude': pointsOfInterest[i].markerPoint.longitude,
    };
    if (pointsOfInterest[i].id > -1) {
      id = pointsOfInterest[i].id;
      try {
        await db.update('points_of_interest', poiMap,
            where: 'id = ?',
            whereArgs: [id],
            conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (e) {
        debugPrint('Error saving points of interest: ${e.toString()}');
        return false;
      }
    } else {
      id = await db.insert(
        'points_of_interest',
        poiMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
  return true;
}

/// Saves the myTrips to the local SQLite database

Future<bool> savePolylinesLocal(
    {required int id,
    required int userId,
    required int driveId,
    required List<Polyline> polylines}) async {
  final db = await dbHelper().db;
  for (int i = 0; i < polylines.length; i++) {
    Map<String, dynamic> plMap = {
      'id': id,
      'user_id': userId,
      'drive_id': driveId,
      'points': pointsToString(polylines[i].points),
      'stroke': polylines[i].strokeWidth,
      'color': uiColours.keys
          .toList()
          .indexWhere((col) => col == polylines[i].color),
    };
    if (id > 0) {
      try {
        await db.update('polylines', plMap,
            conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (e) {
        debugPrint("Database error storing polylines: ${e.toString()}");
        return false;
      }
    } else {
      id = await db.insert(
        'polylines',
        plMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
  return true;
}

/// Get the polylines for a drive from SQLite
/// Will initially only load the descriptive details and only
/// load the details if the drive is selected

Future<List<Polyline>> loadPolyLinesLocal(int driveId) async {
  final db = await dbHelper().db;
  List<Polyline> polylines = [];
  List<Map<String, dynamic>> maps = await db.query(
    'polylines',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );

  for (int i = 0; i < maps.length; i++) {
    polylines.add(Polyline(
        points: stringToPoints(maps[i]['points']), // routePoints,
        color: uiColours.keys.toList()[maps[i]['color']],
        borderColor: uiColours.keys.toList()[maps[i]['color']],
        strokeWidth: maps[i]['stroke']));
  }
  return polylines;
}

List<LatLng> stringToPoints(String pointsString) {
  List<LatLng> points = [];
  try {
    var pointsJson = jsonDecode(pointsString);
    for (int i = 0; i < pointsJson.length; i++) {
      var jpoints = pointsJson[i];
      for (int j = 0; j < jpoints.length; j++) {
        points
            .add(LatLng(jpoints['lat'].toDouble(), jpoints['lon'].toDouble()));
      }
    }
  } catch (e) {
    debugPrint('Points convertion error: ${e.toString()}');
  }
  return points;
}

String polyLineToString(List<Polyline> polyLines) {
  Map<String, dynamic> json;

  String color = Colors.black.toString();
  String points = '';
  String polyLineString = '';

  List<LatLng> testValues = [];

  try {
    for (int i = 0; i < polyLines.length; i++) {
      color = polyLines[i].color.toString();
      points = pointsToString(polyLines[i].points);
      testValues = stringToPoints(points);
      debugPrint('Values retrieved: ${testValues.length}');
      json = {'color': color, 'points': points};
      polyLineString = '$polyLineString${jsonEncode(json).toString()},';
    }
    if (polyLineString.isNotEmpty) {
      polyLineString = polyLineString.substring(0, polyLineString.length - 1);
    }
  } catch (e) {
    String err = e.toString();
    debugPrint('JsonEncode error: $err');
  }
  return polyLineString;
}
