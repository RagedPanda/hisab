import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../categories/category_picker.dart';
import '../shell/widgets/budget_row.dart';
import '../shell/widgets/common.dart';
import 'budget_views.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider).value ?? const <Budget>[];
    final views = ref.watch(budgetViewsProvider);
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

    Future<void> remove(Budget budget) async {
      await repo.delete(budget.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.budgetRemoved),
        action: SnackBarAction(label: l10n.undo, onPressed: () => repo.restore(budget.id)),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgets)),
      floatingActionButton: FloatingActionButton.extended(heroTag: 'add-budget', onPressed: edit, icon: const Icon(Icons.add), label: Text(l10n.budget)),
      body: budgets.isEmpty
          ? EmptyState(
              icon: Icons.savings_outlined,
              title: l10n.noBudgetsTitle,
              message: l10n.noBudgetsBody,
              action: FilledButton.tonal(onPressed: edit, child: Text(l10n.setBudget)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final view in views)
                      Dismissible(
                        key: ValueKey(view.budget.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                        onDismissed: (_) => remove(view.budget),
                        child: BudgetRow(
                          view: view,
                          symbol: symbol,
                          onTap: () => edit(existing: view.budget),
                          trailing: PopupMenuButton<String>(
                            tooltip: l10n.edit,
                            onSelected: (value) => value == 'edit' ? edit(existing: view.budget) : remove(view.budget),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                              PopupMenuItem(value: 'remove', child: Text(l10n.remove)),
                            ],
                          ),
                        ),
                      ),
                  ]),
                ),
              ],
            ),
    );
  }
}
