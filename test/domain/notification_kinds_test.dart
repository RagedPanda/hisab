import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/notifications/notification_kinds.dart';

void main() {
  bool on(NotificationKind kind, {Map<NotificationKind, bool> choices = const {}, NotificationFacts facts = const NotificationFacts()}) =>
      notificationKindOn(kind, choices: choices, facts: facts);

  test('a new install starts with every kind off', () {
    for (final kind in NotificationKind.values) {
      expect(on(kind), isFalse, reason: kind.name);
    }
  });

  group('an untouched switch follows what the user already set up', () {
    test('upgrading with reminders keeps their alerts', () {
      expect(on(NotificationKind.reminders, facts: const NotificationFacts(hasReminders: true)), isTrue);
    });

    test('upgrading with Bank SMS on keeps its notification', () {
      expect(on(NotificationKind.bankSms, facts: const NotificationFacts(smsEnabled: true)), isTrue);
    });

    test('the salary alert follows the salary setup', () {
      expect(on(NotificationKind.salary, facts: const NotificationFacts(salaryAlertOn: true)), isTrue);
      expect(on(NotificationKind.salary, facts: const NotificationFacts()), isFalse);
    });

    test('the evening summary is new, so it stays off whatever else is set up', () {
      const everything = NotificationFacts(hasReminders: true, salaryAlertOn: true, smsEnabled: true);
      expect(on(NotificationKind.eveningSummary, facts: everything), isFalse);
    });
  });

  test("the user's own choice wins over the setup", () {
    const everything = NotificationFacts(hasReminders: true, smsEnabled: true);
    expect(on(NotificationKind.reminders, choices: {NotificationKind.reminders: false}, facts: everything), isFalse);
    expect(on(NotificationKind.bankSms, choices: {NotificationKind.bankSms: false}, facts: everything), isFalse);
    expect(on(NotificationKind.eveningSummary, choices: {NotificationKind.eveningSummary: true}), isTrue);
    expect(on(NotificationKind.reminders, choices: {NotificationKind.reminders: true}), isTrue);
  });

  test('reminder and Bank SMS alerts are posted unless switched off', () {
    expect(reminderAlertsAllowed(const {}), isTrue);
    expect(reminderAlertsAllowed({NotificationKind.reminders: false}), isFalse);
    expect(bankSmsAlertsAllowed(const {}), isTrue);
    expect(bankSmsAlertsAllowed({NotificationKind.bankSms: false}), isFalse);
    expect(bankSmsAlertsAllowed({NotificationKind.reminders: false}), isTrue);
  });
}
