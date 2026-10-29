import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../core/ids.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../data/db/database.dart';
import '../../../data/repositories/quick_entries_repository.dart';
import '../../../domain/quick_entries/quick_entry_strip.dart';
import '../../../l10n/category_names.dart';
import '../../../l10n/l10n.dart';
import '../../quick_entries/quick_entries_screen.dart';
import '../../shell/widgets/common.dart';
import '../dashboard_keys.dart';
import 'dashboard_card.dart';

/// The user's quick entries as one-tap chips: the first few (Settings →
/// Quick entries), the rest behind "+N more". A chip with an amount adds the
/// entry at once with Undo; one without, or a long press, opens the editor
/// prefilled. Hidden until there is a quick entry.
class QuickEntriesCard extends ConsumerWidget {
  const QuickEntriesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickEntries = ref.watch(quickEntriesProvider).value ?? const <QuickEntry>[];
    if (quickEntries.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final split = splitQuickEntries(quickEntries, ref.watch(settingsProvider).quickEntriesShown);
    return DashboardSection(
      title: l10n.quickEntries,
      trailing: SectionAction(label: l10n.manage, onPressed: () => context.push(kQuickEntriesLocation)),
      child: Wrap(
        key: kQuickEntriesCardKey,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final quick in split.shown) QuickEntryChip(quick: quick),
          if (split.hidden > 0)
            ActionChip(
              key: const ValueKey('quick.more'),
              label: Text(l10n.quickEntriesMore(split.hidden)),
              onPressed: () => _showAll(context, quickEntries),
            ),
        ],
      ),
    );
  }

  void _showAll(BuildContext context, List<QuickEntry> quickEntries) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  sheetContext.l10n.quickEntries,
                  trailing: SectionAction(
                    label: sheetContext.l10n.manage,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.push(kQuickEntriesLocation);
                    },
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final quick in quickEntries) QuickEntryChip(quick: quick, onUsed: () => Navigator.pop(sheetContext))],
                ),
              ],
            ),
          ),
        ),
      );
}

/// One quick entry: its name and amount. [onUsed] runs before it acts, so a
/// sheet holding it can close first.
class QuickEntryChip extends ConsumerWidget {
  const QuickEntryChip({super.key, required this.quick, this.onUsed});
  final QuickEntry quick;
  final VoidCallback? onUsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final category = (ref.watch(allCategoriesProvider).value ?? const <Category>[]).where((category) => category.id == quick.categoryId).firstOrNull;
    final amount = quick.amountMinor;
    void openEditor() {
      onUsed?.call();
      context.push('/entry?quick=${quick.id}');
    }

    return GestureDetector(
      onLongPress: openEditor,
      child: ActionChip(
        key: ValueKey('quick.${quick.id}'),
        avatar: category == null ? const Icon(Icons.bolt_outlined, size: 18) : IconBadge(icon: category.icon, color: category.color, size: 24),
        label: Text(amount == null ? quick.label : '${quick.label} · ${formatMinor(amount, format: moneyFormat, showDecimals: false)}'),
        onPressed: amount == null
            ? openEditor
            : () {
                onUsed?.call();
                addQuickEntry(context, ref, quick, category: category);
              },
      ),
    );
  }
}

/// Asks to confirm the entry [quick] stands for, on a day the user can
/// change (today by default), then adds it and offers Undo; opens the editor
/// instead when it cannot be added as it is (no account left).
Future<void> addQuickEntry(BuildContext context, WidgetRef ref, QuickEntry quick, {required Category? category}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final moneyFormat = ref.read(homeMoneyFormatProvider);
  final router = GoRouter.of(context);
  final entries = ref.read(entriesRepositoryProvider);
  final accounts = await ref.read(accountsRepositoryProvider).getAll();
  final configuredAccountId = ref.read(settingsProvider).defaultAccountId;
  final id = newId();
  EntriesCompanion? entryAt(DateTime at) => entryFromQuickEntry(quick, accounts: accounts, category: category, configuredAccountId: configuredAccountId, now: at, id: id);
  if (entryAt(DateTime.now()) == null) {
    router.push('/entry?quick=${quick.id}');
    return;
  }
  if (!context.mounted) return;
  final day = await showDialog<DateTime>(
    context: context,
    builder: (_) => _ConfirmQuickEntryDialog(quick: quick, category: category, amountText: formatMinor(quick.amountMinor ?? 0, format: moneyFormat)),
  );
  if (day == null) return;
  final entry = entryAt(onDayAt(day, DateTime.now()))!;
  await entries.saveEntry(entry);
  showUndoSnackBar(
    messenger,
    message: l10n.quickEntryAdded(quick.label, formatMinor(entry.amountMinor.value, format: moneyFormat)),
    undoLabel: l10n.undo,
    onUndo: () => entries.deleteEntry(entry.id.value),
  );
}

/// "Add Milk?" with the amount, category and the day it goes on; pops the
/// chosen day, or null on Cancel.
class _ConfirmQuickEntryDialog extends StatefulWidget {
  const _ConfirmQuickEntryDialog({required this.quick, required this.category, required this.amountText});
  final QuickEntry quick;
  final Category? category;
  final String amountText;

  @override
  State<_ConfirmQuickEntryDialog> createState() => _ConfirmQuickEntryDialogState();
}

class _ConfirmQuickEntryDialogState extends State<_ConfirmQuickEntryDialog> {
  DateTime _day = startOfDay(DateTime.now());

  Future<void> _pickDay() async {
    final today = startOfDay(DateTime.now());
    final picked = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(today.year - 5), lastDate: today);
    if (picked != null) setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = widget.category;
    return AlertDialog(
      key: const Key('quick.confirm'),
      title: Text(l10n.quickEntryConfirm(widget.quick.label)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.amountText, style: Theme.of(context).textTheme.headlineSmall),
          if (category != null) Text(category.displayName(context), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('quick.confirm.day'),
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(formatDayLabel(_day, today: l10n.today, yesterday: l10n.yesterday, locale: Localizations.localeOf(context).toString())),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(key: const Key('quick.confirm.add'), onPressed: () => Navigator.pop(context, _day), child: Text(l10n.add)),
      ],
    );
  }
}
