import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/group_recurring_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/split/group_recurring.dart';
import 'package:hisab/domain/split/split_calculator.dart';

void main() {
  late AppDatabase db;
  late RecurringRepository recurring;
  late GroupsRepository groups;
  late String groupId;
  late Map<String, String> memberIdByName;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    recurring = RecurringRepository(db);
    groups = GroupsRepository(db);
    groupId = await groups.createGroup(name: 'Flat 302', icon: 'home', myName: 'Me', otherMembers: ['Ravi', 'Priya']);
    memberIdByName = {for (final member in await groups.getMembers(groupId)) member.name: member.id};
  });

  tearDown(() => db.close());

  GroupExpenseTemplate equalRent({List<SplitShare> payers = const []}) => GroupExpenseTemplate(
        method: SplitMethod.equal,
        paidByMemberId: memberIdByName['Me']!,
        inputs: [for (final id in memberIdByName.values) SplitInput(memberId: id)],
        payers: payers,
      );

  Future<String> saveRentRule(GroupExpenseTemplate template, {int amountMinor = 1500000}) => recurring.saveRule(GroupRecurringRepository.asGroupRule(
        RecurringRepository.newRule(name: 'Rent', kind: 'expense', amountMinor: amountMinor, frequency: RecurrenceFrequency.monthly, dayOfMonth: 1, startDate: DateTime(2026, 9, 1, 9)),
        groupId: groupId,
        template: template,
      ));

  Future<List<Entry>> groupEntries() => (db.select(db.entries)..where((t) => t.groupId.equals(groupId))..orderBy([(t) => OrderingTerm.asc(t.occurredAt)])).get();

  test('postDue posts each missed month into the group with the remembered split', () async {
    await saveRentRule(equalRent());
    final written = await recurring.postDue(now: DateTime(2026, 10, 22));
    expect(written, 2);
    final entries = await groupEntries();
    expect(entries.map((entry) => entry.occurredAt), [DateTime(2026, 9, 1, 9), DateTime(2026, 10, 1, 9)]);
    expect(entries.every((entry) => entry.paidByMemberId == memberIdByName['Me'] && entry.splitMethod == 'equal' && entry.accountId == null), isTrue);
    final balances = await groups.getBalances(groupId);
    expect(balances.net[memberIdByName['Me']], 2000000, reason: 'I paid 30,000 and owe 10,000');
    expect(balances.net[memberIdByName['Ravi']], -1000000);
  });

  test('posting is idempotent across repeated runs', () async {
    await saveRentRule(equalRent());
    await recurring.postDue(now: DateTime(2026, 10, 22));
    expect(await recurring.postDue(now: DateTime(2026, 10, 22)), 0);
    expect(await groupEntries(), hasLength(2));
    final splits = await db.select(db.splits).get();
    expect(splits, hasLength(6));
  });

  test('several payers are posted with every occurrence', () async {
    await saveRentRule(equalRent(payers: [SplitShare(memberIdByName['Me']!, 600000), SplitShare(memberIdByName['Ravi']!, 900000)]));
    await recurring.postDue(now: DateTime(2026, 9, 2));
    final entry = (await groupEntries()).single;
    expect(entry.paidByMemberId, memberIdByName['Ravi']);
    final payers = await db.select(db.entryPayers).get();
    expect({for (final payer in payers) payer.memberId: payer.amountMinor}, {memberIdByName['Me']: 600000, memberIdByName['Ravi']: 900000});
  });

  test('a group rule switched to income or transfer posts nothing into the group', () async {
    for (final kind in ['income', 'transfer']) {
      await recurring.saveRule(GroupRecurringRepository.asGroupRule(
        RecurringRepository.newRule(name: 'Salary', kind: kind, amountMinor: 100000, frequency: RecurrenceFrequency.monthly, dayOfMonth: 1, startDate: DateTime(2026, 9, 1, 9)),
        groupId: groupId,
        template: equalRent(),
      ));
    }
    expect(await recurring.postDue(now: DateTime(2026, 10, 22)), 0);
    expect(await db.select(db.entries).get(), isEmpty);
  });

  test('a payer who left pauses the rule instead of posting a wrong split', () async {
    final ruleId = await saveRentRule(GroupExpenseTemplate(
      method: SplitMethod.equal,
      paidByMemberId: memberIdByName['Priya']!,
      inputs: [for (final id in memberIdByName.values) SplitInput(memberId: id)],
    ));
    await recurring.postDue(now: DateTime(2026, 9, 2));
    await groups.removeMember(memberIdByName['Priya']!);
    expect(await recurring.postDue(now: DateTime(2026, 10, 22)), 0);
    final rule = (await recurring.getRule(ruleId))!;
    expect(rule.status, RecurringStatus.paused);
    expect(rule.nextDue, DateTime(2026, 10, 1, 9), reason: 'the blocked month stays due');
    expect(await groupEntries(), hasLength(1));
  });

  test('views list group rules under their group and keep them off the personal list', () async {
    await saveRentRule(equalRent());
    await recurring.saveRule(RecurringRepository.newRule(kind: 'expense', amountMinor: 100, frequency: RecurrenceFrequency.monthly, startDate: DateTime(2026, 9, 1)));
    final groupViews = await recurring.getViews(groupId: groupId);
    expect(groupViews.map((view) => view.rule.name), ['Rent']);
    expect((await recurring.getViews()).map((view) => view.rule.groupId), [null]);
  });
}
