import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
// import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';
import 'package:drives/models.dart';
import 'dart:async';

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
  String path = '';
  // join(dbPath, 'autoguard.db');
  var newdb = await openDatabase(
    path,
    version: newVersion,
    onCreate: (Database db, int version) async {
      await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, forename TEXT, surname TEXT, email TEXT, password TEXT, imageUrl Text)'); //, locationId INTEGER, vehicleId INTEGER)');
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
          '''CREATE TABLE setup(id INTEGER PRIMARY KEY AUTOINCREMENT, keepAlive INTEGER, notifications INTEGER,
              lockSetup INTEGER, record INTEGER, recordRate INTEGER, playRate INTEGER, dark INTEGER) ''');

      await db.execute(
          '''CREATE TABLE drives(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, name TEXT, description TEXT, 
          maxLat REAL, minLat REAL, maxLong REAL, minLong REAL, added DATETIME)''');

      await db.execute(
          '''CREATE TABLE wayPoints(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, driveId INTEGER, type INTEGER, 
          description TEXT, hint TEXT, latitude REAL, longitude REAL)''');

      /// SQLite does have JSON capabilities
      /// INSERT INTO users (name, data) VALUES ('John', '{"age:": 30, "country": "USA"});
      /// SELECT name, JSON_EXTRACT(data, '$.age') AS age FROM users; // will return all names and ages
      /// See JSON_QUERY, JSON_MODIFY
      /// SELECT * FROM users WHERE data LIKE '%"country":"USA"%';

      await db.execute(
          '''CREATE TABLE polyLines(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, driveId INTEGER, points TEXT, 
    colour TEXT, stroke INTEGER)''');

      await db.execute(
        '''CREATE TABLE log(id INTEGER PRIMARY KEY AUTOINCREMENT, monitor INTEGER, dateTime DATETIME, portNumber INTEGER, 
              value REAL, alarm INTEGER)''',
      );
    },
    onUpgrade: (Database db, int oldVersion, int newVersion) async {
      await db.execute('ALTER TABLE ports ADD COLUMN value INTEGER');
      await db.execute('ALTER TABLE gauges ADD COLUMN notification TEXT');
    },
    onDowngrade: (Database db, int oldVersion, int newVersion) async {
      await db.execute('DROP TABLE IF EXISTS gauges');
      await db.execute('DROP TABLE IF EXISTS ports');

      await db.execute(
          '''CREATE TABLE ports(id INTEGER PRIMARY KEY AUTOINCREMENT, monitor INTEGER, portNumber INTEGER, name TEXT,
            value REAL, type INTEGER, unit TEXT, minValue REAL, minRaw REAL, minReal REAL, redLine REAL, warning REAL, 
            maxValue REAL, maxRaw REAL, maxReal REAL, latency INTEGER, volume INTEGER, inverse INTEGER)''');

      await db.execute(
          '''CREATE TABLE gauges(id INTEGER PRIMARY KEY AUTOINCREMENT, monitor INTEGER, portNumber INTEGER, type INTEGER,
            size INTEGER, positionXp REAL, positionYp REAL, positionXl REAL, positionYl REAL, damping INTEGER, 
            isDecimal INTEGER, notification TEXT)''');
    },
  );
  return newdb;
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

Future<int> saveUser(User user) async {
  final db = await dbHelper().db;
  try {
    final insertedId = await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return insertedId;
  } catch (e) {
    debugPrint('Error witing user : ${e.toString()}');
    return -1;
  }
}

Future<Drive> getDrive(int driveId) async {
  int id = 0;
  int userId = 0;
  String name = '';
  String description = '';
  DateTime date = DateTime.now();
  double maxLat = 0.0;
  double minLat = 0.0;
  double maxLong = 0.0;
  double minLong = 0.0;
  final db = await dbHelper().db;
  try {
    String query = "SELECT * FROM drives WHERE if = $driveId";
    var maps = await db.rawQuery(query);
    id = int.parse(maps[0]['id'].toString());
    userId = int.parse(maps[0]['userId'].toString());
    name = maps[0]['name'].toString();
    description = maps[0]['description'].toString();
    date = DateTime.parse(maps[0]['date'].toString());
    maxLat = double.parse(maps[0]['maxLat'].toString());
    minLat = double.parse(maps[0]['minLat'].toString());
    maxLong = double.parse(maps[0]['maxLong'].toString());
    minLong = double.parse(maps[0]['minLong'].toString());
  } catch (e) {
    debugPrint('dbError:${e.toString()}');
  }
  return Drive(
      id: id,
      userId: userId,
      name: name,
      description: description,
      date: date,
      maxLat: maxLat,
      minLat: minLat,
      maxLong: maxLong,
      minLong: minLong);
}

Future<bool> saveDrive({required Drive drive}) async {
  final db = await dbHelper().db;
  try {
    await db.update('drives', drive.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  } catch (e) {
    debugPrint("Database error storing drive: ${e.toString()}");
    return false;
  }
  return true;
}

///          '''CREATE TABLE pointsOfInterest(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, driveId INTEGER, type INTEGER,
///          description TEXT, hint TEXT, latitude REAL, longitude REAL)''');

Future<WayPoint> getWayPoint(int id) async {
  int id = 0;
  int userId = 0;
  int driveId = 0;
  int type = 0;
  String description = '';
  String hint = '';
  double longitude = 0.0;
  double latitude = 0.0;
  final db = await dbHelper().db;
  try {
    String query = "SELECT * FROM drives WHERE if = $driveId";
    var maps = await db.rawQuery(query);
    id = int.parse(maps[0]['id'].toString());
    userId = int.parse(maps[0]['userId'].toString());
    driveId = int.parse(maps[0]['driveId'].toString());
    type = int.parse(maps[0]['type'].toString());
    description = maps[0]['description'].toString();
    hint = maps[0]['hint'].toString();
    longitude = double.parse(maps[0]['longitude'].toString());
    latitude = double.parse(maps[0]['latitude'].toString());
  } catch (e) {
    debugPrint('Database error getting point of interest: ${e.toString()}');
  }

  return WayPoint(
      id: id,
      userId: userId,
      driveId: driveId,
      type: type,
      description: description,
      hint: hint,
      markerPoint: LatLng(latitude, longitude));
}
