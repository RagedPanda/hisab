import '../../core/format.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/subscriptions/subscription_costs.dart';
import '../../domain/subscriptions/subscription_templates.dart';
import '../../l10n/l10n.dart';

/// Localised name of a quick-add subscription template.
String subscriptionTemplateName(AppLocalizations l10n, SubscriptionTemplate template) => switch (template.key) {
      'netflix' => l10n.subscriptionTemplateNetflix,
      'amazon_prime' => l10n.subscriptionTemplateAmazonPrime,
      'jiohotstar' => l10n.subscriptionTemplateJiohotstar,
      'spotify' => l10n.subscriptionTemplateSpotify,
      'youtube_premium' => l10n.subscriptionTemplateYoutubePremium,
      'mobile_recharge' => l10n.subscriptionTemplateMobileRecharge,
      'dth' => l10n.subscriptionTemplateDth,
      'broadband' => l10n.subscriptionTemplateBroadband,
      'gym' => l10n.subscriptionTemplateGym,
      'cloud_storage' => l10n.subscriptionTemplateCloudStorage,
      'news_app' => l10n.subscriptionTemplateNewsApp,
      _ => template.key,
    };

/// "Monthly", "Every 3 months", "Every 28 days", "Yearly".
String subscriptionCycleLabel(AppLocalizations l10n, RecurrenceFrequency frequency, int interval) {
  final count = interval < 1 ? 1 : interval;
  return switch (frequency) {
    RecurrenceFrequency.daily => l10n.subscriptionEveryDays(count),
    RecurrenceFrequency.weekly => l10n.subscriptionEveryWeeks(count),
    RecurrenceFrequency.monthly => l10n.subscriptionEveryMonths(count),
    RecurrenceFrequency.yearly => l10n.subscriptionEveryYears(count),
  };
}

/// "Renews today", "Renews in 3 days", "Renews 5 Nov" or "Was due 20 Oct".
String subscriptionRenewalLabel(AppLocalizations l10n, DateTime renewal, DateTime today, {String? locale}) {
  final days = daysUntilRenewal(renewal, today);
  if (days < 0) return l10n.subscriptionOverdue(formatRowDate(renewal, now: today, locale: locale));
  if (days == 0) return l10n.subscriptionRenewsToday;
  if (days <= 7) return l10n.subscriptionRenewsInDays(days);
  return l10n.subscriptionRenewsOn(formatRowDate(renewal, now: today, locale: locale));
}

String subscriptionSortLabel(AppLocalizations l10n, SubscriptionSort sort) => switch (sort) {
      SubscriptionSort.costHighToLow => l10n.subscriptionSortCostHigh,
      SubscriptionSort.costLowToHigh => l10n.subscriptionSortCostLow,
      SubscriptionSort.nextRenewal => l10n.subscriptionSortRenewal,
      SubscriptionSort.name => l10n.subscriptionSortName,
    };
