import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Small tag on a reminder that a matching bank SMS marked paid.
class PaidViaSmsLabel extends StatelessWidget {
  const PaidViaSmsLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSecondaryContainer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sms_outlined, size: 12, color: scheme.onSecondaryContainer),
        const SizedBox(width: 4),
        Flexible(child: Text(context.l10n.smsReminderPaidViaSms, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
