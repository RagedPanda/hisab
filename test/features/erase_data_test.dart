import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/settings/drive_backup_providers.dart';
import 'package:hisab/features/settings/erase_data.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';
import '../data/fake_drive_backup.dart';

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('only the exact confirm word unlocks Erase', () {
    expect(eraseConfirmationMatches('DELETE'), isTrue);
    expect(eraseConfirmationMatches('  DELETE '), isTrue);
    expect(eraseConfirmationMatches('delete'), isFalse);
    expect(eraseConfirmationMatches('DELET'), isFalse);
    expect(eraseConfirmationMatches(''), isFalse);
  });

  test('eraseAllData leaves the database as a fresh install has it', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.seedDefaults();
    final freshCategories = (await db.select(db.categories).get()).length;
    final cash = (await db.select(db.accounts).get()).single;
    await EntriesRepository(db).saveEntry(EntriesRepository.newExpense(amountMinor: 7500, occurredAt: DateTime(2026, 10, 1), accountId: cash.id));

    await db.eraseAllData();

    expect(await db.select(db.entries).get(), isEmpty);
    expect(await db.select(db.categories).get(), hasLength(freshCategories));
    final accounts = await db.select(db.accounts).get();
    expect(accounts.single.name, 'Cash');
    expect(accounts.single.id, isNot(cash.id), reason: 'the old rows are gone, not kept');
  });

  testWidgets('Settings erases everything only after DELETE is typed', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'USD', kDriveBackupEmailPref: 'me@example.com'});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final account = FakeDriveAccount();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
      driveAccountProvider.overrideWithValue(account),
      driveBackupStoreProvider.overrideWithValue(FakeDriveBackupStore(now: () => DateTime(2026, 10, 29))),
    ]);
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    appRouter.go('/settings');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await _settle(tester);
    await EntriesRepository(db).saveEntry(EntriesRepository.newExpense(amountMinor: 7500, occurredAt: DateTime(2026, 10, 1)));

    final tile = find.byKey(const Key('eraseAllDataTile'));
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(tile);
    await _settle(tester, 4);
    await tester.tap(tile);
    await _settle(tester, 4);

    FilledButton eraseButton() => tester.widget<FilledButton>(find.byKey(const Key('eraseConfirmButton')));
    expect(find.text('Erase everything?'), findsOneWidget);
    expect(eraseButton().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('eraseConfirmField')), 'delete');
    await tester.pump();
    expect(eraseButton().onPressed, isNull, reason: 'lower case does not count');

    // Cancel keeps everything.
    await tester.tap(find.text('Cancel'));
    await _settle(tester, 4);
    expect(await db.select(db.entries).get(), hasLength(1));

    await tester.tap(tile);
    await _settle(tester, 4);
    await tester.enterText(find.byKey(const Key('eraseConfirmField')), 'DELETE');
    await tester.pump();
    expect(eraseButton().onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('eraseConfirmButton')));
    await _settle(tester);

    expect(await db.select(db.entries).get(), isEmpty);
    expect(prefs.getString('currencyCode'), isNull);
    expect(container.read(driveBackupEmailProvider), isNull);
    expect(account.disconnected, isTrue);
    expect(find.text('All data erased. Hisab is back to a fresh start.'), findsOneWidget);
    expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/home');
  });
}
