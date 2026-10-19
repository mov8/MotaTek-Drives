import 'dart:convert';
import '/models/models.dart';
import '/classes/classes.dart';
import '/services/services.dart';
import 'package:hive/hive.dart';
import 'dart:developer' as developer;

// https://resocoder.com/2019/09/30/hive-flutter-tutorial-lightweight-fast-database/
// Although storing data as json is fine, at some stage should convert to adaptors

// Following test routine works
// final Box name = await Hive.openBox('name');
// await Hive.openBox('name');
// name.put('name', 'David');

class UserRepository {
  late final Box _userBox;
  Future<bool> openBox() async {
    _userBox = await Hive.openBox('user');
    return true;
  }

  // void openBox() => Hive.openBox('userBox');
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
      //  await Hive.openBox('tripsBox');
      await _tripsBox.put(trip.uri, jsonString);
      _tripsBox.close();
      developer.log('Saved trip to Hive OK ', name: '_hive_');
    } catch (e) {
      developer.log('Error saving trip to Hive ${e.toString()}',
          name: '_hive_');
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
