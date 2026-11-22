import 'package:flutter/material.dart';

import '../models/input_field_spec.dart';

/// One labelled text field for a trip input.
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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: spec.isNumber ? TextInputType.number : TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onSubmitted: isLast && onSubmitted != null ? (_) => onSubmitted!() : null,
      decoration: InputDecoration(
        labelText: spec.label,
        hintText: spec.hint,
      ),
    );
  }
}
