import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;
import '../classes/classes.dart';
import '../models/models.dart';
import '../constants.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// saveMyTrip saves a complete trip locally
/// All lists should be stored in SQLite as strings using jsonEncode()
///
/// {'uri': '0203023..', 'title': 'Drive name', 'sub_title': 'Drive sub_title',
/// 'body': 'Drive description', 'added': '01/01/2006', 'score': 5,
/// 'scored': 0, 'distance': 125, 'downloads': 0, 'author_uri': '',
/// 'author': 'James Seddon',
/// 'ne': [-0.765, 51.9879], 'sw':[-0.765, 51.9879],
/// 'routes':[
///   {'uri': '98018...',
///     'lines': {'type': 'LineString', 'coordinates':[[-0.765, 51.9879], [-0.7654, 519978], ...]},
///     'shields': {'type': 'MultiPoint', 'coordinates': [[-0.765, 51.9879], [-0.7654, 519978], ...]}},
///   ],
/// 'good_roads':[
///   {'uri': '98018...', 'point_of_interest_id': '98018...', 'ne': [-0.765, 51.9879], 'sw':[-0.765, 51.9879],
///     'lines': {'type': 'LineString', 'coordinates':[[-0.765, 51.9879], [-0.7654, 519978], ...]},
///     'shields': {'type': 'MultiPoint', 'coordinates': [[-0.765, 51.9879], [-0.7654, 519978], ...]}},
///   ],
/// 'maneuvers':[
///   {'uri': '98018...',
///     'road_from': 'jkhk', 'road_to': 'hkkkjh', 'bearing_before': 45,
///     'bearing_after': 67, 'point': {'type': 'Point', 'coordinates': [-0.5454, 54.3]},
///     'modifier': 'left', 'type': 'roundabout',
///     'distance': 12.6,
///     'point': }, {...}
///  ],
/// 'points_of_interest':[
///   {'uri': '98018...', 'type': 12, 'name': 'start', 'description': 'hgjghj',
///   'images': [], 'point': {'type': 'Point', 'coordinates': [-0.65, 51.23]},
///   'score': 5, 'scored': 0, 'comment': ' '}, {...}
///   ]
/// }

/// GeoJSON considerations:
/// Each source should be tied to a single FeatureCollection so that only the data that has
/// been changed is updated on the map
/// All api data changes on zoom and bounding box
/// Waypoints can change when a waypoint is highlighted without changing user-route
/// User-routes
/// Driving data - driven route and followers
///
///   Data                  Source                    Flutter geoJSON List      Flutter data        Drives route
///   ====                  ======                    ====================      =============       ============
///   api-routes            route-data                routeDataGEOJSON          routes              Great Drives
///   api-goodRoads         route-data                routeDataGEOJSON          routes              Great Drives / My Trip
///   waypoints             waypoint-data             waypointsGEOJSON          waypoints           My Trip
///   edited-routes         user-data                 userRouteGEOJSON          routes              My Trip
///   edited-goodRoads      goodRoad-data             goodRoadsGEOJSON          goodRoads           My Trip
///   points of interest    point-of-interest-data    pointsOfInterestGEOJSON   pointsOfInterest    My Tri
///
/// Should have two methods for each FeatureCollection
///   1 updateFeatures()
///       Flutter list is cleared
///       Flutter list is generated
///       geoJSON FeatureList is generated
///       MapLibre FeatureList is updated
///   2 addFeature()
///       feature is added to the Flutter List
///       feature geoJSON is regenerated
///       LibreMap is updated with just adding the feature
///

/// fenceFilter() uses MapLibre's setFilter() method to change the filter conditions
/// on a layer. This avoids having to identify all the visible features, and the decide if they
/// should be visible.
/// In this case the objects to be highlighted will be made visible:
/// The route and good road highlight layer, and their associated shields.
/// The geoJson objects have to have a min_lat min_lon etc that is calculated by
/// Mariadb.

List fenceFilter({required LatLngBounds bounds, proportion = 0.6}) {
  double height = bounds.northeast.latitude - bounds.southwest.latitude;
  double width = bounds.northeast.longitude - bounds.southwest.longitude;

  double lngGap = (width - (width * proportion));
  double latGap = (height - (height * proportion));

  LatLng ne = LatLng(
      bounds.northeast.latitude - latGap, bounds.northeast.longitude - lngGap);
  LatLng sw = LatLng(
      bounds.southwest.latitude + latGap, bounds.southwest.longitude + lngGap);

  var filter = [
    "all", // <- all conditions must be met so NOT "any"
    // Object's sw corner must be further south and west than the fence's ne corner
    [
      "<=",
      ["get", "min_lat"], // <- object sw.lat
      ne.latitude
    ],
    [
      "<=",
      ["get", "min_lon"], // <- object sw.lng
      ne.longitude
    ],
    // Object's ne corner must be further north and east than the fence's sw corner
    [
      ">=",
      ["get", "max_lat"], // <- object ne.lat
      sw.latitude
    ],
    [
      ">=",
      ["get", "max_lon"], // <- object ne.lng
      sw.longitude
    ]
  ];
  return filter;
}

/// stateFilter() is to allow features to be hidden if the TripState is inappropriate
/// The geoJson has 4 possible state properties that matches a TripState.name where
/// the filtered item should be exposed.

List tripStateFilter({TripState tripState = TripState.none}) {
  List filter = [
    "any", // <- any conditions must be met so NOT "all"
    [
      "==",
      ["get", "trip-state-1"], // <- option 1
      tripState.name
    ],
    [
      "==",
      ["get", "trip-state-2"], // <- option 2
      tripState.name
    ],
    [
      "==",
      ["get", "trip-state-3"], // <- option 3
      tripState.name
    ],
    [
      "==",
      ["get", "trip-state-4"], // <- option 4 - a saved trip, e.g. from My Trips
      tripState.name
    ]
  ];
  return filter;
}

/// The trip labels on Published: one per trip, at its start - the shield
/// features only. Without the group test MapLibre labelled the route's line
/// too, at its start, with an empty label ("miles long downloads").
List shieldFilter(List fence) => [
      "all",
      [
        "==",
        ["get", "group"],
        "shield"
      ],
      fence,
    ];

/// The sources the app fills - the trips, their waypoints and points of
/// interest - as against the map's own (motatek_uk)
const List<String> appSources = [
  'published-data',
  'route-data',
  'good-road-data',
  'user-data',
  'streamed-data',
  'waypoint-data',
  'good-road-waypoint-data',
  'point-of-interest-data',
];

/// The source and layers for a trip opened on Published - its waypoints and
/// points of interest - added to the style here, as the style may become the
/// user's own (see waypointsAbovePointsOfInterest())
const String publishedTripSource = 'published-trip-data';
const String publishedTripWaypoints = 'published-trip-waypoints';
const String publishedTripPointsOfInterest =
    'published-trip-points-of-interest';

/// Published: the label of the trip under the crosshair, drawn over any
/// others (see publishedHighlightLayer())
const String publishedHighlightLabel = 'published-highlighted-label';

/// The label layer for the trip under the crosshair on Published: a copy of
/// the trip labels that's always drawn, above them, so where trips start
/// from the same place the one picked out shows (only one label had room).
/// Its filter - none at first - is set as the map moves.
String publishedHighlightLayer(String style) {
  try {
    Map<String, dynamic> parsed = jsonDecode(style);
    List layers = parsed['layers'];
    int at = layers.indexWhere((l) => l['id'] == 'route-marker-layer');
    if (at < 0) return style;
    Map copy = jsonDecode(jsonEncode(layers[at]))
      ..['id'] = publishedHighlightLabel
      ..['filter'] = [
        "==",
        ["get", "group"],
        "none"
      ];
    copy['layout'] = {
      ...?copy['layout'],
      'icon-allow-overlap': true,
      'text-allow-overlap': true,
      'icon-padding': 0,
    };
    layers.insert(at + 1, copy);
    return jsonEncode(parsed);
  } catch (_) {
    return style;
  }
}

/// The trips' labels on Published, all but [highlighted]'s - and the
/// filters for the highlighted trips' label and their routes' glow
List publishedLabelsFilter(List<String> highlighted) => [
      "all",
      [
        "==",
        ["get", "group"],
        "shield"
      ],
      [
        "!",
        [
          "in",
          ["get", "uri"],
          ["literal", highlighted]
        ]
      ],
    ];

List publishedHighlightFilter(List<String> highlighted, String group) => [
      "all",
      [
        "==",
        ["get", "group"],
        group
      ],
      [
        "in",
        ["get", "uri"],
        ["literal", highlighted]
      ],
    ];

/// The great roads in published trips, on Explore - their source and layers
/// (see publishedGreatRoadLayers())
const String publishedGreatRoadSource = 'published-great-road-data';
const String publishedGreatRoads = 'published-great-roads';
const String publishedGreatRoadNames = 'published-great-road-names';

/// The map style as the app needs it, from the server's - see each change:
/// waypointsAbovePointsOfInterest(), routeLayers(), publishedTripLayers(),
/// publishedHighlightLayer(), publishedGreatRoadLayers()
String appStyle(String style) =>
    publishedGreatRoadLayers(publishedHighlightLayer(publishedTripLayers(
        routeLayers(waypointsAbovePointsOfInterest(style)))));

/// The great roads others have published, shown on Explore so a trip can be
/// planned along them: a line like the trip's own great roads, a little
/// see-through and under the trip being planned, with the great road's name
/// along it from zoom 10. On a source of their own, as Explore's great road
/// source is the trip's.
String publishedGreatRoadLayers(String style) {
  try {
    Map<String, dynamic> parsed = jsonDecode(style);
    List layers = parsed['layers'];
    Map? greatRoads = layers.firstWhere(
        (l) => l['id'] == 'published_good_roads',
        orElse: () => null);
    if (greatRoads == null) return style;
    Map? labels = layers.firstWhere((l) => l['id'] == 'route-marker-layer',
        orElse: () => null);
    List font = labels?['layout']?['text-font'] ?? ['Noto Sans Regular'];
    parsed['sources'][publishedGreatRoadSource] = {
      'type': 'geojson',
      'data': {'type': 'FeatureCollection', 'features': []},
    };
    Map line = jsonDecode(jsonEncode(greatRoads))
      ..['id'] = publishedGreatRoads
      ..['source'] = publishedGreatRoadSource
      ..['filter'] = [
        "==",
        ["get", "group"],
        "line"
      ];
    line['layout'] = {
      ...?line['layout'],
      'line-cap': 'round',
      'line-join': 'round',
    };
    line['paint'] = {...?line['paint'], 'line-opacity': 0.7};
    Map names = {
      'id': publishedGreatRoadNames,
      'type': 'symbol',
      'source': publishedGreatRoadSource,
      'minzoom': 10,
      'filter': [
        "==",
        ["get", "group"],
        "line"
      ],
      'layout': {
        'symbol-placement': 'line',
        'text-field': ["get", "title"],
        'text-font': font,
        'text-size': 13,
      },
      'paint': {
        'text-color': '#011D33',
        'text-halo-color': '#FFFFFF',
        'text-halo-width': 1.5,
      },
    };
    // Under the trip being planned, which is drawn over them
    int at = layers.indexWhere((l) => l['id'] == 'planned_routes');
    layers.insert(at < 0 ? layers.length : at, line);
    int labelAt = layers.indexWhere((l) => l['id'] == 'route-marker-layer');
    layers.insert(labelAt < 0 ? layers.length : labelAt, names);
    return jsonEncode(parsed);
  } catch (_) {
    return style;
  }
}

/// The trips' lines with round ends and corners - square ends looked odd -
/// and the trip labels only for the trips (shieldFilter()). A trip label
/// keeps only a little space clear round it: it kept 100 pixels, from when a
/// trip had a label every mile, so the trip's own points of interest pushed
/// its one label off the map at some zooms.
String routeLayers(String style) {
  try {
    Map<String, dynamic> parsed = jsonDecode(style);
    for (Map layer in parsed['layers']) {
      if (layer['type'] == 'line' && appSources.contains(layer['source'])) {
        layer['layout'] = {
          ...?layer['layout'],
          'line-cap': 'round',
          'line-join': 'round',
        };
      }
      if (layer['id'] == 'route-marker-layer') {
        layer['filter'] = [
          "==",
          ["get", "group"],
          "shield"
        ];
        layer['layout'] = {...?layer['layout'], 'icon-padding': 4};
      }
    }
    return jsonEncode(parsed);
  } catch (_) {
    return style;
  }
}

/// A published trip's waypoints and points of interest, drawn as Explore
/// draws a trip's - copies of its layers, on a source of their own so
/// Explore's trip is left alone. The waypoints only from zoom 10, where
/// they're far enough apart to read.
String publishedTripLayers(String style) {
  try {
    Map<String, dynamic> parsed = jsonDecode(style);
    List layers = parsed['layers'];
    Map? waypoints = layers.firstWhere((l) => l['id'] == 'way-marker-layer',
        orElse: () => null);
    Map? pointsOfInterest = layers.firstWhere(
        (l) => l['id'] == 'point-of-interest-shield-layer',
        orElse: () => null);
    if (waypoints == null || pointsOfInterest == null) return style;
    parsed['sources'][publishedTripSource] = {
      'type': 'geojson',
      'data': {'type': 'FeatureCollection', 'features': []},
    };
    Map copy(Map layer, String id, String group) =>
        jsonDecode(jsonEncode(layer))
          ..['id'] = id
          ..['source'] = publishedTripSource
          ..['filter'] = [
            "==",
            ["get", "group"],
            group
          ];
    // Above the trip labels, and the waypoints above the points of interest
    int at = layers.indexWhere((l) => l['id'] == 'route-marker-layer') + 1;
    layers.insertAll(at == 0 ? layers.length : at, [
      copy(
          pointsOfInterest, publishedTripPointsOfInterest, 'point_of_interest'),
      copy(waypoints, publishedTripWaypoints, 'waypoint')..['minzoom'] = 10,
    ]);
    return jsonEncode(parsed);
  } catch (_) {
    return style;
  }
}

/// A published trip's waypoints - numbered from the start, revisits sharing
/// the earlier one's marker - and its points of interest, for
/// publishedTripSource
Map<String, dynamic> publishedTripToGeoJson(MyTripItem trip) {
  List<Map<String, dynamic>> features = [];
  String colour = Setup().routeColourHex();
  for (Route route in trip.routes) {
    int number = 0;
    for (Waypoint waypoint in route.waypoints) {
      if (waypoint.revisit) continue;
      number++;
      features.add({
        "type": "Feature",
        "id": 'pwp$number',
        "geometry": {
          "type": "Point",
          "coordinates": [waypoint.point.x, waypoint.point.y]
        },
        "properties": {
          "group": 'waypoint',
          "number": number,
          "color": waypoint.isGoodRoad ? Setup().goodRouteColourHex() : colour,
        }
      });
    }
  }
  features.addAll(
      pointsOfInterestToGeoJson(pointsOfInterest: trip.pointsOfInterest));
  return {"type": "FeatureCollection", "features": features};
}

/// The map style (from the server) with the waypoint markers moved above
/// the points of interest, which hid them - most of AI assist's stops are
/// waypoints too, and a hidden anchor seemed not to be highlighted. The
/// markers also ignore placement, so they don't hide the points of
/// interest's labels in turn. Done in the app, as the style may become the
/// user's own. A style that isn't JSON is returned as it is.
String waypointsAbovePointsOfInterest(String style) {
  const List<String> markers = [
    'way-marker-layer',
    'good-road-way-marker-layer'
  ];
  const String pointsOfInterest = 'point-of-interest-shield-layer';
  try {
    Map<String, dynamic> parsed = jsonDecode(style);
    List layers = parsed['layers'];
    if (!layers.any((layer) => layer['id'] == pointsOfInterest)) return style;
    List moved =
        layers.where((layer) => markers.contains(layer['id'])).toList();
    for (Map layer in moved) {
      layer['layout'] = {
        ...?layer['layout'],
        'icon-ignore-placement': true,
        'text-ignore-placement': true,
        'text-allow-overlap': true,
      };
    }
    layers.removeWhere((layer) => markers.contains(layer['id']));
    layers.insertAll(
        layers.indexWhere((layer) => layer['id'] == pointsOfInterest) + 1,
        moved);
    return jsonEncode(parsed);
  } catch (_) {
    return style;
  }
}

List<Map<String, dynamic>> routesToGeoJson(
    {List<Route>? routes,
    int index = -1,
    String? colour,
    String? indexColour,
    bool? highlighted}) {
  routes ??= CurrentTripItem().routes;
  // A trip AI assist suggested is in the AI colour until it's saved
  colour ??= CurrentTripItem().aiSuggestion &&
          identical(routes, CurrentTripItem().routes)
      ? Setup().aiRouteColourHex()
      : Setup().routeColourHex();
  highlighted ??= false;
  indexColour = indexColour ?? Setup().highlightedColourHex();

  String goodRoadColour = Setup().goodRouteColourHex();
  List<Map<String, dynamic>> features = [];
  if (routes.isNotEmpty) {
    for (int i = 0; i < routes.length; i++) {
      // A LineString needs 2+ points - an invalid one makes MapLibre reject
      // the whole source and keep drawing the previous route
      if (routes[i].lines.length < 2) continue;
      // Great road legs (arriving at waypoints flagged isGoodRoad) are drawn
      // in the great road colour as part of the route
      for (({List<List<double>> lines, bool goodRoad}) segment
          in routeSegments(routes[i])) {
        if (segment.lines.length < 2) continue;
        features.add({
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": segment.lines},
          "id": i,
          "properties": {
            "group": 'route',
            "width": 2,
            "color": i == index
                ? indexColour
                : segment.goodRoad
                    ? goodRoadColour
                    : colour,
          }
        });
      }
    }
  }
  return features;
}

/// Splits a route's line into stretches of ordinary and great road. A
/// waypoint flagged isGoodRoad makes the leg arriving at it great road.
/// Consecutive legs of the same kind are joined.
List<({List<List<double>> lines, bool goodRoad})> routeSegments(Route route) {
  List<Waypoint> waypoints = route.waypoints;
  if (waypoints.length < 2 || !waypoints.any((w) => w.isGoodRoad)) {
    return [(lines: route.lines, goodRoad: false)];
  }
  List<int> indices = waypointLineIndices(route);
  List<({List<List<double>> lines, bool goodRoad})> segments = [];
  int start = 0;
  bool goodRoad = waypoints[1].isGoodRoad;
  for (int k = 2; k < waypoints.length; k++) {
    if (waypoints[k].isGoodRoad != goodRoad) {
      segments.add((
        lines: route.lines.sublist(start, indices[k - 1] + 1),
        goodRoad: goodRoad
      ));
      start = indices[k - 1];
      goodRoad = waypoints[k].isGoodRoad;
    }
  }
  segments.add((lines: route.lines.sublist(start), goodRoad: goodRoad));
  return segments;
}

/// The index in route.lines nearest each waypoint, searching forwards from
/// the previous waypoint. It takes the first pass that comes close (within
/// 30m) rather than the closest overall, so a point visited twice - a
/// revisit, or the crossing of a figure of eight - splits at the right pass.
List<int> waypointLineIndices(Route route) {
  List<int> indices = [];
  int from = 0;
  double metres(Point p, List<double> q) {
    double dx = (q[0] - p.x) * cos(p.y * pi / 180) * 111320;
    double dy = (q[1] - p.y) * 110540;
    return sqrt(dx * dx + dy * dy);
  }

  for (Waypoint waypoint in route.waypoints) {
    int index = from;
    double closest = double.infinity;
    for (int j = from; j < route.lines.length; j++) {
      double distance = metres(waypoint.point, route.lines[j]);
      if (distance < 30) {
        // Follow the pass to its nearest point
        index = j;
        while (index + 1 < route.lines.length &&
            metres(waypoint.point, route.lines[index + 1]) <=
                metres(waypoint.point, route.lines[index])) {
          index++;
        }
        break;
      }
      if (distance < closest) {
        closest = distance;
        index = j;
      }
    }
    indices.add(index);
    from = index;
  }
  return indices;
}

List<Map<String, dynamic>> goodRoadsToGeoJson(
    {List<Route>? routes,
    int index = -1,
    String? colour,
    String? indexColour,
    bool? highlighted}) {
  colour ??= Setup().goodRouteColourHex();
  // The current trip's great roads made from its route are drawn by the
  // route itself (routesToGeoJson()) - only those off the route need drawing
  bool currentTrip = routes == null;
  routes ??= CurrentTripItem().goodRoads;
  highlighted ??= false;
  indexColour = indexColour ?? Setup().highlightedColourHex();
  List<Map<String, dynamic>> features = [];
  if (routes.isNotEmpty) {
    for (int i = 0; i < routes.length; i++) {
      // A LineString needs 2+ points - an invalid one makes MapLibre reject
      // the whole source and keep drawing the previous route
      if (routes[i].lines.length < 2) continue;
      if (currentTrip &&
          (routes[i].fromRoute ||
              (routes[i].waypoints.isNotEmpty &&
                  routes[i]
                      .waypoints
                      .every((w) => routeWaypointNumber(w.point) > 0)))) {
        continue;
      }
      features.add({
        "type": "Feature",
        "geometry": {"type": "LineString", "coordinates": routes[i].lines},
        "id": i,
        "properties": {
          "group": 'route',
          // Wider than the route (planned_routes draws width x2, good_roads_user
          // x1.5) so a great road stretch shows fully in its colour
          "width": 3,
          "highlighted": true,
          "color": i == index ? indexColour : colour,
        }
      });
    }
  }

  return features;
}

List<List<double>> dynamicToDouble({required List<dynamic> dynamicList}) {
  List<List<double>> newList = List<List<double>>.from(
    dynamicList.map(
      (xy) => List<double>.from(
        xy.map(
          (val) => val.toDouble(),
        ),
      ),
    ),
  );
  return newList;
}

/// pointsOfInterestToGeoJSON  returns a list of GeoJson Features

List<Map<String, dynamic>> pointsOfInterestToGeoJson(
    {List<PointOfInterest>? pointsOfInterest,
    String? colour,
    List<int>? exclude,
    rated = 0}) {
  pointsOfInterest ??= CurrentTripItem().pointsOfInterest;
  exclude ??= [12, 14, 17, 18, 19];
  List<Map<String, dynamic>> geoJson = [];
  if (pointsOfInterest.isNotEmpty) {
    try {
      for (int i = 0; i < pointsOfInterest.length; i++) {
        if (!exclude.contains(pointsOfInterest[i].type)) {
          geoJson.add(pointsOfInterest[i].toGeoJson(index: i));
        }
      }
    } catch (e) {
      developer.log('Error pointsOfInterestToGeoJson(): ${e.toString()}',
          name: 'error');
    }
  }
  return geoJson;
}

/// The user's position marker for MapService().showLocation(). bearing is the
/// direction of travel in degrees from north - the location layer rotates the
/// arrow by it.
List<Map<String, dynamic>> locationMarkerToGeoJson(
    {Point? location, double bearing = 0}) {
  location ??= CurrentTripItem().tripValues.position;
  if (location.x == 0 && location.y == 0) {
    return [];
  }
  List<Map<String, dynamic>> features = [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [location.x, location.y],
        "group": "location"
      },
      "id": 1,
      "properties": {
        "group": 'location',
        "bearing": bearing,
        "item_type": "location_icon",
        "color": "#1e88e5"
      }
    },
  ];

  return features;
}

List<Map<String, dynamic>> followersToGeoJson(
    {List<Follower>? followers, Point? location, bool debugging = false}) {
  followers ??= CurrentTripItem().followers;
  location ??= CurrentTripItem().tripValues.position;
  List<Map<String, dynamic>> features = [];

  if (debugging) {
    features.add({
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [location.x, location.y],
        "group": "location"
      },
      "id": 1,
      "properties": {
        "group": 'location',
        "icon": "circle",
        "bearing": 0,
        "item_type": "location_icon",
        "colour": "#1e88e5" //  "#1e88e5"
      }
    });
  }

  if (followers.isNotEmpty) {
    try {
      for (int i = 0; i < followers.length; i++) {
        // Hidden by the participant's track checkbox, or not reported yet
        if (!followers[i].track ||
            (followers[i].position[0] == 0 && followers[i].position[1] == 0)) {
          continue;
        }
        features.add(
          {
            "type": "Feature",
            "geometry": {"type": "Point", "coordinates": followers[i].position},
            "group": "follower",
            "id": i,
            "properties": {
              "group": 'follower',
              "icon": "follower",
              "bearing": 0,
              "item_type": "location_icon",
              "name":
                  ('${followers[i].forename} ${followers[i].surname}').trim(),
              "registration": followers[i].registration,
              "manufacturer": followers[i].manufacturer,
              "model": followers[i].model,
              "phone": followers[i].phoneNumber,
              "colour": colourIntToHex(index: followers[i].iconColour),
            }
          },
        );
      }
    } catch (e) {
      developer.log('Error pointsOfInterestToGeoJson(): ${e.toString()}',
          name: 'error');
    }
  }
  return features;
}

/// The stars for a rating - five empty ones if nobody has rated it yet. The
/// server counts no ratings as five stars, so a trip just published looked
/// top rated.
String unratedStars(dynamic rated, dynamic stars) =>
    (rated ?? 0) == 0 ? toStars(rating: 0) : '${stars ?? toStars(rating: 0)}';

String toStars({double rating = 5}) {
  int rated = rating.toInt();
  return '${'★' * rated}${'☆' * (5 - rated)}';
}

/// The number a waypoint's marker shows - revisits have no marker or number
/// of their own, so a revisit has its earlier waypoint's number
int markerNumber(List<Waypoint> waypoints, int index) {
  if (index < 0 || index >= waypoints.length) return 0;
  if (waypoints[index].revisit) {
    int first = waypoints
        .indexWhere((w) => !w.revisit && w.point == waypoints[index].point);
    if (first > -1) index = first;
  }
  return waypoints.take(index + 1).where((w) => !w.revisit).length;
}

List<Map<String, dynamic>> waypointsToGeoJson(
    {List<Waypoint>? waypoints,
    int index = -1,
    String? colour,
    String? indexColour,
    List? lastPoint}) {
  List<Map<String, dynamic>> features = [];

  try {
    waypoints ??= CurrentTripItem().routes.last.waypoints;
    lastPoint = lastPoint ?? [];
    colour = colour ??
        (CurrentTripItem().aiSuggestion
            ? Setup().aiRouteColourHex()
            : Setup().routeColourHex());
    indexColour = indexColour ?? Setup().highlightedColourHex();
    if (CurrentTripItem().routes.isNotEmpty) {
      for (int h = 0; h < CurrentTripItem().routes.length; h++) {
        waypoints = CurrentTripItem().routes[h].waypoints;
        // Revisits share an earlier waypoint's point and number, so they have
        // no marker and aren't counted. "id" stays the list index so tapping a
        // marker identifies the right waypoint.
        int number = 0;
        for (int i = 0; i < waypoints.length; i++) {
          if (waypoints[i].revisit) continue;
          number++;
          // A highlighted revisit (e.g. the end of a round trip as an
          // anchor) shows on the marker it shares
          Point point = waypoints[i].point;
          bool selected = waypoints.any((w) =>
              (w.selected ?? false) &&
              (identical(w, waypoints![i]) || (w.revisit && w.point == point)));
          features.add({
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": i == waypoints.length - 1 && lastPoint.isNotEmpty
                  ? lastPoint
                  : [waypoints[i].point.x, waypoints[i].point.y]
            },
            "id": i,
            "properties": {
              "group": 'waypoint',
              "trip-state-1": "manual",
              "trip-state-2": "editing",
              "trip-state-3": "goodRoadStart",
              "trip-state-4": "loaded",
              "number": number,
              // Highlights only mean something while editing - stops them
              // lingering after e.g. a save switches to TripState.loaded
              "color":
                  selected && CurrentTripItem().tripState == TripState.editing
                      ? indexColour
                      // Great road waypoints are route waypoints in its colour
                      : waypoints[i].isGoodRoad
                          ? Setup().goodRouteColourHex()
                          : colour,
            }
          });
        }
      }
    }
  } catch (e) {
    developer.log('Error geojson_helpers waypointsToGeoJson() :${e.toString}',
        name: 'error');
  }
  return features;
}

/// To use Waypoints have to ensure the filters _mapController.setFilter()
/// aren't stopping them rendering
///
List<Map<String, dynamic>> routeEndsToGeoJson({
  List<Route>? routes,
  int index = -1,
  String? colour,
}) {
  List<Map<String, dynamic>> features = [];
  colour = colour ?? Setup().routeColourHex();
  try {
    if (routes != null) {
      for (int i = 0; i < 2; i++) {
        features.add({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates":
                i == 0 ? routes.first.lines.first : routes.last.lines.last
          },
          "id": i,
          "properties": {
            "group": 'waypoint',
            "trip-state-1": "manual",
            "trip-state-2": "editing",
            "trip-state-3": "goodRoadStart",
            "trip-state-4": "loaded",
            "number": i + 1,
            "color": colour, //"#673ab7", //colour,
          }
        });
      }
    }
  } catch (e) {
    developer.log('Error geojson_helpers.dart routeEndsToJson(): ${e.toString}',
        name: 'error');
  }
  return features;
}

/// The marker number of the route waypoint at point (revisits aren't
/// counted), or 0 if no route waypoint is there
int routeWaypointNumber(Point point) {
  int number = 0;
  for (Route route in CurrentTripItem().routes) {
    for (Waypoint waypoint in route.waypoints) {
      if (waypoint.revisit) continue;
      number++;
      if (waypoint.point == point) return number;
    }
  }
  return 0;
}

List<Map<String, dynamic>> goodRoadWaypointsToGeoJson(
    {List<Waypoint>? waypoints,
    int index = -1,
    String? colour,
    String? indexColour,
    List? lastPoint}) {
  List<Map<String, dynamic>> features = [];

  try {
    waypoints ??= CurrentTripItem().goodRoads.last.waypoints;
    lastPoint = lastPoint ?? [];
    colour = colour ?? Setup().goodRouteColourHex();
    indexColour = indexColour ?? Setup().highlightedColourHex();
    if (CurrentTripItem().goodRoads.isNotEmpty) {
      for (int h = 0; h < CurrentTripItem().goodRoads.length; h++) {
        waypoints = CurrentTripItem().goodRoads[h].waypoints;
        for (int i = 0; i < waypoints.length; i++) {
          // Great roads made from the route are drawn by the route's own
          // markers (waypointsToGeoJson()) - only those off the route
          // (tracked, or saved before) need markers of their own
          if (routeWaypointNumber(waypoints[i].point) > 0) continue;
          features.add({
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": i == waypoints.length - 1 && lastPoint.isNotEmpty
                  ? lastPoint
                  : [waypoints[i].point.x, waypoints[i].point.y]
            },
            "id": i,
            "properties": {
              "group": 'good_road_waypoint',
              "item_type": "good_road",
              "trip-state-1": "manual",
              "trip-state-2": "editing",
              "trip-state-3": "goodRoadStart",
              "trip-state-4": "loaded",
              "number": i + 1,
              "color": i == index ? indexColour : colour,
            }
          });
        }
      }
    }
  } catch (e) {
    developer.log(
        'Error geojsonhelpers.dart goodRoadWayointsToGeoJson: ${e.toString}',
        name: 'error');
  }
  return features;
}

Point latLngToPoint({required LatLng latLng}) {
  return Point(latLng.longitude, latLng.latitude);
}
