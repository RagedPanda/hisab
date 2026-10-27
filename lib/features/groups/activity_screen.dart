import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/split/group_activity.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'activity_messages.dart';
import 'member_display.dart';

/// The activity log of one group, or of every group when the id is null.
final activityFeedProvider = StreamProvider.family((ref, String? groupId) => ref.watch(groupsRepositoryProvider).watchActivityFeed(groupId: groupId));

/// Who added, edited, deleted or restored what, newest first, with Restore on
/// deleted expenses. [groupId] null shows every group, each row naming its group.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key, this.groupId});
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final feed = ref.watch(activityFeedProvider(groupId)).value;
    final groupName = groupId == null ? l10n.activityAllGroups : feed?.groupsById[groupId]?.name;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.activityTitle),
          if (groupName != null) Text(groupName, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
      body: feed == null
          ? const SizedBox.shrink()
          : feed.activities.isEmpty
              ? EmptyState(icon: Icons.history, title: l10n.activityEmptyTitle, message: l10n.activityEmptyBody)
              : _ActivityList(feed: feed, showGroup: groupId == null),
    );
  }
}

class _ActivityList extends ConsumerWidget {
  const _ActivityList({required this.feed, required this.showGroup});
  final ActivityFeed feed;
  final bool showGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final categoryById = {for (final category in categories) category.id: category};
    final myMemberIds = {for (final member in feed.membersById.values) if (member.isMe) member.id};
    final days = groupConsecutiveByDay(feed.activities, (activity) => activity.occurredAt);
    ActivityFormatters formatFor(ActivityRecord activity) => ActivityFormatters(
          nameOf: (id) => switch (feed.membersById[id]) { final member? => memberShortName(l10n, member), null => l10n.unknown },
          categoryNameOf: (id) => switch (categoryById[id]) { final category? => categoryDisplayName(category, locale), null => l10n.kindExpense },
          money: (minor) => formatMinor(minor, format: moneyFormat),
          date: (day) => formatRowDate(day, locale: locale.toString()),
          myMemberId: myMemberIds.where((id) => feed.membersById[id]?.groupId == activity.groupId).firstOrNull,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        for (final day in days) ...[
          SectionHeader(formatDayLabel(day.day, today: l10n.today, yesterday: l10n.yesterday, locale: locale.toString()), padding: const EdgeInsets.fromLTRB(4, 16, 4, 6)),
          Card(
            child: Column(children: [
              for (final activity in day.items)
                _ActivityTile(
                  activity: activity,
                  words: activityWords(l10n, activity, formatFor(activity)),
                  groupName: showGroup ? feed.groupsById[activity.groupId]?.name : null,
                  restorable: feed.restorableIds.contains(activity.id),
                  opensExpense: activity.subject == ActivitySubject.expense && !feed.deletedExpenseIds.contains(activity.subjectId),
                ),
            ]),
          ),
        ],
      ],
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  const _ActivityTile({required this.activity, required this.words, required this.groupName, required this.restorable, required this.opensExpense});
  final ActivityRecord activity;
  final bool opensExpense;
  final ActivityWords words;
  final String? groupName;
  final bool restorable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final meta = [?groupName, formatTime(activity.occurredAt, locale: Localizations.localeOf(context).toString())].join(' · ');
    return ListTile(
      key: ValueKey('activity-${activity.id}'),
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: Icon(_iconFor(activity)),
      ),
      title: Text(words.headline),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final line in words.details) Text(line, style: textTheme.bodySmall),
        Text(meta, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ]),
      isThreeLine: words.details.isNotEmpty,
      trailing: restorable ? TextButton(onPressed: () => _restore(context, ref), child: Text(l10n.activityRestore)) : null,
      onTap: opensExpense ? () => context.push('/entry?id=${activity.subjectId}') : null,
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    await ref.read(groupsRepositoryProvider).restoreDeleted(activity);
    final restored = switch (activity.subject) {
      ActivitySubject.expense => l10n.activityExpenseRestoredSnack,
      ActivitySubject.payment => l10n.activityPaymentRestoredSnack,
      ActivitySubject.group => l10n.activityGroupRestoredSnack,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(restored)));
  }

  static IconData _iconFor(ActivityRecord activity) => switch (activity.action) {
        ActivityAction.added => activity.subject == ActivitySubject.payment ? Icons.payments_outlined : Icons.add_circle_outline,
        ActivityAction.edited => Icons.edit_outlined,
        ActivityAction.deleted => Icons.delete_outline,
        ActivityAction.restored => Icons.restore,
      };
}
