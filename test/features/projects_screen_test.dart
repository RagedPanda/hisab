import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/projects/project_math.dart';
import 'package:hisab/domain/projects/project_templates.dart';
import 'package:hisab/features/projects/project_template_labels.dart';
import 'package:hisab/l10n/generated/app_localizations_en.dart';

import '../support/app_harness.dart' show settle;
import '../support/screen_harness.dart';
import 'groups_screen_test.dart' show createContainer;

/// Creates a project named [name] with [budgetMinor] and moves it to [status].
Future<String> seedProject(ProviderContainer container, String name, {int? budgetMinor, ProjectStatus status = ProjectStatus.active}) async {
  final projects = container.read(projectsRepositoryProvider);
  final projectId = await projects.create(name: name, icon: 'folder', color: 0xFF2196F3, budgetMinor: budgetMinor);
  if (status != ProjectStatus.active) await projects.setStatus(projectId, status);
  return projectId;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('with no projects the list shows the empty state and starting one opens the templates', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/projects');

    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.byTooltip('Show archived'), findsNothing, reason: 'nothing is archived, so there is nothing to reveal');
    await tapAndSettle(tester, find.text('Start a project'));

    expect(find.text('Blank project'), findsOneWidget);
    expect(find.text('Start from a template'), findsOneWidget);
    expect(find.text('Vehicle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('projects are grouped by status and archived ones show only on request', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() async {
      await seedProject(container, 'Car', budgetMinor: 1000000);
      await seedProject(container, 'Kitchen', status: ProjectStatus.completed);
      await seedProject(container, 'Old trip', status: ProjectStatus.archived);
    });
    await pumpAt(tester, container, '/projects');

    expect(find.text('Car'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Old trip'), findsNothing, reason: 'archived projects are hidden by default');
    expect(find.text('₹10,000 of ₹10,000 left · No entries'), findsOneWidget);
    expect(find.text('No budget set · No entries'), findsOneWidget);
    expect(find.text('Completed'), findsNWidgets(2), reason: 'a section header and the status chip');

    await tapAndSettle(tester, find.byTooltip('Show archived'));
    expect(find.text('Old trip'), findsOneWidget);
    expect(find.text('Archived'), findsNWidgets(2));

    await tapAndSettle(tester, find.byTooltip('Hide archived'));
    expect(find.text('Old trip'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a project card opens its detail screen', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() => seedProject(container, 'Car'));
    await pumpAt(tester, container, '/projects');

    await tapAndSettle(tester, find.text('Car'));
    expect(find.text('Spent so far'), findsOneWidget);
    expect(find.text('Nothing spent yet'), findsOneWidget);
  });

  testWidgets('the new project button opens the templates and a blank project opens an empty form', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/projects');

    await tapAndSettle(tester, find.byType(FloatingActionButton));
    await tapAndSettle(tester, find.text('Blank project'));

    expect(find.widgetWithText(TextField, 'Project name'), findsOneWidget);
    expect(find.text('Add suggested categories'), findsNothing, reason: 'a blank project has no category pack');
    expect(find.text('New project'), findsOneWidget);
    await settle(tester);
  });

  test('every template has a name and a hint, and an unknown one falls back to its key', () {
    final l10n = AppLocalizationsEn();
    for (final template in projectTemplates) {
      expect(templateName(l10n, template), isNot(template.key), reason: template.key);
      expect(templateHint(l10n, template), isNotEmpty, reason: template.key);
    }
    const unknown = ProjectTemplate(key: 'garden', icon: 'yard', color: 0xFF4CAF50, packKey: 'garden', fields: []);
    expect((templateName(l10n, unknown), templateHint(l10n, unknown)), ('garden', ''));
  });
}
