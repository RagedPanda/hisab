import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:hisab/features/sms/sms_history_screen.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _upiDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';
const _atmDebit = 'Rs.4,000.00 withdrawn from A/c XX1234 at ATM on 21-10-26. Avl bal Rs.11,541.00';

void main() {
  testWidgets('history lists every outcome with chips, filters and actions', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(db)]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final service = container.read(smsIngestServiceProvider);
    final day = DateTime(2026, 10, 21, 9);
    await tester.runAsync(() async {
      await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: day), autoAdd: true);
      await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: day.add(const Duration(minutes: 40))), autoAdd: true);
      await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _atmDebit, receivedAt: day.add(const Duration(hours: 2))), autoAdd: false);
      await service.ingest(RawSms(sender: 'AMAZON', body: 'Your order has shipped', receivedAt: day.add(const Duration(hours: 3))), autoAdd: true);
      await service.ingest(RawSms(sender: 'VM-HDFCBK', body: 'Your statement is ready on NetBanking.', receivedAt: day.add(const Duration(hours: 4))), autoAdd: true);
    });

    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SmsHistoryScreen(),
      ),
    ));
    Future<void> pumpFrames() async {
      for (var frame = 0; frame < 5; frame++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await pumpFrames();
    final strip = find.descendant(of: find.byType(ChipRow), matching: find.byType(Scrollable));
    final chipTexts = <String>{};
    for (var step = 0; step < 12; step++) {
      chipTexts.addAll(find.descendant(of: find.byType(ChipRow), matching: find.byType(Text)).evaluate().map((element) => (element.widget as Text).data!));
      await tester.drag(strip, const Offset(-120, 0));
      await tester.pump();
    }
    expect(chipTexts, containsAll(['All', 'Added 1', 'Duplicate 1', 'Ignored 1', 'Unreadable 1', 'Pending 1']));
    expect(chipTexts.where((text) => text.startsWith('Undone')), isEmpty);

    // Scrolled to the far end, the strip stays there (the edge fade going
    // away must not rebuild the list back to the start).
    await tester.drag(strip, const Offset(-2000, 0));
    await pumpFrames();
    expect(find.text('Pending 1').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Pending 1'));
    await pumpFrames();
    expect(find.text('Not a bank message'), findsNothing, reason: 'the pending filter shows only pending messages');
    await tester.drag(strip, const Offset(2000, 0));
    await pumpFrames();
    await tester.tap(find.text('All'));
    await pumpFrames();
    expect(find.text('Not a bank message'), findsOneWidget);
    expect(find.text('Message text not kept'), findsOneWidget, reason: 'the not-bank message has no stored text');
    expect(find.text('Your order has shipped'), findsNothing);
    expect(find.text('Process again'), findsOneWidget, reason: 'only the unreadable bank message; a not-bank row has no text to process');
    expect(tester.takeException(), isNull, reason: 'no overflow at 360dp');
  });
}
