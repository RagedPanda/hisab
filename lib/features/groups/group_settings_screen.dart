import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/split/group_settings.dart';
import '../../domain/split/split_calculator.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import '../split/split_editor.dart';
import 'group_actions.dart';
import 'group_detail_screen.dart';
import 'group_form.dart';
import 'member_display.dart';

String groupTypeLabel(GroupType type, AppLocalizations l10n) => switch (type) {
      GroupType.trip => l10n.groupTypeTrip,
      GroupType.home => l10n.groupTypeHome,
      GroupType.couple => l10n.groupTypeCouple,
      GroupType.other => l10n.groupTypeOther,
    };

/// Name, type, icon, default split with member weights, currency label,
/// simplify debts, notes, and archive / leave / delete (gap report 4.7).
class GroupSettingsScreen extends ConsumerWidget {
  const GroupSettingsScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(groupDetailProvider(groupId)).value;
    final appSymbol = ref.watch(settingsProvider).currencySymbol;
    if (detail == null) return Scaffold(appBar: AppBar(title: Text(l10n.groupSettingsTitle)), body: const SizedBox.shrink());
    final group = detail.group;
    final repo = ref.read(groupsRepositoryProvider);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final type = GroupType.parse(group.type);
    final defaultSplit = parseDefaultSplitMethod(group.defaultSplitMethod);
    final symbol = groupSymbol(currencyLabel: group.currencyLabel, appSymbol: appSymbol);
    final saved = detail.balances.repaymentsSaved;
    Future<void> update(GroupsCompanion changes) => repo.updateGroup(changes.copyWith(id: Value(group.id)));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Column(children: [
              ListTile(
                leading: IconBadge(icon: group.icon, color: kSeedColor.toARGB32()),
                title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.groupName),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () async {
                  final name = await promptText(context, title: l10n.renameGroup, initial: group.name);
                  if (name != null && name.isNotEmpty) await update(GroupsCompanion(name: Value(name)));
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.groupSettingsType, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final option in GroupType.values)
                      ChoiceChip(
                        label: Text(groupTypeLabel(option, l10n)),
                        selected: type == option,
                        onSelected: (_) => update(GroupsCompanion(
                          type: Value(option.name),
                          icon: Value(iconAfterTypeChange(currentIcon: group.icon, previous: type, next: option)),
                        )),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  Text(l10n.groupSettingsIcon, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  GroupIconPicker(selected: group.icon, onSelected: (icon) => update(GroupsCompanion(icon: Value(icon)))),
                ]),
              ),
            ]),
          ),
          SectionHeader(l10n.groupSettingsDefaultSplit),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final method in groupDefaultSplitMethods)
                    ChoiceChip(
                      label: Text(splitMethodLabel(method, l10n)),
                      selected: defaultSplit == method,
                      onSelected: (_) => update(GroupsCompanion(defaultSplitMethod: Value(method.name))),
                    ),
                ]),
                const SizedBox(height: 8),
                Text(l10n.groupSettingsDefaultSplitHint, style: muted),
                if (defaultSplit == SplitMethod.shares) ...[
                  const SizedBox(height: 12),
                  Text(l10n.groupSettingsWeights, style: theme.textTheme.labelLarge),
                  for (final member in detail.members) _WeightRow(member: member, onChanged: (weight) => repo.setMemberWeight(member.id, weight)),
                ],
              ]),
            ),
          ),
          SectionHeader(l10n.groupSettingsSimplify),
          Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SwitchListTile(
                title: Text(l10n.groupSettingsSimplify),
                value: group.simplifyDebts,
                onChanged: (value) => update(GroupsCompanion(simplifyDebts: Value(value))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.groupSettingsSimplifyBody, style: muted),
                  if (saved > 0) ...[
                    const SizedBox(height: 6),
                    Text(l10n.groupSettingsSimplifySaves(saved), style: theme.textTheme.bodyMedium?.copyWith(color: kIncomeColor, fontWeight: FontWeight.w600)),
                  ],
                ]),
              ),
            ]),
          ),
          SectionHeader(l10n.groupSettingsCurrency),
          Card(
            child: ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: Text(group.currencyLabel == null ? l10n.groupSettingsCurrencyAppDefault(appSymbol) : symbol),
              subtitle: Text(l10n.groupSettingsCurrencyHint),
              onTap: () => _pickCurrency(context, ref, group, appSymbol),
            ),
          ),
          SectionHeader(l10n.groupSettingsNotes),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: Text(group.notes.isEmpty ? l10n.groupSettingsNotesAdd : group.notes, maxLines: 4, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final notes = await promptText(context, title: l10n.groupSettingsNotes, initial: group.notes, hint: l10n.groupSettingsNotesHint, maxLines: 6);
                if (notes != null) await update(GroupsCompanion(notes: Value(notes)));
              },
            ),
          ),
          SectionHeader(l10n.groupSettingsManage),
          Card(
            child: Column(children: [
              if (group.archivedAt == null)
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(l10n.groupArchive),
                  onTap: () => confirmArchiveGroup(context, ref, detail),
                )
              else
                ListTile(
                  leading: const Icon(Icons.unarchive_outlined),
                  title: Text(l10n.groupUnarchive),
                  onTap: () => repo.unarchiveGroup(group.id),
                ),
              if (detail.me != null)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.groupLeave),
                  onTap: () => confirmLeaveGroup(context, ref, detail),
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text(l10n.deleteGroup, style: TextStyle(color: theme.colorScheme.error)),
                onTap: () async {
                  if (await confirmDeleteGroup(context, ref, detail) && context.mounted) context.go('/groups');
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet of common currency symbols, the app default and a typed one.
  static Future<void> _pickCurrency(BuildContext context, WidgetRef ref, Group group, String appSymbol) {
    final l10n = context.l10n;
    final repo = ref.read(groupsRepositoryProvider);
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        void choose(String? label) {
          Navigator.of(sheetContext).pop();
          repo.setCurrencyLabel(group, label);
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _choice(l10n.groupSettingsCurrencyAppDefault(appSymbol), selected: group.currencyLabel == null, onTap: () => choose(null)),
              for (final currency in groupCurrencies)
                _choice('${currency.symbol}  ·  ${currency.code}', selected: group.currencyLabel == currency.symbol, onTap: () => choose(currency.symbol)),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.groupSettingsCurrencyOther),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final typed = await promptText(context, title: l10n.groupSettingsCurrency, initial: group.currencyLabel ?? '', hint: '₹, \$, €');
                  if (typed != null && typed.isNotEmpty) await repo.setCurrencyLabel(group, typed);
                },
              ),
            ]),
          ),
        );
      },
    );
  }
}

Widget _choice(String label, {required bool selected, required VoidCallback onTap}) => ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: onTap,
    );

/// One member's share weight with a −/+ stepper.
class _WeightRow extends StatelessWidget {
  const _WeightRow({required this.member, required this.onChanged});
  final Member member;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = memberShortName(l10n, member);
    final weight = member.weight;
    return Row(children: [
      MemberAvatar(member: member),
      const SizedBox(width: 12),
      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      IconButton(
        tooltip: l10n.groupSettingsWeightLess(name),
        onPressed: weight <= minMemberWeight ? null : () => onChanged(steppedWeight(weight, -1)),
        icon: const Icon(Icons.remove_circle_outline),
      ),
      SizedBox(
        width: 72,
        child: Text(l10n.groupSettingsWeightValue(formatQuantity(weight, null)), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600).tabular),
      ),
      IconButton(
        tooltip: l10n.groupSettingsWeightMore(name),
        onPressed: weight >= maxMemberWeight ? null : () => onChanged(steppedWeight(weight, 1)),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ]);
  }
}
