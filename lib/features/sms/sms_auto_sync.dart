import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/sms/sms_channel.dart';
import '../../domain/notifications/notification_kinds.dart';
import '../../l10n/l10n.dart';

/// Background receiver settings in the user's language. The amount and
/// sender stay as literal placeholders for the native side to fill.
/// With auto-add on, a clear transaction is added when the app next opens,
/// so the text says that instead of asking for a review (#103).
/// [notify] off keeps capturing but posts nothing (Settings > Notifications).
SmsCaptureConfig smsCaptureConfig(AppLocalizations l10n, {required bool enabled, required bool autoAdd, bool notify = true}) => SmsCaptureConfig(
      enabled: enabled,
      notify: notify,
      channelName: l10n.bankSms,
      title: l10n.smsNotificationTitle,
      bodyWithAmount: autoAdd ? l10n.smsNotificationBodyAmountAutoAdd('{amount}', '{sender}') : l10n.smsNotificationBodyAmount('{amount}', '{sender}'),
      bodyWithoutAmount: autoAdd ? l10n.smsNotificationBodyAutoAdd('{sender}') : l10n.smsNotificationBody('{sender}'),
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
    final settings = ref.read(settingsProvider);
    final enabled = settings.smsEnabled;
    final notify = bankSmsAlertsAllowed(ref.read(notificationPrefsProvider).choices);
    final capture = smsCaptureConfig(context.l10n, enabled: enabled, autoAdd: settings.smsAutoAdd, notify: notify);
    final config = capture.toMap();
    if (!mapEquals(config, _sentConfig)) {
      _sentConfig = config;
      unawaited(SmsChannel.configureCapture(capture));
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
    // Users upgrading with Bank SMS already on were never asked (#42).
    await ref.read(smsNotificationPromptProvider).askOnce();
    await service.sync(autoAdd: settings.smsAutoAdd);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider.select((settings) => (settings.smsEnabled, settings.smsAutoAdd)), (_, _) => _applySettings());
    ref.listen(notificationPrefsProvider.select((prefs) => bankSmsAlertsAllowed(prefs.choices)), (_, _) => _applySettings());
    return widget.child;
  }
}
