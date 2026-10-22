import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../data/repositories/sms_log_repository.dart';
import '../../data/sms/sms_ingest_service.dart';
import '../../domain/sms/sms_outcome.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// Settings > Bank SMS > History: every processed message and its outcome.
class SmsHistoryScreen extends ConsumerStatefulWidget {
  const SmsHistoryScreen({super.key});

  @override
  ConsumerState<SmsHistoryScreen> createState() => _SmsHistoryScreenState();
}

class _SmsHistoryScreenState extends ConsumerState<SmsHistoryScreen> {
  SmsOutcome? _outcomeFilter;

  Future<void> _clearHistory(int clearableCount) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.smsHistoryClearQuestion,
      message: l10n.smsHistoryClearBody(clearableCount),
      confirmLabel: l10n.smsHistoryClearConfirm,
    );
    if (!confirmed) return;
    await ref.read(smsLogRepositoryProvider).clearHistory(now: DateTime.now());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.smsHistoryCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final history = ref.watch(smsHistoryProvider);
    final rows = history.value ?? const <SmsHistoryRow>[];
    final outcomes = [for (final row in rows) smsOutcomeFor(row.log.status)];
    final counts = countSmsOutcomes(outcomes);
    final clearableCount = rows.length - counts[SmsOutcome.pending]!;
    final visible = [
      for (var index = 0; index < rows.length; index++)
        if (_outcomeFilter == null || outcomes[index] == _outcomeFilter) rows[index],
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.smsHistoryTitle),
        actions: [
          IconButton(
            key: const ValueKey('smsHistoryClear'),
            tooltip: l10n.smsHistoryClear,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: clearableCount == 0 ? null : () => _clearHistory(clearableCount),
          ),
        ],
      ),
      body: history.isLoading && rows.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? EmptyState(icon: Icons.sms_outlined, title: l10n.smsHistoryEmptyTitle, message: l10n.smsHistoryEmptyBody)
              : Column(children: [
                  const SizedBox(height: 4),
                  ChipRow(children: [
                    ChoiceChip(label: Text(l10n.all), selected: _outcomeFilter == null, onSelected: (_) => setState(() => _outcomeFilter = null)),
                    for (final outcome in SmsOutcome.values)
                      if (outcome != SmsOutcome.undone || counts[outcome]! > 0)
                        ChoiceChip(
                          key: ValueKey('smsOutcomeChip-${outcome.name}'),
                          label: Text('${smsOutcomeLabel(context, outcome)} ${counts[outcome]}'),
                          selected: _outcomeFilter == outcome,
                          onSelected: (_) => setState(() => _outcomeFilter = outcome),
                        ),
                  ]),
                  const SizedBox(height: 8),
                  Expanded(
                    child: visible.isEmpty
                        ? EmptyState(icon: Icons.filter_alt_off_outlined, title: l10n.smsHistoryEmptyFiltered)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            itemCount: visible.length,
                            itemBuilder: (_, index) => _SmsHistoryCard(row: visible[index]),
                          ),
                  ),
                ]),
    );
  }
}

class _SmsHistoryCard extends ConsumerWidget {
  const _SmsHistoryCard({required this.row});
  final SmsHistoryRow row;

  Future<void> _reprocess(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final autoAdd = ref.read(settingsProvider).smsAutoAdd;
    final status = await ref.read(smsIngestServiceProvider).reprocess(row.log, autoAdd: autoAdd);
    if (!context.mounted) return;
    final message = switch (status) {
      IngestStatus.pending => l10n.smsFoundReview,
      IngestStatus.added => l10n.smsAdded,
      _ => l10n.smsNotFound,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final log = row.log;
    final outcome = smsOutcomeFor(log.status);
    final color = smsOutcomeColor(theme.colorScheme, outcome);
    final locale = Localizations.localeOf(context).toString();
    final detail = smsOutcomeDetail(context, log.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(log.sender, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text('${formatRowDate(log.receivedAt, locale: locale)}, ${formatTime(log.receivedAt, locale: locale)}', style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
            ]),
            const SizedBox(height: 4),
            Text(smsBodyPreview(log.body), maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(smsOutcomeIcon(outcome), size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(smsOutcomeLabel(context, outcome), style: theme.textTheme.labelMedium?.copyWith(color: color)),
                ]),
                if (detail != null) Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(spacing: 4, children: [
                if (row.hasEntry && log.entryId != null)
                  TextButton.icon(
                    onPressed: () => context.push('/entry?id=${log.entryId}'),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.smsHistoryOpenEntry),
                  ),
                if (canReprocessSms(outcome) && log.body.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _reprocess(context, ref),
                    icon: const Icon(Icons.replay, size: 18),
                    label: Text(l10n.smsHistoryReprocess),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

String smsOutcomeLabel(BuildContext context, SmsOutcome outcome) {
  final l10n = context.l10n;
  return switch (outcome) {
    SmsOutcome.added => l10n.smsOutcomeAdded,
    SmsOutcome.duplicate => l10n.smsOutcomeDuplicate,
    SmsOutcome.ignored => l10n.smsOutcomeIgnored,
    SmsOutcome.unparsed => l10n.smsOutcomeUnparsed,
    SmsOutcome.pending => l10n.smsOutcomePending,
    SmsOutcome.undone => l10n.smsOutcomeUndone,
  };
}

/// Why a message ended up with its outcome, when that is not obvious.
String? smsOutcomeDetail(BuildContext context, String status) {
  final l10n = context.l10n;
  return switch (status) {
    SmsLogStatus.notBank => l10n.smsHistoryNotBank,
    SmsLogStatus.ignored => l10n.smsHistoryDismissed,
    SmsLogStatus.skipped => l10n.smsHistoryUnparsedDetail,
    SmsLogStatus.duplicate => l10n.smsHistoryDuplicateDetail,
    _ => null,
  };
}

IconData smsOutcomeIcon(SmsOutcome outcome) => switch (outcome) {
      SmsOutcome.added => Icons.check_circle_outline,
      SmsOutcome.duplicate => Icons.copy_all_outlined,
      SmsOutcome.ignored => Icons.block,
      SmsOutcome.unparsed => Icons.help_outline,
      SmsOutcome.pending => Icons.hourglass_empty,
      SmsOutcome.undone => Icons.undo,
    };

Color smsOutcomeColor(ColorScheme scheme, SmsOutcome outcome) => switch (outcome) {
      SmsOutcome.added => scheme.primary,
      SmsOutcome.duplicate => scheme.tertiary,
      SmsOutcome.unparsed => scheme.error,
      SmsOutcome.pending => scheme.secondary,
      SmsOutcome.ignored || SmsOutcome.undone => scheme.outline,
    };
