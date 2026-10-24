import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';

void main() {
  test('foreign-currency rows already in the queue are left out of review', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final smsLog = SmsLogRepository(db);
    final received = DateTime(2026, 10, 21, 10);
    await smsLog.record(id: 'usd', sender: 'VM-HDFCBK', body: 'USD 25.00 spent on Card XX1234 at AMAZON US', receivedAt: received, status: 'pending');
    await smsLog.record(id: 'inr', sender: 'VM-HDFCBK', body: 'Rs.459.00 debited from A/c XX1234', receivedAt: received, status: 'pending');
    await smsLog.record(id: 'bare', sender: 'VM-HDFCBK', body: 'A/c XX1234: transaction of 1,200.00 on 21-10-26', receivedAt: received, status: 'pending');

    // Listened to, as Home does, so the provider is not paused.
    final subscription = container.listen(pendingSmsProvider.future, (_, _) {});
    final pending = await subscription.read();

    expect(pending.map((row) => row.id), unorderedEquals(['inr', 'bare']));
  });
}
