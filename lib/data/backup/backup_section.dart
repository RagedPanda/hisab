/// A block of settings kept outside the database (shared preferences) that
/// still travels in backups under its own [key]. Backups made before a
/// section existed simply lack the key and restore without it.
abstract interface class BackupSection {
  /// Top-level key in the backup payload.
  String get key;

  /// The block to store, or null to leave the key out.
  Map<String, dynamic>? export();

  /// Applies a backup's block with the same newer-wins rule as rows and
  /// returns how many records it wrote.
  Future<int> restore(Map<String, dynamic> json);
}
