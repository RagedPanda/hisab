import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/salary_settings.dart';
import '../../data/db/database.dart';
import '../../domain/salary/salary_schedule.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'salary_providers.dart';
import 'salary_reminder.dart';

/// Highest "remind after" choice, in days after the expected date.
const int kMaxSalaryReminderDelayDays = 10;

String salaryShiftLabel(BuildContext context, SalaryShift shift) => switch (shift) {
      SalaryShift.sameDay => context.l10n.salaryShiftSameDay,
      SalaryShift.previousWorkingDay => context.l10n.salaryShiftPrevious,
      SalaryShift.nextWorkingDay => context.l10n.salaryShiftNext,
    };

/// The status card's two lines: what happened to the tracked cycle (received
/// with its amount, late, or expected) and what comes next, with the last
/// salary received when the tracked one has not arrived yet.
({String title, String subtitle}) salaryStatusLines(SalaryStatus status, AppLocalizations l10n, {required String locale, required String symbol}) {
  String date(DateTime value) => formatShortDate(value, locale: locale);
  String money(int minor) => formatMinor(minor, symbol: symbol);
  final received = status.received;
  final title = received != null
      ? l10n.salaryReceivedAmount(date(received.occurredAt), money(received.amountMinor))
      : status.isLate
          ? l10n.salaryLateSince(date(status.expected))
          : l10n.salaryExpectedOn(date(status.expected));
  final last = status.lastReceived;
  final subtitle = [
    if (received == null && last != null) l10n.salaryLastReceived(date(last.occurredAt), money(last.amountMinor)),
    l10n.salaryNextExpected(date(status.next)),
  ].join('\n');
  return (title: title, subtitle: subtitle);
}

/// Asks for the notification permission (the Android 13+ prompt) unless it
/// is already granted, so the salary reminder can actually be shown. Never
/// throws: saving the salary must not depend on the prompt.
Future<void> ensureSalaryNotificationPermission(WidgetRef ref) async {
  try {
    final notifications = ref.read(notificationServiceProvider);
    if (!(await notifications.checkPermission()).notificationsAllowed) await notifications.requestPermission();
  } catch (error) {
    debugPrint('Hisab: notification permission not requested: $error');
  }
  ref.invalidate(notificationPermissionProvider);
}

/// Settings > Money > Salary: amount, account, day, weekend shift and the
/// "Salary not seen yet" reminder. Saving creates the recurring income rule.
class SalarySetupScreen extends ConsumerStatefulWidget {
  const SalarySetupScreen({super.key});

  @override
  ConsumerState<SalarySetupScreen> createState() => _SalarySetupScreenState();
}

class _SalarySetupScreenState extends ConsumerState<SalarySetupScreen> {
  late SalarySettings draft = ref.read(salarySettingsProvider);
  late final TextEditingController amountController =
      TextEditingController(text: draft.amountMinor > 0 ? amountInputText(draft.amountMinor) : '');
  bool saving = false;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  int? get parsedAmount => parseAmountToMinor(amountController.text);
  bool get canSave => !saving && (parsedAmount ?? 0) > 0;

  Future<void> addHoliday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 2), initialDate: now);
    if (picked == null || draft.holidays.any((day) => day == picked)) return;
    setState(() => draft = draft.copyWith(holidays: [...draft.holidays, picked]..sort()));
  }

  Future<void> save() async {
    setState(() => saving = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(salarySettingsProvider.notifier);
    final now = DateTime.now();
    if (draft.reminderEnabled) await ensureSalaryNotificationPermission(ref);
    final saved = await ref.read(salaryServiceProvider).saveSalaryRule(settings: draft.copyWith(amountMinor: parsedAmount), today: now, monthStartDay: settings.monthStartDay);
    await notifier.save(saved);
    if (!mounted) return;
    if (saved.shouldOfferMonthStartAlign(monthStartDay: settings.monthStartDay)) {
      final suggested = suggestedMonthStartDay(saved.salaryDay);
      final align = await confirmDialog(context, title: l10n.salaryAlignTitle(suggested), message: l10n.salaryAlignMessage, confirmLabel: l10n.salaryAlignAction);
      if (align) {
        await ref.read(settingsProvider.notifier).update((current) => current.copyWith(monthStartDay: suggested));
      } else {
        await notifier.save(saved.copyWith(alignDeclinedRuleId: saved.ruleId));
      }
    }
    await syncSalaryReminder(ref.read, now: now);
    messenger.showSnackBar(SnackBar(content: Text(l10n.salarySaved)));
    if (mounted) popOrGoHome(context);
  }

  /// Turning the reminder on asks for the permission it needs right away.
  Future<void> setReminderEnabled(bool enabled) async {
    setState(() => draft = draft.copyWith(reminderEnabled: enabled));
    if (enabled) await ensureSalaryNotificationPermission(ref);
  }

  Future<void> remove() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await confirmDialog(context, title: l10n.salaryRemove, confirmLabel: l10n.salaryRemove);
    if (!confirmed) return;
    await ref.read(salaryServiceProvider).removeSalaryRule(draft.ruleId);
    // Back to a blank setup, so setting it up again starts from the defaults.
    await ref.read(salarySettingsProvider.notifier).save(const SalarySettings());
    if (mounted) {
      setState(() => draft = const SalarySettings());
      amountController.clear();
    }
    await syncSalaryReminder(ref.read, now: DateTime.now());
    messenger.showSnackBar(SnackBar(content: Text(l10n.salaryRemoved)));
    if (mounted) popOrGoHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final monthStartDay = ref.watch(settingsProvider).monthStartDay;
    final status = ref.watch(salaryStatusProvider);
    final statusLines = status == null ? null : salaryStatusLines(status, l10n, locale: locale, symbol: ref.watch(settingsProvider).currencySymbol);
    final aligned = isMonthStartAligned(monthStartDay: monthStartDay, salaryDay: draft.salaryDay);
    final accountIds = {for (final account in accounts) account.id};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salaryTitle),
        actions: [
          if (draft.isSetUp) IconButton(key: const Key('salaryRemove'), tooltip: l10n.salaryRemove, icon: const Icon(Icons.delete_outline), onPressed: remove),
        ],
      ),
      body: DismissKeyboardOnTap(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(l10n.salaryIntro, style: Theme.of(context).textTheme.bodyMedium),
            if (status != null && statusLines != null) ...[
              const SizedBox(height: 12),
              Card(
                key: const Key('salaryStatus'),
                child: ListTile(
                  leading: Icon(status.isSeen ? Icons.check_circle_outline : (status.isLate ? Icons.warning_amber_outlined : Icons.schedule)),
                  title: Text(statusLines.title),
                  subtitle: Text(statusLines.subtitle),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const Key('salaryAmount'),
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: amountInputFormatters,
              decoration: InputDecoration(
                labelText: l10n.salaryAmount,
                prefixText: '${ref.watch(settingsProvider).currencySymbol} ',
                errorText: amountErrorText(context, amountController.text),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              key: const Key('salaryAccount'),
              initialValue: accountIds.contains(draft.accountId) ? draft.accountId : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.salaryAccount, border: const OutlineInputBorder()),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.salaryAnyAccount)),
                for (final account in accounts) DropdownMenuItem(value: account.id, child: Text(account.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (value) => setState(() => draft = value == null ? draft.copyWith(clearAccount: true) : draft.copyWith(accountId: value)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const Key('salaryDay'),
              initialValue: draft.salaryDay,
              decoration: InputDecoration(labelText: l10n.salaryDay, border: const OutlineInputBorder()),
              items: [for (var day = 1; day <= 31; day++) DropdownMenuItem(value: day, child: Text(l10n.dayNumber(day)))],
              onChanged: (value) => setState(() => draft = draft.copyWith(salaryDay: value)),
            ),
            const SizedBox(height: 8),
            ListTile(
              key: const Key('salaryAlignment'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(aligned ? Icons.event_available_outlined : Icons.info_outline),
              title: Text(aligned ? l10n.salaryAligned : l10n.salaryNotAligned(monthStartDay, draft.salaryDay)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SalaryShift>(
              key: const Key('salaryShift'),
              initialValue: draft.shift,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.salaryShiftLabel, border: const OutlineInputBorder()),
              items: [for (final shift in SalaryShift.values) DropdownMenuItem(value: shift, child: Text(salaryShiftLabel(context, shift)))],
              onChanged: (value) => setState(() => draft = draft.copyWith(shift: value)),
            ),
            if (draft.shift != SalaryShift.sameDay) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.salaryHolidays),
                subtitle: Text(l10n.salaryHolidaysHelp),
                trailing: TextButton.icon(key: const Key('salaryAddHoliday'), onPressed: addHoliday, icon: const Icon(Icons.add), label: Text(l10n.salaryAddHoliday)),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final holiday in draft.holidays)
                    InputChip(
                      label: Text(formatShortDate(holiday, locale: locale)),
                      onDeleted: () => setState(() => draft = draft.copyWith(holidays: [...draft.holidays]..remove(holiday))),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const Key('salaryMatchWindow'),
              initialValue: clampSalaryMatchWindowDays(draft.matchWindowDays),
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.salaryMatchWindow, border: const OutlineInputBorder()),
              items: [
                for (var days = kMinSalaryMatchWindowDays; days <= kMaxSalaryMatchWindowDays; days++)
                  DropdownMenuItem(value: days, child: Text(l10n.salaryMatchWindowDays(days))),
              ],
              onChanged: (value) => setState(() => draft = draft.copyWith(matchWindowDays: value)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: const Key('salaryTolerance'),
              initialValue: nearestSalaryToleranceChoice(draft.tolerancePercent),
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.salaryTolerance, border: const OutlineInputBorder(), helperText: l10n.salaryDetectionHelp, helperMaxLines: 3),
              items: [
                for (final percent in kSalaryTolerancePercentChoices)
                  DropdownMenuItem(value: percent, child: Text(percent == 0 ? l10n.salaryToleranceExact : l10n.salaryTolerancePercent(percent))),
              ],
              onChanged: (value) => setState(() => draft = draft.copyWith(tolerancePercent: value)),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('salaryReminderSwitch'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.salaryReminder),
              value: draft.reminderEnabled,
              onChanged: setReminderEnabled,
            ),
            if (draft.reminderEnabled)
              DropdownButtonFormField<int>(
                key: const Key('salaryReminderDelay'),
                initialValue: draft.reminderDelayDays.clamp(1, kMaxSalaryReminderDelayDays),
                decoration: InputDecoration(labelText: l10n.salaryReminderDelay, border: const OutlineInputBorder()),
                items: [for (var days = 1; days <= kMaxSalaryReminderDelayDays; days++) DropdownMenuItem(value: days, child: Text(l10n.salaryDaysAfter(days)))],
                onChanged: (value) => setState(() => draft = draft.copyWith(reminderDelayDays: value)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(key: const Key('salarySave'), onPressed: canSave ? save : null, child: Text(l10n.save)),
      ),
    );
  }
}
