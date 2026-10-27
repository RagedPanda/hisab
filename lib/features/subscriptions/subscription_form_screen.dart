import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/subscriptions/subscription_schedule.dart';
import '../../domain/subscriptions/subscription_templates.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../categories/category_picker.dart';
import '../shell/widgets/common.dart';
import 'subscription_labels.dart';
import 'subscription_rules.dart';

/// Hour every renewal is recorded at when a new subscription is created.
const int kSubscriptionRenewalHour = 9;

/// Add a subscription (blank or from a quick-add template) or edit one. It is
/// stored as a recurring expense rule flagged `isSubscription`; the next
/// renewal date becomes the rule's start, so nothing before it is back-posted.
class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({super.key, this.ruleId, this.templateKey});

  /// Null to add a new subscription.
  final String? ruleId;
  final String? templateKey;

  @override
  ConsumerState<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends ConsumerState<SubscriptionFormScreen> {
  /// Number format the amount fields read and write (the app's own).
  MoneyFormat get _moneyFormat => ref.read(homeMoneyFormatProvider);

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  SubscriptionCycle _cycle = subscriptionCycles.first;
  DateTime _nextRenewal = startOfDay(DateTime.now());

  /// Whether the user picked the renewal date; only a picked past date is
  /// rolled forward, so editing an overdue subscription keeps it overdue.
  bool _dateEdited = false;
  Category? _category;
  String? _accountId;
  bool _autoPost = true;
  RecurringRule? _existing;
  bool _loaded = false;
  bool _submitted = false;

  bool get _isEditing => widget.ruleId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final id = widget.ruleId;
    final categories = ref.read(categoriesRepositoryProvider);
    if (id != null) {
      final rule = await ref.read(recurringRepositoryProvider).getRule(id);
      if (rule != null) {
        _existing = rule;
        _nameController.text = rule.name;
        _priceController.text = amountInputText(rule.amountMinor, format: _moneyFormat);
        _cycle = SubscriptionCycle(RecurrenceFrequency.parse(rule.frequency), rule.interval);
        _nextRenewal = startOfDay(rule.nextDue ?? DateTime.now());
        _category = rule.categoryId == null ? null : await categories.byId(rule.categoryId!);
        _accountId = rule.accountId;
        _autoPost = rule.autoPost;
      }
    } else {
      _accountId = (await ref.read(accountsRepositoryProvider).getAll()).firstOrNull?.id;
      final template = subscriptionTemplateByKey(widget.templateKey ?? '');
      if (template != null) {
        _cycle = SubscriptionCycle(template.frequency, template.interval);
        if (mounted) _nameController.text = subscriptionTemplateName(context.l10n, template);
      }
      _category = await categories.findBySeedKey(subscriptionCategoryKeyFor(template));
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final priceMinor = parseAmountToMinor(_priceController.text, format: _moneyFormat);
    final nameError = _submitted && _nameController.text.trim().isEmpty ? l10n.subscriptionNameRequired : null;
    final priceError = amountErrorText(context, _priceController.text, format: _moneyFormat) ??
        (_submitted && (priceMinor == null || priceMinor <= 0) ? l10n.subscriptionPriceRequired : null);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.subscriptionEdit : l10n.subscriptionAdd)),
      bottomNavigationBar: BottomActionBar(child: FilledButton(onPressed: _loaded ? _save : null, child: Text(l10n.save))),
      body: !_loaded
          ? const SizedBox.shrink()
          : DismissKeyboardOnTap(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  TextField(
                    key: const Key('subscriptionName'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.name, errorText: nameError),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('subscriptionPrice'),
                    controller: _priceController,
                    autofocus: !_isEditing,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: amountInputFormatters,
                    decoration: InputDecoration(labelText: l10n.subscriptionPrice, prefixText: amountPrefixText(moneyFormat), suffixText: amountSuffixText(moneyFormat), errorText: priceError),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SubscriptionCycle>(
                    initialValue: _cycle,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.subscriptionCycle),
                    items: [
                      for (final cycle in cycleOptionsFor(_cycle))
                        DropdownMenuItem(value: cycle, child: Text(subscriptionCycleLabel(l10n, cycle.frequency, cycle.interval))),
                    ],
                    onChanged: (cycle) => setState(() => _cycle = cycle ?? _cycle),
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(l10n.subscriptionNextRenewal),
                    subtitle: _startedInPast ? Text(l10n.subscriptionStartedOn(formatShortDate(_nextRenewal, locale: locale.toString()))) : null,
                    trailing: SettingValue(formatShortDate(_schedule().start, locale: locale.toString())),
                    onTap: _pickDate,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.category_outlined),
                    title: Text(l10n.category),
                    trailing: SettingValue(_category == null ? l10n.notSet : categoryDisplayName(_category!, locale)),
                    onTap: () async {
                      final picked = await showCategoryPicker(context, kind: 'expense', selectedId: _category?.id);
                      if (picked != null) setState(() => _category = picked);
                    },
                  ),
                  if (accounts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(l10n.account, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    ChipRow(padding: EdgeInsets.zero, children: [
                      for (final account in accounts)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(label: Text(account.name), selected: _accountId == account.id, onSelected: (_) => setState(() => _accountId = account.id)),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.subscriptionAutoPost),
                    subtitle: Text(l10n.subscriptionAutoPostHelp),
                    value: _autoPost,
                    onChanged: (value) => setState(() => _autoPost = value),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate() async {
    final today = startOfDay(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextRenewal,
      firstDate: earliestSubscriptionRenewal(today),
      lastDate: DateTime(today.year + kSubscriptionMaxYearsBack),
    );
    if (picked != null && mounted) {
      setState(() {
        _nextRenewal = picked;
        _dateEdited = true;
      });
    }
  }

  bool get _startedInPast => _dateEdited && _nextRenewal.isBefore(startOfDay(DateTime.now()));

  /// Rule start and anchors for the form as filled in now.
  ({DateTime start, int? dayOfMonth, int? weekday}) _schedule() {
    final existing = _existing;
    return subscriptionScheduleFrom(
      renewalDate: _nextRenewal,
      cycle: _cycle,
      today: _dateEdited ? DateTime.now() : _nextRenewal,
      hour: existing?.startDate.hour ?? kSubscriptionRenewalHour,
      minute: existing?.startDate.minute ?? 0,
      monthStartDay: ref.read(settingsProvider).monthStartDay,
    );
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final name = _nameController.text.trim();
    final priceMinor = parseAmountToMinor(_priceController.text, format: _moneyFormat);
    if (name.isEmpty || priceMinor == null || priceMinor <= 0) return;
    final existing = _existing;
    final schedule = _schedule();
    final start = schedule.start;
    final dateChanged = existing == null || existing.nextDue == null || !isSameDay(existing.nextDue!, start);
    final draft = SubscriptionDraft(
      name: name,
      amountMinor: priceMinor,
      cycle: _cycle,
      startDate: start,
      categoryId: _category?.id,
      accountId: _accountId,
      autoPost: _autoPost,
      dayOfMonth: schedule.dayOfMonth,
      weekday: schedule.weekday,
    );
    final rule = existing == null ? newSubscriptionRule(draft) : editedSubscriptionRule(existing, draft, renewalDayChanged: dateChanged);
    await ref.read(recurringRepositoryProvider).saveRule(rule, monthStartDay: ref.read(settingsProvider).monthStartDay);
    if (mounted) context.pop();
  }
}
