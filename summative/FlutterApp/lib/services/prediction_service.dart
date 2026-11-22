import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/input_field_spec.dart';

/// The outcome of a prediction request: either the predicted minutes or a
/// readable error message that can be shown to the user as it is.
///
/// Errors are returned as values instead of thrown as exceptions, so a
/// rejected input (for example hour 25) is a normal outcome, not a crash.
class PredictionResult {
  const PredictionResult.success(double this.minutes) : error = null;
  const PredictionResult.failure(String this.error) : minutes = null;

  final double? minutes;
  final String? error;

  bool get isSuccess => minutes != null;
}

/// Sends trip details to the API's /predict endpoint.
class PredictionService {
  PredictionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Returns the predicted delay in minutes, or a readable error message.
  Future<PredictionResult> predictDelay(Map<String, Object> trip) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConfig.predictUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(trip),
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      return const PredictionResult.failure(
          'The server took too long to answer. It may be waking up, '
          'please try again in a moment.');
    } on SocketException {
      return const PredictionResult.failure(
          'No internet connection. Check your connection and try again.');
    } on http.ClientException {
      return const PredictionResult.failure(
          'Could not reach the server. Please try again.');
    }

    if (response.statusCode == 200) {
      final minutes = _readMinutes(response.body);
      return minutes == null
          ? const PredictionResult.failure(
              'The server sent an unexpected answer. Please try again.')
          : PredictionResult.success(minutes);
    }
    if (response.statusCode == 422) {
      return PredictionResult.failure(_validationMessage(response.body));
    }
    return PredictionResult.failure(
        'The server returned an error (${response.statusCode}). '
        'Please try again.');
  }

  /// Reads predicted_delay_minutes from a 200 response, or null if missing.
  double? _readMinutes(String body) {
    final data = _decode(body);
    final minutes = data is Map ? data['predicted_delay_minutes'] : null;
    return minutes is num ? minutes.toDouble() : null;
  }

  /// Decodes a JSON body, or returns null if it is not valid JSON.
  dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  /// Turns the API's 422 validation response into one line per bad field,
  /// e.g. "Hour of the day: Input should be less than or equal to 23".
  String _validationMessage(String body) {
    final data = _decode(body);
    final details = data is Map ? data['detail'] : null;
    if (details is! List || details.isEmpty) {
      return 'Some values are not valid. Please check the fields.';
    }

    final lines = <String>[];
    for (final item in details) {
      final loc = item['loc'];
      final key = loc is List && loc.isNotEmpty ? loc.last.toString() : '';
      final spec = tripInputs.where((s) => s.key == key);
      final label = spec.isEmpty ? key : spec.first.label;
      var message = item['msg'].toString();
      if (key == 'incident_code' && message.startsWith('Input should be')) {
        message = 'unknown code. Use a code such as MFDV, MFUS, EFO or OTHER';
      }
      lines.add('$label: $message');
    }
    return lines.toSet().join('\n');
  }
}
