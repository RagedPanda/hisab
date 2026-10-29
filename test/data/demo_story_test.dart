import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/debug/demo_seed.dart';
import 'package:hisab/data/debug/demo_story.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 10, 29, 12);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  tearDown(() => db.close());

  test('equalShares hands the leftover paise to the first members', () {
    expect(equalShares(1000, 3), [334, 333, 333]);
    expect(equalShares(900000, 3), [300000, 300000, 300000]);
  });

  test('nextDayOfMonth keeps today and later this month, else rolls to next month', () {
    expect(nextDayOfMonth(now, 29), DateTime(2026, 10, 29));
    expect(nextDayOfMonth(now, 30), DateTime(2026, 10, 30));
    expect(nextDayOfMonth(now, 12), DateTime(2026, 11, 12));
    expect(nextDayOfMonth(DateTime(2026, 12, 20), 3), DateTime(2027, 1, 3));
  });

  test('seedDemoData writes the README story', () async {
    await seedDemoData(db, entryCount: 5, now: now);

    final dairy = await (db.select(db.entries)..where((entry) => entry.payee.equals('Gwala Ji'))).getSingle();
    final items = await (db.select(db.entryItems)..where((item) => item.entryId.equals(dairy.id))).get();
    expect(items.map((item) => item.name), ['Buffalo milk', 'Paneer']);
    expect(dairy.amountMinor, 14400 + 4200);

    final tripEntries = await (db.select(db.entries)..where((entry) => entry.groupId.isNotNull())).get();
    expect(tripEntries.map((entry) => entry.payee), containsAll(kDemoTripExpenses.map((expense) => expense.payee)));
    for (final entry in tripEntries) {
      final splits = await (db.select(db.splits)..where((split) => split.entryId.equals(entry.id))).get();
      expect(splits.fold<int>(0, (total, split) => total + split.amountMinor), entry.amountMinor, reason: entry.payee);
    }
    expect(await db.select(db.settlements).get(), hasLength(1));

    final pendingSms = await (db.select(db.smsLog)..where((sms) => sms.status.equals('pending'))).get();
    expect(pendingSms, hasLength(kDemoReviewSms.length));
    expect(pendingSms.every((sms) => sms.parsedJson != null), isTrue, reason: 'review cards show the read amount');

    final subscriptions = await (db.select(db.recurringRules)..where((rule) => rule.isSubscription.equals(true))).get();
    expect(subscriptions.map((rule) => rule.name), unorderedEquals(kDemoSubscriptions.map((subscription) => subscription.$1)));
    expect(subscriptions.every((rule) => !rule.nextDue!.isBefore(DateTime(2026, 10, 29))), isTrue, reason: 'nothing starts overdue');
  });
}
