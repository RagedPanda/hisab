/// Pure subscription maths: what a recurring charge costs per month and per
/// year whatever its cycle, the totals across subscriptions, the next
/// renewal and cost sorting. No I/O and no clock.
library;

import '../../core/dates.dart';
import '../recurring/recurrence.dart';

/// Where a subscription stands. Paused and cancelled ones are listed but
/// left out of the totals.
enum SubscriptionStatus {
  active,
  paused,
  cancelled;

  /// Maps a recurring rule status (`active | paused | ended`) to a
  /// subscription status; an ended rule is a cancelled subscription.
  static SubscriptionStatus fromRuleStatus(String status) => switch (status) {
    'paused' => SubscriptionStatus.paused,
    'ended' => SubscriptionStatus.cancelled,
    _ => SubscriptionStatus.active,
  };
}

/// The fields of a recurring rule the subscriptions view needs.
class SubscriptionItem {
  const SubscriptionItem({required this.id, required this.name, required this.amountMinor, required this.frequency, this.interval = 1, this.status = SubscriptionStatus.active, this.nextDue});

  final String id;
  final String name;

  /// Price per charge, in minor units.
  final int amountMinor;
  final RecurrenceFrequency frequency;

  /// Charged every [interval] days, weeks, months or years.
  final int interval;
  final SubscriptionStatus status;

  /// Next charge not yet posted; null once the rule has ended.
  final DateTime? nextDue;

  bool get countsTowardTotals => status == SubscriptionStatus.active;
}

/// Occurrences of one step of [frequency] in a year. A year is 365 days and
/// 52 weeks, so a 28-day prepaid recharge works out to about 13 a year.
int occurrencesPerYear(RecurrenceFrequency frequency) => switch (frequency) {
  RecurrenceFrequency.daily => 365,
  RecurrenceFrequency.weekly => 52,
  RecurrenceFrequency.monthly => 12,
  RecurrenceFrequency.yearly => 1,
};

/// Unrounded yearly cost in minor units, so totals round once at the end.
double _exactYearlyMinor(int amountMinor, RecurrenceFrequency frequency, int interval) => amountMinor * occurrencesPerYear(frequency) / (interval < 1 ? 1 : interval);

/// What a charge of [amountMinor] every [interval] [frequency] costs per year.
int yearlyEquivalentMinor(int amountMinor, RecurrenceFrequency frequency, {int interval = 1}) => _exactYearlyMinor(amountMinor, frequency, interval).round();

/// What a charge of [amountMinor] every [interval] [frequency] costs per month
/// (a twelfth of the yearly cost).
int monthlyEquivalentMinor(int amountMinor, RecurrenceFrequency frequency, {int interval = 1}) => (_exactYearlyMinor(amountMinor, frequency, interval) / 12).round();

int itemMonthlyMinor(SubscriptionItem item) => monthlyEquivalentMinor(item.amountMinor, item.frequency, interval: item.interval);

int itemYearlyMinor(SubscriptionItem item) => yearlyEquivalentMinor(item.amountMinor, item.frequency, interval: item.interval);

/// Monthly and yearly totals of the active subscriptions, plus how many
/// were counted.
({int monthlyMinor, int yearlyMinor, int activeCount}) subscriptionTotals(Iterable<SubscriptionItem> items) {
  final active = items.where((item) => item.countsTowardTotals).toList();
  final yearly = active.fold<double>(0, (sum, item) => sum + _exactYearlyMinor(item.amountMinor, item.frequency, item.interval));
  return (monthlyMinor: (yearly / 12).round(), yearlyMinor: yearly.round(), activeCount: active.length);
}

/// The next renewal to show: the stored next due date for an active
/// subscription, null when it is paused, cancelled or has no charge left.
DateTime? nextRenewal(SubscriptionItem item) => item.countsTowardTotals ? item.nextDue : null;

/// Whole calendar days from [today] to [renewal]; negative when overdue.
int daysUntilRenewal(DateTime renewal, DateTime today) {
  final from = startOfDay(today);
  final to = startOfDay(renewal);
  return DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}

enum SubscriptionSort { costHighToLow, costLowToHigh, nextRenewal, name }

int _statusRank(SubscriptionStatus status) => status == SubscriptionStatus.active ? 0 : (status == SubscriptionStatus.paused ? 1 : 2);

/// [items] sorted by [sort]. Active subscriptions always come first, then
/// paused, then cancelled; ties fall back to the name so the order is stable.
List<SubscriptionItem> sortSubscriptions(Iterable<SubscriptionItem> items, SubscriptionSort sort) {
  int byName(SubscriptionItem left, SubscriptionItem right) => left.name.toLowerCase().compareTo(right.name.toLowerCase());
  int byKey(SubscriptionItem left, SubscriptionItem right) {
    switch (sort) {
      case SubscriptionSort.costHighToLow:
        return itemMonthlyMinor(right).compareTo(itemMonthlyMinor(left));
      case SubscriptionSort.costLowToHigh:
        return itemMonthlyMinor(left).compareTo(itemMonthlyMinor(right));
      case SubscriptionSort.nextRenewal:
        final leftDate = nextRenewal(left);
        final rightDate = nextRenewal(right);
        if (leftDate == null || rightDate == null) return (leftDate == null ? 1 : 0) - (rightDate == null ? 1 : 0);
        return leftDate.compareTo(rightDate);
      case SubscriptionSort.name:
        return 0;
    }
  }

  return [...items]..sort((left, right) {
    final status = _statusRank(left.status).compareTo(_statusRank(right.status));
    if (status != 0) return status;
    final key = byKey(left, right);
    return key != 0 ? key : byName(left, right);
  });
}
