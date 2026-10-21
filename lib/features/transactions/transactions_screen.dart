import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/entries_repository.dart';
import '../../domain/categories/category_filter.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

class _KindFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final _searchProvider = NotifierProvider<_SearchNotifier, String>(_SearchNotifier.new);
final _kindFilterProvider = NotifierProvider<_KindFilterNotifier, String?>(_KindFilterNotifier.new);

/// Filters carried in the route, e.g. `/transactions?category=<id>` from the
/// dashboard donut or `?account=<id>` from an account card. Dismissing a chip
/// navigates to the same route without that parameter.
class RouteFilters {
  const RouteFilters({this.categoryId, this.accountId});
  final String? categoryId;
  final String? accountId;

  static RouteFilters of(BuildContext context) {
    final params = GoRouterState.of(context).uri.queryParameters;
    return RouteFilters(categoryId: params['category'], accountId: params['account']);
  }

  bool get isEmpty => categoryId == null && accountId == null;

  String locationWithout({bool category = false, bool account = false}) => Uri(
        path: '/transactions',
        queryParameters: {
          if (!category && categoryId != null) 'category': categoryId!,
          if (!account && accountId != null) 'account': accountId!,
        },
      ).toString().replaceFirst(RegExp(r'\?$'), '');

  bool matches(EntryDetails details) {
    if (accountId != null && details.entry.accountId != accountId) return false;
    if (categoryId != null && !matchesCategoryFilter(selectedId: categoryId!, categoryId: details.category?.id, parentId: details.category?.parentId)) return false;
    return true;
  }
}

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final search = ref.watch(_searchProvider);
    final kindFilter = ref.watch(_kindFilterProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final async = ref.watch(monthEntriesProvider);
    final routeFilters = RouteFilters.of(context);
    final entries = (async.value ?? const <EntryDetails>[]).where((d) {
      if (!routeFilters.matches(d)) return false;
      if (kindFilter != null && d.entry.kind != kindFilter) return false;
      if (search.isEmpty) return true;
      final needle = search.toLowerCase();
      return d.entry.note.toLowerCase().contains(needle) ||
          (d.entry.payee ?? '').toLowerCase().contains(needle) ||
          (d.category?.name ?? '').toLowerCase().contains(needle) ||
          (d.category?.displayName(context) ?? '').toLowerCase().contains(needle) ||
          d.items.any((i) => i.name.toLowerCase().contains(needle));
    }).toList();
    final groups = _groupByDay(entries);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.entries), actions: const [MonthSwitcher()]),
      body: DismissKeyboardOnTap(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchEntriesHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => ref.read(_searchProvider.notifier).set('')),
                isDense: true,
              ),
              onChanged: (value) => ref.read(_searchProvider.notifier).set(value),
            ),
          ),
          ChipRow(
            children: [
              if (routeFilters.categoryId != null)
                _RouteFilterChip(
                  label: _categoryFilterLabel(context, ref, routeFilters.categoryId!),
                  onDeleted: () => context.go(routeFilters.locationWithout(category: true)),
                ),
              if (routeFilters.accountId != null)
                _RouteFilterChip(
                  label: _accountFilterLabel(ref, routeFilters.accountId!),
                  onDeleted: () => context.go(routeFilters.locationWithout(account: true)),
                ),
              for (final (label, value) in [(l10n.all, null), (l10n.kindExpenses, 'expense'), (l10n.income, 'income'), (l10n.kindTransfers, 'transfer')])
                ChoiceChip(label: Text(label), selected: kindFilter == value, onSelected: (_) => ref.read(_kindFilterProvider.notifier).set(value)),
            ],
          ),
          Expanded(
            child: async.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groups.isEmpty
                    ? EmptyState(icon: Icons.receipt_long_outlined, title: l10n.noEntriesTitle, message: l10n.noEntriesBody)
                    : ListView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final dayTotal = group.entries.where((d) => d.entry.kind == 'expense').fold(0, (sum, d) => sum + d.myAmountMinor);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                                child: Row(children: [
                                  Expanded(child: Text(formatDayLabel(group.day, today: l10n.today, yesterday: l10n.yesterday, locale: Localizations.localeOf(context).toString()), style: Theme.of(context).textTheme.labelLarge)),
                                  if (dayTotal > 0) Text(formatMinor(dayTotal, symbol: symbol), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ]),
                              ),
                              Card(
                                child: Column(children: [
                                  for (final details in group.entries)
                                    EntryTile(details: details, onTap: () => context.push('/entry?id=${details.entry.id}')),
                                ]),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
        ),
      ),
    );
  }
}

class _DayGroup {
  _DayGroup(this.day) : entries = [];
  final DateTime day;
  final List<EntryDetails> entries;
}

List<_DayGroup> _groupByDay(List<EntryDetails> entries) {
  final groups = <_DayGroup>[];
  for (final details in entries) {
    final day = startOfDay(details.entry.occurredAt);
    if (groups.isEmpty || groups.last.day != day) groups.add(_DayGroup(day));
    groups.last.entries.add(details);
  }
  return groups;
}

class _RouteFilterChip extends StatelessWidget {
  const _RouteFilterChip({required this.label, required this.onDeleted});
  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) => InputChip(label: Text(label), selected: true, onDeleted: onDeleted);
}

String _categoryFilterLabel(BuildContext context, WidgetRef ref, String categoryId) {
  if (categoryId.isEmpty) return context.l10n.uncategorised;
  final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
  return categories.where((category) => category.id == categoryId).firstOrNull?.displayName(context) ?? context.l10n.category;
}

String _accountFilterLabel(WidgetRef ref, String accountId) {
  final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
  return accounts.where((account) => account.id == accountId).firstOrNull?.name ?? '';
}
