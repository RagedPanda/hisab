import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/reminder_scheduler.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/accounts_repository.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../domain/cards/card_reminder.dart';
import '../../domain/cards/card_summary.dart';
import '../../domain/reminders/reminder_kind.dart';
import 'card_providers.dart';

/// Keeps each credit card's automatic "card due" reminder in step with its
/// statement day, due day and last statement. The decision is the pure
/// [planCardReminder]; this class only reads the rows it needs and applies
/// the result through [ReminderScheduler] so notifications follow.
class CardReminderSync {
  CardReminderSync({
    required this.accounts,
    required this.entries,
    required this.reminders,
    required this.scheduler,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AccountsRepository accounts;
  final EntriesRepository entries;
  final RemindersRepository reminders;
  final ReminderScheduler scheduler;
  final DateTime Function() _clock;

  /// Syncs one account after it is saved; a non-card loses its reminder.
  Future<void> syncAccount(Account account) async {
    final today = _clock();
    final isCard = account.type == 'card';
    final movements = isCard ? await entries.getAccountMovements(account.id, since: cardMovementsSince(account, today)) : const <CardMovement>[];
    final due = isCard ? cardOverviewFor(account, movements, today).due : null;
    await _apply(account.id, account.name, due: due);
  }

  /// Syncs the account with [id] as stored now (or removes its reminder
  /// when it is gone).
  Future<void> syncAccountById(String id) async {
    final account = await accounts.getById(id);
    if (account == null) return removeForAccount(id);
    return syncAccount(account);
  }

  /// Removes the pending reminder of an account that was deleted.
  Future<void> removeForAccount(String accountId) => _apply(accountId, '', due: null);

  /// Syncs every live card (run at startup, so due dates roll forward).
  Future<void> syncAll() async {
    for (final account in await accounts.getAll()) {
      if (account.type == 'card') await syncAccount(account);
    }
  }

  Future<void> _apply(String accountId, String cardName, {required CardDue? due}) async {
    final stored = await reminders.latestForAccount(accountId, kind: ReminderKind.card);
    final action = planCardReminder(
      accountId: accountId,
      cardName: cardName,
      due: due,
      existing: stored == null ? null : existingCardReminderOf(stored),
    );
    switch (action) {
      case KeepCardReminder():
        return;
      case SaveCardReminder(:final draft):
        await scheduler.save(draft);
      case DeleteCardReminder(:final id):
        await scheduler.delete(id);
    }
  }
}

/// The planner's view of a stored reminder row.
ExistingCardReminder existingCardReminderOf(Reminder row) =>
    ExistingCardReminder(id: row.id, dueAt: row.dueAt!, status: row.status, title: row.title, amountMinor: row.amountMinor);

final cardReminderSyncProvider = Provider((ref) => CardReminderSync(
      accounts: ref.watch(accountsRepositoryProvider),
      entries: ref.watch(entriesRepositoryProvider),
      reminders: ref.watch(remindersRepositoryProvider),
      scheduler: ref.watch(reminderSchedulerProvider),
    ));

/// Runs a reminder sync after an account write without letting a failure
/// (say, notifications unavailable) undo or block that write.
Future<void> syncCardReminderSafely(Future<void> Function() sync) async {
  try {
    await sync();
  } catch (error, stack) {
    debugPrint('Hisab: card due reminder not updated: $error\n$stack');
  }
}
