import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'widgets/sms_review_card.dart';

/// The review queue: bank SMS that were read with low confidence or could
/// not be read, waiting for the user to add, edit or ignore them.
class SmsReviewScreen extends ConsumerWidget {
  const SmsReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pending = ref.watch(pendingSmsProvider).value ?? const <SmsLogData>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.smsReviewTitle)),
      body: pending.isEmpty
          ? EmptyState(icon: Icons.inbox_outlined, title: l10n.nothingWaitingTitle, message: l10n.nothingWaitingBody)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l10n.smsReviewHelp, style: Theme.of(context).textTheme.bodyMedium),
                ),
                for (final row in pending) SmsReviewCard(key: ValueKey(row.id), row: row, symbol: symbol),
              ],
            ),
    );
  }
}
