import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/accounts/account_choice_chips.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

Account _account(String id, String name) => Account(
      id: id,
      name: name,
      type: 'bank',
      color: 0xFF0D9488,
      balanceMinor: 0,
      includeInTotal: true,
      sortOrder: 0,
      updatedAt: DateTime(2026, 10, 1),
    );

/// Hosts the chips under a router so "Add account" has somewhere to go.
Future<GoRouter> _pumpChips(WidgetTester tester, List<Account> accounts, {String? selectedId, ValueChanged<String?>? onPick}) async {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => Scaffold(body: AccountChoiceChips(accounts: accounts, selectedId: selectedId, onPick: onPick ?? (_) {}))),
    GoRoute(path: '/accounts', builder: (_, _) => const Scaffold(body: Text('Accounts screen'))),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('one chip per account, the selected one marked, a tap picks it', (tester) async {
    final picked = <String?>[];
    await _pumpChips(tester, [_account('cash', 'Cash'), _account('hdfc', 'HDFC Savings')], selectedId: 'cash', onPick: picked.add);

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    expect(chips.map((chip) => chip.selected), [true, false]);
    expect(find.text('Add account'), findsNothing);

    await tester.tap(find.text('HDFC Savings'));
    expect(picked, ['hdfc']);
  });

  testWidgets('with no accounts it offers to add one', (tester) async {
    await _pumpChips(tester, const []);

    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();

    expect(find.text('Accounts screen'), findsOneWidget);
  });
}
