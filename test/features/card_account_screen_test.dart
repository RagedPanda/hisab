import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/domain/cards/card_cycle.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/features/accounts/accounts_screen.dart';
import 'package:hisab/features/accounts/card_account_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../app_flow_test.dart' show pumpApp, settle, enter;
import '../core/fake_notification_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a card with statement details shows limit, cycle spend and due date', (tester) async {
    final container = await pumpApp(tester);
    final db = container.read(databaseProvider);
    final today = startOfDay(DateTime.now());
    final statementDay = today.day > 28 ? 28 : today.day;
    final statementAt = previousStatementDate(today, statementDay);
    final dueDay = statementAt.day == 1 ? 20 : statementAt.day - 1;
    {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
            id: 'card',
            name: 'HDFC Millennia',
            type: 'card',
            color: 0xFF1E88E5,
            balanceMinor: const Value(-4000000),
            statementDay: Value(statementDay),
            dueDay: Value(dueDay),
            creditLimitMinor: const Value(10000000),
            lastStatementMinor: const Value(3000000),
            lastStatementAt: Value(statementAt),
          ));
      await container.read(entriesRepositoryProvider).saveEntry(EntriesRepository.newExpense(amountMinor: 120000, occurredAt: DateTime.now(), accountId: 'card'));
      await container.read(entriesRepositoryProvider).saveEntry(EntriesRepository.newExpense(kind: 'transfer', amountMinor: 1000000, occurredAt: DateTime.now(), accountId: 'other').copyWith(toAccountId: const Value('card')));
    }

    appRouter.push('/accounts');
    await settle(tester);
    await tester.tap(find.text('HDFC Millennia'));
    await settle(tester);

    expect(find.byType(CardAccountScreen), findsOneWidget);
    expect(find.descendant(of: find.byKey(kCardOutstandingKey), matching: find.textContaining('40,000')), findsOneWidget);
    expect(find.text('40% of ₹1,00,000 limit used'), findsOneWidget);
    expect(find.text('₹60,000'), findsOneWidget, reason: 'available limit');
    final due = dueDateForStatement(statementAt, dueDay);
    final daysLeft = calendarDaysBetween(today, due);
    expect(find.descendant(of: find.byKey(kCardDueChipKey), matching: find.text(daysLeft == 1 ? 'Due tomorrow' : 'Due in $daysLeft days')), findsOneWidget);
    expect(find.text('₹20,000 left to pay'), findsOneWidget, reason: '30,000 billed less the 10,000 paid since');
    expect(find.descendant(of: find.byKey(kCardStatementKey), matching: find.text('₹30,000')), findsOneWidget);
    expect(find.descendant(of: find.byKey(kCardCycleKey), matching: find.text('₹1,200')), findsOneWidget, reason: 'the bill payment is not spend');
  });

  testWidgets('a card without details prompts to set the days, and the sheet saves them with a due reminder', (tester) async {
    final gateway = FakeNotificationGateway();
    final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(gateway)]);
    final db = container.read(databaseProvider);
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'card', name: 'Amex', type: 'card', color: 0xFF1E88E5, balanceMinor: const Value(-50000)));

    appRouter.push('/accounts/card/card');
    await settle(tester);
    expect(find.text('Set statement and due days'), findsOneWidget);
    expect(find.text('40% of ₹1,00,000 limit used'), findsNothing);

    await tester.tap(find.text('Set statement and due days'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('account.statementDay')));
    await settle(tester);
    await tester.tap(find.text('5').last);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('account.dueDay')));
    await settle(tester);
    await tester.tap(find.text('15').last);
    await settle(tester);
    await enter(tester, find.byKey(const ValueKey('account.creditLimit')), '100000');
    await enter(tester, find.byKey(const ValueKey('account.lastStatement')), '1500');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await settle(tester);

    final saved = await (db.select(db.accounts)..where((t) => t.id.equals('card'))).getSingle();
    expect(saved.statementDay, 5);
    expect(saved.dueDay, 15);
    expect(saved.creditLimitMinor, 10000000);
    expect(saved.lastStatementMinor, 150000);
    expect(saved.lastStatementAt, previousStatementDate(startOfDay(DateTime.now()), 5));
    expect(saved.balanceMinor, -50000, reason: 'balance untouched');
    expect(find.text('Set statement and due days'), findsNothing);
    expect(find.byKey(kCardDueChipKey), findsOneWidget);

    final reminders = await container.read(remindersRepositoryProvider).forAccount('card', kind: ReminderKind.card);
    expect(reminders, hasLength(1), reason: 'saving the due day creates the card due reminder');
    final reminder = reminders.single;
    expect(reminder.title, 'Amex');
    expect(reminder.amountMinor, 150000);
    expect(reminder.dueAt, dueDateForStatement(saved.lastStatementAt!, 15));
  });

  test('card fields are cleared for other account types', () {
    final fields = cardFieldsFromForm(isCard: false, statementDay: 5, dueDay: 25, limitText: '1000', lastStatementText: '10');
    expect(fields.statementDay, isNull);
    expect(fields.creditLimitMinor, isNull);
    expect(fields.lastStatementAt, isNull);
  });

  test('card fields parse amounts and stamp the statement date', () {
    final fields = cardFieldsFromForm(isCard: true, statementDay: 15, dueDay: 3, limitText: '2,00,000', lastStatementText: '', now: DateTime(2026, 10, 22));
    expect(fields.creditLimitMinor, 20000000);
    expect(fields.lastStatementMinor, isNull);
    expect(fields.lastStatementAt, isNull);
  });
}
