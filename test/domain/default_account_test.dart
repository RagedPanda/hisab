import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/accounts/default_account.dart';

Account account(String id, String type) => Account(
      updatedAt: DateTime(2026),
      id: id,
      name: id,
      type: type,
      balanceMinor: 0,
      includeInTotal: true,
      color: 0,
      sortOrder: 0,
    );

void main() {
  group('defaultEntryAccountId', () {
    final accounts = [account('hdfc', 'bank'), account('cash', 'cash'), account('wallet', 'wallet')];

    test('prefers a cash account when nothing is pinned', () {
      expect(defaultEntryAccountId(accounts), 'cash');
    });

    test('honours a pinned account that still exists', () {
      expect(defaultEntryAccountId(accounts, configuredId: 'hdfc'), 'hdfc');
    });

    test('falls back to cash when the pinned account is gone', () {
      expect(defaultEntryAccountId(accounts, configuredId: 'deleted'), 'cash');
    });

    test('falls back to the first account when there is no cash account', () {
      expect(defaultEntryAccountId([account('hdfc', 'bank'), account('wallet', 'wallet')]), 'hdfc');
    });

    test('returns null when there are no accounts', () {
      expect(defaultEntryAccountId(const [], configuredId: 'hdfc'), isNull);
    });
  });

  group('cardPaymentSourceAccountId', () {
    test('takes the default account when it is a bank account', () {
      final accounts = [account('hdfc', 'bank'), account('sbi', 'bank'), account('cash', 'cash')];
      expect(cardPaymentSourceAccountId(accounts, configuredId: 'sbi'), 'sbi');
    });

    test('takes the only bank account when the default is not a bank', () {
      final accounts = [account('hdfc', 'bank'), account('cash', 'cash'), account('card', 'card')];
      expect(cardPaymentSourceAccountId(accounts, configuredId: 'cash'), 'hdfc');
    });

    test('is null with several banks and none chosen, or no bank at all', () {
      expect(cardPaymentSourceAccountId([account('hdfc', 'bank'), account('sbi', 'bank')]), isNull);
      expect(cardPaymentSourceAccountId([account('cash', 'cash'), account('card', 'card')]), isNull);
    });
  });
}
