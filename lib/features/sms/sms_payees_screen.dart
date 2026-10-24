import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// Settings > Bank SMS > Remembered payees: every payee whose category the
/// user chose, with a way to forget it.
class SmsPayeesScreen extends ConsumerWidget {
  const SmsPayeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final payees = ref.watch(payeeCategoriesProvider).value ?? const <PayeeCategory>[];
    final categories = {for (final category in ref.watch(allCategoriesProvider).value ?? const <Category>[]) category.id: category};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.smsPayeesTitle)),
      body: payees.isEmpty
          ? EmptyState(icon: Icons.person_search_outlined, title: l10n.smsPayeesEmptyTitle, message: l10n.smsPayeesEmptyBody)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l10n.smsPayeesHelp, style: Theme.of(context).textTheme.bodyMedium),
                ),
                Card(
                  child: Column(children: [
                    for (final payee in payees) _PayeeTile(payee: payee, category: categories[payee.categoryId]),
                  ]),
                ),
              ],
            ),
    );
  }
}

class _PayeeTile extends ConsumerWidget {
  const _PayeeTile({required this.payee, required this.category});
  final PayeeCategory payee;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final category = this.category;
    return ListTile(
      leading: category == null ? const Icon(Icons.label_off_outlined) : IconBadge(icon: category.icon, color: category.color),
      title: Text(payee.payee, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(category?.displayName(context) ?? l10n.category, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.smsPayeeForget(payee.payee),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          await ref.read(payeeCategoryRepositoryProvider).forget(payee.id);
          showTimedSnackBar(messenger, l10n.smsPayeeForgotten(payee.payee));
        },
      ),
    );
  }
}
