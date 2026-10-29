import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/launcher/launcher_channel.dart';
import '../../domain/launcher/quick_entry_shortcuts.dart';
import '../../l10n/l10n.dart';
import 'shortcut_settings.dart';
import 'spend_widget_data.dart';

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

/// The persistent "Add expense" notification in the user's language.
AddExpenseNotificationConfig addExpenseNotificationConfig(AppLocalizations l10n, {required bool enabled}) => AddExpenseNotificationConfig(
      enabled: enabled,
      channelName: l10n.addExpenseNotificationChannel,
      title: l10n.addExpense,
      body: l10n.addExpenseNotificationBody,
    );

/// Keeps what Hisab shows outside the app in step with its data: the
/// quick-entry launcher shortcuts, the "Add expense" notification and the
/// Home-screen spend widget. Sends only when something changed.
class LauncherSync extends ConsumerStatefulWidget {
  const LauncherSync({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LauncherSync> createState() => _LauncherSyncState();
}

class _LauncherSyncState extends ConsumerState<LauncherSync> with WidgetsBindingObserver {
  List<LauncherShortcut>? _sentShortcuts;
  Map<String, Object>? _sentNotification;
  Map<String, Object>? _sentWidget;

  @override
  void initState() {
    super.initState();
    if (!ref.read(launcherChannelProvider).isSupported) return;
    ref.listenManual(quickEntryShortcutsProvider, (_, shortcuts) => _sendShortcuts(shortcuts), fireImmediately: true);
    ref.listenManual(shortcutSettingsProvider.select((settings) => settings.addExpenseNotification), (_, _) => _sendNotification());
    ref.listenManual(spendWidgetFiguresProvider, (_, _) => _sendWidget());
    ref.listenManual(shortcutSettingsProvider.select((settings) => settings.widgetOpacity), (_, _) => _sendWidget());
    ref.listenManual(homeMoneyFormatProvider, (_, _) => _sendWidget());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs first on start and again when the language changes.
    _sendNotification();
    _sendWidget();
  }

  // Back in the app, possibly in a new month: query the months again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(spendWidgetFiguresProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _sendWidget() {
    final channel = ref.read(launcherChannelProvider);
    final figures = ref.read(spendWidgetFiguresProvider).value;
    if (!channel.isSupported || figures == null || !mounted) return;
    final data = spendWidgetData(
      figures,
      l10n: context.l10n,
      moneyFormat: ref.read(homeMoneyFormatProvider),
      locale: Localizations.localeOf(context).toString(),
      opacity: ref.read(shortcutSettingsProvider).widgetOpacity,
    ).toMap();
    if (mapEquals(data, _sentWidget)) return;
    _sentWidget = data;
    unawaited(channel.updateSpendWidget(data));
  }

  void _sendNotification() {
    final channel = ref.read(launcherChannelProvider);
    if (!channel.isSupported) return;
    final config = addExpenseNotificationConfig(context.l10n, enabled: ref.read(shortcutSettingsProvider).addExpenseNotification);
    if (mapEquals(config.toMap(), _sentNotification)) return;
    _sentNotification = config.toMap();
    unawaited(channel.setAddExpenseNotification(config));
  }

  void _sendShortcuts(List<LauncherShortcut>? shortcuts) {
    if (shortcuts == null || listEquals(shortcuts, _sentShortcuts)) return;
    _sentShortcuts = shortcuts;
    unawaited(ref.read(launcherChannelProvider).setQuickEntryShortcuts(shortcuts));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
