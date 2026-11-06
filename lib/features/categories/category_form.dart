import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/categories/category_suggestion.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// [category] as the suggestion helpers see it, with its stored and
/// localised names.
CategoryOption categoryOption(Category category, Locale locale) =>
    (id: category.id, parentId: category.parentId, seedKey: category.seedKey, names: [category.name, categoryDisplayName(category, locale)]);

/// Value of the "Put under" choice that makes a top-level category.
const _topLevel = '';

/// Add or edit sheet for one category; resolves to the saved category, or
/// null when dismissed.
///
/// [parentChoices] turns on a "Put under" choice between those top-level
/// categories (with [suggestedParent] listed first and preselected) and a
/// top-level category; icon and colour follow the chosen parent until the
/// user picks their own. [initialName] prefills the name. Creating a name that
/// already exists under the same parent returns that category instead.
Future<Category?> showCategoryForm(
  BuildContext context,
  WidgetRef ref, {
  required String kind,
  Category? parent,
  Category? existing,
  String initialName = '',
  List<Category>? parentChoices,
  Category? suggestedParent,
}) {
  final nameController = TextEditingController(text: existing?.name ?? initialName);
  final unitsController = TextEditingController(text: existing?.units ?? '');
  final choices = parentChoices == null ? null : [?suggestedParent, ...parentChoices.where((choice) => choice.id != suggestedParent?.id)];
  final byId = {for (final choice in choices ?? const <Category>[]) choice.id: choice};
  var parentId = choices == null ? parent?.id : (suggestedParent?.id ?? _topLevel);
  final topLevelColor = nextCategoryColor([for (final choice in choices ?? const <Category>[]) choice.color], kPaletteColors);
  var icon = existing?.icon ?? parent?.icon ?? suggestedParent?.icon ?? 'category';
  var color = existing?.color ?? parent?.color ?? suggestedParent?.color ?? (choices == null ? kPaletteColors.first : topLevelColor);
  var styleTouched = false;
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context);
  final parentName = parent?.displayName(context);
  final existingName = existing?.displayName(context);

  void followParent(String? chosenId) {
    parentId = chosenId;
    if (styleTouched) return;
    final chosen = byId[chosenId];
    icon = chosen?.icon ?? 'category';
    color = chosen?.color ?? topLevelColor;
  }

  Future<Category?> save() async {
    final name = nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) return null;
    final units = unitsController.text.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty).join(',');
    final repo = ref.read(categoriesRepositoryProvider);
    final underId = parentId == _topLevel ? null : parentId;
    if (existing != null) {
      await repo.update(CategoriesCompanion(id: Value(existing.id), name: Value(name), icon: Value(icon), color: Value(color), units: Value(units)));
      return repo.byId(existing.id);
    }
    final sameKind = (await repo.getAll()).where((category) => category.kind == kind).toList();
    final duplicate = existingCategoryNamed(name, [for (final category in sameKind) categoryOption(category, locale)], parentId: underId);
    if (duplicate != null) return repo.byId(duplicate.id);
    final id = await repo.create(name: name, icon: icon, color: color, kind: kind, parentId: underId, units: units);
    return repo.byId(id);
  }

  return showModalBottomSheet<Category>(
    context: context,
    useRootNavigator: true,
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
            TextField(key: const ValueKey('categoryForm.name'), controller: nameController, autofocus: initialName.isEmpty, decoration: InputDecoration(labelText: l10n.name, prefixIcon: Padding(padding: const EdgeInsets.all(8), child: IconBadge(key: const ValueKey('categoryForm.preview'), icon: icon, color: color, size: 32))), textCapitalization: TextCapitalization.words),
            if (choices != null) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey('categoryForm.parent'),
                initialValue: parentId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.putUnder),
                items: [
                  for (final choice in choices.take(suggestedParent == null ? 0 : 1)) _parentItem(sheetContext, choice, suggested: true),
                  DropdownMenuItem(
                    value: _topLevel,
                    child: Row(children: [const Icon(Icons.category_outlined), const SizedBox(width: 12), Expanded(child: Text(l10n.ownTopLevelCategory, overflow: TextOverflow.ellipsis))]),
                  ),
                  for (final choice in choices.skip(suggestedParent == null ? 0 : 1)) _parentItem(sheetContext, choice, suggested: false),
                ],
                onChanged: (value) => setSheetState(() => followParent(value)),
              ),
            ],
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
                    onTap: () => setSheetState(() {
                      color = option;
                      styleTouched = true;
                    }),
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
                      onPressed: () => setSheetState(() {
                        icon = name;
                        styleTouched = true;
                      }),
                      icon: Icon(appIcons[name], color: icon == name ? Color(color) : null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('categoryForm.save'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                final saved = await save();
                if (saved != null && sheetContext.mounted) Navigator.pop(sheetContext, saved);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    ),
  );
}

DropdownMenuItem<String> _parentItem(BuildContext context, Category choice, {required bool suggested}) {
  final name = choice.displayName(context);
  return DropdownMenuItem(
    value: choice.id,
    child: Row(children: [
      Icon(appIcons[choice.icon], color: Color(choice.color)),
      const SizedBox(width: 12),
      Expanded(child: Text(suggested ? context.l10n.suggestedParent(name) : name, overflow: TextOverflow.ellipsis)),
    ]),
  );
}
