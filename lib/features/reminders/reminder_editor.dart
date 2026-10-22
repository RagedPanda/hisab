import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../domain/reminders/reminder_draft.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../domain/reminders/reminder_schedule.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../categories/category_picker.dart';
import '../shell/widgets/common.dart';
import 'reminder_actions.dart';
import 'reminder_labels.dart';

/// Repeats offered in the editor; weekly suits few bills, so it stays out.
const kEditorRepeats = [ReminderRepeat.once, ReminderRepeat.monthly, ReminderRepeat.quarterly, ReminderRepeat.yearly];

/// Opens the create / edit sheet on the root navigator. Returns the saved id.
Future<String?> showReminderEditor(BuildContext context, {Reminder? existing, ReminderDraft? initial}) {
  final now = DateTime.now();
  final draft = existing != null
      ? reminderDraftFrom(existing)
      : initial ?? ReminderDraft(kind: ReminderKind.bill, title: '', dueAt: DateTime(now.year, now.month, now.day + 1));
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    builder: (_) => ReminderEditor(initial: draft),
  );
}

class ReminderEditor extends ConsumerStatefulWidget {
  const ReminderEditor({super.key, required this.initial});
  final ReminderDraft initial;

  @override
  ConsumerState<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends ConsumerState<ReminderEditor> {
  late final _titleController = TextEditingController(text: widget.initial.title);
  late final _amountController = TextEditingController(text: widget.initial.amountMinor == null ? '' : amountInputText(widget.initial.amountMinor!));
  late final _notesController = TextEditingController(text: widget.initial.notes);
  late ReminderKind _kind = widget.initial.kind;
  late DateTime _dueAt = widget.initial.dueAt;
  late ReminderRepeat _repeat = widget.initial.repeat;
  late Set<int> _daysBefore = widget.initial.remindDaysBefore.toSet();
  late bool _notify = widget.initial.notifyAtMinute != null;
  late int _notifyMinute = widget.initial.notifyAtMinute ?? kDefaultNotifyMinute;
  late String? _categoryId = widget.initial.categoryId;
  late String? _accountId = widget.initial.accountId;
  var _submitted = false;
  var _saving = false;

  bool get _isEditing => widget.initial.id != null;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ReminderDraft get _draft => ReminderDraft(
        id: widget.initial.id,
        kind: _kind,
        title: _titleController.text,
        dueAt: DateTime(_dueAt.year, _dueAt.month, _dueAt.day),
        notes: _notesController.text.trim(),
        amountMinor: _kind.isMoney ? parseAmountToMinor(_amountController.text) : null,
        categoryId: _kind.isMoney ? _categoryId : null,
        accountId: _kind.isMoney ? _accountId : null,
        recurringId: widget.initial.recurringId,
        assetId: widget.initial.assetId,
        repeat: _repeat,
        remindDaysBefore: _daysBefore.toList(),
        notifyAtMinute: _notify ? _notifyMinute : null,
        matchKeywords: widget.initial.matchKeywords,
        toleranceMinor: widget.initial.toleranceMinor,
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => _dueAt = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _notifyMinute ~/ 60, minute: _notifyMinute % 60));
    if (picked != null) setState(() => _notifyMinute = picked.hour * 60 + picked.minute);
  }

  Future<void> _pickCategory() async {
    final category = await showCategoryPicker(context, kind: 'expense', selectedId: _categoryId);
    if (category != null) setState(() => _categoryId = category.id);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final draft = _draft;
    if (draft.error != null || (_notify && _daysBefore.isEmpty) || _saving) return;
    setState(() => _saving = true);
    if (_notify) await askNotificationPermissionIfNeeded(context, ref);
    final id = await ref.read(reminderSchedulerProvider).save(draft);
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final category = categories.where((c) => c.id == _categoryId).firstOrNull;
    final permission = ref.watch(notificationPermissionProvider).value;
    final draft = _draft;
    final titleError = _submitted && draft.error == ReminderDraftError.missingTitle ? l10n.reminderTitleRequired : null;
    final firstAlert = planAlerts(
      reminderId: 'preview',
      dueAt: draft.dueAt,
      daysBefore: draft.remindDaysBefore,
      notifyAtMinute: draft.notifyAtMinute,
      now: DateTime.now(),
    ).firstOrNull;
    final dayChoices = {...(_kind == ReminderKind.document ? kDocumentRemindDaysBefore : kRemindDaysBeforeChoices), ..._daysBefore}.toList()..sort();
    const gap = SizedBox(height: 12);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(_isEditing ? l10n.reminderEditTitle : l10n.reminderNew, style: theme.textTheme.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                ChipRow(children: [
                  for (final kind in ReminderKind.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(reminderKindIcon(kind), size: 18),
                        label: Text(reminderKindLabel(l10n, kind)),
                        selected: _kind == kind,
                        onSelected: (_) => setState(() => _kind = kind),
                      ),
                    ),
                ]),
                gap,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextField(
                      key: const ValueKey('reminder-title'),
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: l10n.reminderTitleLabel, hintText: l10n.reminderTitleHint, errorText: titleError),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_kind.isMoney) ...[
                      gap,
                      TextField(
                        key: const ValueKey('reminder-amount'),
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l10n.reminderAmountOptional, prefixText: '$symbol '),
                      ),
                    ],
                    gap,
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('reminder-due'),
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined, size: 18),
                          label: Text(formatShortDate(_dueAt, locale: locale), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ReminderRepeat>(
                          initialValue: kEditorRepeats.contains(_repeat) ? _repeat : ReminderRepeat.monthly,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l10n.reminderRepeatLabel, isDense: true),
                          items: [
                            for (final repeat in {...kEditorRepeats, _repeat})
                              DropdownMenuItem(value: repeat, child: Text(reminderRepeatLabel(l10n, repeat), overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (repeat) => setState(() => _repeat = repeat ?? _repeat),
                        ),
                      ),
                    ]),
                  ]),
                ),
                SwitchListTile(
                  title: Text(l10n.reminderNotifyEnabled),
                  value: _notify,
                  onChanged: (value) => setState(() => _notify = value),
                ),
                if (_notify) ...[
                  ChipRow(children: [
                    for (final days in dayChoices)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(reminderDaysBeforeLabel(l10n, days)),
                          selected: _daysBefore.contains(days),
                          onSelected: (on) => setState(() => _daysBefore = on ? {..._daysBefore, days} : ({..._daysBefore}..remove(days))),
                        ),
                      ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(children: [
                      OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(l10n.reminderNotifyAt(formatTime(DateTime(2000, 1, 1, _notifyMinute ~/ 60, _notifyMinute % 60), locale: locale))),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      _submitted && _daysBefore.isEmpty
                          ? l10n.reminderPickDaysError
                          : firstAlert == null
                              ? l10n.reminderNoAlertsLeft
                              : l10n.reminderNotifyPreview(DateFormat('EEE d MMM, h:mm a', locale).format(firstAlert.fireAt)),
                      style: theme.textTheme.bodySmall?.copyWith(color: _submitted && _daysBefore.isEmpty ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  if (permission != null && permission.notificationsAllowed && !permission.exactAlarmsAllowed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                      child: Row(children: [
                        Expanded(child: Text(l10n.reminderExactAlarmNote, style: theme.textTheme.bodySmall)),
                        TextButton(
                          onPressed: () async {
                            await ref.read(notificationServiceProvider).requestExactAlarms();
                            ref.invalidate(notificationPermissionProvider);
                          },
                          child: Text(l10n.notifTurnOn),
                        ),
                      ]),
                    ),
                ],
                if (_kind.isMoney) ...[
                  gap,
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(category?.displayName(context) ?? l10n.chooseCategory),
                    subtitle: Text(l10n.category),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickCategory,
                  ),
                  if (accounts.isNotEmpty)
                    ChipRow(children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(label: Text(l10n.reminderNoAccount), selected: _accountId == null, onSelected: (_) => setState(() => _accountId = null)),
                      ),
                      for (final account in accounts)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(label: Text(account.name), selected: _accountId == account.id, onSelected: (_) => setState(() => _accountId = account.id)),
                        ),
                    ]),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: l10n.note),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: FilledButton(
              key: const ValueKey('reminder-save'),
              onPressed: _saving ? null : _save,
              child: Text(l10n.reminderSave),
            ),
          ),
        ]),
      ),
    );
  }
}
