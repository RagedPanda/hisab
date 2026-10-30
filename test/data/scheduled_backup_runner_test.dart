import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/app_backup_service.dart';
import 'package:hisab/data/backup/drive_account.dart';
import 'package:hisab/data/backup/scheduled_backup_channel.dart';
import 'package:hisab/data/backup/scheduled_backup_prefs.dart';
import 'package:hisab/data/backup/scheduled_backup_runner.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/domain/backup/backup_codec.dart';
import 'package:hisab/domain/backup/backup_file_name.dart';
import 'package:hisab/domain/backup/backup_schedule.dart';
import 'package:hisab/domain/backup/scheduled_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_drive_backup.dart';
import 'fake_scheduled_backup.dart';

const _passphrase = 'correct horse';
const _daily = ScheduledBackupChoices(frequency: BackupFrequency.daily, folderUri: 'content://tree/backups', folderName: 'Backups', keep: 2);

void main() {
  // The restore test opens a second in-memory database: the new phone.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase phone;
  late SharedPreferences prefs;

  Future<void> useChoices(ScheduledBackupChoices choices) => writeScheduledBackupChoices(prefs, choices);

  ScheduledBackupRunner runner({FakeBackupFolder? folder, String? passphrase = _passphrase, FakeDriveBackupStore? drive}) => ScheduledBackupRunner(
        backups: appBackupService(phone, prefs),
        folder: folder ?? FakeBackupFolder(),
        vault: FakePassphraseVault(passphrase),
        prefs: prefs,
        driveConnected: drive != null,
        driveStore: drive == null ? null : () => drive,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({'currencyCode': 'INR'});
    prefs = await SharedPreferences.getInstance();
    phone = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => phone.close());

  test('a due backup lands in the folder, restores into a fresh install, and old ones are pruned', () async {
    await useChoices(_daily);
    await phone.into(phone.entries).insert(EntriesRepository.newExpense(id: 'milk', amountMinor: 4500, occurredAt: DateTime(2026, 10, 29), note: 'Gwala Ji'));
    final folder = FakeBackupFolder(files: {
      backupFileName(DateTime(2026, 10, 27)): Uint8List(1),
      backupFileName(DateTime(2026, 10, 28)): Uint8List(1),
      'notes.txt': Uint8List(1),
    });
    final now = DateTime(2026, 10, 30, 10);

    final attempts = await runner(folder: folder).runDue(now);

    final name = backupFileName(now);
    expect(attempts[ScheduledBackupTarget.folder]!.succeeded, isTrue);
    expect(folder.files.keys, unorderedEquals([name, backupFileName(DateTime(2026, 10, 28)), 'notes.txt']));
    final bytes = folder.files[name]!;
    expect(String.fromCharCodes(bytes.take(backupMagic.length)), backupMagic, reason: 'encrypted, never plain JSON');

    final newPhone = AppDatabase(NativeDatabase.memory());
    addTearDown(newPhone.close);
    final restored = await appBackupService(newPhone, prefs).importEncrypted(bytes, _passphrase);
    expect(restored.currencyCode, 'INR');
    expect((await newPhone.select(newPhone.entries).get()).map((entry) => entry.note), ['Gwala Ji']);

    final history = readScheduledBackupHistory(prefs);
    expect(history.lastSuccess[ScheduledBackupTarget.folder]!.at, now);
    expect(history.lastSuccess[ScheduledBackupTarget.folder]!.detail, name);
  });

  test('nothing runs before the next backup is due', () async {
    await useChoices(_daily);
    final folder = FakeBackupFolder();
    await runner(folder: folder).runDue(DateTime(2026, 10, 30, 10));
    folder.files.clear();
    expect(await runner(folder: folder).runDue(DateTime(2026, 10, 30, 22)), isEmpty);
    expect(folder.files, isEmpty);
  });

  test('without a saved passphrase nothing is written and the failure is recorded', () async {
    await useChoices(_daily);
    final folder = FakeBackupFolder();
    final attempts = await runner(folder: folder, passphrase: null).runDue(DateTime(2026, 10, 30, 10));
    expect(attempts[ScheduledBackupTarget.folder]!.failure, ScheduledBackupFailure.noPassphrase);
    expect(folder.files, isEmpty);
  });

  test('a folder that went away is reported, and retried only after an hour', () async {
    await useChoices(_daily);
    final folder = FakeBackupFolder()..failWith = const BackupFolderUnavailableException('gone');
    final now = DateTime(2026, 10, 30, 10);
    final attempts = await runner(folder: folder).runDue(now);
    expect(attempts[ScheduledBackupTarget.folder]!.failure, ScheduledBackupFailure.folderUnavailable);
    expect(await runner(folder: folder).runDue(now.add(const Duration(minutes: 20))), isEmpty);
  });

  test('a schedule without a folder says so', () async {
    await useChoices(const ScheduledBackupChoices(frequency: BackupFrequency.weekly));
    final attempts = await runner().runDue(DateTime(2026, 10, 30, 10));
    expect(attempts[ScheduledBackupTarget.folder]!.failure, ScheduledBackupFailure.noFolder);
  });

  test('the Drive copy is replaced on the same schedule, and a needed sign-in is reported', () async {
    await useChoices(_daily.copyWith(includeDrive: true));
    final drive = FakeDriveBackupStore();
    final folder = FakeBackupFolder();
    await runner(folder: folder, drive: drive).runNow(DateTime(2026, 10, 30, 10));
    expect(drive.uploads, 1);
    expect(drive.bytes, folder.files.values.single, reason: 'one export serves both');

    drive.failWith = const DriveSignInNeededException();
    final attempts = await runner(folder: folder, drive: drive).runDue(DateTime(2026, 10, 31, 10));
    expect(attempts[ScheduledBackupTarget.drive]!.failure, ScheduledBackupFailure.signInNeeded);
    expect(attempts[ScheduledBackupTarget.folder]!.succeeded, isTrue);
  });
}
