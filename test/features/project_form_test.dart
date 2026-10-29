import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/projects/project_templates.dart';

import '../support/app_harness.dart' show enter, settle;
import '../support/screen_harness.dart';
import '../support/app_harness.dart' show createContainer;
import 'projects_screen_test.dart' show seedProject;

Finder _field(String label) => find.widgetWithText(TextField, label);

/// Opens the date picker from the tile labelled [tileLabel], picks [day] of
/// the shown month and confirms.
Future<void> _pickDay(WidgetTester tester, String tileLabel, String day) async {
  await tapAndSettle(tester, find.text(tileLabel));
  await tester.tap(find.text(day).last);
  await tester.pump();
  await tapAndSettle(tester, find.text('OK'));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a blank project saves with its budget, dates, colour, icon and notes, then opens', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/projects/new/blank');

    await tapAndSettle(tester, find.text('Save'));
    expect(await tester.runAsync(() => container.read(projectsRepositoryProvider).getAll()), isEmpty, reason: 'a project needs a name');

    await enter(tester, _field('Project name'), '  Car  ');
    await enter(tester, _field('Budget (optional)'), '0');
    await tapAndSettle(tester, find.text('Save'));
    expect(await tester.runAsync(() => container.read(projectsRepositoryProvider).getAll()), isEmpty, reason: 'a zero budget is rejected');

    await enter(tester, _field('Budget (optional)'), '5000');
    await _pickDay(tester, 'Start date', '10');
    await _pickDay(tester, 'End date', '20');
    expect(find.text('Not set'), findsNothing);

    await _pickDay(tester, 'Start date', '25');
    expect(find.text('Not set'), findsOneWidget, reason: 'an end before the new start is cleared');
    await _pickDay(tester, 'End date', '28');

    await tester.tap(find.byType(CircleAvatar).at(2));
    await tester.pump();
    await tapAndSettle(tester, find.byType(IconButton).at(3));
    await enter(tester, _field('Notes'), '  Monthly car costs ');
    await tapAndSettle(tester, find.text('Save'));

    final project = (await tester.runAsync(() => container.read(projectsRepositoryProvider).getAll()))!.single;
    expect(project.name, 'Car');
    expect(project.budgetMinor, 500000);
    expect(project.notes, 'Monthly car costs');
    expect(project.startDate!.day, 25);
    expect(project.endDate!.day, 28);
    expect(project.color, isNot(0xFF2196F3));
    expect(find.text('Spent so far'), findsNothing, reason: 'the detail screen shows the dates instead');
    expect(find.text('Monthly car costs'), findsOneWidget, reason: 'the new project opens on its detail screen');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cleared dates and a cancelled picker leave the dates unset', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/projects/new/blank');

    await _pickDay(tester, 'Start date', '10');
    await _pickDay(tester, 'End date', '20');
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pump();
    expect(find.text('Not set'), findsNWidgets(2));

    await tapAndSettle(tester, find.text('Start date'));
    await tapAndSettle(tester, find.text('Cancel'));
    expect(find.text('Not set'), findsNWidgets(2));
  });

  testWidgets('a template prefills the form and its suggested categories are added on request', (tester) async {
    final container = await createContainer();
    final categoriesBefore = (await tester.runAsync(() => container.read(categoriesRepositoryProvider).getAll()))!.length;
    await pumpAt(tester, container, '/projects/new');
    await tapAndSettle(tester, find.text('Vehicle'));

    expect(tester.widget<TextField>(_field('Project name')).controller!.text, 'Vehicle');
    expect(find.text('Add suggested categories'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const ValueKey('project.addSuggestedCategories')));
    await tapAndSettle(tester, find.text('Save'));

    final project = (await tester.runAsync(() => container.read(projectsRepositoryProvider).getAll()))!.single;
    expect(project.templateKey, 'vehicle');
    final categoriesAfter = (await tester.runAsync(() => container.read(categoriesRepositoryProvider).getAll()))!.length;
    expect(categoriesAfter, greaterThan(categoriesBefore), reason: 'the vehicle pack was added');
    expect(find.text('Metrics'), findsOneWidget, reason: 'template fields come with the project');
  });

  testWidgets('a template whose categories are all present cannot add them again', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() => container.read(categoriesRepositoryProvider).addPack(templateByKey('construction')!.pack));
    await pumpAt(tester, container, '/projects/new/construction');

    expect(find.text('All suggested categories are already in your list'), findsOneWidget);
    final checkbox = tester.widget<CheckboxListTile>(find.byKey(const ValueKey('project.addSuggestedCategories')));
    expect(checkbox.onChanged, isNull);
    expect(checkbox.value, isFalse);
  });

  testWidgets('editing a project loads its values and saves the changes', (tester) async {
    final container = await createContainer();
    final projectId = (await tester.runAsync(() async {
      final projects = container.read(projectsRepositoryProvider);
      return projects.create(name: 'Car', icon: 'folder', color: 0xFF2196F3, budgetMinor: 250000, startDate: DateTime(2026, 1, 5), endDate: DateTime(2026, 3, 5), notes: 'Old notes');
    }))!;
    await pumpAt(tester, container, '/projects/$projectId');
    await tapAndSettle(tester, find.byTooltip('Edit'));

    expect(find.text('Edit project'), findsOneWidget);
    expect(tester.widget<TextField>(_field('Project name')).controller!.text, 'Car');
    expect(tester.widget<TextField>(_field('Budget (optional)')).controller!.text, '2500');
    expect(find.text('Add suggested categories'), findsNothing);

    await enter(tester, _field('Project name'), 'Bike');
    await enter(tester, _field('Budget (optional)'), '');
    await tapAndSettle(tester, find.text('Save'));

    final project = (await tester.runAsync(() => container.read(projectsRepositoryProvider).byId(projectId)))!;
    expect(project.name, 'Bike');
    expect(project.budgetMinor, isNull);
    expect(project.notes, 'Old notes');
    expect(project.startDate, DateTime(2026, 1, 5));
    expect(find.text('Bike'), findsOneWidget, reason: 'saving goes back to the detail screen');
  });

  testWidgets('editing a project that no longer exists shows an empty form', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() => seedProject(container, 'Car'));
    await pumpAt(tester, container, '/projects/missing/edit');

    expect(find.text('Edit project'), findsOneWidget);
    expect(tester.widget<TextField>(_field('Project name')).controller!.text, isEmpty);
    await settle(tester);
  });
}
