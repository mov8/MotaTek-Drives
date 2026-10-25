// Tests for DrivenLog - what following a trip notes for "driven by": the
// turns passed and the stops made, and the summary that's sent.
//
// Run with:   flutter test test/models/driven_log_test.dart

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:drives/classes/classes.dart';

void main() {
  // Points are (longitude, latitude), as in the app. 0.001 of latitude is
  // about 111 metres.
  const Point start = Point(-0.5169, 51.4360);
  const Point turn = Point(-0.5300, 51.4352);
  const Point end = Point(-0.6040, 51.4838);
  const Point runnymede = Point(-0.5600, 51.4400);
  final DateTime nine = DateTime(2026, 10, 25, 9);

  DrivenLog log() => DrivenLog(
        tripUri: 'trip1',
        checkpoints: [start, turn, end],
        pointsOfInterest: {'poi1': runnymede},
      );

  group('turns passed', () {
    test('within 100 metres of a turn, it is passed', () {
      DrivenLog driven = log();
      driven.update(const Point(-0.5169, 51.4365), nine); // about 55 m away
      expect(driven.passed, 1);
    });

    test('further off, it is not', () {
      DrivenLog driven = log();
      driven.update(const Point(-0.5169, 51.4380), nine); // about 220 m away
      expect(driven.passed, 0);
    });

    test('the minutes are from the first position to the last', () {
      DrivenLog driven = log();
      driven.update(start, nine);
      driven.update(turn, nine.add(const Duration(minutes: 4)));
      driven.update(end, nine.add(const Duration(minutes: 25)));
      expect((driven.passed, driven.checkpoints, driven.minutes), (3, 3, 25));
    });
  });

  group('stops', () {
    test('three minutes near a point of interest is a stop', () {
      DrivenLog driven = log();
      driven.update(runnymede, nine);
      driven.update(runnymede, nine.add(const Duration(minutes: 3)));
      expect(driven.stoppedAt, {'poi1'});
    });

    test('driving past is not', () {
      DrivenLog driven = log();
      driven.update(runnymede, nine);
      driven.update(runnymede, nine.add(const Duration(minutes: 1)));
      driven.update(end, nine.add(const Duration(minutes: 2)));
      // back later, briefly - the clock started again when they left
      driven.update(runnymede, nine.add(const Duration(minutes: 10)));
      expect(driven.stoppedAt, isEmpty);
    });
  });

  group('the summary', () {
    test('is only counts and the stops - no positions', () {
      DrivenLog driven = log();
      driven.update(start, nine);
      driven.update(runnymede, nine.add(const Duration(minutes: 5)));
      driven.update(runnymede, nine.add(const Duration(minutes: 9)));
      Map<String, dynamic> summary = driven.summary();
      expect(summary.keys.toSet(),
          {'drive_id', 'checkpoints', 'passed', 'minutes', 'stopped_at'});
      expect(summary['drive_id'], 'trip1');
      expect(summary['stopped_at'], ['poi1']);
      expect(jsonEncode(summary), isNot(contains('51.4')));
    });

    test('nothing passed and no stops - nothing to send', () {
      expect(log().hasSomething, isFalse);
    });
  });

  group('a trip without turn instructions', () {
    test('has checkpoints along its route, about every 500 metres', () {
      // 0.001 of latitude is about 111 m: points every 111 m for 2.2 km
      List<List<double>> line = [
        for (int i = 0; i <= 20; i++) [-0.5, 51.4 + i * 0.001]
      ];
      List<Point> points = DrivenLog.pointsAlong(line);
      expect(points.length, 5); // 0, 555, 1110, 1665, 2220 m
      expect(points.first, const Point(-0.5, 51.4));
    });
  });

  group('MyTripItem.publishedUri', () {
    test('saved and loaded with the trip', () {
      MyTripItem trip = MyTripItem(title: 'A copy')..publishedUri = 'trip1';
      MyTripItem again =
          MyTripItem.fromJson(jsonObject: jsonDecode(jsonEncode(trip.toJson())));
      expect(again.publishedUri, 'trip1');
    });
  });
}
