/// Pure rules behind the group settings page: group types, the default split
/// for new expenses, member weights and the currency label.
library;

import 'split_calculator.dart';

/// What a group is for. Stored by [name] in `Groups.type`.
enum GroupType {
  trip,
  home,
  couple,
  other;

  /// Unknown or missing values read as [other].
  static GroupType parse(String? value) => GroupType.values.firstWhere((type) => type.name == value, orElse: () => GroupType.other);

  /// Icon a group of this type starts with.
  String get defaultIcon => switch (this) {
        GroupType.trip => 'flight',
        GroupType.home => 'home',
        GroupType.couple => 'favorite',
        GroupType.other => 'groups',
      };
}

/// Icons that mean "no deliberate choice yet": the table default and the
/// first icon of the new-group form.
const _genericIcons = {'group', 'groups'};

/// The icon after switching from [previous] to [next]: follows the new type's
/// default unless the user picked an icon of their own.
String iconAfterTypeChange({required String currentIcon, required GroupType previous, required GroupType next}) {
  final untouched = currentIcon == previous.defaultIcon || _genericIcons.contains(currentIcon);
  return untouched ? next.defaultIcon : currentIcon;
}

/// Split methods a group can pre-select for new expenses.
const groupDefaultSplitMethods = [SplitMethod.equal, SplitMethod.shares, SplitMethod.percent];

/// The stored default split, falling back to equal for anything else.
SplitMethod parseDefaultSplitMethod(String? value) =>
    groupDefaultSplitMethods.firstWhere((method) => method.name == value, orElse: () => SplitMethod.equal);

/// Member weight step, floor and ceiling for the Shares stepper.
const memberWeightStep = 0.5;
const minMemberWeight = 0.5;
const maxMemberWeight = 10.0;

/// [weight] moved by [steps] stepper taps, kept inside the allowed range.
double steppedWeight(double weight, int steps) => (weight + steps * memberWeightStep).clamp(minMemberWeight, maxMemberWeight).toDouble();

/// A currency a group can label its amounts with.
typedef GroupCurrency = ({String code, String symbol});

/// Common currencies offered in group settings; anything else can be typed.
const groupCurrencies = <GroupCurrency>[
  (code: 'INR', symbol: '₹'),
  (code: 'USD', symbol: r'$'),
  (code: 'EUR', symbol: '€'),
  (code: 'GBP', symbol: '£'),
  (code: 'AED', symbol: 'AED'),
  (code: 'SGD', symbol: r'S$'),
  (code: 'THB', symbol: '฿'),
  (code: 'JPY', symbol: '¥'),
];

/// The symbol a group's amounts are shown with: its own label, or the app's.
String groupSymbol({required String? currencyLabel, required String appSymbol}) {
  final label = currencyLabel?.trim() ?? '';
  return label.isEmpty ? appSymbol : label;
}

/// Whether a group's amounts can be added to totals kept in the app currency.
bool sharesAppCurrency({required String? currencyLabel, required String appSymbol}) =>
    groupSymbol(currencyLabel: currencyLabel, appSymbol: appSymbol) == appSymbol;

/// The ISO code stored with a label, so a later multi-currency feature knows
/// what was meant; a typed label keeps [fallbackCode].
String currencyCodeFor(String? label, {required String fallbackCode}) =>
    groupCurrencies.where((currency) => currency.symbol == label).firstOrNull?.code ?? fallbackCode;
