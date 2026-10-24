/// One combined provider per dashboard card. Each derives from the shared
/// six-month ledger stream (plus the static lists it needs), so a card shows
/// either a complete, self-consistent snapshot or its skeleton.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/groups_repository.dart';
import '../../data/repositories/projects_repository.dart';
import '../../domain/accounts/account_label.dart';
import '../../domain/budget/budget_math.dart';
import '../../domain/categories/category_filter.dart';
import '../../domain/ledger/personal_totals.dart';
import '../../domain/projects/project_math.dart';
import '../../domain/stats/category_shares.dart';
import '../../domain/stats/month_summary.dart';
import '../../domain/stats/spend_series.dart';
import '../../domain/stats/today_spend.dart';
import '../../domain/stats/trend.dart';
import '../budgets/budget_views.dart';

/// Rows the recent card shows.
const int kRecentEntryCount = 7;

/// Rows the groups card shows.
const int kGroupsCardRows = 3;

/// Maps an async source without dropping the value it still holds while a
/// new one loads (`whenData` would), so cards keep their last snapshot
/// during a month switch instead of flashing a skeleton.
AsyncValue<R> mapAsync<T, R>(AsyncValue<T> source, R Function(T value) transform) {
  if (source.hasError) return AsyncError(source.error!, source.stackTrace ?? StackTrace.current);
  if (!source.hasValue) return const AsyncLoading();
  return AsyncData(transform(source.requireValue));
}

/// Joins two async sources: loading until both have a value, first error wins.
AsyncValue<R> combineAsync<A, B, R>(AsyncValue<A> first, AsyncValue<B> second, R Function(A first, B second) merge) {
  if (first.hasError) return AsyncError(first.error!, first.stackTrace ?? StackTrace.current);
  if (second.hasError) return AsyncError(second.error!, second.stackTrace ?? StackTrace.current);
  if (!first.hasValue || !second.hasValue) return const AsyncLoading();
  return AsyncData(merge(first.requireValue, second.requireValue));
}

// Hero -----------------------------------------------------------------------

class HeroData {
  const HeroData({required this.summary, required this.range, required this.previousRange, this.todayMinor});
  final MonthSummary summary;
  final DateRange range;
  final DateRange previousRange;

  /// Today's spend; null when the card shows a month that is not this one.
  final int? todayMinor;
}

final heroDataProvider = Provider<AsyncValue<HeroData>>((ref) => mapAsync(ref.watch(dashboardLedgerProvider), (ledger) {
      final now = DateTime.now();
      final currentLines = linesWithin(ledger.lines, ledger.range);
      final summary = summariseMonth(
        current: currentLines,
        previous: linesWithin(ledger.lines, ledger.previousRange),
        range: ledger.range,
        now: now,
      );
      return HeroData(
        summary: summary,
        range: ledger.range,
        previousRange: ledger.previousRange,
        todayMinor: todaySpendMinor(lines: currentLines, shownRange: ledger.range, now: now),
      );
    }));

// Trend ----------------------------------------------------------------------

final trendDataProvider = Provider<AsyncValue<TrendData>>((ref) => mapAsync(
      ref.watch(dashboardLedgerProvider),
      (ledger) => buildTrend(lines: ledger.lines, monthRanges: ledger.ranges, now: DateTime.now()),
    ));

// Category donut -------------------------------------------------------------

class CategoryBreakdown {
  const CategoryBreakdown({required this.shares, required this.categoriesById, required this.totalMinor});
  final List<CategoryShare> shares;
  final Map<String, Category> categoriesById;
  final int totalMinor;

  Category? categoryOf(CategoryShare share) => share.categoryId == null ? null : categoriesById[share.categoryId];
}

final categoryBreakdownProvider = Provider<AsyncValue<CategoryBreakdown>>((ref) => combineAsync(
      ref.watch(dashboardLedgerProvider),
      ref.watch(allCategoriesProvider),
      (ledger, categories) => buildCategoryBreakdown(totalsByCategory(linesWithin(ledger.lines, ledger.range)), categories),
    ));

/// Expense per category rolled up to parents and cut to the top slices; the
/// shape the category donut draws, for the dashboard month or a project.
CategoryBreakdown buildCategoryBreakdown(Map<String, int> expenseByCategory, List<Category> categories) {
  final rolled = rollUpToParents(expenseByCategory, {for (final category in categories) category.id: category.parentId});
  final shares = categoryShares(rolled);
  return CategoryBreakdown(
    shares: shares,
    categoriesById: {for (final category in categories) category.id: category},
    totalMinor: shares.fold(0, (sum, share) => sum + share.minor),
  );
}

/// The category the donut has selected; '' is "uncategorised", null is none.
class SelectedDashboardCategory extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? categoryId) => state = categoryId;
  void clear() => state = null;
}

final selectedDashboardCategoryProvider = NotifierProvider<SelectedDashboardCategory, String?>(SelectedDashboardCategory.new);

// Budgets --------------------------------------------------------------------

class BudgetsOverview {
  const BudgetsOverview({required this.shown, required this.more});
  final List<BudgetView> shown;
  final int more;

  bool get isEmpty => shown.isEmpty;
}

class ProjectsOverview {
  const ProjectsOverview({required this.shown, required this.more});
  final List<ProjectView> shown;
  final int more;

  bool get isEmpty => shown.isEmpty;
}

/// Active projects for the dashboard card, most recently touched first.
final projectsOverviewProvider = Provider<AsyncValue<ProjectsOverview>>((ref) => mapAsync(ref.watch(projectViewsProvider), (views) {
      final rows = activeProjectRows(views, statusOf: (view) => view.status);
      return ProjectsOverview(shown: rows.shown, more: rows.more);
    }));

final budgetsOverviewProvider = Provider<AsyncValue<BudgetsOverview>>((ref) {
  final lists = combineAsync(ref.watch(budgetsProvider), ref.watch(allCategoriesProvider), (budgets, categories) => (budgets: budgets, categories: categories));
  return combineAsync(ref.watch(dashboardLedgerProvider), lists, (ledger, lists) {
    final monthLines = linesWithin(ledger.lines, ledger.range);
    final views = buildBudgetViews(
      budgets: lists.budgets,
      categories: lists.categories,
      expenseByCategory: totalsByCategory(monthLines),
      monthExpenseMinor: totalsByKind(monthLines).expense,
      range: ledger.range,
      now: DateTime.now(),
    );
    final rows = budgetOverviewRows(views, isOverall: (view) => view.isOverall, limitOf: (view) => view.budget.amountMinor);
    return BudgetsOverview(shown: rows.shown, more: rows.more);
  });
});

// Accounts -------------------------------------------------------------------

class AccountsOverview {
  const AccountsOverview({required this.accounts, required this.totalMinor});
  final List<Account> accounts;
  final int totalMinor;
}

final accountsOverviewProvider = Provider<AsyncValue<AccountsOverview>>((ref) => mapAsync(
      ref.watch(accountsProvider),
      (accounts) => AccountsOverview(
        accounts: accounts,
        totalMinor: includedBalanceTotal(accounts.map((account) => (includeInTotal: account.includeInTotal, balanceMinor: account.balanceMinor))),
      ),
    ));

// Groups ---------------------------------------------------------------------

class GroupsOverview {
  const GroupsOverview({required this.shown, required this.owedToMe, required this.iOwe});
  final List<GroupSummary> shown;
  final int owedToMe;
  final int iOwe;

  bool get isEmpty => shown.isEmpty;
}

final groupsOverviewProvider = Provider<AsyncValue<GroupsOverview>>((ref) {
  final appSymbol = ref.watch(settingsProvider).currencySymbol;
  return mapAsync(ref.watch(groupSummariesProvider), (summaries) {
    final totals = groupTotalsInAppCurrency(summaries, appSymbol: appSymbol);
    final active = summaries.where((summary) => summary.group.archivedAt == null);
    return GroupsOverview(shown: active.take(kGroupsCardRows).toList(), owedToMe: totals.owedToMe, iOwe: totals.iOwe);
  });
});

// Recent ---------------------------------------------------------------------

class RecentEntries {
  const RecentEntries({required this.entries, required this.filter, required this.hasAnyEntries});
  final List<EntryDetails> entries;

  /// The category the list is narrowed to, when the donut selected one.
  final Category? filter;

  /// Whether any entry exists at all, which decides between
  /// "no entries this month" and the first-run empty state.
  final bool hasAnyEntries;
}

final recentEntriesProvider = Provider<AsyncValue<RecentEntries>>((ref) {
  final selected = ref.watch(selectedDashboardCategoryProvider);
  final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
  return combineAsync(ref.watch(monthEntriesProvider), ref.watch(hasAnyEntriesProvider), (entries, hasAnyEntries) {
    final matching = selected == null
        ? entries
        : entries.where((details) => matchesCategoryFilter(selectedId: selected, categoryId: details.category?.id, parentId: details.category?.parentId));
    return RecentEntries(
      entries: matching.take(kRecentEntryCount).toList(),
      filter: selected == null ? null : categories.where((category) => category.id == selected).firstOrNull,
      hasAnyEntries: hasAnyEntries,
    );
  });
});
