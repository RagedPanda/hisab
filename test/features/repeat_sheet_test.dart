import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/recurring/repeat_draft.dart';
import 'package:hisab/features/recurring/repeat_sheet.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

/// An editor-like screen: a focused amount field above the Repeat tile.
class _Host extends StatefulWidget {
  const _Host({required this.amountFocus});
  final FocusNode amountFocus;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  RepeatDraft? draft;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          TextField(focusNode: widget.amountFocus, autofocus: true),
          RepeatTile(draft: draft, start: DateTime(2026, 7, 5), onChanged: (value) => setState(() => draft = value)),
        ]),
      );
}

Future<void> _pumpHost(WidgetTester tester, FocusNode amountFocus) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: _Host(amountFocus: amountFocus),
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
}
