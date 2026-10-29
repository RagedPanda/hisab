/// The kinds of notification Settings > Notifications switches on and off,
/// and how a switch the user never touched is read. Pure: no I/O, no clock.
library;

/// Every kind of notification Hisab can post, in the order the Settings
/// screen lists them. A new kind is one more value here plus its texts and
/// sample in lib/features/notifications.
enum NotificationKind {
  /// Alerts of reminders: bills, documents, card dues and group settle-ups.
  reminders,

  /// "Salary not seen yet"; stored on the salary setup, not here.
  salary,

  /// "New bank transaction", posted by the native SMS receiver.
  bankSms,

  /// Once a day at a chosen time: today's spend, SMS to review, bills due soon.
  eveningSummary,

  /// The persistent "Add expense" shortcut in the notification shade;
  /// stored on Settings > Shortcuts & widget, not here.
  addExpenseShortcut,
}

/// What this install already does without having been asked, so a switch
/// the user has never touched shows (and behaves) the way Hisab worked
/// before the switches existed.
class NotificationFacts {
  const NotificationFacts({this.hasReminders = false, this.salaryAlertOn = false, this.smsEnabled = false, this.addExpenseShortcutOn = false});

  /// Any pending reminder (or settle-up schedule) with alerts.
  final bool hasReminders;

  /// Salary is set up and its "not seen yet" alert is on.
  final bool salaryAlertOn;

  /// The user opted in to Bank SMS.
  final bool smsEnabled;

  /// The persistent "Add expense" notification is on (off until turned on).
  final bool addExpenseShortcutOn;
}

/// Whether [kind] is on, given the user's explicit [choices] (kinds absent
/// from it were never touched) and the install's [facts].
///
/// New installs start with everything off. A kind tied to something the user
/// set up themselves (a reminder, salary, Bank SMS) follows that setup until
/// they flip its switch, so nobody upgrading loses an alert they relied on
/// and creating a reminder still notifies. The evening summary is new and
/// stays off until it is turned on.
bool notificationKindOn(NotificationKind kind, {required Map<NotificationKind, bool> choices, required NotificationFacts facts}) =>
    switch (kind) {
      NotificationKind.reminders => choices[kind] ?? facts.hasReminders,
      NotificationKind.salary => facts.salaryAlertOn,
      NotificationKind.bankSms => choices[kind] ?? facts.smsEnabled,
      NotificationKind.eveningSummary => choices[kind] ?? false,
      NotificationKind.addExpenseShortcut => facts.addExpenseShortcutOn,
    };

/// Whether reminder alerts may be posted: true unless the user turned the
/// Reminders switch off. (A reminder being scheduled is itself the setup
/// [notificationKindOn] follows.)
bool reminderAlertsAllowed(Map<NotificationKind, bool> choices) => choices[NotificationKind.reminders] ?? true;

/// Whether the native receiver may post "New bank transaction" while Bank
/// SMS is on: true unless the user turned the switch off.
bool bankSmsAlertsAllowed(Map<NotificationKind, bool> choices) => choices[NotificationKind.bankSms] ?? true;
