import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/format.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/backup/scheduled_backup_prefs.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/backup/backup_file_name.dart';
import 'package:hisab/domain/backup/backup_schedule.dart';
import 'package:hisab/domain/backup/scheduled_backup.dart';
import 'package:hisab/features/settings/drive_backup_providers.dart';
import 'package:hisab/features/settings/scheduled_backup_providers.dart';
import 'package:hisab/features/settings/scheduled_backup_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';
import '../data/fake_drive_backup.dart';
import '../data/fake_scheduled_backup.dart';

class _Harness {
  _Harness(this.container, this.folder, this.vault, this.scheduler);
  final ProviderContainer container;
  final FakeBackupFolder folder;
  final FakePassphraseVault vault;
  final FakeBackgroundScheduler scheduler;
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _folder = (uri: 'content://tree/primary%3ABackups', name: 'Backups');

/// Opens Settings, checks the row, then opens the scheduled backup screen.
Future<_Harness> _pumpScheduledBackup(
  WidgetTester tester, {
  ScheduledBackupChoices? choices,
  ScheduledBackupHistory? history,
  String? passphrase,
  void Function(Text subtitle)? checkTile,
}) async {
  SharedPreferences.setMockInitialValues({
    'onboarded': true,
    'currencyCode': 'INR',
    if (choices != null) kScheduledBackupChoicesPref: jsonEncode(choices.toJson()),
    if (history != null) kScheduledBackupHistoryPref: jsonEncode(history.toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  final folder = FakeBackupFolder(picked: _folder);
  final vault = FakePassphraseVault(passphrase);
  final scheduler = FakeBackgroundScheduler();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
    notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
    driveAccountProvider.overrideWithValue(FakeDriveAccount()),
    backupFolderAccessProvider.overrideWithValue(folder),
    backupPassphraseVaultProvider.overrideWithValue(vault),
    backgroundBackupSchedulerProvider.overrideWithValue(scheduler),
    scheduledDriveStoreProvider.overrideWithValue(FakeDriveBackupStore()),
  ]);
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(360, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  appRouter.go('/settings');
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await _settle(tester);
  final tile = find.byKey(const Key('scheduledBackupTile'));
  await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(tile);
  await _settle(tester, 4);
  checkTile?.call(tester.widget<Text>(find.descendant(of: tile, matching: find.byType(Text)).last));
  await tester.tap(tile);
  await _settle(tester);
  return _Harness(container, folder, vault, scheduler);
}

Future<void> _enterPassphrase(WidgetTester tester, String passphrase) async {
  await tester.enterText(find.byType(TextField), passphrase);
  await tester.tap(find.byType(FilledButton).last);
  await _settle(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final english = lookupAppLocalizations(const Locale('en'));
  setUpAll(() => initializeDateFormatting('en'));
  const daily = ScheduledBackupChoices(frequency: BackupFrequency.daily, folderUri: 'content://tree/primary%3ABackups', folderName: 'Backups');

  test('the Settings summary is Off until a schedule is set, then shows the latest run plainly', () {
    expect(scheduledBackupSummary(english, const ScheduledBackupChoices(), const ScheduledBackupHistory()), english.scheduledBackupOff);
    final saved = const ScheduledBackupHistory().record(ScheduledBackupTarget.folder, BackupAttempt(at: DateTime(2026, 10, 29, 9)));
    final failed = saved.record(ScheduledBackupTarget.folder, BackupAttempt(at: DateTime(2026, 10, 30, 9), failure: ScheduledBackupFailure.folderUnavailable));
    expect(
      scheduledBackupSummary(english, daily, saved, locale: 'en'),
      english.scheduledBackupSummary(english.backupFrequencyDaily, english.scheduledBackupLast(formatShortDateTime(DateTime(2026, 10, 29, 9), locale: 'en'), 'Backups')),
    );
    expect(
      scheduledBackupSummary(english, daily, failed, locale: 'en'),
      english.scheduledBackupSummary(
        english.backupFrequencyDaily,
        english.scheduledBackupFailed(formatShortDateTime(DateTime(2026, 10, 30, 9), locale: 'en'), english.backupFailureFolderUnavailable),
      ),
    );
    expect(scheduledBackupFailing(daily, saved), isFalse);
    expect(scheduledBackupFailing(daily, failed), isTrue);
    expect(scheduledBackupFailing(const ScheduledBackupChoices(), failed), isFalse);
  });

  testWidgets('turning the schedule on asks for a passphrase and a folder, and starts the background job', (tester) async {
    final harness = await _pumpScheduledBackup(tester, checkTile: (subtitle) => expect(subtitle.data, english.scheduledBackupOff));
    expect(find.text(english.scheduledBackupWhenBackground), findsOneWidget);

    await tester.tap(find.text(english.backupFrequencyWeekly));
    await _settle(tester);
    await _enterPassphrase(tester, 'correct horse');

    expect(harness.vault.passphrase, 'correct horse');
    expect(harness.folder.picks, 1);
    final saved = harness.container.read(scheduledBackupChoicesProvider);
    expect(saved.frequency, BackupFrequency.weekly);
    expect(saved.folderUri, _folder.uri);
    expect(harness.scheduler.enabled, isTrue);
    expect(find.text('Backups'), findsOneWidget);
    expect(find.text(english.scheduledBackupPassphraseSaved), findsOneWidget);
  });

  testWidgets('a dismissed passphrase leaves the schedule off', (tester) async {
    final harness = await _pumpScheduledBackup(tester);
    await tester.tap(find.text(english.backupFrequencyDaily));
    await _settle(tester);
    await tester.tap(find.byType(TextButton).first);
    await _settle(tester);
    expect(harness.container.read(scheduledBackupChoicesProvider).isOn, isFalse);
    expect(harness.folder.picks, 0);
    expect(harness.scheduler.enabled, isNull);
  });

  testWidgets('a failed run shows why, in the Settings row and on the screen', (tester) async {
    final history = const ScheduledBackupHistory()
        .record(ScheduledBackupTarget.folder, BackupAttempt(at: DateTime(2026, 10, 29, 9)))
        .record(ScheduledBackupTarget.folder, BackupAttempt(at: DateTime(2026, 10, 30, 9), failure: ScheduledBackupFailure.noPassphrase));
    final failure = english.scheduledBackupFailed(formatShortDateTime(DateTime(2026, 10, 30, 9), locale: 'en'), english.backupFailureNoPassphrase);
    await _pumpScheduledBackup(
      tester,
      choices: daily,
      history: history,
      checkTile: (subtitle) {
        expect(subtitle.data, contains(failure));
        expect(subtitle.style?.color, Theme.of(tester.element(find.byKey(const Key('scheduledBackupTile')))).colorScheme.error);
      },
    );

    final status = tester.widget<Text>(find.byKey(const Key('scheduledBackupStatus-folder')));
    expect(status.data, failure);
    final error = Theme.of(tester.element(find.byType(ScheduledBackupScreen))).colorScheme.error;
    expect(status.style?.color, error);
    expect(find.text(english.scheduledBackupPassphraseMissing), findsOneWidget);
  });

  testWidgets('Back up now writes an encrypted backup to the folder and shows when', (tester) async {
    final harness = await _pumpScheduledBackup(tester, choices: daily, passphrase: 'correct horse');
    expect(find.text(english.scheduledBackupNone), findsOneWidget);

    await tester.tap(find.byKey(const Key('scheduledBackupNow')));
    await tester.runAsync(() => _settle(tester, 30));
    await _settle(tester);

    final name = harness.folder.files.keys.single;
    expect(isHisabBackupName(name), isTrue);
    expect(find.text(english.scheduledBackupSaved), findsOneWidget);
    final lastSuccess = harness.container.read(scheduledBackupHistoryProvider).lastSuccess[ScheduledBackupTarget.folder]!;
    expect(lastSuccess.detail, name);
    expect(find.text(english.scheduledBackupLast(formatShortDateTime(lastSuccess.at, locale: 'en'), 'Backups')), findsOneWidget);
  });

  testWidgets('choosing the folder again after a failure backs up there at once', (tester) async {
    final history = const ScheduledBackupHistory().record(ScheduledBackupTarget.folder, BackupAttempt(at: DateTime.now(), failure: ScheduledBackupFailure.folderUnavailable));
    final harness = await _pumpScheduledBackup(tester, choices: daily, history: history, passphrase: 'correct horse');

    await tester.tap(find.byKey(const Key('backupFolderTile')));
    await tester.runAsync(() => _settle(tester, 30));
    await _settle(tester);

    expect(harness.folder.picks, 1);
    expect(isHisabBackupName(harness.folder.files.keys.single), isTrue);
    expect(harness.container.read(scheduledBackupHistoryProvider).lastAttempt[ScheduledBackupTarget.folder]!.succeeded, isTrue);
    expect(find.text(english.scheduledBackupSaved), findsOneWidget);
  });
}
