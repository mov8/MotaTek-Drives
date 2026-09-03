import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'models/models.dart';
import 'screens/screens.dart';

const appVersion = {'major': 0, 'minor': 0, 'patch': 9, 'suffix': 'beta db'};

const apiAddress = 'https://drives.motatek.com/';
const wifiIpAddress = 'http://192.168.1.168:5001/';
// 'http://10.101.1.216:5001/'; // <- Home

// const wifiIpAddress = 'http://10.164.124.105:5001/'; // < Redmi
// const wifiIpAddress = 'http://192.168.1.111:5001/'; // <- Boston unit
// const wifiIpAddress = 'http://192.168.68.122:5001/'; // <- Barnet
// const wifiIpAddress = 'http://192.168.1.212:5001/'; // <- Irby Street
// const wifiIpAddress = 'http://192.168.68.112:5001/'; // <- Dias
// const wifiIpAddress = 'http://10.249.4.160:5001/'; // <- airport joburg
// const wifiIpAddress ='http://10.2.222.57:5001/'; // <- Staines library 10.2.222.57:5001
// https://drives.motatek.com/v1/user/test

const urlBase = wifiIpAddress;
// const urlBase = apiAddress;

const mapsApiKey = '';

const String motatekId = 'f9440cb2e8c747c2811bc80ef5653ce6';

const double degreeToRadians = 0.0174532925; // degrees to radians pi/180

const organisationName = 'MotaTek';

const List<String> routes = [
  'home',
  'trips',
  'createTrip',
  'myTrips',
  'shop',
  'messages'
];

int oneTenthMile = 161;

enum LoginState { notLoggedin, cancel, login, register, edit, resetPassword }

enum LoginStatus {
  noData,
  noEmail,
  emailInvalid,
  emailUnknown,
  emailKnown,
  noPassword,
  passwordValid,
  passwordUnknown,
  passwordTooShort,
  emailHasChars,
}

enum LoginError {
  noData,
  noEmail,
  noPassword,
  invalidEmail,
  wrongEmail,
  wrongPassword,
  wrongData,
  allOk,
  none,
}

enum MyTripActions {
  none,
  startManual,
  beginTracking,
  track,
  addWaypoint,
  deleteWaypoint,
  revisitWaypoint,
  extendEnd,
  editTrip,
  addPointOfInterest,
  addGoodRoadDetails,
  addGoodRoad,
  saveGoodRoad,
  saveTrip,
  follow,
  stopFollowing,
  stopTracking,
  clearTrip,
  reverseTrip,
  showSteps,
  showMessages,
  showGroup,
  message,
  getMap,
}

enum MarkerTypes {
  trip,
  goodRoad,
  pointOfInterest,
}

enum MapHeights {
  full,
  headers,
  pointOfInterest,
  message,
}

enum AppState {
  loading,
  home,
  createTrip,
  trips,
  myTrips,
  shop,
  messages,
  driveTrip
}

enum TripType { none, saved, group }

enum TripState {
  none,
  editing,
  loaded,
  manual,
  tracking,
  stoppedTracking,
  pausedTracking,
  following,
  notFollowing,
  stoppedFollowing,
  startFollowing,
  manualStart,
  goodRoadStart,
  clearing,
}

enum WaypointState { none, extendStart, extendEnd, insert, revisit, remove }

enum TripActions {
  none,
  readOnly,
  saving,
  saved,
  headingDetail,
  pointOfInterest,
  goodRoad,
  showGroup,
  showSteps,
  showMessages,
}

enum HighliteActions {
  none,
  greatRoadStarted,
  greatRoadNamed,
  greatRoadEnded,
  greatRoadHighlighted,
  routeHighlited,
  waypointHighlited,
}

enum GroupActions {
  none,
  editName,
  addGroup,
  addMember,
}

enum ChangedFeatures {
  route(1),
  goodRoad(2),
  features(3),
  viewPort(4),
  all(7),
  none(0);

  const ChangedFeatures(this.value);
  final num value;
  bool routeChanged() => [1, 3, 7].contains(value);
  bool goodRoadsChanged() => [2, 3, 7].contains(value);
  bool viewPortChanged() => [4, 5, 6].contains(value);
}

/* 
  11111111 & 10011001 -> 10011001   returns 1 where both are 1 
  11111111 | 10011001 -> 11111111   returns 1 where either are 1
  11111111 ^ 10011001 -> 01100110   returns 1 where only one is 1 
  value    name               purpose                 action
  00000000 none
  00000001 route
  00000010 goodRoad
  00000100 pointOfInterest
  00001000 steps
  00010000 messages
  00100000 requested         add BottomDrawer data  clear complete    return requested version of enum
  01000000 complete          add geoJSON to map     set complete bit 
*/

/// Objectives:
///   1 Set the enum type when the ActionChip is tapped
///   2 Set the enums state during processing requested / completed
///     before and after the data has been added in the bottom drawer
///   ie. _controlEnum = driveData
///       _controlEnum = controlEnum.requested
///       if (_controlEnum == ControlEnum.driveData && _controlEnum.completed)
///
/// Nifty extension of enums which are immutable to allow
/// then to have two states
///   1 requested the user has tapped the ActionChip to open drawer
///   2 completed the user has added the data now update the map
///

/*
enum DataSources {none, goodRoads, pointsOfInterest, headers, steps, messages}
enum DataSourceStates {none, requested, completed}

class BottomDrawerData {
  bool none
}
*/

enum BottomDrawerData {
  none(0),
  heading(1 << 0),
  pointOfInterest(1 << 1),
  steps(1 << 2),
  messages(1 << 3),
  group(1 << 4),
  maneuvers(1 << 5),
  headingRequested((1 << 0) | (1 << 6)),
  headingCompleted((1 << 0) | (1 << 7)),
  pointOfInterestRequested((1 << 1) | (1 << 6)),
  pointOfInterestCompleted((1 << 1) | (1 << 7));

  final int value;
  const BottomDrawerData(this.value);
  bool get isPointOfInterest => value & pointOfInterest.value != 0;
  bool get isHeading => value & heading.value != 0;
  bool get isRequested => value & (1 << 6) != 0;
  bool get isCompleted => value & (1 << 7) != 0;

  BottomDrawerData requested() {
    // have to clear the completed bit before setting with 01111111 (127)
    // requested bit else returns BottomDrawerData.none
    return _fromValue((value & 127) | (1 << 6));
  }

  BottomDrawerData completed() {
    // have to clear the requested bit before setting with 10111111 (191)
    // completed bit else returns BottomDrawerData.none
    return _fromValue((value & 191) | (1 << 7));
  }

  BottomDrawerData clear() => _fromValue((value | 128));

  static BottomDrawerData _fromValue(int value) {
    return BottomDrawerData.values.firstWhere((e) => e.value == value,
        orElse: () => BottomDrawerData.none);
  }
}

/// BitMask combination enabled enum allows the easy tracking
/// of combined requests

List<String> mapSources = [
  'route-data',
  'good-road-data',
  'waypoint-data',
  'good-road-waypoint-data',
  'point-of-interest-data',
  'followers'
];

/// MapUpdates combination enum to action user requests on the map
/// can be either a single action or a combination
/// Each separate action has an Object providing the data and a
/// method to convert the data to geoJson for the
/// Flags:
///   decimal binary      App data
///         1 [00000001]  List<Route>
///         2 [00000010]  List<GoodRoad>
///         3 [00000011]  route + goodRoad
///         4 [00000100]  List<Waypoint>
///         5 [00000101]
///         6 [00000110]
///         7 [00000111]
///         8 [00001000]  GoodRoad.List<Waypoint>
///         9 [00001001]
///        10 [00001010]
///        16 [00010000]  List<PointOfInterest>
///        32 [00100000]  List<Follower>
///        33 [00100001]
///        64 [01000000]
///        65 [01000001]
///        66 [01000011]
///        68 [01000100]
///        69 [01000101]
///        73 [01001010]
///        80 [01010000]
///        96 [01100000]
///        97 [01100001]

///   It's not sensible to provide for all combinations, but it's important
///   that a value exists for any enum the user uses. Best strategy is to check
///   when it unexpectedly returns none, then add an enum for that combination.
///   This should be checked when a new call to .remove() is added.
enum MapUpdates {
  none(0), //                                               00000000
  routes(1), // 1 << 1                                      00000001
  goodRoads(2), // 1 << 2                                   00000010
  waypoints(4), // 1 << 3                                   00000100
  routesAndWaypoints(5), //                                 00000101
  goodRoadWaypoints(8), // 1 << 4                           00001000
  goodRoadsAndGoodRoadWaypoints(10), //                     00001010
  pointsOfInterest(16), // 1 << 5                           00010000
  routesAndWaypointsAndPointsOfInterest(21), //             00010101
  goodRoadsAndWaypointsAndPointsOfInterest(26), //          00011010
  followers(32), // 1 << 6                                  00100000
  routesAndFollowers(33), //                                00100001
  allWithoutAllWaypoints(51), //                            00111011
  allWithoutWaypoints(59), //                               00110011
  updatingRoutes(65),
  updatingGoodRoads(130),
  updatingWaypoints(132),
  updatingRoutesAndWaypoints(133),
  updatingGoodRoadsAndGoodRoadWaypoints(138),
  updatingPointsOfInterest(144),
  updatingGoodRoadsAndWaypointsAndPointsOfInterest(154), //
  updatingFollowers(160),
  updatingRoutesAndFollowers(161),
  updateAll(127), //   01111111
  updating(128), //   10000000
  updatingAll(255);

// 1 + 4 : 2 + 8
  const MapUpdates(this.value);
  final int value;

  MapUpdates add(MapUpdates added) {
    return _fromValue(added.value | value);
  }

  MapUpdates remove(MapUpdates removed) {
    // To flip the bits add 1 to the mask decimal value and * -1 this overcomes the 2's compliment
    // Have to ensure the all flag bit 6 is cleared first 64 -> -65
    // 00111111 - clear all higher combination values
    int newValue = value & 63;
    int newValue2 = newValue & ((removed.value + 1) * -1);
    return _fromValue(newValue2);
  }

  MapUpdates notUpdating() {
    // The & 63 removes the updating bit 64 if set (63 = [00111111], 64 = [01000000])
    return _fromValue(value & 127);
  }

  bool get includesRoutes => value & routes.value != 0;
  bool get includesGoodRoads => value & goodRoads.value != 0;
  bool get includesWaypoints => value & waypoints.value != 0;
  bool get includesGoodRoadWaypoints => value & goodRoadWaypoints.value != 0;
  bool get includesPointsOfInterest => value & pointsOfInterest.value != 0;
  bool get includesLocationStream => value & followers.value != 0;
  bool get isUpdating => value & updating.value != 0;
  String get routesSource => value & routes.value != 0 ? 'route-data' : '';
  String get goodRoadsSource =>
      value & goodRoads.value != 0 ? 'good-road-data' : '';
  String get waypointsSource =>
      value & waypoints.value != 0 ? 'waypoint-data' : '';
  String get goodRoadWaypointsSource =>
      value & goodRoadWaypoints.value != 0 ? 'waypoint-data' : '';
  String get pointsOfInterestSource =>
      value & followers.value != 0 ? 'point-of-interest-data' : '';

  List<String> get sourcesToUpdate {
    List<String> sources = [];
    for (int i = 0; i < mapSources.length; i++) {
      if (value & (1 << i) != 0) {
        sources.add(mapSources[i]);
      }
    }
    return sources;
  }

  // route-data, waypoint-data, user-data, good-road-data, point-of-interest-data

  static MapUpdates _fromValue(int value) {
    return MapUpdates.values
        .firstWhere((e) => e.value == (value), orElse: () => MapUpdates.none);
  }
}

enum GroupMemberState { none, isNew, registered, incomplete, complete, added }

enum GroupAction { add, delete, edit, invite, uninvite, update, leave }

// enums HighLightActions TripActions TripState MapHeights
// https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status#informational_responses

const List<String> settlementTypes = ['city', 'town', 'village', 'hamlet'];
DateFormat dateFormat = DateFormat('dd/MM/yy');
DateFormat dateFormatSQL = DateFormat('yyyy-MM-dd hh:mm:ss');
DateFormat dateFormatDoc = DateFormat('E dd/MM/yyyy');
DateFormat dateFormatDocTime = DateFormat('E dd/MM/yyyy hh:mm:ss');

Color backgroundColour = Color.fromRGBO(2, 46, 75, 0);

/// Constants for Markdown helpers
Map<String, Color> colour = {
  'amber': Colors.amber,
  'black': Colors.black,
  'blue': Colors.blue,
  'cyan': Colors.cyan,
  'green': Colors.green,
  'grey': Colors.grey,
  'indigo': Colors.indigo,
  'lime': Colors.lime,
  'orange': Colors.orange,
  'pink': Colors.pink,
  'purple': Colors.purple,
  'red': Colors.red,
  'teal': Colors.teal,
  'white': Colors.white,
  'yellow': Colors.yellow,
};

Map<String, double> fontSizes = {
  '16 pt': 16,
  '18 pt': 18,
  '20 pt': 20,
  '22 pt': 22,
  '24 pt': 24,
  '28 pt': 28
};

Map<String, FontStyle> fontStyles = {
  'italic': FontStyle.italic,
  'normal': FontStyle.normal
};

Map<String, FontWeight> fontWeights = {
  'bold': FontWeight.bold,
  'normal': FontWeight.normal
};

///

List<IconData> inviteIcons = [
  Icons.thumbs_up_down_outlined,
  Icons.thumb_down_outlined,
  Icons.thumb_up_outlined,
  Icons.outgoing_mail,
];

/// The next 3 lists are for the bottom and top navigations
///
const List<String> routeNavLabels = [
  'Home',
  'Published', //  'Great Drives',
  'Explore', //'My Trip',
  'Favourites',
  'Shop',
  'Messages'
];

const List<IconData> routeNavIconsSelected = [
  Icons.home,
  Icons.map_sharp,
  Icons.explore,
  Icons.favorite_sharp,
  Icons.shopping_bag,
  Icons.chat_bubble
];

const List<IconData> routeNavIcons = [
  Icons.home_outlined,
  Icons.map_outlined,
  Icons.explore_outlined,
  Icons.favorite_border_outlined,
  Icons.shopping_bag_outlined,
  Icons.chat_bubble_outline_outlined,
];

const Map<int, String> responseCodes = {
  200: 'OK',
  201: 'created',
  202: 'accepted',
  204: 'no data',
  400: 'request error', //
  401: 'unauthorised', //  <-- password failed
  403: 'forbidden', //  <-- JWT problem
  408: 'timed out',
  410: 'missing' //  <-- User not found
};

const List<String> contactChoices = [
  'All OK',
  'Stopping for fuel',
  'Stopping for food',
  'Mechanical problem',
  'Stopping for a break',
  'Stuck in traffic',
  'Lost the way',
];

/// allow access to shop and home
enum UserType {
  user(1),
  administrator(2),
  owner(4);

  final int value;
  const UserType(this.value);
}

/// Before changing any values check drawerOptions etc for consequences
/// The order isn't important, but the names are.
enum BottomDrawerItems {
  none,
  goodRoad,
  group,
  headingDetail,
  maneuvers,
  messages,
  pointOfInterest,
  showGroup,
  steps,
  trip, // <-- trip = heading, good road and points of interest
  home,
  shop,
  drives,
  favourites,
  settings,
  register,
  myGroups,
  groups,
  invite,
  myEvents,
  events,
  docs,
  markdown, // <-- Markdown editor
  markdownHome, // <-- Markdown summary tile
  markdownShop, // <-- Markdown summary tile
  cached,
}

/// This list ensures that the overflow popup menu options are
/// named correctly, and that when chosen the appropriate
/// BottomDrawerItems enum is selected.
/// Now includes all the TripState enum options too as it
/// simplifies the Action Prompt in the WebAppBar
List<Map<String, dynamic>> drawerOptions = [
  {
    'key': 'settings',
    'text': 'App settings',
    'iconData': const Icon(Icons.settings_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.settings,
    'screen': SetupForm(),
  },
  {
    'key': 'register',
    'text': Setup().jwt.isEmpty ? 'Register my details' : 'Change my details',
    'iconData': Icon(Icons.manage_accounts_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.register,
    'screen': SignupForm(),
  },
  {
    'key': 'myGroups',
    'text': 'Groups I manage',
    'iconData': Icon(Icons.groups_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.myGroups,
    'screen': GroupForm(),
  },
  {
    'key': 'groups',
    'text': 'Groups to which I belong',
    'iconData': Icon(Icons.group_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.groups,
    'screen': MyGroupsForm(),
  },
  {
    'key': 'invite',
    'text': 'Invite a new user',
    'iconData': Icon(Icons.person_add_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.invite,
    'screen': IntroduceForm(),
  },
  {
    'key': 'myEvents',
    'text': "Events I've organised",
    'iconData': Icon(Icons.directions_car_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.myEvents,
    'screen': GroupDriveForm(),
  },
  {
    'key': 'events',
    'text': "Events to which I've been invited",
    'iconData': Icon(Icons.mail_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.events,
    'screen': InvitationsScreen(),
  },
  {
    'key': 'docs',
    'text': 'Drives documentation',
    'iconData': Icon(Icons.groups_outlined, size: 30),
    'method': BottomDrawerItems.settings,
    'drawer': BottomDrawerItems.docs,
    'screen': DocumentationForm()
  },
  {
    'key': 'markdownHome',
    'text': 'Home page contents',
    'iconData': Icon(Icons.home_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.markdownHome,
    'screen': MarkdownForm(
      markdownData: {},
      dataType: 'home',
    )
  },
  {
    'key': 'markdownShop',
    'text': 'Shop page contents',
    'iconData': Icon(Icons.shopping_bag_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.markdownShop,
    'screen': MarkdownForm(
      markdownData: {},
      dataType: 'shop',
    ) //Shop()
  },
  {
    'key': 'goodRoad',
    'text': 'Good road details',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.goodRoad,
    'screen': '',
  },
  {
    'key': 'group',
    'text': 'Group members',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.group,
    'screen': '',
  },
  {
    'key': 'headingDetail',
    'text': 'Please enter trip description',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.headingDetail,
    'screen': '',
  },
  {
    'key': 'maneuvers',
    'text': 'Turn-by-turn instructions',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.maneuvers,
    'screen': '',
  },
  {
    'key': 'messages',
    'text': 'Messages from other users',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.messages,
    'screen': '',
  },
  {
    'key': 'pointOfInterest',
    'text': 'Trip highlight details',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.pointOfInterest,
    'screen': '',
  },
  {
    'key': 'showGroup',
    'text': 'Group details',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.showGroup,
    'screen': '',
  },
  {
    'key': 'steps',
    'text': 'Turn-by-turn instructions',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.steps,
    'screen': '',
  },
  {
    'key': 'trip',
    'text': 'Details of this trip',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.trip,
    'screen': '',
  },
  {
    'key': 'drives',
    'text': 'Published drives to download',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.drives,
    'screen': '',
  },
  {
    'key': 'favourites',
    'text': 'Saved private trips',
    'iconData': '',
    'method': '',
    'drawer': BottomDrawerItems.favourites,
    'screen': '',
  },
];

enum InviteState { undecided, declined, accepted }

RegExp emailRegex = RegExp(r'[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

const List<int> responseOk = [200, 201, 202, 204];
const List<int> responseError = [400, 401, 403, 408, 410];

const int dbVersion = 1;

// String stadiaMapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';

const LatLng ukNorthEast = LatLng(61, 2);
const LatLng ukSouthWest = LatLng(49, -8);

const double metersToMiles = 0.000621371192;
const double metersPerSecondToMPH = 3.6 / 8 * 5;
const double metersPerSecondToKmPH = 3.6;
const double metersToYards = 0.9144;
const double metersPerMile = 1609.344;
const double metersPerTenths = 160.934;
const double yardsToMeters = 1.0936133;
const double yardsPerMile = 1760;
const double yardsToMiles = 0.000568182;
const List<String> tableDefs = [
  /// CACHES

  /// '''CREATE TABLE caches(id INTEGER PRIMARY KEY AUTOINCREMENT, uri TEXT,
  /// feature_id INTEGER, type INTEGER, added DATETIME)''',

  /// DRIVES - 19/02/26 modified to hold drives as a JSON string in column 'trip' rather than shredding it
  '''CREATE TABLE drives(id INTEGER PRIMARY KEY AUTOINCREMENT, uri TEXT, title TEXT, sub_title TEXT, trip TEXT, 
  distance INTEGER, points_of_interest INTEGER, added TEXT)''',

  /// FEATURES
  '''CREATE TABLE features(id INTEGER PRIMARY KEY AUTOINCREMENT, uri TEXT, feature_id INTEGER, 
 latitude REAL, longitude REAL, type INTEGER)''',

  /// FOLLOWERS
  '''CREATE TABLE followers(id INTEGER PRIMARY KEY AUTOINCREMENT, uri TEXT, drive_id INTEGER, forename TEXT, 
  surname TEXT, phone_number TEXT, car TEXT, registration TEXT, icon_colour INTEGER, position TEXT, 
  reported DATETIME)''',

  /// GROUPS
  '''CREATE TABLE groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, 
  created DATETIME)''',

  /// GROUP_MEMBERS
  '''CREATE TABLE group_members(id INTEGER PRIMARY KEY AUTOINCREMENT, group_ids STRING, forename TEXT, surname TEXT, 
  email TEXT, phone TEXT, status Integer, joined DATETIME, note TEXT, uri TEXT)''',

  /// HOME_ITEMS
  '''CREATE TABLE home_items(id INTEGER PRIMARY KEY AUTOINCREMENT, 
  uri TEXT, heading TEXT, sub_heading TEXT, body TEXT, image_urls TEXT, 
  added DATETIME, score INTEGER, coverage TEXT)''',

  /// IMAGES
  '''CREATE TABLE images(id INTEGER PRIMARY KEY AUTOINCREMENT, 
  drive_id INTEGER, point_of_interest_id INTEGER, caption TEXT, image BLOB, added DATETIME)''',

  /// LOG
  '''CREATE TABLE log(id INTEGER PRIMARY KEY AUTOINCREMENT, monitor INTEGER, dateTime DATETIME, portNumber INTEGER, 
  value REAL, alarm INTEGER)''',

  /// MANEUVERS
  '''CREATE TABLE maneuvers(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, road_from TEXT, 
  road_to TEXT, bearing_before INTEGER, bearing_after INTEGER, exit INTEGER, location TEXT, 
  modifier TEXT, type TEXT, distance REAL)''',

  /// MAPCACHE
  '''CREATE TABLE map_cache(id INTEGER PRIMARY KEY AUTOINCREMENT, 
  key TEXT, value BLOB, added DATETIME)''',

  /// MESSAGES
  '''CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, target_id INTEGER, message TEXT, 
  read INTEGER, received DATETIME)''',

  /// NOTIFICATIONS
  '''CREATE TABLE notifications(id INTEGER PRIMARY KEY AUTOINCREMENT, sentBy TEXT, message TEXT, 
  received DATETIME)''',

  /// OSM_DATA
  '''CREATE TABLE osm_data(id INTEGER PRIMARY KEY AUTOINCREMENT, osm_id INTEGER, 
  name TEXT, amenity TEXT, postcode TEXT, lat FLOAT, lng FLOAT)''',

  /// POINTS_OF_INTEREST
  '''CREATE TABLE points_of_interest(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, type INTEGER, 
  waypoint INTEGER, name TEXT, description TEXT, images TEXT, sounds TEXT, latitude REAL, longitude REAL)''',

  /// POLYLINES
  '''CREATE TABLE polylines(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, 
  type INTEGER, point_of_interest_id INTEGER, points TEXT, colour Integer, stroke INTEGER)''',

  /// SETUP
  '''CREATE TABLE setup(id INTEGER PRIMARY KEY AUTOINCREMENT, route_colour INTEGER, good_route_colour INTEGER, 
  waypoint_colour INTEGER, waypoint_colour_2 INTEGER, point_of_interest_colour INTEGER, rotate_map INTEGER, 
  point_of_interest_colour_2 INTEGER, selected_colour INTEGER, highlighted_colour INTEGER, published_trip_colour INTEGER, 
  record_detail INTEGER, allow_notifications INTEGER, jwt TEXT, dark INTEGER, avoid_motorways INTEGER, 
  avoid_a_roads INTEGER, avoid_b_roads INTEGER, avoid_toll_roads INTEGER, avoid_ferries INTEGER, 
  osm_pubs INTEGER, osm_restaurants INTEGER, osm_fuel INTEGER, osm_toilets INTEGER, 
  osm_atms INTEGER, osm_historical INTEGER, bottom_nav_index INTEGER, route TEXT, app_state TEXT, male_voice INTEGER)''',

  /// SHOP_ITEMS
  '''CREATE TABLE shop_items(id INTEGER PRIMARY KEY AUTOINCREMENT, 
  uri TEXT, heading TEXT, sub_heading TEXT, body TEXT, image_urls TEXT, 
  added DATETIME, score INTEGER, coverage TEXT, url_1 TEXT, button_text_1, TEXT, url_2 TEXT, button_text_2 TEXT)''',

  /// TRIP_ITEMS
  '''CREATE TABLE trip_items(id INTEGER PRIMARY KEY AUTOINCREMENT, heading TEXT, uri TEXT, sub_heading TEXT, 
  body TEXT, author TEXT, author_url TEXT, published DATETIME, image_urls TEXT, score REAL, 
  scored INTEGER, distance REAL, points_of_interest INTEGER, closest INTEGER, downloads INTEGER)''',

  /// USERS
  '''CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, forename TEXT, surname TEXT, email TEXT, 
  phone TEXT, password TEXT, imageUrl Text)''',

  /// VERSIONS
  '''CREATE TABLE versions(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, downloaded DATETIME, major INTEGER, 
  minor INTEGER, patch INTEGER, status INTEGER )''',

  /// CONTACT
  '''CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT,
           stand_id INTEGER, forename TEXT, surname TEXT, position TEXT, 
           email TEXT, phone TEXT, ratings TEXT, contact TEXT, 
           feedback TEXT)''',

  /// SHOW
  '''CREATE TABLE shows(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, location TEXT, date DATETIME)''',

  /// STANDS
  '''CREATE TABLE stands(id INTEGER PRIMARY KEY AUTOINCREMENT, 
          show_id INTEGER, stand TEXT, name TEXT, seen INTEGER, 
          comments TEXT, action TEXT, interviewer TEXT)''',
];

/// User Api endpoints:
///
// const urlBase = 'http://192.168.1.5:5001/';
// const urlBase = 'http://172.23.16.1:5001/'; //'http://10.101.1.216:5001/';

// const urlBase = 'http://192.168.1.109:5001/';
// const urlBase = 'https://drives.motatek.com/';

const String urlDocs = 'http://127.0.0.1:1313/docs/'; // <- localhost
const String urlDrive = '${urlBase}v1/drive';
const String urlDriveImages = '${urlBase}v1/drive/images';
const String urlDriveRating = '${urlBase}v1/drive_rating';
const String urlGoodRoad = '${urlBase}v1/good_road';
const String urlGroup = '${urlBase}v1/group';
const String urlGroupDrive = '${urlBase}v1/group_drive';
const String urlGroupDriveInvitation = '${urlBase}v1/group_drive_invitation';
const String urlGroupMember = '${urlBase}v1/group_member';
const String urlHomeItem = '${urlBase}v1/home_item';
const String urlShopItem = '${urlBase}v1/shop_item';
const String urlIntroduced = '${urlBase}v1/introduced';
const String urlManeuver = '${urlBase}v1/maneuver';
const String urlTextToSpeech = '${urlBase}v1/text_to_speech';
// const String urlTextToSpeech = 'https://motatek.com/mailer/send/';
const String urlMessage = '${urlBase}v1/message';
const String urlPointOfInterest = '${urlBase}v1/point_of_interest';
const String urlPointOfInterestRating = '${urlBase}v1/point_of_interest_rating';
const String urlPolyline = '${urlBase}v1/polyline';
const String urlOsmReview = '${urlBase}v1/osm_review';
const String staticImagesFolder =
    '${urlBase}static/images'; // Now the same on development and production versions
/// const String urlRouter = '${urlBase}router/route/v1/driving/';
const String urlRouter = 'https://drives.motatek.com/router/route/v1/driving/';
const String urlTiler = '${urlBase}v1/tile/style';
const String urlTilerMapLibre = '${urlBase}v1/tile/style/map_libre';
// const String urlTestTiler = '${urlBase}v1/tile/test_style';
const String urlUser = '${urlBase}v1/user';

const Map<String, int> iconMap = {
  "bar": 0xe38c,
  "biergarten": 0xe5e4,
  "pub": 0xe5e4,
  "cafe": 0xe38d,
  "fast_food": 0xe25a,
  "food_court": 0xe25a,
  "ice_cream": 0xe331,
  "restaurant": 0xe532,
  "toilets": 0xe6dc,
  "atm": 0xe0af,
  "fuel": 0xea8e,
  "charging-station": 0xe939,
  "city": 0xe3a8,
  "town": 0xe317,
  "village": 0xe45f,
  "hamlet": 0xe19b
};

const Map<String, String> amenitiesMap = {
  "pubs": "'pub', 'bar', 'biergarten'",
  "restaurants": "'restaurant', 'cafe', 'fast_food', 'ice_cream', 'food_court'",
  "fuel": "'fuel', 'charging_station'",
  "toilets": "'toilets'",
  "atms": "'atm', 'bank'"
};
