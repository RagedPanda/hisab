import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/features/dashboard/dashboard_keys.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart' show settle;
import '../support/group_harness.dart';

/// Opens the Groups list on a 360dp phone in [locale].
Future<void> openGroups(WidgetTester tester, ProviderContainer container, String locale) async {
  await container.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: locale));
  await tester.binding.setSurfaceSize(const Size(360, 740));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  appRouter.go('/groups');
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await settle(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  for (final locale in ['en', 'hi']) {
    testWidgets('groups summary shows one total per currency at 360dp in $locale (#131)', (tester) async {
      final container = await createContainer();
      await tester.runAsync(() => seedGroupOwingMe(container, 'Dubai flat with long name', 280000, label: 'AED'));
      await openGroups(tester, container, locale);

      expect(find.text('₹0 · AED 1,400'), findsOneWidget, reason: 'the AED amount is listed beside the app currency, never added to it');
      expect(find.text('₹0'), findsOneWidget, reason: 'nobody owes in AED, so the owe side stays app currency only');
      expect(tester.takeException(), isNull);
      appRouter.go('/home');
      await tester.pump();
    });
  }

  testWidgets('a single-currency groups summary looks as before', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() => seedGroupOwingMe(container, 'Flat', 280000));
    await openGroups(tester, container, 'en');

    expect(find.text('₹1,400'), findsWidgets);
    expect(find.text('₹0'), findsOneWidget, reason: 'the owe side is one plain amount');
    expect(find.textContaining('₹1,400 ·'), findsNothing, reason: 'no other currency is joined on');
    appRouter.go('/home');
    await tester.pump();
  });

  testWidgets('archived groups are left out of the groups summary (#50)', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() async {
      await seedGroupOwingMe(container, 'Flat', 280000);
      final groups = container.read(groupsRepositoryProvider);
      await groups.archiveGroup((await groups.getSummaries()).single.group.id);
    });
    await openGroups(tester, container, 'en');

    expect(find.text('₹0'), findsNWidgets(2), reason: 'the only group is archived, so nothing is owed either way');
    expect(find.text('₹1,400'), findsNothing);
    appRouter.go('/home');
    await tester.pump();
  });

  testWidgets('dashboard groups card lists a group in another currency (#139)', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() => seedGroupOwingMe(container, 'Dubai flat', 280000, label: 'AED'));
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    appRouter.go('/home');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(kGroupsCardKey), 300, scrollable: find.byType(Scrollable).first);
    await settle(tester);

    expect(find.text('You get AED 1,400'), findsOneWidget, reason: 'the AED balance is shown in AED, not dropped from the card');
    expect(find.text('You get ₹0'), findsOneWidget, reason: 'the app currency total stays first');
    expect(tester.takeException(), isNull);
  });
}
