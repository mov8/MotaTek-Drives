import 'package:drives/classes/planner_panel.dart';
import 'package:drives/models/models.dart';
import 'package:drives/services/planner_service.dart';
import 'package:drives/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('before a request is written', () {
    Future<void> showPanel(WidgetTester tester) async {
      PlannerService().status = PlannerStatus.idle;
      await tester.pumpWidget(MaterialApp(
          theme: drivesTheme(),
          home: const Scaffold(
              body: SingleChildScrollView(child: PlannerPanel()))));
      await tester.pump();
    }

    tearDown(() => Setup().jwt = '');

    testWidgets('someone not logged in is told first', (tester) async {
      Setup().jwt = '';
      await showPanel(tester);
      expect(find.text('Log in to use Auto-route'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Log in'), findsOneWidget);
      TextField request = tester.widget(find.byType(TextField));
      expect(request.enabled, isFalse);
      FilledButton plan = tester.widget(find.byWidgetPredicate(
          (widget) => widget is FilledButton && widget.onPressed == null));
      expect(plan.onPressed, isNull);
    });

    test('a token the server has refused means logging in again', () {
      Setup().jwt = 'expired';
      PlannerService planner = PlannerService();
      expect(planner.needsLogin, isFalse);
      planner.refused(401);
      expect(planner.needsLogin, isTrue);
      expect(planner.canPlan, isFalse);
      planner.refused(200);
      expect(planner.needsLogin, isFalse);
    });
  });

  testWidgets(
      'a plan shows its overview and what was asked for; the guide and each '
      "stop's story and sources open when wanted", (tester) async {
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
        'checks': [
          {'wanted': 'About 1 h 30 min', 'got': '1 h 24 min', 'ok': true},
          {
            'wanted': 'A pub about halfway',
            'got': 'Blue Bell Inn, about 40 min in',
            'ok': true
          },
          {
            'wanted': 'Through Gibralta Point',
            'got': 'not on this route',
            'ok': false
          },
        ],
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
            'along': 0.47,
            'story': 'It was the local of 617 Squadron.',
            'sources': [
              {
                'url':
                    'https://www.visitlincolnshire.com/food-drink/blue-bell-inn/',
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

    // the overview: is it the sort of drive they want?
    expect(find.text('Fens, Castles and Dambusters'), findsOneWidget);
    expect(find.text('What you asked for'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(find.textContaining('not on this route', findRichText: true),
        findsOneWidget);
    // each stop in a line or two
    expect(find.text('Blue Bell Inn'), findsOneWidget);
    expect(find.text('pub · about 39 min in'), findsOneWidget);
    expect(find.text('Old Mill'), findsOneWidget);
    // the details wait to be opened
    expect(find.text('It was the local of 617 Squadron.'), findsNothing);
    expect(find.textContaining('B road through Langrick'), findsNothing);

    await tester.tap(find.text('Blue Bell Inn'));
    await tester.pumpAndSettle();
    expect(find.text('It was the local of 617 Squadron.'), findsOneWidget);
    expect(find.text('Source: visitlincolnshire.com'), findsOneWidget);
    expect(find.text("Chosen because: The Dambusters' local"), findsOneWidget);

    await tester.ensureVisible(find.text('Guide to the drive'));
    await tester.tap(find.text('Guide to the drive'));
    await tester.pumpAndSettle();
    expect(find.textContaining('B road through Langrick'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
