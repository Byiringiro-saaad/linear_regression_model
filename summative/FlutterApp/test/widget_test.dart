import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bus_delay_app/app.dart';
import 'package:bus_delay_app/services/prediction_service.dart';

/// A tall phone-sized screen, so every field and the result area are built.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

/// A PredictionService whose HTTP client always returns [status] and [body].
PredictionService fakeService(int status, Object body) => PredictionService(
      client: MockClient(
          (request) async => http.Response(jsonEncode(body), status)),
    );

Future<void> fillValidTrip(WidgetTester tester) async {
  const values = ['29', 'n', 'mfdv', '8', '1', '3'];
  for (var i = 0; i < values.length; i++) {
    await tester.enterText(find.byType(TextField).at(i), values[i]);
  }
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

  testWidgets('a successful API answer shows the predicted delay',
      (WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(BusDelayApp(
        service: fakeService(200, {'predicted_delay_minutes': 33.38})));

    await fillValidTrip(tester);
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();

    expect(find.text('33.4 minutes'), findsOneWidget);
  });

  testWidgets('an API validation error is shown as a readable message',
      (WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(BusDelayApp(
      service: fakeService(422, {
        'detail': [
          {
            'loc': ['body', 'hour'],
            'msg': 'Input should be less than or equal to 23',
          }
        ]
      }),
    ));

    await fillValidTrip(tester);
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();

    expect(find.text('Could not predict'), findsOneWidget);
    expect(
      find.text('Hour of the day: Input should be less than or equal to 23'),
      findsOneWidget,
    );
  });

  testWidgets('a server error is shown as a readable message',
      (WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
        BusDelayApp(service: fakeService(500, {'detail': 'error'})));

    await fillValidTrip(tester);
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();

    expect(
      find.text('The server returned an error (500). Please try again.'),
      findsOneWidget,
    );
  });
}
