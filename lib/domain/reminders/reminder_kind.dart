/// What a due reminder is about. The stored value is [key].
enum ReminderKind {
  bill('bill'),
  emi('emi'),
  card('card'),
  subscription('subscription'),
  insurance('insurance'),
  document('document'),
  custom('custom');

  const ReminderKind(this.key);
  final String key;

  /// Paying it creates an expense entry; documents and custom nudges are just ticked off.
  bool get isMoney => this != document && this != custom;

  static ReminderKind? fromKey(String key) {
    for (final kind in values) {
      if (kind.key == key) return kind;
    }
    return null;
  }

  /// [fromKey] for stored rows, treating an unknown key as [custom].
  static ReminderKind of(String key) => fromKey(key) ?? custom;
}

/// Every stored [ReminderKind.key], for queries that must skip settle_up rows.
final List<String> dueReminderKindKeys = [for (final kind in ReminderKind.values) kind.key];

/// How a reminder comes back after it is paid or skipped. The stored value is [key].
enum ReminderRepeat {
  once('once'),
  weekly('weekly'),
  monthly('monthly'),
  quarterly('quarterly'),
  yearly('yearly');

  const ReminderRepeat(this.key);
  final String key;

  bool get repeats => this != once;

  static ReminderRepeat fromKey(String key) {
    for (final repeat in values) {
      if (repeat.key == key) return repeat;
    }
    return once;
  }
}

/// Stored values of the reminder status column.
abstract final class ReminderStatus {
  static const pending = 'pending';
  static const done = 'done';
  static const skipped = 'skipped';
}
