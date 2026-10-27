import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/split/debt_simplifier.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'member_display.dart';

/// Stored values of `Settlements.method`, in the order the chips show them.
const paymentMethods = ['cash', 'upi', 'bank', 'other'];

String paymentMethodLabel(String method, AppLocalizations l10n) => switch (method) {
      'upi' => l10n.methodUpi,
      'bank' => l10n.methodBank,
      'other' => l10n.methodOther,
      _ => l10n.methodCash,
    };

IconData paymentMethodIcon(String method) => switch (method) {
      'upi' => Icons.qr_code_2,
      'bank' => Icons.account_balance_outlined,
      'other' => Icons.more_horiz,
      _ => Icons.payments_outlined,
    };

/// How much [from] is expected to pay [to] before this payment: the larger of
/// the direct (pairwise) debt and the settle-up suggestion, so a payment
/// prefilled from a simplified suggestion is never flagged as an overpayment.
int owedBetween(GroupBalances balances, String from, String to) {
  int sumFor(List<Transfer> transfers) => transfers
      .where((transfer) => transfer.from == from && transfer.to == to)
      .fold(0, (sum, transfer) => sum + transfer.amountMinor);
  final direct = sumFor(balances.pairwise);
  final suggested = sumFor(balances.suggested);
  return direct > suggested ? direct : suggested;
}

/// Bottom sheet to record (or edit, when [existing] is given) a payment
/// between two members: direction, amount, date, method and note.
Future<void> showRecordPaymentSheet(
  BuildContext context,
  WidgetRef ref, {
  required Group group,
  required List<Member> members,
  required GroupBalances balances,
  required MoneyFormat moneyFormat,
  String? fromMemberId,
  String? toMemberId,
  int? amountMinor,
  Settlement? existing,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _RecordPaymentSheet(
      ref: ref,
      group: group,
      members: members,
      balances: balances,
      moneyFormat: moneyFormat,
      initialFrom: existing?.fromMemberId ?? fromMemberId,
      initialTo: existing?.toMemberId ?? toMemberId,
      initialAmountMinor: existing?.amountMinor ?? amountMinor,
      existing: existing,
      hostContext: context,
    ),
  );
}

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({
    required this.ref,
    required this.group,
    required this.members,
    required this.balances,
    required this.moneyFormat,
    required this.initialFrom,
    required this.initialTo,
    required this.initialAmountMinor,
    required this.existing,
    required this.hostContext,
  });

  final WidgetRef ref;
  final Group group;
  final List<Member> members;
  final GroupBalances balances;
  final MoneyFormat moneyFormat;
  final String? initialFrom;
  final String? initialTo;
  final int? initialAmountMinor;
  final Settlement? existing;

  /// The screen underneath, used for the snackbar after the sheet closes.
  final BuildContext hostContext;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _from;
  late String _to;
  late DateTime _occurredAt;
  late String _method;

  @override
  void initState() {
    super.initState();
    final members = widget.members;
    final me = members.where((member) => member.isMe).firstOrNull ?? members.first;
    final other = members.where((member) => member.id != me.id).firstOrNull ?? me;
    _from = widget.initialFrom ?? me.id;
    _to = widget.initialTo ?? (other.id == _from ? me.id : other.id);
    _amount = TextEditingController(text: widget.initialAmountMinor == null ? '' : amountInputText(widget.initialAmountMinor!, format: widget.moneyFormat));
    _amount.selection = TextSelection(baseOffset: 0, extentOffset: _amount.text.length);
    _note = TextEditingController(text: widget.existing?.note ?? '');
    _occurredAt = widget.existing?.occurredAt ?? DateTime.now();
    _method = widget.existing?.method ?? paymentMethods.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _amountMinor => parseAmountToMinor(_amount.text, format: widget.moneyFormat);

  /// Owed before this payment; when editing, the edited row is excluded.
  int get _owedMinor {
    final base = owedBetween(widget.balances, _from, _to);
    final existing = widget.existing;
    if (existing == null) return base;
    if (existing.fromMemberId == _from && existing.toMemberId == _to) return base + existing.amountMinor;
    if (existing.fromMemberId == _to && existing.toMemberId == _from) return (base - existing.amountMinor).clamp(0, 1 << 62);
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = _amountMinor;
    final samePerson = _from == _to;
    final valid = !samePerson && amount != null && amount > 0;
    final owed = _owedMinor;
    final String? hint = samePerson
        ? l10n.samePersonError
        : (amount != null && amount > owed)
            ? (owed == 0 ? l10n.paymentNoDebt(_name(_from), _name(_to)) : l10n.paymentOverOwed(formatMinor(owed, format: widget.moneyFormat)))
            : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? l10n.recordPayment : l10n.editPayment, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _memberField(l10n.paymentFrom, _from, (id) => setState(() => _from = id))),
                IconButton(
                  tooltip: l10n.swapDirection,
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () => setState(() {
                    final from = _from;
                    _from = _to;
                    _to = from;
                  }),
                ),
                Expanded(child: _memberField(l10n.paymentTo, _to, (id) => setState(() => _to = id))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: amountInputFormatters,
              decoration: InputDecoration(
                labelText: l10n.amountLabel,
                prefixText: amountPrefixText(widget.moneyFormat),
                suffixText: amountSuffixText(widget.moneyFormat),
                errorText: amountErrorText(context, _amount.text, format: widget.moneyFormat),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: samePerson ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_outlined),
                    label: Text(formatShortDate(_occurredAt, locale: locale)),
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _occurredAt, firstDate: DateTime(2000), lastDate: DateTime.now());
                      if (picked != null) setState(() => _occurredAt = DateTime(picked.year, picked.month, picked.day, _occurredAt.hour, _occurredAt.minute));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.paymentMethod, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final method in paymentMethods)
                  ChoiceChip(
                    avatar: Icon(paymentMethodIcon(method), size: 18),
                    label: Text(paymentMethodLabel(method, l10n)),
                    selected: _method == method,
                    onSelected: (_) => setState(() => _method = method),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _note, decoration: InputDecoration(labelText: l10n.note), textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: valid ? () => _save(amount) : null,
              child: Text(l10n.savePayment),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberField(String label, String value, ValueChanged<String> onChanged) {
    final l10n = context.l10n;
    final ids = widget.members.map((member) => member.id).toSet();
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: ids.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final member in widget.members) DropdownMenuItem(value: member.id, child: Text(memberShortName(l10n, member), overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (id) => id == null ? null : onChanged(id),
    );
  }

  String _name(String id) {
    final member = widget.members.where((member) => member.id == id).firstOrNull;
    return member == null ? context.l10n.unknown : memberShortName(context.l10n, member);
  }

  Future<void> _save(int amount) async {
    final l10n = context.l10n;
    final repo = widget.ref.read(groupsRepositoryProvider);
    final transferLine = l10n.transferArrow(_name(_from), _name(_to));
    final note = _note.text.trim();
    final existing = widget.existing;
    Navigator.pop(context);
    final host = widget.hostContext;
    if (existing != null) {
      await repo.updateSettlement(id: existing.id, fromMemberId: _from, toMemberId: _to, amountMinor: amount, occurredAt: _occurredAt, note: note, method: _method);
      if (!host.mounted) return;
      ScaffoldMessenger.of(host).showSnackBar(SnackBar(content: Text(l10n.paymentUpdated)));
      return;
    }
    final id = await repo.addSettlement(groupId: widget.group.id, fromMemberId: _from, toMemberId: _to, amountMinor: amount, occurredAt: _occurredAt, note: note, method: _method);
    if (!host.mounted) return;
    showUndoSnackBar(
      ScaffoldMessenger.of(host),
      message: l10n.paymentRecorded(transferLine, formatMinor(amount, format: widget.moneyFormat)),
      undoLabel: l10n.undo,
      onUndo: () => repo.deleteSettlement(id),
    );
  }
}
