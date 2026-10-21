import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/split/split_calculator.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final option in SplitMethod.values.where((m) => m != SplitMethod.byItem))
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(option.label), selected: method == option, onSelected: (_) => onMethodChanged(option)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(_hint(method), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        for (final member in members) _memberRow(context, member, shares[member.id]),
        const SizedBox(height: 8),
        if (!outcome.isValid)
          Text(outcome.error ?? 'Split does not add up', style: TextStyle(color: theme.colorScheme.error))
        else
          Text('Splits ${formatMinor(outcome.totalMinor, symbol: symbol)} across ${outcome.shares.length} people', style: theme.textTheme.bodySmall),
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
              Text(member.isMe ? '${member.name} (you)' : member.name),
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

  static String _hint(SplitMethod method) => switch (method) {
        SplitMethod.equal => 'Everyone ticked pays the same share.',
        SplitMethod.exact => 'Enter the exact amount each person owes; must add up to the total.',
        SplitMethod.percent => 'Enter percentages adding up to 100.',
        SplitMethod.shares => 'Enter shares, e.g. 2 for a couple and 1 for a single.',
        SplitMethod.adjustment => 'Extras are charged first, the rest is split equally among ticked people.',
        SplitMethod.byItem => 'Each item is split among the people who shared it.',
      };
}

/// Default inputs for a method, so switching methods keeps a valid state.
List<SplitInput> defaultSplitInputs(List<Member> members, SplitMethod method) => [
      for (final m in members)
        SplitInput(
          memberId: m.id,
          included: true,
          weight: method == SplitMethod.percent ? (100 / members.length) : (method == SplitMethod.shares ? 1 : 0),
        ),
    ];
