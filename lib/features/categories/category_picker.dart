import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/categories_repository.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'subcategory_preview.dart';

final _recentCategoryIdsProvider = FutureProvider.family<List<String>, String>((ref, kind) => ref.watch(entriesRepositoryProvider).recentCategoryIds(kind: kind));

/// Bottom sheet that lets the user pick a parent or child category.
Future<Category?> showCategoryPicker(BuildContext context, {required String kind, String? selectedId}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => _CategoryPickerBody(kind: kind, selectedId: selectedId, controller: controller),
    ),
  );
}

class _CategoryPickerBody extends ConsumerStatefulWidget {
  const _CategoryPickerBody({required this.kind, required this.selectedId, required this.controller});
  final String kind;
  final String? selectedId;
  final ScrollController controller;

  @override
  ConsumerState<_CategoryPickerBody> createState() => _CategoryPickerBodyState();
}

class _CategoryPickerBodyState extends ConsumerState<_CategoryPickerBody> {
  String _query = '';
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _expandedId = widget.selectedId;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final tree = buildCategoryTree(categories, kind: widget.kind);
    final needle = _query.trim().toLowerCase();
    final searching = needle.isNotEmpty;
    final matches = searching
        ? categories.where((c) => c.kind == widget.kind && (c.name.toLowerCase().contains(needle) || c.displayName(context).toLowerCase().contains(needle))).toList()
        : const <Category>[];
    final byId = {for (final c in categories) c.id: c};
    final selected = widget.selectedId == null ? null : byId[widget.selectedId];
    final expanded = _expandedId == null ? null : (byId[_expandedId]?.parentId ?? _expandedId);
    final recent = (ref.watch(_recentCategoryIdsProvider(widget.kind)).value ?? const <String>[]).map((id) => byId[id]).whereType<Category>().toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: false,
            decoration: InputDecoration(hintText: context.l10n.searchCategories, prefixIcon: const Icon(Icons.search), isDense: true),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: searching
              ? ListView(
                  controller: widget.controller,
                  children: [
                    for (final category in matches)
                      ListTile(
                        leading: IconBadge(icon: category.icon, color: category.color),
                        title: Text(category.displayName(context)),
                        subtitle: category.parentId == null ? null : Text(byId[category.parentId]?.displayName(context) ?? ''),
                        onTap: () => Navigator.pop(context, category),
                      ),
                    if (matches.isEmpty) EmptyState(icon: Icons.search_off, title: context.l10n.noMatchingCategory),
                  ],
                )
              : ListView(
                  controller: widget.controller,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (recent.isNotEmpty) _RecentRow(categories: recent, selected: selected, onPick: (category) => Navigator.pop(context, category)),
                    for (final node in tree)
                      _ParentTile(
                        node: node,
                        expanded: expanded == node.category.id,
                        selected: selected,
                        onToggle: () => setState(() => _expandedId = expanded == node.category.id ? null : node.category.id),
                        onPick: (category) => Navigator.pop(context, category),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Recently used categories as a chip row so the common picks are one tap away.
class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.categories, required this.selected, required this.onPick});
  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(context.l10n.recent),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ChoiceChip(
                avatar: IconBadge(icon: category.icon, color: category.color, size: 22),
                label: Text(category.displayName(context)),
                selected: selected?.id == category.id,
                onSelected: (_) => onPick(category),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ParentTile extends StatelessWidget {
  const _ParentTile({required this.node, required this.expanded, required this.selected, required this.onToggle, required this.onPick});
  final CategoryNode node;
  final bool expanded;
  final Category? selected;
  final VoidCallback onToggle;
  final ValueChanged<Category> onPick;

  @override
  Widget build(BuildContext context) {
    final parent = node.category;
    final l10n = context.l10n;
    return Column(
      children: [
        ListTile(
          leading: IconBadge(icon: parent.icon, color: parent.color),
          title: Text(parent.displayName(context), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: node.children.isEmpty || expanded ? null : Text(subcategoryPreview(context, node), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: node.children.isEmpty
              ? null
              : IconButton(
                  tooltip: expanded ? l10n.collapse : l10n.expand,
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: onToggle,
                ),
          selected: selected?.id == parent.id,
          onTap: () => onPick(parent),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final child in node.children)
                  ChoiceChip(
                    avatar: IconBadge(icon: child.icon, color: child.color, size: 22),
                    label: Text(child.displayName(context)),
                    selected: selected?.id == child.id,
                    onSelected: (_) => onPick(child),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
