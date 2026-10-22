import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/cards/card_summary.dart';

/// One live account by id; null once it is deleted.
final accountByIdProvider = StreamProvider.family<Account?, String>((ref, id) => ref.watch(accountsRepositoryProvider).watchById(id));

/// Entries touching a card from a given day on (see [movementsSince]).
final cardMovementsProvider = StreamProvider.family<List<CardMovement>, ({String cardId, DateTime since})>(
  (ref, query) => ref.watch(entriesRepositoryProvider).watchAccountMovements(query.cardId, since: query.since),
);

/// The card screen's figures for [account] as of [today].
CardOverview cardOverviewFor(Account account, List<CardMovement> movements, DateTime today) => buildCardOverview(
      cardId: account.id,
      today: today,
      balanceMinor: account.balanceMinor,
      movements: movements,
      statementDay: account.statementDay,
      dueDay: account.dueDay,
      creditLimitMinor: account.creditLimitMinor,
      lastStatementMinor: account.lastStatementMinor,
      lastStatementAt: account.lastStatementAt,
    );

/// The window of movements [cardOverviewFor] needs for [account].
DateTime cardMovementsSince(Account account, DateTime today) =>
    movementsSince(today: today, statementDay: account.statementDay, lastStatementAt: account.lastStatementAt);
