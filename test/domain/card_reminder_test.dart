import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/cards/card_reminder.dart';
import 'package:hisab/domain/cards/card_summary.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/reminders/reminder_schedule.dart';

void main() {
  final due = CardDue(dueDate: DateTime(2026, 11, 15), daysLeft: 10, state: CardDueState.upcoming, amountDueMinor: 2500000);

  CardReminderPlan plan({CardDue? cardDue, List<ExistingCardReminder> existing = const [], String name = 'HDFC Millennia'}) =>
      planCardReminder(accountId: 'card', cardName: name, due: cardDue, existing: existing);

  ExistingCardReminder stored({
    String id = 'r1',
    String status = ReminderStatus.pending,
    DateTime? dueAt,
    int? amountMinor = 2500000,
    String title = 'HDFC Millennia',
    List<int> remindDaysBefore = kCardReminderDaysBefore,
    int? notifyAtMinute = kDefaultNotifyMinute,
    String notes = '',
  }) =>
      ExistingCardReminder(
        status: status,
        draft: ReminderDraft(
          id: id,
          kind: ReminderKind.card,
          title: title,
          accountId: 'card',
          dueAt: dueAt ?? DateTime(2026, 11, 15),
          amountMinor: amountMinor,
          remindDaysBefore: remindDaysBefore,
          notifyAtMinute: notifyAtMinute,
          notes: notes,
        ),
      );

  group('cardReminderDraft', () {
    test('is a one-off card reminder on the due day, 3 days ahead and on the day', () {
      final draft = cardReminderDraft(accountId: 'card', cardName: 'HDFC Millennia', due: due);
      expect(draft.id, isNull);
      expect(draft.kind, ReminderKind.card);
      expect(draft.title, 'HDFC Millennia');
      expect(draft.accountId, 'card');
      expect(draft.dueAt, DateTime(2026, 11, 15));
      expect(draft.amountMinor, 2500000);
      expect(draft.repeat, ReminderRepeat.once);
      expect(draft.remindDaysBefore, [3, 0]);
      expect(draft.notifyAtMinute, kDefaultNotifyMinute);
    });

    test('drops the time of day from the due date', () {
      final timed = CardDue(dueDate: DateTime(2026, 11, 15, 18, 30), daysLeft: 3, state: CardDueState.upcoming);
      expect(cardReminderDraft(accountId: 'card', cardName: 'Card', due: timed).dueAt, DateTime(2026, 11, 15));
    });

    test('leaves the amount empty when nothing or an unknown amount is due', () {
      final paid = CardDue(dueDate: DateTime(2026, 12, 15), daysLeft: 40, state: CardDueState.paid, amountDueMinor: 0);
      final unknown = CardDue(dueDate: DateTime(2026, 12, 15), daysLeft: 40, state: CardDueState.upcoming);
      expect(cardReminderDraft(accountId: 'card', cardName: 'Card', due: paid).amountMinor, isNull);
      expect(cardReminderDraft(accountId: 'card', cardName: 'Card', due: unknown).amountMinor, isNull);
    });
  });

  group('planCardReminder', () {
    test('creates a reminder when the card has none', () {
      final result = plan(cardDue: due);
      expect(result.save, isNotNull);
      expect(result.save!.id, isNull);
      expect(result.deleteIds, isEmpty);
    });

    test('keeps a pending reminder that already matches', () {
      expect(plan(cardDue: due, existing: [stored()]).isEmpty, isTrue);
    });

    test('updates the pending reminder in place when the date, amount or name changes', () {
      for (final existing in [
        stored(dueAt: DateTime(2026, 10, 15)),
        stored(amountMinor: 1000000),
        stored(title: 'Old name'),
      ]) {
        final result = plan(cardDue: due, existing: [existing]);
        expect(result.save!.id, 'r1');
        expect(result.save!.dueAt, DateTime(2026, 11, 15));
        expect(result.deleteIds, isEmpty);
      }
    });

    test('moving the pending reminder keeps the alert days, time and notes the user set', () {
      final result = plan(cardDue: due, existing: [
        stored(dueAt: DateTime(2026, 10, 20), remindDaysBefore: const [7, 1], notifyAtMinute: 20 * 60, notes: 'autopay off'),
      ]);
      final draft = result.save!;
      expect(draft.id, 'r1');
      expect(draft.dueAt, DateTime(2026, 11, 15));
      expect(draft.amountMinor, 2500000);
      expect(draft.remindDaysBefore, [7, 1]);
      expect(draft.notifyAtMinute, 20 * 60);
      expect(draft.notes, 'autopay off');
    });

    test('only a new reminder gets the default alert days', () {
      expect(plan(cardDue: due).save!.remindDaysBefore, kCardReminderDaysBefore);
      final afterPaid = plan(cardDue: due, existing: [stored(status: ReminderStatus.done, dueAt: DateTime(2026, 10, 15), remindDaysBefore: const [7])]);
      expect(afterPaid.save!.remindDaysBefore, kCardReminderDaysBefore);
    });

    test('a newer closed reminder does not stop the pending one being updated in place (#59)', () {
      final result = plan(cardDue: due, existing: [
        stored(id: 'done-nov-28', status: ReminderStatus.done, dueAt: DateTime(2026, 11, 28), amountMinor: null),
        stored(id: 'pending', dueAt: DateTime(2026, 10, 20)),
      ]);
      expect(result.save!.id, 'pending');
      expect(result.save!.dueAt, DateTime(2026, 11, 15));
      expect(result.deleteIds, isEmpty);
    });

    test('collapses duplicate pending reminders into one, keeping the one on the due date (#59)', () {
      final result = plan(cardDue: due, existing: [
        stored(id: 'a', dueAt: DateTime(2026, 10, 20)),
        stored(id: 'b', dueAt: DateTime(2026, 11, 15)),
        stored(id: 'c', dueAt: DateTime(2026, 10, 31)),
      ]);
      expect(result.save, isNull, reason: 'b already matches');
      expect(result.deleteIds, ['a', 'c']);
    });

    test('does not re-raise a reminder already marked paid or skipped for this due date', () {
      expect(plan(cardDue: due, existing: [stored(status: ReminderStatus.done)]).isEmpty, isTrue);
      expect(plan(cardDue: due, existing: [stored(status: ReminderStatus.skipped)]).isEmpty, isTrue);
      final withStray = plan(cardDue: due, existing: [stored(status: ReminderStatus.done), stored(id: 'stray', dueAt: DateTime(2026, 10, 20))]);
      expect(withStray.save, isNull);
      expect(withStray.deleteIds, ['stray']);
    });

    test('starts a new reminder for the next bill once the last one is closed', () {
      final result = plan(cardDue: due, existing: [stored(status: ReminderStatus.done, dueAt: DateTime(2026, 10, 15))]);
      expect(result.save!.id, isNull);
    });

    test('deletes every pending reminder when the due date goes away, even with a newer closed one (#59)', () {
      final result = plan(existing: [
        stored(id: 'done', status: ReminderStatus.done, dueAt: DateTime(2026, 11, 28)),
        stored(id: 'p1', dueAt: DateTime(2026, 10, 20)),
        stored(id: 'p2', dueAt: DateTime(2026, 10, 31)),
      ]);
      expect(result.save, isNull);
      expect(result.deleteIds, ['p1', 'p2']);
    });

    test('a paid bill moves the pending reminder on to the next bill', () {
      final paid = CardDue(dueDate: DateTime(2026, 11, 15), daysLeft: 10, state: CardDueState.paid, amountDueMinor: 0, nextDueDate: DateTime(2026, 12, 15));
      final result = plan(cardDue: paid, existing: [stored(id: 'p1')]);
      expect(result.save!.id, 'p1');
      expect(result.save!.dueAt, DateTime(2026, 12, 15));
      expect(result.save!.amountMinor, isNull);
      expect(result.deleteIds, isEmpty);
    });

    test('a paid bill with no known next due date clears the pending reminder', () {
      final paid = CardDue(dueDate: DateTime(2026, 11, 15), daysLeft: 10, state: CardDueState.paid, amountDueMinor: 0);
      final result = plan(cardDue: paid, existing: [stored(id: 'p1')]);
      expect(result.save, isNull);
      expect(result.deleteIds, ['p1']);
    });

    test('keeps closed reminders in history when the due date goes away', () {
      expect(plan(existing: [stored(status: ReminderStatus.done)]).isEmpty, isTrue);
      expect(plan().isEmpty, isTrue);
    });
  });
}
