import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/split/item_split.dart';
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
String splitErrorMessage(SplitError error, AppLocalizations l10n, MoneyFormat moneyFormat) {
  String money() => formatMinor(error.amountMinor, format: moneyFormat);
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

/// Split methods in the order the chips show them. By item needs items, and
/// when there are some it comes first, since that is what they are for.
List<SplitMethod> splitMethodOptions({required bool hasItems}) => [
      if (hasItems) SplitMethod.byItem,
      for (final method in SplitMethod.values)
        if (method != SplitMethod.byItem) method,
    ];

/// Icon for a split method in the picker row and its sheet.
IconData splitMethodIcon(SplitMethod method) => switch (method) {
      SplitMethod.equal => Icons.drag_handle,
      SplitMethod.exact => Icons.edit_note,
      SplitMethod.percent => Icons.percent,
      SplitMethod.shares => Icons.pie_chart_outline,
      SplitMethod.adjustment => Icons.tune,
      SplitMethod.byItem => Icons.receipt_long,
    };

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
    required this.moneyFormat,
    required this.onMethodChanged,
    required this.onInputsChanged,
    this.items = const [],
    this.payerId,
  });

  final int totalMinor;
  final List<Member> members;
  final SplitMethod method;
  final List<SplitInput> inputs;
  final MoneyFormat moneyFormat;
  final ValueChanged<SplitMethod> onMethodChanged;
  final ValueChanged<List<SplitInput>> onInputsChanged;

  /// The expense's line items; "By item" is offered only when there are some.
  final List<ItemSplitInput> items;

  /// Takes the rounding remainders of a by-item split.
  final String? payerId;

  @override
  Widget build(BuildContext context) {
    final outcome = computeSplit(totalMinor: totalMinor, method: method, inputs: inputs, items: items, payerId: payerId);
    final shares = outcome.asMap();
    final summaries = {for (final summary in itemShareSummaries(outcome, items)) summary.memberId: summary};
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SplitMethodTile(method: method, options: splitMethodOptions(hasItems: items.isNotEmpty), onPick: onMethodChanged),
        if (items.isEmpty)
          Text(l10n.byItemHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        for (final member in members)
          _memberRow(
            context,
            member,
            method == SplitMethod.byItem ? _byItemLine(l10n, summaries[member.id]) : _shareText(shares[member.id]),
          ),
        const SizedBox(height: 8),
        if (!outcome.isValid)
          Text(outcome.error == null ? l10n.splitDoesNotAddUp : splitErrorMessage(outcome.error!, l10n, moneyFormat), style: TextStyle(color: theme.colorScheme.error))
        else
          Text(l10n.splitsAcross(formatMinor(outcome.totalMinor, format: moneyFormat), outcome.shares.length), style: theme.textTheme.bodySmall),
      ],
    );
  }

  String _shareText(int? share) => share == null ? '—' : formatMinor(share, format: moneyFormat);

  /// "₹620 · 3 items · 31%" for a member of a by-item split.
  String _byItemLine(AppLocalizations l10n, ItemShareSummary? summary) =>
      summary == null ? '—' : l10n.byItemSummary(formatMinor(summary.amountMinor, format: moneyFormat), summary.itemCount, summary.percent);

  Widget _memberRow(BuildContext context, Member member, String shareText) {
    final input = inputs.firstWhere((i) => i.memberId == member.id, orElse: () => SplitInput(memberId: member.id));
    Widget trailing;
    switch (method) {
      case SplitMethod.equal:
        trailing = Checkbox(value: input.included, onChanged: (v) => _update(input.copyWith(included: v ?? false)));
      case SplitMethod.exact:
        trailing = _numberField(
          initial: input.amountMinor == 0 ? '' : amountInputText(input.amountMinor, format: moneyFormat),
          money: true,
          suffix: moneyFormat.symbol,
          onChanged: (text) => _update(input.copyWith(amountMinor: parseAmountToMinor(text, format: moneyFormat) ?? 0)),
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
            initial: input.amountMinor == 0 ? '' : amountInputText(input.amountMinor, format: moneyFormat),
            money: true,
            suffix: '+${moneyFormat.symbol}',
            onChanged: (text) => _update(input.copyWith(amountMinor: parseAmountToMinor(text, format: moneyFormat) ?? 0)),
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

  /// A small number field; [money] fields follow [moneyFormat]'s decimals.
  Widget _numberField({required String initial, required String suffix, required ValueChanged<String> onChanged, bool money = false}) {
    return SizedBox(
      width: 110,
      child: TextFormField(
        initialValue: initial,
        textAlign: TextAlign.end,
        keyboardType: money ? amountKeyboardType(moneyFormat) : const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: money ? amountInputFormatters(moneyFormat) : null,
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

/// One row showing the chosen split method and how it works, like the
/// account row; tapping it opens a sheet of every method.
class SplitMethodTile extends StatelessWidget {
  const SplitMethodTile({super.key, required this.method, required this.options, required this.onPick});
  final SplitMethod method;
  final List<SplitMethod> options;
  final ValueChanged<SplitMethod> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      key: const Key('split-method-picker'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(splitMethodIcon(method), color: Theme.of(context).colorScheme.primary),
      title: Text(splitMethodLabel(method, l10n)),
      subtitle: Text(splitMethodHelp(method, l10n)),
      trailing: const Icon(Icons.expand_more),
      onTap: () async {
        final picked = await showSplitMethodPicker(context, options: options, selected: method);
        if (picked != null && picked != method) onPick(picked);
      },
    );
  }
}

/// Bottom sheet listing [options] with a line on each; returns the picked
/// method, or null when dismissed.
Future<SplitMethod?> showSplitMethodPicker(BuildContext context, {required List<SplitMethod> options, required SplitMethod selected}) {
  final l10n = context.l10n;
  return showModalBottomSheet<SplitMethod>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final option in options)
          ListTile(
            key: Key('split-method-${option.name}'),
            leading: Icon(splitMethodIcon(option)),
            title: Text(splitMethodLabel(option, l10n)),
            subtitle: Text(splitMethodHelp(option, l10n)),
            trailing: option == selected ? const Icon(Icons.check) : null,
            selected: option == selected,
            onTap: () => Navigator.of(context).pop(option),
          ),
      ],
    ),
  );
}
