import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/launcher/launcher_channel.dart';
import '../../domain/launcher/quick_entry_shortcuts.dart';

/// Platform access for [LauncherSync]; tests override it with a fake.
final launcherChannelProvider = Provider<LauncherChannel>((ref) => const LauncherChannel());

/// The launcher shortcuts for the current quick entries, amounts in the
/// home format; null until the quick entries have loaded, so a cold start
/// never clears the shortcuts before the database has answered.
final quickEntryShortcutsProvider = Provider<List<LauncherShortcut>?>((ref) {
  final moneyFormat = ref.watch(homeMoneyFormatProvider);
  final quickEntries = ref.watch(quickEntriesProvider).value;
  if (quickEntries == null) return null;
  return quickEntryShortcuts([
    for (final quick in quickEntries)
      (
        id: quick.id,
        label: quick.label,
        amountText: quick.amountMinor == null ? null : formatMinor(quick.amountMinor!, format: moneyFormat, showDecimals: false),
      ),
  ]);
});

/// Keeps what Hisab shows outside the app in step with its data: the
/// quick-entry launcher shortcuts. Sends only when something changed.
class LauncherSync extends ConsumerStatefulWidget {
  const LauncherSync({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LauncherSync> createState() => _LauncherSyncState();
}

class _LauncherSyncState extends ConsumerState<LauncherSync> {
  List<LauncherShortcut>? _sentShortcuts;

  @override
  void initState() {
    super.initState();
    if (!ref.read(launcherChannelProvider).isSupported) return;
    ref.listenManual(quickEntryShortcutsProvider, (_, shortcuts) => _sendShortcuts(shortcuts), fireImmediately: true);
  }

  void _sendShortcuts(List<LauncherShortcut>? shortcuts) {
    if (shortcuts == null || listEquals(shortcuts, _sentShortcuts)) return;
    _sentShortcuts = shortcuts;
    unawaited(ref.read(launcherChannelProvider).setQuickEntryShortcuts(shortcuts));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
