import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_lock/device_authenticator.dart';
import '../../domain/app_lock/app_lock_policy.dart';
import '../../l10n/l10n.dart';
import 'app_lock_providers.dart';

/// Covers the whole app with the lock screen while the app lock is locked,
/// and with a plain cover while Hisab is in the background, so neither the
/// screen nor the recent-apps switcher shows any figures.
///
/// The app underneath stays alive: a deep link, shortcut, tile or
/// notification tap still moves the router while locked, and the
/// destination shows once the user unlocks. Unsaved input survives a lock.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child, this.isIOS});

  final Widget child;

  /// Overrides the platform check for the recent-apps cover in tests.
  final bool? isIOS;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;
  AppLifecycleState? _state = WidgetsBinding.instance.lifecycleState;

  /// The prompt to show once the app is in front: on a cold start, and on
  /// coming back after the timeout.
  bool _promptPending = false;
  AppAuthResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _promptPending = ref.read(appLockedProvider);
    _lifecycle = AppLifecycleListener(onStateChange: _onStateChange);
    ref.listenManual(appLockSettingsProvider.select((settings) => settings.secureWindow), (_, secure) {
      ref.read(secureWindowChannelProvider).setSecure(secure).ignore();
    }, fireImmediately: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptIfInFront());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onStateChange(AppLifecycleState state) {
    final cameBackLocked = ref.read(appLockProvider.notifier).onLifecycle(state);
    setState(() {
      _state = state;
      if (cameBackLocked) {
        _promptPending = true;
        _lastResult = null;
      }
    });
    _promptIfInFront();
  }

  void _promptIfInFront() {
    if (!mounted || !_promptPending || _state != AppLifecycleState.resumed) return;
    _promptPending = false;
    _unlock();
  }

  Future<void> _unlock() async {
    if (!ref.read(appLockedProvider)) return;
    final result = await ref.read(appLockProvider.notifier).unlock(context.l10n.appLockPromptReason);
    if (mounted) setState(() => _lastResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockedProvider);
    final enabled = ref.watch(appLockSettingsProvider.select((settings) => settings.enabled));
    final state = _state;
    final covered = enabled && state != null && coversContent(state, isIOS: widget.isIOS ?? Platform.isIOS);
    final hidden = locked || covered;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: hidden,
          child: TickerMode(
            enabled: !hidden,
            // No field underneath may take focus (and raise the keypad)
            // while the lock screen is up.
            child: ExcludeFocus(excluding: locked, child: widget.child),
          ),
        ),
        if (hidden) AppLockScreen(onUnlock: locked ? _unlock : null, result: _lastResult),
      ],
    );
  }
}

/// What the user sees while Hisab is locked: the unlock button, and why the
/// last try did not unlock. Without [onUnlock] it is the plain background
/// cover.
class AppLockScreen extends StatelessWidget {
  const AppLockScreen({super.key, this.onUnlock, this.result});

  final VoidCallback? onUnlock;
  final AppAuthResult? result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final message = switch (result) {
      AppAuthResult.lockedOut => l10n.appLockLockedOut,
      _ => null,
    };
    return Material(
      key: const Key('appLockScreen'),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(l10n.appLockLockedTitle, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                if (onUnlock != null) ...[
                  const SizedBox(height: 8),
                  Text(message ?? l10n.appLockLockedHint, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('appLockUnlock'),
                    onPressed: onUnlock,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l10n.appLockUnlock),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
