import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_lock/device_authenticator.dart';
import '../../domain/app_lock/app_lock_policy.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'app_lock_providers.dart';

const String kAppLockLocation = '/app-lock';

/// "after 1 minute", as the Settings row's summary reads it.
String appLockTimeoutLabel(AppLocalizations l10n, AppLockTimeout timeout) => switch (timeout) {
      AppLockTimeout.immediately => l10n.appLockImmediately,
      AppLockTimeout.oneMinute => l10n.appLockOneMinute,
      AppLockTimeout.fiveMinutes => l10n.appLockFiveMinutes,
    };

String _timeoutSegmentLabel(AppLocalizations l10n, AppLockTimeout timeout) => switch (timeout) {
      AppLockTimeout.immediately => l10n.appLockImmediatelyShort,
      AppLockTimeout.oneMinute => l10n.appLockOneMinuteShort,
      AppLockTimeout.fiveMinutes => l10n.appLockFiveMinutesShort,
    };

/// Turns the app lock on only after the user proves who they are, so it can
/// never lock someone out of their own data. On a device without a screen
/// lock it stays off; the result says why.
Future<AppAuthResult> turnOnAppLock(WidgetRef ref, String reason) async {
  if (!await ref.read(appAuthenticatorProvider).isAvailable()) return AppAuthResult.noScreenLock;
  final result = await ref.read(appLockProvider.notifier).authenticate(reason);
  if (result == AppAuthResult.unlocked) await ref.read(appLockSettingsProvider.notifier).setEnabled(true);
  return result;
}

/// Settings > App lock: the switch, how soon it locks again, and (Android)
/// hiding Hisab in the recent-apps list.
class AppLockSettingsScreen extends ConsumerWidget {
  const AppLockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(appLockSettingsProvider);
    final notifier = ref.read(appLockSettingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appLockTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Column(children: [
              SwitchListTile(
                key: const Key('appLockSwitch'),
                secondary: const Icon(Icons.lock_outline),
                title: Text(l10n.appLockSwitch),
                subtitle: Text(l10n.appLockSwitchHelp),
                value: settings.enabled,
                onChanged: (on) => on ? _turnOn(context, ref) : notifier.setEnabled(false),
              ),
              if (settings.enabled) ...[
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(l10n.appLockAfter),
                  visualDensity: VisualDensity.compact,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SegmentedButton<AppLockTimeout>(
                    key: const Key('appLockTimeout'),
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                    segments: [
                      for (final timeout in AppLockTimeout.values)
                        ButtonSegment(value: timeout, label: Text(_timeoutSegmentLabel(l10n, timeout), maxLines: 1, softWrap: false)),
                    ],
                    selected: {settings.timeout},
                    onSelectionChanged: (set) => notifier.setTimeout(set.first),
                  ),
                ),
              ],
            ]),
          ),
          if (settings.enabled && ref.watch(secureWindowChannelProvider).isSupported)
            Card(
              child: SwitchListTile(
                key: const Key('appLockHideInRecents'),
                secondary: const Icon(Icons.visibility_off_outlined),
                title: Text(l10n.appLockHideInRecents),
                subtitle: Text(l10n.appLockHideInRecentsHelp),
                value: settings.hideInRecents,
                onChanged: notifier.setHideInRecents,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _turnOn(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = await turnOnAppLock(ref, l10n.appLockEnableReason);
    final note = switch (result) {
      AppAuthResult.noScreenLock => l10n.appLockNoScreenLock,
      AppAuthResult.lockedOut => l10n.appLockLockedOut,
      _ => null,
    };
    if (note != null) showTimedSnackBar(messenger, note);
  }
}

/// Settings row: "Off", or "On, locks after 1 minute".
class AppLockSettingsTile extends ConsumerWidget {
  const AppLockSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(appLockSettingsProvider);
    return ListTile(
      key: const Key('settingsAppLock'),
      leading: const Icon(Icons.fingerprint),
      title: Text(l10n.appLockTitle),
      subtitle: Text(settings.enabled ? l10n.appLockOnSummary(appLockTimeoutLabel(l10n, settings.timeout)) : l10n.appLockSettingsHint),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(kAppLockLocation),
    );
  }
}
