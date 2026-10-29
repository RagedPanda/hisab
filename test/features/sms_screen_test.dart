import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/features/sms/sms_review_screen.dart';
import 'package:hisab/features/sms/sms_screen.dart';
import 'package:hisab/features/sms/widgets/sms_review_card.dart';

import '../support/app_harness.dart';

const _upiDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';
const _atmDebit = 'Rs.4,000.00 withdrawn from A/c XX1234 at ATM on 21-10-26. Avl bal Rs.11,541.00';
const _usdSpend = 'USD 25.00 spent on your HDFC Bank Credit Card XX1234 at AMAZON US on 21-10-26.';

/// Tall enough that the review list under the settings card is laid out.
const _wideScreen = Size(600, 1400);

/// The Bank SMS screen fed by [sharedText], as the share deep link does.
Widget _sharedSmsScreen(ValueNotifier<String?> sharedText) => ValueListenableBuilder<String?>(valueListenable: sharedText, builder: (_, text, _) => SmsScreen(sharedText: text));

Future<void> _share(WidgetTester tester, ValueNotifier<String?> sharedText, String text) async {
  sharedText.value = text;
  await pumpWithDatabase(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shared text is read on open and every new share reports its outcome', (tester) async {
    final container = await createContainer();
    final sharedText = ValueNotifier<String?>(_upiDebit);
    addTearDown(sharedText.dispose);
    await pumpScreen(tester, container, _sharedSmsScreen(sharedText), size: _wideScreen);
    expect(find.text('Transaction added.'), findsOneWidget);

    await _share(tester, sharedText, '$_upiDebit ');
    expect(find.text('Already imported.'), findsOneWidget, reason: 'the same payment shared again');

    await _share(tester, sharedText, _usdSpend);
    expect(find.text('Only SMS in your home currency are supported, so this one was ignored.'), findsOneWidget);

    await _share(tester, sharedText, 'See you at dinner');
    expect(find.text('Could not find a transaction in that text.'), findsOneWidget);

    await _share(tester, sharedText, '   ');
    expect(find.text('Could not find a transaction in that text.'), findsOneWidget, reason: 'blank text is not read again');
  });

  testWidgets('a pasted SMS with auto-add off waits in the review list', (tester) async {
    final container = await createContainer();
    await pumpScreen(tester, container, const SmsScreen(), size: _wideScreen);
    expect(find.text('Not available on iOS. Use the Shortcut or paste below.'), findsOneWidget, reason: 'tests do not run on Android');
    expect(find.text('Nothing waiting'), findsOneWidget);

    await tester.tap(find.text('Add clear transactions automatically'));
    await pumpWithDatabase(tester);
    expect(container.read(settingsProvider).smsAutoAdd, isFalse);
    expect(container.read(settingsProvider).smsAutoAddChosen, isTrue);

    await tester.tap(find.text('Paste an SMS'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _atmDebit);
    await tester.tap(find.text('Save'));
    await pumpWithDatabase(tester);
    expect(find.text('Transaction found. Review it below.'), findsOneWidget);
    expect(find.text('To review (1)'), findsOneWidget);
    expect(find.byType(SmsReviewCard), findsOneWidget);

    await tester.tap(find.text('Paste an SMS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await pumpWithDatabase(tester);
    expect(find.text('Transaction found. Review it below.'), findsOneWidget, reason: 'cancelling the paste reads nothing');
  });

  for (final (title, location) in const [('SMS history', '/sms/history'), ('Remembered payees', '/sms/payees')]) {
    testWidgets('$title opens $location', (tester) async {
      final container = await createContainer();
      await pumpScreen(tester, container, const SmsScreen(), size: _wideScreen);
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text(openedLocation(location)), findsOneWidget);
    });
  }

  testWidgets('the review screen lists waiting messages, or says nothing is waiting', (tester) async {
    final container = await createContainer();
    await pumpScreen(tester, container, const SmsReviewScreen(), size: _wideScreen);
    expect(find.text('Nothing waiting'), findsOneWidget);

    await tester.runAsync(() => container.read(smsIngestServiceProvider).ingest(RawSms(sender: 'VM-HDFCBK', body: _atmDebit, receivedAt: DateTime(2026, 10, 21, 9)), autoAdd: false));
    await pumpWithDatabase(tester);
    expect(find.text('SMS to review'), findsOneWidget);
    expect(find.text('These messages were not clear enough to add on their own. Add, edit or ignore each one.'), findsOneWidget);
    expect(find.byType(SmsReviewCard), findsOneWidget);
  });
}
