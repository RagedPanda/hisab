import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/split/split_calculator.dart';
import '../../l10n/l10n.dart';
import '../groups/member_display.dart';
import '../shell/widgets/common.dart';

/// Translated chip label for a split method.
String splitMethodLabel(SplitMethod method, AppLocalizations l10n) => switch (method) {
      SplitMethod.equal => l10n.splitEqual,
      SplitMethod.exact => l10n.splitExact,
      SplitMethod.percent => l10n.splitPercent,
      SplitMethod.shares => l10n.splitShares,
      SplitMethod.adjustment => l10n.splitAdjustment,
      SplitMethod.byItem => l10n.splitByItem,
    };

/// Translated one-line explanation of how a split method works.
/// Translates a language-free [SplitError] into user-facing text.
String splitErrorMessage(SplitError error, AppLocalizations l10n, String symbol) {
  String money() => formatMinor(error.amountMinor, symbol: symbol);
  String percent() {
    final text = error.percent.toStringAsFixed(2);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }

  return switch (error.code) {
    SplitErrorCode.negativeTotal => l10n.splitErrorNegativeTotal,
    SplitErrorCode.nobodyIncluded => l10n.splitErrorNobodyIncluded,
    SplitErrorCode.negativeAmounts => l10n.splitErrorNegativeAmounts,
    SplitErrorCode.amountLeft => l10n.splitErrorAmountLeft(money()),
    SplitErrorCode.amountOver => l10n.splitErrorAmountOver(money()),
    SplitErrorCode.negativeValues => l10n.splitErrorNegativeValues,
    SplitErrorCode.percentMustTotal => l10n.splitErrorPercentMustTotal,
    SplitErrorCode.noShares => l10n.splitErrorNoShares,
    SplitErrorCode.percentLeft => l10n.splitErrorPercentLeft(percent()),
    SplitErrorCode.percentOver => l10n.splitErrorPercentOver(percent()),
    SplitErrorCode.adjustmentsExceed => l10n.splitErrorAdjustmentsExceed(money()),
    SplitErrorCode.adjustmentNegativeShare => l10n.splitErrorAdjustmentNegativeShare,
    SplitErrorCode.noItems => l10n.splitErrorNoItems,
    SplitErrorCode.itemsExceed => l10n.splitErrorItemsExceed(money()),
    SplitErrorCode.itemUnassigned => l10n.splitErrorItemUnassigned(error.label.isEmpty ? l10n.genericItem : error.label),
  };
}

String splitMethodHelp(SplitMethod method, AppLocalizations l10n) => switch (method) {
      SplitMethod.equal => l10n.splitHelpEqual,
      SplitMethod.exact => l10n.splitHelpExact,
      SplitMethod.percent => l10n.splitHelpPercent,
      SplitMethod.shares => l10n.splitHelpShares,
      SplitMethod.adjustment => l10n.splitHelpAdjustment,
      SplitMethod.byItem => l10n.splitHelpByItem,
    };

/// Editable split for a group expense. Emits the full state on every change so
/// the parent can persist it; validation comes from [computeSplit].
class SplitEditor extends StatelessWidget {
  const SplitEditor({
    super.key,
    required this.totalMinor,
    required this.members,
    required this.method,
    required this.inputs,
    required this.symbol,
    required this.onMethodChanged,
    required this.onInputsChanged,
  });

  final int totalMinor;
  final List<Member> members;
  final SplitMethod method;
  final List<SplitInput> inputs;
  final String symbol;
  final ValueChanged<SplitMethod> onMethodChanged;
  final ValueChanged<List<SplitInput>> onInputsChanged;

  @override
  Widget build(BuildContext context) {
    final outcome = computeSplit(totalMinor: totalMinor, method: method, inputs: inputs);
    final shares = outcome.asMap();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipRow(
          padding: EdgeInsets.zero,
          children: [
            for (final option in SplitMethod.values.where((m) => m != SplitMethod.byItem))
              ChoiceChip(label: Text(splitMethodLabel(option, l10n)), selected: method == option, onSelected: (_) => onMethodChanged(option)),
          ],
        ),
        const SizedBox(height: 8),
        Text(splitMethodHelp(method, l10n), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        for (final member in members) _memberRow(context, member, shares[member.id]),
        const SizedBox(height: 8),
        if (!outcome.isValid)
          Text(outcome.error == null ? l10n.splitDoesNotAddUp : splitErrorMessage(outcome.error!, l10n, symbol), style: TextStyle(color: theme.colorScheme.error))
        else
          Text(l10n.splitsAcross(formatMinor(outcome.totalMinor, symbol: symbol), outcome.shares.length), style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _memberRow(BuildContext context, Member member, int? share) {
    final input = inputs.firstWhere((i) => i.memberId == member.id, orElse: () => SplitInput(memberId: member.id));
    final shareText = share == null ? '—' : formatMinor(share, symbol: symbol);
    Widget trailing;
    switch (method) {
      case SplitMethod.equal:
        trailing = Checkbox(value: input.included, onChanged: (v) => _update(input.copyWith(included: v ?? false)));
      case SplitMethod.exact:
        trailing = _numberField(
          initial: input.amountMinor == 0 ? '' : minorToDouble(input.amountMinor).toStringAsFixed(2),
          suffix: symbol,
          onChanged: (text) => _update(input.copyWith(amountMinor: parseAmountToMinor(text) ?? 0)),
        );
      case SplitMethod.percent:
        trailing = _numberField(
          initial: input.weight == 0 ? '' : _trim(input.weight),
          suffix: '%',
          onChanged: (text) => _update(input.copyWith(weight: double.tryParse(text) ?? 0)),
        );
      case SplitMethod.shares:
        trailing = _numberField(
          initial: input.weight == 0 ? '' : _trim(input.weight),
          suffix: 'sh',
          onChanged: (text) => _update(input.copyWith(weight: double.tryParse(text) ?? 0)),
        );
      case SplitMethod.adjustment:
        trailing = Row(mainAxisSize: MainAxisSize.min, children: [
          Checkbox(value: input.included, onChanged: (v) => _update(input.copyWith(included: v ?? false))),
          _numberField(
            initial: input.amountMinor == 0 ? '' : minorToDouble(input.amountMinor).toStringAsFixed(2),
            suffix: '+$symbol',
            onChanged: (text) => _update(input.copyWith(amountMinor: parseAmountToMinor(text) ?? 0)),
          ),
        ]);
      case SplitMethod.byItem:
        trailing = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 16, child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase())),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(memberDisplayName(context.l10n, member)),
              Text(shareText, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _numberField({required String initial, required String suffix, required ValueChanged<String> onChanged}) {
    return SizedBox(
      width: 110,
      child: TextFormField(
        initialValue: initial,
        textAlign: TextAlign.end,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(suffixText: suffix, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
        onChanged: onChanged,
      ),
    );
  }

  void _update(SplitInput changed) {
    final next = [for (final i in inputs) if (i.memberId == changed.memberId) changed else i];
    if (!next.any((i) => i.memberId == changed.memberId)) next.add(changed);
    onInputsChanged(next);
  }

  static String _trim(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

}

/// Default inputs for a method, so switching methods keeps a valid state.
/// Shares start from each member's weight from group settings.
List<SplitInput> defaultSplitInputs(List<Member> members, SplitMethod method) => [
      for (final m in members)
        SplitInput(
          memberId: m.id,
          included: true,
          weight: switch (method) {
            SplitMethod.percent => 100 / members.length,
            SplitMethod.shares => m.weight > 0 ? m.weight : 1,
            _ => 0,
          },
        ),
    ];
