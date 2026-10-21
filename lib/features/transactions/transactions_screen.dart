import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/repositories/entries_repository.dart';
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

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final search = ref.watch(_searchProvider);
    final kindFilter = ref.watch(_kindFilterProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final async = ref.watch(monthEntriesProvider);
    final entries = (async.value ?? const <EntryDetails>[]).where((d) {
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
      body: Column(
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
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (label, value) in [(l10n.all, null), (l10n.kindExpenses, 'expense'), (l10n.income, 'income'), (l10n.kindTransfers, 'transfer')])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(label), selected: kindFilter == value, onSelected: (_) => ref.read(_kindFilterProvider.notifier).set(value)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: async.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groups.isEmpty
                    ? EmptyState(icon: Icons.receipt_long_outlined, title: l10n.noEntriesTitle, message: l10n.noEntriesBody)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final dayTotal = group.entries.where((d) => d.entry.kind == 'expense').fold(0, (sum, d) => sum + d.entry.amountMinor);
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
