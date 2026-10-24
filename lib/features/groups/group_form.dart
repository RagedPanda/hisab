import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_icons.dart';
import '../../core/providers.dart';
import '../../l10n/l10n.dart';
import 'member_display.dart';

const groupIcons = ['groups', 'flight', 'home', 'restaurant', 'celebration', 'work', 'sports_cricket', 'directions_car', 'favorite', 'school'];

Future<void> showGroupForm(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final membersController = TextEditingController();
  var icon = groupIcons.first;
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
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
              GroupIconPicker(selected: icon, onSelected: (option) => setSheetState(() => icon = option)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final myName = resolvedMyName(l10n, ref.read(settingsProvider));
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

/// One chip per group icon; shared by the new-group form and group settings.
class GroupIconPicker extends StatelessWidget {
  const GroupIconPicker({super.key, required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final option in groupIcons)
            ChoiceChip(
              label: Icon(iconFor(option), size: 20),
              selected: selected == option,
              onSelected: (_) => onSelected(option),
            ),
        ],
      );
}
