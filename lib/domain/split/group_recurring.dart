/// Recurring group expenses (rent, maid, wifi): the split a rule remembers
/// and the occurrence it posts on each due date. Pure functions; the
/// schedule itself comes from `lib/domain/recurring/recurrence.dart`.
library;

import 'dart:convert';

import 'payers.dart';
import 'split_calculator.dart';

/// The raw input stored beside a split amount (`Splits.shareValue`): the
/// typed amount for exact and adjustment splits, the weight otherwise.
double? shareValueFor(SplitMethod method, SplitInput? input) {
  if (input == null) return null;
  return method == SplitMethod.exact || method == SplitMethod.adjustment ? input.amountMinor.toDouble() : input.weight;
}

/// How a recurring group expense is split and paid, as saved from the editor.
class GroupExpenseTemplate {
  const GroupExpenseTemplate({
    required this.method,
    required this.inputs,
    required this.paidByMemberId,
    this.payers = const [],
  });

  final SplitMethod method;
  final List<SplitInput> inputs;

  /// The single payer, or the main payer when [payers] has several rows.
  final String paidByMemberId;

  /// Several payers' amounts; empty for a single payer.
  final List<SplitShare> payers;

  Map<String, Object?> toJson() => {
        'method': method.name,
        'paidBy': paidByMemberId,
        'inputs': [
          for (final input in inputs)
            {'member': input.memberId, 'included': input.included, 'amount': input.amountMinor, 'weight': input.weight},
        ],
        'payers': [
          for (final payer in payers) {'member': payer.memberId, 'amount': payer.amountMinor},
        ],
      };

  String encode() => jsonEncode(toJson());

  /// Null when [raw] is missing or not a template this version understands.
  static GroupExpenseTemplate? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final method = SplitMethod.values.where((value) => value.name == json['method']).firstOrNull;
      final paidBy = json['paidBy'];
      if (method == null || paidBy is! String) return null;
      return GroupExpenseTemplate(
        method: method,
        paidByMemberId: paidBy,
        inputs: [
          for (final input in (json['inputs'] as List? ?? const []).cast<Map<String, dynamic>>())
            SplitInput(
              memberId: input['member'] as String,
              included: input['included'] as bool? ?? true,
              amountMinor: (input['amount'] as num?)?.toInt() ?? 0,
              weight: (input['weight'] as num?)?.toDouble() ?? 0,
            ),
        ],
        payers: [
          for (final payer in (json['payers'] as List? ?? const []).cast<Map<String, dynamic>>())
            SplitShare(payer['member'] as String, (payer['amount'] as num).toInt()),
        ],
      );
    } on Object {
      return null;
    }
  }
}

/// One member's share of a posted occurrence, with the raw input kept.
class OccurrenceSplit {
  const OccurrenceSplit({required this.memberId, required this.amountMinor, this.shareValue});
  final String memberId;
  final int amountMinor;
  final double? shareValue;

  @override
  bool operator ==(Object other) =>
      other is OccurrenceSplit && other.memberId == memberId && other.amountMinor == amountMinor && other.shareValue == shareValue;

  @override
  int get hashCode => Object.hash(memberId, amountMinor, shareValue);

  @override
  String toString() => '$memberId:$amountMinor';
}

/// Why an occurrence could not be posted as remembered.
enum GroupOccurrenceProblem {
  /// A payer has left the group since the rule was saved.
  payerLeft,

  /// The remembered split no longer works out (e.g. an exact share belonged
  /// to someone who left, so the amounts no longer add up).
  splitInvalid,
}

/// The splits and payers one occurrence posts, or the [problem] that stops it.
class GroupOccurrence {
  const GroupOccurrence({required this.splits, required this.payers, required this.paidByMemberId}) : problem = null;
  const GroupOccurrence.blocked(GroupOccurrenceProblem this.problem)
      : splits = const [],
        payers = const [],
        paidByMemberId = null;

  final List<OccurrenceSplit> splits;

  /// Several-payer rows; empty for a single payer.
  final List<SplitShare> payers;
  final String? paidByMemberId;
  final GroupOccurrenceProblem? problem;

  bool get canPost => problem == null;
}

/// The occurrence a rule posts for an expense of [amountMinor], given who
/// is still in the group. Members who left are dropped from the split, so an
/// equal or shares split is spread over whoever remains; a payer who left
/// blocks the occurrence rather than guessing who paid.
GroupOccurrence groupOccurrence(GroupExpenseTemplate template, {required int amountMinor, required Set<String> activeMemberIds}) {
  final payers = template.payers.length > 1 ? template.payers : const <SplitShare>[];
  final payerIds = payers.isEmpty ? {template.paidByMemberId} : {for (final payer in payers) payer.memberId};
  if (!activeMemberIds.containsAll(payerIds)) return const GroupOccurrence.blocked(GroupOccurrenceProblem.payerLeft);
  if (payers.isNotEmpty && unassignedMinor(amountMinor, payers) != 0) return const GroupOccurrence.blocked(GroupOccurrenceProblem.splitInvalid);
  final inputs = [for (final input in template.inputs) if (activeMemberIds.contains(input.memberId)) input];
  final outcome = computeSplit(totalMinor: amountMinor, method: template.method, inputs: inputs);
  if (!outcome.isValid || outcome.shares.isEmpty) return const GroupOccurrence.blocked(GroupOccurrenceProblem.splitInvalid);
  final inputByMember = {for (final input in inputs) input.memberId: input};
  return GroupOccurrence(
    paidByMemberId: payers.isEmpty ? template.paidByMemberId : primaryPayerId(payers),
    payers: payers,
    splits: [
      for (final share in outcome.shares)
        OccurrenceSplit(memberId: share.memberId, amountMinor: share.amountMinor, shareValue: shareValueFor(template.method, inputByMember[share.memberId])),
    ],
  );
}

/// Whether [template] still splits [amountMinor] with everyone it names:
/// exact amounts and several payers' shares are tied to the old total.
bool templateFitsAmount(GroupExpenseTemplate template, int amountMinor) => groupOccurrence(
      template,
      amountMinor: amountMinor,
      activeMemberIds: {template.paidByMemberId, for (final input in template.inputs) input.memberId, for (final payer in template.payers) payer.memberId},
    ).canPost;

/// Group rules post shared expenses only; income and transfers have no split.
bool isGroupRuleKind(String kind) => kind == 'expense';

/// My share of the next occurrence of a group rule, or null when I am not
/// in its split, it cannot post (see [groupOccurrence]) or nothing is stored.
int? myShareOfGroupRule(String? groupSplit, {required int amountMinor, required Set<String> activeMemberIds, required String? myMemberId}) {
  final template = GroupExpenseTemplate.decode(groupSplit);
  if (template == null || myMemberId == null) return null;
  final occurrence = groupOccurrence(template, amountMinor: amountMinor, activeMemberIds: activeMemberIds);
  return occurrence.splits.where((split) => split.memberId == myMemberId).firstOrNull?.amountMinor;
}
