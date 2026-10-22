/// Screenshot tour of the group screens in every locale and theme, for the
/// visual checks in the dev reports. Seeds data through the repositories and
/// only navigates, so it runs unchanged in English and Hindi.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/group_screens_test.dart -d emulator-5556
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

const _sharedFuelId = 'tour-shared-fuel';
const _configs = [('en', ThemeMode.light), ('en', ThemeMode.dark), ('hi', ThemeMode.light), ('hi', ThemeMode.dark)];

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('group screens in every locale and theme', (tester) async {
    final app = await createApp();
    final groupId = await _seedGroup(app);
    final settledGroupId = await _seedSettledGroup(app);
    final squareGroupId = await _seedSquareGroup(app);
    final archivedGroupId = await _seedArchivedGroup(app);
    await pumpApp(tester, app);

    for (final (locale, mode) in _configs) {
      await app.read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: locale, themeMode: mode));
      final tag = '${locale}_${mode.name}';
      appRouter.go('/groups/$groupId');
      await settle(tester, 10);
      await shoot(tester, 'group_expenses_$tag');
      appRouter.go('/groups/$groupId/settings');
      await settle(tester, 10);
      await shoot(tester, 'group_settings_top_$tag');
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await settle(tester, 10);
      await shoot(tester, 'group_settings_middle_$tag');
      await tester.drag(find.byType(ListView).first, const Offset(0, -1400));
      await settle(tester, 10);
      await shoot(tester, 'group_settings_bottom_$tag');
      await tapFinder(tester, find.byIcon(Icons.currency_exchange), frames: 12);
      await shoot(tester, 'group_currency_sheet_$tag');
      await _popSheet(tester);
      appRouter.go('/groups/$archivedGroupId');
      await settle(tester, 10);
      await shoot(tester, 'group_archived_$tag');
      appRouter.go('/groups/$groupId');
      await settle(tester, 10);
      await tester.tap(find.byType(Tab).at(1));
      await settle(tester, 10);
      await shoot(tester, 'group_balances_$tag');

      // The first transfer row is Rahul -> You: Remind, then Record payment.
      await tapFinder(tester, find.byType(TextButton).at(1), frames: 12);
      await _dropKeyboard(tester);
      await shoot(tester, 'record_payment_prefilled_$tag');
      await _closeSheet(tester);
      await tapFinder(tester, find.byIcon(Icons.add_card_outlined), frames: 12);
      await _dropKeyboard(tester);
      await shoot(tester, 'record_payment_$tag');
      await _closeSheet(tester);
      await tapFinder(tester, find.byIcon(Icons.notifications_active_outlined).first, frames: 12);
      await _dropKeyboard(tester);
      await shoot(tester, 'remind_sheet_$tag');
      await _popSheet(tester);
      await tapFinder(tester, find.byIcon(Icons.ios_share).first, frames: 12);
      await shoot(tester, 'share_options_$tag');
      await _popSheet(tester);

      await tester.tap(find.byType(Tab).at(2));
      await settle(tester, 10);
      await shoot(tester, 'group_members_$tag');
      await tapFinder(tester, find.text('Rahul').first, frames: 12);
      await _dropKeyboard(tester);
      await shoot(tester, 'member_sheet_$tag');
      await _popSheet(tester);
      appRouter.go('/groups/$settledGroupId');
      await settle(tester, 10);
      await tester.tap(find.byType(Tab).first);
      await settle(tester, 10);
      await shoot(tester, 'group_expenses_settled_$tag');
      await tapFinder(tester, find.byIcon(Icons.expand_more), frames: 10);
      await shoot(tester, 'group_expenses_settled_open_$tag');
      await tapFinder(tester, find.byIcon(Icons.expand_less), frames: 10);
      await tester.tap(find.byType(Tab).at(1));
      await settle(tester, 10);
      await shoot(tester, 'group_balances_pay_$tag');
      await tapFinder(tester, find.byIcon(Icons.send_outlined).first, frames: 12);
      await _dropKeyboard(tester);
      await shoot(tester, 'pay_sheet_$tag');
      await _popSheet(tester);

      appRouter.go('/groups/$squareGroupId');
      await settle(tester, 10);
      await tester.tap(find.byType(Tab).at(1));
      await settle(tester, 10);
      await shoot(tester, 'group_balances_settled_$tag');

      appRouter.go('/entry?id=$_sharedFuelId');
      await settle(tester, 12);
      await scrollTo(tester, find.byKey(const Key('payers-assigned')), within: find.byType(ExpenseEditorScreen));
      await shoot(tester, 'expense_multiple_payers_$tag');

      appRouter.go('/groups');
      await settle(tester, 10);
      await shoot(tester, 'groups_list_$tag');
      await scrollTo(tester, find.byIcon(Icons.archive_outlined));
      await tapFinder(tester, find.byIcon(Icons.archive_outlined), frames: 10);
      await scrollTo(tester, find.text('Old flat'));
      await shoot(tester, 'groups_list_archived_$tag');
      await tapFinder(tester, find.byIcon(Icons.archive_outlined), frames: 10);
    }
  });
}

/// Hides the soft keyboard so the emulator's IME toolbar never covers a shot.
Future<void> _dropKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester, 6);
}

/// Pops the top bottom sheet without relying on where its scrim is.
Future<void> _popSheet(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(BottomSheet).last)).pop();
  await settle(tester, 10);
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
  // Paid half each and shared by the two payers, so it shows "Rahul and you
  // paid" without moving any balance.
  await entries.saveEntry(
    EntriesRepository.newExpense(id: _sharedFuelId, amountMinor: 60000, occurredAt: DateTime(2026, 10, 7), note: 'Fuel', groupId: groupId, paidByMemberId: rahul, splitMethod: 'equal'),
    splits: [for (final member in [me, rahul]) SplitsCompanion.insert(id: newId(), entryId: _sharedFuelId, memberId: member, amountMinor: 30000)],
    payers: [for (final member in [rahul, me]) EntryPayersCompanion.insert(id: newId(), entryId: _sharedFuelId, memberId: member, amountMinor: 30000)],
  );
  await groups.updateMember(MembersCompanion(id: Value(rahul), phone: const Value('98765 43210')));
  // Group settings: a trip that splits by shares, Rahul counting double, with notes.
  await groups.updateGroup(GroupsCompanion(id: Value(groupId), type: const Value('trip'), defaultSplitMethod: const Value('shares'), notes: const Value('Villa keys are with Priya. Checkout 11 am Sunday.')));
  await groups.setMemberWeight(rahul, 2);
  return groupId;
}

/// Old flat: an archived home group with no expenses, for the banner, the
/// home-type empty state and the Archived section of the groups list.
Future<String> _seedArchivedGroup(AppHandle app) async {
  final groups = app.read(groupsRepositoryProvider);
  final groupId = await groups.createGroup(name: 'Old flat', icon: 'home', myName: 'You', otherMembers: ['Rahul']);
  await groups.updateGroup(GroupsCompanion(id: Value(groupId), type: const Value('home')));
  await groups.archiveGroup(groupId);
  return groupId;
}

/// Flat dinners: Rahul squared up with me, then a fresh expense, so the
/// expenses tab opens on Unsettled with the settled history folded away.
Future<String> _seedSettledGroup(AppHandle app) async {
  final groups = app.read(groupsRepositoryProvider);
  final entries = app.read(entriesRepositoryProvider);
  final groupId = await groups.createGroup(name: 'Flat dinners', icon: 'restaurant', myName: 'You', otherMembers: ['Rahul']);
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((m) => m.isMe).id;
  final rahul = members.firstWhere((m) => m.name == 'Rahul').id;
  Future<void> expense(String note, String payer, int total, DateTime when) async {
    final entryId = newId();
    await entries.saveEntry(
      EntriesRepository.newExpense(id: entryId, amountMinor: total, occurredAt: when, note: note, groupId: groupId, paidByMemberId: payer, splitMethod: 'equal'),
      splits: [
        for (final member in [me, rahul]) SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: member, amountMinor: total ~/ 2),
      ],
    );
  }

  await expense('Pizza night', me, 120000, DateTime(2026, 9, 26));
  await groups.addSettlement(groupId: groupId, fromMemberId: rahul, toMemberId: me, amountMinor: 60000, occurredAt: DateTime(2026, 9, 28), method: 'upi');
  await expense('Biryani', rahul, 80000, DateTime(2026, 10, 8));
  await groups.updateMember(MembersCompanion(id: Value(rahul), phone: const Value('98765 43210'), upiId: const Value('rahul.k@okicici')));
  return groupId;
}

/// Movie night: one expense Rahul has fully paid back, so balances are square.
Future<String> _seedSquareGroup(AppHandle app) async {
  final groups = app.read(groupsRepositoryProvider);
  final entries = app.read(entriesRepositoryProvider);
  final groupId = await groups.createGroup(name: 'Movie night', icon: 'celebration', myName: 'You', otherMembers: ['Rahul']);
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((m) => m.isMe).id;
  final rahul = members.firstWhere((m) => m.name == 'Rahul').id;
  final entryId = newId();
  await entries.saveEntry(
    EntriesRepository.newExpense(id: entryId, amountMinor: 60000, occurredAt: DateTime(2026, 10, 10), note: 'Tickets', groupId: groupId, paidByMemberId: me, splitMethod: 'equal'),
    splits: [
      for (final member in [me, rahul]) SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: member, amountMinor: 30000),
    ],
  );
  await groups.addSettlement(groupId: groupId, fromMemberId: rahul, toMemberId: me, amountMinor: 30000, occurredAt: DateTime(2026, 10, 11), method: 'cash');
  return groupId;
}
