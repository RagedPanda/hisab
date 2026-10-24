import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/recurring/repeat_draft.dart';
import '../../l10n/l10n.dart';

/// "Every month on day 5, 12 times" for [draft] starting on [start].
String repeatSummary(AppLocalizations l10n, RepeatDraft draft, DateTime start, {String? locale}) {
  final interval = draft.interval < 1 ? 1 : draft.interval;
  final every = switch (draft.frequency) {
    RecurrenceFrequency.daily => l10n.recurringEveryDays(interval),
    RecurrenceFrequency.weekly => l10n.recurringEveryWeeks(interval),
    RecurrenceFrequency.monthly => l10n.recurringEveryMonths(interval),
    RecurrenceFrequency.yearly => l10n.recurringEveryYears(interval),
  };
  final anchor = switch (draft.frequency) {
    RecurrenceFrequency.daily => null,
    RecurrenceFrequency.weekly => l10n.recurringOnWeekday(formatWeekday(start, locale: locale)),
    RecurrenceFrequency.monthly => draft.lastDayOfMonth ? l10n.recurringOnLastDay : l10n.recurringOnDay(start.day),
    RecurrenceFrequency.yearly => l10n.recurringOnDate(formatDayMonth(start, locale: locale)),
  };
  final ending = switch (draft.end) {
    RepeatEnd.never => null,
    RepeatEnd.onDate => draft.endDate == null ? null : l10n.recurringUntil(formatShortDate(draft.endDate!, locale: locale)),
    RepeatEnd.afterCount => draft.maxCount == null ? null : l10n.recurringTimes(draft.maxCount!),
  };
  final schedule = anchor == null ? every : '$every $anchor';
  return ending == null ? schedule : '$schedule, $ending';
}

String frequencyLabel(AppLocalizations l10n, RecurrenceFrequency frequency) => switch (frequency) {
      RecurrenceFrequency.daily => l10n.recurringDaily,
      RecurrenceFrequency.weekly => l10n.recurringWeekly,
      RecurrenceFrequency.monthly => l10n.recurringMonthly,
      RecurrenceFrequency.yearly => l10n.recurringYearly,
    };

/// What the Repeat sheet returned: a schedule, or null for "don't repeat".
typedef RepeatChoice = ({RepeatDraft? draft});

/// Opens the Repeat sheet. Returns null when dismissed. [allowNone] offers
/// "Don't repeat" (the entry editor); a rule's own form leaves it out.
///
/// The keyboard is closed first: the sheet has no text fields, and a keyboard
/// left open from the amount field would cover its Done button.
Future<RepeatChoice?> showRepeatSheet(BuildContext context, {required RepeatDraft? initial, required DateTime start, bool allowNone = true}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<RepeatChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _RepeatSheet(initial: initial ?? const RepeatDraft(), start: start, allowNone: allowNone),
  );
}

class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({required this.initial, required this.start, required this.allowNone});
  final RepeatDraft initial;
  final DateTime start;
  final bool allowNone;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  late RepeatDraft _draft = widget.initial;

  void _update(RepeatDraft draft) => setState(() => _draft = draft);

  Future<void> _pickEndDate() async {
    final start = widget.start;
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.endDate ?? DateTime(start.year + 1, start.month, start.day),
      firstDate: DateTime(start.year, start.month, start.day),
      lastDate: DateTime(start.year + 50),
    );
    if (picked != null) _update(_draft.copyWith(endDate: picked, end: RepeatEnd.onDate));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final valid = _draft.isValidFrom(widget.start);
    // The options scroll; the buttons sit in a footer outside the scroll view
    // so they always stay above the keyboard and on screen.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.recurringRepeat, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(repeatSummary(l10n, _draft, widget.start, locale: locale), key: const ValueKey('repeat.summary'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final frequency in RecurrenceFrequency.values)
                        ChoiceChip(
                          label: Text(frequencyLabel(l10n, frequency)),
                          selected: _draft.frequency == frequency,
                          onSelected: (_) => _update(_draft.copyWith(frequency: frequency)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Stepper(
                    label: l10n.recurringInterval,
                    value: _draft.interval,
                    keyPrefix: 'repeat.interval',
                    onChanged: (value) => _update(_draft.copyWith(interval: value)),
                  ),
                  if (_draft.frequency == RecurrenceFrequency.monthly)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.recurringLastDayOfMonth),
                      value: _draft.lastDayOfMonth,
                      onChanged: (value) => _update(_draft.copyWith(lastDayOfMonth: value)),
                    ),
                  const SizedBox(height: 8),
                  Text(l10n.recurringEnds, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(label: Text(l10n.recurringEndNever), selected: _draft.end == RepeatEnd.never, onSelected: (_) => _update(_draft.copyWith(end: RepeatEnd.never))),
                      ChoiceChip(
                        label: Text(_draft.end == RepeatEnd.onDate && _draft.endDate != null ? formatShortDate(_draft.endDate!, locale: locale) : l10n.recurringEndOnDate),
                        selected: _draft.end == RepeatEnd.onDate,
                        onSelected: (_) => _pickEndDate(),
                      ),
                      ChoiceChip(
                        label: Text(l10n.recurringEndAfter),
                        selected: _draft.end == RepeatEnd.afterCount,
                        onSelected: (_) => _update(_draft.copyWith(end: RepeatEnd.afterCount, maxCount: _draft.maxCount ?? 12)),
                      ),
                    ],
                  ),
                  if (_draft.end == RepeatEnd.afterCount)
                    _Stepper(
                      label: l10n.recurringOccurrences,
                      value: _draft.maxCount ?? 12,
                      keyPrefix: 'repeat.count',
                      onChanged: (value) => _update(_draft.copyWith(maxCount: value)),
                    ),
                  if (!valid && _draft.end == RepeatEnd.onDate)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l10n.recurringEndBeforeStart, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const ValueKey('repeat.autoPost'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.recurringAutoPost),
                    subtitle: Text(l10n.recurringAutoPostHint),
                    value: _draft.autoPost,
                    onChanged: (value) => _update(_draft.copyWith(autoPost: value)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (widget.allowNone) ...[
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('repeat.none'),
                      onPressed: () => Navigator.of(context).pop<RepeatChoice>((draft: null)),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.recurringStopRepeating)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('repeat.done'),
                    onPressed: valid ? () => Navigator.of(context).pop<RepeatChoice>((draft: _draft)) : null,
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.recurringDone)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A label with minus and plus buttons around a whole number of at least 1.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.keyPrefix, required this.onChanged});
  final String label;
  final int value;
  final String keyPrefix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        IconButton(key: ValueKey('$keyPrefix.minus'), tooltip: l10n.recurringDecrease(label), icon: const Icon(Icons.remove_circle_outline), onPressed: value > 1 ? () => onChanged(value - 1) : null),
        SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.center, style: theme.textTheme.titleMedium)),
        IconButton(key: ValueKey('$keyPrefix.plus'), tooltip: l10n.recurringIncrease(label), icon: const Icon(Icons.add_circle_outline), onPressed: value < 999 ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

/// The Repeat row: shows the schedule and opens [showRepeatSheet].
class RepeatTile extends StatelessWidget {
  const RepeatTile({super.key, required this.draft, required this.start, required this.onChanged, this.allowNone = true});
  final RepeatDraft? draft;
  final DateTime start;
  final ValueChanged<RepeatDraft?> onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final current = draft;
    return ListTile(
      key: const ValueKey('editor.repeat'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.repeat),
      title: Text(l10n.recurringRepeat),
      subtitle: Text(current == null ? l10n.recurringDoesNotRepeat : repeatSummary(l10n, current, start, locale: locale)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final choice = await showRepeatSheet(context, initial: current, start: start, allowNone: allowNone);
        if (choice != null) onChanged(choice.draft);
      },
    );
  }
}
