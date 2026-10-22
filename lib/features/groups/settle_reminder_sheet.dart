import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/db/database.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/split/settle_reminder.dart';
import '../../l10n/l10n.dart';
import 'settle_up_messages.dart';

/// What the sheet returns: the new schedule, or a null schedule for "turn
/// off". The sheet itself returns null when dismissed.
typedef SettleReminderChoice = ({SettleReminderSchedule? schedule});

/// "Remind me to settle up": about everyone or one member, monthly on a day
/// (or the last day) or weekly on a weekday, with the next reminder shown.
Future<SettleReminderChoice?> showSettleReminderSheet(
  BuildContext context, {
  required List<Member> otherMembers,
  SettleReminderSchedule? existing,
  DateTime Function() clock = DateTime.now,
}) =>
    showModalBottomSheet<SettleReminderChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SettleReminderSheet(otherMembers: otherMembers, existing: existing, clock: clock),
    );

/// Days offered for a monthly reminder; [kLastDayOfMonth] covers 29 to 31.
final List<int> kSettleReminderDays = List.unmodifiable([for (var day = 1; day <= 28; day++) day, kLastDayOfMonth]);

class _SettleReminderSheet extends StatefulWidget {
  const _SettleReminderSheet({required this.otherMembers, required this.existing, required this.clock});
  final List<Member> otherMembers;
  final SettleReminderSchedule? existing;
  final DateTime Function() clock;

  @override
  State<_SettleReminderSheet> createState() => _SettleReminderSheetState();
}

class _SettleReminderSheetState extends State<_SettleReminderSheet> {
  late String? _memberId = widget.existing?.memberId;
  late RecurrenceFrequency _frequency = widget.existing?.frequency ?? RecurrenceFrequency.monthly;
  late int _dayOfMonth = widget.existing?.dayOfMonth ?? 1;
  late int _weekday = widget.existing?.weekday ?? DateTime.sunday;

  SettleReminderSchedule get _schedule => SettleReminderSchedule(
        frequency: _frequency,
        dayOfMonth: _frequency == RecurrenceFrequency.monthly ? _dayOfMonth : null,
        weekday: _frequency == RecurrenceFrequency.weekly ? _weekday : null,
        memberId: _memberId,
      );

  Widget _chips(List<Widget> chips) => Wrap(spacing: 8, runSpacing: 4, children: chips);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final next = nextSettleReminderAt(_schedule, now: widget.clock());
    final label = theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settleReminderSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.settleReminderWith, style: label),
            const SizedBox(height: 4),
            _chips([
              ChoiceChip(label: Text(l10n.settleReminderEveryone), selected: _memberId == null, onSelected: (_) => setState(() => _memberId = null)),
              for (final member in widget.otherMembers)
                ChoiceChip(label: Text(member.name), selected: _memberId == member.id, onSelected: (_) => setState(() => _memberId = member.id)),
            ]),
            const SizedBox(height: 16),
            Text(l10n.settleReminderHowOften, style: label),
            const SizedBox(height: 4),
            SegmentedButton<RecurrenceFrequency>(
              segments: [
                ButtonSegment(value: RecurrenceFrequency.monthly, label: Text(l10n.settleReminderMonthly)),
                ButtonSegment(value: RecurrenceFrequency.weekly, label: Text(l10n.settleReminderWeekly)),
              ],
              selected: {_frequency},
              onSelectionChanged: (selection) => setState(() => _frequency = selection.single),
            ),
            const SizedBox(height: 12),
            if (_frequency == RecurrenceFrequency.monthly)
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                decoration: InputDecoration(labelText: l10n.settleReminderOnDay),
                items: [
                  for (final day in kSettleReminderDays)
                    DropdownMenuItem(value: day, child: Text(day == kLastDayOfMonth ? l10n.settleReminderLastDay : '$day')),
                ],
                onChanged: (day) => setState(() => _dayOfMonth = day ?? 1),
              )
            else
              _chips([
                for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
                  ChoiceChip(
                    label: Text(DateFormat.E(locale).format(DateTime(2024, 1, weekday))),
                    tooltip: weekdayName(weekday, locale),
                    selected: _weekday == weekday,
                    onSelected: (_) => setState(() => _weekday = weekday),
                  ),
              ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.notifications_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(l10n.settleReminderNextAt(DateFormat('EEE, d MMM', locale).format(next)), style: theme.textTheme.bodyMedium)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.existing != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop<SettleReminderChoice>((schedule: null)),
                      child: Text(l10n.settleReminderTurnOff),
                    ),
                  ),
                if (widget.existing != null) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop<SettleReminderChoice>((schedule: _schedule)),
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
