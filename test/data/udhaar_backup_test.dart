import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/app_backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/udhaar/udhaar_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late AppDatabase restoredDb;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    restoredDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await restoredDb.close();
  });

  test('the app backup carries my UPI ID to a fresh device', () async {
    await prefs.setString(kMyUpiIdPref, 'ankur@okicici');
    final payload = await appBackupService(db, prefs).snapshot();
    expect(payload['udhaarSettings'], {kMyUpiIdPref: 'ankur@okicici'});

    await prefs.clear();
    await appBackupService(restoredDb, prefs).importSnapshot(payload);
    expect(prefs.getString(kMyUpiIdPref), 'ankur@okicici');
  });

  test('choosing to leave the UPI ID out is restored too', () async {
    await prefs.setString(kMyUpiIdPref, '');
    final payload = await appBackupService(db, prefs).snapshot();

    await prefs.clear();
    await appBackupService(restoredDb, prefs).importSnapshot(payload);
    expect(prefs.getString(kMyUpiIdPref), '', reason: 'so the first reminder does not ask again');
  });

  test('no block before a UPI ID is set, and older backups keep the one on this device', () async {
    final payload = await appBackupService(db, prefs).snapshot();
    expect(payload.containsKey('udhaarSettings'), isFalse);

    await prefs.setString(kMyUpiIdPref, 'me@upi');
    await appBackupService(restoredDb, prefs).importSnapshot(payload);
    expect(prefs.getString(kMyUpiIdPref), 'me@upi');
  });

  test('a backed-up UPI ID is read only when it is text', () {
    expect(parseBackedUpUpiId({kMyUpiIdPref: ' me@upi '}), 'me@upi');
    expect(parseBackedUpUpiId({kMyUpiIdPref: 42}), isNull);
    expect(parseBackedUpUpiId({}), isNull);
  });
}
