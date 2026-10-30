import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/accounts/default_account.dart';
import '../../domain/udhaar/udhaar.dart';
import '../../l10n/l10n.dart';
import '../accounts/account_picker_tile.dart';
import '../shell/widgets/common.dart';
import 'udhaar_labels.dart';
import 'udhaar_providers.dart';
import 'udhaar_screen.dart' show addPersonFromDialog;

/// Adds or edits one udhaar entry: lent, borrowed, got back or paid back,
/// with whom, how much, on which account and when.
class UdhaarFormScreen extends ConsumerStatefulWidget {
  const UdhaarFormScreen({super.key, this.entryId, this.personId, this.kind, this.amountMinor, this.accountId});

  /// The entry to edit; null for a new one.
  final String? entryId;
  final String? personId;
  final UdhaarKind? kind;
  final int? amountMinor;
  final String? accountId;

  @override
  ConsumerState<UdhaarFormScreen> createState() => _UdhaarFormScreenState();
}

class _UdhaarFormScreenState extends ConsumerState<UdhaarFormScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late UdhaarKind _kind = widget.kind ?? UdhaarKind.lent;
  late String? _personId = widget.personId;
  String? _accountId;
  DateTime _occurredAt = DateTime.now();
  bool _loaded = false;

  bool get _isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final moneyFormat = ref.read(homeMoneyFormatProvider);
    final entryId = widget.entryId;
    if (entryId != null) {
      final entry = await ref.read(udhaarRepositoryProvider).getEntry(entryId);
      if (entry != null) {
        _kind = UdhaarKind.parse(entry.udhaarKind) ?? _kind;
        _personId = entry.personId;
        _accountId = udhaarAccountOf(from: entry.accountId, to: entry.toAccountId);
        _occurredAt = entry.occurredAt;
        _amount.text = amountInputText(entry.amountMinor, format: moneyFormat);
        _note.text = entry.note;
      }
    } else {
      if (widget.amountMinor case final amount?) _amount.text = amountInputText(amount, format: moneyFormat);
      final accounts = await ref.read(accountsRepositoryProvider).getAll();
      _accountId = accounts.any((account) => account.id == widget.accountId)
          ? widget.accountId
          : defaultEntryAccountId(accounts, configuredId: ref.read(settingsProvider).defaultAccountId);
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _amountMinor {
    final amount = parseAmountToMinor(_amount.text, format: ref.read(homeMoneyFormatProvider));
    return amount == null || amount <= 0 ? null : amount;
  }

  Person? _person(List<Person> people) => people.where((person) => person.id == _personId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final people = ref.watch(peopleProvider).value ?? const <Person>[];
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final person = _person(people);
    final canSave = _loaded && person != null && _amountMinor != null && _accountId != null;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.udhaarEdit : l10n.udhaarAdd),
        actions: [
          if (_isEditing) IconButton(key: const Key('udhaar.delete'), tooltip: l10n.delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final kind in UdhaarKind.values)
                    ChoiceChip(
                      key: ValueKey('udhaar.kind.${kind.storageKey}'),
                      label: Text(udhaarKindLabel(l10n, kind)),
                      selected: _kind == kind,
                      onSelected: (_) => setState(() => _kind = kind),
                    ),
                ]),
                const SizedBox(height: 8),
                ListTile(
                  key: const Key('udhaar.person'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(person?.name ?? l10n.udhaarPickPerson),
                  subtitle: Text(l10n.udhaarPerson),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickPerson(people),
                ),
                TextField(
                  key: const Key('udhaar.amount'),
                  controller: _amount,
                  autofocus: !_isEditing && widget.amountMinor == null,
                  keyboardType: amountKeyboardType(moneyFormat),
                  inputFormatters: amountInputFormatters(moneyFormat),
                  style: Theme.of(context).textTheme.headlineSmall?.tabular,
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: amountPrefixText(moneyFormat),
                    suffixText: amountSuffixText(moneyFormat),
                    errorText: amountErrorText(context, _amount.text, format: moneyFormat),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                AccountPickerTile(
                  key: const Key('udhaar.account'),
                  label: _kind.isMoneyOut ? l10n.udhaarPaidFrom : l10n.udhaarReceivedIn,
                  accounts: accounts,
                  selectedId: _accountId,
                  onPick: (id) => setState(() => _accountId = id),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(formatShortDate(_occurredAt, locale: locale)),
                  onTap: _pickDate,
                ),
                TextField(
                  key: const Key('udhaar.note'),
                  controller: _note,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.note),
                ),
              ],
            ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(key: const Key('udhaar.save'), onPressed: canSave ? () => _save(person) : null, child: Text(l10n.save)),
      ),
    );
  }

  Future<void> _pickPerson(List<Person> people) async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          for (final person in people)
            ListTile(
              key: ValueKey('udhaar.pick.${person.id}'),
              leading: const Icon(Icons.person_outline),
              title: Text(person.name),
              selected: person.id == _personId,
              onTap: () => Navigator.pop(context, person.id),
            ),
          ListTile(
            key: const Key('udhaar.pickNewPerson'),
            leading: const Icon(Icons.person_add_alt_1_outlined),
            title: Text(l10n.udhaarAddPerson),
            onTap: () => Navigator.pop(context, ''),
          ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final id = picked.isEmpty ? await addPersonFromDialog(context, ref) : picked;
    if (id != null && mounted) setState(() => _personId = id);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _occurredAt, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked == null || !mounted) return;
    setState(() => _occurredAt = DateTime(picked.year, picked.month, picked.day, _occurredAt.hour, _occurredAt.minute));
  }

  Future<void> _save(Person person) async {
    final amount = _amountMinor;
    if (amount == null) return;
    await ref.read(udhaarRepositoryProvider).save(
          (
            personId: person.id,
            personName: person.name,
            kind: _kind,
            amountMinor: amount,
            occurredAt: _occurredAt,
            accountId: _accountId,
            note: _note.text,
          ),
          id: widget.entryId,
        );
    if (mounted) popOrGoHome(context);
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final repository = ref.read(udhaarRepositoryProvider);
    final id = widget.entryId!;
    await repository.delete(id);
    showUndoSnackBar(messenger, message: l10n.udhaarDeleted, undoLabel: l10n.undo, onUndo: () => repository.restore(id));
    if (mounted) popOrGoHome(context);
  }
}
