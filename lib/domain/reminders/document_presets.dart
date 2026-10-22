/// Presets for document and renewal reminders: the things Indian households
/// otherwise track in a separate expiry app (PUC, insurance, RC, passport,
/// warranty, FD maturity...). Each preset prefills the reminder editor with a
/// reminder kind, how many days ahead to alert and how often it repeats.
/// Names live in the ARB files keyed by [DocumentPreset.key]. Pure data, no
/// Flutter or Drift imports.
library;

import 'reminder_draft.dart';
import 'reminder_kind.dart';

class DocumentPreset {
  const DocumentPreset({
    required this.key,
    required this.kind,
    required this.icon,
    required this.remindDaysBefore,
    required this.repeatChoices,
    this.tracksAmount = false,
    this.projectTemplateKey,
  });

  /// Stable key; resolved to a name by the UI.
  final String key;
  final ReminderKind kind;

  /// Material icon name, resolved by the UI.
  final String icon;

  /// Days before the due date to alert, largest first; 0 is the due day.
  final List<int> remindDaysBefore;

  /// Repeat options this preset suggests; the first is the default.
  final List<ReminderRepeat> repeatChoices;

  /// Whether an amount (premium, tax, maturity value) is worth asking for.
  final bool tracksAmount;

  /// Project template whose projects this reminder naturally belongs to
  /// (a vehicle's PUC), so the editor can suggest one. Null when unrelated.
  final String? projectTemplateKey;

  ReminderRepeat get defaultRepeat => repeatChoices.first;
}

const List<DocumentPreset> documentPresets = [
  DocumentPreset(
    key: 'vehicle_insurance',
    kind: ReminderKind.insurance,
    icon: 'directions_car',
    remindDaysBefore: [30, 15, 7, 1, 0],
    repeatChoices: [ReminderRepeat.yearly],
    tracksAmount: true,
    projectTemplateKey: 'vehicle',
  ),
  DocumentPreset(
    key: 'puc',
    kind: ReminderKind.document,
    icon: 'eco',
    remindDaysBefore: [15, 7, 1, 0],
    // PUC is valid 1 year for BS-IV and newer vehicles, 6 months for older ones.
    repeatChoices: [ReminderRepeat.yearly, ReminderRepeat.halfYearly],
    projectTemplateKey: 'vehicle',
  ),
  DocumentPreset(
    key: 'rc_renewal',
    kind: ReminderKind.document,
    icon: 'badge',
    // Renewal can be filed up to 60 days ahead; private RCs renew every 5 years after the first 15.
    remindDaysBefore: [90, 60, 30, 7, 0],
    repeatChoices: [ReminderRepeat.everyFiveYears, ReminderRepeat.once],
    projectTemplateKey: 'vehicle',
  ),
  DocumentPreset(
    key: 'driving_licence',
    kind: ReminderKind.document,
    icon: 'credit_card',
    remindDaysBefore: [90, 60, 30, 7, 0],
    repeatChoices: [ReminderRepeat.once, ReminderRepeat.everyFiveYears],
  ),
  DocumentPreset(
    key: 'passport',
    kind: ReminderKind.document,
    icon: 'flight',
    // Many countries refuse entry with under six months of validity left.
    remindDaysBefore: [270, 180, 90, 30, 0],
    repeatChoices: [ReminderRepeat.everyTenYears, ReminderRepeat.once],
  ),
  DocumentPreset(
    key: 'health_insurance',
    kind: ReminderKind.insurance,
    icon: 'health_and_safety',
    remindDaysBefore: [30, 15, 7, 1, 0],
    repeatChoices: [ReminderRepeat.yearly],
    tracksAmount: true,
  ),
  DocumentPreset(
    key: 'life_insurance',
    kind: ReminderKind.insurance,
    icon: 'shield',
    remindDaysBefore: [15, 7, 1, 0],
    repeatChoices: [ReminderRepeat.yearly, ReminderRepeat.halfYearly, ReminderRepeat.quarterly, ReminderRepeat.monthly],
    tracksAmount: true,
  ),
  DocumentPreset(key: 'warranty', kind: ReminderKind.document, icon: 'verified', remindDaysBefore: [30, 7, 0], repeatChoices: [ReminderRepeat.once]),
  DocumentPreset(key: 'amc', kind: ReminderKind.bill, icon: 'build', remindDaysBefore: [30, 7, 0], repeatChoices: [ReminderRepeat.yearly], tracksAmount: true),
  DocumentPreset(
    key: 'fd_maturity',
    kind: ReminderKind.document,
    icon: 'savings',
    remindDaysBefore: [7, 1, 0],
    repeatChoices: [ReminderRepeat.once],
    tracksAmount: true,
  ),
  DocumentPreset(
    key: 'property_tax',
    kind: ReminderKind.bill,
    icon: 'home',
    remindDaysBefore: [30, 7, 1, 0],
    repeatChoices: [ReminderRepeat.yearly, ReminderRepeat.halfYearly],
    tracksAmount: true,
  ),
  DocumentPreset(
    key: 'rent_agreement',
    kind: ReminderKind.document,
    icon: 'description',
    // Most Indian rent agreements run 11 months to stay outside compulsory registration.
    remindDaysBefore: [30, 15, 7, 0],
    repeatChoices: [ReminderRepeat.everyElevenMonths, ReminderRepeat.yearly],
  ),
];

DocumentPreset? documentPresetByKey(String? key) {
  for (final preset in documentPresets) {
    if (preset.key == key) return preset;
  }
  return null;
}

/// The project a new reminder from [preset] should link to by default: the
/// only active project made from the preset's template (the one Vehicle
/// project for a PUC). Null when the preset has no template, or when there is
/// none or more than one such project, so the user picks.
String? suggestedPresetProjectId<T>(
  DocumentPreset preset,
  Iterable<T> activeProjects, {
  required String Function(T project) idOf,
  required String? Function(T project) templateKeyOf,
}) {
  final templateKey = preset.projectTemplateKey;
  if (templateKey == null) return null;
  final matches = [
    for (final project in activeProjects)
      if (templateKeyOf(project) == templateKey) idOf(project),
  ];
  return matches.length == 1 ? matches.single : null;
}

/// The draft a preset opens the editor with. [title] is the preset's
/// localised name; the due date is left for the user, so it starts at [today].
/// Money kinds ask for an amount only when the preset tracks one.
ReminderDraft draftFromPreset(DocumentPreset preset, {required String title, required DateTime today, String? projectId}) => ReminderDraft(
  kind: preset.kind,
  title: title,
  dueAt: today,
  repeat: preset.defaultRepeat,
  remindDaysBefore: preset.remindDaysBefore,
  presetKey: preset.key,
  projectId: projectId,
);

/// Repeat options the editor shows: the everyday ones plus whatever the
/// preset suggests (and the current value, so an edited reminder keeps it).
List<ReminderRepeat> repeatOptionsFor({DocumentPreset? preset, ReminderRepeat? current}) {
  final wanted = {...ReminderRepeat.common, ...?preset?.repeatChoices, ?current};
  return [
    for (final repeat in ReminderRepeat.values)
      if (wanted.contains(repeat)) repeat,
  ];
}

/// Days-before options the editor shows: the everyday ones, the preset's
/// lead times and whatever the reminder already has, largest last.
List<int> remindDaysOptionsFor({required List<int> common, DocumentPreset? preset, List<int> current = const []}) =>
    {...common, ...?preset?.remindDaysBefore, ...current}.toList()..sort();
