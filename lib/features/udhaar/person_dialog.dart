import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// A person's name and optional phone, as typed.
typedef PersonFields = ({String name, String? phone});

/// Asks for a person's name and phone (for WhatsApp); null when cancelled.
/// Save stays disabled until there is a name.
Future<PersonFields?> showPersonDialog(BuildContext context, {required String title, String name = '', String? phone}) {
  final nameController = TextEditingController(text: name);
  final phoneController = TextEditingController(text: phone ?? '');
  return showDialog<PersonFields>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = context.l10n;
        final canSave = nameController.text.trim().isNotEmpty;
        void save() {
          if (!canSave) return;
          final typedPhone = phoneController.text.trim();
          Navigator.pop(context, (name: nameController.text.trim(), phone: typedPhone.isEmpty ? null : typedPhone));
        }

        return AlertDialog(
          title: Text(title),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              key: const Key('udhaar.personName'),
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.name),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('udhaar.personPhone'),
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phoneOptional),
              onSubmitted: (_) => save(),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            FilledButton(key: const Key('udhaar.personSave'), onPressed: canSave ? save : null, child: Text(l10n.save)),
          ],
        );
      },
    ),
  );
}
