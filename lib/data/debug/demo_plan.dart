/// Pure planning of demo data: a deterministic spread of entries over the
/// last six months, so a seeded database looks like real use. No I/O here;
/// `demo_seed.dart` writes the plan through the repositories.
library;

import 'dart:math';

class DemoEntryPlan {
  const DemoEntryPlan({
    required this.kind,
    required this.categoryKey,
    required this.amountMinor,
    required this.occurredAt,
    required this.accountIndex,
    required this.payee,
  });
  final String kind;
  final String categoryKey;
  final int amountMinor;
  final DateTime occurredAt;
  final int accountIndex;
  final String payee;
}

/// Expense categories with a typical amount band (in whole rupees) and the
/// payees they show up under; weighted so food dominates like a real ledger.
const List<({String key, int min, int max, List<String> payees, int weight})> kDemoExpenseProfiles = [
  (key: 'groceries', min: 150, max: 1800, payees: ['Big Bazaar', 'DMart', 'Reliance Fresh'], weight: 5),
  (key: 'milk_dairy', min: 50, max: 220, payees: ['Mother Dairy', 'Amul Parlour'], weight: 6),
  (key: 'restaurants', min: 300, max: 2400, payees: ['Cafe Coffee Day', 'Barbeque Nation', 'Haldiram'], weight: 3),
  (key: 'food_delivery', min: 180, max: 900, payees: ['Swiggy', 'Zomato'], weight: 4),
  (key: 'cab_auto', min: 60, max: 450, payees: ['Uber', 'Ola', 'Auto'], weight: 4),
  (key: 'fuel', min: 500, max: 3000, payees: ['HP Petrol Pump', 'Indian Oil'], weight: 2),
  (key: 'electricity', min: 900, max: 3200, payees: ['BSES'], weight: 1),
  (key: 'mobile_recharge', min: 239, max: 999, payees: ['Jio', 'Airtel'], weight: 1),
  (key: 'medicines', min: 120, max: 1500, payees: ['Apollo Pharmacy', '1mg'], weight: 1),
  (key: 'clothing', min: 600, max: 4500, payees: ['Myntra', 'Zudio'], weight: 1),
  (key: 'movies', min: 250, max: 1200, payees: ['PVR', 'BookMyShow'], weight: 1),
  (key: 'ott', min: 149, max: 649, payees: ['Netflix', 'Hotstar'], weight: 1),
  (key: 'salon', min: 200, max: 900, payees: ['Looks Salon'], weight: 1),
];

const List<({String key, int amount, String payee})> kDemoIncomeProfiles = [
  (key: 'salary', amount: 85000, payee: 'Acme Pvt Ltd'),
  (key: 'freelance', amount: 12000, payee: 'Upwork'),
];

/// Fixed outgoings on the 2nd of every month.
const List<({String key, int amount, String payee})> kDemoMonthlyExpenses = [
  (key: 'rent', amount: 18000, payee: 'Landlord'),
];

/// Builds [count] expense entries spread over the six months ending at [now]
/// (denser in the current month) plus a salary at the start of each month.
List<DemoEntryPlan> planDemoEntries({required int count, required DateTime now, int accountCount = 3, int months = 6}) {
  final random = Random(42);
  final weighted = [for (final profile in kDemoExpenseProfiles) for (var i = 0; i < profile.weight; i++) profile];
  final firstDay = DateTime(now.year, now.month - (months - 1), 1);
  final totalDays = now.difference(firstDay).inDays + 1;
  final plans = <DemoEntryPlan>[];
  for (var index = 0; index < count; index++) {
    final profile = weighted[random.nextInt(weighted.length)];
    final dayOffset = random.nextInt(totalDays);
    final occurredAt = firstDay.add(Duration(days: dayOffset, hours: 8 + random.nextInt(13), minutes: random.nextInt(60)));
    if (occurredAt.isAfter(now)) continue;
    final rupees = profile.min + random.nextInt(profile.max - profile.min + 1);
    plans.add(DemoEntryPlan(
      kind: 'expense',
      categoryKey: profile.key,
      amountMinor: rupees * 100,
      occurredAt: occurredAt,
      accountIndex: random.nextInt(accountCount),
      payee: profile.payees[random.nextInt(profile.payees.length)],
    ));
  }
  for (var back = 0; back < months; back++) {
    final monthStart = DateTime(now.year, now.month - back, 1);
    for (final income in kDemoIncomeProfiles) {
      final occurredAt = DateTime(monthStart.year, monthStart.month, income.key == 'salary' ? 1 : 12, 10);
      if (occurredAt.isAfter(now)) continue;
      plans.add(DemoEntryPlan(kind: 'income', categoryKey: income.key, amountMinor: income.amount * 100, occurredAt: occurredAt, accountIndex: 0, payee: income.payee));
    }
    for (final fixed in kDemoMonthlyExpenses) {
      final occurredAt = DateTime(monthStart.year, monthStart.month, 2, 9);
      if (occurredAt.isAfter(now)) continue;
      plans.add(DemoEntryPlan(kind: 'expense', categoryKey: fixed.key, amountMinor: fixed.amount * 100, occurredAt: occurredAt, accountIndex: 0, payee: fixed.payee));
    }
  }
  plans.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  return plans;
}
