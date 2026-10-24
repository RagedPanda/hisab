import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/subscriptions/subscription_costs.dart';
import 'package:hisab/features/subscriptions/subscription_providers.dart';

void main() {
  late AppDatabase db;
  late RecurringRepository recurring;
  const english = Locale('en');
  const hindi = Locale('hi');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recurring = RecurringRepository(db);
  });

  tearDown(() => db.close());

  Future<RecurringRuleView> viewOf(String id) async => (await recurring.getViews()).firstWhere((view) => view.rule.id == id);

  test('a stored subscription maps to its pure item', () async {
    final id = await recurring.saveRule(
      RecurringRepository.newRule(name: 'Netflix', kind: 'expense', amountMinor: 64900, frequency: RecurrenceFrequency.monthly, interval: 3, startDate: DateTime(2026, 11, 5, 9), isSubscription: true),
    );
    final item = subscriptionItemOf(await viewOf(id), english);
    expect(item.name, 'Netflix');
    expect(item.amountMinor, 64900);
    expect(item.frequency, RecurrenceFrequency.monthly);
    expect(item.interval, 3);
    expect(item.status, SubscriptionStatus.active);
    expect(item.nextDue, DateTime(2026, 11, 5, 9));

    await recurring.setPaused(id, true, now: DateTime(2026, 10, 22));
    expect(subscriptionItemOf(await viewOf(id), english).status, SubscriptionStatus.paused);
    await recurring.setStatus(id, RecurringStatus.ended);
    expect(subscriptionItemOf(await viewOf(id), english).status, SubscriptionStatus.cancelled);
  });

  test('an unnamed rule falls back to payee, then the localised category', () async {
    final gym = (await CategoriesRepository(db).findBySeedKey('fitness'))!;
    final byPayee = await recurring.saveRule(
      RecurringRepository.newRule(kind: 'expense', amountMinor: 100, payee: 'Cult', frequency: RecurrenceFrequency.monthly, startDate: DateTime(2026, 11, 1), isSubscription: true),
    );
    final byCategory = await recurring.saveRule(
      RecurringRepository.newRule(kind: 'expense', amountMinor: 100, categoryId: gym.id, frequency: RecurrenceFrequency.monthly, startDate: DateTime(2026, 11, 1), isSubscription: true),
    );
    expect(subscriptionDisplayName(await viewOf(byPayee), english), 'Cult');
    expect(subscriptionDisplayName(await viewOf(byCategory), english), gym.name);
    expect(subscriptionDisplayName(await viewOf(byCategory), hindi), isNot(gym.name));
  });
}
