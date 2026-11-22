/// Values a user can pick from a list instead of typing them.
///
/// [value] is what goes into the text field and is sent to the API;
/// [label] is the plain-English description shown in the list.
class PickOption {
  const PickOption(this.value, this.label);

  final String value;
  final String label;
}

const List<PickOption> directionOptions = [
  PickOption('N', 'Northbound'),
  PickOption('S', 'Southbound'),
  PickOption('E', 'Eastbound'),
  PickOption('W', 'Westbound'),
];

const List<PickOption> dayOfWeekOptions = [
  PickOption('0', 'Monday'),
  PickOption('1', 'Tuesday'),
  PickOption('2', 'Wednesday'),
  PickOption('3', 'Thursday'),
  PickOption('4', 'Friday'),
  PickOption('5', 'Saturday'),
  PickOption('6', 'Sunday'),
];

/// The 42 incident codes the model was trained on (TTC Bus Delay Data).
///
/// Descriptions come from the TTC code list (incident_codes.csv). The first
/// letter is the category: E = equipment, M = miscellaneous, S = security,
/// T = transportation. Codes the TTC list does not describe only show their
/// category.
const List<PickOption> incidentCodeOptions = [
  PickOption('MFDV', 'Bus on diversion'),
  PickOption('MFUS', 'Unable to maintain schedule'),
  PickOption('MFWEA', 'Weather related'),
  PickOption('MFPI', 'Collision / personal injury (TTC not involved)'),
  PickOption('MFTO', 'Ill operator or other operator issue'),
  PickOption('MFUI', 'Ill customer, transported'),
  PickOption('MFUIR', 'Ill customer, transport declined'),
  PickOption('MFSAN', 'Unsanitary vehicle'),
  PickOption('MFSH', 'Bus used as a shuttle'),
  PickOption('MFESA', 'No operator available (ESA)'),
  PickOption('MFVIS', 'Vision issues'),
  PickOption('MFO', 'Other miscellaneous incident'),
  PickOption('MFBIO', 'Miscellaneous incident (no description published)'),
  PickOption('MFFL', 'Miscellaneous incident (no description published)'),
  PickOption('MFGD', 'Miscellaneous incident (no description published)'),
  PickOption('EFD', 'Doors problem'),
  PickOption('EFB', 'Body damage'),
  PickOption('EFHVA', 'Heating / ventilation / air conditioning'),
  PickOption('EFP', 'Propulsion (engine) problem'),
  PickOption('EFRA', 'Ramp issues'),
  PickOption('EFO', 'Other equipment problem'),
  PickOption('EFAS', 'Equipment problem (no description published)'),
  PickOption('EFCEL', 'Equipment problem (no description published)'),
  PickOption('EFFL', 'Equipment problem (no description published)'),
  PickOption('EFLT', 'Equipment problem (no description published)'),
  PickOption('EFSD', 'Equipment problem (no description published)'),
  PickOption('EFTI', 'Equipment problem (no description published)'),
  PickOption('EFTRM', 'Equipment problem (no description published)'),
  PickOption('EFVIS', 'Equipment problem (no description published)'),
  PickOption('SFAE', 'Assault on an employee'),
  PickOption('SFAP', 'Assault on a passenger'),
  PickOption('SFDP', 'Disorderly passenger'),
  PickOption('SFPOL', 'Held for a police investigation'),
  PickOption('SFO', 'Other security incident'),
  PickOption('SFL', 'Security incident (no description published)'),
  PickOption('TFPD', 'TTC collision, property damage'),
  PickOption('TFPI', 'TTC collision, personal injury'),
  PickOption('TFOI', 'Injury on board'),
  PickOption('TFCNO', 'No operator available'),
  PickOption('TFO', 'Other transportation incident (switch violation)'),
  PickOption('TFOR', 'Transportation incident (no description published)'),
  PickOption('OTHER', 'Any other / rare incident'),
];
