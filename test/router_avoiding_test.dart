import 'package:drives/helpers/create_trip_helpers.dart';
import 'package:drives/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the router is asked to avoid, from the user's settings. The router
/// (OSRM) only takes some combinations: each class on its own, and
/// motorway,trunk,primary. Anything else is refused - "Avoid main roads"
/// alone (trunk,primary) used to stop the trip being routed at all.
void main() {
  void settings({
    bool motorways = false,
    bool mainRoads = false,
    bool ferries = false,
    bool tolls = false,
  }) {
    Setup()
      ..avoidMotorways = motorways
      ..avoidAroads = mainRoads
      ..avoidFerries = ferries
      ..avoidTollRoads = tolls;
  }

  tearDown(() => settings());

  test('nothing to avoid', () {
    settings();
    expect(setAvoiding(), '');
  });

  test('main roads take motorways with them - the router has no trunk,primary',
      () {
    settings(mainRoads: true);
    expect(setAvoiding(), '&exclude=motorway,trunk,primary');
    settings(motorways: true, mainRoads: true);
    expect(setAvoiding(), '&exclude=motorway,trunk,primary');
  });

  test('motorways, ferries and tolls each on their own', () {
    settings(motorways: true);
    expect(setAvoiding(), '&exclude=motorway');
    settings(ferries: true);
    expect(setAvoiding(), '&exclude=ferry');
    settings(tolls: true);
    expect(setAvoiding(), '&exclude=toll');
  });

  test("the roads come first when the router can't take everything asked for",
      () {
    settings(motorways: true, ferries: true, tolls: true);
    expect(setAvoiding(), '&exclude=motorway');
    settings(ferries: true, tolls: true);
    expect(setAvoiding(), '&exclude=ferry');
  });
}
