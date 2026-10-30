/// Udhaar: money lent to or borrowed from one person outside any group.
///
/// Each udhaar entry is a one-sided transfer with a person: money that left
/// one of my accounts (I lent, or I repaid) or came into one (I borrowed, or
/// they repaid). It is never spending or income, so Home totals skip it, but
/// it moves the account's balance like any transfer.
///
/// A person's balance is positive when they owe me and negative when I owe
/// them. Pure: no I/O.
library;

enum UdhaarKind {
  /// I gave them money: they owe me more.
  lent('lent'),

  /// They gave me money: I owe them more.
  borrowed('borrowed'),

  /// They paid me back: they owe me less.
  repaidToMe('repaid_to_me'),

  /// I paid them back: I owe them less.
  repaidByMe('repaid_by_me');

  const UdhaarKind(this.storageKey);

  /// The value stored in `entries.udhaar_kind`.
  final String storageKey;

  /// The kind stored as [key], or null for a non-udhaar entry.
  static UdhaarKind? parse(String? key) => values.where((kind) => kind.storageKey == key).firstOrNull;

  /// Whether money left my account (lent, or I repaid).
  bool get isMoneyOut => this == lent || this == repaidByMe;

  /// How [amountMinor] of this kind changes what the person owes me.
  int balanceEffect(int amountMinor) => isMoneyOut ? amountMinor : -amountMinor;
}

/// The from and to accounts of the transfer that stores an udhaar entry of
/// [kind] on [accountId]: money out leaves from it, money in arrives in it.
({String? from, String? to}) udhaarAccounts(UdhaarKind kind, String? accountId) =>
    kind.isMoneyOut ? (from: accountId, to: null) : (from: null, to: accountId);

/// The one account an udhaar entry stored with [from] and [to] touches.
String? udhaarAccountOf({required String? from, required String? to}) => from ?? to;

/// One udhaar entry reduced to what balances need.
typedef UdhaarLine = ({String personId, UdhaarKind kind, int amountMinor, DateTime occurredAt});

/// What [personId] owes me (positive) or I owe them (negative).
int udhaarBalance(Iterable<UdhaarLine> lines, String personId) =>
    lines.where((line) => line.personId == personId).fold(0, (sum, line) => sum + line.kind.balanceEffect(line.amountMinor));

/// Person id -> balance, for everyone with at least one udhaar entry.
Map<String, int> udhaarBalances(Iterable<UdhaarLine> lines) {
  final balances = <String, int>{};
  for (final line in lines) {
    balances.update(line.personId, (sum) => sum + line.kind.balanceEffect(line.amountMinor), ifAbsent: () => line.kind.balanceEffect(line.amountMinor));
  }
  return balances;
}

/// The person ids with a non-zero balance, largest amount either way first,
/// then by id so the order is stable.
List<String> outstandingPeople(Map<String, int> balances) => [
      for (final entry in balances.entries)
        if (entry.value != 0) entry.key,
    ]..sort((left, right) {
        final bySize = balances[right]!.abs().compareTo(balances[left]!.abs());
        return bySize != 0 ? bySize : left.compareTo(right);
      });

/// What everyone owes me and what I owe everyone, both as positive amounts.
({int owedToMe, int iOwe}) udhaarTotals(Map<String, int> balances) {
  var owedToMe = 0;
  var iOwe = 0;
  for (final balance in balances.values) {
    if (balance > 0) owedToMe += balance;
    if (balance < 0) iOwe -= balance;
  }
  return (owedToMe: owedToMe, iOwe: iOwe);
}

/// The day the person's current balance started: the date of the entry that
/// last took it from settled (or the other side) to where it is now. Null
/// when the balance is zero.
DateTime? outstandingSince(Iterable<UdhaarLine> personLines) {
  final ordered = personLines.toList()..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
  var balance = 0;
  DateTime? since;
  for (final line in ordered) {
    final next = balance + line.kind.balanceEffect(line.amountMinor);
    if (next != 0 && next.sign != balance.sign) since = line.occurredAt;
    balance = next;
  }
  return balance == 0 ? null : since;
}

/// The repayment that settles a [balance]: they repay a positive one, I
/// repay a negative one. Null when nothing is owed.
UdhaarKind? repaymentKindFor(int balance) => balance > 0
    ? UdhaarKind.repaidToMe
    : balance < 0
        ? UdhaarKind.repaidByMe
        : null;

/// The balance after each of one person's [newestFirst] lines, for a
/// timeline: the first is the balance now, each next one undoes the line
/// above it.
List<int> balancesAfter(List<UdhaarLine> newestFirst) {
  var balance = newestFirst.fold(0, (sum, line) => sum + line.kind.balanceEffect(line.amountMinor));
  final after = <int>[];
  for (final line in newestFirst) {
    after.add(balance);
    balance -= line.kind.balanceEffect(line.amountMinor);
  }
  return after;
}
