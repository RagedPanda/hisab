import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/group_recurring_repository.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/split/group_recurring.dart';
import 'package:hisab/domain/split/split_calculator.dart';
import 'package:hisab/features/recurring/recurring_rule_form_screen.dart';

import '../support/app_harness.dart';

const _amountField = ValueKey('recurring.amount');
const _nameField = ValueKey('recurring.name');
const _saveButton = ValueKey('recurring.save');

Future<List<RecurringRule>> _rules(WidgetTester tester, ProviderContainer container) async {
  final db = container.read(databaseProvider);
  return (await tester.runAsync(() => db.select(db.recurringRules).get()))!;
}

Future<String> _saveRule(WidgetTester tester, ProviderContainer container, RecurringRulesCompanion rule) async =>
    (await tester.runAsync(() => container.read(recurringRepositoryProvider).saveRule(rule)))!;

RecurringRulesCompanion _monthlyRule({String kind = 'expense', int amountMinor = 150000, int? dayOfMonth = 5, DateTime? endDate, String? categoryId}) => RecurringRepository.newRule(
      name: 'Gym',
      kind: kind,
      amountMinor: amountMinor,
      categoryId: categoryId,
      payee: 'Cult',
      note: 'Membership',
      frequency: RecurrenceFrequency.monthly,
      dayOfMonth: dayOfMonth,
      startDate: DateTime(2030, 1, 5, 9),
      endDate: endDate,
    );

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(find.byKey(_saveButton));
  await pumpWithDatabase(tester);
}

/// A group of me and Ravi with a rent rule split by [template] built from
/// the member ids.
Future<String> _saveGroupRule(WidgetTester tester, ProviderContainer container, {required String kind, required GroupExpenseTemplate Function(String me, String ravi) template}) async {
  return (await tester.runAsync(() async {
    final groups = container.read(groupsRepositoryProvider);
    final groupId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me', otherMembers: ['Ravi']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((member) => member.isMe).id;
    final ravi = members.firstWhere((member) => !member.isMe).id;
    return container.read(recurringRepositoryProvider).saveRule(GroupRecurringRepository.asGroupRule(_monthlyRule(kind: kind, amountMinor: 1000000), groupId: groupId, template: template(me, ravi)));
  }))!;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a new rule saves what the form shows and returns home', (tester) async {
    final container = await createContainer();
    await pumpScreen(tester, container, const RecurringRuleFormScreen());
    expect(find.text('New recurring'), findsOneWidget);
    expect(find.text('Uncategorised'), findsOneWidget);

    await tester.tap(find.text('Income'));
    await tester.pump();
    await tester.tap(find.text('Uncategorised'));
    await pumpWithDatabase(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search categories'), 'Salary');
    await tester.pump();
    await tester.tap(find.text('Salary').last);
    await pumpWithDatabase(tester);
    expect(find.text('Salary'), findsOneWidget, reason: 'the picked category replaces Uncategorised');

    await enter(tester, find.byKey(_amountField), '45000');
    await enter(tester, find.byKey(_nameField), ' Pay day ');
    await enter(tester, find.widgetWithText(TextField, 'Paid to / received from'), ' Acme ');
    await enter(tester, find.widgetWithText(TextField, 'Note'), ' monthly ');

    await tester.ensureVisible(find.byKey(const ValueKey('recurring.nextOn')));
    await tester.tap(find.byKey(const ValueKey('recurring.nextOn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('editor.repeat')));
    await tester.tap(find.byKey(const ValueKey('editor.repeat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('repeat.autoPost')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('repeat.done')));
    await tester.pumpAndSettle();

    await _tapSave(tester);
    expect(find.text('home'), findsOneWidget, reason: 'saving pops back to where the form was opened from');
    final rule = (await _rules(tester, container)).single;
    final now = DateTime.now();
    expect(rule.kind, 'income');
    expect(rule.amountMinor, 4500000);
    expect(rule.name, 'Pay day');
    expect(rule.payee, 'Acme');
    expect(rule.note, 'monthly');
    expect(rule.startDate, DateTime(now.year, now.month, 15, 9));
    expect(rule.dayOfMonth, 15);
    expect(rule.autoPost, isFalse);
    expect(rule.accountId, isNotNull, reason: 'the first account is picked for a new rule');
    final salary = await tester.runAsync(() => container.read(categoriesRepositoryProvider).byId(rule.categoryId!));
    expect(salary!.name, 'Salary');
  });

  testWidgets('a blank amount, a zero amount and an unreadable amount are refused', (tester) async {
    final container = await createContainer();
    await pumpScreen(tester, container, const RecurringRuleFormScreen());

    await _tapSave(tester);
    expect(find.text('Enter an amount greater than zero'), findsOneWidget);

    await enter(tester, find.byKey(_amountField), '1.2.3');
    expect(find.text('Enter a valid amount, e.g. 250 or 99.50'), findsOneWidget, reason: 'the field shows the error inline');
    ScaffoldMessenger.of(tester.element(find.byKey(_saveButton))).removeCurrentSnackBar();
    await _tapSave(tester);
    expect(find.text('Enter a valid amount, e.g. 250 or 99.50'), findsNWidgets(2), reason: 'and Save repeats it in a snackbar');
    expect(await _rules(tester, container), isEmpty);
  });

  testWidgets('a transfer needs both accounts and stores no category', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() => container.read(accountsRepositoryProvider).create(name: 'HDFC', type: 'bank', color: 0xFF1E88E5));
    await pumpScreen(tester, container, const RecurringRuleFormScreen());

    await tester.tap(find.text('Transfer'));
    await tester.pump();
    expect(find.text('From account'), findsOneWidget);
    expect(find.text('To account'), findsOneWidget);
    expect(find.text('Uncategorised'), findsNothing, reason: 'a transfer has no category');

    await enter(tester, find.byKey(_amountField), '5000');
    await _tapSave(tester);
    expect(find.text('Pick both accounts for a transfer'), findsOneWidget);

    final toChoices = find.byType(ChoiceChip).last;
    await tester.ensureVisible(toChoices);
    await tester.tap(toChoices);
    await tester.pump();
    await _tapSave(tester);

    final rule = (await _rules(tester, container)).single;
    expect(rule.kind, 'transfer');
    expect(rule.toAccountId, isNotNull);
    expect(rule.toAccountId, isNot(rule.accountId));
    expect(rule.categoryId, isNull);
  });

  testWidgets('editing a rule loads it and keeps the fields the form does not show', (tester) async {
    final container = await createContainer();
    final rent = (await tester.runAsync(() => container.read(categoriesRepositoryProvider).findBySeedKey('rent')))!;
    final ruleId = await _saveRule(tester, container, _monthlyRule(categoryId: rent.id).copyWith(isSubscription: const Value(true), remindDaysBefore: const Value('1,3'), currency: const Value('USD')));
    await pumpScreen(tester, container, RecurringRuleFormScreen(ruleId: ruleId));

    expect(find.text('Edit recurring'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Cult'), findsOneWidget);
    expect(find.text('Membership'), findsOneWidget);

    await enter(tester, find.byKey(_amountField), '2000');
    await _tapSave(tester);

    final rule = (await _rules(tester, container)).single;
    expect(rule.id, ruleId);
    expect(rule.amountMinor, 200000);
    expect(rule.categoryId, rent.id);
    expect(rule.isSubscription, isTrue);
    expect(rule.remindDaysBefore, '1,3');
    expect(rule.currency, 'USD');
  });

  testWidgets('a rule on the salary-month day keeps that anchor when saved', (tester) async {
    final container = await createContainer();
    final ruleId = await _saveRule(tester, container, _monthlyRule(dayOfMonth: kMonthStartDayOfMonth));
    await pumpScreen(tester, container, RecurringRuleFormScreen(ruleId: ruleId));
    await _tapSave(tester);
    expect((await _rules(tester, container)).single.dayOfMonth, kMonthStartDayOfMonth);
  });

  testWidgets('an end date before the next date is refused', (tester) async {
    final container = await createContainer();
    final ruleId = await _saveRule(tester, container, _monthlyRule(endDate: DateTime(2031, 1, 1)));
    await tester.runAsync(() async {
      final db = container.read(databaseProvider);
      await (db.update(db.recurringRules)..where((table) => table.id.equals(ruleId))).write(RecurringRulesCompanion(nextDue: Value(DateTime(2031, 6, 5, 9))));
    });
    await pumpScreen(tester, container, RecurringRuleFormScreen(ruleId: ruleId));
    await _tapSave(tester);
    expect(find.text('Pick an end date on or after the start'), findsOneWidget);
  });

  testWidgets('a deleted or unknown rule shows that it is gone', (tester) async {
    final container = await createContainer();
    final ruleId = await _saveRule(tester, container, _monthlyRule());
    await tester.runAsync(() => container.read(recurringRepositoryProvider).delete(ruleId));
    await pumpScreen(tester, container, RecurringRuleFormScreen(ruleId: ruleId));
    expect(find.text('This recurring entry was deleted'), findsOneWidget);
    expect(find.byKey(_saveButton), findsNothing);
  });

  testWidgets('a group rule hides kind and account, and refuses anything but an expense', (tester) async {
    final container = await createContainer();
    final ruleId = await _saveGroupRule(tester, container, kind: 'income', template: (me, ravi) => GroupExpenseTemplate(method: SplitMethod.equal, paidByMemberId: me, inputs: [SplitInput(memberId: me), SplitInput(memberId: ravi)]));
    await pumpScreen(tester, container, RecurringRuleFormScreen(ruleId: ruleId));
    expect(find.text('Expense'), findsNothing, reason: 'a group rule cannot change kind');
    expect(find.text('Account'), findsNothing, reason: 'a member pays a group rule, not one of my accounts');
    await _tapSave(tester);
    expect(find.text('A group repeating rule can only be an expense.'), findsOneWidget);
  });

  testWidgets('a group rule split by fixed amounts cannot change its total', (tester) async {
    final container = await createContainer();
    final ruleId = await _saveGroupRule(tester, container, kind: 'expense', template: (me, ravi) => GroupExpenseTemplate(
          method: SplitMethod.exact,
          paidByMemberId: me,
          inputs: [SplitInput(memberId: me, amountMinor: 600000), SplitInput(memberId: ravi, amountMinor: 400000)],
        ));
    await pumpScreen(tester, container, RecurringRuleFormScreen(ruleId: ruleId));
    await enter(tester, find.byKey(_amountField), '12000');
    await _tapSave(tester);
    expect(find.text("This split uses fixed amounts, so the total can't change here"), findsOneWidget);

    await enter(tester, find.byKey(_amountField), '10000');
    await _tapSave(tester);
    expect(find.text('home'), findsOneWidget, reason: 'the unchanged total still fits the split');
  });
}
