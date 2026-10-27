import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/split/debt_simplifier.dart';
import '../../domain/split/settle_up_links.dart';
import '../../l10n/l10n.dart';

/// Opens a link in another app (UPI, WhatsApp, SMS). Returns false when no app
/// took it. A provider so tests can stand in for the outside world.
final linkLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  },
);

/// Shares text through the system sheet. Returns true unless the person
/// dismissed it, so a cancelled share is never logged as a reminder.
final textSharerProvider = Provider<Future<bool> Function(String)>(
  (ref) => (text) async => (await SharePlus.instance.share(ShareParams(text: text))).status != ShareResultStatus.dismissed,
);

/// Remind (someone owes me) or Pay (I owe someone) for one settle-up transfer:
/// an editable message plus Share, Copy, and WhatsApp/SMS when the member has a
/// phone; Pay adds "Pay with UPI" when they have a UPI ID, then asks whether
/// the payment went through before recording anything.
Future<void> showSettleUpSheet(
  BuildContext context, {
  required Group group,
  required Transfer transfer,
  required SettleRole role,
  required Member counterpart,
  required String message,
  required MoneyFormat moneyFormat,
  required DateTime? lastRemindedAt,
  required VoidCallback onRecordPayment,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SettleUpSheet(
      group: group,
      transfer: transfer,
      role: role,
      counterpart: counterpart,
      message: message,
      moneyFormat: moneyFormat,
      lastRemindedAt: lastRemindedAt,
      onRecordPayment: onRecordPayment,
    ),
  );
}

class _SettleUpSheet extends ConsumerStatefulWidget {
  const _SettleUpSheet({
    required this.group,
    required this.transfer,
    required this.role,
    required this.counterpart,
    required this.message,
    required this.moneyFormat,
    required this.lastRemindedAt,
    required this.onRecordPayment,
  });
  final Group group;
  final Transfer transfer;
  final SettleRole role;
  final Member counterpart;
  final String message;
  final MoneyFormat moneyFormat;
  final DateTime? lastRemindedAt;
  final VoidCallback onRecordPayment;

  @override
  ConsumerState<_SettleUpSheet> createState() => _SettleUpSheetState();
}

class _SettleUpSheetState extends ConsumerState<_SettleUpSheet> {
  late final _message = TextEditingController(text: widget.message);

  /// Why the last action failed. Shown inside the sheet, because a snackbar
  /// would sit behind it.
  String? _problem;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _isReminder => widget.role == SettleRole.remind;

  /// Logs a reminder (only when I am the one being paid) and closes the sheet.
  Future<void> _sent(String channel) async {
    if (_isReminder) {
      await ref.read(groupsRepositoryProvider).recordSettleUpReminder(
            groupId: widget.group.id,
            memberId: widget.counterpart.id,
            channel: channel,
            message: _message.text,
          );
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _share() async {
    if (await ref.read(textSharerProvider)(_message.text)) await _sent('share');
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _message.text));
    if (!mounted) return;
    _snack(context.l10n.copiedReminder);
    await _sent('copy');
  }

  Future<void> _open(Uri? uri, String channel, String appName) async {
    if (uri != null && await ref.read(linkLauncherProvider)(uri)) {
      await _sent(channel);
    } else if (mounted) {
      setState(() => _problem = context.l10n.couldNotOpenApp(appName));
    }
  }

  Future<void> _payWithUpi(String upiId) async {
    final l10n = context.l10n;
    final uri = upiPayUri(upiId: upiId, payeeName: widget.counterpart.name, amountMinor: widget.transfer.amountMinor, note: widget.group.name, currency: widget.group.currency);
    if (!await ref.read(linkLauncherProvider)(uri)) {
      if (mounted) setState(() => _problem = l10n.noUpiApp);
      return;
    }
    if (!mounted) return;
    // Hisab cannot see the UPI app's result, so the person confirms.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.didPaymentGoThrough),
        content: Text(l10n.didPaymentGoThroughBody(formatMinor(widget.transfer.amountMinor, format: widget.moneyFormat), widget.counterpart.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.notYet)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.yesRecordIt)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(groupsRepositoryProvider).addSettlement(
          groupId: widget.group.id,
          fromMemberId: widget.transfer.from,
          toMemberId: widget.transfer.to,
          amountMinor: widget.transfer.amountMinor,
          method: 'upi',
        );
    if (!mounted) return;
    _snack(l10n.paymentRecorded(l10n.transferArrow(l10n.you, widget.counterpart.name), formatMinor(widget.transfer.amountMinor, format: widget.moneyFormat)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = widget.counterpart.name;
    final phone = widget.counterpart.phone?.trim();
    final hasPhone = phone != null && internationalDigits(phone) != null;
    final upiId = widget.counterpart.upiId;
    final lastReminded = widget.lastRemindedAt;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isReminder ? l10n.remindName(name) : l10n.payName(name), style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(formatMinor(widget.transfer.amountMinor, format: widget.moneyFormat), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            if (_isReminder && lastReminded != null) ...[
              const SizedBox(height: 4),
              Text(l10n.remindedDaysAgo(daysBetween(lastReminded, DateTime.now())), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (_problem case final problem?) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 20, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(problem, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error))),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (!_isReminder && upiId != null) ...[
              FilledButton.icon(
                onPressed: () => _payWithUpi(upiId),
                icon: const Icon(Icons.qr_code_2),
                label: Text(l10n.payWithUpi),
              ),
              const SizedBox(height: 8),
            ],
            if (!_isReminder) ...[
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRecordPayment();
                },
                icon: const Icon(Icons.add_card_outlined),
                label: Text(l10n.recordPayment),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(labelText: l10n.messageLabel, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(onPressed: _share, icon: const Icon(Icons.ios_share), label: Text(l10n.shareAction)),
                OutlinedButton.icon(onPressed: _copy, icon: const Icon(Icons.copy), label: Text(l10n.copyAction)),
                if (hasPhone) ...[
                  OutlinedButton.icon(
                    onPressed: () => _open(whatsAppUri(phone, _message.text), 'whatsapp', l10n.whatsAppAction),
                    icon: const Icon(Icons.chat_outlined),
                    label: Text(l10n.whatsAppAction),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _open(smsUri(phone, _message.text), 'sms', l10n.smsAction),
                    icon: const Icon(Icons.sms_outlined),
                    label: Text(l10n.smsAction),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
