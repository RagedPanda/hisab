import 'package:flutter/material.dart' hide Split;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/core/theme.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/domain/split/group_timeline.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:hisab/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _when = DateTime(2026, 10, 20, 13, 5);

Entry _entry({String? groupId, String? paidBy, int amountMinor = 1000000}) => Entry(
      updatedAt: _when,
      id: 'e1',
      kind: 'expense',
      amountMinor: amountMinor,
      currency: 'INR',
      occurredAt: _when,
      note: 'Dinner',
      source: 'manual',
      groupId: groupId,
      paidByMemberId: paidBy,
      tags: '',
      createdAt: _when,
    );

final _group = Group(
  updatedAt: _when,
  id: 'g1',
  name: 'Goa trip',
  icon: 'group',
  currency: 'INR',
  simplifyDebts: true,
  createdAt: _when,
  type: 'trip',
  defaultSplitMethod: 'equal',
  notes: '',
);

Split _split(String memberId, int amountMinor) =>
    Split(updatedAt: _when, id: 's-$memberId', entryId: 'e1', memberId: memberId, amountMinor: amountMinor);

/// A 10,000 bill split four ways, 2,500 each.
final _fourWay = [for (final id in ['me', 'a', 'b', 'c']) _split(id, 250000)];

EntryDetails _shared({required String paidBy}) => EntryDetails(
      entry: _entry(groupId: 'g1', paidBy: paidBy),
      items: const [],
      group: _group,
      myShareMinor: 250000,
      myMemberId: 'me',
      splits: _fourWay,
    );

Future<void> _pump(WidgetTester tester, EntryDetails details) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: ListView(children: [EntryTile(details: details)])),
    ),
  ));
  await tester.pumpAndSettle();
}

Color? _colorOf(WidgetTester tester, Finder text) => tester.widget<Text>(text).style?.color;

void main() {
  test('myEffect: paying a four-way 10,000 bill lends the other 7,500', () {
    final effect = _shared(paidBy: 'me').myEffect!;
    expect(effect.kind, ExpenseEffectKind.lent);
    expect(effect.amountMinor, 750000);
  });

  test('myEffect: someone else paying means I borrowed my 2,500 share', () {
    final effect = _shared(paidBy: 'a').myEffect!;
    expect(effect.kind, ExpenseEffectKind.borrowed);
    expect(effect.amountMinor, 250000);
  });

  test('myEffect: multi-payer rows win over the single payer', () {
    final details = EntryDetails(
      entry: _entry(groupId: 'g1', paidBy: 'a'),
      items: const [],
      group: _group,
      myMemberId: 'me',
      splits: _fourWay,
      payers: [
        EntryPayer(updatedAt: _when, id: 'p1', entryId: 'e1', memberId: 'me', amountMinor: 500000),
        EntryPayer(updatedAt: _when, id: 'p2', entryId: 'e1', memberId: 'a', amountMinor: 500000),
      ],
    );
    expect(details.myEffect!.kind, ExpenseEffectKind.lent);
    expect(details.myEffect!.amountMinor, 250000);
  });

  test('myEffect is null for personal entries and when I have no member id', () {
    expect(EntryDetails(entry: _entry(), items: const []).myEffect, isNull);
    expect(EntryDetails(entry: _entry(groupId: 'g1', paidBy: 'a'), items: const [], splits: _fourWay).myEffect, isNull);
  });

  testWidgets('a shared expense I paid shows the group tag, mark and "you lent" in green', (tester) async {
    await _pump(tester, _shared(paidBy: 'me'));
    expect(find.byKey(const Key('group-mark')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('group-tag')), matching: find.text('Goa trip')), findsOneWidget);
    final lent = find.textContaining('you lent');
    expect(lent, findsOneWidget);
    expect(tester.widget<Text>(lent).data, contains('7,500'));
    expect(_colorOf(tester, lent), kIncomeColor);
    // The row's own amount stays my share, not the whole bill.
    expect(find.textContaining('2,500'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a shared expense someone else paid shows "you borrowed" in red', (tester) async {
    await _pump(tester, _shared(paidBy: 'a'));
    final borrowed = find.textContaining('you borrowed');
    expect(borrowed, findsOneWidget);
    expect(_colorOf(tester, borrowed), kExpenseColor);
  });

  testWidgets('a personal expense has no group mark or tag', (tester) async {
    await _pump(tester, EntryDetails(entry: _entry(), items: const []));
    expect(find.byKey(const Key('group-mark')), findsNothing);
    expect(find.byKey(const Key('group-tag')), findsNothing);
  });

  testWidgets('a long group name ellipsizes at 360dp without overflow', (tester) async {
    final details = EntryDetails(
      entry: _entry(groupId: 'g1', paidBy: 'me'),
      items: const [],
      group: _group.copyWith(name: 'A very long weekend trip with the whole extended family'),
      myShareMinor: 250000,
      myMemberId: 'me',
      splits: _fourWay,
    );
    await _pump(tester, details);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('you lent'), findsOneWidget);
  });
}
