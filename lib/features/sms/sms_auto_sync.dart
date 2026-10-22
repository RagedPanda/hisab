import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/sms/sms_channel.dart';
import '../../l10n/l10n.dart';

/// Background receiver settings in the user's language. The amount and
/// sender stay as literal placeholders for the native side to fill.
SmsCaptureConfig smsCaptureConfig(AppLocalizations l10n, {required bool enabled}) => SmsCaptureConfig(
      enabled: enabled,
      channelName: l10n.bankSms,
      title: l10n.smsNotificationTitle,
      bodyWithAmount: l10n.smsNotificationBodyAmount('{amount}', '{sender}'),
      bodyWithoutAmount: l10n.smsNotificationBody('{sender}'),
    );

/// Keeps Bank SMS capture running for the whole app: tells the native
/// receiver whether the user opted in, and runs the ingest sync when the app
/// starts, returns to the foreground, or the receiver queues a message.
/// Does nothing where SMS cannot be read (iOS, tests).
class SmsAutoSync extends ConsumerStatefulWidget {
  const SmsAutoSync({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SmsAutoSync> createState() => _SmsAutoSyncState();
}

class _SmsAutoSyncState extends ConsumerState<SmsAutoSync> with WidgetsBindingObserver {
  StreamSubscription<void>? _signals;
  Map<String, Object>? _sentConfig;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs first on start and again when the language changes.
    _applySettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncIfEnabled();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _signals?.cancel();
    super.dispose();
  }

  void _applySettings() {
    if (!SmsChannel.isSupported) return;
    final enabled = ref.read(settingsProvider).smsEnabled;
    final config = smsCaptureConfig(context.l10n, enabled: enabled).toMap();
    if (!mapEquals(config, _sentConfig)) {
      _sentConfig = config;
      unawaited(SmsChannel.configureCapture(smsCaptureConfig(context.l10n, enabled: enabled)));
    }
    if (enabled && _signals == null) {
      _signals = SmsChannel.queueSignals().listen((_) => _syncIfEnabled());
      _syncIfEnabled();
    } else if (!enabled) {
      _signals?.cancel();
      _signals = null;
    }
  }

  Future<void> _syncIfEnabled() async {
    final settings = ref.read(settingsProvider);
    if (!SmsChannel.isSupported || !settings.smsEnabled) return;
    final service = ref.read(smsIngestServiceProvider);
    if (!await service.hasPermission()) return;
    await service.sync(autoAdd: settings.smsAutoAdd);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider.select((settings) => settings.smsEnabled), (_, _) => _applySettings());
    return widget.child;
  }
}
