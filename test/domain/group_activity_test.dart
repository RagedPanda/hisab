import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/group_activity.dart';

void main() {
  final dinner = ExpenseSnapshot(
    amountMinor: 90000,
    occurredAt: DateTime(2026, 10, 20, 21),
    note: 'Dinner',
    categoryId: 'food',
    payers: const [MemberAmount(memberId: 'me', amountMinor: 90000)],
    shares: const [
      MemberAmount(memberId: 'me', amountMinor: 30000, rowId: 's1'),
      MemberAmount(memberId: 'rahul', amountMinor: 30000, rowId: 's2'),
      MemberAmount(memberId: 'priya', amountMinor: 30000, rowId: 's3'),
    ],
    splitMethod: 'equal',
  );
  final payment = PaymentSnapshot(fromMemberId: 'rahul', toMemberId: 'me', amountMinor: 30000, occurredAt: DateTime(2026, 10, 21));

  group('snapshots', () {
    test('an expense survives a JSON round trip, row ids included', () {
      final decoded = ActivitySnapshot.decode(dinner.encode())! as ExpenseSnapshot;
      expect(decoded.toJson(), dinner.toJson());
      expect(decoded.shares.map((share) => share.rowId), ['s1', 's2', 's3']);
    });

    test('a payment survives a JSON round trip', () {
      expect(ActivitySnapshot.decode(payment.encode())!.toJson(), payment.toJson());
    });

    test('null, empty and unreadable text decode to null', () {
      expect(ActivitySnapshot.decode(null), isNull);
      expect(ActivitySnapshot.decode(''), isNull);
      expect(ActivitySnapshot.decode('{oops'), isNull);
      expect(ActivitySnapshot.decode('{"type":"robot"}'), isNull);
    });

    test('action and subject names fall back instead of throwing', () {
      expect(activityActionFrom('deleted'), ActivityAction.deleted);
      expect(activityActionFrom('???'), ActivityAction.edited);
      expect(activitySubjectFrom('payment'), ActivitySubject.payment);
    });
  });

  group('diffSnapshots for expenses', () {
    test('identical snapshots have no changes', () {
      expect(diffSnapshots(dinner, dinner), isEmpty);
      expect(isMeaningfulEdit(dinner, dinner), isFalse);
    });

    test('amount, description, day and category each show up once', () {
      final edited = ExpenseSnapshot(
        amountMinor: 120000,
        occurredAt: DateTime(2026, 10, 21),
        note: 'Late dinner',
        categoryId: 'travel',
        payers: dinner.payers,
        shares: dinner.shares,
      );
      final changes = diffSnapshots(dinner, edited);
      expect(changes.map((change) => change.runtimeType), [DescriptionChange, AmountChange, DateChange, CategoryChange]);
      final amount = changes.whereType<AmountChange>().single;
      expect((amount.fromMinor, amount.toMinor), (90000, 120000));
    });

    test('a time-of-day change alone is not a date change', () {
      final sameDay = ExpenseSnapshot(amountMinor: 90000, occurredAt: DateTime(2026, 10, 20, 9), note: 'Dinner', categoryId: 'food', payers: dinner.payers, shares: dinner.shares, splitMethod: 'equal');
      expect(diffSnapshots(dinner, sameDay), isEmpty);
    });

    test('the description falls back to the payee', () {
      final withPayee = ExpenseSnapshot(amountMinor: 90000, occurredAt: dinner.occurredAt, payee: 'Swiggy', categoryId: 'food', payers: dinner.payers, shares: dinner.shares);
      final change = diffSnapshots(dinner, withPayee).whereType<DescriptionChange>().single;
      expect((change.from, change.to), ('Dinner', 'Swiggy'));
    });

    test('a new payer set is one change, independent of row order', () {
      final twoPayers = ExpenseSnapshot(
        amountMinor: 90000,
        occurredAt: dinner.occurredAt,
        note: 'Dinner',
        categoryId: 'food',
        payers: const [MemberAmount(memberId: 'rahul', amountMinor: 40000), MemberAmount(memberId: 'me', amountMinor: 50000)],
        shares: dinner.shares,
      );
      final change = diffSnapshots(dinner, twoPayers).whereType<PayersChange>().single;
      expect(change.fromMemberIds, ['me']);
      expect(change.toMemberIds, ['me', 'rahul']);
    });

    test('moving money between several payers is a payer change', () {
      ExpenseSnapshot paidBy(int mine, int rahuls) => ExpenseSnapshot(
            amountMinor: 120000,
            occurredAt: dinner.occurredAt,
            note: 'Dinner',
            categoryId: 'food',
            payers: [MemberAmount(memberId: 'rahul', amountMinor: rahuls), MemberAmount(memberId: 'me', amountMinor: mine)],
            shares: dinner.shares,
          );
      final changes = diffSnapshots(paidBy(40000, 80000), paidBy(50000, 70000));
      final change = changes.whereType<PayersChange>().single;
      expect([for (final payer in change.from) (payer.memberId, payer.amountMinor)], [('me', 40000), ('rahul', 80000)]);
      expect([for (final payer in change.to) (payer.memberId, payer.amountMinor)], [('me', 50000), ('rahul', 70000)]);
      expect(isMeaningfulEdit(paidBy(40000, 80000), paidBy(50000, 70000)), isTrue);
    });

    test('a lone payer paying a new total is only an amount change', () {
      final pricier = ExpenseSnapshot(
        amountMinor: 120000,
        occurredAt: dinner.occurredAt,
        note: 'Dinner',
        categoryId: 'food',
        payers: const [MemberAmount(memberId: 'me', amountMinor: 120000)],
        shares: dinner.shares,
      );
      expect(diffSnapshots(dinner, pricier).whereType<PayersChange>(), isEmpty);
      expect(diffSnapshots(dinner, pricier).whereType<AmountChange>(), hasLength(1));
    });

    test('share changes list who moved, who joined and who left', () {
      final reshared = ExpenseSnapshot(
        amountMinor: 90000,
        occurredAt: dinner.occurredAt,
        note: 'Dinner',
        categoryId: 'food',
        payers: dinner.payers,
        shares: const [
          MemberAmount(memberId: 'me', amountMinor: 30000),
          MemberAmount(memberId: 'rahul', amountMinor: 45000),
          MemberAmount(memberId: 'amit', amountMinor: 15000),
        ],
      );
      final shares = diffSnapshots(dinner, reshared).whereType<ShareChange>().map((change) => (change.memberId, change.fromMinor, change.toMinor));
      expect(shares, [('rahul', 30000, 45000), ('priya', 30000, 0), ('amit', 0, 15000)]);
    });
  });

  group('diffSnapshots for payments', () {
    test('swapped parties, amount, method and note are reported', () {
      final edited = PaymentSnapshot(fromMemberId: 'me', toMemberId: 'rahul', amountMinor: 25000, occurredAt: payment.occurredAt, method: 'upi', note: 'GPay');
      final changes = diffSnapshots(payment, edited);
      expect(changes.map((change) => change.runtimeType), [PartiesChange, AmountChange, MethodChange, NoteChange]);
    });

    test('an expense and a payment are never compared', () {
      expect(diffSnapshots(dinner, payment), isEmpty);
    });
  });

  group('restorableActivityIds', () {
    ActivityRecord deletion(String id, String entryId, DateTime at, {ActivitySubject subject = ActivitySubject.expense}) => ActivityRecord(
          id: id,
          groupId: 'g1',
          action: ActivityAction.deleted,
          subject: subject,
          subjectId: entryId,
          actorMemberId: 'me',
          occurredAt: at,
          before: dinner,
        );

    test('only the latest deletion of a still-deleted expense offers Restore', () {
      final activities = [
        deletion('a1', 'e1', DateTime(2026, 10, 20)),
        deletion('a2', 'e1', DateTime(2026, 10, 22)),
        deletion('a3', 'e2', DateTime(2026, 10, 21)),
        deletion('a4', 'p1', DateTime(2026, 10, 21), subject: ActivitySubject.payment),
      ];
      expect(restorableActivityIds(activities, deletedExpenseIds: {'e1', 'p1'}), {'a2'});
    });

    test('a restored expense offers nothing', () {
      expect(restorableActivityIds([deletion('a1', 'e1', DateTime(2026, 10, 20))], deletedExpenseIds: const {}), isEmpty);
    });
  });

  test('a record diffs its own before and after', () {
    final record = ActivityRecord(
      id: 'a1',
      groupId: 'g1',
      action: ActivityAction.edited,
      subject: ActivitySubject.payment,
      subjectId: 'p1',
      actorMemberId: 'me',
      occurredAt: DateTime(2026, 10, 22),
      before: payment,
      after: PaymentSnapshot(fromMemberId: 'rahul', toMemberId: 'me', amountMinor: 35000, occurredAt: payment.occurredAt),
    );
    expect(record.changes.single, isA<AmountChange>());
    expect(record.latest, same(record.after));
  });
}
