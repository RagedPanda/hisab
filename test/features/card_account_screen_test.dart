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

import '../support/app_harness.dart' show pumpApp, settle, enter;
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
    expect(find.textContaining('More than the amount due (₹500)'), findsOneWidget, reason: 'a statement above the amount due is not saved');
    expect((await (db.select(db.accounts)..where((t) => t.id.equals('card'))).getSingle()).dueDay, isNull);

    await enter(tester, find.byKey(const ValueKey('account.lastStatement')), '400');
    expect(find.textContaining('More than the amount due'), findsNothing, reason: 'editing the field clears the error');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await settle(tester);

    final saved = await (db.select(db.accounts)..where((t) => t.id.equals('card'))).getSingle();
    expect(saved.statementDay, 5);
    expect(saved.dueDay, 15);
    expect(saved.creditLimitMinor, 10000000);
    expect(saved.lastStatementMinor, 40000);
    expect(saved.lastStatementAt, previousStatementDate(startOfDay(DateTime.now()), 5));
    expect(saved.balanceMinor, -50000, reason: 'balance untouched');
    expect(find.text('Set statement and due days'), findsNothing);
    expect(find.byKey(kCardDueChipKey), findsOneWidget);

    final reminders = await container.read(remindersRepositoryProvider).forAccount('card', kind: ReminderKind.card);
    expect(reminders, hasLength(1), reason: 'saving the due day creates the card due reminder');
    final reminder = reminders.single;
    expect(reminder.title, 'Amex');
    expect(reminder.amountMinor, 40000);
    expect(reminder.dueAt, dueDateForStatement(saved.lastStatementAt!, 15));
  });

  testWidgets('an overpaid card shows its credit, and changing its type leaves the card screen', (tester) async {
    final container = await pumpApp(tester);
    final db = container.read(databaseProvider);
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'card',
          name: 'Amex',
          type: 'card',
          color: 0xFF1E88E5,
          balanceMinor: const Value(50000),
          creditLimitMinor: const Value(10000000),
        ));

    appRouter.push('/accounts');
    await settle(tester);
    await tester.tap(find.text('Amex'));
    await settle(tester);
    expect(find.descendant(of: find.byKey(kCardOutstandingKey), matching: find.text('₹500 credit')), findsOneWidget);
    final semantics = tester.getSemantics(find.byKey(kCardOutstandingKey));
    expect(semantics.label, startsWith('Outstanding'));
    expect(semantics.value, isEmpty, reason: 'TalkBack reads a value first; the bare utilisation number must not lead the card');

    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);
    await tester.tap(find.text('Bank account'));
    await settle(tester);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.byType(CardAccountScreen), findsNothing);
    expect(find.text('Amex'), findsOneWidget, reason: 'back on the Accounts list');
  });

  Future<Account> savedCard(AppDatabase db) => (db.select(db.accounts)..where((t) => t.id.equals('card'))).getSingle();

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await settle(tester);
  }

  testWidgets('a paid card can be edited without touching its last statement (#97)', (tester) async {
    final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
    final db = container.read(databaseProvider);
    final statementAt = previousStatementDate(startOfDay(DateTime.now()), 5);
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'card',
          name: 'Amex',
          type: 'card',
          color: 0xFF1E88E5,
          balanceMinor: const Value(0),
          statementDay: const Value(5),
          dueDay: const Value(15),
          lastStatementMinor: const Value(500000),
          lastStatementAt: Value(statementAt),
        ));
    await container.read(entriesRepositoryProvider).saveEntry(EntriesRepository.newExpense(kind: 'transfer', amountMinor: 500000, occurredAt: DateTime.now(), accountId: 'cash').copyWith(toAccountId: const Value('card')));

    appRouter.push('/accounts/card/card');
    await settle(tester);
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('account.dueDay')));
    await settle(tester);
    await tester.tap(find.text('20').last);
    await settle(tester);
    await tapSave(tester);

    expect(find.textContaining('More than the amount due'), findsNothing);
    final saved = await savedCard(db);
    expect(saved.dueDay, 20);
    expect(saved.lastStatementMinor, 500000);
    expect(saved.balanceMinor, 0);
  });

  Future<AppDatabase> insertSmsCard(WidgetTester tester) async {
    final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
    final db = container.read(databaseProvider);
    final today = startOfDay(DateTime.now());
    final statementAt = previousStatementDate(today, 5);
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          id: 'card',
          name: 'HDFC Millennia',
          type: 'card',
          color: 0xFF1E88E5,
          balanceMinor: const Value(-2345678),
          statementDay: const Value(5),
          dueDay: const Value(25),
          lastStatementMinor: const Value(2345678),
          lastStatementAt: Value(statementAt),
          minimumDueMinor: const Value(118000),
          statementFromSmsAt: Value(statementAt.add(const Duration(hours: 9))),
          availableLimitMinor: const Value(7654321),
          availableLimitAt: Value(today),
        ));
    appRouter.push('/accounts/card/card');
    await settle(tester);
    return db;
  }

  testWidgets('card facts read from SMS show where they came from', (tester) async {
    await insertSmsCard(tester);

    expect(find.descendant(of: find.byKey(kCardStatementKey), matching: find.textContaining('From SMS, ')), findsOneWidget);
    expect(find.descendant(of: find.byKey(kCardDueKey), matching: find.text('Minimum due ₹1,180')), findsOneWidget);
    expect(find.byKey(kCardSmsLimitKey), findsOneWidget);
    expect(find.textContaining('₹76,543 available, from SMS, '), findsOneWidget);
  });

  testWidgets('editing the statement amount drops the minimum due read from SMS', (tester) async {
    final db = await insertSmsCard(tester);
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);
    await enter(tester, find.byKey(const ValueKey('account.lastStatement')), '20000');
    await tapSave(tester);

    final saved = await savedCard(db);
    expect(saved.lastStatementMinor, 2000000);
    expect(saved.minimumDueMinor, isNull);
    expect(saved.statementFromSmsAt, isNull);
    expect(saved.availableLimitMinor, 7654321, reason: 'still a card');
  });

  testWidgets('editing other card details keeps the statement read from SMS', (tester) async {
    final db = await insertSmsCard(tester);
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('account.dueDay')));
    await settle(tester);
    await tester.tap(find.text('20').last);
    await settle(tester);
    await tapSave(tester);

    final saved = await savedCard(db);
    expect(saved.dueDay, 20);
    expect(saved.minimumDueMinor, 118000);
    expect(saved.statementFromSmsAt, isNotNull);
  });

  testWidgets('editing a card in credit keeps the credit (#98)', (tester) async {
    final container = await pumpApp(tester);
    final db = container.read(databaseProvider);
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'card', name: 'Amex', type: 'card', color: 0xFF1E88E5, balanceMinor: const Value(50000), lastStatementMinor: const Value(500000), lastStatementAt: Value(DateTime(2026, 10, 5))));

    appRouter.push('/accounts/card/card');
    await settle(tester);
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);
    expect(find.text('Credit on the card'), findsOneWidget);
    await tapSave(tester);

    expect((await savedCard(db)).balanceMinor, 50000);
    expect(find.descendant(of: find.byKey(kCardOutstandingKey), matching: find.text('₹500 credit')), findsOneWidget);
  });

  testWidgets('changing a card to a bank account keeps money owed as a negative balance', (tester) async {
    final container = await pumpApp(tester);
    final db = container.read(databaseProvider);
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'card', name: 'Amex', type: 'card', color: 0xFF1E88E5, balanceMinor: const Value(-50000)));

    appRouter.push('/accounts/card/card');
    await settle(tester);
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);
    await tester.tap(find.text('Bank account'));
    await settle(tester);
    expect(find.text('Overdrawn'), findsOneWidget, reason: 'the direction is shown for the new type');
    await tapSave(tester);

    final saved = await savedCard(db);
    expect(saved.type, 'bank');
    expect(saved.balanceMinor, -50000);
  });

  testWidgets('setting a card due day shows the notification and Alarms & reminders sheets, then the late note', (tester) async {
    final gateway = FakeNotificationGateway(notificationsAllowed: false, exactAlarmsAllowed: false);
    final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(gateway)]);
    final db = container.read(databaseProvider);
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'card', name: 'Amex', type: 'card', color: 0xFF1E88E5, balanceMinor: const Value(-50000)));

    appRouter.push('/accounts/card/card');
    await settle(tester);
    expect(find.byKey(const ValueKey('reminders-late-note')), findsNothing, reason: 'no due day, no reminder');
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
    await tapSave(tester);

    expect(find.text("Get reminded before it's due"), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await settle(tester);
    expect(gateway.permissionRequests, 1);
    expect(find.text('Get reminders on time'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await settle(tester);
    expect(gateway.exactRequests, 1);
    expect((await savedCard(db)).dueDay, 15);
    expect(find.byKey(const ValueKey('reminders-late-note')), findsOneWidget, reason: 'still inexact, so the card says reminders may be late');
    expect(tester.takeException(), isNull);
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
