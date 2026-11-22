import 'package:flutter/material.dart';

/// Copy / paste menu for the app's text fields, drawn by Flutter itself.
///
/// By default Flutter shows the native iOS menu (Paste, Select All, Scan Text).
/// Closing that menu can trip a Flutter assertion in debug builds, which makes
/// the debugger pause the app. Flutter's own menu has the same actions and
/// avoids that problem.
Widget textFieldMenu(BuildContext context, EditableTextState editableTextState) {
  return AdaptiveTextSelectionToolbar.editableText(
    editableTextState: editableTextState,
  );
}
