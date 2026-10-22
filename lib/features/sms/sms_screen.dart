import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/sms/sms_channel.dart';
import '../../data/sms/sms_ingest_service.dart';
import '../../domain/sms/payee_normaliser.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

class SmsScreen extends ConsumerStatefulWidget {
  const SmsScreen({super.key, this.sharedText});

  /// Text handed in by the iOS Shortcut / share sheet deep link.
  final String? sharedText;

  @override
  ConsumerState<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends ConsumerState<SmsScreen> {
  bool _busy = false;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    if (widget.sharedText != null && widget.sharedText!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ingestText(widget.sharedText!));
    }
  }

  /// A second share or link while this screen is already open reuses it
  /// with new text; ingest that too.
  @override
  void didUpdateWidget(SmsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.sharedText;
    if (text != null && text.trim().isNotEmpty && text != oldWidget.sharedText) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ingestText(text));
    }
  }

  Future<void> _ingestText(String text) async {
    final service = ref.read(smsIngestServiceProvider);
    final status = await service.ingest(RawSms(sender: 'PASTED', body: text, receivedAt: DateTime.now()), autoAdd: false, force: true);
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() => _lastResult = switch (status) {
          IngestStatus.pending => l10n.smsFoundReview,
          IngestStatus.added => l10n.smsAdded,
          IngestStatus.duplicate => l10n.smsDuplicate,
          _ => l10n.smsNotFound,
        });
  }

  Future<void> _toggleSms(bool enable) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (!enable) {
      ref.read(smsIngestServiceProvider).stopListening();
      await notifier.update((s) => s.copyWith(smsEnabled: false));
      return;
    }
    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.readBankSmsQuestion),
        content: Text(dialogContext.l10n.smsConsentBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(dialogContext.l10n.notNow)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(dialogContext.l10n.allow)),
        ],
      ),
    );
    if (consent != true) return;
    final granted = await ref.read(smsIngestServiceProvider).requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.smsPermissionDenied),
          action: SnackBarAction(label: context.l10n.settings, onPressed: openAppSettings),
        ));
      }
      return;
    }
    await notifier.update((s) => s.copyWith(smsEnabled: true));
    await _scan();
  }

  Future<void> _scan() async {
    setState(() => _busy = true);
    final settings = ref.read(settingsProvider);
    final service = ref.read(smsIngestServiceProvider);
    final result = await service.scanInbox(autoAdd: settings.smsAutoAdd);
    service.startListening(autoAdd: () => ref.read(settingsProvider).smsAutoAdd);
    if (mounted) {
      setState(() {
        _busy = false;
        _lastResult = context.l10n.scanResult(result.scanned, result.added, result.pending);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final pending = ref.watch(pendingSmsProvider).value ?? const <SmsLogData>[];
    final symbol = settings.currencySymbol;
    final supported = SmsChannel.isSupported;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bankSms)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Card(
            child: Column(children: [
              SwitchListTile(
                title: Text(l10n.readBankSmsAuto),
                subtitle: Text(supported ? l10n.smsAndroidOnly : l10n.smsNotOnIos),
                value: settings.smsEnabled && supported,
                onChanged: supported ? _toggleSms : null,
              ),
              SwitchListTile(
                title: Text(l10n.smsAutoAddTitle),
                subtitle: Text(l10n.smsAutoAddHelp),
                value: settings.smsAutoAdd,
                onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(smsAutoAdd: v)),
              ),
              if (supported && settings.smsEnabled)
                ListTile(
                  leading: _busy ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                  title: Text(l10n.scanInboxNow),
                  subtitle: Text(l10n.scanInboxHelp),
                  onTap: _busy ? null : _scan,
                ),
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: Text(l10n.pasteSms),
                subtitle: Text(l10n.pasteSmsHelp),
                onTap: () async {
                  final text = await promptText(context, title: l10n.pasteBankSms, hint: l10n.pasteBankSmsHint);
                  if (text != null && text.isNotEmpty) await _ingestText(text);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(l10n.smsHistoryTitle),
                subtitle: Text(l10n.smsHistoryHelp),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/sms/history'),
              ),
            ]),
          ),
          if (_lastResult != null) Padding(padding: const EdgeInsets.all(12), child: Text(_lastResult!, style: Theme.of(context).textTheme.bodyMedium)),
          SectionHeader(l10n.toReview(pending.length)),
          if (pending.isEmpty)
            Card(child: ListTile(leading: const Icon(Icons.inbox_outlined), title: Text(l10n.nothingWaitingTitle), subtitle: Text(l10n.nothingWaitingBody)))
          else
            for (final row in pending) _PendingCard(row: row, symbol: symbol),
          const SizedBox(height: 16),
          Text(l10n.iosShortcutHelp, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.row, required this.symbol});
  final SmsLogData row;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsed = row.parsedJson == null ? const <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(row.parsedJson!) as Map);
    final isDebit = parsed['direction'] == 'debit';
    final amount = (parsed['amountMinor'] as int?) ?? 0;
    final service = ref.read(smsIngestServiceProvider);
    final smsLog = ref.read(smsLogRepositoryProvider);
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final categoryKey = parsed['suggestedCategory'] as String?;
    final category = categoryKey == null ? null : categories.where((c) => c.seedKey == categoryKey).firstOrNull;
    final occurredAt = DateTime.tryParse(parsed['occurredAt'] as String? ?? '') ?? row.receivedAt;
    final locale = Localizations.localeOf(context).toString();
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
                  _payeeLabel(parsed['counterparty'] as String?) ?? (parsed['bank'] as String?) ?? row.sender,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AmountText(amount, kind: isDebit ? 'expense' : 'income'),
            ]),
            const SizedBox(height: 4),
            Text(
              [
                if (parsed['bank'] != null) parsed['bank'] as String,
                if (parsed['accountLast4'] != null) '••${parsed['accountLast4']}',
                if (category != null) category.displayName(context),
                formatShortDate(occurredAt, locale: locale),
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(row.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
            Row(children: [
              TextButton(onPressed: () => smsLog.setStatus(row.id, 'ignored'), child: Text(context.l10n.ignore)),
              const Spacer(),
              TextButton(onPressed: () => context.push('/entry?sms=${row.id}'), child: Text(context.l10n.edit)),
              FilledButton.tonal(
                onPressed: () async {
                  final id = await service.approvePending(row);
                  if (id == null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.couldNotAddUseEdit)));
                },
                child: Text(context.l10n.addAmount(formatMinor(amount, symbol: symbol, showDecimals: false))),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

String? _payeeLabel(String? counterparty) => counterparty == null ? null : normalisePayee(counterparty);
