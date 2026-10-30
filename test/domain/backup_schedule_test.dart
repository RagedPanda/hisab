import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/backup/backup_file_name.dart';
import 'package:hisab/domain/backup/backup_schedule.dart';
import 'package:hisab/domain/backup/scheduled_backup.dart';

void main() {
  group('nextBackupDue', () {
    final last = DateTime(2026, 1, 31, 21, 40);

    test('off never falls due', () {
      expect(nextBackupDue(BackupFrequency.off, last), isNull);
      expect(isBackupDue(frequency: BackupFrequency.off, lastSuccess: null, now: DateTime(2026, 5)), isFalse);
    });

    test('is due straight away before the first backup', () {
      expect(isBackupDue(frequency: BackupFrequency.monthly, lastSuccess: null, now: DateTime(2026, 1, 1)), isTrue);
    });

    test('daily is due from the start of the next calendar day', () {
      expect(nextBackupDue(BackupFrequency.daily, last), DateTime(2026, 2, 1));
      expect(isBackupDue(frequency: BackupFrequency.daily, lastSuccess: last, now: DateTime(2026, 1, 31, 23, 59)), isFalse);
      expect(isBackupDue(frequency: BackupFrequency.daily, lastSuccess: last, now: DateTime(2026, 2, 1, 0, 1)), isTrue);
    });

    test('weekly is due seven calendar days on', () {
      expect(nextBackupDue(BackupFrequency.weekly, last), DateTime(2026, 2, 7));
    });

    test('monthly keeps the day, clamped to a short month', () {
      expect(nextBackupDue(BackupFrequency.monthly, last), DateTime(2026, 2, 28));
      expect(nextBackupDue(BackupFrequency.monthly, DateTime(2026, 12, 15)), DateTime(2027, 1, 15));
    });

    test('waits an hour after a failed attempt before trying again', () {
      final failedAt = DateTime(2026, 2, 3, 9);
      bool dueAt(DateTime now) => isBackupDue(frequency: BackupFrequency.daily, lastSuccess: last, lastAttempt: failedAt, now: now);
      expect(dueAt(DateTime(2026, 2, 3, 9, 30)), isFalse);
      expect(dueAt(DateTime(2026, 2, 3, 10)), isTrue);
    });

    test('an attempt that succeeded does not hold the next one back', () {
      expect(isBackupDue(frequency: BackupFrequency.daily, lastSuccess: last, lastAttempt: last, now: DateTime(2026, 2, 1, 0, 5)), isTrue);
    });
  });

  group('backup file names', () {
    test('match the manual export and sort in time order', () {
      final name = backupFileName(DateTime(2026, 10, 30, 9, 5, 7, 123));
      expect(name, 'hisab-backup-2026-10-30T09-05-07.hisab');
      expect(isHisabBackupName(name), isTrue);
      expect(isHisabBackupName('hisab-backup-2026-10-30T09-05-07 (1).hisab'), isFalse);
      expect(isHisabBackupName('notes.txt'), isFalse);
    });

    test('pruning keeps the newest and never touches other files', () {
      final names = [
        for (var day = 1; day <= 7; day++) backupFileName(DateTime(2026, 10, day)),
        'photo.jpg',
        'hisab-backup.hisab',
      ];
      final pruned = backupsToPrune(names, keep: 5);
      expect(pruned, [backupFileName(DateTime(2026, 10, 2)), backupFileName(DateTime(2026, 10, 1))]);
      expect(backupsToPrune(names, keep: 0), hasLength(6), reason: 'the newest always stays');
      expect(backupsToPrune(names, keep: 20), isEmpty);
    });
  });

  group('due targets', () {
    final now = DateTime(2026, 10, 30, 10);
    const daily = ScheduledBackupChoices(frequency: BackupFrequency.daily, folderUri: 'content://tree/backups', folderName: 'Backups');

    test('nothing while off', () {
      expect(dueBackupTargets(const ScheduledBackupChoices(), const ScheduledBackupHistory(), driveConnected: true, now: now), isEmpty);
    });

    test('the folder, and Drive only when included and connected', () {
      expect(dueBackupTargets(daily, const ScheduledBackupHistory(), driveConnected: true, now: now), {ScheduledBackupTarget.folder});
      final withDrive = daily.copyWith(includeDrive: true);
      expect(dueBackupTargets(withDrive, const ScheduledBackupHistory(), driveConnected: true, now: now), {ScheduledBackupTarget.folder, ScheduledBackupTarget.drive});
      expect(dueBackupTargets(withDrive, const ScheduledBackupHistory(), driveConnected: false, now: now), {ScheduledBackupTarget.folder});
    });

    test('each destination keeps its own schedule', () {
      final history = const ScheduledBackupHistory().record(ScheduledBackupTarget.folder, BackupAttempt(at: DateTime(2026, 10, 30, 8)));
      expect(dueBackupTargets(daily.copyWith(includeDrive: true), history, driveConnected: true, now: now), {ScheduledBackupTarget.drive});
    });

    test('with Drive as the only destination, a missing folder is not reported', () {
      const driveOnly = ScheduledBackupChoices(frequency: BackupFrequency.weekly, includeDrive: true);
      expect(dueBackupTargets(driveOnly, const ScheduledBackupHistory(), driveConnected: true, now: now), {ScheduledBackupTarget.drive});
      expect(dueBackupTargets(driveOnly, const ScheduledBackupHistory(), driveConnected: false, now: now), {ScheduledBackupTarget.folder});
    });
  });

  test('choices and history survive a round trip through JSON', () {
    const choices = ScheduledBackupChoices(frequency: BackupFrequency.monthly, folderUri: 'u', folderName: 'Backups', keep: 10, includeDrive: true);
    final restored = ScheduledBackupChoices.fromJson(choices.toJson());
    expect(restored.toJson(), choices.toJson());
    expect(ScheduledBackupChoices.fromJson('junk').frequency, BackupFrequency.off);
    expect(ScheduledBackupChoices.fromJson(const {'keep': -2}).keep, kDefaultBackupsKept);

    final history = const ScheduledBackupHistory()
        .record(ScheduledBackupTarget.folder, BackupAttempt(at: DateTime(2026, 10, 1), detail: 'a.hisab'))
        .record(ScheduledBackupTarget.folder, BackupAttempt(at: DateTime(2026, 10, 2), failure: ScheduledBackupFailure.folderUnavailable));
    final back = ScheduledBackupHistory.fromJson(history.toJson());
    expect(back.lastSuccess[ScheduledBackupTarget.folder]!.at, DateTime(2026, 10, 1));
    expect(back.lastAttempt[ScheduledBackupTarget.folder]!.failure, ScheduledBackupFailure.folderUnavailable);
    expect(back.lastAttempt[ScheduledBackupTarget.drive], isNull);
  });
}
