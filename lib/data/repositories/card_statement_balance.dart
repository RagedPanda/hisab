import 'package:drift/drift.dart' show Value;

import '../../domain/cards/card_sms_facts.dart';
import '../../domain/cards/card_summary.dart';
import '../db/database.dart';
import 'accounts_repository.dart';
import 'entries_repository.dart';

/// Brings the balance of each card among [accountIds] that follows its SMS
/// statement ([balanceFollowsSmsStatement]) in line with the entries recorded
/// since ([balanceSinceStatementMinor]). SMS entries never move balances, so
/// adding, editing, undoing or deleting a card spend or bill payment read
/// from SMS is counted here. Other accounts and nulls are left alone.
Future<void> refreshStatementBalances({
  required EntriesRepository entries,
  required AccountsRepository accounts,
  required Iterable<String?> accountIds,
}) async {
  for (final id in {...accountIds.whereType<String>()}) {
    final card = await accounts.getById(id);
    if (card == null || !balanceFollowsSmsStatement(card)) continue;
    final balance = await balanceSinceStatement(entries, cardId: card.id, statementMinor: card.lastStatementMinor!, statementAt: card.lastStatementAt!);
    if (balance != card.balanceMinor) await accounts.update(AccountsCompanion(id: Value(card.id), balanceMinor: Value(balance)));
  }
}

/// What [cardId] owes counted from a statement of [statementMinor] on
/// [statementAt] and the entries since ([balanceSinceStatementMinor]).
Future<int> balanceSinceStatement(
  EntriesRepository entries, {
  required String cardId,
  required int statementMinor,
  required DateTime statementAt,
}) async =>
    balanceSinceStatementMinor(
      cardId: cardId,
      statementMinor: statementMinor,
      statementAt: statementAt,
      movements: await entries.getAccountMovements(cardId, since: statementAt),
    );
