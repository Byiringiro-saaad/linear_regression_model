import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bus_delay_app/main.dart';

/// A tall phone-sized screen, so every field and the result area are built.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('page shows the 6 input fields and the Predict button',
      (WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const BusDelayApp());

    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('Predict'), findsOneWidget);
    expect(find.text('The prediction will appear here.'), findsOneWidget);
  });

  testWidgets('empty fields show an error without calling the API',
      (WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const BusDelayApp());

    await tester.tap(find.text('Predict'));
    await tester.pump();

    expect(find.text('Please fill in "Route number".'), findsOneWidget);
  });
}
