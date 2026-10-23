import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/recurring/repeat_draft.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../../l10n/rule_names.dart';
import '../shell/widgets/common.dart';
import 'recurring_list_model.dart';
import 'repeat_sheet.dart';

String recurringSectionLabel(AppLocalizations l10n, RecurringSection section) => switch (section) {
      RecurringSection.waiting => l10n.recurringSectionWaiting,
      RecurringSection.active => l10n.recurringSectionActive,
      RecurringSection.paused => l10n.recurringSectionPaused,
      RecurringSection.ended => l10n.recurringSectionEnded,
    };

/// What a rule is called in lists: its name, else payee, else category.
String recurringRuleTitle(BuildContext context, RecurringRuleView view) {
  final rule = view.rule;
  if (rule.name.trim().isNotEmpty) return localizedRuleName(context.l10n, rule.name.trim());
  if ((rule.payee ?? '').trim().isNotEmpty) return rule.payee!.trim();
  final category = view.category;
  if (category != null) return category.displayName(context);
  final l10n = context.l10n;
  return rule.kind == 'transfer' ? l10n.kindTransfer : l10n.recurringTitle;
}

/// Settings > Money > Recurring: every rule grouped by what needs doing.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(recurringListProvider);
    void create() => context.push('/recurring/new');
    final list = items.value ?? const <RecurringListItem>[];
    return HomeFallbackPop(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.recurringTitle)),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add-recurring',
          onPressed: create,
          icon: const Icon(Icons.add),
          label: Text(l10n.recurringNew),
        ),
        body: !items.hasValue
            ? const SizedBox.shrink()
            : list.isEmpty
                ? EmptyState(icon: Icons.repeat, title: l10n.recurringEmptyTitle, message: l10n.recurringEmptyBody, action: FilledButton.tonal(onPressed: create, child: Text(l10n.recurringNew)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    children: [
                      for (final (index, item) in list.indexed) ...[
                        if (index == 0 || list[index - 1].section != item.section)
                          SectionHeader(recurringSectionLabel(l10n, item.section), padding: const EdgeInsets.fromLTRB(4, 16, 4, 8)),
                        RecurringRuleCard(item: item),
                      ],
                    ],
                  ),
      ),
    );
  }
}

enum _RuleAction { edit, pause, resume, delete }

class RecurringRuleCard extends ConsumerWidget {
  const RecurringRuleCard({super.key, required this.item});
  final RecurringListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final view = item.view;
    final rule = view.rule;
    final category = view.category;
    final repository = ref.read(recurringRepositoryProvider);
    final monthStartDay = ref.watch(settingsProvider).monthStartDay;
    final summary = repeatSummary(l10n, RepeatDraft.fromSpec(specOf(rule), autoPost: rule.autoPost), rule.nextDue ?? rule.startDate, locale: locale);
    final nextDue = rule.nextDue;
    final when = switch (item.section) {
      RecurringSection.waiting => l10n.recurringDue(formatRowDate(nextDue!, locale: locale)),
      RecurringSection.active => l10n.recurringNext(formatRowDate(nextDue!, locale: locale)),
      RecurringSection.paused || RecurringSection.ended => l10n.recurringPostedCount(rule.postedCount),
    };
    final waiting = item.section == RecurringSection.waiting;
    final messenger = ScaffoldMessenger.of(context);

    Future<void> onAction(_RuleAction action) async {
      switch (action) {
        case _RuleAction.edit:
          context.push('/recurring/${rule.id}');
        case _RuleAction.pause:
          await repository.setPaused(rule.id, true, now: DateTime.now(), monthStartDay: monthStartDay);
        case _RuleAction.resume:
          await repository.setPaused(rule.id, false, now: DateTime.now(), monthStartDay: monthStartDay);
        case _RuleAction.delete:
          await repository.delete(rule.id);
          showUndoSnackBar(messenger, message: l10n.recurringDeleted, undoLabel: l10n.undo, onUndo: () => repository.restore(rule.id));
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/recurring/${rule.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(icon: category?.icon ?? (rule.kind == 'transfer' ? 'swap_horiz' : 'category'), color: category?.color ?? 0xFF9E9E9E),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recurringRuleTitle(context, view), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(
                          when,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: waiting ? theme.colorScheme.error : theme.colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(padding: const EdgeInsets.only(top: 2), child: AmountText(rule.amountMinor, kind: rule.kind)),
                  PopupMenuButton<_RuleAction>(
                    key: ValueKey('recurring.menu.${rule.id}'),
                    onSelected: onAction,
                    itemBuilder: (_) => [
                      PopupMenuItem(value: _RuleAction.edit, child: Text(l10n.edit)),
                      if (rule.status == RecurringStatus.active) PopupMenuItem(value: _RuleAction.pause, child: Text(l10n.recurringPause)),
                      if (rule.status == RecurringStatus.paused) PopupMenuItem(value: _RuleAction.resume, child: Text(l10n.recurringResume)),
                      PopupMenuItem(value: _RuleAction.delete, child: Text(l10n.delete)),
                    ],
                  ),
                ],
              ),
              if (waiting)
                Padding(
                  padding: const EdgeInsets.only(left: 52, right: 12, top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.tonal(
                        key: ValueKey('recurring.confirm.${rule.id}'),
                        onPressed: () async {
                          await repository.confirmNext(rule.id, monthStartDay: monthStartDay);
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(l10n.recurringAdded)));
                        },
                        child: Text(l10n.recurringConfirm),
                      ),
                      TextButton(
                        key: ValueKey('recurring.skip.${rule.id}'),
                        onPressed: () async {
                          await repository.skipNext(rule.id, monthStartDay: monthStartDay);
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(l10n.recurringSkipped)));
                        },
                        child: Text(l10n.recurringSkip),
                      ),
                      if (item.waiting > 1) Text(l10n.recurringMoreWaiting(item.waiting - 1), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
