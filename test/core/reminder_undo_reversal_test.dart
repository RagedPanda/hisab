import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/notifications/notification_service.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/core/notifications/reminder_scheduler.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/entry_removal.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/data/repositories/reminders_repository.dart';
import 'package:hisab/domain/ledger/balance_effects.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';

import 'fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late EntriesRepository entries;
  late AccountsRepository accounts;
  late GroupsRepository groups;
  late ReminderScheduler scheduler;
  final now = DateTime(2026, 10, 22, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    entries = EntriesRepository(db);
    accounts = AccountsRepository(db);
    groups = GroupsRepository(db);
    scheduler = ReminderScheduler(
      reminders: RemindersRepository(db, clock: () => now),
      notifications: NotificationService(
        FakeNotificationGateway(),
        buildAlert: (r, a) => alertRequestFor(r, a, notificationLocalizations('en'), currencySymbol: '₹'),
        clock: () => now,
      ),
      removeEntry: (entryId) => deleteEntryReversingBalances(entries: entries, accounts: accounts, entryId: entryId),
      clock: () => now,
    );
  });

  tearDown(() => db.close());

  Future<String> addBill({ReminderRepeat repeat = ReminderRepeat.monthly}) => scheduler.save(ReminderDraft(
        kind: ReminderKind.bill,
        title: 'Rent',
        amountMinor: 500000,
        dueAt: DateTime(2026, 11, 5),
        repeat: repeat,
        remindDaysBefore: const [1],
        notifyAtMinute: 9 * 60,
      ));

  Future<int> balanceOf(String accountId) async =>
      (await (db.select(db.accounts)..where((t) => t.id.equals(accountId))).getSingle()).balanceMinor;

  Future<Entry> entryRow(String id) => (db.select(db.entries)..where((t) => t.id.equals(id))).getSingle();

  test('undo of paid deletes the recorded entry and restores the account balance', () async {
    final account = await accounts.create(name: 'HDFC', type: 'bank', color: 0xFF000000, balanceMinor: 1000000);
    final reminderId = await addBill();
    final entryId = newId();
    await entries.saveEntry(EntriesRepository.newExpense(id: entryId, amountMinor: 500000, occurredAt: now, accountId: account.id));
    await accounts.applyBalanceDeltas(postingDeltas(snapshotOfEntry(await entryRow(entryId))));
    await scheduler.markDone(reminderId, entryId: entryId);
    expect(await balanceOf(account.id), 500000);

    await scheduler.undoDone(reminderId);

    expect(await balanceOf(account.id), 1000000, reason: 'paying 5,000 then Undo leaves the full 10,000');
    expect((await entryRow(entryId)).deletedAt, isNotNull);
    final reopened = await (db.select(db.reminders)..where((t) => t.id.equals(reminderId))).getSingle();
    expect(reopened.status, ReminderStatus.pending);
    expect(reopened.entryId, isNull);
  });

  test('undo of a group payment returns group balances to what they were', () async {
    final groupId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me', otherMembers: ['Priya']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final priya = members.firstWhere((m) => !m.isMe).id;
    final rent = newId();
    await entries.saveEntry(
      EntriesRepository.newExpense(id: rent, amountMinor: 2000000, occurredAt: now, groupId: groupId, paidByMemberId: priya, splitMethod: 'equal'),
      splits: [
        SplitsCompanion.insert(id: newId(), entryId: rent, memberId: me, amountMinor: 1000000),
        SplitsCompanion.insert(id: newId(), entryId: rent, memberId: priya, amountMinor: 1000000),
      ],
    );
    final before = Map.of((await groups.getBalances(groupId)).net);
    expect(before[me], -1000000, reason: 'I owe 10,000');

    final reminderId = await addBill(repeat: ReminderRepeat.once);
    final payment = newId();
    await entries.saveEntry(
      EntriesRepository.newExpense(id: payment, amountMinor: 500000, occurredAt: now, groupId: groupId, paidByMemberId: me, splitMethod: 'exact'),
      splits: [SplitsCompanion.insert(id: newId(), entryId: payment, memberId: priya, amountMinor: 500000)],
    );
    await scheduler.markDone(reminderId, entryId: payment);
    expect((await groups.getBalances(groupId)).net[me], isNot(before[me]));

    await scheduler.undoDone(reminderId);

    expect((await groups.getBalances(groupId)).net, before, reason: 'still owe 10,000 after Undo');
  });

  test('undo of a skipped reminder leaves entries alone', () async {
    final reminderId = await addBill();
    final unrelated = newId();
    await entries.saveEntry(EntriesRepository.newExpense(id: unrelated, amountMinor: 1000, occurredAt: now));
    await scheduler.skip(reminderId);

    await scheduler.undoDone(reminderId);

    expect((await entryRow(unrelated)).deletedAt, isNull);
  });

  test('deleteEntryReversingBalances is a no-op for a missing or already deleted entry', () async {
    final account = await accounts.create(name: 'Cash', type: 'cash', color: 0xFF000000, balanceMinor: 3000);
    await deleteEntryReversingBalances(entries: entries, accounts: accounts, entryId: 'missing');
    final entryId = newId();
    await entries.saveEntry(EntriesRepository.newExpense(id: entryId, amountMinor: 1000, occurredAt: now, accountId: account.id));
    await accounts.applyBalanceDeltas(postingDeltas(snapshotOfEntry(await entryRow(entryId))));

    await deleteEntryReversingBalances(entries: entries, accounts: accounts, entryId: entryId);
    await deleteEntryReversingBalances(entries: entries, accounts: accounts, entryId: entryId);

    expect(await balanceOf(account.id), 3000, reason: 'reversed exactly once');
  });
}
