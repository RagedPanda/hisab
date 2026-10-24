import 'package:flutter/material.dart';

import '../../data/db/database.dart';
import '../../domain/split/item_split.dart';
import '../../l10n/l10n.dart';
import '../groups/member_display.dart';

/// Who shares one line item in a by-item group split: one avatar chip per
/// member (tap toggles; long-press offers "Only me" and "Everyone") and a
/// "Shared" chip for common lines such as tax or delivery.
class ItemAssignStrip extends StatelessWidget {
  const ItemAssignStrip({
    super.key,
    required this.itemId,
    required this.itemLabel,
    required this.members,
    required this.memberIds,
    required this.shared,
    required this.onMembersChanged,
    required this.onSharedChanged,
  });

  final String itemId;
  final String itemLabel;
  final List<Member> members;
  final List<String> memberIds;
  final bool shared;
  final ValueChanged<List<String>> onMembersChanged;
  final ValueChanged<bool> onSharedChanged;

  List<String> get _groupOrder => [for (final member in members) member.id];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final unassigned = !shared && memberIds.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final member in members)
              GestureDetector(
                key: Key('assign-$itemId-${member.id}'),
                onLongPressStart: shared ? null : (details) => _showQuickPicks(context, details.globalPosition, member),
                child: FilterChip(
                  avatar: SizedBox.square(dimension: 24, child: MemberAvatar(member: member)),
                  label: Text(memberDisplayName(l10n, member)),
                  selected: !shared && memberIds.contains(member.id),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: shared ? null : (_) => onMembersChanged(toggleItemMember(memberIds, member.id, _groupOrder)),
                ),
              ),
            FilterChip(
              key: Key('assign-shared-$itemId'),
              avatar: const Icon(Icons.groups_outlined, size: 18),
              label: Text(l10n.byItemShared),
              selected: shared,
              visualDensity: VisualDensity.compact,
              onSelected: onSharedChanged,
            ),
          ],
        ),
        if (shared)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.byItemSharedHelp, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        if (unassigned)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.splitErrorItemUnassigned(itemLabel.isEmpty ? l10n.genericItem : itemLabel),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }

  Future<void> _showQuickPicks(BuildContext context, Offset position, Member pressed) async {
    final l10n = context.l10n;
    final me = members.where((member) => member.isMe).firstOrNull ?? pressed;
    final picked = await showMenu<List<String>>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: [me.id], child: Text(l10n.byItemOnlyMe)),
        PopupMenuItem(value: defaultItemMembers(_groupOrder), child: Text(l10n.byItemEveryone)),
      ],
    );
    if (picked != null) onMembersChanged(picked);
  }
}
