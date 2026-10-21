import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/ledger/balance_effects.dart';

void main() {
  const cash = 'cash';
  const bank = 'bank';

  group('posting', () {
    test('expense debits, income credits, transfer moves between accounts', () {
      expect(postingDeltas(const EntrySnapshot(kind: 'expense', amountMinor: 50000, accountId: cash)), {cash: -50000});
      expect(postingDeltas(const EntrySnapshot(kind: 'income', amountMinor: 50000, accountId: bank)), {bank: 50000});
      expect(postingDeltas(const EntrySnapshot(kind: 'transfer', amountMinor: 30000, accountId: bank, toAccountId: cash)), {bank: -30000, cash: 30000});
    });

    test('SMS entries never move balances', () {
      expect(postingDeltas(const EntrySnapshot(kind: 'expense', amountMinor: 50000, accountId: bank, source: 'sms')), isEmpty);
    });

    test('AND-12: group expenses never move the paying account', () {
      expect(postingDeltas(const EntrySnapshot(kind: 'expense', amountMinor: 140000, accountId: cash, groupId: 'goa')), isEmpty);
    });

    test('entry without an account has no effect', () {
      expect(postingDeltas(const EntrySnapshot(kind: 'expense', amountMinor: 100)), isEmpty);
    });
  });

  group('editing', () {
    test('AND-03: switching an expense to income reverses the debit and applies the credit', () {
      const previous = EntrySnapshot(kind: 'expense', amountMinor: 50000, accountId: cash);
      const next = EntrySnapshot(kind: 'income', amountMinor: 50000, accountId: cash);
      // Cash was debited 500; it must end up +500, i.e. a net +1000 swing.
      expect(editDeltas(previous: previous, next: next), {cash: 100000});
    });

    test('AND-05: changing a transfer amount does not double-credit the destination', () {
      const previous = EntrySnapshot(kind: 'transfer', amountMinor: 30000, accountId: bank, toAccountId: cash);
      const next = EntrySnapshot(kind: 'transfer', amountMinor: 50000, accountId: bank, toAccountId: cash);
      expect(editDeltas(previous: previous, next: next), {bank: -20000, cash: 20000});
    });

    test('moving an expense to another account restores the first one', () {
      const previous = EntrySnapshot(kind: 'expense', amountMinor: 10000, accountId: cash);
      const next = EntrySnapshot(kind: 'expense', amountMinor: 10000, accountId: bank);
      expect(editDeltas(previous: previous, next: next), {cash: 10000, bank: -10000});
    });

    test('unchanged entry is a no-op', () {
      const entry = EntrySnapshot(kind: 'expense', amountMinor: 10000, accountId: cash);
      expect(editDeltas(previous: entry, next: entry), isEmpty);
    });

    test('creating is the same as posting', () {
      const next = EntrySnapshot(kind: 'expense', amountMinor: 10000, accountId: cash);
      expect(editDeltas(next: next), postingDeltas(next));
    });

    test('editing an SMS entry leaves balances alone', () {
      const previous = EntrySnapshot(kind: 'expense', amountMinor: 45900, accountId: bank, source: 'sms');
      const next = EntrySnapshot(kind: 'expense', amountMinor: 50000, accountId: bank, source: 'sms');
      expect(editDeltas(previous: previous, next: next), isEmpty);
    });
  });

  group('deleting', () {
    test('AND-04: deleting a transfer reverses both accounts', () {
      const previous = EntrySnapshot(kind: 'transfer', amountMinor: 30000, accountId: bank, toAccountId: cash);
      expect(deleteDeltas(previous), {bank: 30000, cash: -30000});
    });

    test('AND-09: deleting a group expense does not credit the payer account', () {
      const previous = EntrySnapshot(kind: 'expense', amountMinor: 140000, accountId: cash, groupId: 'goa');
      expect(deleteDeltas(previous), isEmpty);
    });

    test('deleting an expense refunds the account, deleting income removes it', () {
      expect(deleteDeltas(const EntrySnapshot(kind: 'expense', amountMinor: 7000, accountId: cash)), {cash: 7000});
      expect(deleteDeltas(const EntrySnapshot(kind: 'income', amountMinor: 7000, accountId: cash)), {cash: -7000});
    });
  });
}
