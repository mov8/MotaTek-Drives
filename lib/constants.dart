import 'package:latlong2/latlong.dart';

const wifiIpAddress = '192.168.68.119';
const urlBase = 'http://$wifiIpAddress:5001/';
const urlBaseTest = '${urlBase}v1/user/test';
const urlRouter =
    'http://$wifiIpAddress:5000/route/v1/driving/'; //$waypoints?steps=true&annotations=true&geometries=geojson&overview=full$avoid'

const urlTiler = 'http://192.168.68.126:5000/tile/v1/driving/';
const urlRouterTest = '$urlRouter-0.1257,51.5085;0.0756,51.5128?overview=false';

const String stadiaMapsApiKey = 'ea533710-31bd-4144-b31b-5cc0578c74d7';
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
  '''CREATE TABLE followers(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, forename TEXT, 
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

  /// POINTS_OF_INTEREST
  '''CREATE TABLE points_of_interest(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, type INTEGER, 
  name TEXT, description TEXT, images TEXT, latitude REAL, longitude REAL)''',

  /// POLYLINES
  '''CREATE TABLE polylines(id INTEGER PRIMARY KEY AUTOINCREMENT, drive_id INTEGER, 
  type INTEGER, point_of_interest_id INTEGER, points TEXT, colour Integer, stroke INTEGER)''',

  /// SETUP
  '''CREATE TABLE setup(id INTEGER PRIMARY KEY AUTOINCREMENT, route_colour INTEGER, good_route_colour INTEGER, 
  waypoint_colour INTEGER, waypoint_colour_2 INTEGER, point_of_interest_colour INTEGER, rotate_map INTEGER, 
  point_of_interest_colour_2 INTEGER, selected_colour INTEGER, highlighted_colour INTEGER, published_trip_colour INTEGER, 
  record_detail INTEGER, allow_notifications INTEGER, jwt TEXT, dark INTEGER, avoid_motorways INTEGER, 
  avoid_a_roads INTEGER, avoid_b_roads INTEGER, avoid_toll_roads INTEGER, avoid_ferries INTEGER, 
  bottom_nav_index INTEGER, route TEXT)''',

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

const String urlDrive = '${urlBase}v1/drive';
const String urlDriveImages = '${urlBase}v1/drive/images';
const String urlDriveRating = '${urlBase}v1/drive_rating';
const String urlGoodRoad = '${urlBase}v1/good_road';
const String urlGroup = '${urlBase}v1/group';
const String urlGroupDrive = '${urlBase}v1/group_drive';
const String urlGroupDriveInvitation = '${urlBase}v1/group_drive_invitation';
const String urlGroupMember = '${urlBase}v1/group_member';
const String urlHomePageItem = '${urlBase}v1/home_page_item';
const String urlIntroduced = '${urlBase}v1/introduced/get';
const String urlManeuver = '${urlBase}v1/maneuver';
const String urlMessage = '${urlBase}v1/message';
const String urlPointOfInterest = '${urlBase}v1/point_of_interest';
const String urlPointOfInterestRating = '${urlBase}v1/point_of_interest_rating';
const String urlPolyline = '${urlBase}v1/polyline';
const String urlShopItem = '${urlBase}v1/shop_item';
const String urlUser = '${urlBase}v1/user';
