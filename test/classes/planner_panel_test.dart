import 'package:drives/classes/planner_panel.dart';
import 'package:drives/services/planner_service.dart';
import 'package:drives/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a plan shows its guide, and each stop its story and sources',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.resetPhysicalSize);
    PlannerService planner = PlannerService();
    planner.status = PlannerStatus.done;
    planner.fields = {'interests': [], 'stops': []};
    planner.result = {
      'trip': {
        'title': 'Fens, Castles and Dambusters',
        'summary': 'A quiet-road loop north west of Boston.',
        'guide': 'Leave Boston on the B road through Langrick.\n\n'
            'Look up to see the airmen\'s signatures on the ceiling.',
        'road_types': {'motorway': 0, 'a_road': 10, 'b_road': 26, 'minor': 41},
        'a_roads': 13,
        'minutes': 84,
        'km': 77,
        'stops': [
          {
            'name': 'Blue Bell Inn',
            'kind': 'pub',
            'what': 'pub',
            'source': 'osm',
            'lat': 53.1,
            'lng': -0.2,
            'why': "The Dambusters' local",
            'story': 'It was the local of 617 Squadron.',
            'sources': [
              {
                'url': 'https://www.visitlincolnshire.com/food-drink/blue-bell-inn/',
                'title': 'Blue Bell Inn'
              }
            ],
          },
          // nothing was found: no story, and nothing the worse for it
          {
            'name': 'Old Mill',
            'kind': 'windmill',
            'what': 'windmill',
            'source': 'osm',
            'why': 'On the way',
            'story': '',
            'sources': [],
          },
        ],
        'choices': [],
      }
    };
    await tester.pumpWidget(MaterialApp(
        theme: drivesTheme(),
        home: const Scaffold(
            body: SingleChildScrollView(child: PlannerPanel()))));
    await tester.pump();

    expect(find.text('Guide to the drive'), findsOneWidget);
    expect(find.textContaining('B road through Langrick'), findsOneWidget);
    expect(find.text('It was the local of 617 Squadron.'), findsOneWidget);
    expect(find.text('Source: visitlincolnshire.com'), findsOneWidget);
    expect(find.text('Old Mill'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
