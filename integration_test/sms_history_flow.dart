import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/data/sms/sms_ingest_service.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:hisab/l10n/generated/app_localizations_hi.dart';

import 'harness.dart';

const _upiDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';
const _atmDebit = 'Rs.4,000.00 withdrawn from A/c XX1234 at ATM on 21-10-26. Avl bal Rs.11,541.00';
const _statement = 'Your HDFC Bank credit card statement for October is now available on NetBanking.';

/// Seeds one message per outcome, then exercises Settings > Bank SMS >
/// History: outcome chips, filtering, re-processing, the entry link, Hindi,
/// dark theme and clearing behind a confirmation.
Future<void> smsHistoryFlow(WidgetTester tester) async {
  final fresh = await createApp();
  addTearDown(fresh.container.dispose);
  final hi = AppLocalizationsHi();
  final service = fresh.read(smsIngestServiceProvider);
  final start = DateTime.now().subtract(const Duration(days: 1));
  final day = DateTime(start.year, start.month, start.day, 9);
  Future<IngestStatus> ingest(String sender, String body, Duration after, {bool autoAdd = false}) => service.ingest(
    RawSms(sender: sender, body: body, receivedAt: day.add(after)),
    autoAdd: autoAdd,
  );
  expect(await ingest('VM-HDFCBK', _upiDebit, Duration.zero, autoAdd: true), IngestStatus.added);
  expect(await ingest('VM-HDFCBK', _upiDebit, const Duration(minutes: 40), autoAdd: true), IngestStatus.duplicate);
  expect(await ingest('VM-HDFCBK', _atmDebit, const Duration(hours: 2)), IngestStatus.pending);
  expect(await ingest('AMAZON', 'Your order of 2 items has shipped and arrives tomorrow.', const Duration(hours: 3)), IngestStatus.notBank);
  expect(await ingest('VM-HDFCBK', _statement, const Duration(hours: 4)), IngestStatus.unparsed);

  // The chip strip builds lazily, so a chip off to the right is not in the
  // tree until the strip is scrolled to it.
  final chipStrip = find.descendant(of: find.byType(ChipRow), matching: find.byType(Scrollable));
  Future<Finder> chip(String label) async {
    await tester.drag(chipStrip, const Offset(2000, 0));
    await settle(tester, 3);
    final target = find.text(label);
    await tester.scrollUntilVisible(target, 120, scrollable: chipStrip, maxScrolls: 20);
    await settle(tester, 2);
    return target;
  }

  Future<void> tapChip(String label) async => tapFinder(tester, await chip(label));

  await pumpApp(tester, fresh);
  await goTab(tester, 'Settings');
  await tapText(tester, 'Bank SMS');
  await tapText(tester, 'SMS history');
  for (final label in ['Added 1', 'Duplicate 1', 'Ignored 1', 'Unreadable 1', 'Pending 1']) {
    expect(await chip(label), findsOneWidget, reason: label);
  }
  expect(find.textContaining('Undone'), findsNothing, reason: 'the undone chip appears once something was undone');
  await chip('All');
  expect(find.text('Not a bank message'), findsOneWidget);
  expect(find.text('Open entry'), findsNWidgets(2), reason: 'the added message and its duplicate both link the entry');
  await shoot(tester, 'sms_history');

  await tapChip('Unreadable 1');
  expect(find.text('No transaction found in the text'), findsOneWidget);
  expect(find.text('Process again'), findsOneWidget);
  expect(find.text('Not a bank message'), findsNothing);
  await shoot(tester, 'sms_history_unreadable');

  await tapText(tester, 'Process again', frames: 10);
  expect(find.text('Could not find a transaction in that text.'), findsOneWidget);
  expect(await chip('Unreadable 1'), findsOneWidget, reason: 'the forced parse found nothing either');

  await tapChip('Ignored 1');
  expect(find.text('Not a bank message'), findsOneWidget);
  expect(find.text('Message text not kept'), findsOneWidget, reason: 'OTP and promo text is never stored');
  expect(find.text('Process again'), findsNothing, reason: 'nothing to process without the text');

  await tapChip('Added 1');
  await tapText(tester, 'Open entry', frames: 10);
  expect(find.byType(ExpenseEditorScreen), findsOneWidget);
  await goBack(tester);
  await tapChip('All');

  await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi', themeMode: ThemeMode.dark));
  await settle(tester, 10);
  expect(find.text(hi.smsHistoryTitle), findsOneWidget);
  expect(await chip('${hi.smsOutcomeAdded} 1'), findsOneWidget);
  await shoot(tester, 'hi_dark_sms_history');
  await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en', themeMode: ThemeMode.light));
  await settle(tester, 10);

  await tapFinder(tester, find.byKey(const ValueKey('smsHistoryClear')));
  expect(find.text('Clear SMS history?'), findsOneWidget);
  await shoot(tester, 'sms_history_clear_confirm');
  await tapFinder(tester, find.widgetWithText(FilledButton, 'Clear'), frames: 10);
  expect(find.text('SMS history cleared'), findsOneWidget);
  expect(await chip('Pending 1'), findsOneWidget, reason: 'messages waiting for review are not history');
  expect(await chip('Added 0'), findsOneWidget);
  expect(await fresh.db.select(fresh.db.entries).get(), hasLength(1), reason: 'clearing never deletes entries');
  await shoot(tester, 'sms_history_cleared');
  await goBack(tester);
  await goBack(tester);
}
