import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../sms/sms_auto_add_snackbar.dart';

/// Tabs, the add button and, while the app is open, the Undo snackbar for
/// entries added automatically from bank SMS.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final showFab = shell.currentIndex < 2;
    final l10n = context.l10n;
    final onHomeTab = shell.currentIndex == 0;
    return PopScope(
      // Back on any other tab returns to Home instead of leaving the app.
      canPop: onHomeTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: SmsAutoAddSnackbar(
      child: Scaffold(
      body: shell,
      floatingActionButton: showFab
          ? FloatingActionButton(
              heroTag: 'add-entry',
              onPressed: () => context.push('/entry'),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.tabHome),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: l10n.tabEntries),
          NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: l10n.tabGroups),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l10n.tabSettings),
        ],
      ),
      ),
      ),
    );
  }
}
