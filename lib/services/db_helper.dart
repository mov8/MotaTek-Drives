import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/models/models.dart';
import 'package:drives/services/web_helper.dart';
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
            '''CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, forename TEXT, surname TEXT, email TEXT, 
            phone TEXT, password TEXT, imageUrl Text)'''); //, locationId INTEGER, vehicleId INTEGER)');
        await db.execute(
            '''CREATE TABLE groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, 
            created DATETIME)'''); //, locationId INTEGER, vehicleId INTEGER)');
        await db.execute(
            '''CREATE TABLE group_members(id INTEGER PRIMARY KEY AUTOINCREMENT, group_ids STRING, forename TEXT, surname TEXT, 
            email TEXT, phone TEXT, status Integer, joined DATETIME, note TEXT, uri TEXT)'''); //, locationId INTEGER, vehicleId INTEGER)');
        await db.execute(
            '''CREATE TABLE notifications(id INTEGER PRIMARY KEY AUTOINCREMENT, sentBy TEXT, message TEXT, 
            received DATETIME)'''); //, locationId INTEGER, vehicleId INTEGER)');
        await db.execute(
            '''CREATE TABLE followers(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, forename TEXT, 
            surname TEXT, phone_number TEXT, car TEXT, registration TEXT, icon_colour INTEGER, position TEXT, 
            reported DATETIME)''');

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
          waypoint_colour INTEGER, waypoint_colour_2 INTEGER, point_of_interest_colour INTEGER, rotate_map INTEGER,
          point_of_interest_colour_2 INTEGER, selected_colour INTEGER, highlighted_colour INTEGER, 
          record_detail INTEGER, allow_notifications INTEGER, jwt TEXT, dark INTEGER, avoid_motorways INTEGER, 
          avoid_a_roads INTEGER, avoid_b_roads INTEGER, avoid_toll_roads INTEGER, avoid_ferries INTEGER)''');

        await db.execute(
            '''CREATE TABLE drives(id INTEGER PRIMARY KEY AUTOINCREMENT, uri TEXT, title TEXT, sub_title TEXT, body TEXT, 
          distance REAL, points_of_interest INTEGER, added DATETIME)''');

        await db.execute(
            '''CREATE TABLE points_of_interest(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, type INTEGER, 
          name TEXT, description TEXT, images TEXT, latitude REAL, longitude REAL)''');

        /// SQLite does have JSON capabilities
        /// INSERT INTO users (name, data) VALUES ('John', '{"age:": 30, "country": "USA"});
        /// SELECT name, JSON_EXTRACT(data, '$.age') AS age FROM users; // will return all names and ages
        /// See JSON_QUERY, JSON_MODIFY
        /// SELECT * FROM users WHERE data LIKE '%"country":"USA"%';

        await db.execute(
            '''CREATE TABLE maneuvers(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, road_from TEXT,
          road_to TEXT, bearing_before INTEGER, bearing_after INTEGER, exit INTEGER, location TEXT, 
          modifier TEXT, type TEXT, distance REAL)''');

        await db.execute(
            '''CREATE TABLE polylines(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, 
            type INTEGER, points TEXT, colour Integer, stroke INTEGER)''');

        await db.execute(
            '''CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, target_id INTEGER, message TEXT, 
        read INTEGER, received DATETIME)''');

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
  int? count = 0;
  final db = await dbHelper().db;
  count =
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
        //  await db.query('setup', where: 'id >= ?', whereArgs: [id], limit: 1);
        await db.query('setup', limit: 1);
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
  String phone = '';
  String password = '';
  String imageUrl = '';
  try {
    var maps = await db.rawQuery("SELECT * FROM Users LIMIT 1");
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
    phone: phone,
    password: password,
    imageUrl: imageUrl,
  );
}

Future<int> insertSetup(Setup setup) async {
  final db = await dbHelper().db;
  Map<String, dynamic> suMap = setup.toMap();
  try {
    suMap.remove('id');
  } catch (e) {
    debugPrint('Map.remove() error: ${e.toString()}');
  }
  try {
    int records = await recordCount('setup');
    if (records < 1) {
      final insertedId = await db.insert(
        'setup',
        suMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return insertedId;
    } else {
      await db.update('setup', suMap, where: 'id = ?', whereArgs: [setup.id]);
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
  Map<String, dynamic> usMap = user.toMap();
  try {
    usMap.remove('id');
  } catch (e) {
    debugPrint('Map.remove() error: ${e.toString()}');
  }
  try {
    if (userRecords > 0) {
      await db.update(
        'users',
        usMap, // toMap will return a SQLite friendly map
        where: 'id = ?',
        whereArgs: [user.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return user.id;
    } else {
      final insertedId = await db.insert(
        'users',
        usMap,
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

/*
Future<List<Group>> getGroups() async {
  final db = await dbHelper().db;
  List<Group> groups = [];
  try {
    List<Map<String, dynamic>> maps = await db.query(
      'groups',
    );

    for (int i = 0; i < maps.length; i++) {
      groups.add(Group(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
      ));
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  return groups;
}
*/
Future<List<Group>> loadGroups() async {
  final db = await dbHelper().db;
  List<Group> groups = [];
  try {
    List<Map<String, dynamic>> maps = await db.query(
      'groups',
    );

    for (int i = 0; i < maps.length; i++) {
      groups.add(Group(
          id: maps[i]['id'],
          name: maps[i]['name'],
          description: maps[i]['description']));
    }
  } catch (e) {
    String err = e.toString();
    debugPrint(err);
  }
  return groups;
}

Future<int> saveGroupLocal(Group group) async {
  /*
  final db = await dbHelper().db;
  int id = group.id;
  Map<String, dynamic> grMap = group.toMap();
  if (group.id < 0) {
    try {
      grMap.remove('id');
    } catch (e) {
      debugPrint('Map.remove() error: ${e.toString()}');
    }

    try {
      id = await db.insert(
        'groups',
        grMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (err) {
      String tError = err.toString();
      debugPrint('Error saving groups: $tError');
    }
  } else {
    await db.update('groups', grMap,
        where: 'id = ?',
        whereArgs: [group.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
*/
  return 1;
  //id;
}

Future<List<GroupMember>> loadGroupMembers() async {
  final db = await dbHelper().db;
  List<GroupMember> members = [];
  try {
    List<Map<String, dynamic>> maps = await db.query(
      'group_members',
    );

    for (int i = 0; i < maps.length; i++) {
      members.add(GroupMember(
          forename: maps[i]['forename'],
          surname: maps[i]['surname'],
          email: maps[i]['email'],
          phone: maps[i]['phone']));
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  return members;
}

Future<int> saveGroupMemberLocal(GroupMember groupMember) async {
  final db = await dbHelper().db;
  Map<String, dynamic> grMap = groupMember.toMap();
  int id = 1;
  // groupMember.id;
  if (id == -1) {
    try {
      grMap.remove('id');
    } catch (e) {
      debugPrint('Map.remove() error: ${e.toString()}');
    }

    try {
      id = await db.insert(
        'group_members',
        grMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (err) {
      String tError = err.toString();
      debugPrint('Error saving group memberss: $tError');
    }
  } else {
    try {
      await db.update('group_members', grMap,
          where: 'id = ?',
          whereArgs: [groupMember.id],
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      String err = e.toString();
      debugPrint(err);
    }
  }
  return id;
}

Future<void> deleteGroupMemberById(int id) async {
  final db = await dbHelper().db;
  await db.delete(
    'group_members',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<bool> saveGroupMembers(List<GroupMember> groupMembers) async {
  for (int i = 0; i < groupMembers.length; i++) {
    saveGroupMemberLocal(groupMembers[i]);
  }
  return true;
}

Future<int> saveMessage(MessageLocal message) async {
  final db = await dbHelper().db;
  Map<String, dynamic> meMap = message.toMap();
  int id = message.id;
  if (id == -1) {
    try {
      meMap.remove('id');
    } catch (e) {
      debugPrint('Map.remove() error: ${e.toString()}');
    }

    try {
      id = await db.insert(
        'messages',
        meMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (err) {
      String tError = err.toString();
      debugPrint('Error saving message: $tError');
    }
  } else {
    try {
      await db.update('messages', meMap,
          where: 'id = ?',
          whereArgs: [message.id],
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      String err = e.toString();
      debugPrint(err);
    }
  }
  return id;
}

Future<Map<String, dynamic>> getDrive(int driveId) async {
  final db = await dbHelper().db;
  var maps;
  try {
    String query = "SELECT * FROM drives WHERE id = $driveId";
    maps = await db.rawQuery(query);
  } catch (e) {
    debugPrint('dbError:${e.toString()}');
  }
  return {
    'id': int.parse(maps[0]['id'].toString()),
    'title': maps[0]['title'].toString(),
    'subTitle': maps[0]['sub_title'].toString(),
    'body': maps[0]['body'].toString(),
    'added': DateTime.parse(maps[0]['added'] as String),
    'distance': double.parse(maps[0]['distance'].toString()),
    'pois': int.parse(maps[0]['points_of_interest'].toString()),
    // 'pois': int.parse(maps[0]['points_of_interest'].toString()),
  };
}

Future<void> deleteDriveById(int id) async {
  final db = await dbHelper().db;
  await db.delete(
    'drives',
    where: 'id = ?',
    whereArgs: [id],
  );
}

//
Future<void> deleteDriveLocal({required int driveId}) async {
  await deletePolyLinesByDriveId(driveId);
  await deletePointOfInterestByDriveId(driveId);
  await deleteManeuversByDriveId(driveId);
  await deleteDriveById(driveId);
}

// "type 'int' is not a subtype of type 'Map<String, dynamic>'"
Future<int> saveDrive({required Drive drive}) async {
  final db = await dbHelper().db;
  int id = -1;
  Map<String, dynamic> drMap = drive.toMap();
  try {
    drMap = drMap.remove("id");
  } catch (e) {
    String err = e.toString();
    debugPrint('Error: $err');
  }
  try {
    if (drive.id > -1) {
      id = drive.id;

      await db.update('drives', drMap,
          where: 'id = ?',
          whereArgs: [id],
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      try {
        id = await db.insert(
          'drives',
          drMap,
        );
        // conflictAlgorithm: ConflictAlgorithm.fail);
        // "DatabaseException(UNIQUE constraint failed: drives.id (code 1555 SQLITE_CONSTRAINT_PRIMARYKEY)) sql 'INSERT INTO drives (id, use…"
      } catch (e) {
        String err = e.toString();
        debugPrint('Database error: $err');
      }
    }
  } catch (e) {
    String err = e.toString();
    debugPrint("Database error storing drive: $err");
    return -1;
  }
  return id;
}

Future<int> saveMyTripItem(MyTripItem myTripItem) async {
  final db = await dbHelper().db;
  int id = myTripItem.getId();
  Map<String, dynamic> map = myTripItem.toDrivesMap();
  try {
    if (id < 0) {
      map.remove("id");
      id = await db.insert('drives', map);
    } else {
      await db.update('drives', map,
          where: 'id = ?',
          whereArgs: [id],
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    // Now process Trip images that have been downloaded and are to be save locally
    if (myTripItem.getDriveUri().isNotEmpty) {
      final directory = (await getApplicationDocumentsDirectory()).path;
      for (PointOfInterest pointOfInterest in myTripItem.pointsOfInterest()) {
        if (pointOfInterest.getImages().isNotEmpty) {
          var pics = jsonDecode(pointOfInterest.getImages());
          String jsonImages = '';
          for (String pic in pics) {
            String url =
                Uri.parse('${urlBase}v1/drive/images${pointOfInterest.url}$pic')
                    .toString();
            bool dirExists = await Directory('$directory/drive$id').exists();
            if (!dirExists) {
              await Directory('$directory/drive$id').create();
            }

            String imagePath = '$directory/drive$id/$pic';
            await getAndSaveImage(url: url, filePath: imagePath);
            jsonImages = '$jsonImages,{"url":"$imagePath", "caption":""}';
          }
          pointOfInterest.setImages('[${jsonImages.substring(1)}]');
        }
      }
    }
    await savePointsOfInterestLocal(
        driveId: id, pointsOfInterest: myTripItem.pointsOfInterest());
    await savePolylinesLocal(
        driveId: id, polylines: myTripItem.routes(), type: 0);
    await savePolylinesLocal(
        driveId: id, polylines: myTripItem.goodRoads(), type: 1);
    await saveManeuversLocal(driveId: id, maneuvers: myTripItem.maneuvers());
  } catch (e) {
    String err = e.toString();
    debugPrint('Error: $err');
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

Future<List<PointOfInterest>> loadPointsOfInterestLocal(int driveId) async {
  final db = await dbHelper().db;
  List<PointOfInterest> pointsOfInterest = [];
  List<Map<String, dynamic>> maps = await db.query(
    'points_of_interest',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
  for (int i = 0; i < maps.length; i++) {
    pointsOfInterest.add(
      PointOfInterest(
        maps[i]['id'],
        driveId,
        maps[i]['type'],
        maps[i]['name'],
        maps[i]['description'],
        maps[i]['type'] == 12 ? 10 : 30,
        maps[i]['type'] == 12 ? 10 : 30,
        images: maps[i]['images'],
        markerPoint: LatLng(maps[i]['latitude'], maps[i]['longitude']),
        marker: MarkerWidget(type: maps[i]['type'], list: 0, listIndex: i),
      ),
    );
  }
  return pointsOfInterest;
}

Future<bool> savePointsOfInterestLocal(
    {required int driveId,
    required List<PointOfInterest> pointsOfInterest}) async {
  final db = await dbHelper().db;
  for (int i = 0; i < pointsOfInterest.length; i++) {
    int id = -1;
    Map<String, dynamic> poiMap = {
      'drive_id': driveId,
      'type': pointsOfInterest[i].getType(),
      'name': pointsOfInterest[i].getName(),
      'description': pointsOfInterest[i].getDescription(),
      'images': pointsOfInterest[i].getImages(),
      'latitude': pointsOfInterest[i].point.latitude,
      'longitude': pointsOfInterest[i].point.longitude,
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
      try {
        id = await db.insert(
          'points_of_interest',
          poiMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error saving point of interest: ${e.toString()}');
      }
    }
  }
  return true;
}

Future<void> deletePointOfInterestById(int id) async {
  final db = await dbHelper().db;
  await db.delete(
    'points_of_interest',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> deletePointOfInterestByDriveId(int driveId) async {
  final db = await dbHelper().db;
  await db.delete(
    'points_of_interest',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
}

/// Saves the myTrips to the local SQLite database
///

Future<bool> saveManeuversLocal({
  required int driveId,
  required List<Maneuver> maneuvers,
}) async {
  final db = await dbHelper().db;
  Map<String, dynamic> manMap = {};
  await deleteManeuversByDriveId(driveId);
  for (int i = 0; i < maneuvers.length; i++) {
    try {
      maneuvers[i].driveId = driveId;
      manMap = maneuvers[i].toMap();
      manMap.remove('id');

      await db.insert(
        'maneuvers',
        manMap,
        conflictAlgorithm: ConflictAlgorithm.ignore, //  replace,
      );
    } catch (err) {
      String tError = err.toString();
      debugPrint('Error saving maneuvers: $tError');
    }
    debugPrint(
        'i: $i  => ${maneuvers[maneuvers.length - 1].roadFrom}  ${maneuvers[maneuvers.length - 1].roadTo}');
  }
  return true;
}

Future<List<Maneuver>> loadManeuversLocal(int driveId) async {
  final db = await dbHelper().db;
  List<Maneuver> maneuvers = [];
  List<Map<String, dynamic>> maps = await db.query(
    'maneuvers',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
  LatLng pos = const LatLng(0, 0);
  dynamic jsonPos;

  for (int i = 0; i < maps.length; i++) {
    try {
      jsonPos = jsonDecode(maps[i]['location']);
      pos = LatLng(jsonPos['lat'], jsonPos['long']);

      maneuvers.add(Maneuver(
        id: maps[i]['id'],
        driveId: driveId,
        roadFrom: maps[i]['road_from'],
        roadTo: maps[i]['road_to'],
        bearingBefore: maps[i]['bearing_before'],
        bearingAfter: maps[i]['bearing_after'],
        exit: maps[i]['exit'],
        location: pos,
        modifier: maps[i]['modifier'],
        type: maps[i]['type'],
        distance: maps[i]['distance'],
      ));
      debugPrint(
          'i: $i  => ${maneuvers[maneuvers.length - 1].roadFrom}  ${maneuvers[maneuvers.length - 1].roadTo}');
    } catch (e) {
      String err = e.toString();
      debugPrint(err);
    }
  }
  return maneuvers;
}

Future<void> deleteManeuversByDriveId(int driveId) async {
  final db = await dbHelper().db;
  await db.delete(
    'maneuvers',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
}

Future<bool> savePolylinesLocal(
    {required int driveId, required List<mt.Route> polylines, type = 0}) async {
  final db = await dbHelper().db;
  for (int i = 0; i < polylines.length; i++) {
    int id = polylines[i].id;
    Map<String, dynamic> plMap = {
      'id': id,
      'drive_id': driveId,
      'type': type,
      'points': pointsToString(polylines[i].points),
      'stroke': polylines[i].strokeWidth,
      'colour': uiColours.keys
          .toList()
          .indexWhere((col) => col == polylines[i].color),
    };
    if (id > -1) {
      try {
        await db.update('polylines', plMap,
            where: 'id = ?',
            whereArgs: [plMap['id']],
            conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (e) {
        debugPrint("Database error storing polylines: ${e.toString()}");
        return false;
      }
    } else {
      try {
        plMap.remove('id');
      } catch (e) {
        debugPrint('Map.remove() error: ${e.toString()}');
      }
      try {
        await db.insert(
          'polylines',
          plMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error inserting polylines: ${e.toString}');
      }
    }
  }
  return true;
}

Future<void> deletePolyLinesById(int id) async {
  final db = await dbHelper().db;
  await db.delete(
    'polylines',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> deletePolyLinesByDriveId(int driveId) async {
  final db = await dbHelper().db;
  await db.delete(
    'polylines',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
}

Future<List<Follower>> loadFollowers(int driveId) async {
  final db = await dbHelper().db;
  List<Follower> followers = [];
  List<Map<String, dynamic>> maps = await db.query(
    'followers',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
  dynamic jsonPos;
  LatLng pos;
  for (int i = 0; i < maps.length; i++) {
    jsonPos = jsonDecode(maps[i]['position']);
    pos = LatLng(jsonPos['lat'], jsonPos['long']);
    followers.add(
      Follower(
        id: maps[i]['id'],
        driveId: driveId,
        forename: maps[i]['forename'],
        surname: maps[i]['surname'],
        phoneNumber: maps[i]['phone_number'],
        car: maps[i]['car'],
        registration: maps[i]['registration'],
        iconColour: maps[i]
            ['icon_color'], //uiColours.keys.toList()[maps[i]['icon_color']],
        position: pos,
        marker: MarkerWidget(
          type: 16,
          description: '',
          angle: 0,
        ),
      ),
    );
  }
  return followers;
}

Future<bool> saveFollowersLocal(
    {required int driveId, required List<Follower> followers}) async {
  final db = await dbHelper().db;
  for (int i = 0; i < followers.length; i++) {
    Map<String, dynamic> fMap = followers[i].toMap();

    if (followers[i].id > -1) {
      try {
        await db.update('followers', fMap,
            where: 'id = ?',
            whereArgs: [followers[i].id],
            conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (e) {
        debugPrint("Database error storing followers: ${e.toString()}");
        return false;
      }
    } else {
      try {
        fMap.remove('id');
      } catch (e) {
        debugPrint('Map.remove() error: ${e.toString()}');
      }
      await db.insert(
        'polylines',
        fMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
  return true;
}

Future<void> deleteFollowerById(int id) async {
  final db = await dbHelper().db;
  await db.delete(
    'followers',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> deleteFollowerByDriveId(int driveId) async {
  final db = await dbHelper().db;
  await db.delete(
    'followers',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
}

/// Get the polylines for a drive from SQLite
/// Will initially only load the descriptive details and only
/// load the details if the drive is selected

Future<List<Polyline>> loadPolyLinesLocal(int driveId, {type = 0}) async {
  final db = await dbHelper().db;
  List<Polyline> polylines = [];
  List<Map<String, dynamic>> maps = await db.query(
    'polylines',
    where: 'drive_id = ? and type = ?',
    whereArgs: [driveId, type],
  );

  for (int i = 0; i < maps.length; i++) {
    polylines.add(Polyline(
        points: stringToPoints(maps[i]['points']), // routePoints,
        color: uiColours.keys.toList()[maps[i]['colour']],
        borderColor: uiColours.keys.toList()[maps[i]['colour']],
        strokeWidth: (maps[i]['stroke']).toDouble()));
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
