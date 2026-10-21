import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../categories/category_picker.dart';
import '../shell/widgets/common.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider).value ?? const <Budget>[];
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final byId = {for (final c in categories) c.id: c};
    final repo = ref.read(budgetsRepositoryProvider);

    Future<void> edit({Budget? existing}) async {
      Category? category = existing?.categoryId == null ? null : byId[existing!.categoryId];
      var overall = existing != null && existing.categoryId == null;
      if (existing == null) {
        final choice = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.all_inclusive), title: const Text('Overall monthly budget'), onTap: () => Navigator.pop(sheetContext, 'overall')),
            ListTile(leading: const Icon(Icons.category_outlined), title: const Text('Budget for a category'), onTap: () => Navigator.pop(sheetContext, 'category')),
          ]),
        );
        if (choice == null) return;
        overall = choice == 'overall';
        if (!overall && context.mounted) {
          category = await showCategoryPicker(context, kind: 'expense');
          if (category == null) return;
        }
      }
      if (!context.mounted) return;
      final text = await promptText(
        context,
        title: overall ? 'Overall monthly limit' : '${category!.name} monthly limit',
        initial: existing == null ? null : minorToDouble(existing.amountMinor).toStringAsFixed(0),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      );
      final amount = text == null ? null : parseAmountToMinor(text);
      if (amount == null || amount <= 0) return;
      await repo.save(id: existing?.id, categoryId: overall ? null : category!.id, period: 'month', amountMinor: amount);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(heroTag: 'add-budget', onPressed: edit, icon: const Icon(Icons.add), label: const Text('Budget')),
      body: budgets.isEmpty
          ? const EmptyState(icon: Icons.savings_outlined, title: 'No budgets yet', message: 'Set a monthly limit overall or per category. The dashboard shows pace and what is left.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                Card(
                  child: Column(children: [
                    for (final budget in budgets)
                      ListTile(
                        leading: IconBadge(icon: budget.categoryId == null ? 'all_inclusive' : byId[budget.categoryId]?.icon, color: byId[budget.categoryId]?.color ?? 0xFF0F6E6B),
                        title: Text(budget.categoryId == null ? 'Overall' : byId[budget.categoryId]?.name ?? 'Category'),
                        subtitle: Text('per ${budget.period}'),
                        trailing: Text(formatMinor(budget.amountMinor, symbol: symbol, showDecimals: false), style: const TextStyle(fontWeight: FontWeight.w700)),
                        onTap: () => edit(existing: budget),
                        onLongPress: () async {
                          if (await confirmDialog(context, title: 'Remove this budget?', confirmLabel: 'Remove')) await repo.delete(budget.id);
                        },
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                Text('Long-press a budget to remove it.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
    );
  }
}
