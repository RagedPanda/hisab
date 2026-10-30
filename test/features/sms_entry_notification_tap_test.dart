import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/notification_gateway.dart';
import 'package:hisab/core/notifications/sms_entry_payload.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/domain/sms/sms_outcome.dart';
import 'package:hisab/features/reminders/reminder_startup.dart';
import 'package:hisab/features/shell/router.dart';

import '../core/fake_notification_gateway.dart';
import '../support/app_harness.dart' show pumpApp, pumpWithDatabase, settle;

// Synthetic message only.
const _swiggyDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';

String _location() => appRouter.state.uri.toString();

/// The real app with one SMS already auto-added; seeded before the first
/// frame, while no query is in flight.
Future<(ProviderContainer, SmsEntryRef)> _appWithSmsEntry(WidgetTester tester) async {
  late SmsEntryRef added;
  final container = await pumpApp(
    tester,
    overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())],
    seed: (container) async {
      await container.read(smsIngestServiceProvider).ingest(RawSms(sender: 'VM-HDFCBK', body: _swiggyDebit, receivedAt: DateTime(2026, 10, 21, 10)), autoAdd: true);
      final database = container.read(databaseProvider);
      final row = await (database.select(database.smsLog)..where((log) => log.status.equals(SmsLogStatus.added))).getSingle();
      added = (smsId: row.id, entryId: row.entryId!);
    },
  );
  return (container, added);
}

NotificationTap _tap(SmsEntryRef added, {String? actionId}) =>
    NotificationTap(payload: smsEntryPayload(smsId: added.smsId, entryId: added.entryId), actionId: actionId);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('tapping the notification opens the entry', (tester) async {
    final (container, added) = await _appWithSmsEntry(tester);

    await handleReminderTap(container, _tap(added));
    await settle(tester);

    expect(_location(), '/entry?id=${added.entryId}');
  });

  testWidgets('Change category opens the picker and saves the pick on the entry', (tester) async {
    final (container, added) = await _appWithSmsEntry(tester);

    await handleReminderTap(container, _tap(added, actionId: kSmsChangeCategoryActionId));
    await settle(tester);
    await pumpWithDatabase(tester, 12);
    expect(_location(), startsWith(kSmsEntryCategoryRoute));
    expect(find.byType(BottomSheet), findsOneWidget, reason: 'the picker opens straight away');

    final sheet = find.byType(BottomSheet);
    await tester.enterText(find.descendant(of: sheet, matching: find.byType(TextField)), 'Shopping');
    await tester.pump();
    await tester.tap(find.descendant(of: sheet, matching: find.widgetWithText(ListTile, 'Shopping')).first);
    await pumpWithDatabase(tester, 12);

    final details = await tester.runAsync(() => container.read(entriesRepositoryProvider).getEntry(added.entryId));
    expect(details!.category?.name, 'Shopping');
    expect(_location(), isNot(startsWith(kSmsEntryCategoryRoute)), reason: 'the screen closes once saved');
  });

  testWidgets('Undo delivered to the open app deletes the entry and opens nothing', (tester) async {
    final (container, added) = await _appWithSmsEntry(tester);

    final undone = handleReminderTap(container, _tap(added, actionId: kSmsUndoActionId));
    await pumpWithDatabase(tester, 12);
    await undone;

    expect(_location(), '/home');
    final database = container.read(databaseProvider);
    final entry = await tester.runAsync(() => (database.select(database.entries)..where((row) => row.id.equals(added.entryId))).getSingle());
    expect(entry!.deletedAt, isNotNull);
  });
}
