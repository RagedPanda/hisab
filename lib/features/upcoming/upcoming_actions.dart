import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/upcoming/upcoming_items.dart';
import '../../l10n/l10n.dart';
import 'upcoming_routes.dart';
import 'widgets/upcoming_item_tile.dart';

enum UpcomingConfirmChoice { confirm, edit }

/// What tapping an upcoming item does, shared by the card and the calendar:
/// an overdue confirm-first occurrence offers Confirm first and Edit second;
/// everything else opens the screen that owns it.
Future<void> openUpcomingItem(BuildContext context, WidgetRef ref, UpcomingItem item) async {
  if (!item.offersConfirm) {
    context.push(upcomingItemRoute(item));
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final choice = await showModalBottomSheet<UpcomingConfirmChoice>(
    context: context,
    showDragHandle: true,
    builder: (_) => UpcomingConfirmSheet(item: item),
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case UpcomingConfirmChoice.confirm:
      await ref.read(recurringRepositoryProvider).confirmNext(item.sourceId, monthStartDay: ref.read(settingsProvider).monthStartDay);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.recurringAdded)));
    case UpcomingConfirmChoice.edit:
      context.push(upcomingItemRoute(item));
  }
}

/// Bottom sheet for an overdue confirm-first item: Confirm posts it, Edit
/// opens the rule.
class UpcomingConfirmSheet extends StatelessWidget {
  const UpcomingConfirmSheet({super.key, required this.item});

  final UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UpcomingItemTile(item: item),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.upcomingConfirmPrompt, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const ValueKey('upcoming.confirm.edit'),
                    onPressed: () => Navigator.of(context).pop(UpcomingConfirmChoice.edit),
                    child: Text(l10n.edit),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('upcoming.confirm.post'),
                    onPressed: () => Navigator.of(context).pop(UpcomingConfirmChoice.confirm),
                    child: Text(l10n.upcomingConfirm),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
