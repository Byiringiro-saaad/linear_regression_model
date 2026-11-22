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
  late final PredictionService _service = widget.service ?? PredictionService();

  final Map<String, TextEditingController> _controllers = {
    for (final spec in tripInputs) spec.key: TextEditingController(),
  };

  final ScrollController _scroll = ScrollController();

  bool _loading = false;
  String? _result; // predicted delay, shown in the result area
  String? _error; // readable error message, shown instead of a result

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls down so the result area is visible on small screens.
  void _showResultArea() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Checks the fields before anything is sent: returns a readable message
  /// for the first field that is empty, or a number field that is not a whole
  /// number, or null when all fields are filled in correctly. Ranges and
  /// allowed codes are checked by the API itself.
  String? _validateInputs() {
    for (final spec in tripInputs) {
      final text = _controllers[spec.key]!.text.trim();
      if (text.isEmpty) {
        return 'Please fill in "${spec.label}".';
      }
      if (spec.isNumber && int.tryParse(text) == null) {
        return '"${spec.label}" must be a whole number (${spec.hint}).';
      }
    }
    return null;
  }

  /// Builds the request body from the fields (call after [_validateInputs]).
  Map<String, Object> _readInputs() {
    return {
      for (final spec in tripInputs)
        spec.key: spec.isNumber
            ? int.parse(_controllers[spec.key]!.text.trim())
            : _controllers[spec.key]!.text.trim().toUpperCase(),
    };
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();

    final inputError = _validateInputs();
    if (inputError != null) {
      setState(() {
        _result = null;
        _error = inputError;
      });
      _showResultArea();
      return;
    }

    setState(() {
      _result = null;
      _error = null;
      _loading = true;
    });

    final outcome = await _service.predictDelay(_readInputs());
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (outcome.isSuccess) {
        _result = '${outcome.minutes!.toStringAsFixed(1)} minutes';
      } else {
        _error = outcome.error;
      }
    });
    _showResultArea();
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
          controller: _scroll,
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
