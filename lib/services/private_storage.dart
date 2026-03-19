import 'dart:typed_data';
import 'dart:ui' as ui;
// import 'package:flutter_map/flutter_map.dart';
import '/classes/route.dart';
import '/classes/my_trip_item.dart';
import '/classes/other_classes.dart';
import '/models/other_models.dart';
import '/models/models.dart';
import 'dart:async';

abstract class PrivateDataRepository {
  Future<void> init();

  Future<int> recordCount(table);

  alterTable();

  alterSurveyTables();

  Future<int> saveSurveyData(
      {required Map<String, dynamic> map, required String table});

  Future<List<Map<String, dynamic>>> getSurveyData(
      {required String table, int standId = -1, String stand = ''});

  Future<List<Map<String, dynamic>>> getSetup(int id);

  Future<User> getUser();

  Future<int> insertSetup(Setup setup);

  Future<void> updateSetup();

  Future<bool> checkUser({required User user});

  Future<int> saveUser(User user);

  Future<Uint8List?> loadImageByIdLocal({required int id});

  Future<String> saveImageLocal(
      {required ui.Image image,
      driveUri = '',
      pointOfInterestUri = '',
      imageId = 1});

  Future<List<MailItem>> loadMailItems();

  Future<List<Group>> loadGroups();

  Future<int> saveGroupLocal(Group group);

  Future<List<GroupMember>> loadGroupMembers();

  Future<int> saveGroupMemberLocal(GroupMember groupMember);

  Future<void> deleteGroupMemberById(int id);

  Future<List<HomeItem>> loadHomeItems();

  Future<List<HomeItem>> saveHomeItemsLocal(List<HomeItem> homeItems);

  Future<List<ShopItem>> loadShopItems();

  Future<List<TripItem>> loadTripItems();

  Future<TripItem?> loadTripItemLocal({int id = -1});

  Future<List<TripItem>> loadMyTripItems();

  Future<dynamic> publish(MyTripItem tripItem);

  Future<List<ShopItem>> saveShopItemsLocal(List<ShopItem> shopItems);

  Future<List<TripItem>> saveTripItemsLocal(List<TripItem> tripItems);

  Future<int> saveMessage(MessageLocal message);

  Future<Map<String, dynamic>> getDrive(int driveId);

  Future<void> deleteDriveById(String driveUri);

  Future<void> deleteDriveLocal({required String driveUri});

  Future<int> saveDrive({required Drive drive});

  Future<int> saveMyTrip(CurrentTripItem tripItem);

/*
  Future<OsmAmenity> loadOsmAmenityLocal({required int id, index = 0});

  Future<int> saveOsmAmenityLocal({required OsmAmenity amenity});

  Future<bool> saveOsmDataLocal(
      {required int driveId, required List<OsmAmenity> osmData});
*/
  String pointsToString(List<List<double>> points);

  Future<List<PointOfInterest>> loadPointsOfInterestLocal(int driveId);

  Future<PointOfInterest> loadPointOfInterestLocal(
      {required int id, index = 0});

  Future<bool> savePointsOfInterestLocal(
      {required int driveId, required List<PointOfInterest> pointsOfInterest});

  Future<int> savePointOfInterestLocal(
      {required int driveId, required PointOfInterest pointOfInterest});

  Future<void> deletePointOfInterestById(int id);

  Future<void> deletePointOfInterestByDriveId(int driveId);

  Future<bool> saveManeuversLocal({
    required int driveId,
    required List<Maneuver> maneuvers,
  });

  Future<List<Maneuver>> loadManeuversLocal(int driveId);

  Future<void> deleteManeuversByDriveId(int driveId);

  Future<bool> savePolylinesLocal(
      {required int driveId,
      required List<Map<String, dynamic>> polylines,
      List<PointOfInterest> pointsOfInterest = const [],
      type = 0});

  Future<void> deletePolyLinesById(int id);

  Future<void> deletePolyLinesByDriveId(int driveId);

  Future<List<Follower>> loadFollowers(int driveId);

  Future<bool> saveFollowersLocal(
      {required int driveId, required List<Follower> followers});

  Future<void> deleteFollowerById(int id);

  Future<void> deleteFollowerByDriveId(int driveId);

  Future<List<Route>> getRoutesByName({required String name});

  Future<List<Route>> loadPolyLinesLocal(int driveId, {type = 0});

  Future<Route> loadPolyLineLocal(int id, {type = 0});

  Future<Uint8List> loadTileLocal({required String key});

  Future<List<Route>> loadRoutesLocal(int id, {type = 0, driveKey = -1});

  Future<Uint8List> loadImageBytesLocal({required int id});

  // List<List<double>> stringToPoints(String pointsString);

//  String polyLineToString(List<Polyline> polyLines);

  Future<List<MyTripItem>> tripItemFromDb(
      {int driveId = -1, bool showMethods = false});
}
