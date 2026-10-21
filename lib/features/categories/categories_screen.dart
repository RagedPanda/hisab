import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/categories_repository.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

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
      appBar: AppBar(title: Text(l10n.categories)),
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
                ButtonSegment(value: 'expense', label: Text(l10n.kindExpense)),
                ButtonSegment(value: 'income', label: Text(l10n.kindIncome)),
                ButtonSegment(value: 'transfer', label: Text(l10n.kindTransfer)),
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
                      subtitle: Text(l10n.subcategoryCount(node.children.length)),
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

Future<void> showCategoryForm(BuildContext context, WidgetRef ref, {required String kind, Category? parent, Category? existing}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final unitsController = TextEditingController(text: existing?.units ?? '');
  var icon = existing?.icon ?? parent?.icon ?? 'category';
  var color = existing?.color ?? parent?.color ?? kPaletteColors.first;
  final l10n = context.l10n;
  final parentName = parent?.displayName(context);
  final existingName = existing?.displayName(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(existingName == null ? (parentName == null ? l10n.newCategory : l10n.newSubcategoryOf(parentName)) : l10n.editNamed(existingName), style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: nameController, autofocus: true, decoration: InputDecoration(labelText: l10n.name), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: unitsController, decoration: InputDecoration(labelText: l10n.unitsForItems, hintText: l10n.unitsHint)),
            const SizedBox(height: 12),
            Text(l10n.colour, style: Theme.of(sheetContext).textTheme.labelLarge),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in kPaletteColors)
                  GestureDetector(
                    onTap: () => setSheetState(() => color = option),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(option),
                      child: color == option ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.icon, style: Theme.of(sheetContext).textTheme.labelLarge),
            SizedBox(
              height: 160,
              child: GridView.count(
                crossAxisCount: 8,
                children: [
                  for (final name in pickableIconNames)
                    IconButton(
                      isSelected: icon == name,
                      onPressed: () => setSheetState(() => icon = name),
                      icon: Icon(appIcons[name], color: icon == name ? Color(color) : null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final units = unitsController.text.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty).join(',');
                final repo = ref.read(categoriesRepositoryProvider);
                if (existing == null) {
                  await repo.create(name: name, icon: icon, color: color, kind: kind, parentId: parent?.id, units: units);
                } else {
                  await repo.update(CategoriesCompanion(id: Value(existing.id), name: Value(name), icon: Value(icon), color: Value(color), units: Value(units)));
                }
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    ),
  );
}
