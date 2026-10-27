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
}
