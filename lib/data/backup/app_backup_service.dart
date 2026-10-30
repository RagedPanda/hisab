import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../salary/salary_backup.dart';
import 'backup_service.dart';
import 'month_start_backup.dart';

/// The app's [BackupService] with every settings section it carries. Shared
/// by backupServiceProvider and the background backup job, so both write
/// the same file.
BackupService appBackupService(AppDatabase db, SharedPreferences prefs) => BackupService(db, sections: [
      MonthStartBackupSection(prefs),
      SalaryBackupSection(prefs),
    ]);
