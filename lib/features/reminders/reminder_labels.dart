import 'package:flutter/material.dart';

import '../../domain/reminders/reminder_buckets.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../l10n/generated/app_localizations.dart';

String reminderKindLabel(AppLocalizations l10n, ReminderKind kind) => switch (kind) {
      ReminderKind.bill => l10n.reminderKindBill,
      ReminderKind.emi => l10n.reminderKindEmi,
      ReminderKind.card => l10n.reminderKindCard,
      ReminderKind.subscription => l10n.reminderKindSubscription,
      ReminderKind.insurance => l10n.reminderKindInsurance,
      ReminderKind.document => l10n.reminderKindDocument,
      ReminderKind.custom => l10n.reminderKindCustom,
    };

IconData reminderKindIcon(ReminderKind kind) => switch (kind) {
      ReminderKind.bill => Icons.receipt_long_outlined,
      ReminderKind.emi => Icons.account_balance_outlined,
      ReminderKind.card => Icons.credit_card_outlined,
      ReminderKind.subscription => Icons.autorenew,
      ReminderKind.insurance => Icons.health_and_safety_outlined,
      ReminderKind.document => Icons.description_outlined,
      ReminderKind.custom => Icons.event_outlined,
    };

String reminderRepeatLabel(AppLocalizations l10n, ReminderRepeat repeat) => switch (repeat) {
      ReminderRepeat.once => l10n.reminderRepeatOnce,
      ReminderRepeat.weekly => l10n.reminderRepeatWeekly,
      ReminderRepeat.monthly => l10n.reminderRepeatMonthly,
      ReminderRepeat.quarterly => l10n.reminderRepeatQuarterly,
      ReminderRepeat.yearly => l10n.reminderRepeatYearly,
    };

String reminderBucketLabel(AppLocalizations l10n, ReminderBucket bucket) => switch (bucket) {
      ReminderBucket.overdue => l10n.reminderSectionOverdue,
      ReminderBucket.thisWeek => l10n.reminderSectionThisWeek,
      ReminderBucket.later => l10n.reminderSectionLater,
    };

String reminderDaysBeforeLabel(AppLocalizations l10n, int days) => days == 0 ? l10n.reminderNotifyOnDay : l10n.reminderNotifyDaysBefore(days);
