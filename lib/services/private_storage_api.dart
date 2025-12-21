import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'private_storage.dart';
import '/models/other_models.dart';
import '/classes/other_classes.dart';
import '/classes/my_trip_item.dart';
import '/classes/route.dart' as mt;

class PrivateStorageLocal implements PrivateDataRepository {
  @override
  Future<void> init() async {
    return;
  }

  @override
  Future<int> recordCount(table) async {
    int? count;
    return count ?? 0;
  }

  @override
  alterTable() async {}

  @override
  alterSurveyTables() async {}

// PrivateStorageLocal getLocalRepository() => PrivateStorageLocal();
  @override
  Future<int> saveSurveyData(
      {required Map<String, dynamic> map, required String table}) async {
    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getSurveyData(
      {required String table, int standId = -1, String stand = ''}) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getSetup(int id) async {
    return [];
  }

  @override
  Future<User> getUser() async {
    int id = 0;
    String forename = 'James';
    String surname = 'Seddon';
    String email = 'james@staintonconsultancy.com';
    String phone = '07761632236';
    String password = 'rubberduck';
    String imageUrl = '';
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
    return 0;
  }

  @override
  Future<void> updateSetup() async {
    return;
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
    return false;
  }

  @override
  Future<int> saveUser(User user) async {
    return 0;
  }

  @override
  Future<Uint8List?> loadImageByIdLocal({required int id}) async {
    return null;
  }

  @override
  Future<int> saveImageLocal(
      {required String imageUrl,
      driveId = -1,
      pointOfInterestId = -1,
      caption = ''}) async {
    return -1;
  }

  @override
  Future<List<MailItem>> loadMailItems() async {
    return [];
  }

  @override
  Future<List<Group>> loadGroups() async {
    return [];
  }

  @override
  Future<int> saveGroupLocal(Group group) async {
    return 1;
  }

  @override
  Future<List<GroupMember>> loadGroupMembers() async {
    return [];
  }

  @override
  Future<int> saveGroupMemberLocal(GroupMember groupMember) async {
    return 0;
  }

  @override
  Future<void> deleteGroupMemberById(int id) async {
    return;
  }

// @override
  Future<bool> saveGroupMembers(List<GroupMember> groupMembers) async {
    return true;
  }

  @override
  Future<List<HomeItem>> loadHomeItems() async {
    return [];
  }

  @override
  Future<List<HomeItem>> saveHomeItemsLocal(List<HomeItem> homeItems) async {
    return [];
  }

  @override
  Future<List<ShopItem>> loadShopItems() async {
    return [];
  }

  @override
  Future<List<TripItem>> loadTripItems() async {
    return [];
  }

  @override
  Future<TripItem?> loadTripItemLocal({int id = -1}) async {
    return null;
  }

  /// If the API is online saveShopItemsLocal will refresh the local
  /// cache of shopItems. It will clear the SQLite db and download
  /// all the relevant data again.
  /// ToDo: Add some filtering to only update new or changed data
  @override
  Future<List<ShopItem>> saveShopItemsLocal(List<ShopItem> shopItems) async {
    return [];
  }

  /// If the API is online saveTripItemsLocal will refresh the local
  /// cache of tripItems. It will clear the SQLite db and download
  /// all the relevant data again.
  /// ToDo: Add some filtering to only update new or changed data
  @override
  Future<List<TripItem>> saveTripItemsLocal(List<TripItem> tripItems) async {
    return [];
  }

  @override
  Future<int> saveMessage(MessageLocal message) async {
    return 0;
  }

  @override
  Future<Map<String, dynamic>> getDrive(int driveId) async {
    return {};
  }

  @override
  Future<void> deleteDriveById(int id) async {
    return;
  }

//

  @override
  Future<void> deleteDriveLocal({required int driveId}) async {
    return;
  }

// "type 'int' is not a subtype of type 'Map<String, dynamic>'"
  @override
  Future<int> saveDrive({required Drive drive}) async {
    return 0;
  }

  @override
  Future<int> saveMyTripItem(MyTripItem myTripItem) async {
    return 0;
  }

  @override
  Future<OsmAmenity> loadOsmAmenityLocal({required int id, index = 0}) async {
    return OsmAmenity(
        position: LatLng(0, 0),
        marker: Marker(point: LatLng(0, 0), child: Icon(Icons.add)) as Widget);
  }

  @override
  Future<int> saveOsmAmenityLocal({required OsmAmenity amenity}) async {
    return 0;
  }

  @override
  Future<bool> saveOsmDataLocal(
      {required int driveId, required List<OsmAmenity> osmData}) async {
    return true;
  }

  @override
  String pointsToString(List<LatLng> points) {
    return '';
  }

  @override
  Future<List<PointOfInterest>> loadPointsOfInterestLocal(int driveId) async {
    return [];
  }

  @override
  Future<PointOfInterest> loadPointOfInterestLocal(
      {required int id, index = 0}) async {
    return PointOfInterest();
  }

  @override
  Future<bool> savePointsOfInterestLocal(
      {required int driveId,
      required List<PointOfInterest> pointsOfInterest}) async {
    return true;
  }

  @override
  Future<int> savePointOfInterestLocal(
      {required int driveId, required PointOfInterest pointOfInterest}) async {
    return 0;
  }

  @override
  Future<void> deletePointOfInterestById(int id) async {
    return;
  }

  @override
  Future<void> deletePointOfInterestByDriveId(int driveId) async {
    return;
  }

  /// Saves the myTrips to the local SQLite database
  ///

  @override
  Future<bool> saveManeuversLocal({
    required int driveId,
    required List<Maneuver> maneuvers,
  }) async {
    return true;
  }

  @override
  Future<List<Maneuver>> loadManeuversLocal(int driveId) async {
    return [];
  }

  @override
  Future<void> deleteManeuversByDriveId(int driveId) async {
    return;
  }

  @override
  Future<bool> savePolylinesLocal(
      {required int driveId,
      required List<mt.Route> polylines,
      List<PointOfInterest> pointsOfInterest = const [],
      type = 0}) async {
    return true;
  }

  @override
  Future<void> deletePolyLinesById(int id) async {
    return;
  }

  @override
  Future<void> deletePolyLinesByDriveId(int driveId) async {
    return;
  }

  @override
  Future<List<Follower>> loadFollowers(int driveId) async {
    return [];
  }

  @override
  Future<bool> saveFollowersLocal(
      {required int driveId, required List<Follower> followers}) async {
    return true;
  }

  @override
  Future<void> deleteFollowerById(int id) async {
    return;
  }

  @override
  Future<void> deleteFollowerByDriveId(int driveId) async {
    return;
  }

  /// Get the polylines for a drive from SQLite
  /// Will initially only load the descriptive details and only
  /// load the details if the drive is selected
  ///

  @override
  Future<List<mt.Route>> getRoutesByName({required String name}) async {
    return [];
  }

  @override
  Future<List<mt.Route>> loadPolyLinesLocal(int driveId, {type = 0}) async {
    return [];
  }

  @override
  Future<mt.Route> loadPolyLineLocal(int id, {type = 0}) async {
    return mt.Route(points: []);
  }

  @override
  Future<Uint8List> loadTileLocal({required String key}) async {
    return Uint8List(0);
  }

  @override
  Future<List<mt.Route>> loadRoutesLocal(int id,
      {type = 0, driveKey = -1}) async {
    return [];
  }

  @override
  Future<Uint8List> loadImageBytesLocal({required int id}) async {
    return Uint8List(0);
  }

  @override
  List<LatLng> stringToPoints(String pointsString) {
    return [];
  }

  @override
  String polyLineToString(List<Polyline> polyLines) {
    return '';
  }

  @override
  Future<List<MyTripItem>> tripItemFromDb(
      {int driveId = -1, bool showMethods = false}) async {
    return [];
  }
}

PrivateStorageLocal getPrivateRepository() => PrivateStorageLocal();
