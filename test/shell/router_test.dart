import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/projects/project_form_screen.dart';
import 'package:hisab/features/projects/projects_screen.dart';
import 'package:hisab/features/recurring/recurring_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  for (final (location, screen) in [('/recurring', RecurringScreen), ('/projects', ProjectsScreen)]) {
    testWidgets('$location opens its screen', (tester) async {
      await pumpApp(tester);
      appRouter.push(location);
      await settle(tester);
      expect(find.byType(screen), findsOneWidget);
    });
  }

  testWidgets('a project template link opens the form with that template', (tester) async {
    await pumpApp(tester);
    appRouter.push('/projects/new/vehicle');
    await settle(tester);
    expect(tester.widget<ProjectFormScreen>(find.byType(ProjectFormScreen)).templateKey, 'vehicle');
  });
}
