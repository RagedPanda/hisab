import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/categories_repository.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'category_form.dart';
import 'subcategory_preview.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _kind = 'expense';

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final tree = buildCategoryTree(categories, kind: _kind);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        actions: [
          TextButton.icon(
            key: const ValueKey('categories.addPack'),
            onPressed: () => context.push('/categories/packs'),
            icon: const Icon(Icons.library_add_outlined),
            label: Text(l10n.addAPack),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-category',
        onPressed: () => showCategoryForm(context, ref, kind: _kind),
        icon: const Icon(Icons.add),
        label: Text(l10n.category),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'expense', label: segmentLabel(l10n.kindExpense)),
                ButtonSegment(value: 'income', label: segmentLabel(l10n.kindIncome)),
                ButtonSegment(value: 'transfer', label: segmentLabel(l10n.kindTransfer)),
              ],
              selected: {_kind},
              onSelectionChanged: (set) => setState(() => _kind = set.first),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final node in tree)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      shape: const Border(),
                      leading: IconBadge(icon: node.category.icon, color: node.category.color),
                      title: Text(node.category.displayName(context), style: TextStyle(fontWeight: FontWeight.w600, decoration: node.category.isArchived ? TextDecoration.lineThrough : null)),
                      subtitle: node.children.isEmpty ? null : Text(subcategoryPreview(context, node), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: _menu(context, node.category),
                      children: [
                        for (final child in node.children)
                          ListTile(
                            dense: true,
                            leading: IconBadge(icon: child.icon, color: child.color, size: 32),
                            title: Text(child.displayName(context), style: TextStyle(decoration: child.isArchived ? TextDecoration.lineThrough : null)),
                            subtitle: child.units.isEmpty ? null : Text(l10n.unitsLabel(child.units.replaceAll(',', ', '))),
                            trailing: _menu(context, child),
                          ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.add, size: 20),
                          title: Text(l10n.addSubcategory),
                          onTap: () => showCategoryForm(context, ref, kind: _kind, parent: node.category),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, Category category) {
    final repo = ref.read(categoriesRepositoryProvider);
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await showCategoryForm(context, ref, kind: category.kind, existing: category);
          case 'archive':
            await repo.setArchived(category.id, !category.isArchived);
          case 'delete':
            if (await confirmDialog(context, title: l10n.deleteNamed(category.displayName(context)), message: l10n.deleteCategoryBody)) {
              await repo.delete(category.id);
            }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
        PopupMenuItem(value: 'archive', child: Text(category.isArchived ? l10n.unarchive : l10n.archiveCategory)),
        if (category.seedKey == null) PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
      ],
    );
  }
}
