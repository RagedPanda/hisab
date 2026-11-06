import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/entries/entry_filter.dart';
import '../../domain/entries/tag_edits.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import '../transactions/transactions_screen.dart';

const String kTagsLocation = '/settings/tags';

/// Lists with more tags than this get a search field.
const int _searchFrom = 8;

/// Settings → Tags: every tag in use with its entry count. Tap one for its
/// entries; rename (merging into a tag of the same name) or remove it from
/// every entry, each with Undo.
class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(tagCountsProvider);
    final all = async.value ?? const <TagCount>[];
    final needle = _query.trim().toLowerCase().replaceFirst(RegExp(r'^#+'), '');
    final shown = needle.isEmpty ? all : all.where((tag) => tag.tag.toLowerCase().contains(needle)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tags)),
      body: !async.hasValue
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
              ? EmptyState(icon: Icons.sell_outlined, title: l10n.noTagsTitle, message: l10n.noTagsBody)
              : DismissKeyboardOnTap(
                  child: Column(
                    children: [
                      if (all.length > _searchFrom)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: TextField(
                            key: const ValueKey('tags.search'),
                            decoration: InputDecoration(hintText: l10n.searchTags, prefixIcon: const Icon(Icons.search), isDense: true),
                            onChanged: (value) => setState(() => _query = value),
                          ),
                        ),
                      Expanded(
                        child: shown.isEmpty
                            ? EmptyState(icon: Icons.search_off, title: l10n.noMatchingTag)
                            : ListView(
                                padding: const EdgeInsets.only(bottom: 24),
                                children: [
                                  for (final tag in shown)
                                    ListTile(
                                      key: ValueKey('tag.${tag.tag}'),
                                      leading: const Icon(Icons.tag),
                                      title: Text(tag.tag),
                                      subtitle: Text(l10n.entryCountLabel(tag.count)),
                                      trailing: _TagMenu(onRename: () => _rename(tag, all), onRemove: () => _remove(tag)),
                                      onTap: () => context.go(entriesForTagLocation(tag.tag)),
                                      onLongPress: () => _rename(tag, all),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _rename(TagCount tag, List<TagCount> all) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final input = await _promptTagName(context, tag.tag);
    if (input == null || !mounted) return;
    final plan = planTagRename(tag.tag, input, [for (final each in all) each.tag]);
    final to = plan.to;
    if (to == null || plan.kind == TagRenameKind.unchanged) return;
    final merging = plan.kind == TagRenameKind.merge;
    if (merging &&
        !await confirmDialog(context, title: l10n.mergeTagTitle(to), message: l10n.mergeTagBody(tag.tag, to), confirmLabel: l10n.mergeAction)) {
      return;
    }
    final repo = ref.read(tagsRepositoryProvider);
    final before = await repo.renameTag(tag.tag, to);
    showUndoSnackBar(
      messenger,
      message: merging ? l10n.tagMerged(tag.tag, to) : l10n.tagRenamed(tag.tag, to),
      undoLabel: l10n.undo,
      onUndo: () => repo.restore(before),
    );
  }

  Future<void> _remove(TagCount tag) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirmDialog(context, title: l10n.removeTagTitle(tag.tag, tag.count), message: l10n.removeTagBody, confirmLabel: l10n.remove)) return;
    final repo = ref.read(tagsRepositoryProvider);
    final before = await repo.deleteTag(tag.tag);
    showUndoSnackBar(messenger, message: l10n.tagRemoved(tag.tag), undoLabel: l10n.undo, onUndo: () => repo.restore(before));
  }
}

class _TagMenu extends StatelessWidget {
  const _TagMenu({required this.onRename, required this.onRemove});
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<VoidCallback>(
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        PopupMenuItem(key: const ValueKey('tag.rename'), value: onRename, child: Text(l10n.rename)),
        PopupMenuItem(key: const ValueKey('tag.remove'), value: onRemove, child: Text(l10n.remove)),
      ],
    );
  }
}

/// Asks for a new name for tag [current]; Save stays off until the text is
/// one tag (see [tagNameFrom]). Resolves to the text, or null when cancelled.
Future<String?> _promptTagName(BuildContext context, String current) {
  final controller = TextEditingController(text: current)..selection = TextSelection(baseOffset: 0, extentOffset: current.length);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final l10n = dialogContext.l10n;
        final valid = tagNameFrom(controller.text) != null;
        void submit() {
          if (valid) Navigator.pop(dialogContext, controller.text);
        }

        return AlertDialog(
          title: Text(l10n.renameTagTitle(current)),
          content: TextField(
            key: const ValueKey('tagRename.field'),
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(prefixText: '#', errorText: valid || controller.text.trim().isEmpty ? null : l10n.tagNameInvalid),
            onChanged: (_) => setDialogState(() {}),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            FilledButton(key: const ValueKey('tagRename.save'), onPressed: valid ? submit : null, child: Text(l10n.save)),
          ],
        );
      },
    ),
  );
}
