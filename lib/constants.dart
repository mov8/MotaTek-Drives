import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'models/models.dart';
import 'screens/screens.dart';
import 'classes/classes.dart';

const appVersion = {'major': 0, 'minor': 0, 'patch': 9, 'suffix': 'beta db'};

const apiAddress = 'https://drives.motatek.com/';
// const wifiIpAddress = 'http://192.168.1.216:5001/';  // <- Home extendor
const wifiIpAddress = 'http://192.168.1.168:5001/'; // <- Home fibre
// const wifiIpAddress = 'http://192.168.235.1:5001/'; // <- Home no internet
// Use the Ethernet adapter VMware Network Adapter VMnet1 IP address at home because of router problems

// const wifiIpAddress = "http://10.0.2.2:5001"; //  <- Android emulator
// const wifiIpAddress = "http://10.2.222.7:5001";
// const wifiIpAddress = 'http://10.164.124.105:5001/'; // < Redmi
// const wifiIpAddress = 'http://192.168.1.111:5001/'; // <- Boston unit
// const wifiIpAddress = 'http://192.168.68.122:5001/'; // <- Barnet
// const wifiIpAddress = 'http://192.168.1.211:5001/'; // <- Irby Street
// const wifiIpAddress = 'http://192.168.68.112:5001/'; // <- DiasF
// const wifiIpAddress = 'http://10.249.4.160:5001/'; // <- airport joburg
// const wifiIpAddress ='http://10.2.222.57:5001/'; // <- Staines library 10.2.222.57:5001
// https://drives.motatek.com/v1/user/test

// A build can choose another API, e.g. a test server:
//   --dart-define=DRIVES_API=http://192.168.1.168:5002/
const urlBase =
    String.fromEnvironment('DRIVES_API', defaultValue: wifiIpAddress);

const mapsApiKey = '';

const String motatekId = 'f9440cb2e8c747c2811bc80ef5653ce6';

const double degreeToRadians = 0.0174532925; // degrees to radians pi/180

const organisationName = 'MotaTek';

const List routes = [
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

enum WaypointState {
  none,
  twoPlus,
  extendStart,
  extendEnd,
  insert,
  revisit,
  remove
}

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
  editing,
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
  11111111 & 10011001 -> 10011001   returns 1 where both are 1      binary and
  11111111 | 10011001 -> 11111111   returns 1 where either are 1    binary or
  11111111 ^ 10011001 -> 01100110   returns 1 where only one is 1   binary xor
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

enum Warning { none, tripSaved, tripDownloaded }

// A getter, so each message has the trip's title as it is now - as a list
// it was made once, keeping the first trip's title
List<Map<String, dynamic>> get warnings => [
  {
    'message':
        "Your trip ${CurrentTripItem().title} has been saved ${kIsWeb ? 'in your browser' : 'on your device'} in Favourites.",
    'color': Colors.white,
    'iconData': Icons.library_add_check_rounded,
    'iconSize': 40,
  },
  {
    'message':
        "Published trip ${CurrentTripItem().title} has been downloaded OK for you to edit, follow or save ${kIsWeb ? 'in your browser' : 'on your device'}.",
    'color': Colors.white,
    'iconData': Icons.library_add_check_rounded,
    'iconSize': 40,
  }
];

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
  'streamed-data' // <-- the group drive's other cars (MapUpdates.followers)
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
    return _atLeast(added.value | value);
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

  /// Not every combination of bits has an enum value - e.g. waypoints (4) +
  /// pointsOfInterest (16) = 20. _fromValue() returns none for those, which
  /// silently skips the update. _atLeast() returns the exact value, or the
  /// smallest one that includes all the bits - redrawing an extra source is
  /// harmless.
  static MapUpdates _atLeast(int value) {
    MapUpdates best = MapUpdates.updatingAll;
    for (MapUpdates mapUpdate in MapUpdates.values) {
      if (mapUpdate.value & value == value && mapUpdate.value < best.value) {
        best = mapUpdate;
      }
    }
    return best;
  }

  static MapUpdates _fromValue(int value) {
    return MapUpdates.values
        .firstWhere((e) => e.value == (value), orElse: () => MapUpdates.none);
  }
}

enum GroupMemberState { none, isNew, registered, incomplete, complete, added }

enum GroupAction { add, delete, uninvite, update, leave }

// enums HighLightActions TripActions TripState MapHeights
// https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status#informational_responses

const List<String> settlementTypes = ['city', 'town', 'village', 'hamlet'];
DateFormat dateFormat = DateFormat('dd/MM/yy');
DateFormat dateFormatSQL = DateFormat('yyyy-MM-dd HH:mm:ss');
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
  messages, // <-- the Messages page's conversations (web)
  tripMessages, // <-- a group drive's messages
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
  login,
  transfer, // <-- synchronising a trip with a phone
  markdown, // <-- Markdown editor
  markdownHome, // <-- Markdown summary tile
  markdownShop, // <-- Markdown summary tile
  deleteTrips, // <-- admin: remove published trips (web)
  deleteUser, // <-- admin: stop a user using Drives (web)
  cached,
  planner, // <-- AI assist: the request and the suggested trip
  tripDetails, // <-- AI assist: naming and describing the trip, to save it
  clubs, // <-- My clubs: invitations, my clubs, finding one, running one
  console, // <-- staff: the control panel - clubs, payments, AI, usage
  feedback, // <-- Send feedback: a problem, an idea or a question
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
    'key': 'clubs',
    'text': 'My clubs',
    'iconData': Icon(Icons.diversity_3_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.clubs,
    'screen': ClubsForm(),
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
    'text': 'Edit Home page',
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
    'text': 'Edit Shop page',
    'iconData': Icon(Icons.shopping_bag_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.markdownShop,
    'screen': MarkdownForm(
      markdownData: {},
      dataType: 'shop',
    ) //Shop()
  },
  {
    'key': 'feedback',
    'text': 'Send feedback',
    'iconData': Icon(Icons.feedback_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.feedback,
    'screen': FeedbackForm(),
  },
  {
    'key': 'console',
    'text': 'Control panel',
    'iconData': Icon(Icons.admin_panel_settings_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.console,
    'screen': ConsoleForm(),
  },
  {
    'key': 'deleteTrips',
    'text': 'Remove trips',
    'iconData': Icon(Icons.delete_sweep_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.deleteTrips,
    'screen': DeleteTripsForm(),
  },
  {
    'key': 'deleteUser',
    'text': 'Remove user',
    'iconData': Icon(Icons.person_off_outlined, size: 30),
    'method': BottomDrawerItems.settings.index,
    'drawer': BottomDrawerItems.deleteUser,
    'screen': DeleteUserForm(),
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

const LatLng ukNorthEast = LatLng(61, 2);
const LatLng ukSouthWest = LatLng(49, -8);

const double metersToMiles = 0.000621371192;
const double metersPerSecondToMPH = 3.6 / 8 * 5;
const double metersPerSecondToKmPH = 3.6;
const double metersToYards = 1.0936133;
const double metersPerMile = 1609.344;
const double metersPerTenths = 160.934;
const double yardsToMeters = 0.9144;
const double yardsPerMile = 1760;
const double yardsToMiles = 0.000568182;

/// User Api endpoints:
///
// const urlBase = 'http://192.168.1.5:5001/';
// const urlBase = 'http://172.23.16.1:5001/'; //'http://10.101.1.216:5001/';

// const urlBase = 'http://192.168.1.109:5001/';
// const urlBase = 'https://drives.motatek.com/';

// The documentation (the Hugo site's docs pages) - the ? on each main page
// opens its page here
const String urlDocs = 'https://motatek.com/docs/';
const String urlClub = '${urlBase}v1/club';
const String urlConsole = '${urlBase}v1/console';
// Signing up for AI assist - on the website, where payments are taken.
// Parked (empty) until the website is ready: setting it turns on the
// invitation after registering and AI assist's Find out more.
const String urlSubscribe = '';
const String urlDrive = '${urlBase}v1/drive';
const String urlDriveImages = '${urlBase}v1/drive/images';
const String urlDriveRating = '${urlBase}v1/drive_rating';
const String urlGroup = '${urlBase}v1/group';
const String urlGroupDrive = '${urlBase}v1/group_drive';
const String urlGroupDriveInvitation = '${urlBase}v1/group_drive_invitation';
const String urlHomeItem = '${urlBase}v1/home_item';
const String urlShopItem = '${urlBase}v1/shop_item';
const String urlIntroduced = '${urlBase}v1/introduced';
const String urlTextToSpeech = '${urlBase}v1/text_to_speech';
// const String urlTextToSpeech = 'https://motatek.com/mailer/send/';
const String urlMessage = '${urlBase}v1/message';
const String urlPointOfInterest = '${urlBase}v1/point_of_interest';
const String urlPlanner = '${urlBase}v1/planner';
const String urlPush = '${urlBase}v1/push';
const String urlPointOfInterestRating = '${urlBase}v1/point_of_interest_rating';
const String urlOsmReview = '${urlBase}v1/osm_review';
const String staticImagesFolder =
    '${urlBase}static/images'; // Now the same on development and production versions
/// const String urlRouter = '${urlBase}router/route/v1/driving/';
const String urlRouter = 'https://drives.motatek.com/router/route/v1/driving/';
const String urlTiler = 'https://drives.motatek.com/router/route/v1/tile/style';
const String urlTilerMapLibre =
    'https://drives.motatek.com/v1/tile/style/map_libre'; // <-- Gets the MapLibre Style
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
