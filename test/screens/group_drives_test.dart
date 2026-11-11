import 'package:drives/screens/group_drives.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Events I've organised, before there are any: the steps to get there.
  // Line 2 overflowed a phone by 7.9 pixels once its tick showed.
  for (double width in [320, 360, 411]) {
    testWidgets('the steps fit a ${width.round()} wide phone with both ticks',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: NoGroupEvents(
                  hasTrips: true, hasGroups: true, textColor: Colors.black))));
      expect(tester.takeException(), isNull);
      expect(find.text('2. Create a group of participants.'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });
  }
}
