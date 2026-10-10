import 'dart:convert';
import '/models/models.dart';
import '/classes/classes.dart';
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
    final String jsonString = jsonEncode(user.toMap());
    await _userBox.put('user', jsonString);
  }

  Future<void> saveJwt(String jwt) async {
    await _userBox.put('jwt', jwt);
  }

  Future<void> saveSetup() async {
    final String jsonString = jsonEncode(Setup().toMap());
    await _userBox.put('setup', jsonString);
  }

  // Retrieve and decode the model safely
  User? getUser() {
    final String? jsonString = _userBox.get('user');
    if (jsonString == null) return null;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return User.fromJson(jsonMap);
  }

  String getJwt() {
    return _userBox.get('jwt') ?? '';
  }

  bool getSetup() {
    final String? jsonString = _userBox.get('setup');
    if (jsonString == null) return false;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    Setup().fromJson(map: jsonMap);
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
    try {
      final String jsonString =
          jsonEncode(trip.toJson()); // <-- toJson is a MyTripIem method
      //  await Hive.openBox('tripsBox');
      await _tripsBox.put(trip.uri, jsonString);
    } catch (e) {
      developer.log('Error saving trip to Hive ${e.toString()}',
          name: '_trip_');
    }
  }

  // Retrieve and decode the model
  Future<MyTripItem?> getTrip(String id) async {
    final String? jsonString = _tripsBox.get(id);
    if (jsonString == null) return null;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return MyTripItem.fromJson(jsonObject: jsonMap);
  }

  Future<List<MyTripItem>> getTrips() async {
    List<MyTripItem> tripItems = [];
    developer.log('Executing hive_helper TripRepository().getTrips()',
        name: '_trips_');
    if (_tripsBox.isNotEmpty) {
      try {
        developer.log(
            'Executing hive_helper TripRepository().getTrips() _tripsBox.isNotEmpty',
            name: '_trips_');
        final boxValues = _tripsBox.values;
        for (var tripValue in boxValues) {
          Map<String, dynamic> tripMap = jsonDecode(tripValue);
          MyTripItem tripItem = MyTripItem.fromJson(jsonObject: tripMap);
          tripItems.add(tripItem);
        }
      } catch (e) {
        developer.log('Error getting tripItems from Hive: ${e.toString()}',
            name: '_trips_');
      }
    }
    return tripItems;
  }
}
