import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/shell/widgets/common.dart';

import '../support/app_harness.dart';

/// A button that opens a dialog through [open] and shows what it returned.
class _Prompter<T> extends StatefulWidget {
  const _Prompter({required this.open});
  final Future<T?> Function(BuildContext context) open;

  @override
  State<_Prompter<T>> createState() => _PrompterState<T>();
}

class _PrompterState<T> extends State<_Prompter<T>> {
  String result = 'nothing yet';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          FilledButton(
            onPressed: () async {
              final value = await widget.open(context);
              setState(() => result = 'got $value');
            },
            child: const Text('Open'),
          ),
          Text(result),
        ]),
      );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await settle(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('an SMS entry is titled by its payee and marked as from SMS', (tester) async {
    final container = await createContainer();
    final entries = container.read(entriesRepositoryProvider);
    await tester.runAsync(() => entries.saveEntry(EntriesRepository.newExpense(id: 'swiggy', amountMinor: 45900, occurredAt: DateTime(2026, 10, 21), payee: 'Swiggy', source: 'sms')));
    final details = (await tester.runAsync(() => entries.getEntry('swiggy')))!;
    await pumpScreen(tester, container, Scaffold(body: EntryTile(details: details)));

    expect(find.text('Swiggy'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Icon && widget.semanticLabel == 'Added from SMS'), findsOneWidget);
  });

  testWidgets('the month switcher steps months and the label returns to this month', (tester) async {
    final container = await createContainer();
    await pumpScreen(tester, container, const Scaffold(body: Center(child: MonthSwitcher())));
    final thisMonth = container.read(selectedMonthProvider);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(container.read(selectedMonthProvider).month, DateTime(thisMonth.year, thisMonth.month - 1).month);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(container.read(selectedMonthProvider).month, DateTime(thisMonth.year, thisMonth.month + 1).month);

    await tester.tap(find.byType(AnimatedSwitcher));
    await tester.pumpAndSettle();
    expect(container.read(selectedMonthProvider).month, thisMonth.month);
  });

  testWidgets('a text prompt returns the trimmed text on submit', (tester) async {
    final container = await createContainer();
    await pumpScreen(tester, container, _Prompter<String>(open: (context) => promptText(context, title: 'Name')));
    await _open(tester);
    await tester.enterText(find.byType(TextField), '  Rent  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.text('got Rent'), findsOneWidget);
  });

  group('amount prompt', () {
    Widget prompter() => _Prompter<int>(open: (context) => promptAmount(context, title: 'Amount', format: MoneyFormat.inr, initialMinor: 12345));

    testWidgets('starts from the given amount and saves only a valid one', (tester) async {
      final container = await createContainer();
      await pumpScreen(tester, container, prompter());
      await _open(tester);
      expect(find.text('123.45'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '0');
      await settle(tester);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save')).onPressed, isNull, reason: 'zero is not an amount');

      await tester.enterText(find.byType(TextField), '250');
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);
      expect(find.text('got 25000'), findsOneWidget);
    });

    testWidgets('submitting from the keyboard saves, and Cancel returns nothing', (tester) async {
      final container = await createContainer();
      await pumpScreen(tester, container, prompter());
      await _open(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(find.text('got 12345'), findsOneWidget);

      await _open(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(find.text('got null'), findsOneWidget);
    });
  });

  testWidgets('tapping outside a field closes the keyboard', (tester) async {
    final fieldFocus = FocusNode();
    addTearDown(fieldFocus.dispose);
    final container = await createContainer();
    await pumpScreen(tester, container, Scaffold(body: DismissKeyboardOnTap(child: SizedBox.expand(child: Align(alignment: Alignment.topCenter, child: TextField(focusNode: fieldFocus, autofocus: true))))));
    await settle(tester);
    expect(fieldFocus.hasFocus, isTrue);

    await tester.tapAt(const Offset(180, 600));
    await settle(tester);
    expect(fieldFocus.hasFocus, isFalse);
  });

  group('with nothing to go back to', () {
    /// Shows [screen] as the only route, as when a deep link opens it.
    Future<void> pumpAlone(WidgetTester tester, Widget screen) async {
      final router = await pumpScreen(tester, await createContainer(), screen);
      router.go('/screen');
      await tester.pumpAndSettle();
      expect(router.canPop(), isFalse);
    }

    testWidgets('pop-or-go-home goes Home', (tester) async {
      await pumpAlone(tester, Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => popOrGoHome(context), child: const Text('Back')))));
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('the system Back gesture goes Home', (tester) async {
      await pumpAlone(tester, const HomeFallbackPop(child: Scaffold(body: Text('Deep linked'))));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });
}
