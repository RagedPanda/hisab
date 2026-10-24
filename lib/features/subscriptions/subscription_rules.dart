import 'package:drift/drift.dart' show Value;

import '../../data/db/database.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/subscriptions/subscription_templates.dart';

/// What the subscription form collects, independent of whether the rule is
/// new or being edited.
class SubscriptionDraft {
  const SubscriptionDraft({
    required this.name,
    required this.amountMinor,
    required this.cycle,
    required this.startDate,
    this.categoryId,
    this.accountId,
    this.autoPost = true,
    this.dayOfMonth,
    this.weekday,
  });

  final String name;
  final int amountMinor;
  final SubscriptionCycle cycle;
  final DateTime startDate;
  final String? categoryId;
  final String? accountId;
  final bool autoPost;

  /// Schedule anchors (null means the start date's own day or weekday).
  final int? dayOfMonth;
  final int? weekday;
}

/// A new recurring expense rule flagged as a subscription. The name is also
/// the payee, so every posted charge carries it and Entries search finds it.
RecurringRulesCompanion newSubscriptionRule(SubscriptionDraft draft) => RecurringRepository.newRule(
      name: draft.name,
      payee: draft.name,
      kind: 'expense',
      amountMinor: draft.amountMinor,
      categoryId: draft.categoryId,
      accountId: draft.accountId,
      frequency: draft.cycle.frequency,
      interval: draft.cycle.interval,
      dayOfMonth: draft.dayOfMonth,
      weekday: draft.weekday,
      startDate: draft.startDate,
      autoPost: draft.autoPost,
      isSubscription: true,
    );

/// [existing] updated from [draft]. The next renewal becomes the new start,
/// so an edit never back-posts; a changed renewal day re-anchors the day of
/// month and weekday on the
/// draft's anchors. The payee follows the name.
RecurringRulesCompanion editedSubscriptionRule(RecurringRule existing, SubscriptionDraft draft, {required bool renewalDayChanged}) =>
    existing.toCompanion(true).copyWith(
          name: Value(draft.name),
          payee: Value(draft.name),
          amountMinor: Value(draft.amountMinor),
          categoryId: Value(draft.categoryId),
          accountId: Value(draft.accountId),
          frequency: Value(draft.cycle.frequency.name),
          interval: Value(draft.cycle.interval),
          startDate: Value(draft.startDate),
          dayOfMonth: renewalDayChanged ? Value(draft.dayOfMonth) : Value(existing.dayOfMonth),
          weekday: renewalDayChanged ? Value(draft.weekday) : Value(existing.weekday),
          autoPost: Value(draft.autoPost),
          isSubscription: const Value(true),
        );
