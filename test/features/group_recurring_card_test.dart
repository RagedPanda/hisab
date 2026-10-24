import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/group_recurring_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/split/group_recurring.dart';
import 'package:hisab/domain/split/split_calculator.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart' show settle;

/// A group labelled AED with a monthly 3,000 rent split equally among three,
/// starting in the future so nothing is posted yet.
Future<(String, String)> _seedDubaiFlat(AppDatabase db) async {
  final groups = GroupsRepository(db);
  final groupId = await groups.createGroup(name: 'Dubai flat', icon: 'home', myName: 'Me', otherMembers: const ['Ravi', 'Priya']);
  final group = await (db.select(db.groups)..where((t) => t.id.equals(groupId))).getSingle();
  await groups.setCurrencyLabel(group, 'AED');
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((member) => member.isMe).id;
  final template = GroupExpenseTemplate(method: SplitMethod.equal, paidByMemberId: me, inputs: [for (final member in members) SplitInput(memberId: member.id)]);
  final start = DateTime.now().add(const Duration(days: 40));
  final ruleId = await RecurringRepository(db).saveRule(GroupRecurringRepository.asGroupRule(
    RecurringRepository.newRule(name: 'Rent', kind: 'expense', amountMinor: 300000, frequency: RecurrenceFrequency.monthly, dayOfMonth: start.day, startDate: start),
    groupId: groupId,
    template: template,
  ));
  return (groupId, ruleId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a repeating group expense shows its amount and my share in the group currency label (#129)', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final (groupId, ruleId) = (await tester.runAsync(() => _seedDubaiFlat(db)))!;
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(430, 932));
    appRouter.go('/groups/$groupId');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await settle(tester);

    final card = find.byKey(ValueKey('group.recurring.$ruleId'));
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.textContaining('AED')), findsNWidgets(2), reason: 'the amount and "your share" both use the group label');
    expect(find.descendant(of: card, matching: find.textContaining('₹')), findsNothing);
  });
}
