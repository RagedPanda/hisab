/// When a scheduled backup is due. Pure: the caller passes the clock.
library;

import '../cards/card_cycle.dart';

/// How often the scheduled backup runs. [off] is the default.
enum BackupFrequency {
  off,
  daily,
  weekly,
  monthly;

  String get storageKey => name;

  static BackupFrequency fromStorageKey(String? key) => values.firstWhere((value) => value.name == key, orElse: () => off);
}

/// How long to wait after a failed attempt before trying again on its own,
/// so an offline phone does not retry on every app resume.
const kBackupRetryGap = Duration(hours: 1);

/// Backups kept in the chosen folder unless the user picks another number.
const kDefaultBackupsKept = 5;

/// Choices offered for how many folder backups to keep.
const kBackupsKeptChoices = [3, 5, 10, 20];

/// When the next backup falls due after one that succeeded at [lastSuccess]:
/// the start of the next calendar day, a week later, or the same day next
/// month (clamped to short months). Null when [frequency] is off. With no
/// successful backup yet it is due straight away ([DateTime] zero).
DateTime? nextBackupDue(BackupFrequency frequency, DateTime? lastSuccess) {
  if (frequency == BackupFrequency.off) return null;
  if (lastSuccess == null) return DateTime.fromMillisecondsSinceEpoch(0);
  final last = lastSuccess.toLocal();
  return switch (frequency) {
    BackupFrequency.daily => DateTime(last.year, last.month, last.day + 1),
    BackupFrequency.weekly => DateTime(last.year, last.month, last.day + 7),
    BackupFrequency.monthly => clampedMonthDay(last.year, last.month + 1, last.day),
    BackupFrequency.off => null,
  };
}

/// Whether a scheduled backup should run at [now]: on a schedule, past the
/// due time, and not within [kBackupRetryGap] of the last attempt (which
/// may have failed).
bool isBackupDue({required BackupFrequency frequency, required DateTime? lastSuccess, DateTime? lastAttempt, required DateTime now}) {
  final due = nextBackupDue(frequency, lastSuccess);
  if (due == null || now.isBefore(due)) return false;
  if (lastAttempt != null && (lastSuccess == null || lastAttempt.isAfter(lastSuccess))) {
    return !now.isBefore(lastAttempt.add(kBackupRetryGap));
  }
  return true;
}
