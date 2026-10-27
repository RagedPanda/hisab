/// The account editor's balance field takes a plain amount (no minus sign on
/// a number pad) plus a direction, so a stored balance keeps its meaning:
/// money owed or overdrawn is negative, money held or card credit positive.
library;

/// The direction a new account starts with: a card's amount is money owed.
bool defaultBalanceNegative(String accountType) => accountType == 'card';

/// The amount shown in the balance field for a stored [balanceMinor].
int balanceInputMinor(int balanceMinor) => balanceMinor.abs();

/// The stored balance for an entered amount and direction.
int signedBalanceFromInput({required int enteredMinor, required bool negative}) => negative ? -enteredMinor.abs() : enteredMinor.abs();

/// The direction after the account type changes: an entered amount keeps
/// its meaning (a card's ₹500 owed becomes a bank's -₹500, card credit
/// becomes money in the account); with nothing entered yet the new type's
/// default applies.
bool balanceNegativeAfterTypeChange({required bool negative, required int enteredMinor, required String toType}) =>
    enteredMinor == 0 ? defaultBalanceNegative(toType) : negative;
