import 'dart:convert';
import 'dart:math';

import 'package:drives/classes/classes.dart';
import 'package:drives/helpers/geojson_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// The map style comes from the server with the points of interest drawn
/// over the waypoint markers - a stop that's also a waypoint (most of AI
/// assist's) hid its marker, so an anchor seemed not to be highlighted.
void main() {
  String style(List<String> ids) => jsonEncode({
        'version': 8,
        'layers': [
          for (String id in ids) {'id': id, 'type': 'symbol'}
        ],
      });

  List<String> order(String style) =>
      [for (Map layer in jsonDecode(style)['layers']) layer['id'] as String];

  test('waypoint markers are drawn over the points of interest', () {
    String fixed = waypointsAbovePointsOfInterest(style([
      'roads',
      'way-marker-layer',
      'good-road-way-marker-layer',
      'point-of-interest-shield-layer',
      'location-icon',
    ]));
    expect(order(fixed), [
      'roads',
      'point-of-interest-shield-layer',
      'way-marker-layer',
      'good-road-way-marker-layer',
      'location-icon',
    ]);
  });

  test("the markers don't hide the points of interest's labels", () {
    String fixed = waypointsAbovePointsOfInterest(
        style(['way-marker-layer', 'point-of-interest-shield-layer']));
    Map marker = (jsonDecode(fixed)['layers'] as List)
        .firstWhere((layer) => layer['id'] == 'way-marker-layer');
    expect(marker['layout'], {
      'icon-ignore-placement': true,
      'text-ignore-placement': true,
      'text-allow-overlap': true,
    });
  });

  test('a style in order stays in order; one without the layers is left alone',
      () {
    List<String> fine = [
      'roads',
      'point-of-interest-shield-layer',
      'way-marker-layer',
    ];
    expect(order(waypointsAbovePointsOfInterest(style(fine))), fine);
    String plain = style(['roads']);
    expect(waypointsAbovePointsOfInterest(plain), plain);
  });

  test("a style that isn't JSON is passed on as it is", () {
    expect(waypointsAbovePointsOfInterest(''), '');
    expect(waypointsAbovePointsOfInterest('not json'), 'not json');
  });

  // Published (testing, 2026-11-05)
  Map<String, dynamic> server() => {
        'version': 8,
        'sources': {
          'motatek_uk': {'type': 'vector'},
          'published-data': {'type': 'geojson'},
        },
        'layers': [
          {'id': 'roads', 'type': 'line', 'source': 'motatek_uk'},
          {
            'id': 'planned_routes_highlighted',
            'type': 'line',
            'source': 'published-data',
            'layout': {'visibility': 'visible'}
          },
          {
            'id': 'published_good_roads',
            'type': 'line',
            'source': 'good-road-data',
            'filter': [
              '==',
              ['get', 'group'],
              'line'
            ],
          },
          {
            'id': 'planned_routes',
            'type': 'line',
            'source': 'route-data',
          },
          {
            'id': 'route-marker-layer',
            'type': 'symbol',
            'source': 'published-data',
            'layout': {
              'text-font': ['Noto Sans Regular']
            },
          },
          {
            'id': 'point-of-interest-shield-layer',
            'type': 'symbol',
            'source': 'point-of-interest-data',
            'minzoom': 8
          },
          {
            'id': 'way-marker-layer',
            'type': 'symbol',
            'source': 'waypoint-data',
            'minzoom': 8
          },
        ],
      };
  Map layer(Map style, String id) =>
      (style['layers'] as List).firstWhere((l) => l['id'] == id);

  test("trips' lines have round ends; the map's own roads are left alone", () {
    Map fixed = jsonDecode(appStyle(jsonEncode(server())));
    expect(layer(fixed, 'planned_routes_highlighted')['layout'],
        {'visibility': 'visible', 'line-cap': 'round', 'line-join': 'round'});
    expect(layer(fixed, 'roads')['layout'], isNull);
  });

  test("a trip's label keeps little space clear, so it isn't pushed off", () {
    Map fixed = jsonDecode(appStyle(jsonEncode(server())));
    expect(layer(fixed, 'route-marker-layer')['layout']['icon-padding'], 4);
    expect(layer(fixed, 'route-marker-layer')['layout']['text-font'],
        ['Noto Sans Regular']);
  });

  test("only a trip's shield is labelled, not its line", () {
    Map fixed = jsonDecode(appStyle(jsonEncode(server())));
    expect(layer(fixed, 'route-marker-layer')['filter'], [
      '==',
      ['get', 'group'],
      'shield'
    ]);
    expect(shieldFilter(['all'])[1], [
      '==',
      ['get', 'group'],
      'shield'
    ]);
  });

  test(
      "an opened published trip has its own source, and its waypoints show "
      "from zoom 10", () {
    Map fixed = jsonDecode(appStyle(jsonEncode(server())));
    expect(fixed['sources'][publishedTripSource]['type'], 'geojson');
    Map waypoints = layer(fixed, publishedTripWaypoints);
    expect(waypoints['source'], publishedTripSource);
    expect(waypoints['minzoom'], 10);
    expect(layer(fixed, publishedTripPointsOfInterest)['source'],
        publishedTripSource);
    // Explore's own layers are untouched
    expect(layer(fixed, 'way-marker-layer')['source'], 'waypoint-data');
    expect(order(jsonEncode(fixed)).indexOf(publishedTripWaypoints),
        greaterThan(order(jsonEncode(fixed)).indexOf('route-marker-layer')));
  });

  test(
      "published great roads have their own source, under the trip being "
      "planned, and named from zoom 10", () {
    Map fixed = jsonDecode(appStyle(jsonEncode(server())));
    expect(fixed['sources'][publishedGreatRoadSource]['type'], 'geojson');
    Map line = layer(fixed, publishedGreatRoads);
    expect(line['source'], publishedGreatRoadSource);
    expect(line['layout']['line-cap'], 'round');
    Map names = layer(fixed, publishedGreatRoadNames);
    expect(names['minzoom'], 10);
    expect(names['layout']['text-font'], ['Noto Sans Regular']);
    List<String> ids = order(jsonEncode(fixed));
    expect(ids.indexOf(publishedGreatRoads),
        lessThan(ids.indexOf('planned_routes')));
    // the trip's own great roads keep theirs
    expect(layer(fixed, 'published_good_roads')['source'], 'good-road-data');
  });

  test("a published trip's waypoints are numbered; a revisit has no marker",
      () {
    MyTripItem trip = MyTripItem(title: 't', subTitle: '')
      ..routes = [
        Route(waypoints: [
          Waypoint(point: const Point(0, 0)),
          Waypoint(point: const Point(1, 0)),
          Waypoint(point: const Point(0, 0), revisit: true),
        ])
      ];
    List features = publishedTripToGeoJson(trip)['features'];
    expect([for (Map f in features) f['properties']['number']], [1, 2]);
  });

  // The Status Bar names waypoints by the numbers on their markers
  test("a revisit has the number of the waypoint it goes back to", () {
    List<Waypoint> round = [
      Waypoint(point: const Point(0, 0)),
      Waypoint(point: const Point(1, 0)),
      Waypoint(point: const Point(1, 1)),
      Waypoint(point: const Point(0, 0), revisit: true), // back to the start
    ];
    expect([for (int i = 0; i < 4; i++) markerNumber(round, i)], [1, 2, 3, 1]);
    expect(markerNumber(round, 9), 0);
  });
}
