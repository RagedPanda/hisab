import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
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
    final l10n = context.l10n;

    Future<void> edit({Budget? existing}) async {
      Category? category = existing?.categoryId == null ? null : byId[existing!.categoryId];
      var overall = existing != null && existing.categoryId == null;
      if (existing == null) {
        final choice = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.all_inclusive), title: Text(l10n.overallMonthlyBudget), onTap: () => Navigator.pop(sheetContext, 'overall')),
            ListTile(leading: const Icon(Icons.category_outlined), title: Text(l10n.budgetForCategory), onTap: () => Navigator.pop(sheetContext, 'category')),
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
      final amount = await promptAmount(
        context,
        title: overall ? l10n.overallMonthlyLimit : l10n.categoryMonthlyLimit(category!.displayName(context)),
        initialMinor: existing?.amountMinor,
      );
      if (amount == null || amount <= 0) return;
      await repo.save(id: existing?.id, categoryId: overall ? null : category!.id, period: 'month', amountMinor: amount);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgets)),
      floatingActionButton: FloatingActionButton.extended(heroTag: 'add-budget', onPressed: edit, icon: const Icon(Icons.add), label: Text(l10n.budget)),
      body: budgets.isEmpty
          ? EmptyState(icon: Icons.savings_outlined, title: l10n.noBudgetsTitle, message: l10n.noBudgetsBody)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                Card(
                  child: Column(children: [
                    for (final budget in budgets)
                      ListTile(
                        leading: IconBadge(icon: budget.categoryId == null ? 'all_inclusive' : byId[budget.categoryId]?.icon, color: byId[budget.categoryId]?.color ?? 0xFF0F6E6B),
                        title: Text(budget.categoryId == null ? l10n.overall : byId[budget.categoryId]?.displayName(context) ?? l10n.category),
                        subtitle: Text(l10n.perPeriod(budget.period)),
                        trailing: Text(formatMinor(budget.amountMinor, symbol: symbol, showDecimals: false), style: const TextStyle(fontWeight: FontWeight.w700)),
                        onTap: () => edit(existing: budget),
                        onLongPress: () async {
                          if (await confirmDialog(context, title: l10n.removeBudgetQuestion, confirmLabel: l10n.remove)) await repo.delete(budget.id);
                        },
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(l10n.longPressToRemoveBudget, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
    );
  }
}
