// The Explore page's ActionChips: which show for the trip as it is.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/constants.dart';

void main() {
  setUp(CurrentTripItem.reset);

  test('beyond both ends of a round trip: Extend start, end and both', () {
    CurrentTripItem trip = CurrentTripItem()
      ..tripState = TripState.editing
      ..waypointState = WaypointState.extendBoth
      ..routes = [
        Route(waypoints: [
          for (int i = 0; i < 3; i++) Waypoint(point: Point(i * 0.01, 51.4))
        ])
      ];

    expect(resolveChip(TripChip.waypoint, trip),
        [TripChip.extendStart, TripChip.extendEnd, TripChip.extendBoth]);
  });

  test('a saved trip can be cleared from the map', () {
    expect(chipsForPhase[PlanPhase.loaded], contains(TripChip.clear));
  });

  test("the chip doing both ends says so: 'Extend start and end'", () {
    expect(TripChip.extendBoth.label, 'Extend start and end');
  });

  test('tracking ended before driving anywhere leaves nothing to keep', () {
    CurrentTripItem trip = CurrentTripItem()
      ..tripState = TripState.stoppedTracking
      ..routes = [
        Route(waypoints: [Waypoint(point: Point(0.0, 51.4))], lines: [
          [0.0, 51.4]
        ])
      ];
    expect(nothingTracked(trip), isTrue);
  });

  test('a drive that was tracked is kept', () {
    CurrentTripItem trip = CurrentTripItem()
      ..tripState = TripState.stoppedTracking
      ..routes = [
        Route(waypoints: [
          Waypoint(point: Point(0.0, 51.4)),
          Waypoint(point: Point(0.05, 51.4)),
        ], lines: [
          [0.0, 51.4],
          [0.05, 51.4]
        ])
      ];
    expect(nothingTracked(trip), isFalse);
  });
}
