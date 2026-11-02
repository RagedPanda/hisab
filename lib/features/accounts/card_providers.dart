import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/cards/card_summary.dart';
import '../../l10n/l10n.dart';

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

/// Whether [account] is a live credit card (the card screen only fits those).
bool isCardAccount(Account? account) => account != null && account.type == 'card';

/// What the card [account] shows in account lists ([cardHeadline]), kept up
/// to date with the bill payments since its last statement.
CardHeadline watchCardHeadline(WidgetRef ref, Account account) {
  final since = account.lastStatementAt;
  final movements = since == null ? const <CardMovement>[] : ref.watch(cardMovementsProvider((cardId: account.id, since: since))).value ?? const <CardMovement>[];
  return cardHeadline(
    balanceMinor: account.balanceMinor,
    lastStatementMinor: account.lastStatementMinor,
    paidSinceStatementMinor: since == null ? 0 : paymentsSinceMinor(movements, cardId: account.id, since: since),
  );
}

/// [headline] as text: "Due ₹X", "Paid", "₹X credit" or "Nothing due", amounts written by [format].
String cardHeadlineText(AppLocalizations l10n, CardHeadline headline, String Function(int amountMinor) format) => switch (headline.kind) {
      CardHeadlineKind.due => l10n.cardDue(format(headline.amountMinor)),
      CardHeadlineKind.paid => l10n.cardPaid,
      CardHeadlineKind.credit => l10n.cardInCredit(format(headline.amountMinor)),
      CardHeadlineKind.clear => l10n.cardNothingDue,
    };
