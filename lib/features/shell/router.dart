import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/accounts_screen.dart';
import '../budgets/budgets_screen.dart';
import '../categories/categories_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../expense_editor/expense_editor_screen.dart';
import '../groups/group_detail_screen.dart';
import '../groups/groups_screen.dart';
import '../settings/settings_screen.dart';
import '../sms/sms_screen.dart';
import '../transactions/transactions_screen.dart';
import 'app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  // Custom-scheme links arrive as 'hisab://sms?text=…' on some launchers; the
  // host is the intended path.
  redirect: (context, state) {
    final uri = state.uri;
    if (uri.host.isNotEmpty && uri.path.isEmpty) return Uri(path: '/${uri.host}', queryParameters: uri.queryParameters).toString();
    return null;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const DashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/transactions', builder: (_, _) => const TransactionsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/groups', builder: (_, _) => const GroupsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
      ],
    ),
    GoRoute(
      path: '/entry',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => ExpenseEditorScreen(
        entryId: state.uri.queryParameters['id'],
        groupId: state.uri.queryParameters['group'],
        initialKind: state.uri.queryParameters['kind'],
        smsId: state.uri.queryParameters['sms'],
      ),
    ),
    GoRoute(path: '/groups/:id', parentNavigatorKey: _rootKey, builder: (_, state) => GroupDetailScreen(groupId: state.pathParameters['id']!)),
    GoRoute(path: '/categories', parentNavigatorKey: _rootKey, builder: (_, _) => const CategoriesScreen()),
    GoRoute(path: '/accounts', parentNavigatorKey: _rootKey, builder: (_, _) => const AccountsScreen()),
    GoRoute(path: '/budgets', parentNavigatorKey: _rootKey, builder: (_, _) => const BudgetsScreen()),
    GoRoute(path: '/sms', parentNavigatorKey: _rootKey, builder: (_, state) => SmsScreen(sharedText: state.uri.queryParameters['text'])),
  ],
);
