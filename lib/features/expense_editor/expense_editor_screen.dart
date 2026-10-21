import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/entries_repository.dart';
import '../../domain/ledger/balance_effects.dart';
import '../../domain/split/split_calculator.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../categories/category_picker.dart';
import '../shell/widgets/common.dart';
import '../split/split_editor.dart';
import 'item_row.dart';

class ExpenseEditorScreen extends ConsumerStatefulWidget {
  const ExpenseEditorScreen({super.key, this.entryId, this.groupId, this.initialKind, this.smsId});
  final String? entryId;
  final String? groupId;
  final String? initialKind;
  final String? smsId;

  @override
  ConsumerState<ExpenseEditorScreen> createState() => _ExpenseEditorScreenState();
}

class _ExpenseEditorScreenState extends ConsumerState<ExpenseEditorScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _payeeController = TextEditingController();

  String _kind = 'expense';
  DateTime _occurredAt = DateTime.now();
  Category? _category;
  String? _accountId;
  String? _toAccountId;
  String? _groupId;
  String? _paidByMemberId;
  SplitMethod _splitMethod = SplitMethod.equal;
  List<SplitInput> _splitInputs = const [];
  List<ItemDraft> _items = [];
  List<ItemSuggestion> _suggestions = const [];
  List<Member> _members = const [];
  String _source = 'manual';
  String? _smsId;
  bool _loaded = false;
  bool _saving = false;
  String? _existingId;
  /// Balance-relevant fields of the stored entry, used to reverse its
  /// effect when the entry is edited or deleted.
  EntrySnapshot? _previousSnapshot;

  bool get _isEditing => widget.entryId != null;
  bool get _hasItems => _items.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind ?? 'expense';
    _groupId = widget.groupId;
    _smsId = widget.smsId;
    _load();
  }

  Future<void> _load() async {
    if (widget.entryId != null) {
      final details = await ref.read(entriesRepositoryProvider).getEntry(widget.entryId!);
      if (details != null) {
        final entry = details.entry;
        _existingId = entry.id;
        _kind = entry.kind;
        _amountController.text = amountInputText(entry.amountMinor);
        _noteController.text = entry.note;
        _payeeController.text = entry.payee ?? '';
        _occurredAt = entry.occurredAt;
        _category = details.category;
        _accountId = entry.accountId;
        _toAccountId = entry.toAccountId;
        _groupId = entry.groupId;
        _paidByMemberId = entry.paidByMemberId;
        _source = entry.source;
        _smsId = entry.smsId;
        _previousSnapshot = EntrySnapshot(
          kind: entry.kind,
          amountMinor: entry.amountMinor,
          accountId: entry.accountId,
          toAccountId: entry.toAccountId,
          source: entry.source,
          groupId: entry.groupId,
        );
        _splitMethod = SplitMethod.values.firstWhere((m) => m.name == entry.splitMethod, orElse: () => SplitMethod.equal);
        _items = details.items.map(ItemDraft.fromRow).toList();
        if (_groupId != null) {
          await _loadMembers();
          _splitInputs = _inputsFromSplits(details.splits);
        }
      }
    } else if (widget.smsId != null) {
      await _prefillFromSms(widget.smsId!);
    } else {
      final accounts = await ref.read(accountsRepositoryProvider).getAll();
      _accountId ??= accounts.firstOrNull?.id;
      if (_groupId != null) {
        await _loadMembers();
        _paidByMemberId = _members.where((m) => m.isMe).firstOrNull?.id ?? _members.firstOrNull?.id;
        _splitInputs = defaultSplitInputs(_members, _splitMethod);
      }
    }
    if (_category != null) await _refreshSuggestions();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _prefillFromSms(String smsId) async {
    final log = await ref.read(smsLogRepositoryProvider).getById(smsId);
    if (log == null || log.parsedJson == null) return;
    final parsed = Map<String, dynamic>.from(jsonDecode(log.parsedJson!) as Map);
    _kind = parsed['direction'] == 'credit' ? 'income' : 'expense';
    _amountController.text = amountInputText(parsed['amountMinor'] as int);
    _occurredAt = DateTime.tryParse(parsed['occurredAt'] as String? ?? '') ?? log.receivedAt;
    _payeeController.text = (parsed['counterparty'] as String?) ?? '';
    _source = 'sms';
    final categoryKey = parsed['suggestedCategory'] as String?;
    if (categoryKey != null) _category = await ref.read(categoriesRepositoryProvider).findBySeedKey(categoryKey);
    final accountKey = parsed['accountKey'] as String?;
    if (accountKey != null) _accountId = (await ref.read(accountsRepositoryProvider).findBySmsKey(accountKey))?.id;
  }

  Future<void> _loadMembers() async {
    _members = await ref.read(groupsRepositoryProvider).getMembers(_groupId!);
  }

  List<SplitInput> _inputsFromSplits(List<Split> splits) {
    final byMember = {for (final s in splits) s.memberId: s};
    return [
      for (final m in _members)
        SplitInput(
          memberId: m.id,
          included: byMember.containsKey(m.id),
          amountMinor: byMember[m.id]?.amountMinor ?? 0,
          weight: byMember[m.id]?.shareValue ?? 0,
        ),
    ];
  }

  Future<void> _refreshSuggestions() async {
    if (_category == null) return;
    final suggestions = await ref.read(entriesRepositoryProvider).itemSuggestions(_category!.id);
    if (mounted) setState(() => _suggestions = suggestions);
  }

  int get _itemsTotalMinor => _items.fold(0, (sum, i) => sum + i.amountMinor);

  int get _amountMinor => _hasItems ? _itemsTotalMinor : (parseAmountToMinor(_amountController.text) ?? 0);

  /// Mutates the item list and keeps the amount field bound to the items total (P1-2).
  /// When the last item is removed the last total stays prefilled and the field becomes editable again.
  void _updateItems(void Function() mutate) {
    setState(() {
      mutate();
      if (_hasItems) _amountController.text = amountInputText(_itemsTotalMinor);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final symbol = settings.currencySymbol;
    final units = _category?.units.split(',').where((u) => u.isNotEmpty).toList() ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editEntry : _groupId != null ? l10n.groupExpense : l10n.newEntry),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirmDialog(context, title: l10n.deleteEntryQuestion)) {
                  await ref.read(entriesRepositoryProvider).deleteEntry(_existingId!);
                  if (_previousSnapshot != null) {
                    await ref.read(accountsRepositoryProvider).applyBalanceDeltas(deleteDeltas(_previousSnapshot!));
                  }
                  if (context.mounted) popOrGoHome(context);
                }
              },
            ),
        ],
      ),
      body: DismissKeyboardOnTap(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          children: [
          if (_groupId == null)
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
                _items = [];
                _amountController.text = '';
              }),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            readOnly: _hasItems,
            autofocus: !_isEditing && !_hasItems,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: amountInputFormatters,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '$symbol ',
              hintText: '0',
              helperText: _hasItems ? l10n.totalOfItems(_items.length) : null,
              errorText: _hasItems ? null : amountErrorText(context, _amountController.text),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_kind != 'transfer')
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IconBadge(icon: _category?.icon ?? 'category', color: _category?.color ?? 0xFF9E9E9E),
              title: Text(_category?.displayName(context) ?? l10n.chooseCategory),
              subtitle: _category == null ? Text(l10n.required) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showCategoryPicker(context, kind: _kind, selectedId: _category?.id);
                if (picked != null) {
                  setState(() => _category = picked);
                  await _refreshSuggestions();
                }
              },
            ),
          if (_kind == 'expense' && _groupId == null) _itemsSection(symbol, units),
          // Group expenses are a ledger between people, not an account
          // movement, so they never pick (or touch) a personal account.
          if (_groupId == null) ...[
            const SizedBox(height: 8),
            Text(_kind == 'transfer' ? l10n.fromAccount : l10n.account, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            _accountChips(accounts, _accountId, (id) => setState(() => _accountId = id)),
            if (_kind == 'transfer') ...[
              const SizedBox(height: 12),
              Text(l10n.toAccount, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              _accountChips(accounts.where((a) => a.id != _accountId).toList(), _toAccountId, (id) => setState(() => _toAccountId = id)),
            ],
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(formatShortDate(_occurredAt, locale: Localizations.localeOf(context).toString())),
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: _occurredAt, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setState(() => _occurredAt = DateTime(picked.year, picked.month, picked.day, _occurredAt.hour, _occurredAt.minute));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(formatTime(_occurredAt, locale: Localizations.localeOf(context).toString())),
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_occurredAt));
                  if (picked != null) setState(() => _occurredAt = DateTime(_occurredAt.year, _occurredAt.month, _occurredAt.day, picked.hour, picked.minute));
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(controller: _payeeController, decoration: InputDecoration(labelText: l10n.payeeLabel, prefixIcon: const Icon(Icons.storefront_outlined)), textCapitalization: TextCapitalization.words),
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: InputDecoration(labelText: l10n.note, prefixIcon: const Icon(Icons.notes)), textCapitalization: TextCapitalization.sentences, maxLines: 2),
          if (_groupId != null) _groupSection(symbol),
          if (_source == 'sms')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(l10n.smsEntryNotice, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? l10n.saving : l10n.saveAmount(formatMinor(_amountMinor, symbol: symbol))),
        ),
      ),
    );
  }

  Widget _accountChips(List<Account> accounts, String? selected, ValueChanged<String?> onPick) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final account in accounts)
          ChoiceChip(
            avatar: CircleAvatar(backgroundColor: Color(account.color), radius: 6),
            label: Text(account.name),
            selected: selected == account.id,
            onSelected: (_) => onPick(account.id),
          ),
        if (accounts.isEmpty) ActionChip(label: Text(context.l10n.addAccount), avatar: const Icon(Icons.add, size: 16), onPressed: () => context.push('/accounts')),
      ],
    );
  }

  Widget _itemsSection(String symbol, List<String> units) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          l10n.items,
          trailing: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addItem),
            onPressed: () => _updateItems(() => _items.add(ItemDraft())),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final suggestion in _suggestions.where((s) => !_items.any((i) => i.name.toLowerCase() == s.name.toLowerCase())))
                  ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(l10n.itemSuggestion(suggestion.name, formatQuantity(suggestion.lastQuantity, suggestion.unit), formatMinor(suggestion.lastUnitPriceMinor, symbol: symbol))),
                    onPressed: () => _updateItems(() => _items.add(ItemDraft(
                          name: suggestion.name,
                          quantity: suggestion.lastQuantity,
                          unit: suggestion.unit,
                          unitPriceMinor: suggestion.lastUnitPriceMinor,
                        ))),
                  ),
              ],
            ),
          ),
        for (var i = 0; i < _items.length; i++)
          ItemRow(
            key: ValueKey(_items[i].id),
            draft: _items[i],
            units: units,
            symbol: symbol,
            onChanged: (draft) => _updateItems(() => _items[i] = draft),
            onRemove: () => _updateItems(() => _items.removeAt(i)),
          ),
        if (_items.isEmpty && _suggestions.isEmpty)
          Text(l10n.itemsHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _groupSection(String symbol) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.paidBy),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in _members)
              ChoiceChip(label: Text(member.isMe ? l10n.youSuffix(member.name) : member.name), selected: _paidByMemberId == member.id, onSelected: (_) => setState(() => _paidByMemberId = member.id)),
          ],
        ),
        SectionHeader(l10n.split),
        SplitEditor(
          totalMinor: _amountMinor,
          members: _members,
          method: _splitMethod,
          inputs: _splitInputs,
          symbol: symbol,
          onMethodChanged: (method) => setState(() {
            _splitMethod = method;
            _splitInputs = defaultSplitInputs(_members, method);
          }),
          onInputsChanged: (inputs) => setState(() => _splitInputs = inputs),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final amount = _amountMinor;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!_hasItems && amountErrorText(context, _amountController.text) != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }
    if (amount <= 0) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorAmountZero)));
      return;
    }
    if (_kind != 'transfer' && _category == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorPickCategory)));
      return;
    }
    if (_kind == 'transfer' && (_accountId == null || _toAccountId == null)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorPickBothAccounts)));
      return;
    }
    if (_items.any((i) => i.name.trim().isEmpty)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorItemName)));
      return;
    }
    SplitOutcome? outcome;
    if (_groupId != null) {
      if (_paidByMemberId == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorChoosePayer)));
        return;
      }
      outcome = computeSplit(totalMinor: amount, method: _splitMethod, inputs: _splitInputs);
      if (!outcome.isValid) {
        messenger.showSnackBar(SnackBar(content: Text(outcome.error == null ? l10n.errorFixSplit : splitErrorMessage(outcome.error!, l10n, ref.read(settingsProvider).currencySymbol))));
        return;
      }
    }
    setState(() => _saving = true);
    if (_source == 'sms' && _smsId != null && _accountId == null && _groupId == null) {
      _accountId = (await ref.read(smsIngestServiceProvider).ensureAccountForSms(_smsId!))?.id;
    }
    final id = _existingId ?? newId();
    final entry = EntriesRepository.newExpense(
      id: id,
      kind: _kind,
      amountMinor: amount,
      occurredAt: _occurredAt,
      categoryId: _category?.id,
      accountId: _groupId == null ? _accountId : null,
      note: _noteController.text.trim(),
      payee: _payeeController.text.trim().isEmpty ? null : _payeeController.text.trim(),
      source: _source,
      smsId: _smsId,
      groupId: _groupId,
      paidByMemberId: _paidByMemberId,
      splitMethod: _groupId == null ? null : _splitMethod.name,
    ).copyWith(toAccountId: Value(_kind == 'transfer' ? _toAccountId : null));
    final weights = {for (final i in _splitInputs) i.memberId: i};
    await ref.read(entriesRepositoryProvider).saveEntry(
          entry,
          items: [for (final draft in _items) draft.toCompanion(id)],
          splits: [
            if (outcome != null)
              for (final share in outcome.shares)
                SplitsCompanion.insert(
                  id: newId(),
                  entryId: id,
                  memberId: share.memberId,
                  amountMinor: share.amountMinor,
                  shareValue: Value(_splitMethod == SplitMethod.exact || _splitMethod == SplitMethod.adjustment
                      ? weights[share.memberId]?.amountMinor.toDouble()
                      : weights[share.memberId]?.weight),
                ),
          ],
        );
    await _applyBalanceChange(amount);
    if (_smsId != null) await ref.read(smsLogRepositoryProvider).setStatus(_smsId!, 'added', entryId: id);
    if (mounted) popOrGoHome(context);
  }

  /// Manual entries move the account's running balance; SMS and group
  /// entries do not. The deltas come from the pure ledger module so the
  /// previous version of the entry is always fully reversed first.
  Future<void> _applyBalanceChange(int amount) async {
    final next = EntrySnapshot(
      kind: _kind,
      amountMinor: amount,
      accountId: _accountId,
      toAccountId: _kind == 'transfer' ? _toAccountId : null,
      source: _source,
      groupId: _groupId,
    );
    await ref.read(accountsRepositoryProvider).applyBalanceDeltas(editDeltas(previous: _previousSnapshot, next: next));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _payeeController.dispose();
    super.dispose();
  }
}
