import 'package:flutter/material.dart';

import '../models/input_field_spec.dart';
import 'option_picker_sheet.dart';

/// One labelled text field for a trip input.
///
/// Fields with a list of options get a button that opens a pick list; the
/// chosen value is written into the text field, and its description is shown
/// under the field.
class TripInputField extends StatelessWidget {
  const TripInputField({
    super.key,
    required this.spec,
    required this.controller,
    this.isLast = false,
    this.onSubmitted,
  });

  final InputFieldSpec spec;
  final TextEditingController controller;
  final bool isLast;
  final VoidCallback? onSubmitted;

  Future<void> _pick(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final value = await showOptionPicker(
      context,
      title: 'Choose ${spec.label.toLowerCase()}',
      options: spec.options!,
      selected: controller.text.trim().toUpperCase(),
    );
    if (value != null) controller.text = value;
  }

  /// Description of the value currently in the field, e.g. "Bus on diversion".
  String? _description(String text) {
    final value = text.trim().toUpperCase();
    for (final option in spec.options ?? const []) {
      if (option.value == value) return option.label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final options = spec.options;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        keyboardType:
            spec.isNumber ? TextInputType.number : TextInputType.text,
        textCapitalization: TextCapitalization.characters,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onSubmitted:
            isLast && onSubmitted != null ? (_) => onSubmitted!() : null,
        decoration: InputDecoration(
          labelText: spec.label,
          hintText: spec.hint,
          helperText: _description(value.text),
          suffixIcon: options == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.list_alt),
                  tooltip: 'Choose from list',
                  onPressed: () => _pick(context),
                ),
        ),
      ),
    );
  }
}
