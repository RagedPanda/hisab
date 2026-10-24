import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';

void main() {
  late AppDatabase db;
  late SmsLogRepository smsLog;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    smsLog = SmsLogRepository(db);
  });

  tearDown(() => db.close());

  Future<void> logSms(String id) =>
      smsLog.record(id: id, sender: 'HDFCBK', body: 'Rs 1500 debited $id', receivedAt: DateTime(2026, 11, 5), status: 'added');

  test('a logged SMS starts unmatched and keeps the reminder it is linked to', () async {
    await logSms('s1');
    expect((await smsLog.getById('s1'))!.matchedReminderId, isNull);

    await smsLog.setMatchedReminder('s1', 'r1');
    final row = await smsLog.getById('s1');
    expect(row!.matchedReminderId, 'r1');
    expect(row.status, 'added', reason: 'linking leaves the status alone');
  });

  test('matchedReminderIds lists every reminder some SMS has paid', () async {
    await logSms('s1');
    await logSms('s2');
    await logSms('s3');
    expect(await smsLog.matchedReminderIds(), isEmpty);

    await smsLog.setMatchedReminder('s1', 'r1');
    await smsLog.setMatchedReminder('s3', 'r2');
    expect(await smsLog.matchedReminderIds(), {'r1', 'r2'});
  });
}
