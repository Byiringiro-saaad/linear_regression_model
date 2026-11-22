import 'package:flutter/material.dart';

import 'screens/prediction_screen.dart';
import 'services/prediction_service.dart';

class BusDelayApp extends StatelessWidget {
  const BusDelayApp({super.key, this.service});

  /// Can be replaced in tests; the real API is used by default.
  final PredictionService? service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Delay Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: PredictionScreen(service: service),
    );
  }
}
