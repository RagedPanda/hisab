import '../db/database.dart';

/// A block of settings kept outside the database (shared preferences) that
/// still travels in backups under its own [key]. Backups made before a
/// section existed simply lack the key and restore without it.
abstract interface class BackupSection {
  /// Top-level key in the backup payload.
  String get key;

  /// The block to store, or null to leave the key out.
  Map<String, dynamic>? export();

  /// Applies a backup's block and returns how many records it wrote. Runs
  /// after the rows are restored into [db]; [payload] is the whole backup,
  /// for a block that must stay in step with its rows.
  Future<int> restore(Map<String, dynamic> json, {required AppDatabase db, required Map<String, dynamic> payload});
}
