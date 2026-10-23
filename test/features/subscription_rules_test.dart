import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/entries/entry_filter.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/subscriptions/subscription_templates.dart';
import 'package:hisab/features/subscriptions/subscription_rules.dart';

void main() {
  late AppDatabase db;
  late RecurringRepository recurring;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recurring = RecurringRepository(db);
  });

  tearDown(() => db.close());

  SubscriptionDraft draft({String name = 'Netflix', String? categoryId}) => SubscriptionDraft(
        name: name,
        amountMinor: 64900,
        cycle: const SubscriptionCycle(RecurrenceFrequency.monthly, 1),
        startDate: DateTime(2026, 10, 1, 9),
        categoryId: categoryId,
      );

  Future<Entry> onlyPostedEntry() async => (await (db.select(db.entries)..where((t) => t.source.equals('recurring'))).get()).single;

  test('a posted subscription charge carries the subscription name and search finds it', () async {
    await recurring.saveRule(newSubscriptionRule(draft()), monthStartDay: 1);
    await recurring.postDue(now: DateTime(2026, 10, 1, 10));
    final entry = await onlyPostedEntry();
    expect(entry.payee, 'Netflix');
    final facts = EntryFacts(amountMinor: entry.amountMinor, occurredAt: entry.occurredAt, note: entry.note, payee: entry.payee);
    expect(matchesSearch('netflix', facts), isTrue);
  });

  test('renaming a subscription renames the payee of later charges', () async {
    final id = await recurring.saveRule(newSubscriptionRule(draft()), monthStartDay: 1);
    final existing = (await recurring.getRule(id))!;
    await recurring.saveRule(editedSubscriptionRule(existing, draft(name: 'Netflix Premium'), renewalDayChanged: false), monthStartDay: 1);
    final edited = (await recurring.getRule(id))!;
    expect(edited.name, 'Netflix Premium');
    expect(edited.payee, 'Netflix Premium');
    expect(edited.isSubscription, isTrue);
  });

  test('"Something else" starts in a seeded category, not uncategorised', () async {
    expect(subscriptionCategoryKeyFor(null), kSubscriptionFallbackCategoryKey);
    expect(subscriptionCategoryKeyFor(subscriptionTemplateByKey('netflix')), 'ott');
    final fallback = await CategoriesRepository(db).findBySeedKey(subscriptionCategoryKeyFor(null));
    expect(fallback, isNotNull, reason: 'the fallback key must be a seeded category');
    await recurring.saveRule(newSubscriptionRule(draft(name: 'Swiggy One', categoryId: fallback!.id)), monthStartDay: 1);
    await recurring.postDue(now: DateTime(2026, 10, 1, 10));
    expect((await onlyPostedEntry()).categoryId, fallback.id);
  });
}
