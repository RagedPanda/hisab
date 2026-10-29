import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/domain/sms/sms_outcome.dart';
import 'package:hisab/features/sms/sms_auto_add_snackbar.dart';

import '../support/app_harness.dart';

const _upiDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';
const _atmDebit = 'Rs.4,000.00 withdrawn from A/c XX1234 at ATM on 21-10-26. Avl bal Rs.11,541.00';

Future<void> _autoAdd(WidgetTester tester, ProviderContainer container, String body, DateTime receivedAt) =>
    tester.runAsync(() => container.read(smsIngestServiceProvider).ingest(RawSms(sender: 'VM-HDFCBK', body: body, receivedAt: receivedAt), autoAdd: true));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a burst of automatic adds shares one snackbar whose Undo reverts them all', (tester) async {
    final container = await createContainer();
    await pumpScreen(tester, container, const SmsAutoAddSnackbar(child: Scaffold(body: Text('Home'))));
    final day = DateTime(2026, 10, 21, 9);
    await _autoAdd(tester, container, _upiDebit, day);
    await _autoAdd(tester, container, _atmDebit, day.add(const Duration(hours: 1)));
    await tester.pump(kSmsAutoAddBatchWindow);
    await tester.pump();
    expect(find.text('Added 2 entries from SMS'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await pumpWithDatabase(tester);
    final database = container.read(databaseProvider);
    final logs = (await tester.runAsync(() => database.select(database.smsLog).get()))!;
    // undoAutoAdd stores the message as ignored, never as SmsLogStatus.undone.
    expect(logs.map((log) => log.status), everyElement(SmsLogStatus.ignored));
    final entries = (await tester.runAsync(() => database.select(database.entries).get()))!;
    expect(entries, hasLength(2));
    expect(entries.map((entry) => entry.deletedAt), everyElement(isNotNull), reason: 'both auto-added entries are deleted');
  });
}
