import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/domain/projects/project_math.dart';
import 'package:hisab/features/dashboard/widgets/category_donut.dart';
import 'package:hisab/features/projects/project_picker_sheet.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart' show settle;
import '../support/screen_harness.dart';
import '../support/app_harness.dart' show createContainer;
import 'projects_screen_test.dart' show seedProject;

/// Records an expense of [amountMinor] on [projectId] in the first category
/// whose seed key is [seedKey], [monthsAgo] months back.
Future<void> _seedExpense(ProviderContainer container, String projectId, int amountMinor, {required String seedKey, int monthsAgo = 0, String kind = 'expense', String note = ''}) async {
  final category = await container.read(categoriesRepositoryProvider).findBySeedKey(seedKey);
  final now = DateTime.now();
  await container.read(entriesRepositoryProvider).saveEntry(EntriesRepository.newExpense(
        amountMinor: amountMinor,
        occurredAt: DateTime(now.year, now.month - monthsAgo, 3, 10),
        categoryId: category?.id,
        projectId: projectId,
        kind: kind,
        note: note,
      ));
}

Future<ProjectStatus?> _statusOf(WidgetTester tester, ProviderContainer container, String projectId) async {
  final project = await tester.runAsync(() => container.read(projectsRepositoryProvider).byId(projectId));
  return project == null ? null : ProjectStatus.values.byName(project.status);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('spend is shown by category and month, and a donut slice filters the entries', (tester) async {
    final container = await createContainer();
    final projectId = (await tester.runAsync(() async {
      final now = DateTime.now();
      final projectId = await container.read(projectsRepositoryProvider).create(
            name: 'Car',
            icon: 'directions_car',
            color: 0xFF2196F3,
            budgetMinor: 100000,
            startDate: DateTime(now.year, now.month - 2, 1),
            endDate: DateTime(now.year, now.month + 1, 1),
            notes: 'Family car',
          );
      await _seedExpense(container, projectId, 150000, seedKey: 'food', note: 'Lunch trip');
      await _seedExpense(container, projectId, 20000, seedKey: 'transport', monthsAgo: 1, note: 'Fuel fill');
      await _seedExpense(container, projectId, 5000, seedKey: 'salary', kind: 'income', note: 'Refund');
      return projectId;
    }))!;
    await pumpAt(tester, container, '/projects/$projectId');

    expect(find.text('Car'), findsOneWidget);
    expect(find.textContaining(' – '), findsOneWidget, reason: 'both dates are shown as a range');
    expect(find.text('Family car'), findsOneWidget);
    expect(find.textContaining('came back'), findsOneWidget);
    expect(find.textContaining('Over ₹1,000 by'), findsOneWidget);
    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('Spending by month'), findsOneWidget);

    final donut = tester.widget<CategoryDonut>(find.byType(CategoryDonut));
    final foodShare = donut.data.shares.firstWhere((share) => share.minor == 150000);
    donut.onSliceTap!(foodShare);
    await settle(tester);
    await tester.scrollUntilVisible(find.byType(InputChip), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Lunch trip'), findsOneWidget);
    expect(find.text('Fuel fill'), findsNothing, reason: 'only the picked category is listed');

    tester.widget<InputChip>(find.byType(InputChip)).onDeleted!();
    await settle(tester);
    expect(find.byType(InputChip), findsNothing);
    await tester.scrollUntilVisible(find.text('Fuel fill'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Fuel fill'), findsOneWidget);

    await tapAndSettle(tester, find.text('Fuel fill'));
    expect(appRouter.state.uri.path, '/entry');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a start date alone reads "since", an end date alone reads "until"', (tester) async {
    final container = await createContainer();
    final ids = (await tester.runAsync(() async {
      final projects = container.read(projectsRepositoryProvider);
      final since = await projects.create(name: 'Since', icon: 'folder', color: 0xFF2196F3, startDate: DateTime(2026, 1, 5));
      final until = await projects.create(name: 'Until', icon: 'folder', color: 0xFF2196F3, endDate: DateTime(2026, 1, 5));
      return (since, until);
    }))!;
    await pumpAt(tester, container, '/projects/${ids.$1}');
    expect(find.textContaining('Since '), findsOneWidget);

    appRouter.go('/projects/${ids.$2}');
    await settle(tester);
    expect(find.textContaining('Until '), findsOneWidget);
  });

  testWidgets('the menu completes, reopens and archives with undo', (tester) async {
    final container = await createContainer();
    final projectId = (await tester.runAsync(() => seedProject(container, 'Car')))!;
    await pumpAt(tester, container, '/projects/$projectId');

    Future<void> pickFromMenu(String label) async {
      await tapAndSettle(tester, find.byType(PopupMenuButton<VoidCallback>).first);
      await tapAndSettle(tester, find.text(label));
    }

    await pickFromMenu('Mark completed');
    expect(await _statusOf(tester, container, projectId), ProjectStatus.completed);
    expect(find.text('Marked completed'), findsOneWidget);
    await tapAndSettle(tester, find.text('Undo'));
    expect(await _statusOf(tester, container, projectId), ProjectStatus.active);

    await pickFromMenu('Archive');
    expect(await _statusOf(tester, container, projectId), ProjectStatus.archived);
    await settle(tester, 80);
    await tapAndSettle(tester, find.byType(PopupMenuButton<VoidCallback>).first);
    expect(find.text('Archive'), findsNothing, reason: 'an archived project cannot be archived again');
    await tapAndSettle(tester, find.text('Reopen'));
    expect(await _statusOf(tester, container, projectId), ProjectStatus.active);
    expect(find.text('Project reopened'), findsOneWidget);
  });

  testWidgets('deleting asks first, goes back and can be undone', (tester) async {
    final container = await createContainer();
    final projectId = (await tester.runAsync(() => seedProject(container, 'Car')))!;
    await pumpAt(tester, container, '/projects');
    await tapAndSettle(tester, find.text('Car'));

    await tapAndSettle(tester, find.byType(PopupMenuButton<VoidCallback>).first);
    await tapAndSettle(tester, find.text('Delete project'));
    await tapAndSettle(tester, find.text('Cancel'));
    expect(await tester.runAsync(() => container.read(projectsRepositoryProvider).getAll()), hasLength(1));

    await tapAndSettle(tester, find.byType(PopupMenuButton<VoidCallback>).first);
    await tapAndSettle(tester, find.text('Delete project'));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));
    expect(await tester.runAsync(() => container.read(projectsRepositoryProvider).getAll()), isEmpty);
    expect(find.text('Project deleted'), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget, reason: 'deleting goes back to the list');

    await tapAndSettle(tester, find.text('Undo'));
    expect((await tester.runAsync(() => container.read(projectsRepositoryProvider).byId(projectId)))!.deletedAt, isNull);
  });

  testWidgets('a deleted project shows a not-found state', (tester) async {
    final container = await createContainer();
    final projectId = (await tester.runAsync(() async {
      final projectId = await seedProject(container, 'Car');
      await container.read(projectsRepositoryProvider).delete(projectId);
      return projectId;
    }))!;
    await pumpAt(tester, container, '/projects/$projectId');
    expect(find.text('This project was deleted'), findsOneWidget);
  });

  testWidgets('the add entry button opens the editor on this project', (tester) async {
    final container = await createContainer();
    final projectId = (await tester.runAsync(() => seedProject(container, 'Car')))!;
    await pumpAt(tester, container, '/projects/$projectId');
    await tapAndSettle(tester, find.byType(FloatingActionButton));
    expect(appRouter.state.uri.queryParameters['project'], projectId);
    await settle(tester);
  });

  group('project picker', () {
    testWidgets('lists active projects and returns the picked one', (tester) async {
      final container = await createContainer();
      final ids = (await tester.runAsync(() async => (await seedProject(container, 'Car'), await seedProject(container, 'Done', status: ProjectStatus.completed))))!;
      await pumpAt(tester, container, '/projects');
      final pending = showProjectPicker(tester.element(find.byType(FloatingActionButton)), selectedId: ids.$1);
      await settle(tester);

      expect(find.text('Choose project'), findsOneWidget);
      expect(find.byKey(ValueKey('project.option.${ids.$2}')), findsNothing, reason: 'completed projects are not offered');
      expect(find.descendant(of: find.byKey(ValueKey('project.option.${ids.$1}')), matching: find.byIcon(Icons.check)), findsOneWidget);
      await tapAndSettle(tester, find.byKey(ValueKey('project.option.${ids.$1}')));
      expect((await pending)!.projectId, ids.$1);
    });

    testWidgets('with no projects it offers only "none" under its own label', (tester) async {
      final container = await createContainer();
      await pumpAt(tester, container, '/projects');
      final pending = showProjectPicker(tester.element(find.byType(FloatingActionButton)), noneLabel: 'Any project');
      await settle(tester);

      expect(find.text('Any project'), findsOneWidget);
      expect(find.textContaining('No active projects'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('project.none')), matching: find.byIcon(Icons.check)), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const ValueKey('project.none')));
      final choice = await pending;
      expect(choice, isNotNull);
      expect(choice!.projectId, isNull);
    });
  });
}
