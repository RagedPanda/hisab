import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/backup/drive_account.dart';
import 'package:hisab/data/backup/drive_backup_service.dart';
import 'package:hisab/data/backup/drive_backup_store.dart';
import 'package:hisab/data/backup/drive_rest_backup_store.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/domain/backup/backup_codec.dart';
import 'package:http/http.dart' as http;

import 'fake_drive_backup.dart';

void main() {
  // Each test opens two in-memory databases: the old phone and the new one.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const passphrase = 'correct horse';
  final older = DateTime(2026, 10, 1);
  final newer = DateTime(2026, 10, 20);
  late AppDatabase phone;
  late AppDatabase newPhone;
  late FakeDriveBackupStore drive;

  setUp(() {
    phone = AppDatabase(NativeDatabase.memory());
    newPhone = AppDatabase(NativeDatabase.memory());
    drive = FakeDriveBackupStore(now: () => DateTime(2026, 10, 28, 9));
  });
  tearDown(() async {
    await phone.close();
    await newPhone.close();
  });

  DriveBackupService serviceFor(AppDatabase db) => DriveBackupService(backups: BackupService(db), store: drive);

  Future<void> addExpense(AppDatabase db, String id, {required String note, required DateTime updatedAt}) => db.into(db.entries).insert(
        EntriesRepository.newExpense(id: id, amountMinor: 30000, occurredAt: DateTime(2026, 10, 1), note: note)
            .copyWith(updatedAt: Value(updatedAt)),
      );

  Future<Entry?> entry(AppDatabase db, String id) => (db.select(db.entries)..where((t) => t.id.equals(id))).getSingleOrNull();

  test('backs up ciphertext only, and a new phone restores it', () async {
    await addExpense(phone, 'lunch', note: 'Lunch', updatedAt: older);
    final info = await serviceFor(phone).backUp(passphrase, currencyCode: 'INR');

    expect(info.modifiedAt, DateTime(2026, 10, 28, 9));
    expect(String.fromCharCodes(drive.bytes!.take(backupMagic.length)), backupMagic);
    expect(String.fromCharCodes(drive.bytes!).contains('Lunch'), isFalse, reason: 'Drive only ever sees ciphertext');

    final restored = await serviceFor(newPhone).restore(passphrase);
    expect(restored.currencyCode, 'INR');
    expect((await entry(newPhone, 'lunch'))!.note, 'Lunch');
  });

  test('a second backup replaces the Drive copy', () async {
    await serviceFor(phone).backUp(passphrase);
    await addExpense(phone, 'dinner', note: 'Dinner', updatedAt: older);
    await serviceFor(phone).backUp(passphrase);
    expect(drive.uploads, 2);
    await serviceFor(newPhone).restore(passphrase);
    expect(await entry(newPhone, 'dinner'), isNotNull);
  });

  test('restore merges: newer local edits win, missing rows are added', () async {
    await addExpense(phone, 'lunch', note: 'Lunch (backed up)', updatedAt: older);
    await addExpense(phone, 'dinner', note: 'Dinner', updatedAt: older);
    await serviceFor(phone).backUp(passphrase);

    await addExpense(newPhone, 'lunch', note: 'Lunch (edited here)', updatedAt: newer);
    await serviceFor(newPhone).restore(passphrase);

    expect((await entry(newPhone, 'lunch'))!.note, 'Lunch (edited here)');
    expect((await entry(newPhone, 'dinner'))!.note, 'Dinner');
  });

  test('restore with nothing in Drive says no backup was found', () async {
    await expectLater(serviceFor(newPhone).restore(passphrase), throwsA(isA<DriveBackupNotFoundException>()));
  });

  test('restore with the wrong passphrase fails and writes nothing', () async {
    await addExpense(phone, 'lunch', note: 'Lunch', updatedAt: older);
    await serviceFor(phone).backUp(passphrase);
    await expectLater(serviceFor(newPhone).restore('wrong passphrase'), throwsA(isA<BackupFormatException>()));
    expect(await entry(newPhone, 'lunch'), isNull);
  });

  test('delete removes the Drive copy and reports when there was none', () async {
    await serviceFor(phone).backUp(passphrase);
    expect(await serviceFor(phone).lastBackupInfo(), isNotNull);
    expect(await serviceFor(phone).deleteDriveCopy(), isTrue);
    expect(await serviceFor(phone).lastBackupInfo(), isNull);
    expect(await serviceFor(phone).deleteDriveCopy(), isFalse);
  });

  group('driveBackupFailureOf', () {
    test('sorts errors into the messages the screen shows', () {
      expect(driveBackupFailureOf(const DriveSignInCancelledException()), DriveBackupFailure.cancelled);
      expect(driveBackupFailureOf(const DriveBackupNotFoundException()), DriveBackupFailure.notFound);
      expect(const DriveBackupNotFoundException().toString(), 'No Hisab backup in Google Drive');
      expect(driveBackupFailureOf(const BackupFormatException('Wrong passphrase')), DriveBackupFailure.wrongPassphrase);
      expect(driveBackupFailureOf(const SocketException('Failed host lookup')), DriveBackupFailure.offline);
      expect(driveBackupFailureOf(http.ClientException('Connection closed')), DriveBackupFailure.offline);
      expect(driveBackupFailureOf(TimeoutException('slow')), DriveBackupFailure.offline);
      expect(driveBackupFailureOf(const DriveRequestException(503, '')), DriveBackupFailure.offline);
      expect(driveBackupFailureOf(const DriveRequestException(403, '')), DriveBackupFailure.unknown);
      expect(driveBackupFailureOf(StateError('boom')), DriveBackupFailure.unknown);
    });
  });
}
