import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../domain/entries/calculator.dart';
import '../../l10n/l10n.dart';

/// Calculator keypad for the amount field. Opens with [initialAmountText]
/// (the field's current amount) and returns the result in minor units on
/// "Use", or null when dismissed.
Future<int?> showCalculatorSheet(BuildContext context, {required String initialAmountText, required String symbol}) =>
    showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _CalculatorSheet(initialExpression: calcSeed(initialAmountText), symbol: symbol),
    );

/// Message for an expression that has no amount, or null when nothing needs
/// saying (an empty or half-typed expression).
String? calcErrorText(AppLocalizations l10n, CalcError? error) => switch (error) {
      CalcError.divideByZero => l10n.calcDivideByZero,
      CalcError.negative => l10n.calcNegative,
      CalcError.tooLarge => l10n.calcTooLarge,
      CalcError.empty || CalcError.malformed || null => null,
    };

class _CalculatorSheet extends StatefulWidget {
  const _CalculatorSheet({required this.initialExpression, required this.symbol});
  final String initialExpression;
  final String symbol;

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  late String _expression = widget.initialExpression;

  void _edit(String Function(String expression) change) => setState(() => _expression = change(_expression));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final preview = previewExpression(_expression);
    final result = evaluateExpression(_expression);
    final usable = preview.isValue && preview.minor! > 0;
    final error = calcErrorText(l10n, preview.error ?? result.error);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.calculator, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            _expression.isEmpty ? '0' : _expression,
            key: const ValueKey('calc.display'),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            error ?? (preview.isValue ? '= ${formatMinor(preview.minor!, symbol: widget.symbol)}' : ' '),
            key: const ValueKey('calc.result'),
            textAlign: TextAlign.end,
            style: theme.textTheme.titleMedium?.copyWith(color: error == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error),
          ),
          const SizedBox(height: 12),
          for (final row in _keyRows) ...[
            Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _KeyButton(spec: key, onPressed: () => _edit(key.apply), onLongPress: key.id == 'back' ? () => _edit((_) => '') : null),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(key: const ValueKey('calc.clear'), onPressed: _expression.isEmpty ? null : () => _edit((_) => ''), child: Text(l10n.clear)),
              const Spacer(),
              FilledButton(
                key: const ValueKey('calc.use'),
                onPressed: usable ? () => Navigator.of(context).pop(preview.minor) : null,
                child: Text(l10n.useAmount(formatMinor(usable ? preview.minor! : 0, symbol: widget.symbol))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One keypad key: its id (used in the widget key), what it shows and how
/// it changes the expression.
class _KeySpec {
  const _KeySpec(this.id, this.label, this.apply, {this.icon, this.isOperator = false});
  final String id;
  final String label;
  final String Function(String expression) apply;
  final IconData? icon;
  final bool isOperator;
}

_KeySpec _digit(String digit) => _KeySpec(digit, digit, (expression) => appendDigit(expression, digit));

_KeySpec _operator(String id, String symbol) => _KeySpec(id, symbol, (expression) => appendOperator(expression, symbol), isOperator: true);

final List<List<_KeySpec>> _keyRows = [
  [_digit('7'), _digit('8'), _digit('9'), _operator('divide', calcDivide)],
  [_digit('4'), _digit('5'), _digit('6'), _operator('times', calcTimes)],
  [_digit('1'), _digit('2'), _digit('3'), _operator('minus', calcMinus)],
  [const _KeySpec('dot', '.', appendDot), _digit('0'), const _KeySpec('back', '', backspace, icon: Icons.backspace_outlined), _operator('plus', calcPlus)],
];

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.spec, required this.onPressed, this.onLongPress});
  final _KeySpec spec;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      padding: EdgeInsets.zero,
      textStyle: Theme.of(context).textTheme.titleLarge,
    );
    final child = spec.icon != null ? Icon(spec.icon) : Text(spec.label);
    final key = ValueKey('calc.key.${spec.id}');
    return spec.isOperator
        ? FilledButton(key: key, style: style, onPressed: onPressed, onLongPress: onLongPress, child: child)
        : FilledButton.tonal(key: key, style: style, onPressed: onPressed, onLongPress: onLongPress, child: child);
  }
}
