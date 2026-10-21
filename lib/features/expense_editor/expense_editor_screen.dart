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
import '../../domain/split/split_calculator.dart';
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
  int? _previousAmountMinor;
  String? _previousAccountId;

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
        _amountController.text = minorToDouble(entry.amountMinor).toStringAsFixed(2);
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
        _previousAmountMinor = entry.amountMinor;
        _previousAccountId = entry.accountId;
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
    final log = await (ref.read(databaseProvider).select(ref.read(databaseProvider).smsLog)
          ..where((t) => t.id.equals(smsId)))
        .getSingleOrNull();
    if (log == null || log.parsedJson == null) return;
    final parsed = Map<String, dynamic>.from(jsonDecode(log.parsedJson!) as Map);
    _kind = parsed['direction'] == 'credit' ? 'income' : 'expense';
    _amountController.text = minorToDouble(parsed['amountMinor'] as int).toStringAsFixed(2);
    _occurredAt = DateTime.tryParse(parsed['occurredAt'] as String? ?? '') ?? log.receivedAt;
    _payeeController.text = (parsed['counterparty'] as String?) ?? '';
    _source = 'sms';
    final categoryKey = parsed['suggestedCategory'] as String?;
    if (categoryKey != null) _category = await ref.read(categoriesRepositoryProvider).findBySeedKey(categoryKey);
    final accountKey = parsed['accountKey'] as String?;
    if (accountKey != null) _accountId = (await ref.read(accountsRepositoryProvider).findBySmsKey(accountKey))?.id;
  }

  Future<void> _loadMembers() async {
    _members = await ref.read(groupsRepositoryProvider).watchMembers(_groupId!).first;
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

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final settings = ref.watch(settingsProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final symbol = settings.currencySymbol;
    final units = _category?.units.split(',').where((u) => u.isNotEmpty).toList() ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit entry' : _groupId != null ? 'Group expense' : 'New entry'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirmDialog(context, title: 'Delete this entry?')) {
                  await ref.read(entriesRepositoryProvider).deleteEntry(_existingId!);
                  if (_previousAccountId != null && _source != 'sms' && _kind != 'transfer') {
                    await ref.read(accountsRepositoryProvider).adjustBalance(_previousAccountId!, _kind == 'expense' ? _previousAmountMinor! : -_previousAmountMinor!);
                  }
                  if (context.mounted) context.pop();
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          if (_groupId == null)
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: 'transfer', label: Text('Transfer'), icon: Icon(Icons.swap_horiz)),
              ],
              selected: {_kind},
              onSelectionChanged: (set) => setState(() {
                _kind = set.first;
                _category = null;
                _items = [];
              }),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            readOnly: _hasItems,
            autofocus: !_isEditing && !_hasItems,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '$symbol ',
              hintText: '0',
              helperText: _hasItems ? 'Total of ${_items.length} items' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_kind != 'transfer')
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IconBadge(icon: _category?.icon ?? 'category', color: _category?.color ?? 0xFF9E9E9E),
              title: Text(_category?.name ?? 'Choose category'),
              subtitle: _category == null ? const Text('Required') : null,
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
          const SizedBox(height: 8),
          Text(_kind == 'transfer' ? 'From account' : 'Account', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          _accountChips(accounts, _accountId, (id) => setState(() => _accountId = id)),
          if (_kind == 'transfer') ...[
            const SizedBox(height: 12),
            Text('To account', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            _accountChips(accounts.where((a) => a.id != _accountId).toList(), _toAccountId, (id) => setState(() => _toAccountId = id)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(formatShortDate(_occurredAt)),
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
                label: Text(formatTime(_occurredAt)),
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_occurredAt));
                  if (picked != null) setState(() => _occurredAt = DateTime(_occurredAt.year, _occurredAt.month, _occurredAt.day, picked.hour, picked.minute));
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(controller: _payeeController, decoration: const InputDecoration(labelText: 'Paid to / received from', prefixIcon: Icon(Icons.storefront_outlined)), textCapitalization: TextCapitalization.words),
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Note', prefixIcon: Icon(Icons.notes)), textCapitalization: TextCapitalization.sentences, maxLines: 2),
          if (_groupId != null) _groupSection(symbol),
          if (_source == 'sms')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Created from a bank SMS. Editing it will not change your bank balance.', style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(_saving ? 'Saving…' : 'Save ${formatMinor(_amountMinor, symbol: symbol)}'),
          ),
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
        if (accounts.isEmpty) ActionChip(label: const Text('Add account'), avatar: const Icon(Icons.add, size: 16), onPressed: () => context.push('/accounts')),
      ],
    );
  }

  Widget _itemsSection(String symbol, List<String> units) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Items',
          trailing: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add item'),
            onPressed: () => setState(() => _items.add(ItemDraft(unit: units.firstOrNull))),
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
                    label: Text('${suggestion.name} · ${formatQuantity(suggestion.lastQuantity, suggestion.unit)} @ ${formatMinor(suggestion.lastUnitPriceMinor, symbol: symbol)}'),
                    onPressed: () => setState(() => _items.add(ItemDraft(
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
            onChanged: (draft) => setState(() => _items[i] = draft),
            onRemove: () => setState(() => _items.removeAt(i)),
          ),
        if (_items.isEmpty && _suggestions.isEmpty)
          Text('Optional: break this expense into items with quantity and price (e.g. buffalo milk 1 L). Hisab remembers them for next time.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _groupSection(String symbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Paid by'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in _members)
              ChoiceChip(label: Text(member.isMe ? '${member.name} (you)' : member.name), selected: _paidByMemberId == member.id, onSelected: (_) => setState(() => _paidByMemberId = member.id)),
          ],
        ),
        const SectionHeader('Split'),
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
    final messenger = ScaffoldMessenger.of(context);
    if (amount <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter an amount greater than zero')));
      return;
    }
    if (_kind != 'transfer' && _category == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Pick a category')));
      return;
    }
    if (_kind == 'transfer' && (_accountId == null || _toAccountId == null)) {
      messenger.showSnackBar(const SnackBar(content: Text('Pick both accounts for a transfer')));
      return;
    }
    if (_items.any((i) => i.name.trim().isEmpty)) {
      messenger.showSnackBar(const SnackBar(content: Text('Every item needs a name')));
      return;
    }
    SplitOutcome? outcome;
    if (_groupId != null) {
      if (_paidByMemberId == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Choose who paid')));
        return;
      }
      outcome = computeSplit(totalMinor: amount, method: _splitMethod, inputs: _splitInputs);
      if (!outcome.isValid) {
        messenger.showSnackBar(SnackBar(content: Text(outcome.error ?? 'Fix the split first')));
        return;
      }
    }
    setState(() => _saving = true);
    final id = _existingId ?? newId();
    final entry = EntriesRepository.newExpense(
      id: id,
      kind: _kind,
      amountMinor: amount,
      occurredAt: _occurredAt,
      categoryId: _category?.id,
      accountId: _accountId,
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
    if (mounted) context.pop();
  }

  /// Manual entries move the account's running balance; SMS entries do not,
  /// because the bank SMS already told us the resulting balance.
  Future<void> _applyBalanceChange(int amount) async {
    if (_source == 'sms' || _groupId != null) return;
    final accounts = ref.read(accountsRepositoryProvider);
    if (_previousAccountId != null && _previousAmountMinor != null) {
      await accounts.adjustBalance(_previousAccountId!, _kind == 'income' ? -_previousAmountMinor! : _previousAmountMinor!);
    }
    if (_accountId == null) return;
    switch (_kind) {
      case 'expense':
        await accounts.adjustBalance(_accountId!, -amount);
      case 'income':
        await accounts.adjustBalance(_accountId!, amount);
      case 'transfer':
        await accounts.adjustBalance(_accountId!, -amount);
        if (_toAccountId != null) await accounts.adjustBalance(_toAccountId!, amount);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _payeeController.dispose();
    super.dispose();
  }
}
