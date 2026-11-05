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
}
