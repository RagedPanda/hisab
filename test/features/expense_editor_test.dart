import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/domain/projects/project_templates.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';
import 'package:hisab/features/expense_editor/item_row.dart';
import 'package:hisab/features/recurring/recurring_rule_form_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../core/fake_notification_gateway.dart';
import '../support/app_harness.dart';
import '../support/seed.dart';

/// The personal entry editor: what each control does to the entry that gets
/// saved, the checks that stop a save, and the forms it opens prefilled
/// (an SMS, a due reminder, an existing entry).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final editor = find.byType(ExpenseEditorScreen);
  final amountField = find.descendant(of: editor, matching: find.byType(TextField)).first;
  final saveButton = find.byKey(const ValueKey('editor.save'));
  final saveAndAddAnother = find.byKey(const ValueKey('editor.saveAndAddAnother'));
  final payeeField = find.widgetWithText(TextField, 'Paid to / received from');
  final noteField = find.widgetWithText(TextField, 'Note');

  /// Opens the editor at [location] (pushed over home, so saving pops back);
  /// [location] is read after [seed], so it can name what the seed created.
  Future<ProviderContainer> openEditor(WidgetTester tester, {String Function()? location, Future<void> Function(ProviderContainer container)? seed}) async {
    final container = await pumpApp(tester, seed: seed, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
    appRouter.push(location == null ? '/entry' : location());
    await settle(tester);
    return container;
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: find.descendant(of: editor, matching: find.byType(Scrollable)).first);
    await tester.pump();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
    await reveal(tester, target);
    await tester.tap(target);
    await settle(tester);
  }

  /// The amount sits at the top of a lazy list, so it is only built while scrolled into view.
  Future<String> amountText(WidgetTester tester) async {
    tester.state<ScrollableState>(find.descendant(of: editor, matching: find.byType(Scrollable)).first).position.jumpTo(0);
    await tester.pump();
    return tester.widget<TextField>(amountField).controller!.text;
  }

  Future<void> openMoreDetails(WidgetTester tester) => tapAndSettle(tester, find.text('More details'));

  Future<void> save(WidgetTester tester) async {
    await tester.tap(saveButton);
    await settle(tester);
  }

  Future<List<Entry>> savedEntries(WidgetTester tester, ProviderContainer container) async => (await tester.runAsync(() => liveEntries(container)))!;

  Future<T> read<T>(WidgetTester tester, Future<T> Function() query) async => (await tester.runAsync(query)) as T;

  group('saving', () {
    testWidgets('an empty, zero or malformed amount never saves', (tester) async {
      final container = await openEditor(tester);

      await save(tester);
      expect(find.text('Enter an amount greater than zero'), findsOneWidget);

      await enter(tester, amountField, '.');
      await save(tester);
      expect(find.text('Enter a valid amount, e.g. 250 or 99.50'), findsWidgets);

      expect(await savedEntries(tester, container), isEmpty);
    });

    testWidgets('an expense saves to the default account and moves its balance', (tester) async {
      final container = await openEditor(tester);
      await enter(tester, amountField, '250');
      await save(tester);

      final saved = (await savedEntries(tester, container)).single;
      expect(saved.amountMinor, 25000);
      expect(saved.kind, 'expense');
      final cash = await read(tester, () async => (await container.read(accountsRepositoryProvider).getAll()).single);
      expect(saved.accountId, cash.id);
      expect(cash.balanceMinor, -25000);
      expect(editor, findsNothing, reason: 'saving closes the editor');
    });

    testWidgets('Save & add another keeps the editor open on an empty form', (tester) async {
      final container = await openEditor(tester);
      await enter(tester, amountField, '120');
      await tapAndSettle(tester, find.text('Uncategorised'));
      await tester.tap(find.text('Food & Dining').first);
      await settle(tester);

      await tester.tap(saveAndAddAnother);
      await settle(tester);

      expect(find.text('Saved. Add the next one.'), findsOneWidget);
      expect(find.text('New entry'), findsOneWidget);
      expect(await amountText(tester), isEmpty);
      expect(find.text('Uncategorised'), findsOneWidget, reason: 'the category is cleared for the next entry');
      expect((await savedEntries(tester, container)).single.amountMinor, 12000);
    });

    testWidgets('the calculator fills the amount', (tester) async {
      final container = await openEditor(tester);
      await tester.tap(find.byKey(const ValueKey('editor.calculator')));
      await settle(tester);
      for (final keyId in ['4', 'times', '2', '5']) {
        await tester.tap(find.byKey(ValueKey('calc.key.$keyId')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('calc.use')));
      await settle(tester);

      expect(await amountText(tester), '100');
      await save(tester);
      expect((await savedEntries(tester, container)).single.amountMinor, 10000);
    });

    testWidgets('the date and time buttons set when it happened', (tester) async {
      final container = await openEditor(tester);
      await enter(tester, amountField, '75');
      final today = DateTime.now();
      final pickedDay = today.day == 1 ? 2 : 1;

      await tester.tap(find.byKey(const ValueKey('editor.date')));
      await settle(tester);
      await tester.tap(find.text('$pickedDay').last);
      await tester.tap(find.text('OK'));
      await settle(tester);

      await tester.tap(find.byIcon(Icons.schedule));
      await settle(tester);
      await tester.tap(find.text('OK'));
      await settle(tester);

      await save(tester);
      final saved = (await savedEntries(tester, container)).single;
      expect(saved.occurredAt.day, pickedDay);
      expect(saved.occurredAt.month, today.month);
    });
  });

  group('kinds and accounts', () {
    testWidgets('switching kind clears the amount and category', (tester) async {
      await openEditor(tester);
      await enter(tester, amountField, '90');
      await tapAndSettle(tester, find.text('Uncategorised'));
      await tester.tap(find.text('Food & Dining').first);
      await settle(tester);

      await tester.tap(find.text('Income'));
      await settle(tester);
      expect(await amountText(tester), isEmpty);
      expect(find.text('Uncategorised'), findsOneWidget);
    });

    testWidgets('a transfer needs a second account and saves between both', (tester) async {
      late final String bankId;
      final container = await openEditor(tester, location: () => '/entry?kind=transfer', seed: (container) async {
        bankId = (await container.read(accountsRepositoryProvider).create(name: 'HDFC Savings', type: 'bank', color: 0xFF1E88E5)).id;
      });
      expect(find.text('From account'), findsOneWidget);
      expect(find.text('To account'), findsOneWidget);
      expect(find.text('Uncategorised'), findsNothing, reason: 'transfers have no category');

      await enter(tester, amountField, '1000');
      await save(tester);
      expect(find.text('Pick both accounts for a transfer'), findsOneWidget);

      await tapAndSettle(tester, find.text('To account'));
      await tester.tap(find.byKey(ValueKey('account-option-$bankId')));
      await settle(tester);
      await save(tester);

      final saved = (await savedEntries(tester, container)).single;
      expect(saved.kind, 'transfer');
      expect(saved.toAccountId, bankId);
      expect(saved.categoryId, isNull);
    });

    testWidgets('changing the from account to the to account clears the to account', (tester) async {
      late final String bankId;
      final container = await openEditor(tester, location: () => '/entry?kind=transfer', seed: (container) async {
        bankId = (await container.read(accountsRepositoryProvider).create(name: 'HDFC Savings', type: 'bank', color: 0xFF1E88E5)).id;
      });
      await enter(tester, amountField, '1000');
      await tapAndSettle(tester, find.text('To account'));
      await tester.tap(find.byKey(ValueKey('account-option-$bankId')));
      await settle(tester);

      await tapAndSettle(tester, find.text('From account'));
      await tester.tap(find.byKey(ValueKey('account-option-$bankId')));
      await settle(tester);
      await save(tester);
      expect(find.text('Pick both accounts for a transfer'), findsOneWidget, reason: 'from and to can never be the same account');
      expect(await savedEntries(tester, container), isEmpty);
    });
  });

  group('items', () {
    testWidgets('an unnamed item blocks the save until it has a name', (tester) async {
      final container = await openEditor(tester);
      await openMoreDetails(tester);
      await tapAndSettle(tester, find.text('Add item'));
      await enter(tester, find.widgetWithText(TextField, 'Price per unit'), '40');
      expect(await amountText(tester), '40', reason: 'the amount follows the items');
      expect(find.text('Total of 1 items'), findsOneWidget);

      await save(tester);
      expect(find.text('Every item needs a name'), findsWidgets);
      expect(await savedEntries(tester, container), isEmpty);

      await reveal(tester, find.widgetWithText(TextField, 'Item name'));
      await enter(tester, find.widgetWithText(TextField, 'Item name'), 'Bread');
      await save(tester);
      final saved = (await savedEntries(tester, container)).single;
      expect(saved.amountMinor, 4000);
    });

    testWidgets('items bought before in the category are offered and fill a row', (tester) async {
      late final String groceriesId;
      final container = await openEditor(tester, seed: (container) async {
        groceriesId = await seededCategoryId(container, 'groceries');
        await container.read(entriesRepositoryProvider).saveEntry(
              EntriesRepository.newExpense(id: 'old', amountMinor: 6000, occurredAt: DateTime.now().subtract(const Duration(days: 3)), categoryId: groceriesId),
              items: [ItemDraft(name: 'Rice', quantity: 2, unit: 'kg', unitPriceMinor: 3000).toCompanion('old')],
            );
      });
      await tapAndSettle(tester, find.text('Uncategorised'));
      await tester.enterText(find.widgetWithText(TextField, 'Search categories'), 'groceries');
      await settle(tester);
      await tester.tap(find.text('Groceries').last);
      await settle(tester);
      await openMoreDetails(tester);

      final suggestion = find.widgetWithText(ActionChip, 'Rice · 2 kg @ ₹30');
      await tapAndSettle(tester, suggestion);
      expect(suggestion, findsNothing, reason: 'an item already on the bill is not offered again');
      expect(await amountText(tester), '60');

      await reveal(tester, find.text('kg'));
      await tester.tap(find.text('kg'));
      await settle(tester);
      await tester.tap(find.text('g').last);
      await settle(tester);

      await save(tester);
      final saved = (await savedEntries(tester, container)).singleWhere((entry) => entry.id != 'old');
      expect(saved.categoryId, groceriesId);
      final details = await read(tester, () => container.read(entriesRepositoryProvider).getEntry(saved.id));
      expect(details!.items.single.name, 'Rice');
      expect(details.items.single.unit, 'g');
    });

    testWidgets('editing an entry with items loads them read-only into the amount', (tester) async {
      final container = await openEditor(tester, location: () => '/entry?id=withItems', seed: (container) async => container.read(entriesRepositoryProvider).saveEntry(
            EntriesRepository.newExpense(id: 'withItems', amountMinor: 9000, occurredAt: DateTime.now(), accountId: await cashAccountId(container)),
            items: [ItemDraft(name: 'Paneer', quantity: 1, unitPriceMinor: 9000).toCompanion('withItems')],
          ));
      expect(find.text('Edit entry'), findsOneWidget);
      expect(find.text('Total of 1 items'), findsOneWidget);
      await reveal(tester, find.widgetWithText(TextField, 'Paneer'));
      expect(find.widgetWithText(TextField, 'Paneer'), findsOneWidget, reason: 'More details opens itself for an entry with items');
      expect(saveAndAddAnother, findsNothing, reason: 'edits close on save');

      await tester.tap(find.descendant(of: find.byType(ItemRow), matching: find.byTooltip('Remove')));
      await settle(tester);
      expect(find.byType(ItemRow), findsNothing);
      expect(await amountText(tester), '90', reason: 'the last total stays prefilled');
      expect(find.text('Total of 1 items'), findsNothing);
      await save(tester);
      expect(editor, findsNothing);
      final details = await read(tester, () => container.read(entriesRepositoryProvider).getEntry('withItems'));
      expect(details!.items, isEmpty);
    });
  });

  group('projects', () {
    testWidgets('picking a project shows its entry fields and saves their readings', (tester) async {
      late final String projectId;
      final container = await openEditor(tester, seed: (container) async {
        projectId = await container.read(projectsRepositoryProvider).create(name: 'Car', icon: 'directions_car', color: 0xFF1E88E5);
        await container.read(projectFieldsRepositoryProvider).addField(projectId: projectId, label: 'Odometer', type: ProjectFieldType.number);
      });
      await enter(tester, amountField, '2000');
      await openMoreDetails(tester);

      await tapAndSettle(tester, find.text('Add to project'));
      await tester.tap(find.byKey(ValueKey('project.option.$projectId')));
      await settle(tester);
      expect(find.text('Project details'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Car'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byKey(const ValueKey('editor.project')), matching: find.byIcon(Icons.close)));
      await settle(tester);
      expect(find.text('Add to project'), findsOneWidget);
      expect(find.text('Project details'), findsNothing);

      await tapAndSettle(tester, find.text('Add to project'));
      await tester.tap(find.byKey(ValueKey('project.option.$projectId')));
      await settle(tester);
      await enter(tester, find.widgetWithText(TextField, 'Odometer'), '12500');
      await save(tester);

      final saved = (await savedEntries(tester, container)).single;
      expect(saved.projectId, projectId);
      final readings = await read(tester, () => container.read(projectFieldsRepositoryProvider).valuesForEntry(saved.id));
      expect(readings.values.single.number, 12500);
    });

    testWidgets('a project in the route starts the entry in it', (tester) async {
      late final String projectId;
      final container = await openEditor(tester, location: () => '/entry?project=$projectId', seed: (container) async {
        projectId = await container.read(projectsRepositoryProvider).create(name: 'Trip', icon: 'flight', color: 0xFF1E88E5);
      });
      expect(find.widgetWithText(InputChip, 'Trip'), findsOneWidget, reason: 'More details opens itself for a project entry');

      await enter(tester, amountField, '300');
      await save(tester);
      expect((await savedEntries(tester, container)).single.projectId, projectId);
    });
  });

  group('repeat', () {
    testWidgets('a repeat on a new entry starts a rule, and the entry then links to it', (tester) async {
      final container = await openEditor(tester);
      await enter(tester, amountField, '15000');
      await openMoreDetails(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey('editor.repeat')));
      await tester.tap(find.byKey(const ValueKey('repeat.done')));
      await settle(tester);
      await save(tester);

      final saved = (await savedEntries(tester, container)).single;
      expect(saved.recurringId, isNotNull);
      final rule = await read(tester, () => container.read(recurringRepositoryProvider).getRule(saved.recurringId!));
      expect(rule!.amountMinor, 1500000);
      expect(rule.groupId, isNull);

      appRouter.push('/entry?id=${saved.id}');
      await settle(tester);
      expect(find.byKey(const ValueKey('editor.repeat')), findsNothing, reason: 'repeat is only offered on new entries');
      await tapAndSettle(tester, find.byKey(const ValueKey('editor.recurringRule')));
      expect(find.byType(RecurringRuleFormScreen), findsOneWidget);
      expect(tester.widget<RecurringRuleFormScreen>(find.byType(RecurringRuleFormScreen)).ruleId, saved.recurringId);
    });
  });

  group('editing and deleting', () {
    testWidgets('deleting asks first, then removes the entry and gives the amount back to the account', (tester) async {
      final container = await openEditor(tester);
      await enter(tester, amountField, '400');
      await save(tester);
      final saved = (await savedEntries(tester, container)).single;

      appRouter.push('/entry?id=${saved.id}');
      await settle(tester);
      await tester.tap(find.byTooltip('Delete'));
      await settle(tester);
      expect(find.text('Delete this entry?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(await savedEntries(tester, container), hasLength(1));

      await tester.tap(find.byTooltip('Delete'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);

      expect(await savedEntries(tester, container), isEmpty);
      final cash = await read(tester, () async => (await container.read(accountsRepositoryProvider).getAll()).single);
      expect(cash.balanceMinor, 0, reason: 'the expense is reversed');
      expect(editor, findsNothing);
    });

    testWidgets('Back with nothing to go back to and nothing typed goes home', (tester) async {
      await pumpApp(tester);
      appRouter.go('/entry');
      await settle(tester);
      expect(editor, findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(editor, findsNothing);
      expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), '/home');
    });
  });

  group('prefilled forms', () {
    const smsBody = 'Rs.500.00 debited from A/c XX1234 on 20-Oct-25 to merchant@upi (UPI Ref No 123456789012)';

    testWidgets('an SMS fills the form, creates its account on save and remembers a changed category', (tester) async {
      final received = DateTime(2025, 10, 20, 9, 30);
      final container = await openEditor(tester, location: () => '/entry?sms=sms1', seed: (container) async {
        await container.read(smsLogRepositoryProvider).record(
          id: 'sms1',
          sender: 'VM-HDFCBK-S',
          body: smsBody,
          receivedAt: received,
          status: 'pending',
          parsed: {
            'direction': 'debit',
            'amountMinor': 50000,
            'occurredAt': received.toIso8601String(),
            'counterparty': 'merchant@upi',
            'suggestedCategory': 'groceries',
            'accountKey': 'hdfc:1234',
          },
        );
      });

      expect(await amountText(tester), '500');
      expect(find.text('Groceries'), findsOneWidget, reason: 'the suggested category is picked');
      expect(find.text('Added from SMS. Editing it will not change your bank balance.'), findsOneWidget);
      expect(saveAndAddAnother, findsNothing, reason: 'an SMS entry closes on save');
      expect(find.byKey(const ValueKey('editor.repeat')), findsNothing);

      await tapAndSettle(tester, find.text('Groceries'));
      await tester.enterText(find.widgetWithText(TextField, 'Search categories'), 'restaurants');
      await settle(tester);
      await tester.tap(find.text('Restaurants & Cafes').last);
      await settle(tester);
      await save(tester);

      final saved = (await savedEntries(tester, container)).single;
      expect(saved.source, 'sms');
      expect(saved.smsId, 'sms1');
      expect(saved.occurredAt, received);
      expect(saved.payee, 'merchant@upi');
      final accounts = await read(tester, () => container.read(accountsRepositoryProvider).getAll());
      expect(saved.accountId, isNotNull);
      expect(accounts.map((account) => account.id), contains(saved.accountId), reason: 'the SMS account is created on save');
      expect(accounts.firstWhere((account) => account.id == saved.accountId).balanceMinor, 0, reason: 'SMS entries never move a balance');
      final log = await read(tester, () => container.read(smsLogRepositoryProvider).getById('sms1'));
      expect(log!.status, 'added');
      final remembered = await read(tester, () => container.read(smsIngestServiceProvider).rememberedCategoryFor(kind: 'expense', counterparty: 'merchant@upi'));
      expect(remembered?.id, await read(tester, () => seededCategoryId(container, 'restaurants')));
    });

    testWidgets('an SMS that was never parsed keeps its time and cannot save without an account', (tester) async {
      final received = DateTime(2025, 9, 2, 18, 5);
      final container = await openEditor(tester, location: () => '/entry?sms=raw', seed: (container) => container.read(smsLogRepositoryProvider).record(
            id: 'raw',
            sender: 'AB-SHOPPY',
            body: 'Thanks for shopping with us',
            receivedAt: received,
            status: 'pending',
          ));
      expect(await amountText(tester), isEmpty);
      expect(find.text('Added from SMS. Editing it will not change your bank balance.'), findsOneWidget);

      await enter(tester, amountField, '80');
      await save(tester);
      expect(find.text('Pick an account'), findsWidgets);
      expect(await savedEntries(tester, container), isEmpty);
      expect(editor, findsOneWidget);
    });

    testWidgets('a due reminder fills the form and is marked paid on save', (tester) async {
      late final String reminderId;
      late final String electricityId;
      final container = await openEditor(tester, location: () => '/entry?reminder=$reminderId', seed: (container) async {
        electricityId = await seededCategoryId(container, 'electricity');
        reminderId = await container.read(remindersRepositoryProvider).save(ReminderDraft(
              kind: ReminderKind.bill,
              title: 'Power bill',
              notes: 'October',
              amountMinor: 120000,
              categoryId: electricityId,
              dueAt: DateTime.now(),
            ));
      });

      expect(await amountText(tester), '1200');
      expect(find.widgetWithText(TextField, 'Power bill'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'October'), findsOneWidget);
      expect(saveAndAddAnother, findsNothing);

      await save(tester);
      expect(find.text('Marked paid'), findsOneWidget);
      final saved = (await savedEntries(tester, container)).single;
      expect(saved.categoryId, electricityId);
      expect(saved.payee, 'Power bill');
      final db = container.read(databaseProvider);
      final reminder = await read(tester, () => (db.select(db.reminders)..where((row) => row.id.equals(reminderId))).getSingle());
      expect(reminder.entryId, saved.id);
    });

    testWidgets('a reminder or SMS that no longer exists opens an empty form', (tester) async {
      await openEditor(tester, location: () => '/entry?reminder=gone');
      expect(await amountText(tester), isEmpty);
      appRouter.pop();
      appRouter.push('/entry?sms=gone');
      await settle(tester);
      expect(await amountText(tester), isEmpty);
      expect(payeeField, findsNothing);
      expect(noteField, findsNothing);
    });
  });
}
