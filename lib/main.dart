import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'data/db/database.dart';
import 'data/debug/demo_seed.dart';
import 'data/settings/currency_migration.dart';
import 'features/reminders/reminder_startup.dart';

/// Debug/profile builds started with `--dart-define=HISAB_SEED_ENTRIES=300`
/// fill the database with that many demo entries once; release ignores it.
const int kSeedEntryCount = int.fromEnvironment('HISAB_SEED_ENTRIES');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();
  if (!kReleaseMode && kSeedEntryCount > 0) await seedDemoData(db, entryCount: kSeedEntryCount);
  await migrateCurrencySetting(prefs, db);
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(db)],
  );
  runApp(UncontrolledProviderScope(container: container, child: const HisabApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) => startReminderNotifications(container));
}
