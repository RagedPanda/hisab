import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/people_repository.dart';
import 'package:hisab/data/repositories/udhaar_repository.dart';
import 'package:hisab/domain/udhaar/udhaar.dart';

void main() {
  late AppDatabase db;
  late UdhaarRepository udhaar;
  late AccountsRepository accounts;
  late PeopleRepository people;
  late String cashId;
  late String rahulId;
  final october = DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    udhaar = UdhaarRepository(db);
    accounts = AccountsRepository(db);
    people = PeopleRepository(db);
    cashId = (await accounts.getAll()).single.id;
    rahulId = await people.addPerson(name: ' Rahul ', phone: ' 98765 43210 ');
  });

  tearDown(() => db.close());

  UdhaarDraft draft(UdhaarKind kind, int amountMinor, {int day = 12, String? accountId}) => (
        personId: rahulId,
        personName: 'Rahul',
        kind: kind,
        amountMinor: amountMinor,
        occurredAt: DateTime(2026, 10, day),
        accountId: accountId ?? cashId,
        note: '',
      );

  Future<int> cashBalance() async => (await accounts.getAll()).single.balanceMinor;
  Future<int> rahulBalance() async => udhaarBalance(await udhaar.watchLines().first, rahulId);

  test('a person added for udhaar has a generated id, no email and a trimmed phone', () async {
    final person = (await people.watchPerson(rahulId).first)!;
    expect((person.name, person.email, person.phone), ('Rahul', '', '98765 43210'));
    expect(person.id, isNot(isEmpty));
  });

  test('lending moves money out of the account and is not spending', () async {
    await udhaar.save(draft(UdhaarKind.lent, 250000));
    expect(await cashBalance(), -250000);
    expect(await rahulBalance(), 250000);
    expect(await EntriesRepository(db).watchTotals(october).first, (expense: 0, income: 0));
  });

  test('a repayment moves money back in and lowers the balance', () async {
    await udhaar.save(draft(UdhaarKind.lent, 250000, day: 1));
    await udhaar.save(draft(UdhaarKind.repaidToMe, 100000, day: 5));
    expect(await cashBalance(), -150000);
    expect(await rahulBalance(), 150000);
    final saved = await udhaar.watchPersonEntries(rahulId).first;
    expect([for (final entry in saved) entry.udhaarKind], ['repaid_to_me', 'lent'], reason: 'newest first');
    expect((saved.first.accountId, saved.first.toAccountId, saved.first.kind, saved.first.payee), (null, cashId, 'transfer', 'Rahul'));
  });

  test('borrowing puts money in and makes me owe them', () async {
    await udhaar.save(draft(UdhaarKind.borrowed, 80000));
    expect(await cashBalance(), 80000);
    expect(await rahulBalance(), -80000);
  });

  test('editing an entry moves the account by the difference only', () async {
    final id = await udhaar.save(draft(UdhaarKind.lent, 100000));
    await udhaar.save(draft(UdhaarKind.borrowed, 30000), id: id);
    expect(await cashBalance(), 30000);
    expect(await rahulBalance(), -30000);
    expect(await udhaar.watchPersonEntries(rahulId).first, hasLength(1));
  });

  test('deleting gives the money back and restoring takes it out again', () async {
    final id = await udhaar.save(draft(UdhaarKind.lent, 50000));
    await udhaar.delete(id);
    expect(await cashBalance(), 0);
    expect(await udhaar.getEntry(id), isNull);
    await udhaar.restore(id);
    expect(await cashBalance(), -50000);
    expect(await rahulBalance(), 50000);
    await udhaar.restore(id);
    expect(await cashBalance(), -50000, reason: 'restoring a live entry does nothing');
  });

  test('renaming a person renames their udhaar entries', () async {
    await udhaar.save(draft(UdhaarKind.lent, 1000));
    await people.updatePerson(rahulId, name: 'Rahul K', phone: '');
    await udhaar.renamePerson(rahulId, ' Rahul K ');
    expect((await udhaar.watchPersonEntries(rahulId).first).single.payee, 'Rahul K');
    expect((await people.watchPerson(rahulId).first)!.phone, isNull);
  });

  test('ordinary transfers are not udhaar', () async {
    final walletId = (await accounts.create(name: 'Wallet', type: 'cash', color: 0xFF000000)).id;
    await EntriesRepository(db).saveEntry(EntriesCompanion.insert(
      id: 't1',
      kind: 'transfer',
      amountMinor: 1000,
      occurredAt: DateTime(2026, 10, 3),
      accountId: Value(cashId),
      toAccountId: Value(walletId),
    ));
    expect(await udhaar.watchLines().first, isEmpty);
    expect(await udhaar.getEntry('t1'), isNull);
  });
}
