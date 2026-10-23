import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/notification_service.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/core/notifications/reminder_scheduler.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/reminders_repository.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/features/accounts/card_reminder_sync.dart';

import '../core/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late AccountsRepository accounts;
  late RemindersRepository reminders;
  late CardReminderSync sync;
  var now = DateTime(2026, 10, 8, 10);

  setUp(() {
    now = DateTime(2026, 10, 8, 10);
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    accounts = AccountsRepository(db);
    reminders = RemindersRepository(db, clock: () => now);
    final scheduler = ReminderScheduler(
      reminders: reminders,
      notifications: NotificationService(gateway,
          buildAlert: (r, a) => alertRequestFor(r, a, notificationLocalizations('en'), currencySymbol: '₹'), clock: () => now),
      clock: () => now,
    );
    sync = CardReminderSync(accounts: accounts, entries: EntriesRepository(db), reminders: reminders, scheduler: scheduler, clock: () => now);
  });

  tearDown(() => db.close());

  Future<Account> addCard({int? dueDay = 15, int? lastStatementMinor = 2500000}) => accounts.create(
        name: 'HDFC Millennia',
        type: 'card',
        color: 0xFF1E88E5,
        balanceMinor: -2500000,
        statementDay: 5,
        dueDay: dueDay,
        lastStatementMinor: lastStatementMinor,
        lastStatementAt: lastStatementMinor == null ? null : DateTime(2026, 10, 5),
      );

  Future<List<Reminder>> cardReminders() => (db.select(db.reminders)
        ..where((t) => t.kind.equals(ReminderKind.card.key) & t.deletedAt.isNull()))
      .get();

  test('a card with a due day gets a scheduled card due reminder for its bill', () async {
    final card = await addCard();
    await sync.syncAccount(card);
    final rows = await cardReminders();
    expect(rows, hasLength(1));
    expect(rows.single.accountId, card.id);
    expect(rows.single.title, 'HDFC Millennia');
    expect(rows.single.dueAt, DateTime(2026, 10, 15));
    expect(rows.single.amountMinor, 2500000);
    expect(rows.single.status, ReminderStatus.pending);
    expect(gateway.scheduled, isNotEmpty);
  });

  test('syncing again changes nothing; a new due day moves the same reminder', () async {
    final card = await addCard();
    await sync.syncAccount(card);
    await sync.syncAccount(card);
    final first = (await cardReminders()).single;
    await accounts.update(AccountsCompanion(id: Value(card.id), dueDay: const Value(20)));
    await sync.syncAccountById(card.id);
    final moved = (await cardReminders()).single;
    expect(moved.id, first.id);
    expect(moved.dueAt, DateTime(2026, 10, 20));
  });

  test('a payment towards the bill lowers the reminder amount', () async {
    final card = await addCard();
    await sync.syncAccount(card);
    await EntriesRepository(db).saveEntry(EntriesRepository.newExpense(kind: 'transfer', amountMinor: 1000000, occurredAt: DateTime(2026, 10, 7), accountId: 'bank')
        .copyWith(toAccountId: Value(card.id)));
    await sync.syncAll();
    expect((await cardReminders()).single.amountMinor, 1500000);
  });

  test('a bill marked paid is not raised again', () async {
    final card = await addCard();
    await sync.syncAccount(card);
    await reminders.markDone((await cardReminders()).single.id);
    await sync.syncAll();
    final rows = await cardReminders();
    expect(rows, hasLength(1));
    expect(rows.single.status, ReminderStatus.done);
  });

  test('clearing the due day or deleting the card removes the pending reminder and its alerts', () async {
    final card = await addCard();
    await sync.syncAccount(card);
    await accounts.update(AccountsCompanion(id: Value(card.id), dueDay: const Value(null)));
    await sync.syncAccountById(card.id);
    expect(await cardReminders(), isEmpty);
    expect(gateway.scheduled, isEmpty);

    final other = await addCard();
    await sync.syncAccount(other);
    await accounts.delete(other.id);
    await sync.syncAccountById(other.id);
    expect(await cardReminders(), isEmpty);
  });

  test('accounts that are not cards never get one', () async {
    final bank = await accounts.create(name: 'Savings', type: 'bank', color: 0xFF43A047);
    await sync.syncAccount(bank);
    await sync.syncAll();
    expect(await cardReminders(), isEmpty);
  });

  Future<List<Reminder>> pendingCardReminders() async =>
      [for (final row in await cardReminders()) if (row.status == ReminderStatus.pending) row];

  Future<void> editCard(String id, AccountsCompanion changes) async {
    await accounts.update(changes.copyWith(id: Value(id)));
    await sync.syncAccountById(id);
  }

  Future<Account> cardWithNewerPaidReminder() async {
    final card = await addCard(dueDay: 25);
    await EntriesRepository(db).saveEntry(EntriesRepository.newExpense(kind: 'transfer', amountMinor: 2500000, occurredAt: DateTime(2026, 10, 7), accountId: 'bank')
        .copyWith(toAccountId: Value(card.id)));
    await sync.syncAll();
    final nextBill = (await pendingCardReminders()).single;
    expect(nextBill.dueAt, DateTime(2026, 11, 25), reason: 'paid: next cycle');
    await reminders.markDone(nextBill.id);
    return card;
  }

  test('editing a card with a newer paid reminder updates one pending reminder in place (#59)', () async {
    final card = await cardWithNewerPaidReminder();
    await editCard(card.id, const AccountsCompanion(lastStatementMinor: Value(3000000)));
    final first = (await pendingCardReminders()).single;
    expect(first.dueAt, DateTime(2026, 10, 25));
    for (final dueDay in [20, 23, 24, 31]) {
      await editCard(card.id, AccountsCompanion(dueDay: Value(dueDay)));
      final pending = await pendingCardReminders();
      expect(pending, hasLength(1), reason: 'due day $dueDay');
      expect(pending.single.id, first.id);
      expect(pending.single.dueAt, DateTime(2026, 10, dueDay));
    }
    expect((await cardReminders()).where((row) => row.status == ReminderStatus.done), hasLength(1), reason: 'paid one stays in history');
  });

  test('clearing the due day removes the pending reminder despite a newer paid one, and cancels alerts (#59)', () async {
    final card = await cardWithNewerPaidReminder();
    await editCard(card.id, const AccountsCompanion(lastStatementMinor: Value(3000000)));
    final pendingId = (await pendingCardReminders()).single.id;
    expect(gateway.alertsFor(reminderPayload(pendingId)), isNotEmpty);
    await editCard(card.id, const AccountsCompanion(dueDay: Value(null)));
    expect(await pendingCardReminders(), isEmpty);
    expect(gateway.alertsFor(reminderPayload(pendingId)), isEmpty);
  });

  test('deleting a card removes all its pending reminders and their alerts (#59)', () async {
    final card = await cardWithNewerPaidReminder();
    await editCard(card.id, const AccountsCompanion(lastStatementMinor: Value(3000000)));
    final pendingId = (await pendingCardReminders()).single.id;
    await accounts.delete(card.id);
    await sync.removeForAccount(card.id);
    expect(await pendingCardReminders(), isEmpty);
    expect(gateway.alertsFor(reminderPayload(pendingId)), isEmpty);
  });

  test('startup collapses duplicates and clears reminders of cards deleted earlier (#59)', () async {
    final card = await addCard();
    final gone = await addCard();
    for (final account in [card, gone, card]) {
      await reminders.save(ReminderDraft(kind: ReminderKind.card, title: account.name, accountId: account.id, dueAt: DateTime(2026, 10, 15)));
    }
    await accounts.delete(gone.id);
    await sync.syncAll();
    final pending = await pendingCardReminders();
    expect(pending, hasLength(1));
    expect(pending.single.accountId, card.id);
  });
}
