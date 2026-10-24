import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/sms/sms_channel.dart';
import '../../data/sms/sms_ingest_service.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'widgets/sms_review_card.dart';

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
    final status = await service.ingest(
      RawSms(sender: 'PASTED', body: text, receivedAt: DateTime.now()),
      autoAdd: ref.read(settingsProvider).smsAutoAdd,
      force: true,
    );
    if (!mounted) return;
    final l10n = context.l10n;
    setState(
      () => _lastResult = switch (status) {
        IngestStatus.pending => l10n.smsFoundReview,
        IngestStatus.added => l10n.smsAdded,
        IngestStatus.duplicate => l10n.smsDuplicate,
        IngestStatus.foreignCurrency => l10n.smsForeignCurrency,
        _ => l10n.smsNotFound,
      },
    );
  }

  Future<void> _toggleSms(bool enable) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (!enable) {
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
        showActionSnackBar(ScaffoldMessenger.of(context), message: context.l10n.smsPermissionDenied, actionLabel: context.l10n.settings, onAction: openAppSettings);
      }
      return;
    }
    await ref.read(smsNotificationPromptProvider).ask();
    await notifier.update((s) => s.copyWith(smsEnabled: true));
    await _scan();
  }

  Future<void> _scan() async {
    setState(() => _busy = true);
    final settings = ref.read(settingsProvider);
    final service = ref.read(smsIngestServiceProvider);
    final result = await service.sync(autoAdd: settings.smsAutoAdd);
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
            child: Column(
              children: [
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
                  onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(smsAutoAdd: v, smsAutoAddChosen: true)),
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
              ],
            ),
          ),
          if (_lastResult != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_lastResult!, style: Theme.of(context).textTheme.bodyMedium),
            ),
          SectionHeader(l10n.toReview(pending.length)),
          if (pending.isEmpty)
            Card(
              child: ListTile(leading: const Icon(Icons.inbox_outlined), title: Text(l10n.nothingWaitingTitle), subtitle: Text(l10n.nothingWaitingBody)),
            )
          else
            for (final row in pending) SmsReviewCard(key: ValueKey(row.id), row: row, symbol: symbol),
          const SizedBox(height: 16),
          Text(l10n.iosShortcutHelp, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
