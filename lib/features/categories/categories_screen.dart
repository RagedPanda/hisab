import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/categories_repository.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-category',
        onPressed: () => showCategoryForm(context, ref, kind: _kind),
        icon: const Icon(Icons.add),
        label: const Text('Category'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
                ButtonSegment(value: 'transfer', label: Text('Transfer')),
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
                      title: Text(node.category.name, style: TextStyle(fontWeight: FontWeight.w600, decoration: node.category.isArchived ? TextDecoration.lineThrough : null)),
                      subtitle: Text('${node.children.length} subcategories'),
                      trailing: _menu(context, node.category),
                      children: [
                        for (final child in node.children)
                          ListTile(
                            dense: true,
                            leading: IconBadge(icon: child.icon, color: child.color, size: 32),
                            title: Text(child.name, style: TextStyle(decoration: child.isArchived ? TextDecoration.lineThrough : null)),
                            subtitle: child.units.isEmpty ? null : Text('Units: ${child.units.replaceAll(',', ', ')}'),
                            trailing: _menu(context, child),
                          ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.add, size: 20),
                          title: const Text('Add subcategory'),
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
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await showCategoryForm(context, ref, kind: category.kind, existing: category);
          case 'archive':
            await repo.setArchived(category.id, !category.isArchived);
          case 'delete':
            if (await confirmDialog(context, title: 'Delete ${category.name}?', message: 'Existing entries keep their amounts but become uncategorised.')) {
              await repo.delete(category.id);
            }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'archive', child: Text(category.isArchived ? 'Unarchive' : 'Archive (hide from picker)')),
        if (category.seedKey == null) const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

Future<void> showCategoryForm(BuildContext context, WidgetRef ref, {required String kind, Category? parent, Category? existing}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final unitsController = TextEditingController(text: existing?.units ?? '');
  var icon = existing?.icon ?? parent?.icon ?? 'category';
  var color = existing?.color ?? parent?.color ?? kPaletteColors.first;
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
            Text(existing == null ? (parent == null ? 'New category' : 'New subcategory of ${parent.name}') : 'Edit ${existing.name}', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Name'), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: unitsController, decoration: const InputDecoration(labelText: 'Units for items (comma separated)', hintText: 'L, ml, kg')),
            const SizedBox(height: 12),
            Text('Colour', style: Theme.of(sheetContext).textTheme.labelLarge),
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
            Text('Icon', style: Theme.of(sheetContext).textTheme.labelLarge),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ),
  );
}
