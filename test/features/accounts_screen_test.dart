import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart' show pumpApp, settle, enter;

const _rose = 0xFFF43F5E;

Finder _swatch(int color) => find.byWidgetPredicate((widget) => widget is CircleAvatar && widget.radius == 16 && widget.backgroundColor == Color(color));

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester, 3);
  await tester.tap(finder);
  await settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a new overdrawn account saves with its colour and a negative balance', (tester) async {
    final container = await pumpApp(tester);
    appRouter.push('/accounts');
    await settle(tester);

    await tester.tap(find.text('Account'));
    await settle(tester);
    await enter(tester, find.widgetWithText(TextField, 'Name'), 'Kotak Salary');
    await enter(tester, find.widgetWithText(TextField, 'Current balance'), '500');
    await _tapVisible(tester, find.text('Overdrawn'));
    await _tapVisible(tester, _swatch(_rose));
    await _tapVisible(tester, find.text('Save'));

    final saved = (await container.read(accountsRepositoryProvider).getAll()).firstWhere((account) => account.name == 'Kotak Salary');
    expect(saved.balanceMinor, -50000);
    expect(saved.color, _rose);
  });

  testWidgets('deleting an account from its sheet asks first, then removes it', (tester) async {
    final container = await pumpApp(tester);
    final db = container.read(databaseProvider);
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'kotak', name: 'Kotak Salary', type: 'bank', color: 0xFF1E88E5, balanceMinor: const Value(100000)));
    appRouter.push('/accounts');
    await settle(tester);

    await tester.tap(find.text('Kotak Salary'));
    await settle(tester);
    await _tapVisible(tester, find.widgetWithText(TextButton, 'Delete'));
    expect(find.text('Delete Kotak Salary?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);

    expect(await container.read(accountsRepositoryProvider).getById('kotak'), isNull);
    expect(find.text('Kotak Salary'), findsNothing);
  });

  testWidgets('a card shows what is left to pay on its statement, or Paid, not the whole outstanding', (tester) async {
    final container = await pumpApp(tester);
    final db = container.read(databaseProvider);
    final statementAt = DateTime.now().subtract(const Duration(days: 10));
    Future<void> card(String id, String name, int balance, {int? statement}) => db.into(db.accounts).insert(AccountsCompanion.insert(
          id: id,
          name: name,
          type: 'card',
          color: 0,
          balanceMinor: Value(balance),
          lastStatementMinor: Value(statement),
          lastStatementAt: Value(statement == null ? null : statementAt),
        ));
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'savings', name: 'Savings', type: 'bank', color: 0));
    await card('part', 'Part paid card', -3000000, statement: 2000000);
    await card('paid', 'Paid card', -400000, statement: 500000);
    await card('fresh', 'Fresh card', -125000);
    await card('new', 'New card', 0);
    Future<void> pay(String cardId, int amount) => container.read(entriesRepositoryProvider).saveEntry(
          EntriesRepository.newExpense(kind: 'transfer', amountMinor: amount, occurredAt: statementAt.add(const Duration(days: 2)), accountId: 'savings')
              .copyWith(toAccountId: Value(cardId)),
        );
    await pay('part', 500000);
    await pay('paid', 500000);
    appRouter.push('/accounts');
    await settle(tester);

    Finder trailing(String name) => find.descendant(of: find.widgetWithText(ListTile, name), matching: find.byType(Text));
    String texts(String name) => tester.widgetList<Text>(trailing(name)).map((text) => text.data).join(' | ');
    expect(texts('Part paid card'), contains('Due ₹15,000'));
    expect(texts('Paid card'), contains('Paid'));
    expect(texts('Paid card'), isNot(contains('Due')));
    expect(texts('Fresh card'), contains('Due ₹1,250'), reason: 'no statement: the amount owed');
    expect(texts('New card'), contains('Nothing due'), reason: 'no statement and nothing owed');
    expect(texts('New card'), isNot(contains('Due ₹')));
  });
}
