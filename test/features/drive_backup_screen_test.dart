import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/format.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/settings/drive_backup_providers.dart';
import 'package:hisab/features/settings/drive_backup_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';
import '../data/fake_drive_backup.dart';

class _Harness {
  _Harness(this.container, this.prefs, this.account, this.store);
  final ProviderContainer container;
  final SharedPreferences prefs;
  final FakeDriveAccount account;
  final FakeDriveBackupStore store;
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens Settings, then the Drive backup screen through its tile.
Future<_Harness> _pumpDriveBackup(WidgetTester tester, {String? connectedEmail, FakeDriveBackupStore? store}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR', kDriveBackupEmailPref: ?connectedEmail});
  final prefs = await SharedPreferences.getInstance();
  final account = FakeDriveAccount();
  final driveStore = store ?? FakeDriveBackupStore(now: () => DateTime(2026, 10, 28, 9, 5));
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
    notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
    driveAccountProvider.overrideWithValue(account),
    driveBackupStoreProvider.overrideWithValue(driveStore),
  ]);
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(360, 780));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  appRouter.go('/settings');
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await _settle(tester);
  final tile = find.byKey(const Key('driveBackupTile'));
  await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
  // Lift the tile clear of the bottom navigation bar.
  await tester.ensureVisible(tile);
  await _settle(tester, 4);
  await tester.tap(tile);
  await _settle(tester);
  return _Harness(container, prefs, account, driveStore);
}

Future<void> _enterPassphrase(WidgetTester tester, String passphrase) async {
  await tester.enterText(find.byType(TextField), passphrase);
  await tester.tap(find.byType(FilledButton).last);
  await _settle(tester, 30);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final english = lookupAppLocalizations(const Locale('en'));

  testWidgets('Settings explains why, and the consent screen offers Skip as prominently as Connect', (tester) async {
    await _pumpDriveBackup(tester);
    expect(find.text(english.driveConsentTitle), findsOneWidget);
    expect(find.text(english.driveConsentOffline), findsOneWidget);
    final skip = find.byKey(const Key('driveSkip'));
    final connect = find.byKey(const Key('driveConnect'));
    expect(find.descendant(of: skip, matching: find.text(english.driveSkipForNow)), findsOneWidget);
    expect(find.descendant(of: connect, matching: find.text(english.driveConnect)), findsOneWidget);
    expect(tester.widget(skip).runtimeType, tester.widget(connect).runtimeType, reason: 'same button style');
    expect(tester.getSize(skip), tester.getSize(connect), reason: 'same size');
  });

  testWidgets('Skip goes back to Settings without connecting anything', (tester) async {
    final harness = await _pumpDriveBackup(tester);
    await tester.tap(find.byKey(const Key('driveSkip')));
    await _settle(tester);
    expect(find.byType(DriveBackupScreen), findsNothing);
    expect(find.text(english.driveBackupWhy), findsOneWidget, reason: 'Settings repeats the why line');
    expect(harness.prefs.getString(kDriveBackupEmailPref), isNull);
  });

  testWidgets('Connect shows the account and that Drive has no backup yet', (tester) async {
    final harness = await _pumpDriveBackup(tester);
    await tester.tap(find.byKey(const Key('driveConnect')));
    await _settle(tester);
    expect(find.text(english.driveConnectedAs('asha@example.com')), findsOneWidget);
    expect(find.text(english.driveNoBackupYet), findsOneWidget);
    expect(find.text(english.driveBackUpNow), findsOneWidget);
    expect(harness.prefs.getString(kDriveBackupEmailPref), 'asha@example.com');
  });

  testWidgets('a cancelled sign-in says so and stays on the consent screen', (tester) async {
    final harness = await _pumpDriveBackup(tester);
    harness.account.cancelSignIn = true;
    await tester.tap(find.byKey(const Key('driveConnect')));
    await _settle(tester);
    expect(find.text(english.driveErrorCancelled), findsOneWidget);
    expect(find.byKey(const Key('driveConnect')), findsOneWidget);
    expect(harness.prefs.getString(kDriveBackupEmailPref), isNull);
  });

  testWidgets('connected: shows the last backup time and backs up with a passphrase', (tester) async {
    final store = FakeDriveBackupStore(now: () => DateTime(2026, 10, 28, 9, 5))
      ..bytes = Uint8List(4)
      ..modifiedAt = DateTime(2026, 10, 27, 18, 30);
    final harness = await _pumpDriveBackup(tester, connectedEmail: 'asha@example.com', store: store);
    expect(find.text(english.driveConnectedAs('asha@example.com')), findsOneWidget);
    expect(find.text(english.driveLastBackup(formatShortDateTime(DateTime(2026, 10, 27, 18, 30), locale: 'en'))), findsOneWidget);

    await tester.tap(find.byKey(const Key('driveBackUpNow')));
    await _settle(tester);
    await tester.runAsync(() => _enterPassphrase(tester, 'correct horse'));
    await _settle(tester);
    expect(harness.store.uploads, 1);
    expect(find.text(english.driveBackedUp), findsOneWidget);
    expect(find.text(english.driveLastBackup(formatShortDateTime(DateTime(2026, 10, 28, 9, 5), locale: 'en'))), findsOneWidget);
  });

  testWidgets('connected: restore with no Drive backup says none was found', (tester) async {
    await _pumpDriveBackup(tester, connectedEmail: 'asha@example.com');
    await tester.tap(find.byKey(const Key('driveRestore')));
    await _settle(tester);
    await _enterPassphrase(tester, 'correct horse');
    expect(find.text(english.driveErrorNotFound), findsOneWidget);
  });

  testWidgets('connected: no network shows a clear message instead of the last backup', (tester) async {
    final store = FakeDriveBackupStore()..failWith = const SocketException('Failed host lookup');
    await _pumpDriveBackup(tester, connectedEmail: 'asha@example.com', store: store);
    expect(find.text('${english.driveBackupStatusUnknown} · ${english.driveErrorOffline}'), findsOneWidget);
  });

  testWidgets('connected: Delete Drive copy asks first, then removes it', (tester) async {
    final store = FakeDriveBackupStore()
      ..bytes = Uint8List(4)
      ..modifiedAt = DateTime(2026, 10, 27, 18, 30);
    await _pumpDriveBackup(tester, connectedEmail: 'asha@example.com', store: store);
    await tester.tap(find.byKey(const Key('driveDeleteCopy')));
    await _settle(tester);
    expect(find.text(english.driveDeleteConfirm), findsOneWidget);
    await tester.tap(find.text(english.delete));
    await _settle(tester);
    expect(store.bytes, isNull);
    expect(find.text(english.driveCopyDeleted), findsOneWidget);
    expect(find.text(english.driveNoBackupYet), findsOneWidget);
  });

  testWidgets('connected: Disconnect forgets the account and shows the consent screen again', (tester) async {
    final harness = await _pumpDriveBackup(tester, connectedEmail: 'asha@example.com');
    await tester.tap(find.byKey(const Key('driveDisconnect')));
    await _settle(tester);
    expect(harness.account.disconnected, isTrue);
    expect(harness.prefs.getString(kDriveBackupEmailPref), isNull);
    expect(find.text(english.driveDisconnected), findsOneWidget);
    expect(find.byKey(const Key('driveConnect')), findsOneWidget);
  });
}
