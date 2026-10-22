import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/project_fields_repository.dart';
import '../../domain/projects/project_fields.dart';
import '../../domain/projects/project_metrics.dart';
import '../../domain/projects/project_templates.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'project_field_labels.dart';

const _sectionPadding = EdgeInsets.fromLTRB(4, 20, 4, 8);

/// Cost per km, fuel, cost per sq ft and per traveller, then spend per
/// stage / room / event. A hint stands in until entries record any values.
class ProjectMetricsSection extends StatelessWidget {
  const ProjectMetricsSection({super.key, required this.metrics, required this.fields, required this.symbol});
  final ProjectMetrics metrics;
  final List<ProjectField> fields;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String money(double minor) => formatMinor(minor.round(), symbol: symbol);
    final distance = metrics.distance;
    final fuel = metrics.fuel;
    final rows = <Widget>[
      if (distance != null)
        _MetricTile(key: const ValueKey('metric.costPerKm'), title: l10n.costPerKm, value: money(distance.perKmMinor), subtitle: l10n.kmDriven(formatQuantity(distance.distance, null))),
      if (fuel != null) ...[
        _MetricTile(title: l10n.fuelBought, value: formatQuantity(fuel.litres, 'L'), subtitle: l10n.litresAmount(formatQuantity(fuel.litres, null), formatMinor(fuel.costMinor, symbol: symbol))),
        _MetricTile(key: const ValueKey('metric.perLitre'), title: l10n.pricePerLitre, value: money(fuel.perLitreMinor)),
      ],
      if (metrics.perAreaMinor != null)
        _MetricTile(key: const ValueKey('metric.perSqFt'), title: l10n.costPerSqFt, value: money(metrics.perAreaMinor!), subtitle: l10n.areaOf(formatQuantity(metrics.area!, null))),
      if (metrics.perTravellerMinor != null)
        _MetricTile(
          title: l10n.costPerTraveller,
          value: money(metrics.perTravellerMinor!),
          subtitle: l10n.travellersCount(_travellers(fields).round()),
        ),
    ];
    final fieldsByKey = {for (final field in fields) field.key: field};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.projectMetrics, padding: _sectionPadding),
        if (rows.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.metricsHint, style: theme.textTheme.bodySmall),
            ),
          )
        else
          Card(clipBehavior: Clip.antiAlias, child: Column(children: rows)),
        for (final breakdown in metrics.breakdowns)
          if (fieldsByKey[breakdown.fieldKey] case final field?) ...[
            SectionHeader(l10n.spendingByField(projectFieldLabel(l10n, field)), padding: _sectionPadding),
            Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: _Breakdown(breakdown: breakdown, symbol: symbol))),
          ],
      ],
    );
  }

  double _travellers(List<ProjectField> fields) => fields.where((field) => field.key == travellersFieldKey).firstOrNull?.numberValue ?? 0;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({super.key, required this.title, required this.value, this.subtitle});
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700).tabular),
    );
  }
}

/// One row per option with its share of the field's spend.
class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.breakdown, required this.symbol});
  final ChoiceBreakdown breakdown;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = [
      for (final MapEntry(:key, :value) in breakdown.byOption.entries) (choiceLabel(l10n, key), value),
      if (breakdown.unassignedMinor > 0) (l10n.notPicked, breakdown.unassignedMinor),
    ];
    final largest = rows.fold<int>(1, (max, row) => row.$2 > max ? row.$2 : max);
    return Column(
      children: [
        for (final (label, amount) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(formatMinor(amount, symbol: symbol, showDecimals: false), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600).tabular),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: amount / largest, minHeight: 6, backgroundColor: theme.colorScheme.surfaceContainerHighest),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The project's fields: project-scope ones show (and set) their value,
/// entry-scope ones say they are asked on each entry. Fields can be added
/// and deleted (with undo).
class ProjectFieldsSection extends ConsumerWidget {
  const ProjectFieldsSection({super.key, required this.projectId, required this.fields});
  final String projectId;
  final List<ProjectField> fields;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repo = ref.read(projectFieldsRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l10n.projectFields,
          padding: _sectionPadding,
          trailing: TextButton.icon(
            key: const ValueKey('project.addField'),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addField),
            onPressed: () => showAddFieldSheet(context, ref, projectId: projectId),
          ),
        ),
        if (fields.isNotEmpty)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final field in fields)
                  ListTile(
                    key: ValueKey('projectField.${field.key}'),
                    title: Text(projectFieldLabel(l10n, field)),
                    subtitle: Text(_subtitle(context, field)),
                    onTap: field.scope == ProjectFieldScope.project.name ? () => _editValue(context, ref, field) : null,
                    trailing: PopupMenuButton<VoidCallback>(
                      onSelected: (action) => action(),
                      itemBuilder: (_) => [
                        if (field.scope == ProjectFieldScope.project.name) PopupMenuItem(value: () => _editValue(context, ref, field), child: Text(l10n.setValue)),
                        PopupMenuItem(
                          value: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await repo.deleteField(field.id);
                            showUndoSnackBar(messenger, message: l10n.fieldDeleted, undoLabel: l10n.undo, onUndo: () => repo.restoreField(field.id));
                          },
                          child: Text(l10n.deleteField),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _subtitle(BuildContext context, ProjectField field) {
    final l10n = context.l10n;
    final spec = fieldSpecOf(field);
    if (spec.scope == ProjectFieldScope.entry) return '${fieldTypeLabel(l10n, spec.type)} · ${l10n.fieldOnEachEntry}';
    if (field.numberValue != null) return formatQuantity(field.numberValue!, spec.unit);
    return field.textValue ?? l10n.notSet;
  }

  Future<void> _editValue(BuildContext context, WidgetRef ref, ProjectField field) async {
    final isNumber = field.type == ProjectFieldType.number.name;
    final current = isNumber ? (field.numberValue == null ? '' : formatQuantity(field.numberValue!, null)) : (field.textValue ?? '');
    final typed = await promptText(
      context,
      title: projectFieldLabel(context.l10n, field),
      initial: current,
      hint: field.unit,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
    );
    if (typed == null) return;
    final repo = ref.read(projectFieldsRepositoryProvider);
    await (isNumber ? repo.setProjectValue(field.id, number: parseFieldNumber(typed)) : repo.setProjectValue(field.id, text: typed));
  }
}

/// Sheet for a custom field: name, type, unit or options, and whether it is
/// asked on each entry or held once for the project.
Future<void> showAddFieldSheet(BuildContext context, WidgetRef ref, {required String projectId}) {
  final nameController = TextEditingController();
  final unitController = TextEditingController();
  final optionsController = TextEditingController();
  var type = ProjectFieldType.number;
  var perProject = false;
  NewFieldError? error;
  final l10n = context.l10n;
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final needsOptions = type == ProjectFieldType.choice || type == ProjectFieldType.unit;
        final canBeProjectWide = type == ProjectFieldType.number || type == ProjectFieldType.text;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(l10n.addField, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('addField.name'),
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => error == NewFieldError.missingName ? setSheetState(() => error = null) : null,
                decoration: InputDecoration(labelText: l10n.fieldName, errorText: error == NewFieldError.missingName ? l10n.errorFieldName : null),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProjectFieldType>(
                key: const ValueKey('addField.type'),
                initialValue: type,
                decoration: InputDecoration(labelText: l10n.fieldType),
                items: [for (final option in ProjectFieldType.values) DropdownMenuItem(value: option, child: Text(fieldTypeLabel(l10n, option)))],
                onChanged: (picked) => setSheetState(() => type = picked ?? type),
              ),
              if (type == ProjectFieldType.number) ...[
                const SizedBox(height: 12),
                TextField(controller: unitController, decoration: InputDecoration(labelText: l10n.fieldUnitOptional)),
              ],
              if (needsOptions) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('addField.options'),
                  controller: optionsController,
                  onChanged: (_) => error == NewFieldError.missingOptions ? setSheetState(() => error = null) : null,
                  decoration: InputDecoration(labelText: l10n.fieldOptions, errorText: error == NewFieldError.missingOptions ? l10n.errorFieldOptions : null),
                ),
              ],
              if (canBeProjectWide)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fieldOncePerProject),
                  value: perProject,
                  onChanged: (value) => setSheetState(() => perProject = value),
                ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('addField.save'),
                onPressed: () async {
                  final choices = needsOptions ? parseChoiceList(optionsController.text) : const <String>[];
                  final problem = validateNewField(label: nameController.text, type: type, choices: choices);
                  if (problem != null) {
                    setSheetState(() => error = problem);
                    return;
                  }
                  await ref.read(projectFieldsRepositoryProvider).addField(
                        projectId: projectId,
                        label: nameController.text,
                        type: type,
                        scope: canBeProjectWide && perProject ? ProjectFieldScope.project : ProjectFieldScope.entry,
                        unit: type == ProjectFieldType.number ? unitController.text : null,
                        choices: choices,
                      );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        );
      },
    ),
  );
}
