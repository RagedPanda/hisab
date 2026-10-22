import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/group_activity.dart';
import 'package:hisab/features/groups/activity_messages.dart';
import 'package:hisab/l10n/generated/app_localizations_en.dart';
import 'package:hisab/l10n/generated/app_localizations_hi.dart';

void main() {
  final l10n = AppLocalizationsEn();
  const names = {'me': 'You', 'rahul': 'Rahul', 'priya': 'Priya'};
  final format = ActivityFormatters(
    nameOf: (id) => names[id] ?? 'Unknown',
    categoryNameOf: (id) => id == null ? 'Expense' : (id == 'food' ? 'Food' : 'Travel'),
    money: (minor) => '₹${minor ~/ 100}',
    date: (day) => '${day.day} Oct',
    myMemberId: 'me',
  );
  final dinner = ExpenseSnapshot(
    amountMinor: 90000,
    occurredAt: DateTime(2026, 10, 20),
    note: 'Dinner',
    categoryId: 'food',
    payers: const [MemberAmount(memberId: 'rahul', amountMinor: 90000)],
    shares: const [MemberAmount(memberId: 'me', amountMinor: 45000), MemberAmount(memberId: 'rahul', amountMinor: 45000)],
  );
  final payment = PaymentSnapshot(fromMemberId: 'rahul', toMemberId: 'me', amountMinor: 30000, occurredAt: DateTime(2026, 10, 21));

  ActivityRecord record(ActivityAction action, {ActivitySnapshot? before, ActivitySnapshot? after, ActivitySubject subject = ActivitySubject.expense, String? actor = 'me'}) => ActivityRecord(
        id: 'a1',
        groupId: 'g1',
        action: action,
        subject: subject,
        subjectId: 'x',
        actorMemberId: actor,
        occurredAt: DateTime(2026, 10, 22),
        before: before,
        after: after,
      );

  test('an added expense names the actor, the title, the amount and the payer', () {
    final words = activityWords(l10n, record(ActivityAction.added, after: dinner), format);
    expect(words.headline, 'You added “Dinner”');
    expect(words.details, ['₹900 · paid by Rahul']);
  });

  test('a deleted expense reads from its before state', () {
    final words = activityWords(l10n, record(ActivityAction.deleted, before: dinner, actor: 'rahul'), format);
    expect(words.headline, 'Rahul deleted “Dinner”');
    expect(words.details.single, startsWith('₹900'));
  });

  test('an expense without a description is called by its category', () {
    final untitled = ExpenseSnapshot(amountMinor: 100, occurredAt: DateTime(2026, 10, 20), categoryId: 'travel', payers: const [], shares: const []);
    expect(activityWords(l10n, record(ActivityAction.restored, after: untitled), format).headline, 'You restored “Travel”');
  });

  test('an edited expense lists each change as before → after', () {
    final edited = ExpenseSnapshot(
      amountMinor: 120000,
      occurredAt: DateTime(2026, 10, 21),
      categoryId: 'travel',
      payers: const [MemberAmount(memberId: 'rahul', amountMinor: 60000), MemberAmount(memberId: 'me', amountMinor: 60000)],
      shares: const [MemberAmount(memberId: 'me', amountMinor: 40000), MemberAmount(memberId: 'rahul', amountMinor: 40000), MemberAmount(memberId: 'priya', amountMinor: 40000)],
    );
    final words = activityWords(l10n, record(ActivityAction.edited, before: dinner, after: edited), format);
    expect(words.headline, 'You edited “Travel”');
    expect(words.details, [
      'Description: Dinner → none',
      'Amount: ₹900 → ₹1200',
      'Date: 20 Oct → 21 Oct',
      'Category: Food → Travel',
      'Paid by: Rahul → Rahul and you',
      "Your share: ₹450 → ₹400",
      "Rahul's share: ₹450 → ₹400",
      "Priya's share: ₹0 → ₹400",
    ]);
  });

  test('payments name who paid whom, and an edit adds what changed', () {
    final added = activityWords(l10n, record(ActivityAction.added, after: payment, subject: ActivitySubject.payment), format);
    expect(added.headline, 'You recorded a payment');
    expect(added.details, ['Rahul paid you ₹300']);
    final edited = PaymentSnapshot(fromMemberId: 'me', toMemberId: 'rahul', amountMinor: 30000, occurredAt: payment.occurredAt, method: 'upi', note: 'GPay');
    final words = activityWords(l10n, record(ActivityAction.edited, before: payment, after: edited, subject: ActivitySubject.payment), format);
    expect(words.headline, 'You edited a payment');
    expect(words.details, ['You paid Rahul ₹300', 'Who paid whom: Rahul to you → You to Rahul', 'Method: Cash → UPI', 'Note: none → GPay']);
    expect(activityWords(l10n, record(ActivityAction.deleted, before: payment, subject: ActivitySubject.payment), format).headline, 'You removed a payment');
  });

  test('a row whose snapshot is unreadable still has a headline', () {
    final unreadable = activityWords(l10n, record(ActivityAction.deleted), format);
    expect(unreadable.headline, 'You deleted “Expense”');
    expect(unreadable.details, isEmpty);
    expect(activityWords(l10n, record(ActivityAction.restored, subject: ActivitySubject.payment, actor: null), format).headline, 'You restored a payment');
  });

  test('Hindi wording carries every value', () {
    final words = activityWords(AppLocalizationsHi(), record(ActivityAction.edited, before: payment, after: PaymentSnapshot(fromMemberId: 'rahul', toMemberId: 'me', amountMinor: 45000, occurredAt: payment.occurredAt), subject: ActivitySubject.payment), format);
    expect(words.details.last, 'राशि: ₹300 → ₹450');
    expect(activityWords(AppLocalizationsHi(), record(ActivityAction.added, after: dinner, actor: 'rahul'), format).headline, 'Rahul ने “Dinner” जोड़ा');
  });
}
