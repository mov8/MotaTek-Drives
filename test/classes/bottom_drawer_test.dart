import 'package:drives/classes/classes.dart';
import 'package:drives/constants.dart';
import 'package:drives/services/services.dart';
import 'package:drives/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The drawer as it is on the map page: the bottom sheet of a Scaffold in
/// the shell's Scaffold, on the dev phone's screen
Future<void> showDrawer(WidgetTester tester, double keyboard) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  tester.view.viewInsets =
      FakeViewPadding(bottom: keyboard * tester.view.devicePixelRatio);
  addTearDown(tester.view.reset);
  BottomDrawerController controller = BottomDrawerController();
  await tester.pumpWidget(MaterialApp(
    theme: drivesTheme(),
    home: Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: const SizedBox(height: 80),
      body: Builder(
        builder: (context) => Scaffold(
          body: const SizedBox.expand(),
          bottomSheet: BottomDrawer(context: context, controller: controller),
        ),
      ),
    ),
  ));
  controller.setContent(content: BottomDrawerItems.planner);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => PlannerService().status = PlannerStatus.idle);

  for (double keyboard in [0.0, 300.0, 400.0, 500.0]) {
    testWidgets('Auto-route fits with a ${keyboard.round()} high keyboard',
        (tester) async {
      await showDrawer(tester, keyboard);
      expect(find.text('Auto-route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
