import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/entry_removal.dart';
import '../../data/repositories/project_fields_repository.dart';
import '../../data/repositories/projects_repository.dart';
import '../../data/repositories/group_recurring_repository.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/entries/entry_accounts.dart';
import '../../domain/ledger/balance_effects.dart';
import '../../domain/projects/project_fields.dart';
import '../../domain/projects/project_math.dart';
import '../../domain/projects/project_picker.dart';
import '../../domain/projects/project_templates.dart';
import '../../domain/recurring/repeat_draft.dart';
import '../../domain/reminders/reminder_draft.dart';
import '../../domain/split/group_recurring.dart';
import '../../domain/accounts/default_account.dart';
import '../../domain/split/group_settings.dart';
import '../../domain/split/item_split.dart';
import '../../domain/split/payers.dart';
import '../../domain/split/split_calculator.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../accounts/account_picker_tile.dart';
import '../groups/member_display.dart';
import '../categories/category_picker.dart';
import '../projects/project_field_inputs.dart';
import '../projects/project_picker_sheet.dart';
import '../recurring/repeat_sheet.dart';
import '../shell/widgets/common.dart';
import '../split/item_assign_strip.dart';
import '../split/payers_editor.dart';
import '../split/split_editor.dart';
import 'calculator_sheet.dart';
import 'editor_draft.dart';
import 'item_row.dart';

class ExpenseEditorScreen extends ConsumerStatefulWidget {
  const ExpenseEditorScreen({super.key, this.entryId, this.groupId, this.initialKind, this.smsId, this.projectId, this.reminderId});
  final String? entryId;
  final String? groupId;

  /// Project a new entry starts tagged to, e.g. from a project's Add entry.
  final String? projectId;
  final String? initialKind;
  final String? smsId;

  /// Due reminder this entry pays (notification "Mark paid"); prefills the
  /// form and marks the reminder paid on save.
  final String? reminderId;

  @override
  ConsumerState<ExpenseEditorScreen> createState() => _ExpenseEditorScreenState();
}

class _ExpenseEditorScreenState extends ConsumerState<ExpenseEditorScreen> {
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();

  /// The amount field autofocuses only when the editor opens. The ListView
  /// builds it lazily, so a field rebuilt after scrolling back (or after the
  /// keyboard closes and the list grows) must not grab focus again: that
  /// reopened the keyboard and scrolled the editor away from the Repeat tile.
  bool _autofocusAmount = true;
  final _noteController = TextEditingController();
  final _payeeController = TextEditingController();

  String _kind = 'expense';
  DateTime _occurredAt = DateTime.now();
  Category? _category;
  String? _accountId;
  String? _toAccountId;
  String? _groupId;
  String? _projectId;
  String? _paidByMemberId;

  /// True when several members paid; [_payerAmounts] then holds each one's part.
  bool _multiplePayers = false;
  Map<String, int> _payerAmounts = const {};
  SplitMethod _splitMethod = SplitMethod.equal;
  List<SplitInput> _splitInputs = const [];
  List<ItemDraft> _items = [];

  /// Set once a save is blocked on an unnamed item, so the offending rows
  /// flag their name field until it is filled in.
  bool _showItemErrors = false;

  /// Entry-scope fields of the entry's project, and the values recorded for
  /// them (plus any for fields since removed, kept so a save does not drop them).
  List<ProjectField> _projectFields = const [];
  Map<String, FieldReading> _fieldValues = const {};
  List<ItemSuggestion> _suggestions = const [];
  List<Member> _members = const [];
  Group? _group;
  String _source = 'manual';
  String? _smsId;

  /// Category the screen opened with, so a change on an SMS entry is remembered for its payee.
  String? _loadedCategoryId;
  bool _loaded = false;
  bool _saving = false;
  String? _existingId;

  /// Repeat chosen for a new entry; null saves a one-off entry.
  RepeatDraft? _repeat;

  /// Rule an existing entry was posted by (or started), if any.
  String? _recurringId;
  /// Balance-relevant fields of the stored entry, used to reverse its
  /// effect when the entry is edited or deleted.
  EntrySnapshot? _previousSnapshot;

  bool get _isEditing => widget.entryId != null;
  bool get _hasItems => _items.isNotEmpty;

  /// Advanced fields collapse behind "More details" so a trivial spend shows
  /// only amount/category/account. The section opens itself on first build
  /// whenever a tucked-away field already has a non-default value, so nothing
  /// the user (or a prefill) entered is ever out of sight; editing a plain
  /// entry stays as short as adding one.
  bool get _startExpanded =>
      _recurringId != null ||
      _repeat != null ||
      _items.isNotEmpty ||
      _projectId != null ||
      _noteController.text.trim().isNotEmpty ||
      _payeeController.text.trim().isNotEmpty ||
      !isSameDay(_occurredAt, DateTime.now());

  /// The input the editor opened with (or was reset to by "Save & add
  /// another"); leaving with anything different asks first (#82).
  String? _openedWith;

  /// Whether the last build saw unsaved input, so typing only rebuilds when
  /// that flips and Back's behaviour has to change.
  bool _unsavedAtBuild = false;

  String get _draft => editorDraftFingerprint(
        kind: _kind,
        amountMinor: _hasItems ? _itemsTotalMinor : parseAmountToMinor(_amountController.text, format: _moneyFormat),
        note: _noteController.text,
        payee: _payeeController.text,
        occurredAt: _occurredAt,
        categoryId: _category?.id,
        accountId: _accountId,
        toAccountId: _toAccountId,
        projectId: _projectId,
        paidByMemberId: _paidByMemberId,
        multiplePayers: _multiplePayers,
        payerAmounts: _payerAmounts,
        splitMethod: _splitMethod,
        splitInputs: _splitInputs,
        items: _items,
        fieldValues: _fieldValues,
        repeat: _repeat,
      );

  bool get _hasUnsavedInput => _openedWith != null && _draft != _openedWith;

  void _onTextChanged() {
    if (mounted && _hasUnsavedInput != _unsavedAtBuild) setState(() {});
  }

  /// Back, the back gesture or the close button with unsaved input lands
  /// here instead of leaving: Keep editing stays, Discard leaves.
  Future<void> _confirmDiscard() async {
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardEntryTitle),
        content: Text(l10n.discardEntryBody),
        actions: [
          TextButton(key: const Key('keep-editing'), onPressed: () => Navigator.pop(context, false), child: Text(l10n.keepEditing)),
          FilledButton(key: const Key('discard-entry'), onPressed: () => Navigator.pop(context, true), child: Text(l10n.discard)),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    setState(() => _openedWith = null);
    popOrGoHome(context);
  }

  /// "Save & add another" is offered for new entries typed by hand; SMS
  /// entries and edits close the editor on save.
  bool get _canAddAnother => !_isEditing && widget.smsId == null && widget.reminderId == null && _source != 'sms';

  /// Repeat is offered on new entries typed by hand, group expenses included
  /// (rent, maid, wifi). SMS entries record what happened.
  bool get _canRepeat => !_isEditing && _source == 'manual';

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind ?? 'expense';
    _groupId = widget.groupId;
    _projectId = widget.projectId;
    _smsId = widget.smsId;
    for (final controller in [_amountController, _noteController, _payeeController]) {
      controller.addListener(_onTextChanged);
    }
    _load();
    _amountFocus.addListener(_stopAmountAutofocus);
  }

  /// Once the amount field has had focus, a rebuilt field never autofocuses.
  void _stopAmountAutofocus() {
    if (_amountFocus.hasFocus) _autofocusAmount = false;
  }

  Future<void> _load() async {
    if (widget.entryId != null) {
      final details = await ref.read(entriesRepositoryProvider).getEntry(widget.entryId!);
      if (details != null) {
        final entry = details.entry;
        _existingId = entry.id;
        _kind = entry.kind;
        _amountController.text = amountInputText(entry.amountMinor, format: _moneyFormat);
        _noteController.text = entry.note;
        _payeeController.text = entry.payee ?? '';
        _occurredAt = entry.occurredAt;
        _category = details.category;
        _accountId = entry.accountId;
        _toAccountId = entry.toAccountId;
        _groupId = entry.groupId;
        _projectId = entry.projectId;
        _paidByMemberId = entry.paidByMemberId;
        _source = entry.source;
        _smsId = entry.smsId;
        _recurringId = entry.recurringId;
        _previousSnapshot = snapshotOfEntry(entry);
        _splitMethod = SplitMethod.values.firstWhere((m) => m.name == entry.splitMethod, orElse: () => SplitMethod.equal);
        _items = details.items.map(ItemDraft.fromRow).toList();
        if (_groupId != null) {
          await _loadMembers();
          _splitInputs = _inputsFromSplits(details.splits);
          final assignments = await ref.read(entriesRepositoryProvider).getItemAssignments(entry.id);
          _items = [for (final row in details.items) ItemDraft.fromRow(row, memberIds: assignments[row.id] ?? (row.isShared ? const [] : _everyone))];
          final payers = await ref.read(entriesRepositoryProvider).getPayers(entry.id);
          if (payers.isNotEmpty) {
            _multiplePayers = true;
            _payerAmounts = {for (final payer in payers) payer.memberId: payer.amountMinor};
          }
        }
      }
    } else if (widget.smsId != null) {
      await _prefillFromSms(widget.smsId!);
    } else {
      if (widget.reminderId != null) await _prefillFromReminder(widget.reminderId!);
      final accounts = await ref.read(accountsRepositoryProvider).getAll();
      _accountId ??= defaultEntryAccountId(accounts, configuredId: ref.read(settingsProvider).defaultAccountId);
      final projects = await ref.read(projectsRepositoryProvider).getAll(includeArchived: false);
      _projectId = initialEntryProjectId(
        explicitId: widget.projectId,
        lastUsedId: ref.read(lastProjectIdProvider),
        activeIds: {for (final project in projects) if (ProjectStatus.parse(project.status) == ProjectStatus.active) project.id},
        isGroup: _groupId != null,
      );
      if (_groupId != null) {
        await _loadMembers();
        _paidByMemberId = _members.where((m) => m.isMe).firstOrNull?.id ?? _members.firstOrNull?.id;
        // New expenses start from the group's default split; saved ones keep theirs.
        _splitMethod = parseDefaultSplitMethod(_group?.defaultSplitMethod);
        _splitInputs = defaultSplitInputs(_members, _splitMethod);
      }
    }
    await _loadProjectFields();
    if (_category != null) await _refreshSuggestions();
    _openedWith = _draft;
    _loadedCategoryId = _category?.id;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _loadProjectFields() async {
    final repo = ref.read(projectFieldsRepositoryProvider);
    if (_existingId != null) _fieldValues = await repo.valuesForEntry(_existingId!);
    _projectFields = await _entryFieldsOf(_projectId);
  }

  Future<List<ProjectField>> _entryFieldsOf(String? projectId) async {
    if (projectId == null) return const [];
    final fields = await ref.read(projectFieldsRepositoryProvider).getFields(projectId);
    return fields.where((field) => field.scope == ProjectFieldScope.entry.name).toList();
  }

  /// Moves the entry to another project (or none), keeping only the field
  /// readings the new project also asks for.
  Future<void> _setProject(String? projectId) async {
    final fields = await _entryFieldsOf(projectId);
    if (!mounted) return;
    setState(() {
      _projectId = projectId;
      _projectFields = fields;
      _fieldValues = keepFieldValues(_fieldValues, fields.map((field) => field.key));
    });
  }

  Future<void> _pickProject() async {
    final choice = await showProjectPicker(context, selectedId: _projectId);
    if (choice != null && choice.projectId != _projectId) await _setProject(choice.projectId);
  }

  Widget _projectChip(AppLocalizations l10n, List<ProjectView> views) {
    final name = views.where((view) => view.project.id == _projectId).firstOrNull?.project.name;
    const key = ValueKey('editor.project');
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: name == null
          ? ActionChip(key: key, avatar: const Icon(Icons.create_new_folder_outlined, size: 18), label: Text(l10n.addToProject), onPressed: _pickProject)
          : InputChip(
              key: key,
              avatar: const Icon(Icons.folder_outlined, size: 18),
              label: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 140),
                child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              onPressed: _pickProject,
              onDeleted: () => _setProject(null),
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
    );
  }

  Future<void> _prefillFromSms(String smsId) async {
    final log = await ref.read(smsLogRepositoryProvider).getById(smsId);
    if (log == null) return;
    _source = 'sms';
    if (log.parsedJson == null) {
      _occurredAt = log.receivedAt;
      return;
    }
    final parsed = Map<String, dynamic>.from(jsonDecode(log.parsedJson!) as Map);
    _kind = parsed['direction'] == 'credit' ? 'income' : 'expense';
    _amountController.text = amountInputText(parsed['amountMinor'] as int, format: _moneyFormat);
    _occurredAt = DateTime.tryParse(parsed['occurredAt'] as String? ?? '') ?? log.receivedAt;
    _payeeController.text = (parsed['counterparty'] as String?) ?? '';
    _source = 'sms';
    final categoryKey = parsed['suggestedCategory'] as String?;
    // A category the user chose for this payee before wins over the keyword rules.
    _category = await ref.read(smsIngestServiceProvider).rememberedCategoryFor(kind: _kind, counterparty: parsed['counterparty'] as String?);
    if (_category == null && categoryKey != null) _category = await ref.read(categoriesRepositoryProvider).findBySeedKey(categoryKey);
    final accountKey = parsed['accountKey'] as String?;
    if (accountKey != null) _accountId = (await ref.read(accountsRepositoryProvider).findBySmsKey(accountKey))?.id;
  }

  Future<void> _prefillFromReminder(String reminderId) async {
    final reminder = await ref.read(remindersRepositoryProvider).getById(reminderId);
    if (reminder == null) return;
    _kind = 'expense';
    final amount = reminderAmountOrNone(reminder.amountMinor);
    if (amount != null) _amountController.text = amountInputText(amount, format: _moneyFormat);
    _payeeController.text = reminder.title;
    if (reminder.notes.isNotEmpty) _noteController.text = reminder.notes;
    if (reminder.categoryId != null) _category = await ref.read(categoriesRepositoryProvider).byId(reminder.categoryId!);
    _accountId = reminder.accountId ?? _accountId;
  }

  /// Loads the group's members and the group itself (default split, currency label).
  Future<void> _loadMembers() async {
    final repo = ref.read(groupsRepositoryProvider);
    _members = await repo.getMembers(_groupId!);
    final amountFormat = _moneyFormat;
    _group = await repo.getGroup(_groupId!);
    _amountController.text = reformatAmountInput(_amountController.text, from: amountFormat, to: _moneyFormat);
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

  int get _amountMinor => _hasItems ? _itemsTotalMinor : (parseAmountToMinor(_amountController.text, format: _moneyFormat) ?? 0);

  /// Mutates the item list and keeps the amount field bound to the items total (P1-2).
  /// When the last item is removed the last total stays prefilled and the field becomes editable again.
  void _updateItems(void Function() mutate) {
    final hadItems = _hasItems;
    setState(() {
      mutate();
      if (_hasItems) _amountController.text = amountInputText(_itemsTotalMinor, format: _moneyFormat);
      if (_groupId != null) _syncByItemSplit(hadItems: hadItems);
    });
  }

  List<String> get _everyone => [for (final member in _members) member.id];

  List<ItemSplitInput> get _itemInputs => [for (final draft in _items) draft.toSplitInput()];

  bool get _isByItem => _groupId != null && _splitMethod == SplitMethod.byItem;

  /// New group items start shared by everyone; the first item switches the
  /// split to "By item" and removing the last one switches it back to equal.
  void _syncByItemSplit({required bool hadItems}) {
    _items = [for (final draft in _items) draft.memberIds == null ? draft.copyWith(memberIds: _everyone) : draft];
    if (!hadItems && _hasItems) _setSplitMethod(SplitMethod.byItem);
    if (!_hasItems && _splitMethod == SplitMethod.byItem) _setSplitMethod(SplitMethod.equal);
  }

  void _setSplitMethod(SplitMethod method) {
    _splitMethod = method;
    _splitInputs = defaultSplitInputs(_members, method);
  }

  /// Leaving "By item" drops the assignments, after a confirm when some
  /// item is not simply split among everyone.
  Future<void> _changeSplitMethod(SplitMethod method) async {
    if (_splitMethod == SplitMethod.byItem && method != SplitMethod.byItem && hasCustomAssignments(_itemInputs, _everyone)) {
      final l10n = context.l10n;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.byItemClearTitle),
          content: Text(l10n.byItemClearBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)),
            FilledButton(key: const Key('byItem.clearConfirm'), onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.clear)),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      _items = [for (final draft in _items) draft.copyWith(memberIds: _everyone, isShared: false)];
    }
    setState(() => _setSplitMethod(method));
  }

  /// Currency label whose number format the amount uses: the group's own
  /// when the entry is in a group, else the app's (null).
  String? get _moneyFormatLabel => _groupId == null ? null : _group?.currencyLabel;

  /// Number format for amounts read or written outside build.
  MoneyFormat get _moneyFormat => ref.read(groupMoneyFormatProvider(_moneyFormatLabel));

  /// The payer who absorbs rounding remainders of a by-item split.
  String? get _remainderPayerId => _multiplePayers ? primaryPayerId(payersFrom(_payerAmounts)) ?? _paidByMemberId : _paidByMemberId;

  @override
  Widget build(BuildContext context) {
    _unsavedAtBuild = _hasUnsavedInput;
    return PopScope(
      canPop: !_unsavedAtBuild && context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_hasUnsavedInput) {
          _confirmDiscard();
        } else {
          context.go(kHomeLocation);
        }
      },
      child: _form(context),
    );
  }

  Widget _form(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final l10n = context.l10n;
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final moneyFormat = ref.watch(groupMoneyFormatProvider(_moneyFormatLabel));
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
                  if (_groupId != null) {
                    await _deleteGroupExpense(_existingId!);
                    if (context.mounted) popOrGoHome(context);
                    return;
                  }
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
            focusNode: _amountFocus,
            readOnly: _hasItems,
            autofocus: _autofocusAmount && !_isEditing && !_hasItems,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: amountInputFormatters,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: amountPrefixText(moneyFormat),
              suffixText: amountSuffixText(moneyFormat),
              hintText: '0',
              helperText: _hasItems ? l10n.totalOfItems(_items.length) : null,
              errorText: _hasItems ? null : amountErrorText(context, _amountController.text, format: moneyFormat),
              suffixIcon: _hasItems
                  ? null
                  : IconButton(
                      key: const ValueKey('editor.calculator'),
                      tooltip: l10n.calculator,
                      icon: const Icon(Icons.calculate_outlined),
                      onPressed: () => _openCalculator(moneyFormat),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_kind != 'transfer')
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IconBadge(icon: _category?.icon ?? 'category', color: _category?.color ?? 0xFF9E9E9E),
              title: Text(_category?.displayName(context) ?? l10n.uncategorised),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showCategoryPicker(context, kind: _kind, selectedId: _category?.id, allowClear: _category != null);
                if (picked != null) {
                  setState(() => _category = identical(picked, clearedCategory) ? null : picked);
                  await _refreshSuggestions();
                }
              },
            ),
          // Group expenses are a ledger between people, not an account
          // movement, so they never pick (or touch) a personal account.
          if (_groupId == null) ...[
            AccountPickerTile(
              key: const ValueKey('from-account'),
              label: _kind == 'transfer' ? l10n.fromAccount : l10n.account,
              accounts: accounts,
              selectedId: _accountId,
              onPick: (id) => setState(() {
                _accountId = id;
                _toAccountId = toAccountAfterFromChange(fromId: id, toId: _toAccountId);
              }),
            ),
            if (_kind == 'transfer')
              AccountPickerTile(
                key: const ValueKey('to-account'),
                label: l10n.toAccount,
                accounts: accounts.where((a) => a.id != _accountId).toList(),
                selectedId: _toAccountId,
                onPick: (id) => setState(() => _toAccountId = id),
              ),
          ],
          const SizedBox(height: 16),
          if (_groupId == null)
            _moreDetailsTile(context, l10n, moneyFormat, units)
          else ...[
            ..._detailFields(context, l10n, moneyFormat, units),
            _groupSection(moneyFormat),
          ],
          if (_source == 'sms')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                Icon(Icons.sms_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.smsEntryNotice, style: Theme.of(context).textTheme.bodySmall)),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: _saveButtons(l10n, moneyFormat),
      ),
    );
  }

  /// A by-item split with an item nobody shares cannot be saved yet.
  bool get _saveBlocked => _isByItem && anyItemUnassigned(_itemInputs);

  Widget _saveButtons(AppLocalizations l10n, MoneyFormat moneyFormat) {
    final save = FilledButton(
      key: const ValueKey('editor.save'),
      onPressed: _saving || _saveBlocked ? null : _save,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(_saving ? l10n.saving : l10n.saveAmount(formatMinor(_amountMinor, format: moneyFormat))),
      ),
    );
    if (!_canAddAnother) return save;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: OutlinedButton(
            key: const ValueKey('editor.saveAndAddAnother'),
            onPressed: _saving || _saveBlocked ? null : () => _save(addAnother: true),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.saveAndAddAnother)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: save),
      ],
    );
  }

  Future<void> _openCalculator(MoneyFormat moneyFormat) async {
    FocusScope.of(context).unfocus();
    final minor = await showCalculatorSheet(context, initialAmountText: _amountController.text, moneyFormat: moneyFormat);
    if (minor == null || !mounted) return;
    setState(() => _amountController.text = amountInputText(minor, format: _moneyFormat));
  }

  /// Clears the form for the next entry, keeping the kind, account, project,
  /// date and (for groups) the payer and split method.
  void _startNextEntry() {
    setState(() {
      _amountController.clear();
      _noteController.clear();
      _payeeController.clear();
      _category = null;
      _items = [];
      _repeat = null;
      _fieldValues = const {};
      _multiplePayers = false;
      _payerAmounts = {};
      if (_splitMethod == SplitMethod.byItem) _splitMethod = SplitMethod.equal;
      if (_groupId != null) _splitInputs = defaultSplitInputs(_members, _splitMethod);
      _saving = false;
      _openedWith = _draft;
    });
    _amountFocus.requestFocus();
  }

  /// The "More details" section for a personal entry: everything beyond
  /// amount/category/account, collapsed unless [_startExpanded].
  Widget _moreDetailsTile(BuildContext context, AppLocalizations l10n, MoneyFormat moneyFormat, List<String> units) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const ValueKey('editor.moreDetails'),
        initiallyExpanded: _startExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Text(l10n.moreDetails),
        // The date is the detail most often changed, so it shows while collapsed.
        subtitle: Text(formatDayLabel(_occurredAt, today: l10n.today, yesterday: l10n.yesterday, locale: Localizations.localeOf(context).toString())),
        children: _detailFields(context, l10n, moneyFormat, units),
      ),
    );
  }

  /// The advanced fields tucked behind "More details" (personal) or shown
  /// inline above the split (group): project, items, date/time, repeat, note.
  List<Widget> _detailFields(BuildContext context, AppLocalizations l10n, MoneyFormat moneyFormat, List<String> units) {
    return [
      if (_kind != 'transfer' && _groupId == null) ...[
        const SizedBox(height: 8),
        _projectChip(l10n, ref.watch(projectViewsProvider).value ?? const <ProjectView>[]),
      ],
      if (_kind == 'expense') _itemsSection(moneyFormat, units),
      if (_kind != 'transfer' && _projectFields.isNotEmpty) ...[
        SectionHeader(l10n.projectDetails, padding: const EdgeInsets.fromLTRB(0, 16, 0, 8)),
        ProjectFieldInputs(key: ValueKey('fields.$_projectId'), fields: _projectFields, values: _fieldValues, onChanged: (values) => setState(() => _fieldValues = values)),
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
      if (_canRepeat) ...[
        const SizedBox(height: 8),
        RepeatTile(draft: _repeat, start: _occurredAt, onChanged: (draft) => setState(() => _repeat = draft)),
      ],
      if (_recurringId != null) ...[
        const SizedBox(height: 8),
        ListTile(
          key: const ValueKey('editor.recurringRule'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.repeat),
          title: Text(l10n.recurringPartOfRule),
          // Group rules are managed from the group's Upcoming list.
          trailing: _groupId == null ? const Icon(Icons.chevron_right) : null,
          onTap: _groupId == null ? () => context.push('/recurring/${_recurringId!}') : null,
        ),
      ],
      const SizedBox(height: 16),
      TextField(controller: _payeeController, decoration: InputDecoration(labelText: l10n.payeeLabel, prefixIcon: const Icon(Icons.storefront_outlined)), textCapitalization: TextCapitalization.words),
      const SizedBox(height: 12),
      TextField(controller: _noteController, decoration: InputDecoration(labelText: l10n.note, prefixIcon: const Icon(Icons.notes)), textCapitalization: TextCapitalization.sentences, maxLines: 2),
    ];
  }

  Widget _itemsSection(MoneyFormat moneyFormat, List<String> units) {
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
                    label: Text(l10n.itemSuggestion(suggestion.name, formatQuantity(suggestion.lastQuantity, suggestion.unit), formatMinor(suggestion.lastUnitPriceMinor, format: moneyFormat))),
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
            moneyFormat: moneyFormat,
            onChanged: (draft) => _updateItems(() => _items[i] = draft),
            onRemove: () => _updateItems(() => _items.removeAt(i)),
            showNameError: _showItemErrors && _items[i].name.trim().isEmpty,
            footer: _isByItem
                ? ItemAssignStrip(
                    itemId: _items[i].id,
                    itemLabel: _items[i].name.trim(),
                    members: _members,
                    memberIds: _items[i].memberIds ?? const [],
                    shared: _items[i].isShared,
                    onMembersChanged: (memberIds) => _updateItems(() => _items[i] = _items[i].copyWith(memberIds: memberIds)),
                    onSharedChanged: (shared) => _updateItems(() => _items[i] = _items[i].copyWith(isShared: shared)),
                  )
                : null,
          ),
        if (_isByItem)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('byItem.addExtras'),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text(l10n.byItemAddExtras),
              onPressed: () => _updateItems(() => _items.add(ItemDraft(name: l10n.byItemAddExtras, isShared: true, memberIds: const []))),
            ),
          ),
        if (_items.isEmpty && _suggestions.isEmpty)
          Text(l10n.itemsHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _groupSection(MoneyFormat moneyFormat) {
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
              ChoiceChip(
                label: Text(memberDisplayName(l10n, member)),
                selected: !_multiplePayers && _paidByMemberId == member.id,
                onSelected: (_) => setState(() {
                  _multiplePayers = false;
                  _paidByMemberId = member.id;
                }),
              ),
            if (_members.length > 1)
              ChoiceChip(label: Text(l10n.payersMultiple), selected: _multiplePayers, onSelected: (_) => setState(_startMultiplePayers)),
          ],
        ),
        if (_multiplePayers) ...[
          const SizedBox(height: 8),
          PayersEditor(
            totalMinor: _amountMinor,
            members: _members,
            amounts: _payerAmounts,
            moneyFormat: moneyFormat,
            onChanged: (amounts) => setState(() => _payerAmounts = amounts),
          ),
        ],
        SectionHeader(l10n.split),
        SplitEditor(
          totalMinor: _amountMinor,
          members: _members,
          method: _splitMethod,
          inputs: _splitInputs,
          moneyFormat: moneyFormat,
          items: _itemInputs,
          payerId: _remainderPayerId,
          onMethodChanged: _changeSplitMethod,
          onInputsChanged: (inputs) => setState(() => _splitInputs = inputs),
        ),
      ],
    );
  }

  /// Switches to several payers, starting with the current payer covering
  /// the whole bill so the assigned line begins balanced.
  void _startMultiplePayers() {
    _multiplePayers = true;
    if (_payerAmounts.isEmpty && _paidByMemberId != null) _payerAmounts = {_paidByMemberId!: _amountMinor};
  }

  String _accountProblemMessage(AppLocalizations l10n, EntryAccountProblem problem) => switch (problem) {
        EntryAccountProblem.missingAccount => l10n.errorPickAccount,
        EntryAccountProblem.missingBothAccounts => l10n.errorPickBothAccounts,
        EntryAccountProblem.sameAccount => l10n.errorSameAccount,
        EntryAccountProblem.none => '',
      };

  Future<void> _save({bool addAnother = false}) async {
    final amount = _amountMinor;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!_hasItems && amountErrorText(context, _amountController.text, format: _moneyFormat) != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.invalidAmount)));
      return;
    }
    if (amount <= 0) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorAmountZero)));
      return;
    }
    final accountProblem = entryAccountProblem(
      kind: _kind,
      inGroup: _groupId != null,
      accountId: _accountId,
      toAccountId: _toAccountId,
      accountCreatedOnSave: _source == 'sms' && _smsId != null,
    );
    if (accountProblem != EntryAccountProblem.none) {
      messenger.showSnackBar(SnackBar(content: Text(_accountProblemMessage(l10n, accountProblem))));
      return;
    }
    if (_items.any((i) => i.name.trim().isEmpty)) {
      setState(() => _showItemErrors = true);
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorItemName)));
      return;
    }
    SplitOutcome? outcome;
    if (_groupId != null) {
      if (_multiplePayers) {
        final payers = payersFrom(_payerAmounts);
        if (payers.isEmpty || unassignedMinor(amount, payers) != 0) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.payersMustTotal(formatMinor(amount, format: _moneyFormat)))));
          return;
        }
        _paidByMemberId = primaryPayerId(payers);
      }
      if (_paidByMemberId == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorChoosePayer)));
        return;
      }
      outcome = computeSplit(totalMinor: amount, method: _splitMethod, inputs: _splitInputs, items: _itemInputs, payerId: _paidByMemberId);
      if (!outcome.isValid) {
        messenger.showSnackBar(SnackBar(content: Text(outcome.error == null ? l10n.errorFixSplit : splitErrorMessage(outcome.error!, l10n, _moneyFormat))));
        return;
      }
    }
    messenger.hideCurrentSnackBar();
    setState(() => _saving = true);
    if (_source == 'sms' && _smsId != null && _accountId == null && _groupId == null) {
      _accountId = (await ref.read(smsIngestServiceProvider).ensureAccountForSms(_smsId!))?.id;
      if (_accountId == null) {
        if (mounted) setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorPickAccount)));
        return;
      }
    }
    final id = _existingId ?? newId();
    final projectId = _kind == 'transfer' ? null : _projectId;
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
      projectId: projectId,
    ).copyWith(toAccountId: Value(_kind == 'transfer' ? _toAccountId : null));
    final weights = {for (final i in _splitInputs) i.memberId: i};
    // Group expenses go through the groups repository so the change is logged.
    final save = _groupId == null ? ref.read(entriesRepositoryProvider).saveEntry : ref.read(groupsRepositoryProvider).saveGroupExpense;
    await save(
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
                  shareValue: Value(shareValueFor(_splitMethod, weights[share.memberId])),
                ),
          ],
          payers: _groupId == null
              ? null
              : [
                  if (_multiplePayers && payersFrom(_payerAmounts).length > 1)
                    for (final payer in payersFrom(_payerAmounts))
                      EntryPayersCompanion.insert(id: newId(), entryId: id, memberId: payer.memberId, amountMinor: payer.amountMinor),
                ],
          fieldValues: projectId == null ? const [] : entryFieldValueRows(id, _fieldValues),
          itemAssignments: _groupId == null
              ? null
              : {
                  if (_isByItem)
                    for (final draft in _items)
                      if (!draft.isShared) draft.id: draft.memberIds ?? const [],
                },
        );
    if (!_isEditing && _groupId == null && _kind != 'transfer') ref.read(lastProjectIdProvider.notifier).set(projectId);
    await _applyBalanceChange(amount);
    if (_canRepeat && _repeat != null) await _startRule(_repeat!, entry);
    if (_smsId != null) await ref.read(smsLogRepositoryProvider).setStatus(_smsId!, 'added', entryId: id);
    final pickedCategoryId = _category?.id;
    if (_source == 'sms' && _smsId != null && _kind != 'transfer' && pickedCategoryId != null && pickedCategoryId != _loadedCategoryId) {
      await ref.read(smsIngestServiceProvider).rememberCategoryForSms(_smsId!, pickedCategoryId);
    }
    if (widget.reminderId != null && !_isEditing) {
      await ref.read(reminderSchedulerProvider).markDone(widget.reminderId!, entryId: id);
      messenger.showSnackBar(SnackBar(content: Text(l10n.reminderMarkedPaid)));
    } else if (_smsId != null) {
      await ref.read(smsIngestServiceProvider).linkSavedEntry(_smsId!, id);
    }
    if (!mounted) return;
    if (addAnother) {
      _startNextEntry();
      messenger.showSnackBar(SnackBar(content: Text(l10n.savedAddAnother)));
    } else {
      popOrGoHome(context);
    }
  }

  /// Deletes a group expense (logged in its activity) and offers Undo on the
  /// screen underneath, since this one closes.
  Future<void> _deleteGroupExpense(String entryId) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final groups = ref.read(groupsRepositoryProvider);
    await groups.deleteGroupExpense(entryId);
    showUndoSnackBar(messenger, message: l10n.activityExpenseDeletedSnack, undoLabel: l10n.undo, onUndo: () => groups.restoreGroupExpense(entryId));
  }

  /// Turns the entry just saved into the first occurrence of a new rule.
  Future<void> _startRule(RepeatDraft draft, EntriesCompanion entry) async {
    final repository = ref.read(recurringRepositoryProvider);
    final spec = draft.specFrom(_occurredAt);
    final personalRule = RecurringRepository.newRule(
      kind: _kind,
      amountMinor: entry.amountMinor.value,
      categoryId: entry.categoryId.value,
      accountId: entry.accountId.value,
      toAccountId: entry.toAccountId.value,
      payee: entry.payee.value,
      projectId: entry.projectId.value,
      note: entry.note.value,
      frequency: spec.frequency,
      interval: spec.interval,
      dayOfMonth: spec.dayOfMonth,
      weekday: spec.weekday,
      startDate: _occurredAt,
      endDate: spec.endDate,
      maxCount: spec.maxCount,
      autoPost: draft.autoPost,
    );
    final groupId = _groupId;
    final rule = groupId == null ? personalRule : GroupRecurringRepository.asGroupRule(personalRule, groupId: groupId, template: _groupTemplate());
    final ruleId = await repository.saveRule(rule, monthStartDay: ref.read(settingsProvider).monthStartDay, postedOn: _occurredAt);
    await repository.linkEntry(entry.id.value, ruleId);
  }

  /// The split and payers of the group expense being saved, replayed by
  /// each later occurrence of its rule.
  GroupExpenseTemplate _groupTemplate() {
    final payers = _multiplePayers ? payersFrom(_payerAmounts) : const <SplitShare>[];
    return GroupExpenseTemplate(
      method: _splitMethod,
      inputs: _splitInputs,
      paidByMemberId: _paidByMemberId!,
      payers: payers.length > 1 ? payers : const [],
    );
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
    _amountFocus.dispose();
    _noteController.dispose();
    _payeeController.dispose();
    super.dispose();
  }
}
