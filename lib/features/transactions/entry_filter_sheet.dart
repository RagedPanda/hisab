import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/entries/entry_filter.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../categories/category_picker.dart';
import '../projects/project_picker_sheet.dart';
import '../shell/widgets/common.dart';

/// The Entries filter sheet. Returns the new filter on "Show results" and
/// null when dismissed. [categoryKind] decides which categories the picker
/// lists (income while the income chip is on, expenses otherwise).
Future<EntryFilter?> showEntryFilterSheet(BuildContext context, {required EntryFilter initial, required String categoryKind}) =>
    showModalBottomSheet<EntryFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (context, controller) => _EntryFilterBody(initial: initial, categoryKind: categoryKind, controller: controller),
        ),
      ),
    );

/// Short label of a date range, e.g. "10 Oct 2026 – 12 Oct 2026".
String dateRangeLabel(DateTime? from, DateTime? to, {String? locale}) =>
    [if (from != null) formatShortDate(from, locale: locale), if (to != null) formatShortDate(to, locale: locale)].join(' – ');

/// Short label of an amount range in the user's currency.
String amountRangeLabel(AppLocalizations l10n, int? minMinor, int? maxMinor, String symbol) {
  String money(int minor) => formatMinor(minor, symbol: symbol, showDecimals: minor % 100 != 0);
  if (minMinor != null && maxMinor != null) return l10n.amountBetween(money(minMinor), money(maxMinor));
  if (minMinor != null) return l10n.amountFrom(money(minMinor));
  return l10n.amountUpTo(money(maxMinor ?? 0));
}

class _EntryFilterBody extends ConsumerStatefulWidget {
  const _EntryFilterBody({required this.initial, required this.categoryKind, required this.controller});
  final EntryFilter initial;
  final String categoryKind;
  final ScrollController controller;

  @override
  ConsumerState<_EntryFilterBody> createState() => _EntryFilterBodyState();
}

class _EntryFilterBodyState extends ConsumerState<_EntryFilterBody> {
  late EntryFilter _draft = widget.initial;
  late final _minController = TextEditingController(text: _amountText(widget.initial.minAmountMinor));
  late final _maxController = TextEditingController(text: _amountText(widget.initial.maxAmountMinor));

  static String _amountText(int? minor) => minor == null ? '' : amountInputText(minor);

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _setAmounts() => setState(() => _draft = _draft.copyWith(
        minAmountMinor: parseAmountToMinor(_minController.text),
        maxAmountMinor: parseAmountToMinor(_maxController.text),
      ));

  void _clearAll() {
    _minController.clear();
    _maxController.clear();
    setState(() => _draft = const EntryFilter());
  }

  Future<void> _pickProject() async {
    final choice = await showProjectPicker(context, selectedId: _draft.projectId, includeCompleted: true, noneLabel: context.l10n.anyProject);
    if (choice != null) setState(() => _draft = _draft.copyWith(projectId: choice.projectId));
  }

  Future<void> _pickCategory() async {
    final picked = await showCategoryPicker(context, kind: widget.categoryKind, selectedId: _draft.categoryId);
    if (picked != null) setState(() => _draft = _draft.copyWith(categoryId: picked.id));
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _draft.from != null && _draft.to != null ? DateTimeRange(start: _draft.from!, end: _draft.to!) : null,
    );
    if (picked != null) setState(() => _draft = _draft.copyWith(from: picked.start, to: picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final projects = ref.watch(projectViewsProvider).value ?? const [];
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final tags = ref.watch(entryTagsProvider).value ?? const <String>[];
    final projectName = projects.where((view) => view.project.id == _draft.projectId).firstOrNull?.project.name;
    final category = categories.where((category) => category.id == _draft.categoryId).firstOrNull;
    final amountError = validateAmountRange(_draft.minAmountMinor, _draft.maxAmountMinor);
    Widget clearButton(VoidCallback onPressed) => IconButton(tooltip: l10n.clear, icon: const Icon(Icons.close), onPressed: onPressed);
    Widget label(String text) => Padding(padding: const EdgeInsets.fromLTRB(0, 16, 0, 6), child: Text(text, style: theme.textTheme.labelLarge));

    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const ValueKey('filter.sheet'),
            controller: widget.controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(l10n.filterEntries, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ListTile(
                key: const ValueKey('filter.project'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined),
                title: Text(projectName ?? l10n.anyProject, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(l10n.project),
                trailing: _draft.projectId == null ? const Icon(Icons.chevron_right) : clearButton(() => setState(() => _draft = _draft.copyWith(projectId: null))),
                onTap: _pickProject,
              ),
              ListTile(
                key: const ValueKey('filter.category'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category_outlined),
                title: Text(category?.displayName(context) ?? l10n.anyCategory, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(l10n.category),
                trailing: _draft.categoryId == null ? const Icon(Icons.chevron_right) : clearButton(() => setState(() => _draft = _draft.copyWith(categoryId: null))),
                onTap: _pickCategory,
              ),
              label(l10n.account),
              Wrap(spacing: 8, runSpacing: 4, children: [
                ChoiceChip(
                  key: const ValueKey('filter.account.any'),
                  label: Text(l10n.all),
                  selected: _draft.accountId == null,
                  onSelected: (_) => setState(() => _draft = _draft.copyWith(accountId: null)),
                ),
                for (final account in accounts)
                  ChoiceChip(
                    key: ValueKey('filter.account.${account.id}'),
                    label: Text(account.name),
                    selected: _draft.accountId == account.id,
                    onSelected: (_) => setState(() => _draft = _draft.copyWith(accountId: account.id)),
                  ),
              ]),
              label(l10n.amountLabel),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('filter.minAmount'),
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: amountInputFormatters,
                    decoration: InputDecoration(labelText: l10n.minAmount, errorText: amountError == null ? null : l10n.minAboveMax, errorMaxLines: 2),
                    onChanged: (_) => _setAmounts(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('filter.maxAmount'),
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: amountInputFormatters,
                    decoration: InputDecoration(labelText: l10n.maxAmount),
                    onChanged: (_) => _setAmounts(),
                  ),
                ),
              ]),
              label(l10n.dates),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('filter.dates'),
                    icon: const Icon(Icons.date_range_outlined, size: 18),
                    label: Text(_draft.hasDates ? dateRangeLabel(_draft.from, _draft.to, locale: locale) : l10n.anyDate, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onPressed: _pickDates,
                  ),
                ),
                if (_draft.hasDates) clearButton(() => setState(() => _draft = _draft.copyWith(from: null, to: null))),
              ]),
              if (tags.isNotEmpty) ...[
                label(l10n.tags),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final tag in tags)
                    ChoiceChip(
                      key: ValueKey('filter.tag.$tag'),
                      label: Text('#$tag'),
                      selected: _draft.tag?.toLowerCase() == tag.toLowerCase(),
                      onSelected: (on) => setState(() => _draft = _draft.copyWith(tag: on ? tag : null)),
                    ),
                ]),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              TextButton(key: const ValueKey('filter.clearAll'), onPressed: _clearAll, child: Text(l10n.clearAll)),
              const Spacer(),
              FilledButton(
                key: const ValueKey('filter.apply'),
                onPressed: amountError == null ? () => Navigator.of(context).pop(_draft) : null,
                child: Text(l10n.showResults),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
