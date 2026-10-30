import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';

void main() {
  late AppDatabase db;
  late AppDatabase restoredDb;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    restoredDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await restoredDb.close();
  });

  test('a backup carries card facts from SMS, udhaar entries and People phones to a fresh device', () async {
    final at = DateTime(2026, 10, 30, 9);
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'card1',
          name: 'HDFC Card',
          type: 'card',
          color: 0,
          minimumDueMinor: const Value(118000),
          statementFromSmsAt: Value(at),
          availableLimitMinor: const Value(7654321),
          availableLimitAt: Value(at),
        ));
    await db.into(db.people).insert(PeopleCompanion.insert(id: 'p1', name: 'Amit', email: '', phone: const Value('+919876543210')));
    await db.into(db.entries).insert(EntriesCompanion.insert(
          id: 'e1',
          kind: 'transfer',
          amountMinor: 50000,
          occurredAt: at,
          accountId: const Value('card1'),
          personId: const Value('p1'),
          udhaarKind: const Value('lent'),
        ));

    // Through JSON, as the encrypted file and the Drive copy carry it.
    final payload = jsonDecode(jsonEncode(await BackupService(db).snapshot())) as Map<String, dynamic>;
    await BackupService(restoredDb).importSnapshot(payload);

    final card = await (restoredDb.select(restoredDb.accounts)..where((t) => t.id.equals('card1'))).getSingle();
    expect((card.minimumDueMinor, card.statementFromSmsAt, card.availableLimitMinor, card.availableLimitAt), (118000, at, 7654321, at));
    final person = await (restoredDb.select(restoredDb.people)..where((t) => t.id.equals('p1'))).getSingle();
    expect(person.phone, '+919876543210');
    final entry = await (restoredDb.select(restoredDb.entries)..where((t) => t.id.equals('e1'))).getSingle();
    expect((entry.personId, entry.udhaarKind), ('p1', 'lent'));
  });
}
