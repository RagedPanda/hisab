/// Keys on each dashboard card's root so tests can assert the composition
/// without matching on translated text.
library;

import 'package:flutter/widgets.dart';

const Key kSummarySpentKey = ValueKey('summary.spent');
const Key kHeroCardKey = ValueKey('dashboard.hero');
const Key kHeroTodayKey = ValueKey('dashboard.hero.today');
const Key kSafeToSpendKey = ValueKey('dashboard.hero.safeToSpend');
const Key kTrendCardKey = ValueKey('dashboard.trend');
const Key kCategoryCardKey = ValueKey('dashboard.categories');
const Key kBudgetsCardKey = ValueKey('dashboard.budgets');
const Key kProjectsCardKey = ValueKey('dashboard.projects');
const Key kQuickEntriesCardKey = ValueKey('dashboard.quickEntries');
const Key kUpcomingCardKey = ValueKey('dashboard.upcoming');
const Key kAccountsCardKey = ValueKey('dashboard.accounts');
const Key kGroupsCardKey = ValueKey('dashboard.groups');
const Key kRecentCardKey = ValueKey('dashboard.recent');
