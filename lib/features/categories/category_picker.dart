import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/categories_repository.dart';
import '../shell/widgets/common.dart';

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
        ? categories.where((c) => c.kind == widget.kind && c.name.toLowerCase().contains(needle)).toList()
        : const <Category>[];
    final byId = {for (final c in categories) c.id: c};
    final selected = widget.selectedId == null ? null : byId[widget.selectedId];
    final expanded = _expandedId == null ? null : (byId[_expandedId]?.parentId ?? _expandedId);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: false,
            decoration: const InputDecoration(hintText: 'Search categories', prefixIcon: Icon(Icons.search), isDense: true),
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
                        title: Text(category.name),
                        subtitle: category.parentId == null ? null : Text(byId[category.parentId]?.name ?? ''),
                        onTap: () => Navigator.pop(context, category),
                      ),
                    if (matches.isEmpty) const EmptyState(icon: Icons.search_off, title: 'No matching category'),
                  ],
                )
              : ListView(
                  controller: widget.controller,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
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
    return Column(
      children: [
        ListTile(
          leading: IconBadge(icon: parent.icon, color: parent.color),
          title: Text(parent.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: node.children.isEmpty
              ? null
              : IconButton(icon: Icon(expanded ? Icons.expand_less : Icons.expand_more), onPressed: onToggle),
          selected: selected?.id == parent.id,
          onTap: node.children.isEmpty ? () => onPick(parent) : onToggle,
          onLongPress: () => onPick(parent),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: Icon(Icons.label_outline, size: 18, color: Color(parent.color)),
                  label: Text('${parent.name} (general)'),
                  selected: selected?.id == parent.id,
                  onSelected: (_) => onPick(parent),
                ),
                for (final child in node.children)
                  ChoiceChip(
                    avatar: IconBadge(icon: child.icon, color: child.color, size: 22),
                    label: Text(child.name),
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
