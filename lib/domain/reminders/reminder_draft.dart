import 'reminder_kind.dart';
import 'reminder_schedule.dart';

/// A reminder amount as stored and shown: 0 means "no amount" (owner
/// decision 23), so it becomes null and nothing shows an amount for it.
int? reminderAmountOrNone(int? amountMinor) => amountMinor == null || amountMinor == 0 ? null : amountMinor;

/// Everything the editor (or another feature) supplies to create or update a
/// due reminder. [id] null creates a new one.
class ReminderDraft {
  const ReminderDraft({
    this.id,
    required this.kind,
    required this.title,
    required this.dueAt,
    this.notes = '',
    this.amountMinor,
    this.categoryId,
    this.accountId,
    this.recurringId,
    this.assetId,
    this.repeat = ReminderRepeat.once,
    this.remindDaysBefore = const [0],
    this.notifyAtMinute = kDefaultNotifyMinute,
    this.matchKeywords = '',
    this.toleranceMinor = 0,
    this.projectId,
    this.documentNumber = '',
    this.presetKey,
  });

  final String? id;
  final ReminderKind kind;
  final String title;

  /// Due day; only the date part matters, notifications use [notifyAtMinute].
  final DateTime dueAt;
  final String notes;
  final int? amountMinor;
  final String? categoryId;
  final String? accountId;
  final String? recurringId;
  final String? assetId;
  final ReminderRepeat repeat;
  final List<int> remindDaysBefore;

  /// Minutes after local midnight to notify; null turns notifications off.
  final int? notifyAtMinute;
  final String matchKeywords;
  final int toleranceMinor;

  /// Project the reminder belongs to (the Vehicle project's PUC).
  final String? projectId;

  /// Policy, registration or document number, kept for reference.
  final String documentNumber;

  /// Document preset the reminder was created from (lib/domain/reminders/document_presets.dart).
  final String? presetKey;

  /// The due day at midnight, the form stored in the database.
  DateTime get dueDay => DateTime(dueAt.year, dueAt.month, dueAt.day);

  /// Day of month a repeating reminder keeps, or null for one-offs and weekly.
  int? get repeatDay => switch (repeat) {
        ReminderRepeat.once || ReminderRepeat.weekly => null,
        _ => dueAt.day,
      };

  /// Why this draft cannot be saved, or null when it can.
  ReminderDraftError? get error {
    if (title.trim().isEmpty) return ReminderDraftError.missingTitle;
    if (amountMinor != null && amountMinor! < 0) return ReminderDraftError.negativeAmount;
    return null;
  }
}

enum ReminderDraftError { missingTitle, negativeAmount }
