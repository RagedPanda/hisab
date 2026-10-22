import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/subscriptions/subscription_templates.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../categories/category_picker.dart';
import '../shell/widgets/common.dart';
import 'subscription_labels.dart';

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
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  SubscriptionCycle _cycle = subscriptionCycles.first;
  DateTime _nextRenewal = startOfDay(DateTime.now());
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
        _priceController.text = amountInputText(rule.amountMinor);
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
        _category = await categories.findBySeedKey(template.categoryKey);
        if (mounted) _nameController.text = subscriptionTemplateName(context.l10n, template);
      }
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
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final priceMinor = parseAmountToMinor(_priceController.text);
    final nameError = _submitted && _nameController.text.trim().isEmpty ? l10n.subscriptionNameRequired : null;
    final priceError = amountErrorText(context, _priceController.text) ??
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
                    decoration: InputDecoration(labelText: l10n.subscriptionPrice, prefixText: '$symbol ', errorText: priceError),
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
                    trailing: SettingValue(formatShortDate(_nextRenewal, locale: locale.toString())),
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
      initialDate: _nextRenewal.isBefore(today) ? today : _nextRenewal,
      firstDate: today,
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null && mounted) setState(() => _nextRenewal = picked);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final name = _nameController.text.trim();
    final priceMinor = parseAmountToMinor(_priceController.text);
    if (name.isEmpty || priceMinor == null || priceMinor <= 0) return;
    final existing = _existing;
    final hour = existing?.startDate.hour ?? kSubscriptionRenewalHour;
    final minute = existing?.startDate.minute ?? 0;
    final start = DateTime(_nextRenewal.year, _nextRenewal.month, _nextRenewal.day, hour, minute);
    final dateChanged = existing == null || existing.nextDue == null || !isSameDay(existing.nextDue!, start);
    final RecurringRulesCompanion rule;
    if (existing == null) {
      rule = RecurringRepository.newRule(
        name: name,
        kind: 'expense',
        amountMinor: priceMinor,
        categoryId: _category?.id,
        accountId: _accountId,
        frequency: _cycle.frequency,
        interval: _cycle.interval,
        startDate: start,
        autoPost: _autoPost,
        isSubscription: true,
      );
    } else {
      // The next renewal becomes the new start, so an edit never back-posts.
      // A changed date re-anchors the day of month and weekday on it.
      rule = existing.toCompanion(true).copyWith(
            name: Value(name),
            amountMinor: Value(priceMinor),
            categoryId: Value(_category?.id),
            accountId: Value(_accountId),
            frequency: Value(_cycle.frequency.name),
            interval: Value(_cycle.interval),
            startDate: Value(start),
            dayOfMonth: dateChanged ? const Value(null) : Value(existing.dayOfMonth),
            weekday: dateChanged ? const Value(null) : Value(existing.weekday),
            autoPost: Value(_autoPost),
            isSubscription: const Value(true),
          );
    }
    await ref.read(recurringRepositoryProvider).saveRule(rule, monthStartDay: ref.read(settingsProvider).monthStartDay);
    if (mounted) context.pop();
  }
}
