/// SMS auto-add tour in every locale and theme: a confident bank SMS is added
/// with an Undo snackbar, unclear ones land in the review queue, Home shows
/// the "N SMS to review" row and Entries marks SMS entries. Messages are fed
/// through the ingest service, so it runs on Android and iOS alike.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/sms_auto_add_test.dart -d emulator-5556
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/data/sms/sms_ingest_service.dart';
import 'package:hisab/features/dashboard/dashboard_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/features/sms/sms_review_screen.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

const _configs = [('en', ThemeMode.light), ('en', ThemeMode.dark), ('hi', ThemeMode.light), ('hi', ThemeMode.dark)];

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SMS auto-add, Undo, review queue and Home row in every locale and theme', (tester) async {
    final app = await createApp();
    await pumpApp(tester, app);
    final service = app.read(smsIngestServiceProvider);
    expect(app.read(settingsProvider).smsAutoAdd, isTrue, reason: 'auto-add is the default');

    for (final (index, (locale, mode)) in _configs.indexed) {
      await app.read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: locale, themeMode: mode));
      final tag = '${locale}_${mode.name}';
      final day = DateTime(2026, 10, 1 + index, 10);
      appRouter.go('/home');
      await settle(tester, 10);

      final added = await tester.runAsync(() => service.ingest(
            RawSms(sender: 'VM-HDFCBK', body: 'Rs.459.00 debited from A/c XX1234 on ${day.day}-10-26 to swiggy@ybl (UPI Ref No 12345678901$index). Avl bal Rs.15,541.00', receivedAt: day),
            autoAdd: app.read(settingsProvider).smsAutoAdd,
          ));
      expect(added, IngestStatus.added);
      await settle(tester, 10);
      expect(find.byType(SnackBar), findsOneWidget, reason: 'the open app offers Undo for an automatic add');
      await shoot(tester, 'sms_auto_added_snackbar_$tag');

      await tester.runAsync(() => service.ingest(RawSms(sender: 'PASTED', body: 'Paid Rs 250 to Ramesh on ${day.day}-10-26', receivedAt: day), autoAdd: true, force: true));
      await tester.runAsync(() => service.ingest(RawSms(sender: 'VM-ICICIB', body: 'A/c XX9876: transaction of INR 1,200.00 on ${day.day}-10-26. Ref 99887$index', receivedAt: day), autoAdd: true));
      await settle(tester, 70);
      await shoot(tester, 'sms_home_review_row_$tag');

      await tapFinder(tester, find.descendant(of: find.byType(DashboardScreen), matching: find.byIcon(Icons.sms_outlined)).last, frames: 12);
      expect(find.byType(SmsReviewScreen), findsOneWidget);
      await shoot(tester, 'sms_review_queue_$tag');
      await goBack(tester);

      await goTab(tester, locale == 'en' ? 'Entries' : 'लेन-देन');
      await settle(tester, 10);
      expect(find.byIcon(Icons.sms_outlined), findsWidgets, reason: 'SMS entries carry the marker');
      await shoot(tester, 'sms_entries_marker_$tag');

      // Clear the queue so the next configuration starts from the same state.
      final pending = await tester.runAsync(() => app.read(smsLogRepositoryProvider).watchPending().first);
      for (final row in pending!) {
        await tester.runAsync(() => app.read(smsLogRepositoryProvider).setStatus(row.id, 'ignored'));
      }
    }
  });
}
