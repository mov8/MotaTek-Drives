import 'dart:convert';
import '../helpers/helpers.dart';
import '/classes/classes.dart';
import '/models/models.dart';

// Points formatted for MapLibre [[lng, lat], [lng, lat], ...]
class Route {
  final int id; // SqLite id
  final String uri; // api uri
  List<List<double>> lines;
  List<List<double>> shields;
  List<Waypoint> waypoints;
  String colour;
  String pointOfInterestUri;

  /// A great road CurrentTripItem.syncGoodRoads() built from the route's
  /// waypoints flagged isGoodRoad - replaced whenever the route changes.
  /// Not saved: a loaded trip's great roads are recognised as on its route.
  bool fromRoute = false;
  Route(
      {this.id = -1,
      this.uri = '',
      List<List<double>>? lines,
      List<List<double>>? shields,
      List<Waypoint>? waypoints,
      String? colour,
      String? pointOfInterestUri})
      : lines = lines ?? [],
        shields = shields ?? [],
        waypoints = waypoints ?? [],
        colour = colour ?? Setup().routeColourHex(),
        pointOfInterestUri = pointOfInterestUri ?? '';

  factory Route.fromMap({required Map<String, dynamic> map}) {
    List<Waypoint> waypoints = [];
    for (int i = 0; i < (map["waypoints"] ?? []).length; i++) {
      waypoints.add(Waypoint.fromMap(map: map["waypoints"][i]));
    }
    return Route(
        id: map["id"] ?? -1,
        uri: map["uri"] ?? "",
        lines: dynamicToDouble(dynamicList: jsonDecode(map['lines'] ?? [[]])),
        shields:
            dynamicToDouble(dynamicList: jsonDecode(map['shields'] ?? [[]])),
        waypoints: waypoints,
        pointOfInterestUri: map['point_of_interest_uri'] ?? '');
  }

  factory Route.fromGeoJson(
      {required Map<String, dynamic> geoJsonMap, List<Waypoint>? waypoints}) {
    waypoints ??= <Waypoint>[];
    return Route(
        lines:
            dynamicToDouble(dynamicList: geoJsonMap['geometry']['coordinates']),
        waypoints: waypoints);
  }

  /// Method to set the points from a string
  set pointsFromString(string) => lines = json.decode(string);

  /// Method to get points as String
  String get stringFromPoints => json.encode(lines);

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "uri": uri.isNotEmpty ? uri : getUuid(),
      "lines": json.encode(lines),
      "shields": jsonEncode(shields),
      "waypoints": jsonFromWaypoints(waypoints: waypoints),
      // a great road's description - it was lost when a trip was saved,
      // and the API couldn't link a published great road to it
      "point_of_interest_uri": pointOfInterestUri,
    };
  }
}

List<Route> routesFromJson({required List<dynamic> jsonList}) {
  List<Route> routes = [];
  for (int i = 0; i < jsonList.length; i++) {
    routes.add(Route.fromMap(map: jsonList[i]));
  }
  return routes;
}

List<Map<String, dynamic>> jsonFromRoutes({required List<Route> routes}) {
  return [for (Route route in routes) route.toMap()];
}

List<Map<String, dynamic>> jsonFromWaypoints(
    {required List<Waypoint> waypoints}) {
  return [for (int i = 0; i < waypoints.length; i++) waypoints[i].toMap()];
}
