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
}
