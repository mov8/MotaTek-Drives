import 'package:latlong2/latlong.dart';

const apiAddress = 'https://drives.motatek.com/';
const wifiIpAddress = '192.168.1.14:5001';
// const urlBase = wifiIpAddress;
// https://drives.motatek.com/v1/user/test
// const urlBase = 'https://drives.motatek.com/'; // apiAddress;

// const urlRouter = 'http://$wifiIpAddress:5000/route/v1/driving/';
// const urlRouter =  'http://router.project-osrm.org/route/v1/driving/';

//const urlTiler =
//    'https://tiles.stadiamaps.com/styles/osm_bright.json?api_key={key}';
//const mapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';

const mapsApiKey = '';

const double degreeToRadians = 0.0174532925; // degrees to radians pi/180
//  x 4266 y 2984 z 13
// http://192.168.1.9:5000/route/v1/driving/(4266,2984,13).mvt

const List<String> routes = [
  'home',
  'trips',
  'createTrip',
  'myTrips',
  'shop',
  'messages'
];

enum LoginState { notLoggedin, cancel, login, register, edit }

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
  download,
  createTrip,
  myTrips,
  shop,
  messages,
  driveTrip
}

enum TripState {
  none,
  editing,
  loaded,
  manual,
  automatic,
  recording,
  stoppedRecording,
  paused,
  following,
  notFollowing,
  stoppedFollowing,
  startFollowing,
}

enum TripActions {
  none,
  readOnly,
  saving,
  saved,
  headingDetail,
  pointOfInterest,
  showGroup,
  showSteps,
}

enum HighliteActions {
  none,
  greatRoadStarted,
  greatRoadNamed,
  greatRoadEnded,
  routeHighlited
}

enum GroupAction { add, delete, edit, invite, uninvite, update }

// enums HighLightActions TripActions TripState MapHeights

// https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status#informational_responses

const Map<int, String> responseCodes = {
  200: 'OK',
  201: 'created',
  202: 'accepted',
  204: 'no data',
  400: 'request error', //
  401: 'unauthorised', // password failed
  403: 'forbidden', // JWT problem
  408: 'timed out',
  410: 'missing' // User not found
};

RegExp emailRegex = RegExp(r'[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

const List<int> responseOk = [200, 201, 202, 204];
const List<int> responseError = [400, 401, 403, 408, 410];

const int dbVersion = 1;

// String stadiaMapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';

const LatLng ukNorthEast = LatLng(61, 2);
const LatLng ukSouthWest = LatLng(49, -8);

const List<String> tableDefs = [
  /// CACHES

  /// '''CREATE TABLE caches(id INTEGER PRIMARY KEY AUTOINCREMENT, uri TEXT,
  /// feature_id INTEGER, type INTEGER, added DATETIME)''',

  /// DRIVES
  '''CREATE TABLE drives(id INTEGER PRIMARY KEY AUTOINCREMENT, uri TEXT, title TEXT, sub_title TEXT, body TEXT, 
  distance REAL, points_of_interest INTEGER, added DATETIME)''',

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
  name TEXT, description TEXT, images TEXT, sounds TEXT, latitude REAL, longitude REAL)''',

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
  osm_atms INTEGER, osm_historical INTEGER, bottom_nav_index INTEGER, route TEXT, app_state TEXT)''',

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
const urlBase = 'http://10.101.1.216:5001/';

/// const urlBase = 'https://drives.motatek.com/';
const String urlDrive = '${urlBase}v1/drive';
const String urlDriveImages = '${urlBase}v1/drive/images';
const String urlDriveRating = '${urlBase}v1/drive_rating';
const String urlGoodRoad = '${urlBase}v1/good_road';
const String urlGroup = '${urlBase}v1/group';
const String urlGroupDrive = '${urlBase}v1/group_drive';
const String urlGroupDriveInvitation = '${urlBase}v1/group_drive_invitation';
const String urlGroupMember = '${urlBase}v1/group_member';
const String urlHomePageItem = '${urlBase}v1/home_page_item';
const String urlIntroduced = '${urlBase}v1/introduced';
const String urlManeuver = '${urlBase}v1/maneuver';
const String urlMessage = '${urlBase}v1/message';
const String urlPointOfInterest = '${urlBase}v1/point_of_interest';
const String urlPointOfInterestRating = '${urlBase}v1/point_of_interest_rating';
const String urlPolyline = '${urlBase}v1/polyline';
const String urlShopItem = '${urlBase}v1/shop_item';

/// const String urlRouter = '${urlBase}router/route/v1/driving/';
const String urlRouter = 'https://drives.motatek.com/router/route/v1/driving/';
const String urlTiler = '${urlBase}v1/tile/style';
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
