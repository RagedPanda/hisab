import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../data/db/database.dart';
import '../../../data/repositories/payee_category_repository.dart';
import '../../../domain/sms/payee_category_memory.dart';
import '../../../domain/sms/payee_normaliser.dart';
import '../../categories/category_picker.dart';
import '../../../l10n/category_names.dart';
import '../../../l10n/l10n.dart';
import '../../shell/widgets/common.dart';

/// One SMS in the review queue: what was read from it, the message itself,
/// and Ignore / Edit / Add. A message that could not be read at all has no
/// Add button; Edit opens the editor with the SMS attached.
class SmsReviewCard extends ConsumerWidget {
  const SmsReviewCard({super.key, required this.row, required this.moneyFormat});
  final SmsLogData row;
  final MoneyFormat moneyFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final parsed = row.parsedJson == null ? null : Map<String, dynamic>.from(jsonDecode(row.parsedJson!) as Map);
    final isDebit = parsed?['direction'] != 'credit';
    final amount = (parsed?['amountMinor'] as int?) ?? 0;
    final service = ref.read(smsIngestServiceProvider);
    final smsLog = ref.read(smsLogRepositoryProvider);
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final categoryKey = parsed?['suggestedCategory'] as String?;
    final memory = ref.watch(payeeMemoryProvider).value ?? const <String, String>{};
    final payee = parsedSmsPayee(row.parsedJson);
    final rememberedId = payee == null ? null : rememberedCategoryId(memory, kind: payee.kind, raw: payee.counterparty);
    final remembered = categories.where((c) => c.id == rememberedId).firstOrNull;
    final category = isUsablePayeeCategory(remembered, payee?.kind ?? kPayeeExpense)
        ? remembered
        : (categoryKey == null ? null : categories.where((c) => c.seedKey == categoryKey).firstOrNull);
    final asksForCategory = payee != null && asksForPayeeCategory(payee, memory);
    final occurredAt = DateTime.tryParse(parsed?['occurredAt'] as String? ?? '') ?? row.receivedAt;
    final locale = Localizations.localeOf(context).toString();
    final counterparty = parsed?['counterparty'] as String?;
    final bank = parsed?['bank'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  (counterparty == null ? null : normalisePayee(counterparty)) ?? bank ?? row.sender,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (parsed != null) AmountText(amount, kind: isDebit ? 'expense' : 'income'),
            ]),
            const SizedBox(height: 4),
            Text(
              parsed == null
                  ? [l10n.smsReviewUnread, formatShortDate(row.receivedAt, locale: locale)].join(' · ')
                  : [
                      ?bank,
                      if (parsed['accountLast4'] != null) '••${parsed['accountLast4']}',
                      if (category != null) category.displayName(context),
                      formatShortDate(occurredAt, locale: locale),
                    ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            if (asksForCategory) _PayeeCategoryPrompt(smsId: row.id, kind: payee.kind, payee: normalisePayee(payee.counterparty!)),
            const SizedBox(height: 4),
            Text(row.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            Row(children: [
              TextButton(onPressed: () => smsLog.setStatus(row.id, 'ignored'), child: Text(l10n.ignore)),
              const Spacer(),
              if (parsed == null)
                FilledButton.tonal(onPressed: () => context.push('/entry?sms=${row.id}'), child: Text(l10n.smsReviewAddManually))
              else ...[
                TextButton(onPressed: () => context.push('/entry?sms=${row.id}'), child: Text(l10n.edit)),
                FilledButton.tonal(
                  onPressed: () async {
                    final id = await service.approvePending(row);
                    if (id == null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotAddUseEdit)));
                  },
                  child: Text(l10n.addAmount(formatMinor(amount, format: moneyFormat, showDecimals: false))),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

/// Asks once for the category of a new person paid over UPI. Picking one
/// remembers it for that payee (this card then shows it, and Add uses it);
/// ignoring the prompt stores nothing.
class _PayeeCategoryPrompt extends ConsumerWidget {
  const _PayeeCategoryPrompt({required this.smsId, required this.kind, required this.payee});
  final String smsId;
  final String kind;
  final String payee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(Icons.person_outline, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(l10n.smsPayeeAskTitle(payee), style: theme.textTheme.bodySmall)),
        ActionChip(
          label: Text(l10n.smsPayeePickCategory),
          onPressed: () async {
            final picked = await showCategoryPicker(context, kind: kind);
            if (picked == null || !context.mounted) return;
            final message = l10n.smsPayeeRemembered(picked.displayName(context), payee);
            final messenger = ScaffoldMessenger.of(context);
            await ref.read(smsIngestServiceProvider).rememberCategoryForSms(smsId, picked.id);
            showTimedSnackBar(messenger, message);
          },
        ),
      ]),
    );
  }
}
