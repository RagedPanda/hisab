import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/split/payers.dart';
import '../../l10n/l10n.dart';
import '../groups/member_display.dart';

/// How much each member paid towards one expense, when more than one person
/// paid. Shows a running "X of Y assigned" line that turns red until the
/// amounts add up to the bill.
class PayersEditor extends StatelessWidget {
  const PayersEditor({
    super.key,
    required this.totalMinor,
    required this.members,
    required this.amounts,
    required this.moneyFormat,
    required this.onChanged,
  });

  final int totalMinor;
  final List<Member> members;
  final Map<String, int> amounts;
  final MoneyFormat moneyFormat;
  final ValueChanged<Map<String, int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final assigned = totalMinor - unassignedMinor(totalMinor, payersFrom(amounts));
    final balanced = assigned == totalMinor && totalMinor > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.payersHelp, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        for (final member in members) _payerRow(context, member),
        const SizedBox(height: 8),
        Text(
          l10n.payersAssigned(formatMinor(assigned, format: moneyFormat), formatMinor(totalMinor, format: moneyFormat)),
          key: const Key('payers-assigned'),
          style: balanced ? theme.textTheme.bodySmall : TextStyle(color: theme.colorScheme.error),
        ),
      ],
    );
  }

  Widget _payerRow(BuildContext context, Member member) {
    final amount = amounts[member.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          MemberAvatar(member: member),
          const SizedBox(width: 10),
          Expanded(child: Text(memberDisplayName(context.l10n, member), maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 120,
            child: TextFormField(
              key: Key('payer-amount-${member.id}'),
              initialValue: amount == 0 ? '' : amountInputText(amount, format: moneyFormat),
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(prefixText: amountPrefixText(moneyFormat), suffixText: amountSuffixText(moneyFormat), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              onChanged: (text) => onChanged({...amounts, member.id: parseAmountToMinor(text, format: moneyFormat) ?? 0}),
            ),
          ),
        ],
      ),
    );
  }
}
