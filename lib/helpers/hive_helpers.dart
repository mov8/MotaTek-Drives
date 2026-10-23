import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import '/models/models.dart';
import '/classes/classes.dart';
import 'package:hive/hive.dart';
import 'dart:developer' as developer;

// https://resocoder.com/2019/09/30/hive-flutter-tutorial-lightweight-fast-database/
// Although storing data as json is fine, at some stage should convert to adaptors

// Following test routine works

class UserRepository {
  late final Box _userBox;
  Future<bool> openBox() async {
    _userBox = await Hive.openBox('user');
    return true;
  }

  // Save the model as a JSON string
  Future<void> saveUser(User user) async {
    if (!_userBox.isOpen) {
      await openBox();
    }
    final String jsonString = jsonEncode(user.toMap());
    await _userBox.put('user', jsonString);
    _userBox.close();
  }

  Future<void> saveJwt(String jwt) async {
    if (!_userBox.isOpen) {
      await openBox();
    }
    await _userBox.put('jwt', jwt);
    _userBox.close;
  }

  Future<void> saveSetup() async {
    if (!_userBox.isOpen) {
      await openBox();
    }
    final String jsonString = jsonEncode(Setup().toMap());
    await _userBox.put('setup', jsonString);
    _userBox.close;
  }

  // Retrieve and decode the model safely
  Future<User?> getUser() async {
    if (!_userBox.isOpen) {
      await openBox();
    }
    final String? jsonString = _userBox.get('user');
    if (jsonString == null) return null;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    _userBox.close;
    return User.fromJson(jsonMap);
  }

  Future<String> getJwt() async {
    if (!_userBox.isOpen) {
      await openBox();
    }
    return _userBox.get('jwt') ?? '';
  }

  Future<bool> getSetup() async {
    if (!_userBox.isOpen) {
      await openBox();
    }
    final String? jsonString = _userBox.get('setup');
    if (jsonString == null) return false;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    Setup().fromJson(map: jsonMap);
    _userBox.close;
    return true;
  }
}

class TripRepository {
  /// Can't have anything here that's not 'late' else it gets called when class is used
  late final Box _tripsBox;
  Future<bool> openBox() async {
    _tripsBox = await Hive.openBox('trips');
    return true;
  }

  Future<void> saveTrip(CurrentTripItem trip) async {
    developer.log('TripRepository().savedTrip() called ', name: '_hive_');
    try {
      if (!_tripsBox.isOpen) {
        await openBox();
      }

      final String jsonString =
          jsonEncode(trip.toJson()); // <-- toJson is a MyTripIem method
      await _tripsBox.put(trip.uri, jsonString);
      _tripsBox.close();
      debugPrint('[_save_] saved trip ${trip.uri} to Hive');
    } catch (e) {
      // Visible in the flutter run console - a failed save was silent
      debugPrint('[_save_] ERROR saving trip to Hive: ${e.toString()}');
    }
  }

  /// Deletes a saved trip and its stored media - its points of interest's
  /// voice memos and images, and the trip's own images
  Future<void> deleteTrip(MyTripItem trip) async {
    List<String> media = [
      for (PointOfInterest poi in trip.pointsOfInterest)
        ...CurrentTripItem.mediaOf(poi),
      ...CurrentTripItem.mediaOfImages(trip.images),
    ];
    for (String item in media) {
      await CurrentTripItem.deleteMedia(item);
    }
    try {
      Box box = Hive.isBoxOpen('trips')
          ? Hive.box('trips')
          : await Hive.openBox('trips');
      await box.delete(trip.uri);
    } catch (e) {
      developer.log('Error deleting trip from Hive ${e.toString()}',
          name: 'error');
    }
  }

  // Retrieve and decode the model
  Future<MyTripItem?> getTrip(String id) async {
    if (!_tripsBox.isOpen) {
      await openBox();
    }
    final String? jsonString = _tripsBox.get(id);
    if (jsonString == null) return null;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    _tripsBox.close();
    return MyTripItem.fromJson(jsonObject: jsonMap);
  }

  Future<List<MyTripItem>> getTrips() async {
    List<MyTripItem> tripItems = [];
    if (!_tripsBox.isOpen) {
      await openBox();
    }
    if (_tripsBox.isNotEmpty) {
      try {
        final boxValues = _tripsBox.values;
        for (var tripValue in boxValues) {
          Map<String, dynamic> tripMap = jsonDecode(tripValue);
          MyTripItem tripItem = MyTripItem.fromJson(jsonObject: tripMap);
          tripItems.add(tripItem);
        }
      } catch (e) {
        developer.log('Error getting tripItems from Hive: ${e.toString()}',
            name: 'error');
      }
    }
    _tripsBox.close();
    return tripItems;
  }
}

/// Local storage - SQLite has gone; the user, settings and trips are kept
/// in Hive on phones and the web alike. The repositories need their box
/// opening first, which these do.

Future<void> saveUserLocally(User user) async {
  UserRepository repository = UserRepository();
  await repository.openBox();
  await repository.saveUser(user);
}

/// Loads the user saved on the device into Setup().user, if there is one
Future<void> loadUserLocally() async {
  UserRepository repository = UserRepository();
  await repository.openBox();
  User? user = await repository.getUser();
  if (user != null) {
    Setup().user = user;
  }
}

Future<void> saveSetupLocally() async {
  UserRepository repository = UserRepository();
  await repository.openBox();
  await repository.saveSetup();
}

/// The trips saved on the device (My Trips)
Future<List<MyTripItem>> loadSavedTrips() async {
  TripRepository repository = TripRepository();
  await repository.openBox();
  return repository.getTrips();
}

/// A saved trip by its title - e.g. the debugging route to replay
Future<MyTripItem?> loadSavedTrip({required String title}) async {
  for (MyTripItem trip in await loadSavedTrips()) {
    if (trip.title == title) return trip;
  }
  return null;
}

/// A saved trip by its uri (its Hive key)
Future<MyTripItem?> loadSavedTripByUri(String uri) async {
  TripRepository repository = TripRepository();
  await repository.openBox();
  return repository.getTrip(uri);
}
