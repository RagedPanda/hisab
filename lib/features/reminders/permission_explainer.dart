import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Bottom sheet that explains a permission before the system asks for it.
/// True when the user chose Allow; false for Not now or dismissing.
Future<bool> showPermissionExplainer(BuildContext context, {required IconData icon, required String title, required String body}) async {
  final l10n = context.l10n;
  final allow = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: Theme.of(sheetContext).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(sheetContext).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext, false), child: Text(l10n.notNow))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: Text(l10n.allow))),
          ]),
        ]),
      ),
    ),
  );
  return allow ?? false;
}
