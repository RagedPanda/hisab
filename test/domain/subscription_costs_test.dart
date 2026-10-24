import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/categories/category_catalog.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/subscriptions/subscription_costs.dart';
import 'package:hisab/domain/subscriptions/subscription_templates.dart';

SubscriptionItem item(String name, int amountMinor, RecurrenceFrequency frequency,
        {int interval = 1, SubscriptionStatus status = SubscriptionStatus.active, DateTime? nextDue}) =>
    SubscriptionItem(id: name, name: name, amountMinor: amountMinor, frequency: frequency, interval: interval, status: status, nextDue: nextDue);

void main() {
  group('monthly and yearly equivalents', () {
    test('monthly charge', () {
      expect(monthlyEquivalentMinor(64900, RecurrenceFrequency.monthly), 64900);
      expect(yearlyEquivalentMinor(64900, RecurrenceFrequency.monthly), 778800);
    });

    test('yearly charge is a twelfth per month', () {
      expect(monthlyEquivalentMinor(149900, RecurrenceFrequency.yearly), 12492);
      expect(yearlyEquivalentMinor(149900, RecurrenceFrequency.yearly), 149900);
    });

    test('quarterly is monthly with interval three', () {
      expect(monthlyEquivalentMinor(29900, RecurrenceFrequency.monthly, interval: 3), 9967);
      expect(yearlyEquivalentMinor(29900, RecurrenceFrequency.monthly, interval: 3), 119600);
    });

    test('a 28-day recharge costs more than one charge a month', () {
      expect(yearlyEquivalentMinor(29900, RecurrenceFrequency.daily, interval: 28), 389768);
      expect(monthlyEquivalentMinor(29900, RecurrenceFrequency.daily, interval: 28), 32481);
    });

    test('weekly and daily', () {
      expect(yearlyEquivalentMinor(10000, RecurrenceFrequency.weekly), 520000);
      expect(monthlyEquivalentMinor(1000, RecurrenceFrequency.daily), 30417);
    });

    test('every two years and a non-positive interval', () {
      expect(yearlyEquivalentMinor(200000, RecurrenceFrequency.yearly, interval: 2), 100000);
      expect(yearlyEquivalentMinor(5000, RecurrenceFrequency.monthly, interval: 0), 60000);
    });
  });

  group('subscriptionTotals', () {
    test('sums only active subscriptions and rounds once', () {
      final totals = subscriptionTotals([
        item('Netflix', 64900, RecurrenceFrequency.monthly),
        item('Prime', 149900, RecurrenceFrequency.yearly),
        item('JioHotstar', 29900, RecurrenceFrequency.monthly, interval: 3),
        item('Gym', 150000, RecurrenceFrequency.monthly, status: SubscriptionStatus.paused),
        item('Old', 9900, RecurrenceFrequency.monthly, status: SubscriptionStatus.cancelled),
      ]);
      expect(totals.activeCount, 3);
      expect(totals.yearlyMinor, 778800 + 149900 + 119600);
      expect(totals.monthlyMinor, ((778800 + 149900 + 119600) / 12).round());
    });

    test('empty list is zero', () {
      final totals = subscriptionTotals(const []);
      expect((totals.monthlyMinor, totals.yearlyMinor, totals.activeCount), (0, 0, 0));
    });
  });

  group('renewal', () {
    test('active shows next due, paused and cancelled show none', () {
      final due = DateTime(2026, 11, 5, 9);
      expect(nextRenewal(item('A', 100, RecurrenceFrequency.monthly, nextDue: due)), due);
      expect(nextRenewal(item('B', 100, RecurrenceFrequency.monthly, nextDue: due, status: SubscriptionStatus.paused)), isNull);
      expect(nextRenewal(item('C', 100, RecurrenceFrequency.monthly, nextDue: due, status: SubscriptionStatus.cancelled)), isNull);
      expect(nextRenewal(item('D', 100, RecurrenceFrequency.monthly)), isNull);
    });

    test('days until renewal ignores time of day and DST', () {
      expect(daysUntilRenewal(DateTime(2026, 10, 23, 1), DateTime(2026, 10, 22, 23)), 1);
      expect(daysUntilRenewal(DateTime(2026, 10, 22, 9), DateTime(2026, 10, 22, 23)), 0);
      expect(daysUntilRenewal(DateTime(2026, 10, 20), DateTime(2026, 10, 22)), -2);
      expect(daysUntilRenewal(DateTime(2027, 3, 31), DateTime(2027, 3, 1)), 30);
    });

    test('rule status maps to subscription status', () {
      expect(SubscriptionStatus.fromRuleStatus('active'), SubscriptionStatus.active);
      expect(SubscriptionStatus.fromRuleStatus('paused'), SubscriptionStatus.paused);
      expect(SubscriptionStatus.fromRuleStatus('ended'), SubscriptionStatus.cancelled);
      expect(SubscriptionStatus.fromRuleStatus('unknown'), SubscriptionStatus.active);
    });
  });

  group('sortSubscriptions', () {
    final items = [
      item('netflix', 64900, RecurrenceFrequency.monthly, nextDue: DateTime(2026, 11, 3)),
      item('Prime', 149900, RecurrenceFrequency.yearly, nextDue: DateTime(2026, 10, 25)),
      item('Gym', 150000, RecurrenceFrequency.monthly, status: SubscriptionStatus.paused),
      item('Broadband', 64900, RecurrenceFrequency.monthly, nextDue: DateTime(2026, 11, 1)),
      item('Old', 999900, RecurrenceFrequency.monthly, status: SubscriptionStatus.cancelled),
      item('Recharge', 29900, RecurrenceFrequency.daily, interval: 28),
    ];
    List<String> names(SubscriptionSort sort) => sortSubscriptions(items, sort).map((entry) => entry.name).toList();

    test('cost high to low uses the monthly equivalent, ties by name, inactive last', () {
      expect(names(SubscriptionSort.costHighToLow), ['Broadband', 'netflix', 'Recharge', 'Prime', 'Gym', 'Old']);
    });

    test('cost low to high', () {
      expect(names(SubscriptionSort.costLowToHigh), ['Prime', 'Recharge', 'Broadband', 'netflix', 'Gym', 'Old']);
    });

    test('next renewal puts subscriptions without a date after dated ones', () {
      expect(names(SubscriptionSort.nextRenewal), ['Prime', 'Broadband', 'netflix', 'Recharge', 'Gym', 'Old']);
    });

    test('name is case insensitive', () {
      expect(names(SubscriptionSort.name), ['Broadband', 'netflix', 'Prime', 'Recharge', 'Gym', 'Old']);
    });
  });

  group('templates', () {
    test('include the required services with unique keys', () {
      final keys = subscriptionTemplates.map((template) => template.key).toList();
      expect(keys.toSet().length, keys.length);
      expect(keys, containsAll(['netflix', 'amazon_prime', 'jiohotstar', 'spotify', 'youtube_premium', 'mobile_recharge', 'dth', 'broadband', 'gym', 'cloud_storage', 'news_app']));
    });

    test('point at seeded categories and positive intervals', () {
      final seedKeys = flattenCatalog().map((seed) => seed.key).toSet();
      for (final template in subscriptionTemplates) {
        expect(seedKeys, contains(template.categoryKey), reason: template.key);
        expect(template.interval, greaterThan(0));
      }
      expect(subscriptionTemplateByKey('mobile_recharge')!.interval, 28);
      expect(subscriptionTemplateByKey('missing'), isNull);
    });
  });

  group('cycles', () {
    test('presets are unique and include 28-day packs', () {
      expect(subscriptionCycles.toSet().length, subscriptionCycles.length);
      expect(subscriptionCycles, contains(const SubscriptionCycle(RecurrenceFrequency.daily, 28)));
    });

    test('every template cycle is a preset', () {
      for (final template in subscriptionTemplates) {
        expect(subscriptionCycles, contains(SubscriptionCycle(template.frequency, template.interval)), reason: template.key);
      }
    });

    test('a rule on another cycle keeps it as an option', () {
      const odd = SubscriptionCycle(RecurrenceFrequency.weekly, 2);
      expect(cycleOptionsFor(odd).last, odd);
      expect(cycleOptionsFor(subscriptionCycles.first), subscriptionCycles);
    });
  });
}
