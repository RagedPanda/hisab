import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/projects/project_fields.dart';
import 'package:hisab/domain/projects/project_metrics.dart';
import 'package:hisab/domain/projects/project_templates.dart';
import 'package:hisab/features/projects/project_field_inputs.dart';
import 'package:hisab/features/projects/project_field_labels.dart';
import 'package:hisab/features/projects/project_fields_section.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

import '../support/app_harness.dart' show enter, settle;
import '../support/screen_harness.dart';
import 'groups_screen_test.dart' show createContainer;

const _moneyFormat = MoneyFormat.inr;

/// A stored field row, as the repository would return it.
ProjectField _field(String key, ProjectFieldType type, {ProjectFieldScope scope = ProjectFieldScope.entry, String? unit, List<String> choices = const [], String label = '', double? number, String? text}) =>
    ProjectField(
      updatedAt: DateTime(2026, 10, 1),
      id: 'id-$key',
      projectId: 'project',
      key: key,
      label: label,
      type: type.name,
      unit: unit,
      choices: encodeChoices(choices),
      sortOrder: 0,
      scope: scope.name,
      numberValue: number,
      textValue: text,
    );

/// Shows [child] in a localised app at phone size.
Future<void> _pumpLocalised(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ));
  await tester.pump();
}

/// Inputs for [fields] that keep their own values, so each change feeds back
/// like the entry editor does; [onChanged] sees every reported map.
class _InputsHost extends StatefulWidget {
  const _InputsHost({required this.fields, required this.initial, required this.onChanged});
  final List<ProjectField> fields;
  final Map<String, FieldReading> initial;
  final ValueChanged<Map<String, FieldReading>> onChanged;

  @override
  State<_InputsHost> createState() => _InputsHostState();
}

class _InputsHostState extends State<_InputsHost> {
  late Map<String, FieldReading> _values = widget.initial;

  @override
  Widget build(BuildContext context) => ProjectFieldInputs(
        fields: widget.fields,
        values: _values,
        onChanged: (values) {
          setState(() => _values = values);
          widget.onChanged(values);
        },
      );
}

Future<String> _seedTemplateProject(ProviderContainer container, String templateKey) =>
    container.read(projectsRepositoryProvider).create(name: 'Site', icon: 'folder', color: 0xFF2196F3, templateKey: templateKey);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('metrics section', () {
    testWidgets('shows a hint until entries record values', (tester) async {
      await _pumpLocalised(tester, ProjectMetricsSection(metrics: const ProjectMetrics(), fields: [_field('odometer', ProjectFieldType.number, unit: 'km')], moneyFormat: _moneyFormat));
      expect(find.text('Metrics'), findsOneWidget);
      expect(find.textContaining('Fill in project details'), findsOneWidget);
    });

    testWidgets('lists every metric the fields allow and a breakdown per choice field', (tester) async {
      final fields = [
        _field('odometer', ProjectFieldType.number, unit: 'km'),
        _field('litres', ProjectFieldType.number, unit: 'L'),
        _field('built_up_area', ProjectFieldType.number, scope: ProjectFieldScope.project, unit: 'sq ft', number: 1000),
        _field('travellers', ProjectFieldType.number, scope: ProjectFieldScope.project, number: 4),
        _field('stage', ProjectFieldType.choice, choices: constructionStages),
      ];
      const metrics = ProjectMetrics(
        distance: DistanceCost(distance: 500, costMinor: 500000),
        fuel: FuelSummary(litres: 40, costMinor: 400000),
        perAreaMinor: 150000,
        area: 1000,
        perTravellerMinor: 250000,
        breakdowns: [
          ChoiceBreakdown(fieldKey: 'stage', byOption: {'foundation': 300000, 'plinth': 100000}, unassignedMinor: 50000),
          ChoiceBreakdown(fieldKey: 'gone', byOption: {'x': 1}, unassignedMinor: 0),
        ],
      );
      await _pumpLocalised(tester, ProjectMetricsSection(metrics: metrics, fields: fields, moneyFormat: _moneyFormat));

      expect(find.byKey(const ValueKey('metric.costPerKm')), findsOneWidget);
      expect(find.text('500 km driven'), findsOneWidget);
      expect(find.text('Fuel bought'), findsOneWidget);
      expect(find.byKey(const ValueKey('metric.perLitre')), findsOneWidget);
      expect(find.byKey(const ValueKey('metric.perSqFt')), findsOneWidget);
      expect(find.text('over 1000 sq ft'), findsOneWidget);
      expect(find.text('4 travellers'), findsOneWidget);
      expect(find.text('Spending by Stage'), findsOneWidget);
      expect(find.text('Foundation'), findsOneWidget);
      expect(find.text('Not picked'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3), reason: 'the breakdown for a deleted field is left out');
    });
  });

  group('field inputs', () {
    testWidgets('each field type reports its value whole', (tester) async {
      final fields = [
        _field('odometer', ProjectFieldType.number, unit: 'km'),
        _field('vendor', ProjectFieldType.text),
        _field('custom_due', ProjectFieldType.date, label: 'Due'),
        _field('stage', ProjectFieldType.choice, choices: ['foundation', 'plinth']),
        _field('quantity', ProjectFieldType.unit, choices: ['bag', 'kg']),
      ];
      final reported = <Map<String, FieldReading>>[];
      await _pumpLocalised(tester, _InputsHost(fields: fields, initial: const {'odometer': FieldReading(number: 1200), 'vendor': FieldReading(text: 'Ravi')}, onChanged: reported.add));

      expect(tester.widget<TextField>(find.byKey(const ValueKey('field.odometer'))).controller!.text, '1200');
      expect(tester.widget<TextField>(find.byKey(const ValueKey('field.vendor'))).controller!.text, 'Ravi');

      await tester.enterText(find.byKey(const ValueKey('field.odometer')), '1500');
      expect(reported.last['odometer']!.number, 1500);
      await tester.enterText(find.byKey(const ValueKey('field.vendor')), 'Mohan');
      expect(reported.last['vendor']!.text, 'Mohan');
      expect(reported.last['odometer']!.number, 1500, reason: 'other values are kept');

      await tester.tap(find.byKey(const ValueKey('field.custom_due')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(reported.last['custom_due']!.date, isNotNull);
      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(reported.last['custom_due']!.date, isNull);
      await tester.tap(find.byKey(const ValueKey('field.custom_due')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(reported.last['custom_due']!.date, isNull, reason: 'a cancelled picker changes nothing');

      await tester.tap(find.text('Plinth'));
      await tester.pump();
      expect(reported.last['stage']!.text, 'plinth');
      await tester.tap(find.text('Plinth'));
      await tester.pump();
      expect(reported.last['stage']!.text, isNull, reason: 'tapping the picked chip again clears it');

      await tester.enterText(find.byKey(const ValueKey('field.quantity')), '5');
      await tester.enterText(find.byKey(const ValueKey('field.quantity')), '');
      expect(reported.last['quantity']!.isEmpty, isTrue, reason: 'a unit alone records nothing');
      await tester.enterText(find.byKey(const ValueKey('field.quantity')), '12');
      expect((reported.last['quantity']!.number, reported.last['quantity']!.text), (12, 'bag'));
      await tester.tap(find.byKey(const ValueKey('field.quantity.unit')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('kg').last);
      await tester.pumpAndSettle();
      expect((reported.last['quantity']!.number, reported.last['quantity']!.text), (12, 'kg'));
    });

    testWidgets('a stored unit reading is shown with its unit picked', (tester) async {
      final fields = [_field('quantity', ProjectFieldType.unit, choices: ['bag', 'kg']), _field('custom_on', ProjectFieldType.date, label: 'On')];
      await _pumpLocalised(tester, _InputsHost(fields: fields, initial: {'quantity': const FieldReading(number: 3, text: 'kg'), 'custom_on': FieldReading(date: DateTime(2026, 5, 4))}, onChanged: (_) {}));
      expect(tester.widget<TextField>(find.byKey(const ValueKey('field.quantity'))).controller!.text, '3');
      expect(find.text('kg'), findsOneWidget);
      expect(find.textContaining('4 May'), findsOneWidget);
    });
  });

  group('labels', () {
    testWidgets('template and custom fields, options and types are named', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        }),
      ));
      for (final key in ['odometer', 'litres', 'built_up_area', 'stage', 'quantity', 'room', 'travellers', 'event', 'vendor']) {
        expect(templateFieldLabel(l10n, key), isNotNull, reason: key);
      }
      expect(templateFieldLabel(l10n, 'custom_1'), isNull);
      expect(projectFieldLabel(l10n, _field('custom_1', ProjectFieldType.text, label: 'Colour')), 'Colour');
      expect(projectFieldLabel(l10n, _field('custom_2', ProjectFieldType.text)), 'custom_2');
      for (final option in [...constructionStages, ...renovationRooms, ...weddingEvents]) {
        expect(choiceLabel(l10n, option), isNot(option), reason: option);
      }
      expect(choiceLabel(l10n, 'Mine'), 'Mine');
      expect([for (final type in ProjectFieldType.values) fieldTypeLabel(l10n, type)], ['Number', 'Text', 'Date', 'Choice', 'Amount with unit']);
    });
  });

  group('fields section on the project screen', () {
    testWidgets('a project-wide value is set, then the field is deleted and restored', (tester) async {
      final container = await createContainer();
      final projectId = (await tester.runAsync(() => _seedTemplateProject(container, 'trip')))!;
      await pumpAt(tester, container, '/projects/$projectId');

      final travellers = find.byKey(const ValueKey('projectField.travellers'));
      await tester.scrollUntilVisible(travellers, 300, scrollable: find.byType(Scrollable).first);
      expect(find.descendant(of: travellers, matching: find.text('Not set')), findsOneWidget);
      await tapAndSettle(tester, travellers);
      await tester.enterText(find.byType(TextField).last, '3');
      await tapAndSettle(tester, find.text('Save'));
      final fields = container.read(projectFieldsRepositoryProvider);
      expect((await tester.runAsync(() => fields.getFields(projectId)))!.single.numberValue, 3);
      expect(find.descendant(of: travellers, matching: find.text('3')), findsOneWidget);

      await tapAndSettle(tester, find.descendant(of: travellers, matching: find.byType(PopupMenuButton<VoidCallback>)));
      await tapAndSettle(tester, find.text('Set value'));
      await tapAndSettle(tester, find.text('Cancel'));
      expect((await tester.runAsync(() => fields.getFields(projectId)))!.single.numberValue, 3, reason: 'cancelling keeps the value');

      await tapAndSettle(tester, find.descendant(of: travellers, matching: find.byType(PopupMenuButton<VoidCallback>)));
      await tapAndSettle(tester, find.text('Delete field'));
      expect(await tester.runAsync(() => fields.getFields(projectId)), isEmpty);
      expect(find.text('Field deleted'), findsOneWidget);
      await tapAndSettle(tester, find.text('Undo'));
      expect((await tester.runAsync(() => fields.getFields(projectId)))!, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a text value is set and entry fields say they are asked on each entry', (tester) async {
      final container = await createContainer();
      final projectId = (await tester.runAsync(() async {
        final projectId = await _seedTemplateProject(container, 'wedding');
        await container.read(projectFieldsRepositoryProvider).addField(projectId: projectId, label: 'Planner', type: ProjectFieldType.text, scope: ProjectFieldScope.project);
        return projectId;
      }))!;
      await pumpAt(tester, container, '/projects/$projectId');

      expect(find.text('Choice · Asked on each entry'), findsOneWidget);
      expect(find.text('Text · Asked on each entry'), findsOneWidget);
      final planner = find.ancestor(of: find.text('Planner'), matching: find.byType(ListTile));
      await tester.scrollUntilVisible(planner, 300, scrollable: find.byType(Scrollable).first);
      await tapAndSettle(tester, planner);
      await tester.enterText(find.byType(TextField).last, 'Asha');
      await tapAndSettle(tester, find.text('Save'));
      expect(find.text('Asha'), findsOneWidget);
    });

    testWidgets('the add field sheet validates, then saves each kind of field', (tester) async {
      final container = await createContainer();
      final projectId = (await tester.runAsync(() => container.read(projectsRepositoryProvider).create(name: 'Plain', icon: 'folder', color: 0xFF2196F3)))!;
      await pumpAt(tester, container, '/projects/$projectId');
      final fields = container.read(projectFieldsRepositoryProvider);

      Future<void> openSheet() => tapAndSettle(tester, find.byKey(const ValueKey('project.addField')));
      Future<void> pickType(String label) async {
        await tapAndSettle(tester, find.byKey(const ValueKey('addField.type')));
        await tapAndSettle(tester, find.text(label).last);
      }

      await openSheet();
      await tapAndSettle(tester, find.byKey(const ValueKey('addField.save')));
      expect(find.text('Give the field a name'), findsOneWidget);
      await enter(tester, find.byKey(const ValueKey('addField.name')), 'Mileage');
      expect(find.text('Give the field a name'), findsNothing, reason: 'typing clears the error');
      await enter(tester, find.widgetWithText(TextField, 'Unit (optional)'), 'mi');
      await tapAndSettle(tester, find.text('One value for the project'));
      await tapAndSettle(tester, find.byKey(const ValueKey('addField.save')));
      var saved = (await tester.runAsync(() => fields.getFields(projectId)))!;
      expect((saved.single.label, saved.single.unit, saved.single.scope), ('Mileage', 'mi', 'project'));

      await openSheet();
      await enter(tester, find.byKey(const ValueKey('addField.name')), 'Phase');
      await pickType('Choice');
      expect(find.text('One value for the project'), findsNothing, reason: 'choice fields are always per entry');
      await tapAndSettle(tester, find.byKey(const ValueKey('addField.save')));
      expect(find.text('Add at least one option'), findsOneWidget);
      await enter(tester, find.byKey(const ValueKey('addField.options')), 'One, Two');
      expect(find.text('Add at least one option'), findsNothing);
      await tapAndSettle(tester, find.byKey(const ValueKey('addField.save')));
      saved = (await tester.runAsync(() => fields.getFields(projectId)))!;
      expect(saved.last.choices, encodeChoices(['One', 'Two']));
      expect(saved.last.scope, 'entry');

      await openSheet();
      await enter(tester, find.byKey(const ValueKey('addField.name')), 'Paid on');
      await pickType('Date');
      await tapAndSettle(tester, find.byKey(const ValueKey('addField.save')));
      saved = (await tester.runAsync(() => fields.getFields(projectId)))!;
      expect((saved.last.type, saved.last.unit), ('date', null));

      await openSheet();
      await enter(tester, find.byKey(const ValueKey('addField.name')), 'Note');
      await pickType('Text');
      await enter(tester, find.byKey(const ValueKey('addField.name')), 'Note2');
      await tapAndSettle(tester, find.byKey(const ValueKey('addField.save')));
      saved = (await tester.runAsync(() => fields.getFields(projectId)))!;
      expect((saved.last.label, saved.last.type), ('Note2', 'text'));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
