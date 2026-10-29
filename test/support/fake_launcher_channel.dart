import 'package:hisab/data/launcher/launcher_channel.dart';
import 'package:hisab/domain/launcher/quick_entry_shortcuts.dart';

/// Android as far as the app can tell, without a platform: records what
/// would reach the launcher and turns down every system request.
class FakeLauncherChannel extends LauncherChannel {
  final shortcuts = <List<LauncherShortcut>>[];
  final widgets = <Map<String, Object>>[];
  final notifications = <Map<String, Object>>[];

  @override
  bool get isSupported => true;

  @override
  Future<void> setQuickEntryShortcuts(List<LauncherShortcut> shortcuts) async => this.shortcuts.add(shortcuts);

  @override
  Future<void> updateSpendWidget(Map<String, Object> data) async => widgets.add(data);

  @override
  Future<void> setAddExpenseNotification(AddExpenseNotificationConfig config) async => notifications.add(config.toMap());

  @override
  Future<bool> requestAddTile() async => false;

  @override
  Future<bool> requestPinWidget() async => false;
}
