import 'package:flutter/material.dart';

import '../models/input_field_spec.dart';
import '../services/prediction_service.dart';
import '../widgets/result_card.dart';
import '../widgets/trip_input_field.dart';

/// The app's single page: 6 inputs, a Predict button and the result area.
class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key, this.service});

  /// Can be replaced in tests; the real API is used by default.
  final PredictionService? service;

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  late final PredictionService _service =
      widget.service ?? PredictionService();

  final Map<String, TextEditingController> _controllers = {
    for (final spec in tripInputs) spec.key: TextEditingController(),
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

  /// Reads the fields and builds the request body. Throws a
  /// [PredictionException] when a field is empty or a number field is not a
  /// whole number. Ranges and allowed codes are checked by the API itself.
  Map<String, Object> _readInputs() {
    final body = <String, Object>{};
    for (final spec in tripInputs) {
      final text = _controllers[spec.key]!.text.trim();
      if (text.isEmpty) {
        throw PredictionException('Please fill in "${spec.label}".');
      }
      if (spec.isNumber) {
        final value = int.tryParse(text);
        if (value == null) {
          throw PredictionException(
              '"${spec.label}" must be a whole number (${spec.hint}).');
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

    try {
      final trip = _readInputs();
      setState(() => _loading = true);
      final minutes = await _service.predictDelay(trip);
      _result = '${minutes.toStringAsFixed(1)} minutes';
    } on PredictionException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong while contacting the server. '
          'Please try again.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            for (final spec in tripInputs) ...[
              TripInputField(
                spec: spec,
                controller: _controllers[spec.key]!,
                isLast: spec == tripInputs.last,
                onSubmitted: _predict,
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
            ResultCard(result: _result, error: _error),
          ],
        ),
      ),
    );
  }
}
