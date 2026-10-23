import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/currency/currency_lookup.dart';
import '../../l10n/l10n.dart';
import 'currency_picker.dart';

/// Shown once on a fresh install, before Home. The device region's currency
/// (or INR) is preselected, so a single tap on Continue confirms it.
class FirstLaunchCurrencyScreen extends ConsumerStatefulWidget {
  const FirstLaunchCurrencyScreen({super.key, required this.deviceRegion});

  /// The device locale's country code, e.g. "IN" or "GB"; null if unknown.
  final String? deviceRegion;

  @override
  ConsumerState<FirstLaunchCurrencyScreen> createState() => _FirstLaunchCurrencyScreenState();
}

class _FirstLaunchCurrencyScreenState extends ConsumerState<FirstLaunchCurrencyScreen> {
  late String _selectedCode = currencyCodeForRegion(widget.deviceRegion);
  bool _saving = false;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    await ref.read(settingsProvider.notifier).update((settings) => settings.copyWith(currencyCode: _selectedCode, currencyConfirmed: true));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Text(l10n.currencyChooseTitle, style: textTheme.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.currencyChooseBody, style: textTheme.bodyMedium),
          ),
          Expanded(
            child: CurrencyPickerList(selectedCode: _selectedCode, onTap: (currency) => setState(() => _selectedCode = currency.code)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              key: const ValueKey('currency-continue'),
              onPressed: _saving ? null : _confirm,
              child: Text(l10n.currencyContinue(currencyShortLabel(_selectedCode)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Holds the first-launch screen in its own navigator so text fields and
/// overlays work while the app's router waits behind it.
class FirstLaunchCurrencyGate extends StatelessWidget {
  const FirstLaunchCurrencyGate({super.key, required this.deviceRegion});

  final String? deviceRegion;

  @override
  Widget build(BuildContext context) => Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => FirstLaunchCurrencyScreen(deviceRegion: deviceRegion)),
      );
}
