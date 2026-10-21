import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../l10n/l10n.dart';

const groupIcons = ['groups', 'flight', 'home', 'restaurant', 'celebration', 'work', 'sports_cricket', 'directions_car', 'favorite', 'school'];

Future<void> showGroupForm(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final membersController = TextEditingController();
  var icon = groupIcons.first;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final l10n = sheetContext.l10n;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.newGroup, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: nameController, autofocus: true, decoration: InputDecoration(labelText: l10n.groupName, hintText: l10n.groupNameHint), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              TextField(controller: membersController, decoration: InputDecoration(labelText: l10n.membersCommaSeparated, hintText: l10n.membersHint), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in groupIcons)
                    ChoiceChip(
                      label: Icon(_icon(option), size: 20),
                      selected: icon == option,
                      onSelected: (_) => setSheetState(() => icon = option),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final myName = ref.read(settingsProvider).myName;
                  final others = membersController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  final id = await ref.read(groupsRepositoryProvider).createGroup(name: name, icon: icon, myName: myName, otherMembers: others);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (context.mounted) context.push('/groups/$id');
                },
                child: Text(l10n.createGroup),
              ),
            ],
          ),
        );
      },
    ),
  );
}

IconData _icon(String name) => switch (name) {
      'flight' => Icons.flight,
      'home' => Icons.home,
      'restaurant' => Icons.restaurant,
      'celebration' => Icons.celebration,
      'work' => Icons.work,
      'sports_cricket' => Icons.sports_cricket,
      'directions_car' => Icons.directions_car,
      'favorite' => Icons.favorite,
      'school' => Icons.school,
      _ => Icons.groups,
    };
