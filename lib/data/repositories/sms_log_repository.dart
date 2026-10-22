import 'dart:convert';

import 'package:crypto/crypto.dart' show sha1;
import 'package:drift/drift.dart';

import '../../domain/sms/sms_outcome.dart';
import '../db/database.dart';

/// One history row with whether the entry it points at still exists.
typedef SmsHistoryRow = ({SmsLogData log, bool hasEntry});

class SmsLogRepository {
  SmsLogRepository(this.db);
  final AppDatabase db;

  /// Stable id for a message. Banks re-send the same text within a day
  /// (retries, gateway duplicates), so the bucket is the calendar day, not
  /// the minute it arrived.
  static String idFor(String sender, String body, DateTime receivedAt) =>
      sha1.convert(utf8.encode('$sender|${body.trim()}|${receivedAt.year}-${receivedAt.month}-${receivedAt.day}')).toString();

  /// Id for a bank re-delivery of the message [originalId] at [receivedAt],
  /// so each re-delivery gets its own history row.
  static String duplicateIdFor(String originalId, DateTime receivedAt) =>
      sha1.convert(utf8.encode('$originalId|duplicate|${receivedAt.millisecondsSinceEpoch ~/ 1000}')).toString();

  Future<SmsLogData?> getById(String id) => (db.select(db.smsLog)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> exists(String id) async =>
      (await (db.select(db.smsLog)..where((t) => t.id.equals(id))).getSingleOrNull()) != null;

  Future<void> record({
    required String id,
    required String sender,
    required String body,
    required DateTime receivedAt,
    required String status,
    Map<String, dynamic>? parsed,
    String? entryId,
  }) =>
      db.into(db.smsLog).insertOnConflictUpdate(SmsLogCompanion.insert(
            id: id,
            sender: sender,
            body: body,
            receivedAt: receivedAt,
            status: status,
            parsedJson: Value(parsed == null ? null : jsonEncode(parsed)),
            entryId: Value(entryId),
          ));

  Stream<List<SmsLogData>> watchPending() => (db.select(db.smsLog)
        ..where((t) => t.status.equals(SmsLogStatus.pending))
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
      .watch();

  Stream<List<SmsLogData>> watchRecent({int limit = 100}) => (db.select(db.smsLog)
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)])
        ..limit(limit))
      .watch();

  /// Every processed message not yet cleared, newest first, with whether its
  /// entry still exists (it may have been deleted since).
  Stream<List<SmsHistoryRow>> watchHistory() {
    final linkedEntry = db.entries.id.equalsExp(db.smsLog.entryId) & db.entries.deletedAt.isNull();
    final query = db.select(db.smsLog).join([leftOuterJoin(db.entries, linkedEntry, useColumns: false)])
      ..addColumns([db.entries.id])
      ..where(db.smsLog.clearedAt.isNull())
      ..orderBy([OrderingTerm.desc(db.smsLog.receivedAt)]);
    return query.watch().map((rows) => [
          for (final row in rows) (log: row.readTable(db.smsLog), hasEntry: row.read(db.entries.id) != null),
        ]);
  }

  Future<void> delete(String id) => (db.delete(db.smsLog)..where((t) => t.id.equals(id))).go();

  /// Hides every non-pending message from the history and wipes its text.
  /// The rows stay so the same SMS is still recognised as already processed;
  /// pending messages stay too, they are the review queue.
  Future<int> clearHistory({required DateTime now}) =>
      (db.update(db.smsLog)..where((t) => t.clearedAt.isNull() & t.status.equals(SmsLogStatus.pending).not()))
          .write(SmsLogCompanion(clearedAt: Value(now), body: const Value('')));

  Future<void> setStatus(String id, String status, {String? entryId}) =>
      (db.update(db.smsLog)..where((t) => t.id.equals(id)))
          .write(SmsLogCompanion(status: Value(status), entryId: Value(entryId)));

  Future<DateTime?> latestReceivedAt() async {
    final max = db.smsLog.receivedAt.max();
    final row = await (db.selectOnly(db.smsLog)..addColumns([max])).getSingle();
    return row.read(max);
  }
}
