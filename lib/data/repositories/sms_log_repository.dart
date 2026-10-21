import 'dart:convert';

import 'package:crypto/crypto.dart' show sha1;
import 'package:drift/drift.dart';

import '../db/database.dart';

class SmsLogRepository {
  SmsLogRepository(this.db);
  final AppDatabase db;

  static String idFor(String sender, String body, DateTime receivedAt) =>
      sha1.convert(utf8.encode('$sender|$body|${receivedAt.millisecondsSinceEpoch ~/ 60000}')).toString();

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
        ..where((t) => t.status.equals('pending'))
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
      .watch();

  Stream<List<SmsLogData>> watchRecent({int limit = 100}) => (db.select(db.smsLog)
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)])
        ..limit(limit))
      .watch();

  Future<void> setStatus(String id, String status, {String? entryId}) =>
      (db.update(db.smsLog)..where((t) => t.id.equals(id)))
          .write(SmsLogCompanion(status: Value(status), entryId: Value(entryId)));

  Future<DateTime?> latestReceivedAt() async {
    final max = db.smsLog.receivedAt.max();
    final row = await (db.selectOnly(db.smsLog)..addColumns([max])).getSingle();
    return row.read(max);
  }
}
