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

  List<String> order(String style) => [
        for (Map layer in jsonDecode(style)['layers']) layer['id'] as String
      ];

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
