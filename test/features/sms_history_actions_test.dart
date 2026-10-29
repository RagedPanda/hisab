import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/domain/sms/sms_outcome.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:hisab/features/sms/sms_history_screen.dart';

import '../support/app_harness.dart';

const _upiDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';

/// A history holding one auto-added message, already on screen.
Future<ProviderContainer> _pumpOneAdded(WidgetTester tester) async {
  final container = await createContainer();
  await tester.runAsync(() => container.read(smsIngestServiceProvider).ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: DateTime(2026, 10, 21, 9)), autoAdd: true));
  await pumpScreen(tester, container, const SmsHistoryScreen());
  await pumpWithDatabase(tester);
  return container;
}

Future<void> _tapAndWait(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await pumpWithDatabase(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('an added message opens its entry', (tester) async {
    final container = await _pumpOneAdded(tester);
    final log = (await tester.runAsync(() => container.read(databaseProvider).select(container.read(databaseProvider).smsLog).getSingle()))!;
    await _tapAndWait(tester, find.text('Open entry'));
    expect(find.text(openedLocation('/entry?id=${log.entryId}')), findsOneWidget);
  });

  testWidgets('an outcome with no messages shows the filtered empty state', (tester) async {
    await _pumpOneAdded(tester);
    await _tapAndWait(tester, find.text('Duplicate 0'));
    expect(find.text('No messages with this outcome'), findsOneWidget);
    expect(find.text('Open entry'), findsNothing);
  });

  testWidgets('clearing history asks first and confirms when done', (tester) async {
    await _pumpOneAdded(tester);

    await _tapAndWait(tester, find.byTooltip('Clear history'));
    expect(find.text('Clear SMS history?'), findsOneWidget);
    await _tapAndWait(tester, find.text('Cancel'));
    expect(find.text('SMS history cleared'), findsNothing, reason: 'cancelling keeps the history');

    await _tapAndWait(tester, find.byTooltip('Clear history'));
    await _tapAndWait(tester, find.widgetWithText(FilledButton, 'Clear'));
    expect(find.text('SMS history cleared'), findsOneWidget);
  });

  testWidgets('an undone message gets its own chip and label', (tester) async {
    final container = await createContainer();
    final service = container.read(smsIngestServiceProvider);
    await tester.runAsync(() => service.ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: DateTime(2026, 10, 21, 9)), autoAdd: true));
    final database = container.read(databaseProvider);
    final log = (await tester.runAsync(() => database.select(database.smsLog).getSingle()))!;
    // Production never writes this status today (undo stores ignored), so it is set directly.
    await tester.runAsync(() => container.read(smsLogRepositoryProvider).setStatus(log.id, SmsLogStatus.undone));
    await pumpScreen(tester, container, const SmsHistoryScreen());
    await pumpWithDatabase(tester);

    // The chip strip builds lazily, so it is scrolled to the undone chip at its end.
    final strip = find.descendant(of: find.byType(ChipRow), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('Undone 1'), 200, scrollable: strip);
    expect(find.text('Undone 1'), findsOneWidget);
    expect(find.text('Undone'), findsOneWidget);
  });
}
