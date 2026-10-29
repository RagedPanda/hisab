import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/quick_entries/quick_entry_strip.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

const String kQuickEntriesLocation = '/settings/quick-entries';

/// Settings → Quick entries: how many chips Home shows, their order (drag),
/// and rename or delete. New ones come from the editor in "save as quick" mode.
class QuickEntriesScreen extends ConsumerWidget {
  const QuickEntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quickEntries = ref.watch(quickEntriesProvider).value ?? const <QuickEntry>[];
    final shown = ref.watch(settingsProvider).quickEntriesShown;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quickEntries)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('quickEntries.add'),
        onPressed: () => context.push('/entry?saveAs=quick'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newQuickEntry),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.view_carousel_outlined),
              title: Text(l10n.quickEntriesShown),
              subtitle: Text(l10n.quickEntriesShownHint(shown)),
              trailing: _ShownStepper(shown: shown),
            ),
          ),
          const SizedBox(height: 8),
          if (quickEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: EmptyState(icon: Icons.bolt_outlined, title: l10n.quickEntries, message: l10n.quickEntriesEmpty),
            )
          else
            Card(
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderItem: (oldIndex, newIndex) =>
                    ref.read(quickEntriesRepositoryProvider).reorder(reorderedIds([for (final quick in quickEntries) quick.id], oldIndex, newIndex)),
                children: [
                  for (final (index, quick) in quickEntries.indexed) _QuickEntryTile(key: ValueKey('quickEntries.row.${quick.id}'), quick: quick, index: index),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ShownStepper extends ConsumerWidget {
  const _ShownStepper({required this.shown});
  final int shown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    Future<void> setShown(int count) => notifier.update((settings) => settings.copyWith(quickEntriesShown: clampQuickEntriesShown(count)));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('quickEntries.fewer'),
          icon: const Icon(Icons.remove),
          onPressed: shown > kMinQuickEntriesShown ? () => setShown(shown - 1) : null,
        ),
        Text('$shown', style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          key: const Key('quickEntries.more'),
          icon: const Icon(Icons.add),
          onPressed: shown < kMaxQuickEntriesShown ? () => setShown(shown + 1) : null,
        ),
      ],
    );
  }
}

class _QuickEntryTile extends ConsumerWidget {
  const _QuickEntryTile({super.key, required this.quick, required this.index});
  final QuickEntry quick;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repo = ref.read(quickEntriesRepositoryProvider);
    final amount = quick.amountMinor;
    return ListTile(
      leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_indicator)),
      title: Text(quick.label),
      subtitle: Text(amount == null ? l10n.quickEntryNoAmount : formatMinor(amount, format: ref.watch(homeMoneyFormatProvider))),
      onTap: () => context.push('/entry?quick=${quick.id}'),
      trailing: PopupMenuButton<String>(
        key: Key('quickEntries.menu.${quick.id}'),
        onSelected: (action) async {
          if (action == 'edit') {
            context.push('/entry?quick=${quick.id}&saveAs=quick');
          } else if (action == 'rename') {
            final label = await promptText(context, title: l10n.quickEntryName, initial: quick.label);
            if (label != null && label.trim().isNotEmpty) await repo.rename(quick.id, label.trim());
          } else if (await confirmDialog(context, title: l10n.deleteNamed(quick.label))) {
            await repo.delete(quick.id);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
          PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
          PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
        ],
      ),
    );
  }
}
