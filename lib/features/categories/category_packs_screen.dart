import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/categories_repository.dart';
import '../../domain/categories/category_catalog.dart';
import '../../domain/categories/category_packs.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// Settings > Categories > Add a pack: every category pack, whether it is on,
/// and a preview sheet to add or remove it.
class CategoryPacksScreen extends ConsumerWidget {
  const CategoryPacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final added = addedPackKeys(categories.map(packCategoryRef));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoryPacks)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l10n.categoryPacksHint, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (final pack in categoryPacks)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                key: ValueKey('pack.${pack.key}'),
                leading: IconBadge(icon: pack.icon, color: pack.primary.color),
                title: Text(seedDisplayName(pack.primary, locale), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.packCategoryCount(planPack(pack, const {}).length)),
                trailing: added.contains(pack.key)
                    ? Chip(label: Text(l10n.packAdded), avatar: const Icon(Icons.check, size: 16), visualDensity: VisualDensity.compact)
                    : const Icon(Icons.chevron_right),
                onTap: () => showPackPreview(context, pack),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet listing what [pack] brings, marking what the user already has,
/// with Add pack (or Remove pack once it is on).
Future<void> showPackPreview(BuildContext context, CategoryPack pack) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => _PackPreview(pack: pack, controller: controller),
      ),
    );

class _PackPreview extends ConsumerWidget {
  const _PackPreview({required this.pack, required this.controller});
  final CategoryPack pack;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final existingKeys = {for (final category in categories) ?category.seedKey};
    final isAdded = addedPackKeys(categories.map(packCategoryRef)).contains(pack.key);
    final plan = planPack(pack, existingKeys);
    final newCount = plan.where((item) => !item.exists).length;
    final summary = [
      if (newCount > 0) l10n.suggestedCategoriesNew(newCount),
      if (plan.length > newCount) l10n.suggestedCategoriesReused(plan.length - newCount),
    ].join(' · ');
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Row(
                children: [
                  IconBadge(icon: pack.icon, color: pack.primary.color),
                  const SizedBox(width: 12),
                  Expanded(child: Text(seedDisplayName(pack.primary, locale), style: textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 4),
              Text(summary, style: textTheme.bodyMedium),
              for (final root in pack.roots) ...[
                const SizedBox(height: 16),
                Align(alignment: AlignmentDirectional.centerStart, child: _SeedChip(seed: root, exists: existingKeys.contains(root.key), bold: true)),
                if (root.children.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final child in root.children) _SeedChip(seed: child, exists: existingKeys.contains(child.key))],
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(l10n.packAlreadyHave, style: textTheme.bodySmall)),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: isAdded
                  ? OutlinedButton(key: const ValueKey('pack.remove'), onPressed: () => _remove(context, ref), child: Text(l10n.removePack))
                  : FilledButton(key: const ValueKey('pack.add'), onPressed: () => _add(context, ref), child: Text(l10n.addPack)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.packAddedMessage;
    final created = await ref.read(categoriesRepositoryProvider).addPack(pack);
    if (context.mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(message(created))));
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final repo = ref.read(categoriesRepositoryProvider);
    final preview = await repo.previewPackRemoval(pack.key);
    if (!context.mounted) return;
    final confirmed = await confirmDialog(
      context,
      title: l10n.removePackTitle(seedDisplayName(pack.primary, Localizations.localeOf(context))),
      message: l10n.removePackMessage(preview.archiveIds.length, preview.keepIds.length + preview.handOver.length),
      confirmLabel: l10n.remove,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await repo.removePack(pack.key);
    if (context.mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.packRemoved)));
  }
}

class _SeedChip extends StatelessWidget {
  const _SeedChip({required this.seed, required this.exists, this.bold = false});
  final CategorySeed seed;
  final bool exists;
  final bool bold;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(exists ? Icons.check_circle : appIcons[seed.icon], size: 16, color: Color(seed.color)),
        label: Text(seedDisplayName(seed, Localizations.localeOf(context)), style: bold ? const TextStyle(fontWeight: FontWeight.w600) : null),
        visualDensity: VisualDensity.compact,
      );
}
