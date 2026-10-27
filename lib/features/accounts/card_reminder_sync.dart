import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
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
///
/// Every public call runs one at a time (in call order), so an explicit sync
/// after a save and a live sync from [watchChanges] never both see "no
/// reminder yet" and create two.
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

  /// Tail of the queue that serialises every sync.
  Future<void> _tail = Future<void>.value();

  /// Whether a live sync is queued but has not started yet (bursts of table
  /// changes then share it).
  bool _liveSyncQueued = false;

  Future<void> _serial(Future<void> Function() task) {
    final run = _tail.then((_) => task());
    _tail = run.catchError((Object _) {});
    return run;
  }

  /// Re-syncs every card whenever [changes] fires (account or entry writes),
  /// so a payment, an edit or a new spend updates the reminder's date and
  /// amount without waiting for a restart. Cancel the result to stop.
  StreamSubscription<void> watchChanges(Stream<void> changes) => changes.listen((_) {
        if (_liveSyncQueued) return;
        _liveSyncQueued = true;
        syncCardReminderSafely(() => _serial(() {
              _liveSyncQueued = false;
              return _syncAll();
            }));
      });

  /// Syncs one account after it is saved; a non-card loses its reminder.
  Future<void> syncAccount(Account account) => _serial(() => _syncAccount(account));

  Future<void> _syncAccount(Account account) async {
    final today = _clock();
    final isCard = account.type == 'card';
    final movements = isCard ? await entries.getAccountMovements(account.id, since: cardMovementsSince(account, today)) : const <CardMovement>[];
    final due = isCard ? cardOverviewFor(account, movements, today).due : null;
    await _apply(account.id, account.name, due: due);
  }

  /// Syncs the account with [id] as stored now (or removes its reminder
  /// when it is gone).
  Future<void> syncAccountById(String id) => _serial(() async {
        final account = await accounts.getById(id);
        if (account == null) return _removeForAccount(id);
        return _syncAccount(account);
      });

  /// Removes every pending card reminder of an account that was deleted.
  Future<void> removeForAccount(String accountId) => _serial(() => _removeForAccount(accountId));

  Future<void> _removeForAccount(String accountId) => _apply(accountId, '', due: null);

  /// Syncs every live card (run at startup, so due dates roll forward) and
  /// drops pending card reminders left behind by cards that are gone.
  Future<void> syncAll() => _serial(_syncAll);

  Future<void> _syncAll() async {
    final cards = [for (final account in await accounts.getAll()) if (account.type == 'card') account];
    for (final card in cards) {
      await _syncAccount(card);
    }
    final pending = await reminders.getUpcoming();
    for (final accountId in orphanedCardReminderAccounts(pending, liveCardIds: {for (final card in cards) card.id})) {
      await _removeForAccount(accountId);
    }
  }

  Future<void> _apply(String accountId, String cardName, {required CardDue? due}) async {
    final stored = await reminders.forAccount(accountId, kind: ReminderKind.card);
    final plan = planCardReminder(
      accountId: accountId,
      cardName: cardName,
      due: due,
      existing: [for (final row in stored) existingCardReminderOf(row)],
    );
    for (final id in plan.deleteIds) {
      await scheduler.delete(id);
    }
    final draft = plan.save;
    if (draft != null) await scheduler.save(draft);
  }
}

/// Accounts that still have pending card reminders but are no longer live cards.
Set<String> orphanedCardReminderAccounts(List<Reminder> pending, {required Set<String> liveCardIds}) => {
      for (final reminder in pending)
        if (reminder.kind == ReminderKind.card.key && reminder.accountId != null && !liveCardIds.contains(reminder.accountId)) reminder.accountId!,
    };

/// The planner's view of a stored reminder row.
ExistingCardReminder existingCardReminderOf(Reminder row) =>
    ExistingCardReminder(status: row.status, draft: reminderDraftFrom(row));

final cardReminderSyncProvider = Provider((ref) => CardReminderSync(
      accounts: ref.watch(accountsRepositoryProvider),
      entries: ref.watch(entriesRepositoryProvider),
      reminders: ref.watch(remindersRepositoryProvider),
      scheduler: ref.watch(reminderSchedulerProvider),
    ));

/// Keeps card reminders live while the app runs: accounts and entries table
/// writes trigger [CardReminderSync.watchChanges]. Read it once at startup;
/// the subscription ends when the container is disposed.
final cardReminderLiveSyncProvider = Provider<StreamSubscription<void>>((ref) {
  final db = ref.watch(databaseProvider);
  final changes = db.tableUpdates(TableUpdateQuery.onAllTables([db.accounts, db.entries]));
  final subscription = ref.watch(cardReminderSyncProvider).watchChanges(changes);
  ref.onDispose(subscription.cancel);
  return subscription;
});

/// Runs a reminder sync after an account write without letting a failure
/// (say, notifications unavailable) undo or block that write.
Future<void> syncCardReminderSafely(Future<void> Function() sync) async {
  try {
    await sync();
  } catch (error, stack) {
    debugPrint('Hisab: card due reminder not updated: $error\n$stack');
  }
}
