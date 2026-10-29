import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ids.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../data/db/database.dart';
import '../../../data/repositories/quick_entries_repository.dart';
import '../../../domain/quick_entries/quick_entry_strip.dart';
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

/// Adds the entry [quick] stands for now, then offers Undo; opens the editor
/// instead when it cannot be added as it is (no account left).
Future<void> addQuickEntry(BuildContext context, WidgetRef ref, QuickEntry quick, {required Category? category}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final moneyFormat = ref.read(homeMoneyFormatProvider);
  final router = GoRouter.of(context);
  final entries = ref.read(entriesRepositoryProvider);
  final entry = entryFromQuickEntry(
    quick,
    accounts: await ref.read(accountsRepositoryProvider).getAll(),
    category: category,
    configuredAccountId: ref.read(settingsProvider).defaultAccountId,
    now: DateTime.now(),
    id: newId(),
  );
  if (entry == null) {
    router.push('/entry?quick=${quick.id}');
    return;
  }
  await entries.saveEntry(entry);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(l10n.quickEntryAdded(quick.label, formatMinor(entry.amountMinor.value, format: moneyFormat))),
      action: SnackBarAction(label: l10n.undo, onPressed: () => entries.deleteEntry(entry.id.value)),
    ));
}
