import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:universal_io/universal_io.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart'; // Mobile only plugin
import '/classes/utilities.dart' as utils;
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart'; // Mobile only plugin
import 'package:path/path.dart';
import 'private_storage.dart';
import 'web_helper.dart';
import '../constants.dart';
import '/models/other_models.dart';
import '/classes/other_classes.dart';
import '/classes/my_trip_item.dart';
import '/classes/route.dart' as mt;

class PrivateStorageLocal implements PrivateDataRepository {
  Database? _db;
  String? _path;

  @override
  Future<void> init() async {
    try {
      _path = join(await getDatabasesPath(), 'drives.db');
    } catch (e) {
      debugPrint('Error getDatabasesPath() : ${e.toString()}');
      return;
    }
    _db = await openDatabase(
      _path = join(await getDatabasesPath(), 'drives.db'),
      version: dbVersion, // in constants.dart,
      onCreate: createDb,
    );
    return;
  }

  void createDb(Database db, int version) async {
    try {
      for (String tableDef in tableDefs) {
        await db.execute(tableDef);
      }
      debugPrint('SQLite tables all created OK');
    } catch (e) {
      debugPrint('Error creating tables: ${e.toString()}');
    }
  }

  @override
  Future<int> recordCount(table) async {
    int? count;
    try {
      count = Sqflite.firstIntValue(
          await _db!.rawQuery("SELECT COUNT(*) FROM $table"));
    } catch (e) {
      debugPrint('Error counting records from $table : ${e.toString()}');
    }
    return count ?? 0;
  }

  @override
  alterTable() async {
    /*
      Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  alterSurveyTables() async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    try {
      await db.execute('DROP TABLE IF EXISTS contacts');
      await db.execute(
          '''CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT,
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

// PrivateStorageLocal getLocalRepository() => PrivateStorageLocal();
  @override
  Future<int> saveSurveyData(
      {required Map<String, dynamic> map, required String table}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<List<Map<String, dynamic>>> getSurveyData(
      {required String table, int standId = -1, String stand = ''}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<List<Map<String, dynamic>>> getSetup(int id) async {
    Database db = _db ??
        await openDatabase(
          join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<User> getUser() async {
    int id = 0;
    String forename = '';
    String surname = '';
    String email = '';
    String phone = '';
    String password = '';
    String imageUrl = '';
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    try {
      var maps = await db.rawQuery("SELECT * FROM users LIMIT 1");
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

  @override
  Future<int> insertSetup(Setup setup) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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
      debugPrint('Error writing setup : ${e.toString()}');
      return -1;
    }
  }

  @override
  Future<void> updateSetup() async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<bool> checkUser({required User user}) async {
    /// The issue this should resolve is incomplete user data:
    /// User can login to the server if only the JWT is presented or email / pw pair
    /// If the user logs in succesfully with either the JWT or a stored
    /// password email combination then the local database should be checked to
    /// ensure its details are complete. If they are not then the next steps
    /// should be taken
    ///   1 Check against the API - if registration c##ompleted update the local db and Setup()
    ///   2 If not complete then put up screen for the user to add missing data and save data
    ///
    /// Should only be called after login at which stage the user data should be compltete

    if (user.surname.isEmpty ||
        user.forename.isEmpty ||
        user.email.isEmpty ||
        user.phone.isEmpty) {}
    return false;
  }

  @override
  Future<int> saveUser(User user) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    Map<String, dynamic> usMap = user.toMap();
    if (usMap.containsKey('id')) {
      usMap.remove('id');
    }

    try {
      var maps = await db.rawQuery("SELECT * FROM users LIMIT 1");
      if (maps.isNotEmpty &&
          (user.forename != (maps[0]['forename'] ?? '') ||
              user.surname != (maps[0]['surname'] ?? '') ||
              user.email != (maps[0]['email'] ?? '') ||
              user.phone != (maps[0]['phone']))) {
        int id = int.parse(maps[0]['id'].toString());
        await db.update(
          'users',
          usMap, // toMap will return a SQLite friendly map
          where: 'id = ?',
          whereArgs: [id],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return id;
      } else if (maps.isEmpty) {
        final insertedId = await db.insert(
          'users',
          usMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return insertedId;
      } else {
        return int.parse(maps[0]['id'].toString());
      }
    } catch (e) {
      debugPrint('Error witing user : ${e.toString()}');
      return -1;
    }
  }

  @override
  Future<Uint8List?> loadImageByIdLocal({required int id}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    List<Map<String, dynamic>> imageRecord =
        await db.query('images', where: 'id = ?', whereArgs: [id]);

    if (imageRecord.isNotEmpty) {
      return imageRecord.first['image'];
    }

    return null;
  }

  @override
  Future<int> saveImageLocal(
      {required String imageUrl,
      driveId = -1,
      pointOfInterestId = -1,
      caption = ''}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );

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

  @override
  Future<List<MailItem>> loadMailItems() async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<List<Group>> loadGroups() async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<int> saveGroupLocal(Group group) async {
    /*
      Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<List<GroupMember>> loadGroupMembers() async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<int> saveGroupMemberLocal(GroupMember groupMember) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<void> deleteGroupMemberById(int id) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    await db.delete(
      'group_members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// @override
  Future<bool> saveGroupMembers(List<GroupMember> groupMembers) async {
    for (int i = 0; i < groupMembers.length; i++) {
      saveGroupMemberLocal(groupMembers[i]);
    }
    return true;
  }

  @override
  Future<List<HomeItem>> loadHomeItems() async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<List<HomeItem>> saveHomeItemsLocal(List<HomeItem> homeItems) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );

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

//_____________________
//
  @override
  Future<List<ShopItem>> loadShopItems() async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<List<TripItem>> loadTripItems() async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<TripItem?> loadTripItemLocal({int id = -1}) async {
    if (id > -1) {
      List<Map<String, Object?>> maps;
      Database db = _db ??
          await openDatabase(
            _path = join(await getDatabasesPath(), 'drives.db'),
            version: dbVersion, // in constants.dart,
            onCreate: createDb,
          );
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
  @override
  Future<List<ShopItem>> saveShopItemsLocal(List<ShopItem> shopItems) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );

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
  @override
  Future<List<TripItem>> saveTripItemsLocal(List<TripItem> tripItems) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );

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

  @override
  Future<int> saveMessage(MessageLocal message) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<Map<String, dynamic>> getDrive(int driveId) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );

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
        'distance': maps[0]['distance'],
        'pois': maps[0]['points_of_interest'],
        // 'pois': int.parse(maps[0]['points_of_interest'].toString()),
      };
    } catch (e) {
      debugPrint('dbError:${e.toString()}');
      return {'error': 'getDrive() = ${e.toString()}'};
    }
  }

  @override
  Future<void> deleteDriveById(int id) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    await db.delete(
      'drives',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

//

  @override
  Future<void> deleteDriveLocal({required int driveId}) async {
    await deletePolyLinesByDriveId(driveId);
    await deletePointOfInterestByDriveId(driveId);
    await deleteManeuversByDriveId(driveId);
    await deleteDriveById(driveId);
  }

// "type 'int' is not a subtype of type 'Map<String, dynamic>'"
  @override
  Future<int> saveDrive({required Drive drive}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<int> saveMyTripItem(MyTripItem myTripItem) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    int id = myTripItem.id;
    Map<String, dynamic> map = myTripItem.toDrivesMap();
    try {
      List<Map<String, dynamic>> maps =
          await db.rawQuery("SELECT id, title FROM drives");
      debugPrint('Drives data: ${maps.toString()}');
    } catch (e) {
      debugPrint('Error accessing drives: ${e.toString()}');
    }
    try {
      if (id < 0) {
        map.remove("id");
        id = await db.insert('drives', map);
      } else {
        await db.update('drives', map,
            where: 'id = ?',
            whereArgs: [id],
            conflictAlgorithm: ConflictAlgorithm.replace);
        try {
          List<Map<String, dynamic>> maps =
              await db.rawQuery("SELECT id, title FROM drives");
          debugPrint('Drives data: ${maps.toString()}');
        } catch (e) {
          debugPrint('Error accessing drives: ${e.toString()}');
        }
      }
      // Now process Trip images that have been downloaded and are to be save locally
      if (myTripItem.driveUri.isNotEmpty) {
        final directory = Setup().appDocumentDirectory;
        for (PointOfInterest pointOfInterest in myTripItem.pointsOfInterest) {
          if (pointOfInterest.images.isNotEmpty) {
            var pics = jsonDecode(pointOfInterest.images);
            String jsonImages = '';
            for (Map<String, dynamic> pic in pics) {
              String url = Uri.parse(
                      '$urlDrive/images/${pointOfInterest.url}/${pic['url']}')
                  .toString();
              bool dirExists = await Directory('$directory/drive$id').exists();
              if (!dirExists) {
                await Directory('$directory/drive$id').create();
              }

              String imagePath = '$directory/drive$id/$pic';
              await getAndSaveImage(url: url, filePath: imagePath);
              jsonImages = '$jsonImages,{"url":"$imagePath", "caption":""}';
            }
            pointOfInterest.images = '[${jsonImages.substring(1)}]';
          }
        }
      }

      /// Points of interest must be saved first as goodRoads have a reference
      /// to the pointOfInterest automatically generated
      await savePointsOfInterestLocal(
          driveId: id, pointsOfInterest: myTripItem.pointsOfInterest);
      await deletePolyLinesByDriveId(id);
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

  @override
  Future<OsmAmenity> loadOsmAmenityLocal({required int id, index = 0}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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
      markerWidth: maps.first['type'] == 12 ? 10 : 30,
      markerHeight: maps.first['type'] == 12 ? 10 : 30,
      position: LatLng(maps.first['latitude'], maps.first['longitude']),
      marker: MarkerWidget(type: maps.first['type'], list: 0, listIndex: index),
    );

    return osmAmenity;
  }

  @override
  Future<int> saveOsmAmenityLocal({required OsmAmenity amenity}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<bool> saveOsmDataLocal(
      {required int driveId, required List<OsmAmenity> osmData}) async {
    for (int i = 0; i < osmData.length; i++) {
      saveOsmAmenityLocal(amenity: osmData[i]);
    }
    return true;
  }

  @override
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

  @override
  Future<List<PointOfInterest>> loadPointsOfInterestLocal(int driveId) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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
          colourIndex: -1,
          type: maps[i]['type'],
          name: maps[i]['name'],
          description: maps[i]['description'],
          width: maps[i]['type'] == 12 ? 25 : 30,
          height: maps[i]['type'] == 12 ? 25 : 30,
          images: maps[i]['images'],
          waypoint: maps[i]['waypoint'] ?? i,
          point: LatLng(maps[i]['latitude'], maps[i]['longitude']),
        ),
      );
    }
    return pointsOfInterest;
  }

  @override
  Future<PointOfInterest> loadPointOfInterestLocal(
      {required int id, index = 0}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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
      waypoint: maps.first['waypoint'],
      point: LatLng(maps.first['latitude'], maps.first['longitude']),
    );

    return pointOfInterest;
  }

  @override
  Future<bool> savePointsOfInterestLocal(
      {required int driveId,
      required List<PointOfInterest> pointsOfInterest}) async {
    await deletePointOfInterestByDriveId(driveId);
    for (int i = 0; i < pointsOfInterest.length; i++) {
      savePointOfInterestLocal(
          driveId: driveId, pointOfInterest: pointsOfInterest[i]);
    }
    return true;
  }

  @override
  Future<int> savePointOfInterestLocal(
      {required int driveId, required PointOfInterest pointOfInterest}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    int id = -1;
    Map<String, dynamic> poiMap = {
      'drive_id': driveId,
      'type': pointOfInterest.type,
      'name': pointOfInterest.name,
      'description': pointOfInterest.description,
      'images': pointOfInterest.images,
      'waypoint': pointOfInterest.waypoint,
      'latitude': pointOfInterest.point.latitude,
      'longitude': pointOfInterest.point.longitude,
      'sounds': pointOfInterest.sounds,
    };
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

  @override
  Future<void> deletePointOfInterestById(int id) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    await db.delete(
      'points_of_interest',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deletePointOfInterestByDriveId(int driveId) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    await db.delete(
      'points_of_interest',
      where: 'drive_id = ?',
      whereArgs: [driveId],
    );
  }

  /// Saves the myTrips to the local SQLite database
  ///

  @override
  Future<bool> saveManeuversLocal({
    required int driveId,
    required List<Maneuver> maneuvers,
  }) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    Map<String, dynamic> manMap = {};
    await deleteManeuversByDriveId(driveId);
    Batch batch = db.batch();

    for (int i = 0; i < maneuvers.length; i++) {
      try {
        maneuvers[i].driveId = driveId;
        manMap = maneuvers[i].toMap();
        manMap.remove('id');
        // manMap.remove('drive_uid');
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

  @override
  Future<List<Maneuver>> loadManeuversLocal(int driveId) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<void> deleteManeuversByDriveId(int driveId) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    await db.delete(
      'maneuvers',
      where: 'drive_id = ?',
      whereArgs: [driveId],
    );
  }

  @override
  Future<bool> savePolylinesLocal(
      {required int driveId,
      required List<mt.Route> polylines,
      List<PointOfInterest> pointsOfInterest = const [],
      type = 0}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    for (int i = 0; i < polylines.length; i++) {
      Map<String, dynamic> plMap = {
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
    // }
    return true;
  }

  @override
  Future<void> deletePolyLinesById(int id) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    await db.delete(
      'polylines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deletePolyLinesByDriveId(int driveId) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    await db.delete(
      'polylines',
      where: 'drive_id = ?',
      whereArgs: [driveId],
    );
  }

  @override
  Future<List<Follower>> loadFollowers(int driveId) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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
          model: maps[i]['car'],
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

  @override
  Future<bool> saveFollowersLocal(
      {required int driveId, required List<Follower> followers}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<void> deleteFollowerById(int id) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    await db.delete(
      'followers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteFollowerByDriveId(int driveId) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    await db.delete(
      'followers',
      where: 'drive_id = ?',
      whereArgs: [driveId],
    );
  }

  /// Get the polylines for a drive from SQLite
  /// Will initially only load the descriptive details and only
  /// load the details if the drive is selected
  ///

  @override
  Future<List<mt.Route>> getRoutesByName({required String name}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    List<Map<String, dynamic>> maps = await db.query(
      'drives',
      where: 'LOWER(RTRIM(title)) = ?',
      whereArgs: [name.toLowerCase()],
    );
    List<mt.Route> polylines = [];
    int driveId = maps[0]['id'];
    polylines = await loadPolyLinesLocal(driveId);
    return polylines;
  }

  @override
  Future<List<mt.Route>> loadPolyLinesLocal(int driveId, {type = 0}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<mt.Route> loadPolyLineLocal(int id, {type = 0}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<Uint8List> loadTileLocal({required String key}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    List<Map<String, dynamic>> map = await db.query(
      'map_cache',
      where: 'key = ?',
      whereArgs: [key],
    );
    return map[0]['value'];
  }

  @override
  Future<List<mt.Route>> loadRoutesLocal(int id,
      {type = 0, driveKey = -1}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
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

  @override
  Future<Uint8List> loadImageBytesLocal({required int id}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    List<Map<String, dynamic>> map = await db.query(
      'images',
      where: 'id = ?',
    );
    return map[0]['image'];
  }

  @override
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

  @override
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

  @override
  Future<List<MyTripItem>> tripItemFromDb(
      {int driveId = -1, bool showMethods = false}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    LatLng pos = const LatLng(0, 0);

    await utils.getPosition().then((currentPosition) {
      pos = LatLng(currentPosition.latitude, currentPosition.longitude);
    });

    String drivesQuery =
        '''SELECT drives.id, drives.uri, drives.title, drives.sub_title, drives.body, drives.distance, drives.points_of_interest, drives.added,
    points_of_interest.*  
    FROM drives
    JOIN points_of_interest 
    ON drives.id = points_of_interest.drive_id''';
    if (driveId > -1) {
      drivesQuery = '$drivesQuery WHERE drives.id = $driveId';
    }

    List<MyTripItem> trips = [];
    try {
      List<Map<String, dynamic>> maps = await db.rawQuery(drivesQuery);
      final directory = (await getApplicationDocumentsDirectory()).path;
      int driveId = -1;
      int highlights = 0;
      String tripImages = '';
      double distance = 0;
      for (int i = 0; i < maps.length; i++) {
        if (maps[i]['drive_id'] != driveId) {
          distance = Geolocator.distanceBetween(maps[i]['latitude'],
              maps[i]['longitude'], pos.latitude, pos.longitude);
          driveId = maps[i]['drive_id'];
          tripImages = '{"url": "$directory/drive$driveId.png", "caption": ""}';
          highlights = 0;
          trips.add(MyTripItem(
              id: driveId,
              driveId: driveId,
              showMethods: showMethods,
              driveUri: maps[i]['uri'],
              heading: maps[i]['title'],
              subHeading: maps[i]['sub_title'],
              body: maps[i]['body'],
              published: maps[i]['added'],
              images:
                  '[{"url": "$directory/drive$driveId.png", "caption": ""}]', //maps[i]['map_image'],
              distance: maps[i]['distance'],
              distanceAway: distance,
              highlights: 0,
              pointsOfInterest: [
                PointOfInterest.fromMap(
                    map: maps[i], driveId: driveId, listIndex: i)
              ],
              closest: 15));
          if (maps[i]['type'] != 12) highlights++;
        } else {
          double poiDistance = distance = Geolocator.distanceBetween(
              maps[i]['latitude'],
              maps[i]['longitude'],
              pos.latitude,
              pos.longitude);
          if (poiDistance < trips[trips.length - 1].distance) {
            trips[trips.length - 1].distance = poiDistance;
          }
          trips[trips.length - 1].addPointOfInterest(PointOfInterest.fromMap(
              map: maps[i], driveId: driveId, listIndex: i));
          if (![12, 17, 18].contains(maps[i]['type'])) {
            highlights++;
            trips[trips.length - 1].highlights = highlights;
          }
        }
        if (maps[i]['images'].isNotEmpty) {
          tripImages =
              '${tripImages.isNotEmpty ? '$tripImages,' : ''}${utils.unList(maps[i]['images'])}';
        }
      } //
      if (trips.isNotEmpty) {
        if (tripImages.isNotEmpty) {
          trips[trips.length - 1].images = '[$tripImages]';
        }
      }
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading Drive $err');
    }
    return trips;
  }

/*
  Future<List<MyTripItem>> tripItemFromDb(
      {int driveId = -1, bool showMethods = false}) async {
    Database db = _db ??
        await openDatabase(
          _path = join(await getDatabasesPath(), 'drives.db'),
          version: dbVersion, // in constants.dart,
          onCreate: createDb,
        );
    LatLng pos = const LatLng(0, 0);

    await utils.getPosition().then((currentPosition) {
      pos = LatLng(currentPosition.latitude, currentPosition.longitude);
    });

    String drivesQuery =
        '''SELECT drives.id, drives.uri, drives.title, drives.sub_title, drives.body, drives.distance, drives.points_of_interest, drives.added,
    points_of_interest.*  
    FROM drives
    JOIN points_of_interest 
    ON drives.id = points_of_interest.drive_id''';
    if (driveId > -1) {
      drivesQuery = '$drivesQuery WHERE drives.id = $driveId';
    }

    List<MyTripItem> trips = [];
    try {
      List<Map<String, dynamic>> maps = await db.rawQuery(drivesQuery);
      final directory = (await getApplicationDocumentsDirectory()).path;
      int driveId = -1;
      int highlights = 0;
      String tripImages = '';
      double distance = 0;
      for (int i = 0; i < maps.length; i++) {
        if (maps[i]['drive_id'] != driveId) {
          distance = Geolocator.distanceBetween(maps[i]['latitude'],
              maps[i]['longitude'], pos.latitude, pos.longitude);
          driveId = maps[i]['drive_id'];
          tripImages = '{"url": "$directory/drive$driveId.png", "caption": ""}';
          highlights = 0;
          trips.add(MyTripItem(
              id: driveId,
              driveId: driveId,
              showMethods: showMethods,
              driveUri: maps[i]['uri'],
              heading: maps[i]['title'],
              subHeading: maps[i]['sub_title'],
              body: maps[i]['body'],
              published: maps[i]['added'],
              images:
                  '[{"url": "$directory/drive$driveId.png", "caption": ""}]', //maps[i]['map_image'],
              distance: maps[i]['distance'],
              distanceAway: distance,
              highlights: 0,
              pointsOfInterest: [
                PointOfInterest.fromMap(
                    map: maps[i], driveId: driveId, listIndex: i)
              ],
              closest: 15));
          if (maps[i]['type'] != 12) highlights++;
        } else {
          double poiDistance = distance = Geolocator.distanceBetween(
              maps[i]['latitude'],
              maps[i]['longitude'],
              pos.latitude,
              pos.longitude);
          if (poiDistance < trips[trips.length - 1].distance) {
            trips[trips.length - 1].distance = poiDistance;
          }
          trips[trips.length - 1].addPointOfInterest(PointOfInterest.fromMap(
              map: maps[i], driveId: driveId, listIndex: i));
          if (![12, 17, 18].contains(maps[i]['type'])) {
            highlights++;
            trips[trips.length - 1].highlights = highlights;
          }
        }
        if (maps[i]['images'].isNotEmpty) {
          tripImages =
              '${tripImages.isNotEmpty ? '$tripImages,' : ''}${unList(maps[i]['images'])}';
        }
      } //
      if (trips.isNotEmpty) {
        if (tripImages.isNotEmpty) {
          trips[trips.length - 1].images = '[$tripImages]';
        }
      }
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading Drive $err');
    }
    return trips;
  }
  */
}

PrivateStorageLocal getPrivateRepository() => PrivateStorageLocal();
