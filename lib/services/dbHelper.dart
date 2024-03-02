import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, forename TEXT, surname TEXT, email TEXT, password TEXT)'); //, locationId INTEGER, vehicleId INTEGER)');

      await db.execute(
          'CREATE TABLE monitors(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, identifier TEXT, ports INTEGER)');

      await db.execute(
          '''CREATE TABLE versions(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, downloaded DATETIME, major INTEGER, 
        minor INTEGER, patch INTEGER, status INTEGER )''');

      await db.execute(
          '''CREATE TABLE setup(id INTEGER PRIMARY KEY AUTOINCREMENT, keepAlive INTEGER, notifications INTEGER,
              lockSetup INTEGER, record INTEGER, recordRate INTEGER, playRate INTEGER, dark INTEGER, speedo INTEGER, warning INTEGER,
              alarms INTEGER, dnd INTEGER, alarmLimit INTEGER, supressAlarmOnStartup INTEGER, repeater INTEGER) ''');

      await db.execute(
          'CREATE TABLE trips(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, name TEXT)');

      await db.execute(
          '''CREATE TABLE gauges(id INTEGER PRIMARY KEY AUTOINCREMENT, monitor INTEGER, portNumber INTEGER, type INTEGER,
              size INTEGER, positionXp REAL, positionYp REAL, positionXl REAL, positionYl REAL, damping INTEGER, 
              isDecimal INTEGER, notification TEXT, repeaterType INTEGER, repeaterWarning TEXT, repeaterText TEXT,
              repeaterWarningImage INTEGER)''');

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
  try {
    var maps = await db.rawQuery("SELECT * FROM Users");
    if (maps.isNotEmpty) {
      id = int.parse(maps[0]['id'].toString());
      forename = maps[0]['forename'].toString();
      surname = maps[0]['surname'].toString();
      email = maps[0]['email'].toString();
      password = maps[0]['password'].toString();
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
  );
}

Future<int> insertUser(User user) async {
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
