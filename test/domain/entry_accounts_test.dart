import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/entries/entry_accounts.dart';

void main() {
  EntryAccountProblem check({String kind = 'expense', bool inGroup = false, String? from, String? to, bool smsCreates = false}) =>
      entryAccountProblem(kind: kind, inGroup: inGroup, accountId: from, toAccountId: to, accountCreatedOnSave: smsCreates);

  test('a personal expense or income needs an account (#110)', () {
    expect(check(from: null), EntryAccountProblem.missingAccount);
    expect(check(kind: 'income', from: null), EntryAccountProblem.missingAccount);
    expect(check(from: 'cash'), EntryAccountProblem.none);
  });

  test('an SMS entry whose account is created on save may start without one', () {
    expect(check(from: null, smsCreates: true), EntryAccountProblem.none);
  });

  test('group expenses never need a personal account', () {
    expect(check(inGroup: true), EntryAccountProblem.none);
  });

  test('a transfer needs two different accounts (#111)', () {
    expect(check(kind: 'transfer', from: 'sbi', to: null), EntryAccountProblem.missingBothAccounts);
    expect(check(kind: 'transfer', from: null, to: 'sbi'), EntryAccountProblem.missingBothAccounts);
    expect(check(kind: 'transfer', from: 'sbi', to: 'sbi'), EntryAccountProblem.sameAccount);
    expect(check(kind: 'transfer', from: 'hdfc', to: 'sbi'), EntryAccountProblem.none);
  });

  test('To is cleared when From becomes the same account (#111)', () {
    expect(toAccountAfterFromChange(fromId: 'sbi', toId: 'sbi'), isNull);
    expect(toAccountAfterFromChange(fromId: 'hdfc', toId: 'sbi'), 'sbi');
    expect(toAccountAfterFromChange(fromId: 'cash', toId: null), isNull);
  });
}
