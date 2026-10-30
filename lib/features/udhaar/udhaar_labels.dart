import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/udhaar/udhaar.dart';
import '../../l10n/l10n.dart';

/// The short name of [kind] on the form's choice chips.
String udhaarKindLabel(AppLocalizations l10n, UdhaarKind kind) => switch (kind) {
      UdhaarKind.lent => l10n.udhaarKindLent,
      UdhaarKind.borrowed => l10n.udhaarKindBorrowed,
      UdhaarKind.repaidToMe => l10n.udhaarKindRepaidToMe,
      UdhaarKind.repaidByMe => l10n.udhaarKindRepaidByMe,
    };

/// An udhaar entry as a sentence about [name]: "Lent to Rahul".
String udhaarEntryTitle(AppLocalizations l10n, UdhaarKind kind, String name) => switch (kind) {
      UdhaarKind.lent => l10n.udhaarLentTo(name),
      UdhaarKind.borrowed => l10n.udhaarBorrowedFrom(name),
      UdhaarKind.repaidToMe => l10n.udhaarRepaidByThem(name),
      UdhaarKind.repaidByMe => l10n.udhaarRepaidByMe(name),
    };

/// "Rahul owes you ₹2,500", "You owe Rahul ₹800" or "All settled with Rahul".
String udhaarBalanceSentence(AppLocalizations l10n, {required String name, required int balance, required MoneyFormat format}) {
  final amount = formatMinor(balance.abs(), format: format);
  if (balance > 0) return l10n.udhaarOwesYou(name, amount);
  if (balance < 0) return l10n.udhaarYouOwe(name, amount);
  return l10n.udhaarSettledWith(name);
}

/// Green when they owe me, red when I owe them, plain when settled.
Color? udhaarBalanceColor(int balance) => balance > 0
    ? kIncomeColor
    : balance < 0
        ? kExpenseColor
        : null;

/// The icon of an udhaar entry: money going out or coming in.
IconData udhaarKindIcon(UdhaarKind kind) => kind.isMoneyOut ? Icons.north_east : Icons.south_west;
