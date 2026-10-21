/// Debug-only demo data writer. Fills an app database with accounts,
/// budgets, a group and a few hundred entries so dashboards and lists can be
/// checked with realistic volume. Idempotent: a database that already holds
/// demo entries is left alone.
library;

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/database.dart';
import '../repositories/accounts_repository.dart';
import '../repositories/budgets_repository.dart';
import '../repositories/categories_repository.dart';
import '../repositories/entries_repository.dart';
import '../repositories/groups_repository.dart';
import 'demo_plan.dart';

/// Entries written by the seeder carry this source so a rerun can detect them.
const String kDemoSource = 'demo';

Future<bool> hasDemoData(AppDatabase db) async {
  final row = await (db.select(db.entries)..where((t) => t.source.equals(kDemoSource))..limit(1)).getSingleOrNull();
  return row != null;
}

Future<void> seedDemoData(AppDatabase db, {required int entryCount, DateTime? now}) async {
  if (await hasDemoData(db)) return;
  final clock = now ?? DateTime.now();
  final accounts = AccountsRepository(db);
  final categories = CategoriesRepository(db);
  final entries = EntriesRepository(db);
  final budgets = BudgetsRepository(db);
  final groups = GroupsRepository(db);

  final accountIds = [
    for (final account in await accounts.getAll()) account.id,
    (await accounts.create(name: 'HDFC Savings', type: 'bank', color: 0xFF0F6E6B, bankName: 'HDFC', last4: '4421', balanceMinor: 12450000)).id,
    (await accounts.create(name: 'Axis Credit Card', type: 'card', color: 0xFF9C27B0, bankName: 'Axis', last4: '8812', balanceMinor: -1830000)).id,
  ];
  final categoryIdByKey = {for (final category in await categories.getAll(includeArchived: true)) if (category.seedKey != null) category.seedKey!: category.id};

  final plan = planDemoEntries(count: entryCount, now: clock, accountCount: accountIds.length);
  await db.transaction(() async {
    for (final item in plan) {
      await entries.saveEntry(EntriesRepository.newExpense(
        kind: item.kind,
        amountMinor: item.amountMinor,
        occurredAt: item.occurredAt,
        categoryId: categoryIdByKey[item.categoryKey],
        accountId: accountIds[item.accountIndex],
        payee: item.payee,
        source: kDemoSource,
      ));
    }
  });

  await budgets.save(categoryId: null, period: 'month', amountMinor: 6000000);
  await budgets.save(categoryId: categoryIdByKey['food'], period: 'month', amountMinor: 1500000);
  await budgets.save(categoryId: categoryIdByKey['transport'], period: 'month', amountMinor: 400000);

  final groupId = await groups.createGroup(name: 'Goa trip', icon: 'beach', myName: '', otherMembers: ['Priya', 'Rahul']);
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((member) => member.isMe);
  final entryId = newId();
  await entries.saveEntry(
    EntriesRepository.newExpense(
      id: entryId,
      amountMinor: 900000,
      occurredAt: clock.subtract(const Duration(days: 3)),
      categoryId: categoryIdByKey['hotels'],
      accountId: accountIds[1],
      payee: 'Taj Resort',
      source: kDemoSource,
      groupId: groupId,
      paidByMemberId: me.id,
      splitMethod: 'equal',
    ),
    splits: [
      for (final member in members) SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: member.id, amountMinor: 300000, shareValue: const Value(1)),
    ],
  );
}
