/// One input field: the JSON key the API expects, its label and a hint.
class InputFieldSpec {
  const InputFieldSpec(this.key, this.label, this.hint, {this.isNumber = true});

  final String key;
  final String label;
  final String hint;
  final bool isNumber;
}

/// The 6 inputs the model needs, in the order they appear on the page.
const List<InputFieldSpec> tripInputs = [
  InputFieldSpec('route_number', 'Route number', '1 to 999, e.g. 29'),
  InputFieldSpec('direction', 'Direction', 'N, S, E or W', isNumber: false),
  InputFieldSpec('incident_code', 'Incident code', 'e.g. MFDV (on diversion)',
      isNumber: false),
  InputFieldSpec('hour', 'Hour of the day', '0 to 23, e.g. 8'),
  InputFieldSpec('day_of_week', 'Day of the week', '0 = Monday ... 6 = Sunday'),
  InputFieldSpec('month', 'Month', '1 to 12'),
];
