import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bus_delay_app/app.dart';
import 'package:bus_delay_app/data/pick_options.dart';

void main() {
  test('incident code list matches the codes the API accepts', () {
    // read the IncidentCode Literal from the API code, so the two never drift
    final api = File('../API/prediction.py').readAsStringSync();
    final block = RegExp(r'IncidentCode = Literal\[(.*?)\]', dotAll: true)
        .firstMatch(api)!
        .group(1)!;
    final apiCodes =
        RegExp(r'"([A-Z]+)"').allMatches(block).map((m) => m.group(1)).toSet();

    final appCodes = incidentCodeOptions.map((o) => o.value).toList();
    expect(appCodes.toSet().length, appCodes.length, reason: 'no duplicates');
    expect(appCodes.toSet(), apiCodes);
  });

  testWidgets('picking an incident code fills the text field',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BusDelayApp());

    // the incident code field is the second one with a list button
    await tester.tap(find.byTooltip('Choose from list').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Choose incident code'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'weather');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weather related'));
    await tester.pumpAndSettle();

    expect(find.text('MFWEA'), findsOneWidget); // value in the text field
    expect(find.text('Weather related'), findsOneWidget); // description below
  });

  testWidgets('picking a day writes its number', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BusDelayApp());

    await tester.tap(find.byTooltip('Choose from list').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saturday'));
    await tester.pumpAndSettle();

    final dayField = tester.widget<TextField>(find.byType(TextField).at(4));
    expect(dayField.controller!.text, '5');
    expect(find.text('Saturday'), findsOneWidget);
  });
}
