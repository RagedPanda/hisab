import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/split/split_this.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'group_form.dart';

/// Where "Split this" starts for saved personal expense [entryId]: the group
/// picker, or with [groupId] the group expense form prefilled from the entry.
/// Anything that can name an entry (the editor's menu, a notification
/// action) opens this location.
String splitThisLocation(String entryId, {String? groupId}) =>
    groupId == null ? '/split/$entryId' : '/entry?splitFrom=$entryId&group=$groupId';

/// "Split with which group?": lists the groups the entry can move into and
/// swaps itself for the prefilled group expense once one is picked.
class SplitThisScreen extends ConsumerWidget {
  const SplitThisScreen({super.key, required this.entryId});
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summaries = ref.watch(groupSummariesProvider);
    final groups = splitTargetGroups<GroupSummary>(
      summaries.value ?? const [],
      isArchived: (summary) => summary.group.archivedAt != null,
      includesMe: (summary) => summary.members.any((member) => member.isMe),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.splitThisPickGroup)),
      body: !summaries.hasValue
          ? const SizedBox.shrink()
          : groups.isEmpty
              ? EmptyState(
                  icon: Icons.groups_outlined,
                  title: l10n.noGroupsTitle,
                  message: l10n.noGroupsBody,
                  action: FilledButton.tonal(onPressed: () => showGroupForm(context, ref), child: Text(l10n.startGroup)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    for (final summary in groups)
                      Card(
                        child: ListTile(
                          key: ValueKey('splitThis.group.${summary.group.id}'),
                          leading: IconBadge(icon: summary.group.icon, color: 0xFF0D9488),
                          title: Text(summary.group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(l10n.memberCount(summary.members.length)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.pushReplacement(splitThisLocation(entryId, groupId: summary.group.id)),
                        ),
                      ),
                  ],
                ),
    );
  }
}
