import 'dart:convert';

/// What happened to an expense or payment in a group's activity log.
enum ActivityAction { added, edited, deleted, restored }

/// What a log row is about.
enum ActivitySubject { expense, payment }

ActivityAction activityActionFrom(String name) => ActivityAction.values.firstWhere((action) => action.name == name, orElse: () => ActivityAction.edited);

ActivitySubject activitySubjectFrom(String name) => ActivitySubject.values.firstWhere((subject) => subject.name == name, orElse: () => ActivitySubject.expense);

/// One member's part of an expense: a payer row or a split row. [rowId] is
/// the database row, kept so a deleted expense can be restored exactly.
class MemberAmount {
  const MemberAmount({required this.memberId, required this.amountMinor, this.rowId});
  final String memberId;
  final int amountMinor;
  final String? rowId;

  Map<String, Object?> toJson() => {'memberId': memberId, 'amountMinor': amountMinor, if (rowId != null) 'rowId': rowId};

  static MemberAmount fromJson(Map<String, Object?> json) =>
      MemberAmount(memberId: json['memberId']! as String, amountMinor: (json['amountMinor']! as num).toInt(), rowId: json['rowId'] as String?);
}

/// The state of an expense or payment at one moment, stored as JSON in the
/// log so history reads the same even after later edits.
sealed class ActivitySnapshot {
  const ActivitySnapshot();

  Map<String, Object?> toJson();

  String encode() => jsonEncode(toJson());

  /// Null for null or unreadable text, so one bad row never breaks the feed.
  static ActivitySnapshot? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final json = Map<String, Object?>.from(jsonDecode(text) as Map);
      return switch (json['type']) {
        'expense' => ExpenseSnapshot.fromJson(json),
        'payment' => PaymentSnapshot.fromJson(json),
        _ => null,
      };
    } on Object {
      return null;
    }
  }
}

class ExpenseSnapshot extends ActivitySnapshot {
  const ExpenseSnapshot({
    required this.amountMinor,
    required this.occurredAt,
    this.note = '',
    this.payee,
    this.categoryId,
    required this.payers,
    required this.shares,
    this.splitMethod,
  });
  final int amountMinor;
  final DateTime occurredAt;
  final String note;
  final String? payee;
  final String? categoryId;

  /// Everyone who paid, with what they paid (one row for a single payer).
  final List<MemberAmount> payers;
  final List<MemberAmount> shares;
  final String? splitMethod;

  @override
  Map<String, Object?> toJson() => {
        'type': 'expense',
        'amountMinor': amountMinor,
        'occurredAt': occurredAt.toIso8601String(),
        'note': note,
        'payee': payee,
        'categoryId': categoryId,
        'payers': [for (final payer in payers) payer.toJson()],
        'shares': [for (final share in shares) share.toJson()],
        'splitMethod': splitMethod,
      };

  static ExpenseSnapshot fromJson(Map<String, Object?> json) => ExpenseSnapshot(
        amountMinor: (json['amountMinor']! as num).toInt(),
        occurredAt: DateTime.parse(json['occurredAt']! as String),
        note: json['note'] as String? ?? '',
        payee: json['payee'] as String?,
        categoryId: json['categoryId'] as String?,
        payers: _memberAmounts(json['payers']),
        shares: _memberAmounts(json['shares']),
        splitMethod: json['splitMethod'] as String?,
      );
}

class PaymentSnapshot extends ActivitySnapshot {
  const PaymentSnapshot({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountMinor,
    required this.occurredAt,
    this.method = 'cash',
    this.note = '',
  });
  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;
  final DateTime occurredAt;
  final String method;
  final String note;

  @override
  Map<String, Object?> toJson() => {
        'type': 'payment',
        'fromMemberId': fromMemberId,
        'toMemberId': toMemberId,
        'amountMinor': amountMinor,
        'occurredAt': occurredAt.toIso8601String(),
        'method': method,
        'note': note,
      };

  static PaymentSnapshot fromJson(Map<String, Object?> json) => PaymentSnapshot(
        fromMemberId: json['fromMemberId']! as String,
        toMemberId: json['toMemberId']! as String,
        amountMinor: (json['amountMinor']! as num).toInt(),
        occurredAt: DateTime.parse(json['occurredAt']! as String),
        method: json['method'] as String? ?? 'cash',
        note: json['note'] as String? ?? '',
      );
}

List<MemberAmount> _memberAmounts(Object? raw) => [
      for (final item in (raw as List?) ?? const []) MemberAmount.fromJson(Map<String, Object?>.from(item as Map)),
    ];

/// One difference between two snapshots of the same expense or payment.
sealed class ActivityChange {
  const ActivityChange();
}

class AmountChange extends ActivityChange {
  const AmountChange(this.fromMinor, this.toMinor);
  final int fromMinor;
  final int toMinor;
}

class DateChange extends ActivityChange {
  const DateChange(this.from, this.to);
  final DateTime from;
  final DateTime to;
}

/// The expense description: its note, else its payee.
class DescriptionChange extends ActivityChange {
  const DescriptionChange(this.from, this.to);
  final String from;
  final String to;
}

class CategoryChange extends ActivityChange {
  const CategoryChange(this.fromId, this.toId);
  final String? fromId;
  final String? toId;
}

class PayersChange extends ActivityChange {
  const PayersChange(this.fromMemberIds, this.toMemberIds);
  final List<String> fromMemberIds;
  final List<String> toMemberIds;
}

/// One member's share of an expense; 0 means not in the split.
class ShareChange extends ActivityChange {
  const ShareChange(this.memberId, this.fromMinor, this.toMinor);
  final String memberId;
  final int fromMinor;
  final int toMinor;
}

/// Who paid whom in a payment.
class PartiesChange extends ActivityChange {
  const PartiesChange({required this.fromBefore, required this.toBefore, required this.fromAfter, required this.toAfter});
  final String fromBefore;
  final String toBefore;
  final String fromAfter;
  final String toAfter;
}

class MethodChange extends ActivityChange {
  const MethodChange(this.from, this.to);
  final String from;
  final String to;
}

class NoteChange extends ActivityChange {
  const NoteChange(this.from, this.to);
  final String from;
  final String to;
}

/// The description an expense row shows: its note, else its payee, else ''.
String expenseDescription(ExpenseSnapshot expense) => expense.note.isNotEmpty ? expense.note : (expense.payee ?? '');

/// Every user-visible difference between [before] and [after], in display
/// order. Empty when nothing changed or the two are different kinds.
List<ActivityChange> diffSnapshots(ActivitySnapshot before, ActivitySnapshot after) => switch ((before, after)) {
      (final ExpenseSnapshot from, final ExpenseSnapshot to) => _diffExpenses(from, to),
      (final PaymentSnapshot from, final PaymentSnapshot to) => _diffPayments(from, to),
      _ => const [],
    };

List<ActivityChange> _diffExpenses(ExpenseSnapshot before, ExpenseSnapshot after) {
  final payersBefore = _sortedMemberIds(before.payers);
  final payersAfter = _sortedMemberIds(after.payers);
  return [
    if (expenseDescription(before) != expenseDescription(after)) DescriptionChange(expenseDescription(before), expenseDescription(after)),
    if (before.amountMinor != after.amountMinor) AmountChange(before.amountMinor, after.amountMinor),
    if (!_sameDay(before.occurredAt, after.occurredAt)) DateChange(before.occurredAt, after.occurredAt),
    if (before.categoryId != after.categoryId) CategoryChange(before.categoryId, after.categoryId),
    if (!_sameList(payersBefore, payersAfter)) PayersChange(payersBefore, payersAfter),
    ..._shareChanges(before.shares, after.shares),
  ];
}

List<ActivityChange> _diffPayments(PaymentSnapshot before, PaymentSnapshot after) => [
      if (before.fromMemberId != after.fromMemberId || before.toMemberId != after.toMemberId)
        PartiesChange(fromBefore: before.fromMemberId, toBefore: before.toMemberId, fromAfter: after.fromMemberId, toAfter: after.toMemberId),
      if (before.amountMinor != after.amountMinor) AmountChange(before.amountMinor, after.amountMinor),
      if (!_sameDay(before.occurredAt, after.occurredAt)) DateChange(before.occurredAt, after.occurredAt),
      if (before.method != after.method) MethodChange(before.method, after.method),
      if (before.note != after.note) NoteChange(before.note, after.note),
    ];

/// Members whose share moved, in the order they first appear (before, then
/// newcomers).
List<ShareChange> _shareChanges(List<MemberAmount> before, List<MemberAmount> after) {
  final beforeById = _totalsByMember(before);
  final afterById = _totalsByMember(after);
  final memberIds = {...beforeById.keys, ...afterById.keys};
  return [
    for (final memberId in memberIds)
      if ((beforeById[memberId] ?? 0) != (afterById[memberId] ?? 0)) ShareChange(memberId, beforeById[memberId] ?? 0, afterById[memberId] ?? 0),
  ];
}

Map<String, int> _totalsByMember(List<MemberAmount> amounts) {
  final totals = <String, int>{};
  for (final amount in amounts) {
    totals[amount.memberId] = (totals[amount.memberId] ?? 0) + amount.amountMinor;
  }
  return totals;
}

List<String> _sortedMemberIds(List<MemberAmount> amounts) => ({for (final amount in amounts) amount.memberId}.toList()..sort());

bool _sameList(List<String> first, List<String> second) => first.length == second.length && first.indexed.every((pair) => second[pair.$1] == pair.$2);

bool _sameDay(DateTime first, DateTime second) => first.year == second.year && first.month == second.month && first.day == second.day;

/// A log row as the feed needs it, already decoded.
class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.groupId,
    required this.action,
    required this.subject,
    required this.subjectId,
    required this.actorMemberId,
    required this.occurredAt,
    this.before,
    this.after,
  });
  final String id;
  final String groupId;
  final ActivityAction action;
  final ActivitySubject subject;
  final String subjectId;
  final String? actorMemberId;
  final DateTime occurredAt;
  final ActivitySnapshot? before;
  final ActivitySnapshot? after;

  /// The state the row talks about: the new state, or the old one for a delete.
  ActivitySnapshot? get latest => after ?? before;

  List<ActivityChange> get changes => before != null && after != null ? diffSnapshots(before!, after!) : const [];
}

/// Ids of the log rows that should offer Restore: the latest deletion of each
/// expense that is still deleted. Older deletions (later undone and deleted
/// again) and payments never do; payments are restored through Undo only.
Set<String> restorableActivityIds(List<ActivityRecord> activities, {required Set<String> deletedExpenseIds}) {
  final latestDeletion = <String, ActivityRecord>{};
  for (final activity in activities) {
    if (activity.subject != ActivitySubject.expense || activity.action != ActivityAction.deleted) continue;
    if (!deletedExpenseIds.contains(activity.subjectId)) continue;
    final current = latestDeletion[activity.subjectId];
    if (current == null || activity.occurredAt.isAfter(current.occurredAt)) latestDeletion[activity.subjectId] = activity;
  }
  return {for (final activity in latestDeletion.values) activity.id};
}

/// Whether an edit is worth a log row: true unless nothing visible changed.
bool isMeaningfulEdit(ActivitySnapshot before, ActivitySnapshot after) => diffSnapshots(before, after).isNotEmpty;
