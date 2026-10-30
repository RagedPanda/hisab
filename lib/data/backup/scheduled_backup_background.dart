import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import 'app_backup_service.dart';
import 'scheduled_backup_channel.dart';
import 'scheduled_backup_runner.dart';

/// Body of the Android background job (ScheduledBackupJob.kt starts a
/// headless engine at `scheduledBackupMain` in main.dart). Writes the folder
/// backup if it is due, then tells the job it is done. Drive is left to the
/// next app open: a Google sign-in may need a screen. Never throws.
Future<void> runScheduledBackupInBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  const channel = ScheduledBackupChannel();
  AppDatabase? db;
  try {
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase();
    final runner = ScheduledBackupRunner(backups: appBackupService(db, prefs), folder: channel, vault: channel, prefs: prefs);
    await runner.runDue(DateTime.now());
  } catch (error, stack) {
    FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'backup', context: ErrorDescription('running the scheduled backup in the background')));
  } finally {
    await db?.close();
    await channel.finishBackgroundRun();
  }
}
