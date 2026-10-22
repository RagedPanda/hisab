import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/accounts_screen.dart';
import '../budgets/budgets_screen.dart';
import '../categories/categories_screen.dart';
import '../categories/category_packs_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../expense_editor/expense_editor_screen.dart';
import '../groups/group_detail_screen.dart';
import '../groups/group_totals_screen.dart';
import '../groups/groups_screen.dart';
import '../projects/project_detail_screen.dart';
import '../projects/project_form_screen.dart';
import '../projects/project_templates_screen.dart';
import '../projects/projects_screen.dart';
import '../settings/settings_screen.dart';
import '../sms/sms_screen.dart';
import '../transactions/transactions_screen.dart';
import 'app_shell.dart';
import 'deep_link.dart';
import 'widgets/common.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  // Custom-scheme links arrive as 'hisab://sms?text=…' on some launchers; the
  // host is the intended path.
  redirect: (context, state) => deepLinkLocation(state.uri),
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
      builder: (_, state) => HomeFallbackPop(
        child: ExpenseEditorScreen(
          entryId: state.uri.queryParameters['id'],
          groupId: state.uri.queryParameters['group'],
          initialKind: state.uri.queryParameters['kind'],
          smsId: state.uri.queryParameters['sms'],
          projectId: state.uri.queryParameters['project'],
        ),
      ),
    ),
    GoRoute(path: '/groups/:id', parentNavigatorKey: _rootKey, builder: (_, state) => GroupDetailScreen(groupId: state.pathParameters['id']!)),
    GoRoute(path: '/groups/:id/totals', parentNavigatorKey: _rootKey, builder: (_, state) => GroupTotalsScreen(groupId: state.pathParameters['id']!)),
    GoRoute(path: '/categories', parentNavigatorKey: _rootKey, builder: (_, _) => const CategoriesScreen()),
    GoRoute(path: '/categories/packs', parentNavigatorKey: _rootKey, builder: (_, _) => const CategoryPacksScreen()),
    GoRoute(path: '/accounts', parentNavigatorKey: _rootKey, builder: (_, _) => const AccountsScreen()),
    GoRoute(path: '/budgets', parentNavigatorKey: _rootKey, builder: (_, _) => const BudgetsScreen()),
    GoRoute(
      path: '/projects',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const ProjectsScreen(),
      routes: [
        GoRoute(path: 'new', parentNavigatorKey: _rootKey, builder: (_, _) => const ProjectTemplatesScreen()),
        GoRoute(
          path: 'new/:template',
          parentNavigatorKey: _rootKey,
          builder: (_, state) => ProjectFormScreen(templateKey: state.pathParameters['template']),
        ),
        GoRoute(
          path: ':id',
          parentNavigatorKey: _rootKey,
          builder: (_, state) => ProjectDetailScreen(projectId: state.pathParameters['id']!),
          routes: [
            GoRoute(path: 'edit', parentNavigatorKey: _rootKey, builder: (_, state) => ProjectFormScreen(projectId: state.pathParameters['id']!)),
          ],
        ),
      ],
    ),
    GoRoute(path: '/sms', parentNavigatorKey: _rootKey, builder: (_, state) => HomeFallbackPop(child: SmsScreen(sharedText: state.uri.queryParameters['text']))),
  ],
);
