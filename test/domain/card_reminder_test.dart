import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/cards/card_reminder.dart';
import 'package:hisab/domain/cards/card_summary.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/reminders/reminder_schedule.dart';

void main() {
  final due = CardDue(dueDate: DateTime(2026, 11, 15), daysLeft: 10, state: CardDueState.upcoming, amountDueMinor: 2500000);

  CardReminderAction plan({CardDue? cardDue, ExistingCardReminder? existing, String name = 'HDFC Millennia'}) =>
      planCardReminder(accountId: 'card', cardName: name, due: cardDue, existing: existing);

  ExistingCardReminder stored({String status = ReminderStatus.pending, DateTime? dueAt, int? amountMinor = 2500000, String title = 'HDFC Millennia'}) =>
      ExistingCardReminder(id: 'r1', dueAt: dueAt ?? DateTime(2026, 11, 15), status: status, title: title, amountMinor: amountMinor);

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
      final action = plan(cardDue: due);
      expect(action, isA<SaveCardReminder>());
      expect((action as SaveCardReminder).draft.id, isNull);
    });

    test('keeps a pending reminder that already matches', () {
      expect(plan(cardDue: due, existing: stored()), isA<KeepCardReminder>());
    });

    test('updates the pending reminder in place when the date, amount or name changes', () {
      for (final existing in [
        stored(dueAt: DateTime(2026, 10, 15)),
        stored(amountMinor: 1000000),
        stored(title: 'Old name'),
      ]) {
        final action = plan(cardDue: due, existing: existing);
        expect(action, isA<SaveCardReminder>());
        expect((action as SaveCardReminder).draft.id, 'r1');
        expect(action.draft.dueAt, DateTime(2026, 11, 15));
      }
    });

    test('does not re-raise a reminder already marked paid or skipped for this due date', () {
      expect(plan(cardDue: due, existing: stored(status: ReminderStatus.done)), isA<KeepCardReminder>());
      expect(plan(cardDue: due, existing: stored(status: ReminderStatus.skipped)), isA<KeepCardReminder>());
    });

    test('starts a new reminder for the next bill once the last one is closed', () {
      final action = plan(cardDue: due, existing: stored(status: ReminderStatus.done, dueAt: DateTime(2026, 10, 15)));
      expect(action, isA<SaveCardReminder>());
      expect((action as SaveCardReminder).draft.id, isNull);
    });

    test('deletes the pending reminder when the due date goes away', () {
      final action = plan(existing: stored());
      expect(action, isA<DeleteCardReminder>());
      expect((action as DeleteCardReminder).id, 'r1');
    });

    test('keeps closed reminders in history when the due date goes away', () {
      expect(plan(existing: stored(status: ReminderStatus.done)), isA<KeepCardReminder>());
      expect(plan(), isA<KeepCardReminder>());
    });
  });
}
