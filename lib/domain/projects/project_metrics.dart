/// Per-project figures derived from project fields: cost per km from
/// odometer readings, fuel litres and price per litre, cost per sq ft,
/// cost per traveller and spend per choice (stage, room, event).
/// Pure, no Flutter or Drift imports.
library;

import 'dart:convert';

import 'project_templates.dart';

/// Field keys the metrics understand. Templates use the same keys.
const odometerFieldKey = 'odometer';
const litresFieldKey = 'litres';
const builtUpAreaFieldKey = 'built_up_area';
const travellersFieldKey = 'travellers';

/// One value an entry recorded for a field. A unit field keeps its number in
/// [number] and its unit in [text].
class FieldReading {
  const FieldReading({this.number, this.text, this.date});
  final double? number;
  final String? text;
  final DateTime? date;

  bool get isEmpty => number == null && (text == null || text!.trim().isEmpty) && date == null;
}

/// An entry reduced to what the metrics need.
class MetricEntry {
  const MetricEntry({required this.kind, required this.amountMinor, required this.occurredAt, this.values = const {}});
  final String kind;
  final int amountMinor;
  final DateTime occurredAt;
  final Map<String, FieldReading> values;

  bool get isExpense => kind == 'expense';
  double? numberOf(String key) => values[key]?.number;
}

/// Spend over the distance between the lowest and highest odometer reading.
class DistanceCost {
  const DistanceCost({required this.distance, required this.costMinor});
  final double distance;
  final int costMinor;
  double get perKmMinor => costMinor / distance;
}

class FuelSummary {
  const FuelSummary({required this.litres, required this.costMinor});
  final double litres;
  final int costMinor;
  double get perLitreMinor => costMinor / litres;
}

/// Expense per option of one choice field, in the field's option order.
class ChoiceBreakdown {
  const ChoiceBreakdown({required this.fieldKey, required this.byOption, required this.unassignedMinor});
  final String fieldKey;
  final Map<String, int> byOption;

  /// Expense on entries that did not pick an option.
  final int unassignedMinor;
}

class ProjectMetrics {
  const ProjectMetrics({this.distance, this.fuel, this.perAreaMinor, this.area, this.perTravellerMinor, this.breakdowns = const []});
  final DistanceCost? distance;
  final FuelSummary? fuel;
  final double? perAreaMinor;
  final double? area;
  final double? perTravellerMinor;
  final List<ChoiceBreakdown> breakdowns;

  bool get isEmpty => distance == null && fuel == null && perAreaMinor == null && perTravellerMinor == null && breakdowns.isEmpty;
}

/// Works out every metric the project's [fields] allow. [projectValues]
/// holds the numbers of project-scope fields; [spentMinor] is the project's
/// expense total (the same figure the hero card shows).
ProjectMetrics projectMetrics({
  required List<TemplateField> fields,
  required Map<String, double> projectValues,
  required List<MetricEntry> entries,
  required int spentMinor,
}) {
  final keys = {for (final field in fields) field.key};
  final area = projectValues[builtUpAreaFieldKey];
  final travellers = projectValues[travellersFieldKey];
  return ProjectMetrics(
    distance: keys.contains(odometerFieldKey) ? distanceCost(entries) : null,
    fuel: keys.contains(litresFieldKey) ? fuelSummary(entries) : null,
    area: area,
    perAreaMinor: keys.contains(builtUpAreaFieldKey) && area != null && area > 0 && spentMinor > 0 ? spentMinor / area : null,
    perTravellerMinor: keys.contains(travellersFieldKey) && travellers != null && travellers >= 1 && spentMinor > 0 ? spentMinor / travellers : null,
    breakdowns: [
      for (final field in fields)
        if (field.type == ProjectFieldType.choice && field.scope == ProjectFieldScope.entry) choiceBreakdown(field, entries),
    ].where((breakdown) => breakdown.byOption.isNotEmpty).toList(),
  );
}

/// Tank-to-tank running cost: the distance is the highest odometer reading
/// minus the lowest, and the cost is every expense from the lowest reading
/// up to the highest one, leaving out the entry that carried the lowest
/// reading (that money took the vehicle *to* the start, not past it).
/// Null until two readings span some distance.
DistanceCost? distanceCost(List<MetricEntry> entries) {
  final readings = entries.where((entry) => entry.numberOf(odometerFieldKey) != null).toList()
    ..sort((a, b) {
      final byReading = a.numberOf(odometerFieldKey)!.compareTo(b.numberOf(odometerFieldKey)!);
      return byReading != 0 ? byReading : a.occurredAt.compareTo(b.occurredAt);
    });
  if (readings.length < 2) return null;
  final first = readings.first;
  final last = readings.last;
  final distance = last.numberOf(odometerFieldKey)! - first.numberOf(odometerFieldKey)!;
  if (distance <= 0) return null;
  final cost = entries
      .where((entry) => entry.isExpense && !identical(entry, first) && !entry.occurredAt.isBefore(first.occurredAt) && !entry.occurredAt.isAfter(last.occurredAt))
      .fold<int>(0, (sum, entry) => sum + entry.amountMinor);
  return DistanceCost(distance: distance, costMinor: cost);
}

/// Litres bought and what they cost, over expense entries that recorded litres.
FuelSummary? fuelSummary(List<MetricEntry> entries) {
  final fills = entries.where((entry) => entry.isExpense && (entry.numberOf(litresFieldKey) ?? 0) > 0);
  final litres = fills.fold<double>(0, (sum, entry) => sum + entry.numberOf(litresFieldKey)!);
  if (litres <= 0) return null;
  return FuelSummary(litres: litres, costMinor: fills.fold(0, (sum, entry) => sum + entry.amountMinor));
}

/// Expense per option of [field]. Known options come first in the field's
/// order, then any other recorded value (an option since removed).
ChoiceBreakdown choiceBreakdown(TemplateField field, List<MetricEntry> entries) {
  final totals = <String, int>{};
  var unassigned = 0;
  for (final entry in entries.where((entry) => entry.isExpense)) {
    final option = entry.values[field.key]?.text?.trim();
    if (option == null || option.isEmpty) {
      unassigned += entry.amountMinor;
    } else {
      totals[option] = (totals[option] ?? 0) + entry.amountMinor;
    }
  }
  final ordered = {
    for (final option in field.choices)
      if (totals.containsKey(option)) option: totals[option]!,
    for (final option in totals.keys)
      if (!field.choices.contains(option)) option: totals[option]!,
  };
  return ChoiceBreakdown(fieldKey: field.key, byOption: ordered, unassignedMinor: unassigned);
}

/// Options stored as a JSON array; anything unreadable is no options.
List<String> decodeChoices(String json) {
  try {
    final decoded = jsonDecode(json);
    return decoded is List ? [for (final item in decoded) if (item is String && item.trim().isNotEmpty) item.trim()] : const [];
  } on FormatException {
    return const [];
  }
}

String encodeChoices(List<String> choices) => jsonEncode([for (final choice in choices) if (choice.trim().isNotEmpty) choice.trim()]);

/// Splits a comma-separated list typed by the user into options, dropping
/// blanks and repeats.
List<String> parseChoiceList(String input) => input.split(RegExp(r'[,،\n]')).map((part) => part.trim()).where((part) => part.isNotEmpty).toSet().toList();
