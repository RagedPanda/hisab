import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/recurring/repeat_draft.dart';

/// One row of the Recurring screen: the rule, its section and, for a
/// confirm-first rule, how many occurrences are waiting.
class RecurringListItem {
  const RecurringListItem({required this.view, required this.section, this.waiting = 0});
  final RecurringRuleView view;
  final RecurringSection section;
  final int waiting;
}

/// Rules grouped waiting, active, paused, ended; soonest first within each.
List<RecurringListItem> recurringListItems(List<RecurringRuleView> views, {required DateTime now, int monthStartDay = 1}) {
  final items = [
    for (final view in views)
      () {
        final rule = view.rule;
        final section = sectionOf(status: rule.status, autoPost: rule.autoPost, nextDue: rule.nextDue, now: now);
        final waiting = section == RecurringSection.waiting
            ? waitingCount(specOf(rule), nextDue: rule.nextDue!, now: now, postedCount: rule.postedCount, monthStartDay: monthStartDay)
            : 0;
        return RecurringListItem(view: view, section: section, waiting: waiting);
      }(),
  ];
  int byDue(RecurringListItem item) => item.view.rule.nextDue?.millisecondsSinceEpoch ?? item.view.rule.updatedAt.millisecondsSinceEpoch;
  items.sort((first, second) {
    final bySection = first.section.index.compareTo(second.section.index);
    if (bySection != 0) return bySection;
    final ended = first.section == RecurringSection.ended;
    return ended ? byDue(second).compareTo(byDue(first)) : byDue(first).compareTo(byDue(second));
  });
  return items;
}

/// Occurrences waiting for a confirm across every rule.
int totalWaiting(List<RecurringListItem> items) => items.fold(0, (sum, item) => sum + item.waiting);

/// The time of the last recurring catch-up. The list watches it so that
/// confirm-first occurrences falling due at midnight or by resume show up
/// without a restart, even when the catch-up itself writes nothing.
class RecurringLastCatchUpNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void set(DateTime now) => state = now;
}

final recurringLastCatchUpProvider = NotifierProvider<RecurringLastCatchUpNotifier, DateTime>(RecurringLastCatchUpNotifier.new);

final recurringListProvider = Provider<AsyncValue<List<RecurringListItem>>>((ref) {
  final monthStartDay = ref.watch(settingsProvider).monthStartDay;
  ref.watch(recurringLastCatchUpProvider);
  return ref.watch(recurringViewsProvider).whenData((views) => recurringListItems(views, now: DateTime.now(), monthStartDay: monthStartDay));
});

final recurringWaitingCountProvider = Provider<int>((ref) => totalWaiting(ref.watch(recurringListProvider).value ?? const []));
