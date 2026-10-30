/// Names of Hisab backup files, shared by the manual export and the
/// scheduled folder backup, and the rule for which old ones to prune.
library;

const kBackupFilePrefix = 'hisab-backup-';
const kBackupFileExtension = '.hisab';

/// Exact shape of a name [backupFileName] makes. Only files matching it are
/// ever pruned, so nothing else in the user's folder is touched.
final _timestampedBackupName = RegExp(r'^hisab-backup-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.hisab$');

/// `hisab-backup-2026-10-30T09-15-00.hisab` for [at]: local time to the
/// second, with no characters a file system might refuse. Names sort in
/// time order.
String backupFileName(DateTime at) {
  final stamp = at.toIso8601String().replaceAll(':', '-').split('.').first;
  return '$kBackupFilePrefix$stamp$kBackupFileExtension';
}

/// Whether [name] is a backup file Hisab wrote with [backupFileName].
bool isHisabBackupName(String name) => _timestampedBackupName.hasMatch(name);

/// The Hisab backups among [names] beyond the newest [keep], oldest last.
/// Other files are never included. [keep] below 1 is treated as 1, so the
/// backup just written always survives.
List<String> backupsToPrune(Iterable<String> names, {required int keep}) {
  final backups = names.where(isHisabBackupName).toSet().toList()..sort((a, b) => b.compareTo(a));
  final kept = keep < 1 ? 1 : keep;
  return backups.length <= kept ? const [] : backups.sublist(kept);
}
