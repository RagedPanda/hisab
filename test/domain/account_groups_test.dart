import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/accounts/account_groups.dart';

typedef TestAccount = ({String id, String type});

List<AccountTypeGroup<TestAccount>> groupsOf(List<TestAccount> accounts) => groupAccountsByType(accounts, (account) => account.type);

void main() {
  const hdfc = (id: 'hdfc', type: 'bank');
  const sbi = (id: 'sbi', type: 'bank');
  const cash = (id: 'cash', type: 'cash');
  const paytm = (id: 'paytm', type: 'wallet');

  test('orders types cash, bank, card, wallet and leaves out empty ones', () {
    final groups = groupsOf([paytm, hdfc, cash, sbi]);
    expect(groups.map((group) => group.type), ['cash', 'bank', 'wallet']);
    expect(groups[1].accounts.map((account) => account.id), ['hdfc', 'sbi'], reason: 'accounts keep their order');
  });

  test('an unknown type is grouped with cash', () {
    final groups = groupsOf([cash, (id: 'locker', type: 'safe')]);
    expect(groups.single.type, 'cash');
    expect(groups.single.accounts, hasLength(2));
  });

  test('no accounts gives no groups', () {
    expect(groupsOf([]), isEmpty);
  });

  test('a type with one account picks it directly; several pick nothing yet', () {
    final groups = groupsOf([cash, hdfc, sbi]);
    expect(groups.first.onlyAccount, cash);
    expect(groups.last.onlyAccount, isNull);
  });

  test('typeHolding finds the type of the selected account', () {
    final groups = groupsOf([cash, hdfc, sbi]);
    expect(typeHolding(groups, 'sbi', (account) => account.id), 'bank');
    expect(typeHolding(groups, null, (account) => account.id), isNull);
    expect(typeHolding(groups, 'gone', (account) => account.id), isNull);
  });

  group('accountToPickForType (#110)', () {
    final banks = groupsOf([hdfc, sbi]).single;
    String pick({String? selectedId, List<String> recentIds = const []}) =>
        accountToPickForType(banks, selectedId: selectedId, recentIds: recentIds, idOf: (account) => account.id).id;

    test('keeps the selected account when it is of that type', () {
      expect(pick(selectedId: 'sbi', recentIds: ['hdfc']), 'sbi');
    });

    test('otherwise picks the most recently used account of the type', () {
      expect(pick(selectedId: 'cash', recentIds: ['cash', 'paytm', 'sbi', 'hdfc']), 'sbi');
    });

    test('falls back to the first account when none was used', () {
      expect(pick(selectedId: null), 'hdfc');
      expect(pick(selectedId: 'cash', recentIds: ['cash']), 'hdfc');
    });
  });
}
