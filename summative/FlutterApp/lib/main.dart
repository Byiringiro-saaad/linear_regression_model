import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Live prediction endpoint of the Bus Delay Prediction API on Render.
const String predictUrl =
    'https://bus-delay-prediction-api.onrender.com/predict';

void main() => runApp(const BusDelayApp());

class BusDelayApp extends StatelessWidget {
  const BusDelayApp({super.key});

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
      home: const PredictionPage(),
    );
  }
}

/// One input field: the JSON key the API expects, its label and a hint.
class InputSpec {
  const InputSpec(this.key, this.label, this.hint, {this.isNumber = true});

  final String key;
  final String label;
  final String hint;
  final bool isNumber;
}

const List<InputSpec> inputs = [
  InputSpec('route_number', 'Route number', '1 to 999, e.g. 29'),
  InputSpec('direction', 'Direction', 'N, S, E or W', isNumber: false),
  InputSpec('incident_code', 'Incident code', 'e.g. MFDV (on diversion)',
      isNumber: false),
  InputSpec('hour', 'Hour of the day', '0 to 23, e.g. 8'),
  InputSpec('day_of_week', 'Day of the week', '0 = Monday ... 6 = Sunday'),
  InputSpec('month', 'Month', '1 to 12'),
];

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final Map<String, TextEditingController> _controllers = {
    for (final spec in inputs) spec.key: TextEditingController(),
  };

  bool _loading = false;
  String? _result; // predicted delay, shown in the result area
  String? _error; // readable error message, shown instead of a result

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Reads the fields and builds the JSON body. Returns null and sets
  /// [_error] when a field is empty or a number field is not a whole number.
  /// Ranges and allowed codes are checked by the API itself.
  Map<String, Object>? _readInputs() {
    final body = <String, Object>{};
    for (final spec in inputs) {
      final text = _controllers[spec.key]!.text.trim();
      if (text.isEmpty) {
        _error = 'Please fill in "${spec.label}".';
        return null;
      }
      if (spec.isNumber) {
        final value = int.tryParse(text);
        if (value == null) {
          _error = '"${spec.label}" must be a whole number (${spec.hint}).';
          return null;
        }
        body[spec.key] = value;
      } else {
        body[spec.key] = text.toUpperCase();
      }
    }
    return body;
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _result = null;
      _error = null;
    });

    final body = _readInputs();
    if (body == null) {
      setState(() {});
      return;
    }

    setState(() => _loading = true);
    try {
      // the free Render service sleeps when idle and can take up to a
      // minute to wake up, so the timeout is generous
      final response = await http
          .post(
            Uri.parse(predictUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final minutes = (data['predicted_delay_minutes'] as num).toDouble();
        _result = '${minutes.toStringAsFixed(1)} minutes';
      } else if (response.statusCode == 422) {
        _error = _validationMessage(data);
      } else {
        _error = 'The server returned an error (${response.statusCode}). '
            'Please try again.';
      }
    } on TimeoutException {
      _error = 'The server took too long to answer. It may be waking up, '
          'please try again in a moment.';
    } on SocketException {
      _error = 'No internet connection. Check your connection and try again.';
    } catch (_) {
      _error = 'Something went wrong while contacting the server. '
          'Please try again.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Turns the API's 422 validation response into one line per bad field,
  /// e.g. "Hour of the day: Input should be less than or equal to 23".
  String _validationMessage(dynamic data) {
    final details = data is Map ? data['detail'] : null;
    if (details is! List || details.isEmpty) {
      return 'Some values are not valid. Please check the fields.';
    }
    final lines = <String>[];
    for (final item in details) {
      final loc = item['loc'];
      final key = loc is List && loc.isNotEmpty ? loc.last.toString() : '';
      final spec = inputs.where((s) => s.key == key);
      final label = spec.isEmpty ? key : spec.first.label;
      var message = item['msg'].toString();
      if (key == 'incident_code' && message.startsWith('Input should be')) {
        message = 'unknown code. Use a code such as MFDV, MFUS, EFO or OTHER';
      }
      lines.add('$label: $message');
    }
    return lines.toSet().join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Delay Predictor'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Enter the trip details to predict how many minutes the bus '
              'will be delayed, so passengers get a precise arrival time.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final spec in inputs) ...[
              TextField(
                controller: _controllers[spec.key],
                keyboardType:
                    spec.isNumber ? TextInputType.number : TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                textInputAction: spec == inputs.last
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: spec == inputs.last ? (_) => _predict() : null,
                decoration: InputDecoration(
                  labelText: spec.label,
                  hintText: spec.hint,
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            FilledButton(
              onPressed: _loading ? null : _predict,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Predict', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            _ResultArea(result: _result, error: _error),
          ],
        ),
      ),
    );
  }
}

/// Shows the predicted delay, an error message, or a short placeholder.
class _ResultArea extends StatelessWidget {
  const _ResultArea({required this.result, required this.error});

  final String? result;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isError = error != null;
    final hasResult = result != null && !isError;

    final Color background;
    final Color foreground;
    if (isError) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else if (hasResult) {
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
    } else {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isError ? 'Could not predict' : 'Predicted delay',
            style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            error ?? result ?? 'The prediction will appear here.',
            style: TextStyle(
              color: foreground,
              fontSize: hasResult ? 28 : 15,
              fontWeight: hasResult ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
