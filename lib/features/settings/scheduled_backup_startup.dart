import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'scheduled_backup_providers.dart';

/// Runs a due scheduled backup when the app starts and each time it returns
/// to the foreground, and keeps the Android background job in step. The
/// background job writes prefs from another engine, so they are reloaded
/// first to see its result. Never throws.
Future<void> startScheduledBackups(ProviderContainer container) async {
  Future<void> runIfDue() async {
    try {
      await container.read(sharedPreferencesProvider).reload();
      container.read(scheduledBackupHistoryProvider.notifier).reload();
      await container.read(scheduledBackupGateProvider).runDue(DateTime.now());
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'backup', context: ErrorDescription('running a due scheduled backup')));
    }
  }

  _resumeListener ??= AppLifecycleListener(onResume: runIfDue);
  try {
    await container.read(scheduledBackupChoicesProvider.notifier).syncBackgroundJob();
  } catch (error, stack) {
    FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'backup', context: ErrorDescription('scheduling the background backup')));
  }
  await runIfDue();
}

AppLifecycleListener? _resumeListener;
