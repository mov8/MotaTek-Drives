// Tests for building and editing a trip - adding, inserting and removing
// waypoints, extending the start, revisiting, and undo / redo.
//
// CurrentTripItem is the trip being planned - one shared object (a
// singleton). Each test starts with a fresh one (setUp runs before every
// test) and a fake router (test/helpers/fake_router.dart) instead of the
// real routing server.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/constants.dart';

import '../helpers/fake_router.dart';

// Some points around Staines, west to east - [longitude, latitude]
const Point staines = Point(-0.5160, 51.4340);
const Point egham = Point(-0.5530, 51.4310);
const Point windsor = Point(-0.6040, 51.4838);
const Point laleham = Point(-0.4940, 51.4100);

/// The trip's waypoints as points, in order
List<Point> waypointsOf(CurrentTripItem trip) =>
    [for (Waypoint w in trip.routes.last.waypoints) w.point];

/// The types of the Start / Waypoint / End points of interest
List<int> markerTypes(CurrentTripItem trip) => [
      for (var poi in trip.pointsOfInterest)
        if ([12, 17, 18].contains(poi.type)) poi.type
    ];

void main() {
  late FakeRouter router;
  late CurrentTripItem trip;

  setUp(() {
    CurrentTripItem.reset();
    trip = CurrentTripItem();
    trip.tripState = TripState.manual;
    router = FakeRouter()..install();
  });

  group('adding waypoints', () {
    test('the first waypoint is the Start, with no route yet', () async {
      await trip.addWaypoint(point: staines);

      expect(waypointsOf(trip), [staines]);
      expect(markerTypes(trip), [17]); // Start
      expect(router.requests, isEmpty); // one waypoint - nothing to route
    });

    test('each new waypoint goes on the end, and the route is fetched',
        () async {
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: egham);
      await trip.addWaypoint(point: windsor);

      expect(waypointsOf(trip), [staines, egham, windsor]);
      expect(markerTypes(trip), [17, 12, 18]); // Start, Waypoint, End
      // routed after the 2nd and 3rd waypoints, through all of them
      expect(router.requests, hasLength(2));
      expect(router.requests.last, hasLength(3));
      // the route's line runs from the start to the end
      expect(trip.routes.last.lines.first, [staines.x, staines.y]);
      expect(trip.routes.last.lines.last, [windsor.x, windsor.y]);
    });

    test('Extend start puts the new waypoint first', () async {
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: egham);
      await trip.addWaypoint(point: laleham, atStart: true);

      expect(waypointsOf(trip), [laleham, staines, egham]);
      // the new first waypoint becomes the Start
      expect(trip.pointsOfInterest.first.type, 17);
      expect(trip.pointsOfInterest.first.point, laleham);
    });

    test('Insert goes after the selected (anchor) waypoint', () async {
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: windsor);
      trip.tripState = TripState.editing;
      trip.waypointState = WaypointState.insert;
      trip.routes.last.waypoints.first.selected = true; // the anchor

      await trip.addWaypoint(point: egham);

      expect(waypointsOf(trip), [staines, egham, windsor]);
      expect(markerTypes(trip), [17, 12, 18]);
    });

    test('a revisit goes on the end, flagged as a revisit', () async {
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: egham);
      await trip.addWaypoint(point: windsor);

      await trip.addWaypoint(point: egham, revisit: true);

      expect(waypointsOf(trip), [staines, egham, windsor, egham]);
      expect(trip.routes.last.waypoints.last.revisit, isTrue);
    });
  });

  group('removing waypoints', () {
    test('removes it, re-routes, and the markers follow', () async {
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: egham);
      await trip.addWaypoint(point: windsor);

      await trip.removeWaypoint(index: 1);

      expect(waypointsOf(trip), [staines, windsor]);
      expect(markerTypes(trip), [17, 18]);
    });
  });

  group('undo and redo', () {
    test('undo steps back one waypoint at a time, redo forward', () async {
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: egham);
      await trip.addWaypoint(point: windsor);

      await trip.undo();
      expect(waypointsOf(trip), [staines, egham]);
      await trip.undo();
      expect(waypointsOf(trip), [staines]);
      await trip.redo();
      expect(waypointsOf(trip), [staines, egham]);
      expect(markerTypes(trip), [17, 18]);
    });

    test('every waypoint can be undone - back to an empty trip', () async {
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: egham);
      await trip.addWaypoint(point: windsor);

      while (trip.canUndo) {
        await trip.undo();
      }
      expect(waypointsOf(trip), isEmpty);
      expect(trip.canRedo, isTrue);
    });

    test('a change after undo throws away what was undone', () async {
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: egham);
      await trip.undo();

      await trip.addWaypoint(point: windsor);

      expect(waypointsOf(trip), [staines, windsor]);
      expect(trip.canRedo, isFalse);
    });

    test('a long trip can be undone all the way (more than 10 steps)',
        () async {
      for (int i = 0; i < 12; i++) {
        await trip.addWaypoint(point: Point(-0.50 - i * 0.01, 51.43));
      }
      int steps = 0;
      while (trip.canUndo) {
        await trip.undo();
        steps++;
      }
      expect(steps, 12);
    });
  });

  group('turn-by-turn instructions', () {
    test('a route with no turns keeps its departure (a bug found by tests)',
        () async {
      // The fake router's stretches have no turns - just depart and arrive
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: egham);

      expect(trip.maneuvers.map((m) => m.type), ['depart', 'arrive']);
      expect(trip.maneuvers.first.point, staines);
      expect(trip.maneuvers.last.point, egham);
      expect(trip.pointsOfInterest.first.point, staines); // the Start stays
    });
  });

  group('when the router fails', () {
    test('the waypoint is still added, without crashing', () async {
      await trip.addWaypoint(point: staines);
      router.statusCode = 500;

      await trip.addWaypoint(point: egham);

      expect(waypointsOf(trip), [staines, egham]);
    });

    test("an existing route isn't wiped (a bug found by tests)", () async {
      await trip.addWaypoint(point: staines);
      await trip.addWaypoint(point: egham);
      List<List<double>> line = trip.routes.last.lines;
      router.statusCode = 500;

      await trip.addWaypoint(point: windsor);

      expect(waypointsOf(trip), [staines, egham, windsor]);
      expect(trip.routes.last.lines, line); // the last route that was fetched
    });
  });
}
