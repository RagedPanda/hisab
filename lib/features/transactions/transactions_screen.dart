import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/entries_repository.dart';
import '../../domain/entries/entry_filter.dart';
import '../../domain/entries/entry_summary.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../projects/project_picker_sheet.dart';
import 'entry_filter_sheet.dart';
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

class _EntryFilterNotifier extends Notifier<EntryFilter> {
  @override
  EntryFilter build() => const EntryFilter();
  void set(EntryFilter value) => state = value;
}

final _entryFilterProvider = NotifierProvider<_EntryFilterNotifier, EntryFilter>(_EntryFilterNotifier.new);
final _searchProvider = NotifierProvider<_SearchNotifier, String>(_SearchNotifier.new);
final _kindFilterProvider = NotifierProvider<_KindFilterNotifier, String?>(_KindFilterNotifier.new);

/// Filters carried in the route, e.g. `/transactions?category=<id>` from the
/// dashboard donut, `?account=<id>` from an account card or `?day=2026-10-24`
/// from the Home "Today" figure. Dismissing a chip navigates to the same
/// route without that parameter.
class RouteFilters {
  const RouteFilters({this.categoryId, this.accountId, this.day});
  final String? categoryId;
  final String? accountId;

  /// One calendar day, local midnight.
  final DateTime? day;

  static RouteFilters of(BuildContext context) {
    final params = GoRouterState.of(context).uri.queryParameters;
    return RouteFilters(categoryId: params['category'], accountId: params['account'], day: parseIsoDay(params['day']));
  }

  bool get isEmpty => categoryId == null && accountId == null && day == null;

  String locationWithout({bool category = false, bool account = false, bool day = false}) => Uri(
        path: '/transactions',
        queryParameters: {
          if (!category && categoryId != null) 'category': categoryId!,
          if (!account && accountId != null) 'account': accountId!,
          if (!day && this.day != null) 'day': isoDay(this.day!),
        },
      ).toString().replaceFirst(RegExp(r'\?$'), '');

  EntryFilter get asFilter => EntryFilter(categoryId: categoryId, accountId: accountId, from: day, to: day);
}

/// The Entries list narrowed to the single day [day].
String entriesForDayLocation(DateTime day) => '/transactions?day=${isoDay(day)}';

/// What search and filters see of one listed entry.
EntryFacts entryFacts(BuildContext context, EntryDetails details) => EntryFacts(
      amountMinor: details.myAmountMinor,
      occurredAt: details.entry.occurredAt,
      note: details.entry.note,
      payee: details.entry.payee,
      categoryId: details.category?.id,
      categoryParentId: details.category?.parentId,
      categoryNames: [if (details.category != null) ...[details.category!.name, details.category!.displayName(context)]],
      itemNames: [for (final item in details.items) item.name],
      accountId: details.entry.accountId,
      toAccountId: details.entry.toAccountId,
      projectId: details.entry.projectId,
      tags: details.entry.tags,
    );

/// What the filtered-list summary sees of one listed entry: the user's share
/// of a shared expense, and its item lines as entered.
SummaryEntry summaryEntry(EntryDetails details) => (
      kind: details.entry.kind,
      amountMinor: details.myAmountMinor,
      items: [for (final item in details.items) (name: item.name, quantity: item.quantity, unit: item.unit, amountMinor: item.amountMinor)],
    );

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final search = ref.watch(_searchProvider);
    final kindFilter = ref.watch(_kindFilterProvider);
    final filter = ref.watch(_entryFilterProvider);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final routeFilters = RouteFilters.of(context);
    final routeFilter = routeFilters.asFilter;
    // The sheet's dates win when both are set; both filters still apply below.
    final window = filter.dateWindow ?? routeFilter.dateWindow;
    final async = window == null ? ref.watch(monthEntriesProvider) : ref.watch(windowEntriesProvider(window));
    final entries = (async.value ?? const <EntryDetails>[]).where((d) {
      if (kindFilter != null && d.entry.kind != kindFilter) return false;
      final facts = entryFacts(context, d);
      return matchesEntryFilter(routeFilter, facts) && matchesEntryFilter(filter, facts) && matchesSearch(search, facts);
    }).toList();
    final groups = groupConsecutiveByDay(entries, (details) => details.entry.occurredAt);
    final narrowed = search.trim().isNotEmpty || !filter.isEmpty || kindFilter != null || !routeFilters.isEmpty;
    void clearAll() {
      ref.read(_searchProvider.notifier).set('');
      ref.read(_entryFilterProvider.notifier).set(const EntryFilter());
      ref.read(_kindFilterProvider.notifier).set(null);
      if (!routeFilters.isEmpty) context.go('/transactions');
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.entries), actions: [if (window == null) const MonthSwitcher()]),
      body: DismissKeyboardOnTap(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              const Expanded(child: _SearchField()),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                key: const ValueKey('entries.filters'),
                tooltip: l10n.filters,
                icon: Badge(
                  isLabelVisible: !filter.isEmpty,
                  label: Text('${filter.activeCount}'),
                  child: const Icon(Icons.tune),
                ),
                onPressed: () async {
                  final next = await showEntryFilterSheet(context, initial: filter, categoryKind: kindFilter == 'income' ? 'income' : 'expense');
                  if (next != null) ref.read(_entryFilterProvider.notifier).set(next);
                },
              ),
            ]),
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
              if (routeFilters.day != null)
                _RouteFilterChip(
                  label: isSameDay(routeFilters.day!, DateTime.now())
                      ? l10n.today
                      : dateRangeLabel(routeFilters.day, routeFilters.day, locale: Localizations.localeOf(context).toString()),
                  onDeleted: () => context.go(routeFilters.locationWithout(day: true)),
                ),
              _ProjectFilterChip(selectedId: filter.projectId),
              ..._activeFilterChips(context, ref, filter, moneyFormat),
              for (final (label, value) in [(l10n.all, null), (l10n.kindExpenses, 'expense'), (l10n.income, 'income'), (l10n.kindTransfers, 'transfer')])
                ChoiceChip(label: Text(label), selected: kindFilter == value, onSelected: (_) => ref.read(_kindFilterProvider.notifier).set(value)),
            ],
          ),
          if (narrowed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
              child: Row(children: [
                Expanded(
                  child: Text(
                    l10n.resultsCount(entries.length),
                    key: const ValueKey('entries.resultsCount'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                TextButton(key: const ValueKey('entries.clearAll'), onPressed: clearAll, child: Text(l10n.clearAll)),
              ]),
            ),
          Expanded(
            child: async.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groups.isEmpty
                    ? EmptyState(icon: Icons.receipt_long_outlined, title: l10n.noEntriesTitle, message: l10n.noEntriesBody)
                    : ListView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: groups.length + (narrowed ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (narrowed && index == 0) return _FilteredSummaryCard(summary: summarizeEntries(entries.map(summaryEntry)), moneyFormat: moneyFormat);
                          final group = groups[index - (narrowed ? 1 : 0)];
                          final dayTotal = group.items.where((d) => d.entry.kind == 'expense').fold(0, (sum, d) => sum + d.myAmountMinor);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                                child: Row(children: [
                                  Expanded(child: Text(formatDayLabel(group.day, today: l10n.today, yesterday: l10n.yesterday, locale: Localizations.localeOf(context).toString()), style: Theme.of(context).textTheme.labelLarge)),
                                  if (dayTotal > 0) Text(formatMinor(dayTotal, format: moneyFormat), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ]),
                              ),
                              Card(
                                child: Column(children: [
                                  for (final details in group.items)
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

/// Total spent across the filtered entries, and how much of each item was
/// bought: "Buffalo milk · 62 L · 58 times · ₹4,650".
class _FilteredSummaryCard extends StatelessWidget {
  const _FilteredSummaryCard({required this.summary, required this.moneyFormat});

  final EntrySummary summary;
  final MoneyFormat moneyFormat;

  static const _maxItems = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final shown = summary.items.take(_maxItems).toList();
    return Card(
      key: const ValueKey('entries.summary'),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(l10n.filteredTotal, style: theme.textTheme.titleSmall)),
            Text(formatMinor(summary.spentMinor, format: moneyFormat), key: const ValueKey('entries.summary.spent'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          if (summary.incomeMinor > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                Expanded(child: Text(l10n.income, style: muted)),
                Text(formatMinor(summary.incomeMinor, format: moneyFormat), style: muted),
              ]),
            ),
          if (shown.isNotEmpty) ...[
            const Divider(height: 20),
            for (final item in shown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.name, style: theme.textTheme.bodyMedium),
                      Text(l10n.itemBoughtTimes(formatQuantity(item.quantity, item.unit), item.entryCount), style: muted),
                    ]),
                  ),
                  Text(formatMinor(item.amountMinor, format: moneyFormat), style: theme.textTheme.bodyMedium),
                ]),
              ),
            if (summary.items.length > shown.length) Text(l10n.moreItems(summary.items.length - shown.length), style: muted),
          ],
        ]),
      ),
    );
  }
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

/// Narrows Entries to one project; tapping picks, the cross clears.
class _ProjectFilterChip extends ConsumerWidget {
  const _ProjectFilterChip({required this.selectedId});
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final views = ref.watch(projectViewsProvider).value ?? const [];
    final name = views.where((view) => view.project.id == selectedId).firstOrNull?.project.name;
    final notifier = ref.read(_entryFilterProvider.notifier);
    void setProject(String? projectId) => notifier.set(ref.read(_entryFilterProvider).copyWith(projectId: projectId));
    Future<void> pick() async {
      final choice = await showProjectPicker(context, selectedId: selectedId, includeCompleted: true, noneLabel: l10n.anyProject);
      if (choice != null) setProject(choice.projectId);
    }

    const key = ValueKey('entries.projectFilter');
    if (selectedId == null || name == null) {
      return ActionChip(key: key, avatar: const Icon(Icons.folder_outlined, size: 18), label: Text(l10n.project), onPressed: pick);
    }
    return InputChip(
      key: key,
      selected: true,
      avatar: const Icon(Icons.folder, size: 18),
      label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 160), child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      onPressed: pick,
      onDeleted: () => setProject(null),
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }
}

/// Search box kept in step with the search provider, so "Clear all" empties it.
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final _controller = TextEditingController(text: ref.read(_searchProvider));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(_searchProvider, (_, next) {
      if (next != _controller.text) _controller.text = next;
    });
    final search = ref.watch(_searchProvider);
    return TextField(
      key: const ValueKey('entries.search'),
      controller: _controller,
      decoration: InputDecoration(
        hintText: context.l10n.searchEntriesHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: search.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => ref.read(_searchProvider.notifier).set('')),
        isDense: true,
      ),
      onChanged: (value) => ref.read(_searchProvider.notifier).set(value),
    );
  }
}

/// One removable chip per filter set in the sheet (project has its own chip).
List<Widget> _activeFilterChips(BuildContext context, WidgetRef ref, EntryFilter filter, MoneyFormat moneyFormat) {
  final l10n = context.l10n;
  final notifier = ref.read(_entryFilterProvider.notifier);
  Widget chip(String name, String label, EntryFilter Function(EntryFilter) clear) => InputChip(
        key: ValueKey('entries.filter.$name'),
        label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 200), child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        selected: true,
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () => notifier.set(clear(ref.read(_entryFilterProvider))),
      );
  return [
    if (filter.categoryId != null) chip('category', _categoryFilterLabel(context, ref, filter.categoryId!), (current) => current.copyWith(categoryId: null)),
    if (filter.accountId != null) chip('account', _accountFilterLabel(ref, filter.accountId!), (current) => current.copyWith(accountId: null)),
    if (filter.hasAmount)
      chip('amount', amountRangeLabel(l10n, filter.minAmountMinor, filter.maxAmountMinor, moneyFormat), (current) => current.copyWith(minAmountMinor: null, maxAmountMinor: null)),
    if (filter.hasDates)
      chip('dates', dateRangeLabel(filter.from, filter.to, locale: Localizations.localeOf(context).toString()), (current) => current.copyWith(from: null, to: null)),
    if (filter.tag != null) chip('tag', '#${filter.tag}', (current) => current.copyWith(tag: null)),
  ];
}
