import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/input_field_spec.dart';

/// An error with a message that can be shown to the user as it is.
class PredictionException implements Exception {
  const PredictionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sends trip details to the API's /predict endpoint.
class PredictionService {
  PredictionService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Returns the predicted delay in minutes, or throws a [PredictionException]
  /// with a readable message.
  Future<double> predictDelay(Map<String, Object> trip) async {
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
      throw const PredictionException(
          'The server took too long to answer. It may be waking up, '
          'please try again in a moment.');
    } on SocketException {
      throw const PredictionException(
          'No internet connection. Check your connection and try again.');
    } on http.ClientException {
      throw const PredictionException(
          'Could not reach the server. Please try again.');
    }

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return (data['predicted_delay_minutes'] as num).toDouble();
      } catch (_) {
        throw const PredictionException(
            'The server sent an unexpected answer. Please try again.');
      }
    }
    if (response.statusCode == 422) {
      throw PredictionException(_validationMessage(response.body));
    }
    throw PredictionException(
        'The server returned an error (${response.statusCode}). '
        'Please try again.');
  }

  /// Turns the API's 422 validation response into one line per bad field,
  /// e.g. "Hour of the day: Input should be less than or equal to 23".
  String _validationMessage(String body) {
    dynamic details;
    try {
      final data = jsonDecode(body);
      details = data is Map ? data['detail'] : null;
    } catch (_) {
      details = null;
    }
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
