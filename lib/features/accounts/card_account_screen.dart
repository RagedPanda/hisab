import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/notifications/alarm_timing.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/cards/card_summary.dart';
import '../../domain/reminders/reminder_draft.dart';
import '../../l10n/l10n.dart';
import '../dashboard/widgets/dashboard_card.dart';
import '../reminders/reminder_late_note.dart';
import '../shell/widgets/budget_row.dart';
import '../shell/widgets/common.dart';
import 'accounts_screen.dart';
import 'card_providers.dart';

const Key kCardOutstandingKey = ValueKey('card.outstanding');
const Key kCardDueKey = ValueKey('card.due');
const Key kCardDueChipKey = ValueKey('card.dueChip');
const Key kCardCycleKey = ValueKey('card.cycle');
const Key kCardStatementKey = ValueKey('card.statement');
const Key kCardSmsLimitKey = ValueKey('card.smsLimit');

/// A credit card: what is owed against the limit, when the bill is due, this
/// cycle's spend and the last statement.
class CardAccountScreen extends ConsumerWidget {
  const CardAccountScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accountValue = ref.watch(accountByIdProvider(accountId));
    if (!accountValue.hasValue) return Scaffold(appBar: AppBar());
    final account = accountValue.value;
    if (account == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.credit_card_off_outlined, title: l10n.cardNotFound));
    }
    final today = startOfDay(DateTime.now());
    final movements = ref.watch(cardMovementsProvider((cardId: account.id, since: cardMovementsSince(account, today)))).value ?? const <CardMovement>[];
    final overview = cardOverviewFor(account, movements, today);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final locale = Localizations.localeOf(context).toString();
    final permission = ref.watch(notificationPermissionProvider).value;
    String shortDate(DateTime date) => formatRowDate(date, now: today, locale: locale);
    return HomeFallbackPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(account.name),
          actions: [
            IconButton(tooltip: l10n.edit, icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, ref, account)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            _OutstandingCard(overview: overview, moneyFormat: moneyFormat, account: account, shortDate: shortDate),
            const SizedBox(height: kDashboardCardGap),
            _DueCard(overview: overview, moneyFormat: moneyFormat, locale: locale, minimumDueMinor: account.minimumDueMinor, onSetUp: () => _edit(context, ref, account)),
            // A card with a due date has a due reminder with alerts.
            if (remindersMayArriveLate(permission, hasAlerts: overview.due != null)) const ReminderLateNote(),
            const SizedBox(height: kDashboardCardGap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _FigureCard(
                      key: kCardCycleKey,
                      label: l10n.cardThisCycle,
                      value: overview.cycleSpendMinor == null ? '—' : formatMinor(overview.cycleSpendMinor!, format: moneyFormat, showDecimals: false),
                      caption: overview.cycle == null
                          ? l10n.cardDayNotSet
                          : l10n.cardCycleDates(shortDate(overview.cycle!.start), shortDate(overview.cycle!.end.subtract(const Duration(days: 1)))),
                    ),
                  ),
                  const SizedBox(width: kDashboardCardGap),
                  Expanded(
                    child: _FigureCard(
                      key: kCardStatementKey,
                      label: l10n.cardLastStatement,
                      value: account.lastStatementMinor == null ? '—' : formatMinor(account.lastStatementMinor!, format: moneyFormat, showDecimals: false),
                      caption: account.lastStatementAt == null
                          ? l10n.cardNoStatement
                          : [
                              l10n.cardStatementOn(shortDate(account.lastStatementAt!)),
                              if (account.statementFromSmsAt != null) l10n.cardFromSms(shortDate(account.statementFromSmsAt!)),
                            ].join('\n'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => context.go(Uri(path: '/transactions', queryParameters: {'account': account.id}).toString()),
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(l10n.cardViewTransactions),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the account sheet; when the account is no longer a card afterwards
/// (type changed or deleted) the card screen is left for the Accounts list.
Future<void> _edit(BuildContext context, WidgetRef ref, Account account) async {
  await showAccountForm(context, ref, existing: account);
  final saved = await ref.read(accountsRepositoryProvider).getById(account.id);
  if (!context.mounted || isCardAccount(saved)) return;
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/accounts');
  }
}

/// Outstanding amount, utilisation bar and available limit, plus the
/// available limit the card's last SMS reported.
class _OutstandingCard extends StatelessWidget {
  const _OutstandingCard({required this.overview, required this.moneyFormat, required this.account, required this.shortDate});
  final CardOverview overview;
  final MoneyFormat moneyFormat;
  final Account account;
  final String Function(DateTime date) shortDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final available = overview.availableMinor;
    final band = utilisationBand(overview.utilisation);
    return DashboardCard(
      key: kCardOutstandingKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cardOutstanding, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            overview.creditMinor > 0 ? l10n.cardInCredit(formatMinor(overview.creditMinor, format: moneyFormat)) : formatMinor(overview.outstandingMinor, format: moneyFormat),
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: overview.creditMinor > 0 ? kIncomeColor : null).tabular,
          ),
          if (overview.hasLimit) ...[
            const SizedBox(height: 12),
            // The "% of limit used" line below says the same in words; the bare
            // bar value would otherwise lead the card's spoken label.
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: overview.utilisation.clamp(0, 1),
                  minHeight: 8,
                  color: budgetBandColor(band, scheme),
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.cardLimitUsed(overview.utilisationPercent, formatMinor(overview.creditLimitMinor!, format: moneyFormat, showDecimals: false)),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant).tabular,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(l10n.cardAvailableLimit, style: theme.textTheme.bodyMedium)),
                Text(
                  available! < 0 ? l10n.cardOverLimitBy(formatMinor(-available, format: moneyFormat, showDecimals: false)) : formatMinor(available, format: moneyFormat, showDecimals: false),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: available < 0 ? kExpenseColor : null).tabular,
                ),
              ],
            ),
          ],
          if (account.availableLimitMinor != null && account.availableLimitAt != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.cardSmsAvailableLimit(formatMinor(account.availableLimitMinor!, format: moneyFormat, showDecimals: false), shortDate(account.availableLimitAt!)),
              key: kCardSmsLimitKey,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant).tabular,
            ),
          ],
        ],
      ),
    );
  }
}

/// Due date with a days-left chip and the unpaid part of the statement; a
/// prompt to fill in the card's days when they are missing.
class _DueCard extends StatelessWidget {
  const _DueCard({required this.overview, required this.moneyFormat, required this.locale, required this.minimumDueMinor, required this.onSetUp});
  final CardOverview overview;
  final MoneyFormat moneyFormat;
  final String locale;

  /// The statement's minimum due, read from its SMS.
  final int? minimumDueMinor;
  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final due = overview.due;
    if (due == null) {
      return DashboardCard(
        key: kCardDueKey,
        onTap: onSetUp,
        child: Row(
          children: [
            Icon(Icons.event_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.cardSetUpDays, style: theme.textTheme.titleSmall)),
            const Icon(Icons.chevron_right),
          ],
        ),
      );
    }
    final amountDue = reminderAmountOrNone(due.amountDueMinor);
    return DashboardCard(
      key: kCardDueKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reminderDueDate, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(formatShortDate(due.dueDate, locale: locale), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700).tabular),
              CardDueChip(due: due),
            ],
          ),
          if (due.state == CardDueState.paid && due.nextDueDate != null) ...[
            const SizedBox(height: 8),
            Text(l10n.cardNextDue(formatShortDate(due.nextDueDate!, locale: locale)), style: theme.textTheme.bodyMedium?.tabular),
          ],
          if (amountDue != null) ...[
            const SizedBox(height: 8),
            Text(l10n.cardAmountLeftToPay(formatMinor(amountDue, format: moneyFormat)), style: theme.textTheme.bodyMedium?.tabular),
            if (minimumDueMinor != null) ...[
              const SizedBox(height: 4),
              Text(l10n.cardMinimumDue(formatMinor(minimumDueMinor!, format: moneyFormat)), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant).tabular),
            ],
          ],
        ],
      ),
    );
  }
}

/// "Due in 12 days" / "Due today" / "Overdue by 3 days" / "Paid", coloured by urgency.
class CardDueChip extends StatelessWidget {
  const CardDueChip({super.key, required this.due});
  final CardDue due;

  /// Upcoming bills this close are shown in the warning colour.
  static const int soonDays = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (due.state) {
      CardDueState.paid => (l10n.cardPaid, kIncomeColor),
      CardDueState.overdue => (l10n.reminderOverdueDays(-due.daysLeft), kExpenseColor),
      CardDueState.dueToday => (l10n.reminderDueToday, kExpenseColor),
      CardDueState.upcoming => (l10n.reminderDueInDays(due.daysLeft), due.daysLeft <= soonDays ? kAccentColor : scheme.primary),
    };
    return Container(
      key: kCardDueChipKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

/// A labelled figure with a caption, half the screen wide.
class _FigureCard extends StatelessWidget {
  const _FigureCard({super.key, required this.label, required this.value, required this.caption});
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return DashboardCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: muted)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700).tabular)),
          const SizedBox(height: 4),
          Text(caption, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
