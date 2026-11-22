import 'package:flutter/material.dart';

/// Shows the predicted delay, an error message, or a short placeholder.
class ResultCard extends StatelessWidget {
  const ResultCard({super.key, this.result, this.error});

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
