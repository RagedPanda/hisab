import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/accounts_screen.dart';
import '../budgets/budgets_screen.dart';
import '../categories/categories_screen.dart';
import '../categories/category_packs_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../expense_editor/expense_editor_screen.dart';
import '../groups/activity_screen.dart';
import '../groups/group_detail_screen.dart';
import '../groups/group_settings_screen.dart';
import '../groups/group_totals_screen.dart';
import '../groups/groups_screen.dart';
import '../projects/project_detail_screen.dart';
import '../projects/project_form_screen.dart';
import '../projects/project_templates_screen.dart';
import '../projects/projects_screen.dart';
import '../salary/salary_setup_screen.dart';
import '../salary/salary_reminder.dart';
import '../settings/settings_screen.dart';
import '../reminders/reminders_screen.dart';
import '../sms/sms_history_screen.dart';
import '../sms/sms_review_screen.dart';
import '../sms/sms_screen.dart';
import '../subscriptions/subscription_form_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../transactions/transactions_screen.dart';
import '../recurring/recurring_rule_form_screen.dart';
import '../recurring/recurring_screen.dart';
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
      // The editor handles Back itself: it asks before discarding input and
      // falls back to home when there is nothing to pop to (#82).
      builder: (_, state) => ExpenseEditorScreen(
        entryId: state.uri.queryParameters['id'],
        groupId: state.uri.queryParameters['group'],
        initialKind: state.uri.queryParameters['kind'],
        smsId: state.uri.queryParameters['sms'],
        projectId: state.uri.queryParameters['project'],
        reminderId: state.uri.queryParameters['reminder'],
      ),
    ),
    GoRoute(path: '/groups/:id', parentNavigatorKey: _rootKey, builder: (_, state) => GroupDetailScreen(
          key: ValueKey(state.uri.toString()),
          groupId: state.pathParameters['id']!,
          initialTab: groupDetailInitialTab(state.uri.queryParameters['tab']),
        )),
    GoRoute(path: '/groups/:id/totals', parentNavigatorKey: _rootKey, builder: (_, state) => GroupTotalsScreen(groupId: state.pathParameters['id']!)),
    GoRoute(path: '/groups/:id/settings', parentNavigatorKey: _rootKey, builder: (_, state) => GroupSettingsScreen(groupId: state.pathParameters['id']!)),
    GoRoute(path: '/groups/:id/activity', parentNavigatorKey: _rootKey, builder: (_, state) => ActivityScreen(groupId: state.pathParameters['id']!)),
    GoRoute(path: '/activity', parentNavigatorKey: _rootKey, builder: (_, _) => const ActivityScreen()),
    GoRoute(path: '/categories', parentNavigatorKey: _rootKey, builder: (_, _) => const CategoriesScreen()),
    GoRoute(path: '/categories/packs', parentNavigatorKey: _rootKey, builder: (_, _) => const CategoryPacksScreen()),
    GoRoute(path: '/accounts', parentNavigatorKey: _rootKey, builder: (_, _) => const AccountsScreen()),
    GoRoute(path: kSalaryLocation, parentNavigatorKey: _rootKey, builder: (_, _) => const SalarySetupScreen()),
    GoRoute(path: '/budgets', parentNavigatorKey: _rootKey, builder: (_, _) => const BudgetsScreen()),
    GoRoute(
      path: '/recurring',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const RecurringScreen(),
      routes: [
        GoRoute(path: 'new', parentNavigatorKey: _rootKey, builder: (_, _) => const RecurringRuleFormScreen()),
        GoRoute(path: ':id', parentNavigatorKey: _rootKey, builder: (_, state) => RecurringRuleFormScreen(ruleId: state.pathParameters['id']!)),
      ],
    ),
    GoRoute(
      path: '/subscriptions',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const SubscriptionsScreen(),
      routes: [
        GoRoute(path: 'new', parentNavigatorKey: _rootKey, builder: (_, state) => SubscriptionFormScreen(templateKey: state.uri.queryParameters['template'])),
        GoRoute(path: ':id/edit', parentNavigatorKey: _rootKey, builder: (_, state) => SubscriptionFormScreen(ruleId: state.pathParameters['id']!)),
      ],
    ),
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
    GoRoute(path: '/reminders', parentNavigatorKey: _rootKey, builder: (_, _) => const RemindersScreen()),
    GoRoute(path: '/reminders/:id', parentNavigatorKey: _rootKey, builder: (_, state) => HomeFallbackPop(child: RemindersScreen(highlightId: state.pathParameters['id']))),
    GoRoute(path: '/sms', parentNavigatorKey: _rootKey, builder: (_, state) => HomeFallbackPop(child: SmsScreen(sharedText: state.uri.queryParameters['text']))),
    GoRoute(path: '/sms/review', parentNavigatorKey: _rootKey, builder: (_, _) => const HomeFallbackPop(child: SmsReviewScreen())),
    GoRoute(path: '/sms/history', parentNavigatorKey: _rootKey, builder: (_, _) => const SmsHistoryScreen()),
  ],
);
