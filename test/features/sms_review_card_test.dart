import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/sms/sms_outcome.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/features/sms/sms_review_screen.dart';

import '../support/app_harness.dart';

const _personDebit = 'Rs.500.00 debited from A/c XX1234 on 21-10-26 to rahul.sharma@okaxis (UPI Ref No 223456789012). Avl bal Rs.15,041.00';
const _salaryCredit = 'Rs.50,000.00 credited to A/c XX1234 on 21-10-26 by NEFT from ACME CORP. Avl bal Rs.65,041.00';
/// The test font is wider than real fonts; at 600dp the card's buttons fit.
const _wideScreen = Size(600, 932);
final _received =DateTime(2026, 10, 21, 9);

Future<void> _ingestPending(WidgetTester tester, ProviderContainer container, String body) =>
    tester.runAsync(() => container.read(smsIngestServiceProvider).ingest(RawSms(sender: 'VM-HDFCBK', body: body, receivedAt: _received), autoAdd: false));

/// A pending row written straight to the log, as an older app version or a
/// parser change can leave behind.
Future<void> _recordPending(WidgetTester tester, ProviderContainer container, {required String body, Map<String, dynamic>? parsed}) => tester.runAsync(
    () => container.read(smsLogRepositoryProvider).record(id: 'sms-1', sender: 'VM-HDFCBK', body: body, receivedAt: _received, status: SmsLogStatus.pending, parsed: parsed));

Future<SmsLogData?> _row(WidgetTester tester, ProviderContainer container, String id) => tester.runAsync<SmsLogData?>(() => container.read(smsLogRepositoryProvider).getById(id));

Future<List<SmsLogData>> _all(WidgetTester tester, ProviderContainer container) async {
  final db = container.read(databaseProvider);
  return (await tester.runAsync(() => db.select(db.smsLog).get()))!;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a new person paid over UPI is asked about once, and Add posts the entry', (tester) async {
    final container = await createContainer();
    await _ingestPending(tester, container, _personDebit);
    await pumpScreen(tester, container, const SmsReviewScreen(), size: _wideScreen);

    expect(find.textContaining('••1234'), findsOneWidget);
    expect(find.text('-₹500'), findsOneWidget, reason: 'a debit reads as an expense');
    final prompt = find.textContaining('New person. Pick a category once for');
    expect(prompt, findsOneWidget);

    await tester.tap(find.text('Pick category'));
    await pumpWithDatabase(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search categories'), 'Groceries');
    await tester.pump();
    await tester.tap(find.text('Groceries').last);
    await pumpWithDatabase(tester);
    expect(find.textContaining('Hisab will use Groceries for'), findsOneWidget);
    expect(prompt, findsNothing, reason: 'the person is not asked about again');
    expect(find.textContaining('Groceries ·'), findsOneWidget, reason: 'the card shows the remembered category');

    await tester.tap(find.text('Add ₹500'));
    await pumpWithDatabase(tester);
    final row = (await _all(tester, container)).single;
    expect(row.status, SmsLogStatus.added);
    expect(row.entryId, isNotNull);
    expect(find.text('Nothing waiting'), findsOneWidget);
  });

  testWidgets('dismissing the category picker remembers nothing', (tester) async {
    final container = await createContainer();
    await _ingestPending(tester, container, _personDebit);
    await pumpScreen(tester, container, const SmsReviewScreen(), size: _wideScreen);
    await tester.tap(find.text('Pick category'));
    await pumpWithDatabase(tester);
    await tester.tapAt(const Offset(10, 10));
    await pumpWithDatabase(tester);
    expect(find.textContaining('New person. Pick a category once for'), findsOneWidget);
  });

  testWidgets('a credit reads as income, Ignore drops it and Edit opens the editor with the SMS', (tester) async {
    final container = await createContainer();
    await _ingestPending(tester, container, _salaryCredit);
    final router = await pumpScreen(tester, container, const SmsReviewScreen(), size: _wideScreen);
    expect(find.text('+₹50,000'), findsOneWidget);

    final smsId = (await _all(tester, container)).single.id;
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text(openedLocation('/entry?sms=$smsId')), findsOneWidget);
    router.pop();
    await pumpWithDatabase(tester);

    await tester.tap(find.text('Ignore'));
    await pumpWithDatabase(tester);
    expect((await _row(tester, container, smsId))!.status, SmsLogStatus.ignored);
    expect(find.text('Nothing waiting'), findsOneWidget);
  });

  testWidgets('a message that could not be read offers only Add manually', (tester) async {
    final container = await createContainer();
    await _recordPending(tester, container, body: 'Your a/c was debited for an amount. Call us.');
    await pumpScreen(tester, container, const SmsReviewScreen(), size: _wideScreen);
    expect(find.textContaining('Could not read the amount'), findsOneWidget);
    expect(find.text('VM-HDFCBK'), findsOneWidget, reason: 'with no bank or payee read, the sender names the card');

    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();
    expect(find.text(openedLocation('/entry?sms=sms-1')), findsOneWidget);
  });

  testWidgets('Add that can no longer read the message points to Edit', (tester) async {
    final container = await createContainer();
    await _recordPending(tester, container, body: 'garbled', parsed: {'direction': 'debit', 'amountMinor': 25000, 'bank': 'HDFC', 'occurredAt': 'not a date'});
    await pumpScreen(tester, container, const SmsReviewScreen(), size: _wideScreen);
    expect(find.text('HDFC'), findsOneWidget);

    await tester.tap(find.text('Add ₹250'));
    await pumpWithDatabase(tester);
    expect(find.text('Could not add this one; use Edit'), findsOneWidget);
    expect((await _row(tester, container, 'sms-1'))!.status, SmsLogStatus.pending);
  });
}
