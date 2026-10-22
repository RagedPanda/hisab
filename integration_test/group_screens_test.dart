/// Screenshot tour of the group screens in every locale and theme, for the
/// visual checks in the dev reports. Seeds data through the repositories and
/// only navigates, so it runs unchanged in English and Hindi.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/group_screens_test.dart -d emulator-5556
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

const _configs = [
  ('en', ThemeMode.light),
  ('en', ThemeMode.dark),
  ('hi', ThemeMode.light),
  ('hi', ThemeMode.dark),
];

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('group screens in every locale and theme', (tester) async {
    final app = await createApp();
    final groupId = await _seedGroup(app);
    await pumpApp(tester, app);

    for (final (locale, mode) in _configs) {
      await app.read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: locale, themeMode: mode));
      final tag = '${locale}_${mode.name}';
      appRouter.go('/groups/$groupId');
      await settle(tester, 10);
      await shoot(tester, 'group_expenses_$tag');
      await tester.tap(find.byType(Tab).at(1));
      await settle(tester, 10);
      await shoot(tester, 'group_balances_$tag');

      await tapFinder(tester, find.byType(TextButton).first, frames: 12);
      await _dropKeyboard(tester);
      await shoot(tester, 'record_payment_prefilled_$tag');
      await _closeSheet(tester);
      await tapFinder(tester, find.byIcon(Icons.add_card_outlined), frames: 12);
      await _dropKeyboard(tester);
      await shoot(tester, 'record_payment_$tag');
      await _closeSheet(tester);

      await tester.tap(find.byType(Tab).at(2));
      await settle(tester, 10);
      await shoot(tester, 'group_members_$tag');
      appRouter.go('/groups');
      await settle(tester, 10);
      await shoot(tester, 'groups_list_$tag');
    }
  });
}

/// Hides the soft keyboard so the emulator's IME toolbar never covers a shot.
Future<void> _dropKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester, 6);
}

Future<void> _closeSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 60));
  await settle(tester, 10);
}

/// Goa trip: me, Rahul, Priya; three expenses and one recorded payment so the
/// balances tab has something to settle and something settled.
Future<String> _seedGroup(AppHandle app) async {
  final groups = app.read(groupsRepositoryProvider);
  final entries = app.read(entriesRepositoryProvider);
  final groupId = await groups.createGroup(name: 'Goa trip', icon: 'flight', myName: 'You', otherMembers: ['Rahul', 'Priya']);
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((m) => m.isMe).id;
  final rahul = members.firstWhere((m) => m.name == 'Rahul').id;
  final priya = members.firstWhere((m) => m.name == 'Priya').id;
  Future<void> expense(String note, String payer, int total, List<String> sharers, DateTime when) async {
    final entryId = newId();
    final each = total ~/ sharers.length;
    await entries.saveEntry(
      EntriesRepository.newExpense(id: entryId, amountMinor: total, occurredAt: when, note: note, groupId: groupId, paidByMemberId: payer, splitMethod: 'equal'),
      splits: [for (final member in sharers) SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: member, amountMinor: each)],
    );
  }

  await expense('Villa', me, 900000, [me, rahul, priya], DateTime(2026, 10, 3));
  await expense('Scooter rent', rahul, 240000, [me, rahul, priya], DateTime(2026, 10, 4));
  await expense('Dinner at Thalassa', priya, 450000, [me, rahul, priya], DateTime(2026, 10, 5));
  await groups.addSettlement(groupId: groupId, fromMemberId: priya, toMemberId: me, amountMinor: 100000, occurredAt: DateTime(2026, 10, 6), method: 'upi');
  return groupId;
}
