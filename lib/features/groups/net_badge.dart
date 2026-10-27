import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../l10n/l10n.dart';

/// "you get ₹x" / "you owe ₹x" / "settled" trailing for a group row, shared by
/// the Groups tab and the dashboard groups card.
class GroupNetBadge extends StatelessWidget {
  const GroupNetBadge({super.key, required this.net, required this.moneyFormat});

  /// Positive: others owe me. Negative: I owe.
  final int net;
  final MoneyFormat moneyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (net == 0) return Text(context.l10n.settled, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    final color = net > 0 ? kIncomeColor : kExpenseColor;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(net > 0 ? context.l10n.youGet : context.l10n.youOweLower, style: theme.textTheme.bodySmall),
        Text(formatMinor(net.abs(), format: moneyFormat), style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w700).tabular),
      ],
    );
  }
}
