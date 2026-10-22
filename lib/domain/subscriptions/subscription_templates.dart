/// Quick-add templates for common Indian subscriptions: a name key, the
/// usual billing cycle and the category it belongs in. No prices and no
/// logos: plans change often and differ by tier, so the user types the
/// amount. Names live in the ARB files keyed by [SubscriptionTemplate.key].
/// Pure, no Flutter imports.
library;

import '../recurring/recurrence.dart';

class SubscriptionTemplate {
  const SubscriptionTemplate({
    required this.key,
    required this.frequency,
    required this.categoryKey,
    this.interval = 1,
  });

  final String key;
  final RecurrenceFrequency frequency;

  /// Charged every [interval] [frequency] (a 28-day recharge is daily x 28).
  final int interval;

  /// Seed category key from the category catalog.
  final String categoryKey;
}

/// Cycles are the most common plan length each service sells in India; the
/// user can change it when adding.
const List<SubscriptionTemplate> subscriptionTemplates = [
  SubscriptionTemplate(key: 'netflix', frequency: RecurrenceFrequency.monthly, categoryKey: 'ott'),
  SubscriptionTemplate(key: 'amazon_prime', frequency: RecurrenceFrequency.yearly, categoryKey: 'ott'),
  SubscriptionTemplate(key: 'jiohotstar', frequency: RecurrenceFrequency.monthly, interval: 3, categoryKey: 'ott'),
  SubscriptionTemplate(key: 'spotify', frequency: RecurrenceFrequency.monthly, categoryKey: 'ott'),
  SubscriptionTemplate(key: 'youtube_premium', frequency: RecurrenceFrequency.monthly, categoryKey: 'ott'),
  SubscriptionTemplate(key: 'mobile_recharge', frequency: RecurrenceFrequency.daily, interval: 28, categoryKey: 'mobile_recharge'),
  SubscriptionTemplate(key: 'dth', frequency: RecurrenceFrequency.monthly, categoryKey: 'dth_cable'),
  SubscriptionTemplate(key: 'broadband', frequency: RecurrenceFrequency.monthly, categoryKey: 'internet'),
  SubscriptionTemplate(key: 'gym', frequency: RecurrenceFrequency.monthly, categoryKey: 'fitness'),
  SubscriptionTemplate(key: 'cloud_storage', frequency: RecurrenceFrequency.monthly, categoryKey: 'software_subscriptions'),
  SubscriptionTemplate(key: 'news_app', frequency: RecurrenceFrequency.monthly, categoryKey: 'books_magazines'),
];

SubscriptionTemplate? subscriptionTemplateByKey(String key) {
  for (final template in subscriptionTemplates) {
    if (template.key == key) return template;
  }
  return null;
}

/// A billing cycle the add form offers: every [interval] [frequency].
class SubscriptionCycle {
  const SubscriptionCycle(this.frequency, this.interval);
  final RecurrenceFrequency frequency;
  final int interval;

  @override
  bool operator ==(Object other) => other is SubscriptionCycle && other.frequency == frequency && other.interval == interval;

  @override
  int get hashCode => Object.hash(frequency, interval);
}

/// Cycles Indian plans are sold in: monthly, quarterly, half-yearly, yearly,
/// 28- and 84-day prepaid packs, and weekly.
const List<SubscriptionCycle> subscriptionCycles = [
  SubscriptionCycle(RecurrenceFrequency.monthly, 1),
  SubscriptionCycle(RecurrenceFrequency.monthly, 3),
  SubscriptionCycle(RecurrenceFrequency.monthly, 6),
  SubscriptionCycle(RecurrenceFrequency.yearly, 1),
  SubscriptionCycle(RecurrenceFrequency.daily, 28),
  SubscriptionCycle(RecurrenceFrequency.daily, 84),
  SubscriptionCycle(RecurrenceFrequency.weekly, 1),
];

/// The cycle list to offer for a rule already on [current]: the presets,
/// plus [current] at the end when a rule made elsewhere uses another cycle.
List<SubscriptionCycle> cycleOptionsFor(SubscriptionCycle current) =>
    subscriptionCycles.contains(current) ? subscriptionCycles : [...subscriptionCycles, current];
