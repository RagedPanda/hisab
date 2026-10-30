import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';

/// Udhaar entries and card bill payments read from SMS are both transfers:
/// neither may be taken for the other, and neither is Home spending.
void main() {
  late AppDatabase db;
  late EntriesRepository entries;
  final at = DateTime(2026, 10, 12, 10);
  final range = DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    entries = EntriesRepository(db);
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'bank1', name: 'HDFC', type: 'bank', color: 0));
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'card1', name: 'HDFC Card', type: 'card', color: 0));
  });

  tearDown(() => db.close());

  Future<void> insert(String id, {required String kind, String? from, String? to, String source = 'manual', String? udhaarKind}) =>
      db.into(db.entries).insert(EntriesCompanion.insert(
            id: id,
            kind: kind,
            amountMinor: 2500000,
            occurredAt: at,
            accountId: Value(from),
            toAccountId: Value(to),
            source: Value(source),
            personId: Value(udhaarKind == null ? null : 'p1'),
            udhaarKind: Value(udhaarKind),
          ));

  Future<Set<String>> bankDebits() async =>
      {for (final entry in await entries.bankDebitsBetween(amountMinor: 2500000, from: at.subtract(const Duration(days: 3)), to: at.add(const Duration(days: 3)))) entry.id};

  Future<Set<String>> cardPayments() async =>
      {for (final entry in await entries.smsCardPaymentsBetween(amountMinor: 2500000, from: at.subtract(const Duration(days: 3)), to: at.add(const Duration(days: 3)))) entry.id};

  test('an udhaar entry is never taken for a card bill payment', () async {
    await insert('lent', kind: 'transfer', from: 'bank1', udhaarKind: 'lent');
    await insert('borrowedOnCard', kind: 'transfer', to: 'card1', source: 'sms', udhaarKind: 'borrowed');
    // A hand-edited row an older build could leave: udhaar stored as an expense.
    await insert('udhaarExpense', kind: 'expense', from: 'bank1', udhaarKind: 'repaid_by_me');
    expect(await bankDebits(), isEmpty);
    expect(await cardPayments(), isEmpty);

    await insert('debit', kind: 'expense', from: 'bank1', source: 'sms');
    await insert('payment', kind: 'transfer', from: 'bank1', to: 'card1', source: 'sms');
    expect(await bankDebits(), {'debit'});
    expect(await cardPayments(), {'payment'});
  });

  test('Home spending counts neither udhaar nor card bill payments', () async {
    await insert('lent', kind: 'transfer', from: 'bank1', udhaarKind: 'lent');
    await insert('borrowed', kind: 'transfer', to: 'bank1', udhaarKind: 'borrowed');
    await insert('payment', kind: 'transfer', from: 'bank1', to: 'card1', source: 'sms');
    await db.into(db.entries).insert(EntriesCompanion.insert(id: 'chai', kind: 'expense', amountMinor: 3000, occurredAt: at, accountId: const Value('card1')));

    expect(await entries.watchTotals(range).first, (expense: 3000, income: 0));
  });
}
