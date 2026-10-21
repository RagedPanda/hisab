/// Category filter semantics shared by the dashboard and the entries list. Pure.
library;

/// Whether an entry in [categoryId] (whose parent is [parentId]) matches the
/// selected category: '' selects entries without a category, otherwise the
/// category itself or any of its sub-categories.
bool matchesCategoryFilter({required String selectedId, String? categoryId, String? parentId}) =>
    selectedId.isEmpty ? categoryId == null : categoryId == selectedId || parentId == selectedId;
