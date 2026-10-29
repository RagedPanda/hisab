import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/recurring/repeat_draft.dart';
import 'package:hisab/features/recurring/repeat_sheet.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

/// An editor-like screen: a focused amount field above the Repeat tile.
class _Host extends StatefulWidget {
  const _Host({required this.amountFocus, this.initial});
  final FocusNode amountFocus;
  final RepeatDraft? initial;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late RepeatDraft? draft = widget.initial;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          TextField(focusNode: widget.amountFocus, autofocus: true),
          RepeatTile(draft: draft, start: DateTime(2026, 7, 5), onChanged: (value) => setState(() => draft = value)),
        ]),
      );
}

Future<void> _pumpHost(WidgetTester tester, FocusNode amountFocus, {Locale locale = const Locale('en'), RepeatDraft? initial}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: _Host(amountFocus: amountFocus, initial: initial),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  testWidgets('opening the Repeat sheet closes the keyboard so Done stays reachable', (tester) async {
    final amountFocus = FocusNode();
    addTearDown(amountFocus.dispose);
    await _pumpHost(tester, amountFocus);
    expect(amountFocus.hasFocus, isTrue);

    await tester.tap(find.byKey(const ValueKey('editor.repeat')));
    await tester.pumpAndSettle();
    expect(amountFocus.hasFocus, isFalse);

    await tester.tap(find.byKey(const ValueKey('repeat.done')));
    await tester.pumpAndSettle();
    expect(find.text('Every month on day 5'), findsOneWidget);
  });

  testWidgets('Done stays on screen and tappable while a keyboard is up', (tester) async {
    final amountFocus = FocusNode();
    addTearDown(amountFocus.dispose);
    // A keyboard taking half of an 800x600 screen.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await _pumpHost(tester, amountFocus);

    await tester.tap(find.byKey(const ValueKey('editor.repeat')));
    await tester.pumpAndSettle();
    final done = find.byKey(const ValueKey('repeat.done'));
    expect(tester.getRect(done).bottom, lessThanOrEqualTo(600 - 300));
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.text('Every month on day 5'), findsOneWidget);
  });

  for (final (locale, minus, plus) in [
    (const Locale('en'), 'Decrease Repeat every', 'Increase Repeat every'),
    (const Locale('hi'), null, null),
  ]) {
    testWidgets('stepper buttons have spoken labels (${locale.languageCode})', (tester) async {
      await initializeDateFormatting(locale.languageCode);
      final semantics = tester.ensureSemantics();
      final amountFocus = FocusNode();
      addTearDown(amountFocus.dispose);
      await _pumpHost(tester, amountFocus, locale: locale);
      await tester.tap(find.byKey(const ValueKey('editor.repeat')));
      await tester.pumpAndSettle();
      final l10n = lookupAppLocalizations(locale);
      final expectedMinus = minus ?? l10n.recurringDecrease(l10n.recurringInterval);
      final expectedPlus = plus ?? l10n.recurringIncrease(l10n.recurringInterval);
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('repeat.interval.minus'))).tooltip, expectedMinus);
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('repeat.interval.plus'))).tooltip, expectedPlus);
      // The tooltip is what TalkBack and VoiceOver read for an icon button.
      expect(tester.getSemantics(find.byKey(const ValueKey('repeat.interval.plus'))), isSemantics(tooltip: expectedPlus, isButton: true));
      semantics.dispose();
    });
  }

  testWidgets('the sheet builds every schedule shape and Don\'t repeat clears it', (tester) async {
    final amountFocus = FocusNode();
    addTearDown(amountFocus.dispose);
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHost(tester, amountFocus);
    await tester.tap(find.byKey(const ValueKey('editor.repeat')));
    await tester.pumpAndSettle();
    String summary() => tester.widget<Text>(find.byKey(const ValueKey('repeat.summary'))).data!;
    Future<void> tapAndSettle(Finder target) async {
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await tapAndSettle(find.text('Weekly'));
    expect(summary(), startsWith('Every week on '));
    await tapAndSettle(find.text('Yearly'));
    expect(summary(), startsWith('Every year on '));
    await tapAndSettle(find.text('Daily'));
    await tapAndSettle(find.byKey(const ValueKey('repeat.interval.plus')));
    expect(summary(), 'Every 2 days');
    await tapAndSettle(find.byKey(const ValueKey('repeat.interval.minus')));
    expect(summary(), 'Every day');

    await tapAndSettle(find.text('Monthly'));
    await tapAndSettle(find.text('On the last day of the month'));
    expect(summary(), 'Every month on the last day');

    await tapAndSettle(find.text('After'));
    expect(summary(), 'Every month on the last day, 12 times');
    await tapAndSettle(find.byKey(const ValueKey('repeat.count.plus')));
    await tapAndSettle(find.byKey(const ValueKey('repeat.count.minus')));
    await tapAndSettle(find.byKey(const ValueKey('repeat.count.minus')));
    expect(summary(), 'Every month on the last day, 11 times');

    await tapAndSettle(find.text('On a date'));
    await tapAndSettle(find.text('OK'));
    expect(summary(), contains(', until '), reason: 'the picker opens a year after the start');
    await tapAndSettle(find.text('Never'));
    expect(summary(), 'Every month on the last day');

    await tapAndSettle(find.byKey(const ValueKey('repeat.done')));
    expect(find.text('Every month on the last day'), findsOneWidget);

    await tapAndSettle(find.byKey(const ValueKey('editor.repeat')));
    await tapAndSettle(find.byKey(const ValueKey('repeat.none')));
    expect(find.text('Does not repeat'), findsOneWidget);
  });

  testWidgets('an end date before the start is refused until it is changed', (tester) async {
    final amountFocus = FocusNode();
    addTearDown(amountFocus.dispose);
    await _pumpHost(tester, amountFocus, initial: RepeatDraft(end: RepeatEnd.onDate, endDate: DateTime(2026, 7, 1)));
    await tester.tap(find.byKey(const ValueKey('editor.repeat')));
    await tester.pumpAndSettle();
    expect(find.text('Pick an end date on or after the start'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('repeat.done'))).onPressed, isNull);

    await tester.tap(find.text('Never'));
    await tester.pumpAndSettle();
    expect(find.text('Pick an end date on or after the start'), findsNothing);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('repeat.done'))).onPressed, isNotNull);
  });
}
