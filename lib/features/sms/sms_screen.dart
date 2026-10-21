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

  Future<void> _ingestText(String text) async {
    final service = ref.read(smsIngestServiceProvider);
    final status = await service.ingest(RawSms(sender: 'PASTED', body: text, receivedAt: DateTime.now()), autoAdd: false, force: true);
    if (!mounted) return;
    setState(() => _lastResult = switch (status) {
          IngestStatus.pending => 'Transaction found. Review it below.',
          IngestStatus.added => 'Transaction added.',
          IngestStatus.duplicate => 'Already imported.',
          _ => 'Could not find a transaction in that text.',
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
      builder: (context) => AlertDialog(
        title: const Text('Read bank SMS?'),
        content: const Text(
          'Hisab reads SMS from your bank and UPI apps to log transactions and show account balances. '
          'Messages are processed on this device only and never uploaded. OTPs and promotional SMS are ignored. '
          'You can turn this off any time.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Allow')),
        ],
      ),
    );
    if (consent != true) return;
    final granted = await ref.read(smsIngestServiceProvider).requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('SMS permission was not granted'),
          action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
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
        _lastResult = 'Scanned ${result.scanned} messages: ${result.added} added, ${result.pending} waiting for review.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final pending = ref.watch(pendingSmsProvider).value ?? const <SmsLogData>[];
    final symbol = settings.currencySymbol;
    final supported = SmsChannel.isSupported;
    return Scaffold(
      appBar: AppBar(title: const Text('Bank SMS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Card(
            child: Column(children: [
              SwitchListTile(
                title: const Text('Read bank SMS automatically'),
                subtitle: Text(supported ? 'Android only. Processed on-device, never uploaded.' : 'Not available on iOS. Use the Shortcut or paste below.'),
                value: settings.smsEnabled && supported,
                onChanged: supported ? _toggleSms : null,
              ),
              SwitchListTile(
                title: const Text('Add transactions without review'),
                subtitle: const Text('Off: new SMS wait in the review list below.'),
                value: settings.smsAutoAdd,
                onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(smsAutoAdd: v)),
              ),
              if (supported && settings.smsEnabled)
                ListTile(
                  leading: _busy ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                  title: const Text('Scan inbox now'),
                  subtitle: const Text('Looks back 90 days the first time, then only new messages'),
                  onTap: _busy ? null : _scan,
                ),
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: const Text('Paste an SMS'),
                subtitle: const Text('Works on iOS and Android'),
                onTap: () async {
                  final text = await promptText(context, title: 'Paste bank SMS', hint: 'Rs.500 debited from A/c XX1234…');
                  if (text != null && text.isNotEmpty) await _ingestText(text);
                },
              ),
            ]),
          ),
          if (_lastResult != null) Padding(padding: const EdgeInsets.all(12), child: Text(_lastResult!, style: Theme.of(context).textTheme.bodyMedium)),
          SectionHeader('To review (${pending.length})'),
          if (pending.isEmpty)
            const Card(child: ListTile(leading: Icon(Icons.inbox_outlined), title: Text('Nothing waiting'), subtitle: Text('New bank transactions will show up here.')))
          else
            for (final row in pending) _PendingCard(row: row, symbol: symbol),
          const SizedBox(height: 16),
          Text(
            'iPhone: create a Shortcuts automation "When I get a message containing \'debited\'" → "Open URL" with hisab:///sms?text=[Message]. '
            'Hisab will open and queue the transaction for review.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
                  (parsed['counterparty'] as String?) ?? (parsed['bank'] as String?) ?? row.sender,
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
                if (parsed['suggestedCategory'] != null) (parsed['suggestedCategory'] as String).replaceAll('_', ' '),
                formatShortDate(row.receivedAt),
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(row.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
            Row(children: [
              TextButton(onPressed: () => smsLog.setStatus(row.id, 'ignored'), child: const Text('Ignore')),
              const Spacer(),
              TextButton(onPressed: () => context.push('/entry?sms=${row.id}'), child: const Text('Edit')),
              FilledButton.tonal(
                onPressed: () async {
                  final id = await service.approvePending(row);
                  if (id == null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add this one; use Edit')));
                },
                child: Text('Add ${formatMinor(amount, symbol: symbol, showDecimals: false)}'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
