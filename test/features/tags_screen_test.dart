import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';
import '../support/editor_harness.dart';
import '../support/seed.dart';

/// Settings → Tags: the list, opening a tag's entries, rename, merge and
/// remove, each with Undo.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Finder tagRow(String tag) => find.byKey(ValueKey('tag.$tag'));
  final renameField = find.byKey(const ValueKey('tagRename.field'));
  final renameSave = find.byKey(const ValueKey('tagRename.save'));

  /// Opens the Tags screen from Settings over entries tagged [tagsByPayee].
  Future<ProviderContainer> openTags(WidgetTester tester, Map<String, String> tagsByPayee) async {
    final container = await pumpApp(tester, seed: (container) async {
      var day = 0;
      for (final MapEntry(key: payee, value: tags) in tagsByPayee.entries) {
        // Spread over past months, so a tag's entries are found beyond this month.
        await seedEntry(container, id: payee, payee: payee, amountMinor: 1000, tags: tags, occurredAt: DateTime.now().subtract(Duration(days: 40 * day++)));
      }
    });
    addTearDown(() => appRouter.go('/home'));
    appRouter.go('/settings');
    await settle(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('settingsTags')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('settingsTags')));
    await settle(tester);
    return container;
  }

  Future<Map<String, String>> tagsOnEntries(WidgetTester tester, ProviderContainer container) async =>
      {for (final entry in await readDb(tester, () => liveEntries(container))) entry.payee!: entry.tags};

  Future<void> openMenu(WidgetTester tester, String tag, String item) async {
    await tester.tap(find.descendant(of: tagRow(tag), matching: find.byType(PopupMenuButton<VoidCallback>)));
    await settle(tester);
    await tester.tap(find.byKey(ValueKey('tag.$item')));
    await settle(tester);
  }

  Future<void> renameTo(WidgetTester tester, String tag, String name) async {
    await openMenu(tester, tag, 'rename');
    await tester.enterText(renameField, name);
    await settle(tester);
    await tester.tap(renameSave);
    await settle(tester);
  }

  testWidgets('with no tags it says how to get some', (tester) async {
    await openTags(tester, {'Chai': ''});
    expect(find.text('No tags yet'), findsOneWidget);
  });

  testWidgets('lists tags most used first with their counts, and a tap opens all their entries', (tester) async {
    await openTags(tester, {'Hotel': 'goa, trip', 'Cab': 'Trip', 'Chai': 'office', 'Flight': 'trip'});
    expect(find.descendant(of: tagRow('trip'), matching: find.text('3 entries')), findsOneWidget);
    expect(find.descendant(of: tagRow('goa'), matching: find.text('1 entry')), findsOneWidget);
    expect(tester.getTopLeft(tagRow('trip')).dy, lessThan(tester.getTopLeft(tagRow('goa')).dy));
    expect(tester.getTopLeft(tagRow('goa')).dy, lessThan(tester.getTopLeft(tagRow('office')).dy), reason: 'equal counts go by name');
    expect(find.byKey(const ValueKey('tags.search')), findsNothing, reason: 'a short list needs no search');

    await tester.tap(tagRow('trip'));
    await settle(tester);
    expect(find.text('#trip'), findsOneWidget, reason: 'the Entries list shows the tag filter');
    expect(find.text('3 results'), findsOneWidget, reason: 'entries from earlier months count too');
    expect(find.text('Chai'), findsNothing);
  });

  testWidgets('rename changes the tag on every entry, and Undo puts it back', (tester) async {
    final container = await openTags(tester, {'Hotel': 'goa, trip', 'Beach': '#Goa'});
    await renameTo(tester, 'goa', '  #Goa   2026 ');
    expect(await tagsOnEntries(tester, container), {'Hotel': 'Goa 2026, trip', 'Beach': 'Goa 2026'});
    expect(find.text('Renamed #goa to #Goa 2026'), findsOneWidget);
    expect(tagRow('Goa 2026'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await tagsOnEntries(tester, container), {'Hotel': 'goa, trip', 'Beach': '#Goa'});
  });

  testWidgets('a name that is not one tag cannot be saved', (tester) async {
    await openTags(tester, {'Hotel': 'goa'});
    await openMenu(tester, 'goa', 'rename');
    await tester.enterText(renameField, 'goa, trip');
    await settle(tester);
    expect(find.text('One tag only, without commas'), findsOneWidget);
    expect(tester.widget<FilledButton>(renameSave).onPressed, isNull);
    await tester.enterText(renameField, '   ');
    await settle(tester);
    expect(tester.widget<FilledButton>(renameSave).onPressed, isNull);
  });

  testWidgets('renaming onto another tag asks to merge, then leaves one tag per entry', (tester) async {
    final container = await openTags(tester, {'Hotel': 'goa, trip', 'Beach': 'goa', 'Cab': 'Trip'});
    await renameTo(tester, 'goa', 'TRIP');
    expect(find.text('Merge into #trip?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect((await tagsOnEntries(tester, container))['Beach'], 'goa', reason: 'Cancel changes nothing');

    await renameTo(tester, 'goa', 'TRIP');
    await tester.tap(find.text('Merge'));
    await settle(tester);
    expect(await tagsOnEntries(tester, container), {'Hotel': 'trip', 'Beach': 'trip', 'Cab': 'Trip'});
    expect(find.descendant(of: tagRow('trip'), matching: find.text('3 entries')), findsOneWidget);
    expect(tagRow('goa'), findsNothing);
    expect(find.text('Merged #goa into #trip'), findsOneWidget);
  });

  testWidgets('remove asks with the count, keeps the entries, and Undo brings the tag back', (tester) async {
    final container = await openTags(tester, {'Hotel': 'goa, trip', 'Cab': 'trip'});
    await openMenu(tester, 'trip', 'remove');
    expect(find.text('Remove #trip from 2 entries?'), findsOneWidget);
    expect(find.text('The entries stay.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await settle(tester);
    expect(await tagsOnEntries(tester, container), {'Hotel': 'goa', 'Cab': ''});
    expect(tagRow('trip'), findsNothing);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await tagsOnEntries(tester, container), {'Hotel': 'goa, trip', 'Cab': 'trip'});
  });

  testWidgets('a long list can be searched', (tester) async {
    await openTags(tester, {for (var index = 0; index < 10; index++) 'Shop $index': 'tag $index${index == 3 ? ', दिवाली' : ''}'});
    await tester.enterText(find.byKey(const ValueKey('tags.search')), '#दिवा');
    await settle(tester);
    expect(tagRow('दिवाली'), findsOneWidget);
    expect(tagRow('tag 3'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('tags.search')), 'zzz');
    await settle(tester);
    expect(find.text('No matching tag'), findsOneWidget);
  });

}
