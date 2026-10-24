import 'package:flutter/material.dart';

import '../../domain/currency/currency.dart';
import '../../domain/currency/currency_lookup.dart';
import '../../l10n/l10n.dart';

/// Search box plus the list of world currencies. [onTap] gets the tapped row;
/// the selected row is listed first and checked.
class CurrencyPickerList extends StatefulWidget {
  const CurrencyPickerList({super.key, required this.selectedCode, required this.onTap});

  final String selectedCode;
  final ValueChanged<Currency> onTap;

  @override
  State<CurrencyPickerList> createState() => _CurrencyPickerListState();
}

class _CurrencyPickerListState extends State<CurrencyPickerList> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches = _query.trim().isEmpty ? selectedFirst(searchCurrencies(''), widget.selectedCode) : searchCurrencies(_query);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          key: const ValueKey('currency-search'),
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.currencySearchHint,
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: () => setState(() {
                      _search.clear();
                      _query = '';
                    }),
                  ),
          ),
          onChanged: (text) => setState(() => _query = text),
        ),
      ),
      Expanded(
        child: matches.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.currencyNoMatch(_query.trim()), textAlign: TextAlign.center),
                ),
              )
            : ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) => CurrencyTile(
                  currency: matches[index],
                  selected: matches[index].code == widget.selectedCode,
                  onTap: () => widget.onTap(matches[index]),
                ),
              ),
      ),
    ]);
  }
}

class CurrencyTile extends StatelessWidget {
  const CurrencyTile({super.key, required this.currency, required this.selected, required this.onTap});

  final Currency currency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final countries = countryNamesFor(currency);
    return ListTile(
      key: ValueKey('currency-${currency.code}'),
      selected: selected,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        foregroundColor: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FittedBox(child: Text(currency.symbol, maxLines: 1)),
        ),
      ),
      title: Text(currency.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [currency.code, if (countries.isNotEmpty) countries.join(', ')].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: selected ? Icon(Icons.check, color: scheme.primary) : null,
    );
  }
}

/// Full-screen picker for Settings. One tap on a row returns its code.
Future<String?> showCurrencyPicker(BuildContext context, {required String selectedCode}) => Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(context.l10n.currency)),
          body: SafeArea(
            top: false,
            child: CurrencyPickerList(selectedCode: selectedCode, onTap: (currency) => Navigator.of(context).pop(currency.code)),
          ),
        ),
      ),
    );
