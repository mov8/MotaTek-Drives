// Reading the routing server's reply - a real one, saved in
// test/fixtures/router_staines_egham_windsor.json (Staines -> The Glanty,
// Egham -> Windsor, 2 legs).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/helpers/create_trip_helpers.dart';
import 'package:drives/models/other_models.dart';

void main() {
  late Map<String, dynamic> reply;

  setUpAll(() {
    reply = jsonDecode(File('test/fixtures/router_staines_egham_windsor.json')
        .readAsStringSync());
  });

  test('the route line has every point the router sent', () {
    RouterData data = RouterData.fromGeoJson(geoJson: reply);
    expect(data.routes, hasLength(1));
    expect(data.routes.first.lines, hasLength(474));
    expect(data.routes.first.lines.first, [-0.51689, 51.435996]);
  });

  test('the turn instructions start with depart, from Church Street', () {
    List<Maneuver> maneuvers = getManeuversFromJson(routes: reply['routes']);
    expect(maneuvers.first.type, 'depart');
    expect(maneuvers.first.roadFrom, 'Church Street');
    // turns between the waypoints are kept
    expect(maneuvers.where((m) => m.type == 'turn'), isNotEmpty);
  });

  test('distance and duration come from the router', () {
    RouterData data = RouterData.fromGeoJson(geoJson: reply);
    expect(data.duration, closeTo(930.4, 0.1)); // seconds
    expect(data.distance, greaterThan(0));
  });
}
