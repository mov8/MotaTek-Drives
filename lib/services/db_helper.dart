// import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
// import 'package:drives/classes/classes.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:drives/constants.dart';
import 'package:drives/classes/route.dart' as mt;
import 'package:drives/classes/my_trip_item.dart';
import 'package:drives/classes/other_classes.dart';
import 'package:drives/models/models.dart';
import 'package:drives/services/web_helper.dart';
import 'dart:async';

// import 'package:vector_map_tiles/vector_map_tiles.dart';
// import 'dart:convert';

class DbHelper {
  static Database? _db;
  DbHelper._(); // Private constructor to prevent instantiation

  static final DbHelper instance = DbHelper._();

  static Database? _database;

  Future<Database> get database async {
    return _database ??= await initDb();
  }

  factory DbHelper() {
    return instance;
  }

  Future<Database> get db async {
    return _db ??= await initDb();
  }

  Future<Database> initDb() async {
    String? path;
    try {
      path = join(await getDatabasesPath(), 'drives.db');
    } catch (e) {
      debugPrint('Error getDatabasesPath() : ${e.toString()}');
    }
    var newdb = await openDatabase(
      path!,
      version: dbVersion, // in constants.dart,
      onCreate: _createDb,
    );
    return newdb;
  }

  /// tableDefs defined in constants.dart
  void _createDb(Database db, int version) async {
    try {
      for (String tableDef in tableDefs) {
        await db.execute(tableDef);
      }
      debugPrint('SQLite tables all created OK');
    } catch (e) {
      debugPrint('Error creating tables: ${e.toString()}');
    }
  }
}

Future<int> recordCount(table) async {
  int? count;
  try {
    Database db = await DbHelper().db;
    count =
        Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM $table"));
  } catch (e) {
    debugPrint('Error counting records from $table : ${e.toString()}');
  }
  return count ?? 0;
}

alterTable() async {
  /*
  final db = await DbHelper().db;
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

/// Survey data saving locally
///

alterSurveyTables() async {
  final db = await DbHelper().db;

  try {
    await db.execute('DROP TABLE IF EXISTS contacts');
    await db
        .execute('''CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT,
           stand_id INTEGER, forename TEXT, surname TEXT, position TEXT, 
           email TEXT, phone TEXT, ratings TEXT, contact TEXT, 
           feedback TEXT)''');
  } catch (e) {
    debugPrint('Error creating contacts table: ${e.toString()}');
  }
  try {
    await db.execute('DROP TABLE IF EXISTS stands');
    await db
        .execute('''CREATE TABLE stands(id INTEGER PRIMARY KEY AUTOINCREMENT, 
          show_id INTEGER, stand TEXT, name TEXT, seen INTEGER, 
          comments TEXT, action TEXT, interviewer TEXT)''');
  } catch (e) {
    debugPrint('Error creating stands table: ${e.toString()}');
  }
}

Future<int> saveSurveyData(
    {required Map<String, dynamic> map, required String table}) async {
  final db = await DbHelper().db;
  int id = map['id'];

  try {
    if (id == -1) {
      map.remove('id');
      id = await db.insert(
        table,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.update(table, map,
          where: 'id = ?',
          whereArgs: [id],
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  } catch (e) {
    debugPrint('database error adding to $table: ${e.toString()}');
  }

  return id;
}

Future<List<Map<String, dynamic>>> getSurveyData(
    {required String table, int standId = -1, String stand = ''}) async {
  final db = await DbHelper().db;
  String whereString;
  List<Map<String, dynamic>> map = [];
  List<Object> args;
  if (standId >= 0) {
    args = [standId];
    whereString = 'stand_id = ?';
  } else if (stand.isNotEmpty) {
    args = [stand];
    whereString = 'stand = ?';
  } else {
    try {
      map = await db.query(table);
    } catch (e) {
      debugPrint('error loading $table : ${e.toString()}');
    }
    return map; //await db.query(table);
  }
  return await db.query(table, where: whereString, whereArgs: args);
}

/// End of Survey stuff
///
Future<List<Map<String, dynamic>>> getSetup(int id) async {
  Database db = await DbHelper().db;
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
  final db = await DbHelper().db;
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
      User user = User(
        id: int.parse(maps[0]['id'].toString()),
        forename: maps[0]['forename'].toString(),
        surname: maps[0]['surname'].toString(),
        email: maps[0]['email'].toString(),
        phone: maps[0]['phone'].toString(),
        password: maps[0]['password'].toString(),
        imageUrl: maps[0]['imageUrl'].toString(),
      );
      Setup().user = user;
      Setup().hasLoggedIn = true;
      return user;
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
  final db = await DbHelper().db;
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
  final db = await DbHelper().db;

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
  final db = await DbHelper().db;
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
class LocalImage {
  // extends StatelessWidget {
  int id;
  double width;
  bool imageLoaded = false;
  LocalImage({required this.id, this.width = 50});
  // @override
  // Widget build(BuildContext context) {

  getImage() {
    return FutureBuilder(
      future: loadImageByIdLocal(id: id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ImageMissing(width: width);
        } else if (snapshot.hasData) {
          return snapshot.data as Image;
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
*/
Future<Uint8List?> loadImageByIdLocal({required int id}) async {
  final db = await DbHelper().db;
  List<Map<String, dynamic>> imageRecord =
      await db.query('images', where: 'id = ?', whereArgs: [id]);

  if (imageRecord.isNotEmpty) {
    return imageRecord.first['image'];
  }

  return null;
}

Future<int> saveImageLocal(
    {required String imageUrl,
    driveId = -1,
    pointOfInterestId = -1,
    caption = ''}) async {
  final db = await DbHelper().db;

  try {
    Uint8List imageBytes = await File(imageUrl).readAsBytes();
    int id = await db.insert(
      'images',
      {
        'image': imageBytes,
        'drive_id': driveId,
        'point_of_interest_id': pointOfInterestId,
        'caption': caption,
        'added': DateTime.now().toString()
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  } catch (err) {
    String tError = err.toString();
    debugPrint('Error saving groups: $tError');
  }
  return -1;
}

/*
Future<List<Group>> getGroups() async {
  final db = await DbHelper().db;
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
Future<List<MailItem>> loadMailItems() async {
  final db = await DbHelper().db;
  List<MailItem> mailItems = [];
  try {
    List<Map<String, dynamic>> maps = await db.query(
      'groups',
    );

    for (int i = 0; i < maps.length; i++) {
      mailItems.add(MailItem(
        id: maps[i]['id'],
        name: maps[i]['name'],
        isGroup: true,
      ));
      // description: maps[i]['description']));
    }
  } catch (e) {
    String err = e.toString();
    debugPrint(err);
  }
  return mailItems;
}

Future<List<Group>> loadGroups() async {
  final db = await DbHelper().db;
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
  final db = await DbHelper().db;
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
  final db = await DbHelper().db;
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
  final db = await DbHelper().db;
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
  final db = await DbHelper().db;
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

Future<List<HomeItem>> loadHomeItems() async {
  final db = await DbHelper().db;
  List<HomeItem> homeItems = [];
  try {
    List<Map<String, dynamic>> maps = await db.query(
      'home_items',
    );
    for (Map<String, dynamic> map in maps) {
      homeItems.add(HomeItem.fromMap(map: map));
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  return homeItems;
}

Future<List<HomeItem>> saveHomeItemsLocal(List<HomeItem> homeItems) async {
  final db = await DbHelper().db;

  /// Empty the cache home_items and remove all the images
  String appDocDir = Setup().appDocumentDirectory;

  try {
    await db.execute("delete from home_items");

    final localImageDir = Directory('$appDocDir/home_item_images');
    bool dirExists = await localImageDir.exists();

    if (dirExists) {
      final List<FileSystemEntity> entities =
          await localImageDir.list().toList();
      final Iterable<File> images = entities.whereType<File>();
      for (File image in images) {
        image.delete();
      }
    } else {
      localImageDir.create();
    }
  } catch (e) {
    debugPrint('Error clearing HomeItems cache: ${e.toString()}');
  }

  /// Reload the cache and download all the image files

  for (HomeItem homeItem in homeItems) {
    if (homeItem.uri.contains('http')) {
      // Only save web images
      Map<String, dynamic> hiMap = homeItem.toMap();
      if (homeItem.id == -1) {
        // New record
        try {
          hiMap.remove('id');
          if (hiMap['image_urls'].isNotEmpty) {
            var files = jsonDecode(hiMap['image_urls']);
            for (Map file in files) {
              //  String imagePath = '$appDocDir/home_item_images/${file['url']}';
              await downloadImage(
                  apiUrl: '${homeItem.uri}/${file['url']}',
                  targetFile: '$appDocDir/home_item_images/${file['url']}');
            }
            hiMap['uri'] = '$appDocDir/home_item_images/';
          }
          homeItem.id = await db.insert(
            'home_items',
            hiMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          homeItem.uri = '$appDocDir/home_item_images/';
        } catch (e) {
          String err = e.toString();
          debugPrint('Error inserting HomeItems: $err');
          return homeItems;
        }
      } else {
        try {
          await db.update('home_items', hiMap,
              where: 'id = ?',
              whereArgs: [homeItem.id],
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          String err = e.toString();
          debugPrint('Error updating HomeItems: $err');
          return homeItems;
        }
      }
    }
  }
  return homeItems;
}

Future<List<ShopItem>> loadShopItems() async {
  final db = await DbHelper().db;
  List<ShopItem> shopItems = [];
  try {
    List<Map<String, dynamic>> maps = await db.query(
      'shop_items',
    );
    for (Map<String, dynamic> map in maps) {
      shopItems.add(ShopItem.fromMap(map: map));
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  return shopItems;
}

Future<List<TripItem>> loadTripItems() async {
  final db = await DbHelper().db;
  List<TripItem> tripItems = [];
  try {
    List<Map<String, dynamic>> maps = await db.query(
      'trip_items',
    );
    for (Map<String, dynamic> map in maps) {
      tripItems.add(TripItem.fromMap(
        map: map,
      ));
      // endpoint: '${Setup().appDocumentDirectory}/trip_item_images/'));
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  return tripItems;
}

Future<TripItem?> loadTripItemLocal({int id = -1}) async {
  if (id > -1) {
    List<Map<String, Object?>> maps;
    final db = await DbHelper().db;
    try {
      String query = "SELECT * FROM trip_items WHERE id = $id";
      maps = await db.rawQuery(query);
      return TripItem.fromMap(map: maps[0]);
    } catch (e) {
      debugPrint('dbError:${e.toString()}');
    }
  }
  return null;
}

/// If the API is online saveShopItemsLocal will refresh the local
/// cache of shopItems. It will clear the SQLite db and download
/// all the relevant data again.
/// ToDo: Add some filtering to only update new or changed data

Future<List<ShopItem>> saveShopItemsLocal(List<ShopItem> shopItems) async {
  final db = await DbHelper().db;

  /// Empty the cache home_items and remove all the images
  String appDocDir = Setup().appDocumentDirectory;

  try {
    await db.execute("delete from shop_items");

    final localImageDir = Directory('$appDocDir/shop_item_images');
    bool dirExists = await localImageDir.exists();

    if (dirExists) {
      /// Remove all previously downloaded image files to save space
      final List<FileSystemEntity> entities =
          await localImageDir.list().toList();
      final Iterable<File> images = entities.whereType<File>();
      for (File image in images) {
        image.delete();
      }
    } else {
      localImageDir.create();
    }
  } catch (e) {
    debugPrint('Error clearing ShopItems cache: ${e.toString()}');
  }

  /// Reload the cache and download all the image files

  for (ShopItem shopItem in shopItems) {
    if (shopItem.uri.contains('http')) {
      // Only save web images
      Map<String, dynamic> hiMap = shopItem.toMap();
      if (shopItem.id == -1) {
        // New record
        try {
          hiMap.remove('id');
          if (hiMap['image_urls'].isNotEmpty) {
            var files = jsonDecode(hiMap['image_urls']);
            for (Map file in files) {
              //  String imagePath = '$appDocDir/home_item_images/${file['url']}';
              await downloadImage(
                  apiUrl: '${shopItem.uri}/${file['url']}',
                  targetFile: '$appDocDir/shop_item_images/${file['url']}');
            }
            hiMap['uri'] = '$appDocDir/shop_item_images/';
          }
          shopItem.id = await db.insert(
            'shop_items',
            hiMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          shopItem.uri = '$appDocDir/shop_item_images/';
        } catch (e) {
          String err = e.toString();
          debugPrint('Error inserting ShopItems: $err');
          return shopItems;
        }
      } else {
        try {
          await db.update('shop_items', hiMap,
              where: 'id = ?',
              whereArgs: [shopItem.id],
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          String err = e.toString();
          debugPrint('Error updating ShopItems: $err');
          return shopItems;
        }
      }
    }
  }
  return shopItems;
}

/// If the API is online saveTripItemsLocal will refresh the local
/// cache of tripItems. It will clear the SQLite db and download
/// all the relevant data again.
/// ToDo: Add some filtering to only update new or changed data

Future<List<TripItem>> saveTripItemsLocal(List<TripItem> tripItems) async {
  final db = await DbHelper().db;

  /// Empty the cache home_items and remove all the images
  String appDocDir = Setup().appDocumentDirectory;

  try {
    await db.execute("delete from trip_items");

    ///data/user/0/com.example.drives/app_flutter/trip_item_images
    final localImageDir = Directory('$appDocDir/trip_item_images');
    bool dirExists = await localImageDir.exists();

    if (dirExists) {
      /// Remove all previously downloaded image files to save space
      final List<FileSystemEntity> entities =
          await localImageDir.list().toList();
      final Iterable<File> images = entities.whereType<File>();
      for (File image in images) {
        image.delete();
      }
    } else {
      localImageDir.create();
    }
  } catch (e) {
    debugPrint('Error clearing ShopItems cache: ${e.toString()}');
  }

  /// Reload the cache and download all the image files

  for (TripItem tripItem in tripItems) {
    if (tripItem.uri.contains('http')) {
      // Only save web images

      Map<String, dynamic> tiMap = tripItem.toMap();
      if (tripItem.id == -1) {
        // New record
        try {
          tiMap.remove('id');
          String images = '';
          //  String apiUrl;
          String localName;

          if (tiMap['image_urls'].isNotEmpty) {
            var files = jsonDecode(tiMap['image_urls']);
            for (Map file in files) {
              //  String imagePath = '$appDocDir/home_item_images/${file['url']}';
              // @blueprint.route('/images/<drive_id>/<point_of_interest_id>/<filename>', methods=['GET'])
              if (file['url'].contains('map.png')) {
                localName = '${tripItem.driveUri}.png';
              } else {
                localName = file['url'].substring(file['url'].length - 40);
              }

              await downloadImage(
                  apiUrl:
                      '${tripItem.uri}images/${tripItem.driveUri}/${file['url']}',
                  targetFile: '$appDocDir/trip_item_images/$localName');
              if (images.isEmpty) {
                images = '{"url": "$localName", "caption": ""}';
              } else {
                images = '$images, {"url": "$localName", "caption": ""}';
              }
            }
            tiMap['uri'] = '$appDocDir/trip_item_images/';
            tiMap['image_urls'] = '[$images]';
          }
          tripItem.id = await db.insert(
            'trip_items',
            tiMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          tripItem.uri = '$appDocDir/trip_item_images/';
          tripItem.imageUrls = '[$images]';
        } catch (e) {
          String err = e.toString();
          debugPrint('Error inserting TripItems: $err');
          return tripItems;
        }
      } else {
        try {
          await db.update('trip_items', tiMap,
              where: 'id = ?',
              whereArgs: [tripItem.id],
              conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          String err = e.toString();
          debugPrint('Error updating TripItems: $err');
          return tripItems;
        }
      }
    }
  }
  return tripItems;
}

Future<int> saveMessage(MessageLocal message) async {
  final db = await DbHelper().db;
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

/*
  List<Map<String, dynamic>> maps = await db.query(
    'points_of_interest',
    where: 'id = ?',
    whereArgs: [id],
  );
      var maps = await db.rawQuery("SELECT * FROM Users LIMIT 1");
    if (maps.isNotEmpty) {
      id = int.parse(maps[0]['id'].toString());
      forename = maps[0]['forename'].toString();
      surname = maps[0]['surname'].toString();
      email = maps[0]['email'].toString();
      password = maps[0]['password'].toString();
      imageUrl = maps[0]['imageUrl'].toString();
    }
 */

Future<Map<String, dynamic>> getDrive(int driveId) async {
  final db = await DbHelper().db;

  try {
    String query = "SELECT * FROM drives WHERE id = $driveId";
    List<Map<String, dynamic>> maps = await db.rawQuery(query);
    return {
      'id': int.parse(maps[0]['id'].toString()),
      'uri': maps[0]['uri'].toString(),
      'title': maps[0]['title'].toString(),
      'subTitle': maps[0]['sub_title'].toString(),
      'body': maps[0]['body'].toString(),
      'added': DateTime.parse(maps[0]['added'] as String),
      'distance': double.parse(maps[0]['distance'].toString()),
      'pois': int.parse(maps[0]['points_of_interest'].toString()),
      // 'pois': int.parse(maps[0]['points_of_interest'].toString()),
    };
  } catch (e) {
    debugPrint('dbError:${e.toString()}');
    return {'error': 'getDrive() = ${e.toString()}'};
  }
}

Future<void> deleteDriveById(int id) async {
  final db = await DbHelper().db;
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
  final db = await DbHelper().db;
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
  final db = await DbHelper().db;
  int id = myTripItem.id;
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
    if (myTripItem.driveUri.isNotEmpty) {
      final directory = Setup().appDocumentDirectory;
      for (PointOfInterest pointOfInterest in myTripItem.pointsOfInterest) {
        if (pointOfInterest.getImages().isNotEmpty) {
          var pics = jsonDecode(pointOfInterest.getImages());
          String jsonImages = '';
          for (Map<String, dynamic> pic in pics) {
            String url =
                Uri.parse('$urlDrive/images${pointOfInterest.url}${pic['url']}')
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

    /// Points of interest must be saved first as goodRoads have a referenc
    /// to the pointOfInterest automatically generated
    await savePointsOfInterestLocal(
        driveId: id, pointsOfInterest: myTripItem.pointsOfInterest);
    await savePolylinesLocal(
        driveId: id, polylines: myTripItem.routes, type: 0);
    await savePolylinesLocal(
        driveId: id,
        polylines: myTripItem.goodRoads,
        pointsOfInterest: myTripItem.pointsOfInterest,
        type: 1);
    await saveManeuversLocal(driveId: id, maneuvers: myTripItem.maneuvers);
  } catch (e) {
    String err = e.toString();
    debugPrint('Error: $err');
  }
  return id;
}

Future<OsmAmenity> loadOsmAmenityLocal({required int id, index = 0}) async {
  final db = await DbHelper().db;
  OsmAmenity? osmAmenity;
  List<Map<String, dynamic>> maps = await db.query(
    'osm_data',
    where: 'id = ?',
    whereArgs: [id],
  );
  osmAmenity = OsmAmenity(
    id: maps.first['id'],
    osmId: maps.first['drive_id'],
    name: maps.first['name'],
    amenity: maps.first['amenity'],
    width: maps.first['type'] == 12 ? 10 : 30,
    height: maps.first['type'] == 12 ? 10 : 30,
    position: LatLng(maps.first['latitude'], maps.first['longitude']),
    marker: MarkerWidget(type: maps.first['type'], list: 0, listIndex: index),
  );

  return osmAmenity;
}

Future<int> saveOsmAmenityLocal({required OsmAmenity amenity}) async {
  final db = await DbHelper().db;
  int id = -1;
  Map<String, dynamic> osmMap = {
    'osm_id': amenity.osmId,
    'name': amenity.name,
    'amenity': amenity.amenity,
    'postcode': amenity.postcode,
    'lat': amenity.point.latitude,
    'lng': amenity.point.longitude,
  };
  if (amenity.id!.getValue > -1) {
    id = amenity.id!.getValue;
    try {
      await db.update('osm_data', osmMap,
          where: 'id = ?',
          whereArgs: [id],
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error saving points of interest: ${e.toString()}');
      return -1;
    }
  } else {
    try {
      id = await db.insert(
        'osm_data',
        osmMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      amenity.id!.setValue = id;
    } catch (e) {
      debugPrint('Error saving point of interest: ${e.toString()}');
    }
  }
  return amenity.id!.getValue;
}

Future<bool> saveOsmDataLocal(
    {required int driveId, required List<OsmAmenity> osmData}) async {
  for (int i = 0; i < osmData.length; i++) {
    saveOsmAmenityLocal(amenity: osmData[i]);
  }
  return true;
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
  final db = await DbHelper().db;
  List<PointOfInterest> pointsOfInterest = [];
  List<Map<String, dynamic>> maps = await db.query(
    'points_of_interest',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
  for (int i = 0; i < maps.length; i++) {
    pointsOfInterest.add(
      PointOfInterest(
        id: maps[i]['id'],
        driveId: driveId,
        type: maps[i]['type'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        width: maps[i]['type'] == 12 ? 10 : 30,
        height: maps[i]['type'] == 12 ? 10 : 30,
        images: maps[i]['images'],
        markerPoint: LatLng(maps[i]['latitude'], maps[i]['longitude']),
        marker: MarkerWidget(type: maps[i]['type'], list: 0, listIndex: i),
      ),
    );
  }
  return pointsOfInterest;
}

Future<PointOfInterest> loadPointOfInterestLocal(
    {required int id, index = 0}) async {
  final db = await DbHelper().db;
  PointOfInterest? pointOfInterest;
  List<Map<String, dynamic>> maps = await db.query(
    'points_of_interest',
    where: 'id = ?',
    whereArgs: [id],
  );

  pointOfInterest = PointOfInterest(
    id: maps.first['id'],
    driveId: maps.first['drive_id'],
    type: maps.first['type'],
    name: maps.first['name'],
    description: maps.first['description'],
    width: maps.first['type'] == 12 ? 10 : 30,
    height: maps.first['type'] == 12 ? 10 : 30,
    images: maps.first['images'],
    markerPoint: LatLng(maps.first['latitude'], maps.first['longitude']),
    marker: MarkerWidget(type: maps.first['type'], list: 0, listIndex: index),
  );

  return pointOfInterest;
}

Future<bool> savePointsOfInterestLocal(
    {required int driveId,
    required List<PointOfInterest> pointsOfInterest}) async {
  for (int i = 0; i < pointsOfInterest.length; i++) {
    savePointOfInterestLocal(
        driveId: driveId, pointOfInterest: pointsOfInterest[i]);
  }
  return true;
}

Future<int> savePointOfInterestLocal(
    {required int driveId, required PointOfInterest pointOfInterest}) async {
  final db = await DbHelper().db;
  int id = -1;
  Map<String, dynamic> poiMap = {
    'drive_id': driveId,
    'type': pointOfInterest.getType(),
    'name': pointOfInterest.getName(),
    'description': pointOfInterest.getDescription(),
    'images': pointOfInterest.getImages(),
    'latitude': pointOfInterest.point.latitude,
    'longitude': pointOfInterest.point.longitude,
    'sounds': pointOfInterest.sounds,
  };
  if (pointOfInterest.id > -1) {
    id = pointOfInterest.id;
    try {
      await db.update('points_of_interest', poiMap,
          where: 'id = ?',
          whereArgs: [id],
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error saving points of interest: ${e.toString()}');
      return -1;
    }
  } else {
    try {
      id = await db.insert(
        'points_of_interest',
        poiMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      pointOfInterest.id = id;
    } catch (e) {
      debugPrint('Error saving point of interest: ${e.toString()}');
    }
  }
  if (poiMap['images'].isNotEmpty) {
    dynamic images = jsonDecode(poiMap['images']);
    for (Map<String, dynamic> image in images) {
      if (image['url'] != null) {
        try {
          saveImageLocal(imageUrl: image['url']);
        } catch (e) {
          debugPrint('Image error ${e.toString()}');
        }
      }
    }
  }

  return id;
}

Future<void> deletePointOfInterestById(int id) async {
  final db = await DbHelper().db;
  await db.delete(
    'points_of_interest',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> deletePointOfInterestByDriveId(int driveId) async {
  final db = await DbHelper().db;
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
  final db = await DbHelper().db;
  Map<String, dynamic> manMap = {};

  //List<Maneuver> savedManeuvers = await loadManeuversLocal(driveId);
  // if (savedManeuvers.isNotEmpty) {
  await deleteManeuversByDriveId(driveId);
  // }
  //savedManeuvers.addAll(maneuvers);

  Batch batch = db.batch();

  for (int i = 0; i < maneuvers.length; i++) {
    try {
      maneuvers[i].driveId = driveId;
      manMap = maneuvers[i].toMap();
      manMap.remove('id');
      manMap.remove('drive_uid');
      manMap['drive_id'] = driveId;
      batch.insert('maneuvers', manMap);
    } catch (err) {
      String tError = err.toString();
      debugPrint('Error saving maneuvers: $tError');
    }
  }
  if (batch.length > 0) {
    try {
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Batch insert error: ${e.toString()}');
    }
  }
  return true;
}

Future<List<Maneuver>> loadManeuversLocal(int driveId) async {
  final db = await DbHelper().db;
  List<Maneuver> maneuvers = [];
  List<Map<String, dynamic>> maps = [];
  try {
    maps = await db.query(
      'maneuvers',
      where: 'drive_id = ?',
      whereArgs: [driveId],
    );
  } catch (e) {
    debugPrint('Error getting maneuvers');
  }
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
    } catch (e) {
      String err = e.toString();
      debugPrint(err);
    }
  }
  return maneuvers;
}

Future<void> deleteManeuversByDriveId(int driveId) async {
  final db = await DbHelper().db;
  await db.delete(
    'maneuvers',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
}

Future<bool> savePolylinesLocal(
    {required int driveId,
    required List<mt.Route> polylines,
    List<PointOfInterest> pointsOfInterest = const [],
    type = 0}) async {
  final db = await DbHelper().db;

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
      'point_of_interest_id': polylines[i].pointOfInterestIndex >= 0
          ? pointsOfInterest[polylines[i].pointOfInterestIndex].id
          : -1,
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
      // Check if its a good road, and if so save the associated point of interest
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
  final db = await DbHelper().db;
  await db.delete(
    'polylines',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> deletePolyLinesByDriveId(int driveId) async {
  final db = await DbHelper().db;
  await db.delete(
    'polylines',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
}

Future<List<Follower>> loadFollowers(int driveId) async {
  final db = await DbHelper().db;
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
        uri: maps[i]['id'],
        driveId: driveId.toString(),
        forename: maps[i]['forename'],
        surname: maps[i]['surname'],
        phoneNumber: maps[i]['phone_number'],
        car: maps[i]['car'],
        registration: maps[i]['registration'],
        iconColour: maps[i]['icon_color'],
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
  final db = await DbHelper().db;
  for (int i = 0; i < followers.length; i++) {
    Map<String, dynamic> fMap = followers[i].toMap();

    if (followers[i].uri.isNotEmpty) {
      try {
        await db.update('followers', fMap,
            where: 'id = ?',
            whereArgs: [followers[i].uri],
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
  final db = await DbHelper().db;
  await db.delete(
    'followers',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> deleteFollowerByDriveId(int driveId) async {
  final db = await DbHelper().db;
  await db.delete(
    'followers',
    where: 'drive_id = ?',
    whereArgs: [driveId],
  );
}

/// Get the polylines for a drive from SQLite
/// Will initially only load the descriptive details and only
/// load the details if the drive is selected

Future<List<mt.Route>> loadPolyLinesLocal(int driveId, {type = 0}) async {
  final db = await DbHelper().db;
  List<mt.Route> polylines = [];
  List<Map<String, dynamic>> maps = await db.query(
    'polylines',
    where: 'drive_id = ? and type = ?',
    whereArgs: [driveId, type],
  );

  for (int i = 0; i < maps.length; i++) {
    polylines.add(
      mt.Route(
          points: stringToPoints(maps[i]['points']), // routePoints,
          color: uiColours.keys.toList()[maps[i]['colour']],
          borderColor: uiColours.keys.toList()[maps[i]['colour']],
          strokeWidth: (maps[i]['stroke']).toDouble(),
          pointOfInterestIndex: maps[i]['point_of_interest_id'] ?? -1),
    );
  }
  return polylines;
}

Future<mt.Route> loadPolyLineLocal(int id, {type = 0}) async {
  final db = await DbHelper().db;
  List<Map<String, dynamic>> map = await db.query(
    'polylines',
    where: 'id = ? and type = ?',
    whereArgs: [id, type],
  );
  return mt.Route(
    points: stringToPoints(map[0]['points']), // routePoints,
    color: uiColours.keys.toList()[map[0]['colour']],
    borderColor: uiColours.keys.toList()[map[0]['colour']],
    strokeWidth: (map[0]['stroke']).toDouble(),
    pointOfInterestIndex: map[0]['point_of_interest_id'] ?? -1,
  );
}

Future<Uint8List> loadTileLocal({required String key}) async {
  final db = await DbHelper().db;
  List<Map<String, dynamic>> map = await db.query(
    'map_cache',
    where: 'key = ?',
    whereArgs: [key],
  );
  return map[0]['value'];
}

Future<List<mt.Route>> loadRoutesLocal(int id,
    {type = 0, driveKey = -1}) async {
  final db = await DbHelper().db;
  List<Map<String, dynamic>> maps = await db.query(
    'polylines',
    where: 'drive_id = ? and type = ?',
    whereArgs: [id, type],
  );
  return [
    for (Map<String, dynamic> map in maps)
      mt.Route(
          driveKey: driveKey,
          points: stringToPoints(map['points']), // routePoints,
          color: uiColours.keys.toList()[map['colour']],
          borderColor: uiColours.keys.toList()[map['colour']],
          strokeWidth: (map['stroke']).toDouble())
  ];
}

Future<Uint8List> loadImageBytesLocal({required int id}) async {
  final db = await DbHelper().db;
  List<Map<String, dynamic>> map = await db.query(
    'images',
    where: 'id = ?',
  );
  return map[0]['image'];
}

List<LatLng> stringToPoints(String pointsString) {
  List<LatLng> points = [];
  try {
    var pointsJson = jsonDecode(pointsString);
    for (int i = 0; i < pointsJson.length; i++) {
      points.add(LatLng(pointsJson[i]['lat'], pointsJson[i]['lon']));
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
