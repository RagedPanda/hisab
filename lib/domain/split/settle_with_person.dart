/// "Settle everything with one person": what I owe or am owed by one person,
/// in one group or across every group they are in, and the payments that
/// bring it to zero. Pure.
///
/// The same person in two groups is two member rows; they are matched by
/// email, the id the People list uses (see `domain/people/people.dart`). A
/// member without an email is only ever themselves.
///
/// Within a group the amount is what the Settle up list shows between me and
/// them (simplified or direct debts, per the group's setting), so the sheet
/// never disagrees with the list it is opened from.
library;

import '../people/people.dart';
import 'debt_simplifier.dart';

/// One group as settling with a person needs it.
typedef PersonSettleGroup = ({
  String groupId,

  /// The currency symbol the group's amounts are in; groups with different
  /// symbols are never netted together.
  String symbol,

  /// My member id here; null when I am not in the group.
  String? myMemberId,

  /// Current members' emails (null when they have none), by member id.
  Map<String, String?> emailByMemberId,

  /// The group's Settle up transfers.
  List<Transfer> suggested,
});

/// My balance with the person in one group: positive, they owe me.
class PersonGroupShare {
  const PersonGroupShare({required this.groupId, required this.symbol, required this.myMemberId, required this.theirMemberId, required this.netMinor});
  final String groupId;
  final String symbol;
  final String myMemberId;
  final String theirMemberId;

  /// Positive: they owe me. Negative: I owe them. Never zero in a plan.
  final int netMinor;

  /// The payment that squares this group: they pay me, or I pay them.
  Transfer get settlement => netMinor > 0 ? Transfer(theirMemberId, myMemberId, netMinor) : Transfer(myMemberId, theirMemberId, -netMinor);

  @override
  bool operator ==(Object other) =>
      other is PersonGroupShare &&
      other.groupId == groupId &&
      other.symbol == symbol &&
      other.myMemberId == myMemberId &&
      other.theirMemberId == theirMemberId &&
      other.netMinor == netMinor;

  @override
  int get hashCode => Object.hash(groupId, symbol, myMemberId, theirMemberId, netMinor);

  @override
  String toString() => '$groupId:$theirMemberId:$netMinor$symbol';
}

/// What [them] owes [me] in [transfers], less what I owe them.
int pairNet(Iterable<Transfer> transfers, {required String me, required String them}) => transfers.fold(0, (sum, transfer) {
      if (transfer.from == them && transfer.to == me) return sum + transfer.amountMinor;
      if (transfer.from == me && transfer.to == them) return sum - transfer.amountMinor;
      return sum;
    });

/// The member of [group] who is the same person as [email]; null when there
/// is none, or when that member is me.
String? _memberWithEmail(PersonSettleGroup group, String email) {
  for (final MapEntry(key: memberId, value: memberEmail) in group.emailByMemberId.entries) {
    if (memberId != group.myMemberId && normaliseEmail(memberEmail) == email) return memberId;
  }
  return null;
}

/// My non-zero balances with member [memberId] of [groupId]: just that group,
/// or with [allGroups] every group the same person is in (matched by email),
/// that group first and the rest in [groups] order. Groups where I am not a
/// member, or where we are square, are left out.
List<PersonGroupShare> personShares(List<PersonSettleGroup> groups, {required String groupId, required String memberId, bool allGroups = false}) {
  final home = groups.where((group) => group.groupId == groupId).firstOrNull;
  if (home == null) return const [];
  final email = normaliseEmail(home.emailByMemberId[memberId]);
  final others = allGroups && email != null ? groups.where((group) => group.groupId != groupId) : const <PersonSettleGroup>[];
  return [
    for (final (group, them) in [(home, memberId), for (final group in others) (group, _memberWithEmail(group, email!))])
      if (group.myMemberId case final me? when them != null && them != me)
        if (pairNet(group.suggested, me: me, them: them) case final net when net != 0)
          PersonGroupShare(groupId: group.groupId, symbol: group.symbol, myMemberId: me, theirMemberId: them, netMinor: net),
  ];
}

/// Whether "All groups" would add anything to "This group": the same person
/// has a non-zero balance with me in another group.
bool hasBalancesInOtherGroups(List<PersonSettleGroup> groups, {required String groupId, required String memberId}) =>
    personShares(groups, groupId: groupId, memberId: memberId, allGroups: true).any((share) => share.groupId != groupId);

/// Whether [memberId] still pays or is paid by someone in [groupId]'s Settle
/// up list. When I am square with them but this is true, their balance is
/// with others (often routed there by simplified debts), not with me.
bool settlesWithOthersIn(List<PersonSettleGroup> groups, {required String groupId, required String memberId}) =>
    groups.where((group) => group.groupId == groupId).any((group) => group.suggested.any((transfer) => transfer.from == memberId || transfer.to == memberId));

/// One currency's total of [shares]: positive, they owe me.
typedef PersonTotal = ({String symbol, int netMinor});

/// Totals of [shares] per currency symbol, in the order each symbol first
/// appears. Different currencies are never added together. A total can be
/// zero when groups cancel out; it is kept so the sheet can say so.
List<PersonTotal> personTotals(Iterable<PersonGroupShare> shares) {
  final bySymbol = <String, int>{};
  for (final share in shares) {
    bySymbol.update(share.symbol, (sum) => sum + share.netMinor, ifAbsent: () => share.netMinor);
  }
  return [for (final MapEntry(key: symbol, value: net) in bySymbol.entries) (symbol: symbol, netMinor: net)];
}

/// The single amount I pay the person when everything is in one currency and
/// I owe overall (what a UPI payment should be for), else null.
int? singleCurrencyAmountIOwe(Iterable<PersonGroupShare> shares) {
  final totals = personTotals(shares);
  if (totals.length != 1 || totals.single.netMinor >= 0) return null;
  return -totals.single.netMinor;
}
