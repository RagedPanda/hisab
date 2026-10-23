/// On-device flow for credit card dues (roadmap R2): set a card's statement
/// and due days from the card screen, check the figures and the automatic
/// "card due" reminder, then shoot the card screen and its editor in every
/// locale and theme, including a 360dp-wide phone. Run with
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/card_dues_flow_test.dart -d `<device>`
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/cards/card_cycle.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/features/accounts/card_account_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

const _configs = [('en', ThemeMode.light), ('en', ThemeMode.dark), ('hi', ThemeMode.light), ('hi', ThemeMode.dark)];

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('card dues: set days, see the bill and its reminder', (tester) async {
    final app = await createApp();
    final card = await app.read(accountsRepositoryProvider).create(name: 'HDFC Millennia', type: 'card', color: 0xFF1E88E5, balanceMinor: -4250000);
    await pumpApp(tester, app);

    appRouter.go('/accounts');
    await settle(tester, 10);
    await tapText(tester, 'HDFC Millennia');
    expect(find.text('Set statement and due days'), findsOneWidget);

    await tapText(tester, 'Set statement and due days');
    await tapFinder(tester, find.byKey(const ValueKey('account.statementDay')));
    await tapText(tester, '5', last: true);
    await tapFinder(tester, find.byKey(const ValueKey('account.dueDay')));
    await tapText(tester, '15', last: true);
    await enterText(tester, find.byKey(const ValueKey('account.creditLimit')), '200000');
    await enterText(tester, find.byKey(const ValueKey('account.lastStatement')), '30000');
    await tapText(tester, 'Save');
    await settle(tester, 10);

    expect(find.byKey(kCardDueKey), findsOneWidget);
    expect(find.byKey(kCardDueChipKey), findsOneWidget);
    expect(find.text('₹30,000'), findsWidgets, reason: 'last statement');
    expect(find.text('₹1,57,500'), findsOneWidget, reason: 'available limit');

    final reminders = await app.read(remindersRepositoryProvider).forAccount(card.id, kind: ReminderKind.card);
    expect(reminders, hasLength(1));
    final reminder = reminders.single;
    expect(reminder.amountMinor, 3000000);
    expect(reminder.dueAt, dueDateForStatement(previousStatementDate(startOfDay(DateTime.now()), 5), 15));

    for (final narrow in [false, true]) {
      if (narrow) {
        tester.view.physicalSize = Size(360 * tester.view.devicePixelRatio, tester.view.physicalSize.height);
        addTearDown(tester.view.resetPhysicalSize);
      }
      for (final (locale, mode) in _configs) {
        await app.read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: locale, themeMode: mode));
        final tag = '${locale}_${mode.name}${narrow ? '_360' : ''}';
        appRouter.go('/accounts/card/${card.id}');
        await settle(tester, 10);
        expect(tester.takeException(), isNull, reason: 'no overflow on $tag');
        await shoot(tester, 'card_account_$tag');
        await tapFinder(tester, find.byIcon(Icons.edit_outlined));
        await scrollTo(tester, find.byKey(const ValueKey('account.lastStatement')));
        await shoot(tester, 'card_editor_$tag');
        // Dismiss the editor sheet by tapping its barrier above it.
        await tester.tapAt(const Offset(20, 40));
        await settle(tester);
      }
    }
  });
}
