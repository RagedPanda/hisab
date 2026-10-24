import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/split/group_recurring.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/recurring/repeat_draft.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../accounts/account_choice_chips.dart';
import '../categories/category_picker.dart';
import '../shell/widgets/common.dart';
import 'repeat_sheet.dart';

/// Create or edit a recurring rule: what it posts (kind, amount, category,
/// account, payee, note) and when (next date and the Repeat schedule).
class RecurringRuleFormScreen extends ConsumerStatefulWidget {
  const RecurringRuleFormScreen({super.key, this.ruleId});

  /// Null to create a new rule.
  final String? ruleId;

  @override
  ConsumerState<RecurringRuleFormScreen> createState() => _RecurringRuleFormScreenState();
}

class _RecurringRuleFormScreenState extends ConsumerState<RecurringRuleFormScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _noteController = TextEditingController();
  String _kind = 'expense';
  Category? _category;
  String? _accountId;
  String? _toAccountId;
  DateTime _nextOn = DateTime.now();
  RepeatDraft _repeat = const RepeatDraft();
  RecurringRule? _existing;
  bool _loaded = false;
  bool _missing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final id = widget.ruleId;
    if (id != null) {
      final rule = await ref.read(recurringRepositoryProvider).getRule(id);
      if (rule == null || rule.deletedAt != null) {
        _missing = true;
      } else {
        _existing = rule;
        _kind = rule.kind;
        _nameController.text = rule.name;
        _amountController.text = amountInputText(rule.amountMinor);
        _payeeController.text = rule.payee ?? '';
        _noteController.text = rule.note;
        _accountId = rule.accountId;
        _toAccountId = rule.toAccountId;
        _nextOn = rule.nextDue ?? rule.startDate;
        _repeat = RepeatDraft.fromSpec(specOf(rule), autoPost: rule.autoPost);
        _category = rule.categoryId == null ? null : await ref.read(categoriesRepositoryProvider).byId(rule.categoryId!);
      }
    } else {
      final now = DateTime.now();
      _nextOn = DateTime(now.year, now.month, now.day, 9);
      _accountId = (await ref.read(accountsRepositoryProvider).getAll()).firstOrNull?.id;
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _payeeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _amountMinor => parseAmountToMinor(_amountController.text) ?? 0;

  String? _validationError(AppLocalizations l10n) {
    if (amountErrorText(context, _amountController.text) != null) return l10n.invalidAmount;
    if (_amountMinor <= 0) return l10n.errorAmountZero;
    if (_kind != 'transfer' && _category == null) return l10n.errorPickCategory;
    if (_kind == 'transfer' && (_accountId == null || _toAccountId == null)) return l10n.errorPickBothAccounts;
    if (_existing?.groupId != null && !isGroupRuleKind(_kind)) return l10n.groupRecurringExpenseOnly;
    final groupTemplate = GroupExpenseTemplate.decode(_existing?.groupSplit);
    if (groupTemplate != null && !templateFitsAmount(groupTemplate, _amountMinor)) return l10n.groupRecurringAmountFixed;
    if (!_repeat.isValidFrom(_nextOn)) return l10n.recurringEndBeforeStart;
    return null;
  }

  /// The schedule to store. A rule anchored on the salary-month day keeps
  /// that anchor while it stays monthly on a fixed day.
  RecurrenceSpec _spec() {
    final spec = _repeat.specFrom(_nextOn);
    final keepsMonthStart = _existing?.dayOfMonth == kMonthStartDayOfMonth && spec.frequency == RecurrenceFrequency.monthly && !_repeat.lastDayOfMonth;
    if (!keepsMonthStart) return spec;
    return RecurrenceSpec(frequency: spec.frequency, start: spec.start, interval: spec.interval, dayOfMonth: kMonthStartDayOfMonth, endDate: spec.endDate, maxCount: spec.maxCount);
  }

  RecurringRulesCompanion _companion() {
    final spec = _spec();
    final payee = _payeeController.text.trim();
    final isTransfer = _kind == 'transfer';
    final fields = RecurringRepository.newRule(
      id: _existing?.id,
      name: _nameController.text.trim(),
      kind: _kind,
      amountMinor: _amountMinor,
      categoryId: isTransfer ? null : _category?.id,
      accountId: _accountId,
      toAccountId: isTransfer ? _toAccountId : null,
      payee: payee.isEmpty ? null : payee,
      projectId: isTransfer ? null : _existing?.projectId,
      note: _noteController.text.trim(),
      frequency: spec.frequency,
      interval: spec.interval,
      dayOfMonth: spec.dayOfMonth,
      weekday: spec.weekday,
      startDate: _nextOn,
      endDate: spec.endDate,
      maxCount: spec.maxCount,
      autoPost: _repeat.autoPost,
    );
    final existing = _existing;
    if (existing == null) return fields;
    // Keep what this form does not show (subscription flag, reminders).
    return fields.copyWith(isSubscription: Value(existing.isSubscription), remindDaysBefore: Value(existing.remindDaysBefore), currency: Value(existing.currency));
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final error = _validationError(l10n);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _saving = true);
    await ref.read(recurringRepositoryProvider).saveRule(_companion(), monthStartDay: ref.read(settingsProvider).monthStartDay);
    if (mounted) popOrGoHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final title = Text(widget.ruleId == null ? l10n.recurringNew : l10n.recurringEdit);
    if (_missing) {
      return Scaffold(appBar: AppBar(title: title), body: EmptyState(icon: Icons.repeat, title: l10n.recurringRuleMissing));
    }
    if (!_loaded) return Scaffold(appBar: AppBar(title: title));
    return Scaffold(
      appBar: AppBar(title: title),
      body: DismissKeyboardOnTap(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          children: [
            if (_existing?.groupId == null) ...[
            SegmentedButton<String>(
              segments: [
                compactSegment(context, value: 'expense', label: l10n.kindExpense, icon: Icons.arrow_upward),
                compactSegment(context, value: 'income', label: l10n.kindIncome, icon: Icons.arrow_downward),
                compactSegment(context, value: 'transfer', label: l10n.kindTransfer, icon: Icons.swap_horiz),
              ],
              selected: {_kind},
              onSelectionChanged: (set) => setState(() {
                _kind = set.first;
                _category = null;
              }),
            ),
            const SizedBox(height: 16),
            ],
            TextField(
              key: const ValueKey('recurring.amount'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: amountInputFormatters,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(prefixText: '$symbol ', hintText: '0', errorText: amountErrorText(context, _amountController.text)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('recurring.name'),
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.recurringNameLabel, prefixIcon: const Icon(Icons.label_outline)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            if (_kind != 'transfer')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconBadge(icon: _category?.icon ?? 'category', color: _category?.color ?? 0xFF9E9E9E),
                title: Text(_category?.displayName(context) ?? l10n.chooseCategory),
                subtitle: _category == null ? Text(l10n.required) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showCategoryPicker(context, kind: _kind, selectedId: _category?.id);
                  if (picked != null) setState(() => _category = picked);
                },
              ),
            const SizedBox(height: 8),
            // A group rule is paid by a member, not from one of my accounts.
            if (_existing?.groupId == null) ...[
              Text(_kind == 'transfer' ? l10n.fromAccount : l10n.account, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              AccountChoiceChips(accounts: accounts, selectedId: _accountId, onPick: (id) => setState(() => _accountId = id)),
            ],
            if (_kind == 'transfer') ...[
              const SizedBox(height: 12),
              Text(l10n.toAccount, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              AccountChoiceChips(accounts: accounts.where((account) => account.id != _accountId).toList(), selectedId: _toAccountId, onPick: (id) => setState(() => _toAccountId = id)),
            ],
            const SizedBox(height: 8),
            ListTile(
              key: const ValueKey('recurring.nextOn'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(l10n.recurringNextOn),
              subtitle: Text(formatShortDate(_nextOn, locale: locale)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _nextOn, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 3650)));
                if (picked != null) setState(() => _nextOn = DateTime(picked.year, picked.month, picked.day, _nextOn.hour, _nextOn.minute));
              },
            ),
            RepeatTile(draft: _repeat, start: _nextOn, allowNone: false, onChanged: (draft) => setState(() => _repeat = draft ?? _repeat)),
            const SizedBox(height: 8),
            TextField(controller: _payeeController, decoration: InputDecoration(labelText: l10n.payeeLabel, prefixIcon: const Icon(Icons.storefront_outlined)), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: _noteController, decoration: InputDecoration(labelText: l10n.note, prefixIcon: const Icon(Icons.notes)), textCapitalization: TextCapitalization.sentences, maxLines: 2),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          key: const ValueKey('recurring.save'),
          onPressed: _saving ? null : _save,
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(_saving ? l10n.saving : l10n.save)),
        ),
      ),
    );
  }
}
