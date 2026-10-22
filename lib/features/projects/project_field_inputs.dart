import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/db/database.dart';
import '../../data/repositories/project_fields_repository.dart';
import '../../domain/projects/project_fields.dart';
import '../../domain/projects/project_templates.dart';
import '../../l10n/l10n.dart';
import 'project_field_labels.dart';

/// Inputs for a project's fields, one per field in its own type: numbers with
/// their unit, text, a date, choice chips, or an amount with a unit picker.
/// Values are reported whole on every change.
class ProjectFieldInputs extends StatefulWidget {
  const ProjectFieldInputs({super.key, required this.fields, required this.values, required this.onChanged});
  final List<ProjectField> fields;
  final Map<String, FieldReading> values;
  final ValueChanged<Map<String, FieldReading>> onChanged;

  @override
  State<ProjectFieldInputs> createState() => _ProjectFieldInputsState();
}

class _ProjectFieldInputsState extends State<ProjectFieldInputs> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controllerFor(ProjectField field) => _controllers.putIfAbsent(field.key, () {
        final reading = widget.values[field.key];
        final usesNumber = field.type == ProjectFieldType.number.name || field.type == ProjectFieldType.unit.name;
        final text = usesNumber ? (reading?.number == null ? '' : formatQuantity(reading!.number!, null)) : (reading?.text ?? '');
        return TextEditingController(text: text);
      });

  /// A unit on its own records nothing; only a number with its unit does.
  FieldReading _unitReading(double? number, String? unit) => number == null ? const FieldReading() : FieldReading(number: number, text: unit);

  void _set(String key, FieldReading reading) => widget.onChanged({...widget.values, key: reading});

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in widget.fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _input(context, field, fieldSpecOf(field)),
          ),
      ],
    );
  }

  Widget _input(BuildContext context, ProjectField field, TemplateField spec) {
    final l10n = context.l10n;
    final label = projectFieldLabel(l10n, field);
    final reading = widget.values[field.key];
    final key = ValueKey('field.${field.key}');
    switch (spec.type) {
      case ProjectFieldType.number:
        return TextField(
          key: key,
          controller: _controllerFor(field),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: spec.unit),
          onChanged: (text) => _set(field.key, FieldReading(number: parseFieldNumber(text))),
        );
      case ProjectFieldType.text:
        return TextField(
          key: key,
          controller: _controllerFor(field),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: label),
          onChanged: (text) => _set(field.key, FieldReading(text: text)),
        );
      case ProjectFieldType.date:
        final date = reading?.date;
        return InputDecorator(
          decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.fromLTRB(12, 4, 0, 4)),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  key: key,
                  style: TextButton.styleFrom(alignment: AlignmentDirectional.centerStart, padding: EdgeInsets.zero),
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: date ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) _set(field.key, FieldReading(date: picked));
                  },
                  child: Text(date == null ? l10n.notSet : formatShortDate(date, locale: Localizations.localeOf(context).toString())),
                ),
              ),
              if (date != null) IconButton(tooltip: l10n.clear, icon: const Icon(Icons.close, size: 18), onPressed: () => _set(field.key, const FieldReading())),
            ],
          ),
        );
      case ProjectFieldType.choice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              key: key,
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final option in spec.choices)
                  ChoiceChip(
                    label: Text(choiceLabel(l10n, option)),
                    selected: reading?.text == option,
                    onSelected: (selected) => _set(field.key, FieldReading(text: selected ? option : null)),
                  ),
              ],
            ),
          ],
        );
      case ProjectFieldType.unit:
        final unit = spec.choices.contains(reading?.text) ? reading!.text : spec.choices.firstOrNull;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: key,
                controller: _controllerFor(field),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: label),
                onChanged: (text) => _set(field.key, _unitReading(parseFieldNumber(text), unit)),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 112,
              child: DropdownButtonFormField<String>(
                key: ValueKey('field.${field.key}.unit'),
                initialValue: unit,
                isExpanded: true,
                items: [for (final option in spec.choices) DropdownMenuItem(value: option, child: Text(option))],
                onChanged: (picked) => _set(field.key, _unitReading(parseFieldNumber(_controllerFor(field).text), picked)),
              ),
            ),
          ],
        );
    }
  }
}
