import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/accounts/grouped_account_picker.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

Account account(String id, String name, String type) => Account(
      id: id,
      name: name,
      type: type,
      color: 0xFF2196F3,
      balanceMinor: 0,
      includeInTotal: true,
      sortOrder: 0,
      updatedAt: DateTime(2026),
    );

final cash = account('cash', 'Cash', 'cash');
final hdfc = account('hdfc', 'HDFC', 'bank');
final sbi = account('sbi', 'SBI', 'bank');
final card = account('amex', 'Amex', 'card');

/// Hosts the picker and keeps the picked id, as the entry editor does.
class PickerHost extends StatefulWidget {
  const PickerHost({super.key, required this.accounts, this.initialId});
  final List<Account> accounts;
  final String? initialId;

  @override
  State<PickerHost> createState() => PickerHostState();
}

class PickerHostState extends State<PickerHost> {
  late String? picked = widget.initialId;

  @override
  Widget build(BuildContext context) =>
      GroupedAccountPicker(accounts: widget.accounts, selectedId: picked, onPick: (id) => setState(() => picked = id));
}

Future<PickerHostState> pumpPicker(WidgetTester tester, List<Account> accounts, {String? initialId, Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: PickerHost(accounts: accounts, initialId: initialId)),
  ));
  await tester.pumpAndSettle();
  return tester.state<PickerHostState>(find.byType(PickerHost));
}

bool chipSelected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip))).selected;

void main() {
  testWidgets('shows only the types the user has, not every account', (tester) async {
    await pumpPicker(tester, [hdfc, cash, sbi]);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Bank account'), findsOneWidget);
    expect(find.text('Credit card'), findsNothing);
    expect(find.text('Wallet / UPI'), findsNothing);
    expect(find.text('HDFC'), findsNothing, reason: 'bank accounts stay hidden until the type is tapped');
  });

  testWidgets('a type with several accounts reveals them with none picked; another type hides them', (tester) async {
    final host = await pumpPicker(tester, [cash, hdfc, sbi], initialId: 'cash');
    await tester.tap(find.text('Bank account'));
    await tester.pumpAndSettle();
    expect(find.text('HDFC'), findsOneWidget);
    expect(find.text('SBI'), findsOneWidget);
    expect(host.picked, isNull, reason: 'nothing is picked until the user chooses a bank');
    expect(chipSelected(tester, 'HDFC') || chipSelected(tester, 'SBI'), isFalse);

    await tester.tap(find.text('SBI'));
    await tester.pumpAndSettle();
    expect(host.picked, 'sbi');

    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    expect(find.text('SBI'), findsNothing);
    expect(host.picked, 'cash', reason: 'a type with one account picks it in one tap');
  });

  testWidgets('a preselected account opens its type and row', (tester) async {
    await pumpPicker(tester, [cash, hdfc, sbi, card], initialId: 'hdfc');
    expect(chipSelected(tester, 'Bank account'), isTrue);
    expect(chipSelected(tester, 'HDFC'), isTrue);
    expect(find.text('SBI'), findsOneWidget);
  });

  testWidgets('a preselected single-account type is selected with no second row', (tester) async {
    await pumpPicker(tester, [cash, hdfc, sbi, card], initialId: 'amex');
    expect(chipSelected(tester, 'Credit card'), isTrue);
    expect(find.text('Amex'), findsNothing);
    expect(find.text('HDFC'), findsNothing);
  });

  testWidgets('with no accounts it offers Add account', (tester) async {
    await pumpPicker(tester, const []);
    expect(find.text('Add account'), findsOneWidget);
  });

  testWidgets('type labels are translated (hi)', (tester) async {
    await pumpPicker(tester, [cash, hdfc], locale: const Locale('hi'));
    final l10n = await AppLocalizations.delegate.load(const Locale('hi'));
    expect(find.text(l10n.accountTypeCash), findsOneWidget);
    expect(find.text(l10n.accountTypeBank), findsOneWidget);
  });
}
