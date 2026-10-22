/// Project field values and the parsing the field editors share.
/// Pure, no Flutter or Drift imports.
library;

import 'dart:convert';

import 'project_templates.dart';

/// One value an entry recorded for a field. A unit field keeps its number in
/// [number] and its unit in [text].
class FieldReading {
  const FieldReading({this.number, this.text, this.date});
  final double? number;
  final String? text;
  final DateTime? date;

  bool get isEmpty => number == null && (text == null || text!.trim().isEmpty) && date == null;
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

/// A number typed into a field; accepts a decimal comma. Null when blank or unreadable.
double? parseFieldNumber(String text) {
  final cleaned = text.trim().replaceAll(' ', '').replaceAll(',', '.');
  return cleaned.isEmpty ? null : double.tryParse(cleaned);
}

enum NewFieldError { missingName, missingOptions }

/// Why a field the user is adding cannot be saved yet, or null when it can.
NewFieldError? validateNewField({required String label, required ProjectFieldType type, required List<String> choices}) {
  if (label.trim().isEmpty) return NewFieldError.missingName;
  if ((type == ProjectFieldType.choice || type == ProjectFieldType.unit) && choices.isEmpty) return NewFieldError.missingOptions;
  return null;
}
