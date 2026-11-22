import 'package:flutter/material.dart';

import '../data/pick_options.dart';
import 'text_field_menu.dart';

/// Opens a bottom sheet listing [options] and returns the chosen value,
/// or null if the sheet is closed without choosing.
Future<String?> showOptionPicker(
  BuildContext context, {
  required String title,
  required List<PickOption> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => OptionPickerSheet(
      title: title,
      options: options,
      selected: selected,
    ),
  );
}

/// A searchable list of options, used for incident codes, direction and day.
class OptionPickerSheet extends StatefulWidget {
  const OptionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    this.selected,
  });

  final String title;
  final List<PickOption> options;
  final String? selected;

  @override
  State<OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<OptionPickerSheet> {
  String _query = '';

  /// Long lists (the incident codes) get a search box; short ones do not.
  bool get _searchable => widget.options.length > 10;

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final visible = widget.options
        .where((o) =>
            o.value.toLowerCase().contains(query) ||
            o.label.toLowerCase().contains(query))
        .toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * (_searchable ? 0.75 : 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(widget.title,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                contextMenuBuilder: textFieldMenu,
                decoration: const InputDecoration(
                  hintText: 'Search, e.g. diversion or weather',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (text) => setState(() => _query = text.trim()),
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('No match. Choose OTHER instead.'))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final option = visible[i];
                      return ListTile(
                        leading: SizedBox(
                          width: 56,
                          child: Text(option.value,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(option.label),
                        selected: option.value == widget.selected,
                        trailing: option.value == widget.selected
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => Navigator.pop(context, option.value),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
