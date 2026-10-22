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
