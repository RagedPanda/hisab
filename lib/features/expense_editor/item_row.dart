import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../core/ids.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../l10n/l10n.dart';

/// Mutable draft of one line item while editing.
class ItemDraft {
  ItemDraft({String? id, this.name = '', this.quantity = 1, this.unit, this.unitPriceMinor = 0}) : id = id ?? newId();

  final String id;
  final String name;
  final double quantity;
  final String? unit;
  final int unitPriceMinor;

  int get amountMinor => (unitPriceMinor * quantity).round();

  ItemDraft copyWith({String? name, double? quantity, String? unit, bool clearUnit = false, int? unitPriceMinor}) => ItemDraft(
        id: id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: clearUnit ? null : (unit ?? this.unit),
        unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
      );

  static ItemDraft fromRow(EntryItem row) =>
      ItemDraft(id: row.id, name: row.name, quantity: row.quantity, unit: row.unit, unitPriceMinor: row.unitPriceMinor);

  EntryItemsCompanion toCompanion(String entryId) => EntryItemsCompanion.insert(
        id: id,
        entryId: entryId,
        name: name.trim(),
        quantity: Value(quantity),
        unit: Value(unit),
        unitPriceMinor: unitPriceMinor,
        amountMinor: amountMinor,
      );
}

class ItemRow extends StatefulWidget {
  const ItemRow({super.key, required this.draft, required this.units, required this.symbol, required this.onChanged, required this.onRemove});
  final ItemDraft draft;
  final List<String> units;
  final String symbol;
  final ValueChanged<ItemDraft> onChanged;
  final VoidCallback onRemove;

  @override
  State<ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<ItemRow> {
  late final _name = TextEditingController(text: widget.draft.name);
  late final _qty = TextEditingController(text: _trim(widget.draft.quantity));
  late final _price = TextEditingController(text: widget.draft.unitPriceMinor == 0 ? '' : minorToDouble(widget.draft.unitPriceMinor).toStringAsFixed(2));

  static String _trim(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final l10n = context.l10n;
    final unitOptions = {...widget.units, 'pcs', 'kg', 'g', 'L', 'ml', 'dozen', 'pack', if (draft.unit != null) draft.unit!}.toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  decoration: InputDecoration(hintText: l10n.itemName, isDense: true, filled: false, border: InputBorder.none),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (v) => widget.onChanged(draft.copyWith(name: v)),
                ),
              ),
              Text(formatMinor(draft.amountMinor, symbol: widget.symbol), style: Theme.of(context).textTheme.labelLarge),
              IconButton(tooltip: l10n.remove, icon: const Icon(Icons.close, size: 18), onPressed: widget.onRemove),
            ]),
            Row(children: [
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.qty, isDense: true),
                  onChanged: (v) => widget.onChanged(draft.copyWith(quantity: double.tryParse(v) ?? 0)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                child: DropdownButtonFormField<String>(
                  initialValue: draft.unit ?? '',
                  isDense: true,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.unit, isDense: true),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('—')),
                    for (final unit in unitOptions) DropdownMenuItem(value: unit, child: Text(unit, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => widget.onChanged((v ?? '').isEmpty ? draft.copyWith(clearUnit: true) : draft.copyWith(unit: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.pricePerUnit(draft.unit ?? l10n.genericUnit), prefixText: '${widget.symbol} ', isDense: true),
                  onChanged: (v) => widget.onChanged(draft.copyWith(unitPriceMinor: parseAmountToMinor(v) ?? 0)),
                ),
              ),
              const SizedBox(width: 8),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }
}
