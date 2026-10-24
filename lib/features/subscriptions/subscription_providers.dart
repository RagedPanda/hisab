import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/subscriptions/subscription_costs.dart';
import '../../l10n/category_names.dart';

/// A subscription rule with the rows its tile shows.
class SubscriptionRow {
  const SubscriptionRow({required this.view, required this.item});
  final RecurringRuleView view;
  final SubscriptionItem item;
}

/// Name shown for a rule: its own name, else the payee, else the category.
String subscriptionDisplayName(RecurringRuleView view, Locale locale) {
  final rule = view.rule;
  if (rule.name.trim().isNotEmpty) return rule.name.trim();
  if ((rule.payee ?? '').trim().isNotEmpty) return rule.payee!.trim();
  final category = view.category;
  return category == null ? '' : categoryDisplayName(category, locale);
}

/// The pure view of a stored rule, for the maths in `lib/domain/subscriptions`.
SubscriptionItem subscriptionItemOf(RecurringRuleView view, Locale locale) => SubscriptionItem(
  id: view.rule.id,
  name: subscriptionDisplayName(view, locale),
  amountMinor: view.rule.amountMinor,
  frequency: RecurrenceFrequency.parse(view.rule.frequency),
  interval: view.rule.interval,
  status: SubscriptionStatus.fromRuleStatus(view.rule.status),
  nextDue: view.rule.nextDue,
);

/// Live recurring rules flagged as subscriptions.
final subscriptionViewsProvider = StreamProvider<List<RecurringRuleView>>(
  (ref) => ref
      .watch(recurringRepositoryProvider)
      .watchViews()
      .map(
        (views) => [
          for (final view in views)
            if (view.rule.isSubscription) view,
        ],
      ),
);
