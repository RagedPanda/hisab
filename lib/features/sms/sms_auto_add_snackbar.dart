import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/sms/sms_ingest_service.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// How long the Undo for an automatic SMS add stays on screen.
const kSmsUndoWindow = Duration(seconds: 5);

/// Adds that arrive this close together (an inbox scan, a burst of alerts)
/// share one snackbar and one Undo.
const kSmsAutoAddBatchWindow = Duration(milliseconds: 600);

/// While the app is open, announces every entry added from an SMS with a
/// short snackbar that offers Undo.
class SmsAutoAddSnackbar extends ConsumerStatefulWidget {
  const SmsAutoAddSnackbar({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SmsAutoAddSnackbar> createState() => _SmsAutoAddSnackbarState();
}

class _SmsAutoAddSnackbarState extends ConsumerState<SmsAutoAddSnackbar> {
  StreamSubscription<SmsAutoAdded>? _subscription;
  Timer? _batchTimer;
  final List<SmsAutoAdded> _batch = [];

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(smsIngestServiceProvider).autoAdded.listen(_onAutoAdded);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _batchTimer?.cancel();
    super.dispose();
  }

  void _onAutoAdded(SmsAutoAdded added) {
    _batch.add(added);
    _batchTimer?.cancel();
    _batchTimer = Timer(kSmsAutoAddBatchWindow, _announceBatch);
  }

  void _announceBatch() {
    if (!mounted || _batch.isEmpty) return;
    final added = List<SmsAutoAdded>.of(_batch);
    _batch.clear();
    final l10n = context.l10n;
    final service = ref.read(smsIngestServiceProvider);
    final symbol = ref.read(settingsProvider).currencySymbol;
    final single = added.length == 1 ? added.single : null;
    final message = single == null
        ? l10n.smsAutoAddedMany(added.length)
        : [l10n.smsAutoAddedOne(formatMinor(single.amountMinor, symbol: symbol, showDecimals: false)), ?single.payee].join(' · ');
    showUndoSnackBar(
      ScaffoldMessenger.of(context),
      message: message,
      undoLabel: l10n.undo,
      duration: kSmsUndoWindow,
      onUndo: () {
        for (final item in added) {
          service.undoAutoAdd(item);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
