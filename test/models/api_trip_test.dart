// Tests for turning the API's JSON into the app's objects.
//
// How a test file works:
//   main() holds the tests. group() collects related tests under a name,
//   test() is one test: it runs some code and expect()s things about the
//   result. expect(actual, expected) passes if they match - otherwise the
//   test fails and reports both values.
//
// Run them all with:   flutter test
// or just this file:   flutter test test/models/api_trip_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/other_models.dart';

void main() {
  // A real trip from the API (GET drive/<uri>), saved as test data - a
  // "fixture" - so the tests always see the same input
  late Map<String, dynamic> json;

  // setUpAll runs once, before the tests in this file
  setUpAll(() {
    json = jsonDecode(
        File('test/fixtures/staines_to_windsor.json').readAsStringSync());
  });

  group('MyTripItem.fromApiJson', () {
    test('reads the trip details', () {
      MyTripItem trip = MyTripItem.fromApiJson(json);

      expect(trip.uri, '019e464397e67722a1ea25e8c1973706');
      expect(trip.title, 'Staines To Windsor'); // the API's has a space after
      expect(trip.subTitle, 'Riverside trip');
      expect(trip.author, 'James Seddon');
      expect(trip.distance, closeTo(8.71, 0.01)); // doubles: allow a margin
      expect(trip.published, isTrue);
    });

    test('decodes the route - GeoJSON sent as a string', () {
      MyTripItem trip = MyTripItem.fromApiJson(json);

      expect(trip.routes, hasLength(1));
      expect(trip.routes.first.lines, hasLength(443));
      // [longitude, latitude], as the map wants them
      expect(trip.routes.first.lines.first, [-0.51689, 51.435996]);
    });

    test('reads the turn-by-turn instructions', () {
      MyTripItem trip = MyTripItem.fromApiJson(json);

      expect(trip.maneuvers, hasLength(21));
      Maneuver first = trip.maneuvers.first;
      expect(first.type, 'depart');
      expect(first.roadFrom, 'Church Street');
      expect(first.roadTo, 'Bridge Street');
      expect(first.point.x, -0.51689); // the point is GeoJSON too
      expect(first.point.y, 51.435996);
    });

    test('reads the points of interest, with their types', () {
      MyTripItem trip = MyTripItem.fromApiJson(json);

      // 17 is the start, 18 the end, 15 a new point of interest
      expect(trip.pointsOfInterest.map((p) => p.type), [17, 18, 15]);
    });

    test('copes with a trip that has no good roads (null in the JSON)', () {
      // The API sends "good_roads": null for this trip
      expect(json['good_roads'], isNull);
      expect(MyTripItem.fromApiJson(json).goodRoads, isEmpty);
    });

    test('copes with an empty map rather than throwing', () {
      MyTripItem trip = MyTripItem.fromApiJson({});
      expect(trip.title, '');
      expect(trip.routes, isEmpty);
      expect(trip.maneuvers, isEmpty);
    });
  });

  group('Follower.fromParticipantMap', () {
    // One participant as the API sends them (group_drive_invitation/<id>/2)
    Map<String, dynamic> participant() => {
          'invitation_id': 'abc',
          'group_drive_id': 'gd1',
          'drive_name': 'Staines To Windsor',
          'user_forename': 'Dai',
          'user_surname': 'Llewellin',
          'user_email': 'dai@example.com',
          'user_phone': '0123',
          'accepted': '2', // the API sends numbers as strings here
          'manufacturer': 'MG',
          'model': 'MGB GT',
          'colour': 'red',
          'registration': 'DAI 1',
          'lat': 51.43,
          'lng': -0.51,
        };

    test('maps the API names onto the follower', () {
      Follower f = Follower.fromParticipantMap(map: participant());
      expect(f.forename, 'Dai');
      expect(f.email, 'dai@example.com');
      expect(f.carColour, 'red');
      expect(f.registration, 'DAI 1');
      expect(f.accepted, 2);
      expect(f.position, [-0.51, 51.43]); // [longitude, latitude]
    });

    test('no position yet (null) is [0, 0], which the map skips', () {
      Map<String, dynamic> map = participant()
        ..['lat'] = null
        ..['lng'] = null;
      expect(Follower.fromParticipantMap(map: map).position, [0, 0]);
    });
  });

  group('a great road keeps its description', () {
    // A great road is a Route whose pointOfInterestUri links it to its
    // description. toMap() didn't save it, so a reloaded trip lost the link
    // and the API couldn't connect a published great road to it.
    test('saved and loaded again (toMap / fromMap)', () {
      Route road = Route(
          uri: 'r1', lines: [[-0.5, 51.4], [-0.6, 51.5]], pointOfInterestUri: 'poi9');
      Route again = Route.fromMap(map: road.toMap());
      expect(again.pointOfInterestUri, 'poi9');
      expect(again.lines, road.lines);
    });

    test('loaded from the API', () {
      MyTripItem trip = MyTripItem.fromApiJson({
        'good_roads': [
          {
            'uri': 'g1',
            'lines': '{"type": "LineString", "coordinates": [[-0.5, 51.4], [-0.6, 51.5]]}',
            'point_of_interest_uri': 'poi9',
          }
        ]
      });
      expect(trip.goodRoads.single.pointOfInterestUri, 'poi9');
    });
  });

  group('TripSummary.fromMap', () {
    test('reads the admin list (drive/summaries), score as a double', () {
      TripSummary s = TripSummary.fromMap(map: {
        'uri': 'x',
        'title': 'Test5',
        'sub_title': 'Test',
        'author': 'James Seddon',
        'score': 5, // an int in the JSON
        'scored': 0,
      });
      expect(s.title, 'Test5');
      expect(s.author, 'James Seddon');
      expect(s.score, 5.0);
    });
  });
}
