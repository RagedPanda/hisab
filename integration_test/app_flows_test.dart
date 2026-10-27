/// On-device UI flows for Hisab. Run with
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_flows_test.dart -d `<device>`
///
/// Tests 2..8 share one in-memory database so later flows (groups, dark mode,
/// Hindi, backup) have realistic data on screen; test 1 and 9 use their own.
///
/// iOS, flow 31 (reminders; numbered 24, 28, 29 and 30 before main merges): the flow
/// grants provisional notification authorization itself, which iOS does
/// silently on a simulator that has never been asked (`xcrun simctl privacy` cannot grant notifications). Manual step:
/// if Hisab's notifications were denied on the simulator before, uninstall the
/// app (`xcrun simctl uninstall <udid> com.sarv.hisab`) or erase the simulator
/// first, otherwise iOS keeps the denial and flow 31 fails its first expect.
/// Android, flow 32 (salary day, numbered 25 and 29 before): the notification permission must be granted
/// before the flow, or the Android 13+ system prompt covers the align dialog
/// (#86). The driver does this with
/// `adb shell pm grant com.sarv.hisab android.permission.POST_NOTIFICATIONS`;
/// with several devices attached, set `ANDROID_SERIAL` to the `-d` device.
/// Run another way, grant it by hand first. The flow checks it up front.
library;

import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, MethodCall, SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/format.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/data/debug/demo_plan.dart';
import 'package:hisab/data/debug/demo_seed.dart';
import 'package:hisab/domain/backup/backup_codec.dart';
import 'package:hisab/domain/categories/category_packs.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/features/upcoming/upcoming_calendar_screen.dart';
import 'package:hisab/domain/projects/project_math.dart';
import 'package:hisab/domain/salary/salary_schedule.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/split_calculator.dart';
import 'package:hisab/features/categories/categories_screen.dart';
import 'package:hisab/features/dashboard/dashboard_screen.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';
import 'package:hisab/features/groups/activity_screen.dart';
import 'package:hisab/features/groups/group_detail_screen.dart';
import 'package:hisab/features/reminders/reminder_startup.dart';
import 'package:hisab/features/groups/group_export.dart';
import 'package:hisab/features/groups/group_totals_screen.dart';
import 'package:hisab/features/groups/settle_up_sheet.dart';
import 'package:hisab/features/salary/salary_providers.dart';
import 'package:hisab/features/salary/salary_reminder.dart';
import 'package:hisab/features/salary/salary_setup_screen.dart';
import 'package:hisab/features/split/split_editor.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:hisab/l10n/category_names_hi.dart';
import 'package:hisab/l10n/generated/app_localizations_hi.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import 'harness.dart';
import 'recording_notification_gateway.dart';
import 'card_dues_flow.dart';
import 'sms_history_flow.dart';

const _milkTotalMinor = 20000; // 2 L @ 70 + 1 L @ 60
const _restaurantMinor = 125000;
const _salaryMinor = 5000000;
const _hdfcOpeningMinor = 1000000;
const _axisOpeningMinor = 500000;
const _overallBudgetMinor = 100000;

/// Entries seeded for the dashboard flow; enough that every card has data.
const kDashboardSeedEntries = 120;

int get _spentMinor => _milkTotalMinor + _restaurantMinor;

/// My share of the two Goa trip expenses (300 split three ways + 300 exact):
/// personal totals count only this share of a group expense (P2-1).
const _myGroupShareMinor = 10000 + 30000;
int get _hdfcBalanceMinor => _hdfcOpeningMinor - _restaurantMinor + _salaryMinor;
int get _totalBalanceMinor => _hdfcBalanceMinor + _axisOpeningMinor - _milkTotalMinor;

Finder _amountField() => find.descendant(of: find.byType(ExpenseEditorScreen), matching: find.byType(TextField)).first;
Finder _dialogField() => find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
Finder _chip(String label) => find.widgetWithText(ChoiceChip, label, skipOffstage: false);
Finder _filled(String label) => find.widgetWithText(FilledButton, label);
Finder _accountCardAmount(String name, String amount) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first,
  matching: find.text(amount),
);
Finder _entryAmount(String title, String amount) => find.descendant(of: find.widgetWithText(EntryTile, title), matching: find.text(amount));

/// Hero card caption, "Spent in October", for the month on screen.
String _spentIn(DateTime anchor, {String? locale}) => locale == null ? 'Spent in ${DateFormat('MMMM').format(anchor)}' : AppLocalizationsHi().spentInMonth(DateFormat('MMMM', locale).format(anchor));

/// What the hero shows for a database seeded by [seedDemoData] at [now]:
/// this month's planned expenses plus my 3,000 share of the Goa trip hotel.
int _expectedSeededSpend(DateTime now, {required int entryCount}) {
  final range = monthRange(now);
  final hotelDate = now.subtract(const Duration(days: 3));
  final planned = planDemoEntries(count: entryCount, now: now).where((item) => item.kind == 'expense' && range.contains(item.occurredAt)).fold(0, (sum, item) => sum + item.amountMinor);
  return planned + (range.contains(hotelDate) ? 300000 : 0) + _sliceTopUpKeys.length * _sliceTopUpMinor;
}

/// One child in each of six parent categories. The demo plan spreads entries
/// by date, so on many days (2026-10-24 among them) this month touches five
/// or fewer parents and the donut has no "Others" slice; these make it six.
const _sliceTopUpKeys = ['cab_auto', 'electricity', 'medicines', 'clothing', 'movies', 'salon'];
const _sliceTopUpMinor = 10000;

/// Adds a small expense in each of [_sliceTopUpKeys] at the start of [now]'s
/// month, so the dashboard donut always draws the top five plus "Others".
Future<void> _seedSliceTopUp(AppDatabase db, DateTime now) async {
  final categories = await db.select(db.categories).get();
  final entries = EntriesRepository(db);
  for (final key in _sliceTopUpKeys) {
    final categoryId = categories.firstWhere((category) => category.seedKey == key).id;
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: _sliceTopUpMinor, occurredAt: monthRange(now).start, categoryId: categoryId, payee: 'Top-up'));
  }
}

/// The summary card headline; the same figure also appears in the donut centre
/// and account cards, so it is read through its key rather than by text.
Future<void> _expectSpent(WidgetTester tester, String amount, {String? reason}) async {
  // The home list keeps its scroll offset between tests, so bring the hero back on stage first.
  await scrollTo(tester, find.byKey(kSummarySpentKey), up: true);
  String shown() => tester.widget<Text>(find.byKey(kSummarySpentKey)).data ?? '';
  // The ledger stream delivers asynchronously and the headline tweens to the new value over 300 ms.
  var waited = 0;
  while (shown() != amount && waited < 40) {
    await tester.pump(const Duration(milliseconds: 100));
    waited++;
  }
  if (waited > 0) debugPrint('SPENT-DIAG waited ${waited * 100}ms for $amount');
  expect(shown(), amount, reason: reason);
}

Future<void> _pickCategory(WidgetTester tester, String query, String name) async {
  await tapText(tester, 'Uncategorised');
  await enterText(tester, find.widgetWithText(TextField, 'Search categories'), query);
  await tapText(tester, name);
}

Future<void> _addItem(WidgetTester tester, {required String name, required String qty, required String price}) async {
  await tapText(tester, 'Add item');
  await enterText(tester, find.widgetWithText(TextField, 'Item name').last, name);
  await enterText(tester, find.widgetWithText(TextField, 'Qty').last, qty);
  await enterText(tester, find.ancestor(of: find.textContaining('Price per').last, matching: find.byType(TextField)).first, price);
}

/// Logs where the Save bar sits relative to the software keyboard so the
/// report can tell whether the keyboard covers it (grep KEYBOARD-DIAG).
void _logKeyboardGeometry(WidgetTester tester, Finder saveButton) {
  final editorContext = tester.element(find.byType(ExpenseEditorScreen));
  final insetsSeenByWidgets = MediaQuery.viewInsetsOf(editorContext).bottom;
  final rawView = ui.PlatformDispatcher.instance.implicitView!;
  final insetsFromEngine = rawView.viewInsets.bottom / rawView.devicePixelRatio;
  final screenHeight = rawView.physicalSize.height / rawView.devicePixelRatio;
  final saveBottom = tester.getRect(saveButton).bottom;
  debugPrint('KEYBOARD-DIAG widgetsInset=$insetsSeenByWidgets engineInset=$insetsFromEngine saveBottom=$saveBottom screenHeight=$screenHeight');
}

Future<void> _saveEntry(WidgetTester tester, String expectedLabel) async {
  final button = find.widgetWithText(FilledButton, 'Save $expectedLabel');
  expect(button, findsOneWidget, reason: 'save button should show the computed total');
  _logKeyboardGeometry(tester, button);
  await tapFinder(tester, button, frames: 12);
}

/// Bottom-sheet forms lazily build their Save button below the fold.
Future<void> _saveSheet(WidgetTester tester) async {
  await scrollTo(tester, _filled('Save'), within: find.byType(BottomSheet));
  await tapFinder(tester, _filled('Save'), frames: 10);
}

Future<void> _createAccount(WidgetTester tester, {required String name, required String balance, bool includeInTotal = true, String? screenshot}) async {
  await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Account'));
  expect(find.text('New account'), findsOneWidget);
  await enterText(tester, find.widgetWithText(TextField, 'Name'), name);
  await enterText(tester, find.widgetWithText(TextField, 'Current balance'), balance);
  if (!includeInTotal) await tapFinder(tester, find.byType(Switch));
  if (screenshot != null) await shoot(tester, screenshot);
  await tapFinder(tester, _filled('Save'));
}

/// Settle-up row that still offers "Record payment" for [transferLine].
Finder _pendingTransfer(String transferLine) => find.ancestor(of: find.text('Record payment'), matching: find.widgetWithText(ListTile, transferLine));

Future<void> _recordPayment(WidgetTester tester, String transferLine) async {
  final tile = _pendingTransfer(transferLine).first;
  await tapFinder(tester, find.descendant(of: tile, matching: find.text('Record payment')));
  expect(find.text('Record payment'), findsWidgets);
  await tapFinder(tester, _filled('Save payment'), frames: 12);
}

Finder _splitField(String memberLabel) => find.descendant(
  of: find
      .ancestor(
        of: find.descendant(of: find.byType(SplitEditor), matching: find.text(memberLabel)),
        matching: find.byType(Row),
      )
      .first,
  matching: find.byType(TextFormField),
);

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late AppHandle shared;
  late String groupId;
  final launchedLinks = <Uri>[];
  var linksOpen = true;

  // No UPI app on a simulator: the fake launcher records the link and says it opened.
  setUpAll(
    () async => shared = await createApp(
      overrides: [
        linkLauncherProvider.overrideWithValue((uri) async {
          launchedLinks.add(uri);
          return linksOpen;
        }),
      ],
    ),
  );
  tearDownAll(() => shared.container.dispose());

  testWidgets('01 home shows the empty state with the seeded Cash account', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    await pumpApp(tester, fresh);
    expect(find.text('Hisab'), findsOneWidget);
    expect(find.text(_spentIn(DateTime.now())), findsOneWidget);
    await _expectSpent(tester, '₹0');
    await scrollTo(tester, find.text('Cash'));
    expect(find.text('Cash'), findsOneWidget);
    await scrollTo(tester, find.text('No entries yet'));
    expect(find.text('No entries yet'), findsOneWidget);
    await shoot(tester, 'home_empty');
    await goTab(tester, 'Entries');
    expect(find.text('Nothing here yet'), findsOneWidget);
    await shoot(tester, 'entries_empty');
    await goTab(tester, 'Groups');
    expect(find.text('Split bills with friends'), findsOneWidget);
    await shoot(tester, 'groups_empty');
  });

  testWidgets('02 accounts: create two bank accounts', (tester) async {
    await pumpApp(tester, shared);
    await tapText(tester, 'Account');
    expect(find.text('Accounts'), findsOneWidget);
    await shoot(tester, 'accounts_initial');
    await _createAccount(tester, name: 'HDFC Savings', balance: '10000', screenshot: 'account_form');
    expect(find.text('HDFC Savings'), findsOneWidget);
    expect(find.text(formatMinor(_hdfcOpeningMinor)), findsOneWidget);
    await _createAccount(tester, name: 'Axis Bank', balance: '5000');
    expect(find.text('Axis Bank'), findsOneWidget);
    expect(find.text(formatMinor(_axisOpeningMinor)), findsOneWidget);
    await shoot(tester, 'accounts_list');
    await goBack(tester);
    expect(find.text(formatMinor(_hdfcOpeningMinor + _axisOpeningMinor, showDecimals: false)), findsOneWidget, reason: 'Balances header = Cash 0 + HDFC + Axis');
  });

  testWidgets('03 expense with line items, category, account and date picker', (tester) async {
    await pumpApp(tester, shared);
    await tapFinder(tester, find.byType(FloatingActionButton));
    expect(find.text('New entry'), findsOneWidget);
    await shoot(tester, 'entry_new');
    await tapText(tester, 'Uncategorised');
    await shoot(tester, 'category_picker');
    await enterText(tester, find.widgetWithText(TextField, 'Search categories'), 'milk');
    await tapText(tester, 'Milk & Dairy');
    expect(find.text('Milk & Dairy'), findsOneWidget);
    await openMoreDetails(tester, reveals: find.text('Add item'));
    await _addItem(tester, name: 'Buffalo milk', qty: '2', price: '70');
    await _addItem(tester, name: 'Cow milk', qty: '1', price: '60');
    await shoot(tester, 'entry_items');
    await scrollTo(tester, find.text('Total of 2 items'), within: find.byType(ExpenseEditorScreen), up: true);
    expect(find.text('Total of 2 items'), findsOneWidget);
    expect(tester.widget<TextField>(_amountField()).readOnly, isTrue, reason: 'amount is derived from items');
    await pickEditorAccount(tester, 'Cash');
    await tapFinder(tester, find.byIcon(Icons.calendar_today_outlined));
    await shoot(tester, 'date_picker');
    await tapText(tester, 'OK');
    await tapFinder(tester, find.byIcon(Icons.schedule));
    await shoot(tester, 'time_picker');
    await tapText(tester, 'OK');
    await scrollTo(tester, find.text('Paid to / received from'), within: find.byType(ExpenseEditorScreen));
    await enterText(tester, find.widgetWithText(TextField, 'Paid to / received from'), 'Mother Dairy');
    await shoot(tester, 'entry_filled');
    await _saveEntry(tester, formatMinor(_milkTotalMinor));
    await scrollTo(tester, find.text('Mother Dairy'));
    expect(find.text('Mother Dairy'), findsOneWidget);
    expect(_entryAmount('Mother Dairy', '-${formatMinor(_milkTotalMinor)}'), findsOneWidget);
    await scrollTo(tester, find.byKey(kSummarySpentKey), up: true);
    await _expectSpent(tester, formatMinor(_milkTotalMinor), reason: 'summary card spent amount');
    await shoot(tester, 'home_after_expense');
  });

  testWidgets('04 plain expense, income, dashboard totals and entries list', (tester) async {
    await pumpApp(tester, shared);
    await tapFinder(tester, find.byType(FloatingActionButton));
    await _pickCategory(tester, 'restaurants', 'Restaurants & Cafes');
    await enterText(tester, _amountField(), '1250');
    await pickEditorAccount(tester, 'HDFC Savings');
    await _saveEntry(tester, formatMinor(_restaurantMinor));

    await tapFinder(tester, find.byType(FloatingActionButton));
    await tapText(tester, 'Income');
    await _pickCategory(tester, 'salary', 'Salary');
    await enterText(tester, _amountField(), '50000');
    await pickEditorAccount(tester, 'HDFC Savings');
    await shoot(tester, 'entry_income');
    await _saveEntry(tester, formatMinor(_salaryMinor));

    await _expectSpent(tester, formatMinor(_spentMinor), reason: 'Spent this month');
    expect(find.text(formatMinor(_salaryMinor, showDecimals: false)), findsOneWidget, reason: 'Income stat');
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text(formatMinor(_salaryMinor - _spentMinor, showDecimals: false)), findsOneWidget, reason: 'Saved stat');
    expect(find.text('Spending by category'), findsOneWidget);
    await shoot(tester, 'home_totals');
    await scrollTo(tester, find.text('Accounts'));
    expect(find.text(formatMinor(_totalBalanceMinor, showDecimals: false)), findsOneWidget, reason: 'Accounts header total');
    expect(_accountCardAmount('Cash', formatMinor(-_milkTotalMinor, showDecimals: false)), findsOneWidget, reason: 'Cash card went negative');
    expect(find.text(formatMinor(_hdfcBalanceMinor, showDecimals: false)), findsOneWidget, reason: 'HDFC card');
    await shoot(tester, 'home_accounts');

    await goTab(tester, 'Entries');
    expect(find.text('Today'), findsOneWidget);
    expect(find.text(formatMinor(_spentMinor)), findsOneWidget, reason: 'day total');
    expect(find.text('Salary'), findsOneWidget);
    await shoot(tester, 'entries_list');
    await tapFinder(tester, _chip('Income'));
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Mother Dairy'), findsNothing);
    await tapFinder(tester, _chip('All'));
    await enterText(tester, find.widgetWithText(TextField, 'Search payee, note, item or category'), 'cow');
    expect(find.text('Mother Dairy'), findsOneWidget, reason: 'search matches item names');
    expect(find.text('Salary'), findsNothing);
    await shoot(tester, 'entries_search');
    await tapFinder(tester, find.byIcon(Icons.clear));
    await goTab(tester, 'Home');
  });

  testWidgets('05 month navigation', (tester) async {
    await pumpApp(tester, shared);
    // Later tests share this app and expect the current month, whatever happens here.
    addTearDown(() => shared.container.read(selectedMonthProvider.notifier).reset());
    final now = DateTime.now();
    final previous = DateFormat('MMMM yyyy').format(DateTime(now.year, now.month - 1, 15));
    final current = DateFormat('MMMM yyyy').format(now);
    expect(find.text(current), findsOneWidget);
    await tapFinder(tester, find.byIcon(Icons.chevron_left));
    expect(find.text(previous), findsOneWidget);
    await _expectSpent(tester, '₹0', reason: 'previous month has no spend');
    await shoot(tester, 'home_previous_month');
    await scrollTo(tester, find.text('No entries this month'));
    expect(find.text('No entries this month'), findsOneWidget);
    await scrollTo(tester, find.byIcon(Icons.chevron_right), up: true);
    await tapFinder(tester, find.byIcon(Icons.chevron_right));
    expect(find.text(current), findsOneWidget);
    await _expectSpent(tester, formatMinor(_spentMinor));
  });

  testWidgets('06 budgets: overall budget is exceeded, category budget has room', (tester) async {
    await pumpApp(tester, shared);
    await goTab(tester, 'Settings');
    await scrollTo(tester, find.text('Budgets'));
    await tapText(tester, 'Budgets');
    expect(find.text('No budgets yet'), findsOneWidget);
    await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Budget'));
    await shoot(tester, 'budget_kind_sheet');
    await tapText(tester, 'Overall monthly budget');
    await enterText(tester, _dialogField(), '1000');
    await tapFinder(tester, _filled('Save'));
    expect(find.text('Overall'), findsOneWidget);
    await waitFor(tester, find.textContaining('Over ${formatMinor(_overallBudgetMinor, showDecimals: false)} by '));

    await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Budget'));
    await tapText(tester, 'Budget for a category');
    await enterText(tester, find.widgetWithText(TextField, 'Search categories'), 'milk');
    await tapText(tester, 'Milk & Dairy');
    await enterText(tester, _dialogField(), '2000');
    await tapFinder(tester, _filled('Save'));
    expect(find.text('Milk & Dairy'), findsOneWidget);
    await shoot(tester, 'budgets_list');

    await goBack(tester);
    await goTab(tester, 'Home');
    await scrollTo(tester, find.text('Budgets'));
    expect(find.text('Over ${formatMinor(_overallBudgetMinor, showDecimals: false)} by ${formatMinor(_spentMinor - _overallBudgetMinor, showDecimals: false)}'), findsOneWidget);
    expect(find.textContaining('${formatMinor(200000 - _milkTotalMinor, showDecimals: false)} of ${formatMinor(200000, showDecimals: false)} left · '), findsOneWidget);
    await shoot(tester, 'home_budget_over');
  });

  testWidgets('07 edit an itemised entry, then add and delete a throwaway entry', (tester) async {
    await pumpApp(tester, shared);
    await scrollTo(tester, find.text('Mother Dairy'));
    await tapText(tester, 'Mother Dairy');
    expect(find.text('Edit entry'), findsOneWidget);
    expect(find.text('Buffalo milk'), findsOneWidget);
    expect(find.text('Cow milk'), findsOneWidget);
    expect(find.text('Save ${formatMinor(_milkTotalMinor)}'), findsOneWidget);
    await shoot(tester, 'entry_edit');
    await goBack(tester);

    await tapFinder(tester, find.byType(FloatingActionButton));
    await _pickCategory(tester, 'groceries', 'Groceries');
    await enterText(tester, _amountField(), '10');
    await pickEditorAccount(tester, 'Cash');
    await _saveEntry(tester, formatMinor(1000));
    await scrollTo(tester, find.text(_spentIn(DateTime.now())), up: true);
    await _expectSpent(tester, formatMinor(_spentMinor + 1000));
    await scrollTo(tester, find.text('Groceries'));
    await tapText(tester, 'Groceries');
    await tapFinder(tester, find.byIcon(Icons.delete_outline));
    expect(find.text('Delete this entry?'), findsOneWidget);
    await shoot(tester, 'entry_delete_confirm');
    await tapFinder(tester, _filled('Delete'), frames: 12);
    await scrollTo(tester, find.text(_spentIn(DateTime.now())), up: true);
    await _expectSpent(tester, formatMinor(_spentMinor), reason: 'totals restored after delete');
    await scrollTo(tester, find.text('Accounts'));
    expect(_accountCardAmount('Cash', formatMinor(-_milkTotalMinor, showDecimals: false)), findsOneWidget, reason: 'Cash balance restored after delete');
  });

  testWidgets('08 groups: 3 members, equal + exact splits, simplified debts, settle up', (tester) async {
    await pumpApp(tester, shared);
    await goTab(tester, 'Groups');
    await tapText(tester, 'New group');
    await enterText(tester, find.widgetWithText(TextField, 'Group name'), 'Goa trip');
    await enterText(tester, find.widgetWithText(TextField, 'Members (comma separated)'), 'Rahul, Priya');
    await shoot(tester, 'group_form');
    await tapFinder(tester, _filled('Create group'), frames: 12);
    expect(find.text('Goa trip'), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);
    await shoot(tester, 'group_detail_empty');
    groupId = (await shared.db.select(shared.db.groups).getSingle()).id;
    final members = await shared.read(groupsRepositoryProvider).getMembers(groupId);
    expect(members.map((m) => m.name), containsAll(['You', 'Rahul', 'Priya']));

    // Expense 1: 300 paid by me, equal split.
    await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Add expense'));
    expect(find.text('Group expense'), findsOneWidget);
    await _pickCategory(tester, 'restaurants', 'Restaurants & Cafes');
    await enterText(tester, _amountField(), '300');
    await scrollTo(tester, find.text('Splits ${formatMinor(30000)} across 3 people'), within: find.byType(ExpenseEditorScreen));
    await shoot(tester, 'group_split_equal');
    await _saveEntry(tester, formatMinor(30000));
    expect(find.textContaining('You paid ${formatMinor(30000)}'), findsOneWidget);
    expect(find.text('you lent'), findsOneWidget);
    expect(find.text(formatMinor(20000)), findsOneWidget, reason: 'I lent the other two their shares');

    // Expense 2: 500 paid by Rahul, exact amounts Me 300 / Rahul 100 / Priya 100.
    await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Add expense'));
    await _pickCategory(tester, 'hotels', 'Hotels & Stays');
    await enterText(tester, _amountField(), '500');
    await scrollTo(tester, find.text('Paid by'), within: find.byType(ExpenseEditorScreen));
    await tapFinder(tester, _chip('Rahul'));
    expect(tester.widget<ChoiceChip>(_chip('Rahul')).selected, isTrue, reason: 'Rahul selected as payer');
    await shoot(tester, 'group_paid_by');
    await scrollTo(tester, find.text('Split'), within: find.byType(ExpenseEditorScreen));
    await tapFinder(tester, _chip('Exact amounts'));
    await enterText(tester, _splitField('You'), '300');
    await enterText(tester, _splitField('Rahul'), '100');
    await enterText(tester, _splitField('Priya'), '100');
    expect(find.text('Splits ${formatMinor(50000)} across 3 people'), findsOneWidget);
    await shoot(tester, 'group_split_exact');
    await _saveEntry(tester, formatMinor(50000));
    final savedEntries = await shared.read(groupsRepositoryProvider).getGroupEntries(groupId);
    expect(savedEntries, hasLength(2));
    expect(savedEntries.map((pair) => pair.$1.paidByMemberId).toSet(), hasLength(2), reason: 'second expense paid by a different member');
    expect(find.textContaining('Rahul paid ${formatMinor(50000)}'), findsOneWidget);
    expect(find.text('you borrowed'), findsOneWidget);
    expect(find.text(formatMinor(30000)), findsOneWidget, reason: 'my exact share of the stay');
    await shoot(tester, 'group_expenses');

    // Expected balances straight from the domain layer.
    final entries = await shared.read(groupsRepositoryProvider).getGroupEntries(groupId);
    final ledger = [
      for (final (entry, splits, _) in entries) LedgerExpense(paidByMemberId: entry.paidByMemberId!, shares: [for (final s in splits) SplitShare(s.memberId, s.amountMinor)]),
    ];
    final net = computeNetBalances(memberIds: members.map((m) => m.id), expenses: ledger, settlements: const []);
    final nameOf = {for (final m in members) m.id: m.isMe ? 'You' : m.name};
    final me = members.singleWhere((m) => m.isMe).id;
    final rahul = members.singleWhere((m) => m.name == 'Rahul').id;
    final priya = members.singleWhere((m) => m.name == 'Priya').id;
    expect(net, {me: -10000, rahul: 30000, priya: -20000});
    final suggested = simplifyDebts(net);
    expect(suggested, hasLength(2));

    await tapText(tester, 'Balances', frames: 16);
    await shoot(tester, 'group_balances_tab');
    // Known to fail: GroupsRepository.watchBalances nests asyncExpand over never-ending
    // drift streams, so the Balances tab keeps the snapshot taken when the screen first
    // opened (no expenses) and shows everyone as settled.
    expect(find.text('owes ${formatMinor(10000)}'), findsOneWidget, reason: 'You owe 100 (Balances tab must reflect the two expenses just added)');
    expect(find.text('gets back ${formatMinor(30000)}'), findsOneWidget, reason: 'Rahul gets back 300');
    expect(find.text('owes ${formatMinor(20000)}'), findsOneWidget, reason: 'Priya owes 200');
    expect(find.text('Settle up (simplified)'), findsOneWidget);
    for (final transfer in suggested) {
      final line = '${nameOf[transfer.from]} → ${nameOf[transfer.to]}';
      final tile = find.ancestor(of: find.text(line), matching: find.byType(ListTile)).first;
      expect(
        find.descendant(of: tile, matching: find.text(formatMinor(transfer.amountMinor))),
        findsOneWidget,
        reason: 'suggested transfer $line',
      );
    }
    await shoot(tester, 'group_balances');

    await tapText(tester, 'Members');
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Rahul'), findsOneWidget);
    expect(find.text('Priya'), findsOneWidget);
    await shoot(tester, 'group_members');

    await tapText(tester, 'Rahul');
    expect(find.text('Edit member'), findsOneWidget);
    await enterText(tester, find.widgetWithText(TextField, 'Phone (optional)'), '98765 43210');
    await enterText(tester, find.widgetWithText(TextField, 'UPI ID (optional)'), 'rahul');
    expect(find.text('Enter a UPI ID like name@bank'), findsOneWidget);
    expect(tester.widget<FilledButton>(_filled('Save')).onPressed, isNull, reason: 'an invalid UPI ID blocks saving');
    await enterText(tester, find.widgetWithText(TextField, 'UPI ID (optional)'), 'Rahul.K@okicici');
    await shoot(tester, 'member_sheet');
    await _saveSheet(tester);
    expect(find.text('98765 43210 · rahul.k@okicici'), findsOneWidget, reason: 'the UPI ID is stored normalised');

    await tapText(tester, 'Balances');
    await _recordPayment(tester, 'Priya → Rahul');
    expect(_pendingTransfer('Priya → Rahul'), findsNothing);
    expect(_pendingTransfer('You → Rahul'), findsOneWidget);
    expect(find.text('Settled payments'), findsOneWidget, reason: 'recorded payments are listed under Settle up');

    const youOweRahul = 10000;
    await tapFinder(tester, find.descendant(of: _pendingTransfer('You → Rahul'), matching: find.text('Pay')), frames: 12);
    expect(find.text('Pay Rahul'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget, reason: 'Rahul has a phone number');
    await shoot(tester, 'pay_sheet');
    linksOpen = false;
    await tapFinder(tester, _filled('Pay with UPI'), frames: 12);
    expect(find.text('No UPI app on this phone. Pay another way, then record it.'), findsOneWidget, reason: 'the failure shows inside the sheet');
    expect(find.text('Did the payment go through?'), findsNothing);
    linksOpen = true;
    launchedLinks.clear();
    await tapFinder(tester, _filled('Pay with UPI'), frames: 12);
    final upiLink = launchedLinks.single;
    expect(upiLink.scheme, 'upi');
    expect(upiLink.queryParameters['pa'], 'rahul.k@okicici');
    expect(upiLink.queryParameters['am'], (youOweRahul / 100).toStringAsFixed(2));
    expect(find.text('Did the payment go through?'), findsOneWidget);
    await tapFinder(tester, find.widgetWithText(FilledButton, 'Yes, record it'), frames: 12);
    expect(find.text('Everyone is settled up. Nothing to remind or pay.'), findsOneWidget);
    expect(find.text('settled'), findsNWidgets(3));
    await shoot(tester, 'group_settled');
    await tapText(tester, 'Expenses');
    // Everyone is square, so the tab opens on Unsettled with history folded away.
    expect(find.text('All settled up. New expenses will show here.'), findsOneWidget);
    expect(find.textContaining('Settled up to'), findsOneWidget);
    expect(find.text('Priya paid Rahul'), findsNothing);
    await shoot(tester, 'group_expenses_settled');
    await tapText(tester, 'Show 4 older entries');
    expect(find.text('Priya paid Rahul'), findsOneWidget);
    expect(find.text('You paid Rahul'), findsOneWidget);
    await tapText(tester, 'Mine');
    expect(find.text('Priya paid Rahul'), findsNothing, reason: 'Mine hides payments between other people');
    expect(find.text('You paid Rahul'), findsOneWidget);
    await shoot(tester, 'group_expenses_mine');
    await goBack(tester);
    expect(find.text('Goa trip'), findsOneWidget);
    expect(find.text('3 members · ${formatMinor(80000, showDecimals: false)} spent'), findsOneWidget);
    await shoot(tester, 'groups_list');
    await goTab(tester, 'Home');
    await _expectSpent(tester, formatMinor(_spentMinor + _myGroupShareMinor), reason: 'only my share of group expenses counts as personal spend');
  });

  testWidgets('09 categories: add, rename, delete a custom category', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    await pumpApp(tester, fresh);
    await goTab(tester, 'Settings');
    await scrollTo(tester, find.text('Categories'));
    await tapText(tester, 'Categories');
    expect(find.text('Food & Dining'), findsOneWidget);
    await shoot(tester, 'categories_list');
    await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Category'));
    expect(find.text('New category'), findsOneWidget);
    await enterText(tester, find.widgetWithText(TextField, 'Name'), 'Chai');
    await shoot(tester, 'category_form');
    await _saveSheet(tester);
    await scrollTo(tester, find.text('Chai'), within: find.byType(CategoriesScreen));
    expect(find.text('Chai'), findsOneWidget);

    Finder menuFor(String name) => find.descendant(
      of: find.ancestor(of: find.text(name), matching: find.byType(ExpansionTile)).first,
      matching: find.byType(PopupMenuButton<String>),
    );
    await tapFinder(tester, menuFor('Chai'));
    expect(find.text('Delete'), findsOneWidget, reason: 'custom categories can be deleted');
    await tapText(tester, 'Edit');
    expect(find.text('Edit Chai'), findsOneWidget);
    await enterText(tester, find.widgetWithText(TextField, 'Name'), 'Chai & Snacks');
    await _saveSheet(tester);
    await scrollTo(tester, find.text('Chai & Snacks'), within: find.byType(CategoriesScreen));
    expect(find.text('Chai'), findsNothing);
    await shoot(tester, 'category_renamed');

    await tapFinder(tester, menuFor('Chai & Snacks'));
    await tapText(tester, 'Delete');
    expect(find.text('Delete Chai & Snacks?'), findsOneWidget);
    await tapFinder(tester, _filled('Delete'));
    expect(find.text('Chai & Snacks'), findsNothing);

    await scrollTo(tester, find.text('Food & Dining'), within: find.byType(CategoriesScreen), up: true);
    await tapFinder(tester, menuFor('Food & Dining'));
    expect(find.text('Delete'), findsNothing, reason: 'seeded categories can only be archived');
    await tapText(tester, 'Archive (hide from picker)');
    await tapText(tester, 'Income');
    expect(find.text('Salary'), findsOneWidget);
    await shoot(tester, 'categories_income');
  });

  // iOS only: Android offers SMS reading on this screen, so the flow is skipped there.
  testWidgets('10 bank SMS screen on iOS: reading disabled, paste auto-adds with Undo, unclear SMS wait for review', (tester) async {
    await pumpApp(tester, shared);
    await goTab(tester, 'Settings');
    await shoot(tester, 'settings');
    await scrollTo(tester, find.text('Bank SMS'));
    await tapText(tester, 'Bank SMS');
    await waitFor(tester, find.text('Not available on iOS. Use the Shortcut or paste below.'));
    expect(find.text('Not available on iOS. Use the Shortcut or paste below.'), findsOneWidget);
    final readSwitch = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Read bank SMS automatically'));
    expect(readSwitch.onChanged, isNull, reason: 'SMS reading must be disabled on iOS');
    expect(readSwitch.value, isFalse);
    expect(find.text('Scan inbox now'), findsNothing);
    await shoot(tester, 'sms_ios');
    await tapText(tester, 'Paste an SMS');
    await enterText(tester, _dialogField(), 'Rs.500.00 debited from A/c XX1234 on 20-Oct-25 to merchant@upi (UPI Ref No 123456789012)');
    await tapFinder(tester, _filled('Save'), frames: 12);
    expect(find.text('Transaction added.'), findsOneWidget, reason: 'auto-add is on by default and this SMS names the account');
    await waitFor(tester, find.textContaining('Added ${formatMinor(50000, showDecimals: false)} from SMS'));
    await shoot(tester, 'sms_auto_added_undo');
    await tapText(tester, 'Undo', frames: 12);
    expect(find.text('To review (0)'), findsOneWidget, reason: 'Undo ignores the SMS; it does not come back for review');
    await shoot(tester, 'sms_after_undo');

    await tapText(tester, 'Paste an SMS');
    await enterText(tester, _dialogField(), 'Paid Rs 250 to Ramesh');
    await tapFinder(tester, _filled('Save'), frames: 12);
    expect(find.text('Transaction found. Review it below.'), findsOneWidget, reason: 'no bank or account: not confident enough to add alone');
    expect(find.text('To review (1)'), findsOneWidget);
    final accountNames = (await shared.read(accountsRepositoryProvider).getAll()).map((a) => a.name).toList();
    debugPrint('SMS-DIAG accounts after undo and an unclear SMS: $accountNames');
    await goBack(tester);
    await goTab(tester, 'Home');
    await waitFor(tester, find.text('1 SMS to review'));
    await shoot(tester, 'sms_home_review_row');
    await tapText(tester, '1 SMS to review');
    expect(find.text('SMS to review'), findsWidgets);
    expect(find.text('Add ${formatMinor(25000, showDecimals: false)}'), findsOneWidget);
    await shoot(tester, 'sms_review_queue');
    await tapText(tester, 'Ignore');
    expect(find.text('Nothing waiting'), findsOneWidget);
    await goBack(tester);
  }, skip: !Platform.isIOS);

  testWidgets('11 settings: dark theme on every tab', (tester) async {
    addTearDown(() => shared.read(settingsProvider.notifier).update((s) => s.copyWith(themeMode: ThemeMode.light)));
    await pumpApp(tester, shared);
    await goTab(tester, 'Settings');
    await tapText(tester, 'Dark');
    expect(Theme.of(tester.element(find.byType(NavigationBar))).brightness, Brightness.dark);
    await shoot(tester, 'dark_settings');
    await goTab(tester, 'Home');
    await shoot(tester, 'dark_home');
    await goTab(tester, 'Entries');
    await shoot(tester, 'dark_entries');
    await goTab(tester, 'Groups');
    await shoot(tester, 'dark_groups');
    await tapText(tester, 'Goa trip');
    await shoot(tester, 'dark_group_detail');
    await goBack(tester);
    await goTab(tester, 'Home');
    await tapFinder(tester, find.byType(FloatingActionButton));
    await tapText(tester, 'Uncategorised');
    await shoot(tester, 'dark_category_picker');
    await enterText(tester, find.widgetWithText(TextField, 'Search categories'), 'groceries');
    await tapText(tester, 'Groceries');
    await shoot(tester, 'dark_entry');
    await discardEntry(tester);
    await goTab(tester, 'Settings');
    await tapText(tester, 'Light');
    expect(Theme.of(tester.element(find.byType(NavigationBar))).brightness, Brightness.light);
  });

  testWidgets('12 settings: Hindi on every tab', (tester) async {
    final hi = AppLocalizationsHi();
    addTearDown(() => shared.read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: 'en')));
    await pumpApp(tester, shared);
    await goTab(tester, 'Settings');
    await tapText(tester, 'Language');
    expect(find.text('हिन्दी'), findsOneWidget);
    await shoot(tester, 'language_dialog');
    await tapText(tester, 'हिन्दी', frames: 12);
    expect(find.text(hi.settings), findsWidgets);
    for (final tab in [hi.tabHome, hi.tabEntries, hi.tabGroups, hi.tabSettings]) {
      expect(
        find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)),
        findsOneWidget,
        reason: 'tab $tab',
      );
    }
    await shoot(tester, 'hi_settings');
    await scrollTo(tester, find.text(hi.about));
    await shoot(tester, 'hi_settings_bottom');
    await goTab(tester, hi.tabHome);
    await scrollTo(tester, find.text(_spentIn(DateTime.now(), locale: 'hi')), up: true);
    expect(find.text(_spentIn(DateTime.now(), locale: 'hi')), findsOneWidget);
    await _expectSpent(tester, formatMinor(_spentMinor + _myGroupShareMinor));
    await shoot(tester, 'hi_home');
    await scrollTo(tester, find.text(hi.recent));
    await shoot(tester, 'hi_home_bottom');
    await goTab(tester, hi.tabEntries);
    expect(find.text(hi.today), findsOneWidget);
    await shoot(tester, 'hi_entries');
    await goTab(tester, hi.tabGroups);
    await shoot(tester, 'hi_groups');
    await tapText(tester, 'Goa trip');
    await tapText(tester, hi.balances);
    await shoot(tester, 'hi_group_balances');
    await goBack(tester);
    await goTab(tester, hi.tabHome);
    await tapFinder(tester, find.byType(FloatingActionButton));
    expect(find.text(hi.newEntry), findsOneWidget);
    await tapText(tester, hi.uncategorised);
    await shoot(tester, 'hi_category_picker');
    expect(find.text('Food & Dining'), findsNothing, reason: 'seeded category names are translated');
    expect(find.text(hindiCategoryNames['food']!), findsOneWidget);
    await enterText(tester, find.widgetWithText(TextField, hi.searchCategories), 'groceries');
    await tapText(tester, hindiCategoryNames['groceries']!);
    await openMoreDetails(tester, reveals: find.text(hi.addItem));
    await tapText(tester, hi.addItem);
    await shoot(tester, 'hi_entry');
    await discardEntry(tester);
    await goTab(tester, hi.tabSettings);
    await scrollTo(tester, find.text(hi.language), up: true);
    await tapText(tester, hi.language);
    await tapText(tester, 'English', frames: 12);
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Settings')), findsOneWidget);
  });

  testWidgets('13 backup: passphrase validation in UI and an in-process export/restore round trip', (tester) async {
    await pumpApp(tester, shared);
    await goTab(tester, 'Settings');
    await scrollTo(tester, find.text('Export encrypted backup'));
    await tapText(tester, 'Export encrypted backup');
    expect(find.text('Backup passphrase'), findsOneWidget);
    await shoot(tester, 'backup_passphrase');
    await enterText(tester, _dialogField(), 'short');
    await tapFinder(tester, _filled('Save'));
    expect(find.text('Use at least 8 characters'), findsOneWidget, reason: 'short passphrase rejected, share sheet not opened');
    await shoot(tester, 'backup_passphrase_short');

    const passphrase = 'correct horse battery';
    final bytes = await shared.read(backupServiceProvider).exportEncrypted(passphrase);
    expect(bytes.length, greaterThan(100));
    final restoreDb = AppDatabase(NativeDatabase.memory());
    addTearDown(restoreDb.close);
    await expectLater(BackupService(restoreDb).importEncrypted(bytes, 'wrong passphrase'), throwsA(isA<BackupFormatException>()));
    final written = await BackupService(restoreDb).importEncrypted(bytes, passphrase);
    expect(written, greaterThan(0));
    final sourceEntries = await shared.db.select(shared.db.entries).get();
    final restoredEntries = await restoreDb.select(restoreDb.entries).get();
    expect(restoredEntries.map((e) => e.id).toSet(), sourceEntries.map((e) => e.id).toSet());
    final restoredAccounts = await restoreDb.select(restoreDb.accounts).get();
    expect(restoredAccounts.map((a) => a.name), containsAll(['HDFC Savings', 'Axis Bank']));
    final restoredMembers = await restoreDb.select(restoreDb.members).get();
    expect(restoredMembers.where((m) => m.groupId == groupId), hasLength(3));
  });

  testWidgets('14 accounts: the include-in-total switch applies to the account being created', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    await pumpApp(tester, fresh);
    await tapText(tester, 'Account');
    await _createAccount(tester, name: 'HDFC Savings', balance: '10000');
    // Alphabetically before 'Cash' and 'HDFC Savings', so it is not the last row of the list.
    await _createAccount(tester, name: 'Axis Bank', balance: '5000', includeInTotal: false, screenshot: 'account_form_excluded');
    await shoot(tester, 'accounts_excluded');
    final accounts = await fresh.read(accountsRepositoryProvider).getAll();
    expect(
      {for (final account in accounts) account.name: account.includeInTotal},
      {'Cash': true, 'HDFC Savings': true, 'Axis Bank': false},
      reason: 'the switch must apply to the account being created, not to whichever account sorts last',
    );
    final axisTile = find.ancestor(of: find.text('Axis Bank'), matching: find.byType(ListTile)).first;
    expect(find.descendant(of: axisTile, matching: find.textContaining('excluded from total')), findsOneWidget);
    await goBack(tester);
    await scrollTo(tester, find.text('Accounts'));
    expect(find.text(formatMinor(_hdfcOpeningMinor, showDecimals: false)), findsWidgets, reason: 'Accounts header = Cash 0 + HDFC 10,000; Axis excluded');
  });

  testWidgets('15 dashboard: every card renders from a seeded ledger and the hero matches the domain total', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final now = DateTime.now();
    await seedDemoData(fresh.db, entryCount: kDashboardSeedEntries, now: now);
    await _seedSliceTopUp(fresh.db, now);
    await pumpApp(tester, fresh);
    await settle(tester, 12);
    expect(find.text(_spentIn(now)), findsOneWidget);
    await _expectSpent(tester, formatMinor(_expectedSeededSpend(now, entryCount: kDashboardSeedEntries), showDecimals: false), reason: 'hero spend = planned expenses this month + my hotel share + slice top-up');
    expect(find.byKey(kHeroCardKey), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Daily avg'), findsOneWidget);
    await shoot(tester, 'dashboard_seeded_hero');
    await scrollTo(tester, find.byKey(kTrendCardKey));
    expect(find.text('Spending trend'), findsOneWidget);
    await tapText(tester, 'Monthly');
    expect(find.text(DateFormat('MMM').format(now)), findsWidgets, reason: 'monthly bars label the current month');
    await shoot(tester, 'dashboard_seeded_trend_monthly');
    await scrollTo(tester, find.byKey(kCategoryCardKey));
    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('Others'), findsOneWidget, reason: 'top 5 + Others with a seeded ledger');
    await scrollTo(tester, find.byKey(kBudgetsCardKey));
    expect(find.text('Overall'), findsOneWidget, reason: 'overall budget row comes first');
    await scrollTo(tester, find.byKey(kAccountsCardKey));
    expect(find.byKey(kUpcomingCardKey, skipOffstage: false), findsOneWidget, reason: 'the Upcoming card is keyed even while it shows its empty state');
    expect(find.text('HDFC Savings'), findsOneWidget);
    await scrollTo(tester, find.byKey(kGroupsCardKey));
    expect(find.text('Goa trip'), findsOneWidget);
    expect(find.text('You get ${formatMinor(600000, showDecimals: false)}'), findsOneWidget, reason: 'two friends owe 3,000 each');
    await scrollTo(tester, find.byKey(kRecentCardKey));
    expect(find.text('Recent'), findsOneWidget);
    expect(find.byType(EntryTile), findsWidgets);
    await shoot(tester, 'dashboard_seeded_bottom');
  });

  testWidgets('16 projects: create, add an entry, dashboard card, complete with undo, delete with undo, Hindi', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    const fuelMinor = 250000;
    const budgetMinor = 5000000;
    await pumpApp(tester, fresh);

    await goTab(tester, 'Settings');
    await scrollTo(tester, find.text('Projects'));
    await tapText(tester, 'Projects');
    expect(find.text('No projects yet'), findsOneWidget);
    await shoot(tester, 'projects_empty');

    await tapText(tester, 'Start a project');
    await tapText(tester, 'Blank project');
    await enterText(tester, find.widgetWithText(TextField, 'Project name'), 'Swift car');
    await enterText(tester, find.widgetWithText(TextField, 'Budget (optional)'), '50000');
    await shoot(tester, 'project_form');
    await tapFinder(tester, _filled('Save'), frames: 12);
    expect(find.text('Swift car'), findsWidgets, reason: 'saving opens the new project');
    expect(find.text('Nothing spent yet'), findsOneWidget);
    await shoot(tester, 'project_detail_empty');

    await tapText(tester, 'Add entry');
    await _pickCategory(tester, 'fuel', 'Fuel / Petrol / Diesel');
    await enterText(tester, _amountField(), '2500');
    await _saveEntry(tester, formatMinor(fuelMinor));
    await waitFor(tester, find.byType(EntryTile));
    expect(find.byType(EntryTile), findsOneWidget, reason: 'the entry is tagged to the project');
    expect(find.text(formatMinor(fuelMinor, showDecimals: false)), findsWidgets, reason: 'hero shows the spend');
    expect(find.text('${formatMinor(budgetMinor - fuelMinor, showDecimals: false)} of ${formatMinor(budgetMinor, showDecimals: false)} left · 1 entry'), findsOneWidget);
    expect(find.text('Spending by category'), findsOneWidget);
    await shoot(tester, 'project_detail');
    final stored = await fresh.db.select(fresh.db.entries).get();
    expect(stored.single.projectId, isNotNull);

    await goBack(tester);
    expect(find.text('Swift car'), findsOneWidget);
    expect(find.text('${formatMinor(fuelMinor, showDecimals: false)} spent'), findsOneWidget);
    await shoot(tester, 'projects_list');
    await goBack(tester);
    await goTab(tester, 'Home');
    await scrollTo(tester, find.byKey(kProjectsCardKey));
    expect(find.descendant(of: find.byKey(kProjectsCardKey), matching: find.text('Swift car')), findsOneWidget);
    await shoot(tester, 'dashboard_projects_card');
    await tapFinder(tester, find.byKey(kProjectsCardKey));
    expect(find.byType(BackButton), findsOneWidget, reason: 'the card opens the Projects screen');
    await tapText(tester, 'Swift car');

    await tapFinder(tester, find.byType(PopupMenuButton<VoidCallback>));
    await tapText(tester, 'Mark completed');
    expect(find.text('Completed'), findsOneWidget);
    await tapText(tester, 'Undo');
    await settle(tester, 6);
    expect(find.text('Active'), findsOneWidget, reason: 'undo restores the previous status');
    await tapFinder(tester, find.byType(PopupMenuButton<VoidCallback>));
    await tapText(tester, 'Mark completed');
    await settle(tester, 6);

    await tapFinder(tester, find.byType(PopupMenuButton<VoidCallback>));
    await tapText(tester, 'Delete project');
    await tapText(tester, 'Delete', last: true, frames: 12);
    expect(find.text('Project deleted'), findsOneWidget);
    await tapText(tester, 'Undo');
    await settle(tester, 6);
    expect(find.text('Swift car'), findsOneWidget, reason: 'undo brings the project back');
    expect(find.text('Completed'), findsWidgets, reason: 'completed projects get their own section');

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    expect(find.text(hi.projects), findsWidgets);
    await shoot(tester, 'hi_projects_list');
    await tapText(tester, 'Swift car');
    expect(find.text(hi.projectStatusCompleted), findsWidgets);
    expect(find.text(hi.spendingByCategory), findsOneWidget);
    await shoot(tester, 'hi_project_detail');
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });

  testWidgets('17 project templates: vehicle seeds its pack only when ticked, trip without, Hindi', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    await pumpApp(tester, fresh);
    Future<List<Category>> packCategories(String packKey) => (fresh.db.select(fresh.db.categories)..where((t) => t.packKey.equals(packKey))).get();

    await goTab(tester, 'Settings');
    await scrollTo(tester, find.text('Projects'));
    await tapText(tester, 'Projects');
    await tapText(tester, 'Start a project');
    expect(find.text('Start from a template'), findsOneWidget);
    await shoot(tester, 'project_templates');

    await tapText(tester, 'Vehicle');
    expect(find.widgetWithText(TextField, 'Vehicle'), findsOneWidget, reason: 'the template names the project');
    await scrollTo(tester, find.byKey(const ValueKey('project.addSuggestedCategories')));
    expect(find.text('Add suggested categories'), findsOneWidget);
    await shoot(tester, 'project_template_form');
    await tapFinder(tester, find.byKey(const ValueKey('project.addSuggestedCategories')));
    await tapFinder(tester, _filled('Save'), frames: 12);
    expect(find.text('Nothing spent yet'), findsOneWidget, reason: 'saving opens the new project');
    final vehicle = (await fresh.db.select(fresh.db.projects).get()).single;
    expect(vehicle.templateKey, 'vehicle');
    final vehicleCategories = await packCategories('vehicle');
    expect(vehicleCategories.map((c) => c.seedKey), containsAll(['vehicle', 'vehicle_tyres_battery', 'vehicle_puc']));
    final fuelRows = (await fresh.db.select(fresh.db.categories).get()).where((c) => c.seedKey == 'fuel');
    expect(fuelRows.length, 1, reason: 'fuel is reused, not duplicated');

    await goBack(tester);
    await tapText(tester, 'New project');
    await tapText(tester, 'Trip');
    await tapFinder(tester, _filled('Save'), frames: 12);
    expect(await packCategories('trip'), isEmpty, reason: 'categories are added only when ticked');
    expect((await fresh.db.select(fresh.db.projects).get()).map((p) => p.templateKey), containsAll(['vehicle', 'trip']));

    await goBack(tester);
    await tapText(tester, 'New project');
    await tapText(tester, 'Vehicle');
    await scrollTo(tester, find.byKey(const ValueKey('project.addSuggestedCategories')));
    expect(find.text('All suggested categories are already in your list'), findsOneWidget);
    await goBack(tester);
    await tapText(tester, 'New project');
    await tapText(tester, 'Home construction');
    await scrollTo(tester, find.byKey(const ValueKey('project.addSuggestedCategories')));

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    expect(find.text(hi.addSuggestedCategories), findsOneWidget);
    await shoot(tester, 'hi_project_template_form');
    await goBack(tester);
    await tapText(tester, hi.newProject);
    expect(find.text(hi.templateConstruction), findsOneWidget);
    await shoot(tester, 'hi_project_templates');
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });

  testWidgets('18 project fields: vehicle cost per km and per litre, construction per sq ft and by stage, custom field, Hindi', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    await pumpApp(tester, fresh);
    Finder metric(String key, String value) => find.descendant(of: find.byKey(ValueKey('metric.$key')), matching: find.text(value));

    Future<void> addVehicleEntry(String amount, String odometer, String litres) async {
      await tapText(tester, 'Add entry');
      await _pickCategory(tester, 'fuel', 'Fuel / Petrol / Diesel');
      await enterText(tester, _amountField(), amount);
      await scrollTo(tester, find.text('Project details'));
      await scrollTo(tester, find.byKey(const ValueKey('field.litres')));
      await enterText(tester, find.byKey(const ValueKey('field.odometer')), odometer);
      await enterText(tester, find.byKey(const ValueKey('field.litres')), litres);
    }

    await goTab(tester, 'Settings');
    await scrollTo(tester, find.text('Projects'));
    await tapText(tester, 'Projects');
    await tapText(tester, 'Start a project');
    await tapText(tester, 'Vehicle');
    await tapFinder(tester, _filled('Save'), frames: 12);
    expect(find.text('Fill in project details on entries (odometer, stage, room…) to see metrics here.'), findsOneWidget);

    await addVehicleEntry('2000', '10000', '20');
    await shoot(tester, 'project_entry_fields');
    await _saveEntry(tester, formatMinor(200000));
    await addVehicleEntry('2000', '11000', '20');
    await _saveEntry(tester, formatMinor(200000));
    await waitFor(tester, find.byKey(const ValueKey('metric.costPerKm')));
    expect(metric('costPerKm', formatMinor(200)), findsOneWidget, reason: '₹2000 after the first fill over 1000 km');
    expect(find.text('1000 km driven'), findsOneWidget);
    expect(metric('perLitre', formatMinor(10000)), findsOneWidget, reason: '₹4000 over 40 L');
    await shoot(tester, 'project_metrics_vehicle');
    final values = await fresh.db.select(fresh.db.entryFieldValues).get();
    expect(values.where((value) => value.fieldKey == 'odometer').map((value) => value.numberValue), containsAll([10000.0, 11000.0]));

    await goBack(tester);
    await tapText(tester, 'New project');
    await tapText(tester, 'Home construction');
    await scrollTo(tester, find.byKey(const ValueKey('project.addSuggestedCategories')));
    await tapFinder(tester, find.byKey(const ValueKey('project.addSuggestedCategories')));
    await tapFinder(tester, _filled('Save'), frames: 12);
    await scrollTo(tester, find.byKey(const ValueKey('projectField.built_up_area')));
    expect(find.descendant(of: find.byKey(const ValueKey('projectField.built_up_area')), matching: find.text('Not set')), findsOneWidget);
    await tapFinder(tester, find.byKey(const ValueKey('projectField.built_up_area')));
    await enterText(tester, _dialogField(), '1000');
    await tapFinder(tester, _filled('Save').last, frames: 10);
    expect(find.text('1000 sq ft'), findsOneWidget);

    await tapText(tester, 'Add entry');
    await _pickCategory(tester, 'cement', 'Cement');
    await enterText(tester, _amountField(), '50000');
    await scrollTo(tester, _chip('Foundation'));
    await tapFinder(tester, _chip('Foundation'));
    await enterText(tester, find.byKey(const ValueKey('field.quantity')), '100');
    await _saveEntry(tester, formatMinor(5000000));
    await waitFor(tester, find.byKey(const ValueKey('metric.perSqFt')));
    expect(metric('perSqFt', formatMinor(5000)), findsOneWidget, reason: '₹50,000 over 1000 sq ft');
    await scrollTo(tester, find.text('Spending by Stage'));
    expect(find.text('Foundation'), findsOneWidget);
    await shoot(tester, 'project_metrics_construction');
    final quantity = (await fresh.db.select(fresh.db.entryFieldValues).get()).firstWhere((value) => value.fieldKey == 'quantity');
    expect((quantity.numberValue, quantity.textValue), (100.0, 'bag'));

    await scrollTo(tester, find.byKey(const ValueKey('project.addField')));
    await tapFinder(tester, find.byKey(const ValueKey('project.addField')));
    await tapFinder(tester, find.byKey(const ValueKey('addField.save')));
    expect(find.text('Give the field a name'), findsOneWidget);
    await enterText(tester, find.byKey(const ValueKey('addField.name')), 'Floor');
    expect(find.text('Give the field a name'), findsNothing);
    await tapFinder(tester, find.byKey(const ValueKey('addField.type')));
    await tapText(tester, 'Choice', last: true);
    await enterText(tester, find.byKey(const ValueKey('addField.options')), 'Ground, First');
    await shoot(tester, 'project_add_field');
    await tapFinder(tester, find.byKey(const ValueKey('addField.save')), frames: 10);
    final floor = (await fresh.db.select(fresh.db.projectFields).get()).singleWhere((field) => field.label == 'Floor');
    expect(floor.choices, '["Ground","First"]');
    await scrollTo(tester, find.text('Floor'));
    await shoot(tester, 'project_fields');

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    await scrollTo(tester, find.text(hi.costPerSqFt), up: true);
    expect(find.text(hi.projectMetrics), findsOneWidget);
    await shoot(tester, 'hi_project_metrics');
    await scrollTo(tester, find.text(hi.spendingByField(hi.fieldStage)));
    expect(find.text(hi.stageFoundation), findsOneWidget);
    await scrollTo(tester, find.text(hi.fieldBuiltUpArea));
    await shoot(tester, 'hi_project_fields');
    await tapText(tester, hi.addEntry);
    await scrollTo(tester, find.text(hi.projectDetails));
    expect(find.text(hi.fieldStage), findsOneWidget);
    await shoot(tester, 'hi_project_entry_fields');
    await goBack(tester);
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });

  testWidgets('19 category packs: preview, add once, remove keeps used categories, Hindi', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    await pumpApp(tester, fresh);
    Future<void> openPacks() async {
      await goTab(tester, 'Settings');
      await scrollTo(tester, find.text('Categories'));
      await tapText(tester, 'Categories');
      await tapFinder(tester, find.byKey(const ValueKey('categories.addPack')));
    }

    Finder addedChip(String packKey) => find.descendant(of: find.byKey(ValueKey('pack.$packKey')), matching: find.byType(Chip));
    Future<void> closeSheet() async {
      await tester.tapAt(const Offset(20, 120));
      await settle(tester);
    }

    await openPacks();
    expect(find.text('Category packs'), findsOneWidget);
    expect(addedChip('farming'), findsNothing);
    await shoot(tester, 'category_packs');
    await scrollTo(tester, find.byKey(const ValueKey('pack.farming')));
    await tapFinder(tester, find.byKey(const ValueKey('pack.farming')));
    expect(find.text('Fertiliser'), findsOneWidget);
    expect(find.text('Crop Sale'), findsOneWidget);
    await shoot(tester, 'category_pack_preview');
    final farmingCount = planPack(farmingPack, const {}).length;
    await tapFinder(tester, find.byKey(const ValueKey('pack.add')), frames: 10);
    expect(find.text('Pack added with $farmingCount new categories'), findsOneWidget);
    expect(addedChip('farming'), findsOneWidget);
    await shoot(tester, 'category_packs_added');

    await tapFinder(tester, find.byKey(const ValueKey('pack.farming')));
    expect(find.byKey(const ValueKey('pack.add')), findsNothing, reason: 'a pack can be added once');
    expect(find.byKey(const ValueKey('pack.remove')), findsOneWidget);
    await closeSheet();
    await goBack(tester);
    await goBack(tester);

    await goTab(tester, 'Home');
    await tapFinder(tester, find.byType(FloatingActionButton));
    await _pickCategory(tester, 'seeds', 'Seeds');
    await enterText(tester, _amountField(), '500');
    await _saveEntry(tester, formatMinor(50000));

    await openPacks();
    await scrollTo(tester, find.byKey(const ValueKey('pack.farming')));
    await tapFinder(tester, find.byKey(const ValueKey('pack.farming')));
    await tapFinder(tester, find.byKey(const ValueKey('pack.remove')));
    expect(find.text('Unused categories (${farmingCount - 2}) will be archived. Categories in use (2) stay as your own.'), findsOneWidget);
    await shoot(tester, 'category_pack_remove');
    await tapFinder(tester, find.widgetWithText(FilledButton, 'Remove'), frames: 10);
    expect(find.text('Pack removed'), findsOneWidget);
    expect(addedChip('farming'), findsNothing);
    await goBack(tester);
    await scrollTo(tester, find.text('Farming'), within: find.byType(CategoriesScreen));
    expect(find.text('Farming'), findsOneWidget, reason: 'the parent of a used category stays');
    await goBack(tester);

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    await tapText(tester, hi.categories);
    expect(find.text(hi.addAPack), findsOneWidget);
    await tapFinder(tester, find.byKey(const ValueKey('categories.addPack')));
    expect(find.text(hi.categoryPacks), findsOneWidget);
    expect(find.text(hindiCategoryNames['baby']!), findsOneWidget);
    await shoot(tester, 'hi_category_packs');
    await tapFinder(tester, find.byKey(const ValueKey('pack.baby')));
    expect(find.text(hindiCategoryNames['baby_diapers']!), findsOneWidget);
    expect(find.text(hi.addPack), findsOneWidget);
    await shoot(tester, 'hi_category_pack_preview');
    await closeSheet();
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });

  testWidgets('21 entry project picker: pick, remember per session, switch, clear, Entries filter, Hindi', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    final projects = fresh.read(projectsRepositoryProvider);
    final carId = await projects.create(name: 'Swift car', icon: 'folder', color: 0xFF1E88E5, templateKey: 'vehicle');
    final kitchenId = await projects.create(name: 'Kitchen', icon: 'folder', color: 0xFF43A047);
    final tripId = await projects.create(name: 'Goa trip', icon: 'folder', color: 0xFFFB8C00);
    await projects.setStatus(tripId, ProjectStatus.completed);
    await pumpApp(tester, fresh);
    final projectChip = find.byKey(const ValueKey('editor.project'));
    Finder option(String id) => find.byKey(ValueKey('project.option.$id'));
    Future<String?> projectOf(int amountMinor) async => (await fresh.db.select(fresh.db.entries).get()).singleWhere((entry) => entry.amountMinor == amountMinor).projectId;

    await tapFinder(tester, find.byType(FloatingActionButton));
    await openMoreDetails(tester, reveals: projectChip);
    expect(find.text('Add to project'), findsOneWidget, reason: 'nothing remembered yet');
    await shoot(tester, 'editor_project_chip');
    await tapFinder(tester, projectChip);
    expect(find.text('Choose project'), findsOneWidget);
    expect(option(carId), findsOneWidget);
    expect(option(kitchenId), findsOneWidget);
    expect(option(tripId), findsNothing, reason: 'only active projects take new entries');
    await shoot(tester, 'editor_project_picker');
    await tapFinder(tester, option(carId));
    expect(find.descendant(of: projectChip, matching: find.text('Swift car')), findsOneWidget);
    await scrollTo(tester, find.text('Project details'));
    expect(find.text('Project details'), findsOneWidget, reason: 'the picked project brings its entry fields');
    await shoot(tester, 'editor_project_picked');
    await scrollTo(tester, find.text('Uncategorised'), up: true);
    await _pickCategory(tester, 'fuel', 'Fuel / Petrol / Diesel');
    await enterText(tester, _amountField(), '2500');
    await _saveEntry(tester, formatMinor(250000));
    expect(await projectOf(250000), carId);

    await tapFinder(tester, find.byType(FloatingActionButton));
    await openMoreDetails(tester, reveals: projectChip);
    expect(
      find.descendant(of: projectChip, matching: find.text('Swift car')),
      findsOneWidget,
      reason: 'the last project is remembered',
    );
    await shoot(tester, 'editor_project_remembered');
    await tapFinder(tester, projectChip);
    await tapFinder(tester, option(kitchenId));
    expect(find.descendant(of: projectChip, matching: find.text('Kitchen')), findsOneWidget);
    expect(find.text('Project details'), findsNothing, reason: 'Kitchen has no entry fields');
    await _pickCategory(tester, 'fuel', 'Fuel / Petrol / Diesel');
    await enterText(tester, _amountField(), '300');
    await _saveEntry(tester, formatMinor(30000));
    expect(await projectOf(30000), kitchenId);

    await tapFinder(tester, find.byType(FloatingActionButton));
    await openMoreDetails(tester, reveals: projectChip);
    expect(find.descendant(of: projectChip, matching: find.text('Kitchen')), findsOneWidget);
    await tapFinder(tester, find.descendant(of: projectChip, matching: find.byIcon(Icons.close)));
    expect(find.text('Add to project'), findsOneWidget, reason: 'the cross clears the project');
    await scrollTo(tester, find.text('Uncategorised'), up: true);
    await _pickCategory(tester, 'fuel', 'Fuel / Petrol / Diesel');
    await enterText(tester, _amountField(), '100');
    await _saveEntry(tester, formatMinor(10000));
    expect(await projectOf(10000), isNull);

    await goTab(tester, 'Entries');
    expect(find.byType(EntryTile), findsNWidgets(3));
    final filterChip = find.byKey(const ValueKey('entries.projectFilter'));
    await tapFinder(tester, filterChip);
    expect(option(tripId), findsOneWidget, reason: 'completed projects can still be filtered on');
    await tapFinder(tester, option(carId));
    expect(find.descendant(of: filterChip, matching: find.text('Swift car')), findsOneWidget);
    expect(find.byType(EntryTile), findsOneWidget);
    await shoot(tester, 'entries_project_filter');
    await tapFinder(tester, find.descendant(of: filterChip, matching: find.byIcon(Icons.close)));
    expect(find.byType(EntryTile), findsNWidgets(3));

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    expect(find.descendant(of: filterChip, matching: find.text(hi.project)), findsOneWidget);
    await tapFinder(tester, find.byType(FloatingActionButton));
    await openMoreDetails(tester, reveals: projectChip);
    expect(find.text(hi.addToProject), findsOneWidget);
    await shoot(tester, 'hi_editor_project_chip');
    await tapFinder(tester, projectChip);
    expect(find.text(hi.chooseProject), findsOneWidget);
    expect(find.text(hi.noProject), findsOneWidget);
    await shoot(tester, 'hi_editor_project_picker');
    await tapFinder(tester, find.byKey(const ValueKey('project.none')));
    await goBack(tester);
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });

  testWidgets('20 groups: remind a debtor by copying the message, then the tile says reminded today', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final groups = fresh.read(groupsRepositoryProvider);
    final remindGroupId = await groups.createGroup(name: 'Lunch club', icon: 'restaurant', myName: 'You', otherMembers: ['Rahul']);
    final members = await groups.getMembers(remindGroupId);
    await groups.addSettlement(
      groupId: remindGroupId,
      fromMemberId: members.firstWhere((member) => member.isMe).id,
      toMemberId: members.firstWhere((member) => member.name == 'Rahul').id,
      amountMinor: 50000,
      occurredAt: DateTime.now(),
    );
    await pumpApp(tester, fresh);
    await goTab(tester, 'Groups');
    await tapText(tester, 'Lunch club');
    await tapText(tester, 'Balances');
    expect(find.text('Rahul → You'), findsOneWidget);
    await tapText(tester, 'Remind');
    expect(find.text('Remind Rahul'), findsOneWidget);
    expect(find.text('WhatsApp'), findsNothing, reason: 'no phone number, so only share and copy');
    final message = tester.widget<TextField>(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField))).controller!.text;
    expect(message, contains('Lunch club'));
    expect(message, contains(formatMinor(50000)));
    await shoot(tester, 'remind_sheet');
    await tapText(tester, 'Copy', frames: 12);
    expect(find.text('Copied. Paste it into any chat.'), findsOneWidget);
    expect(find.text('Reminded today'), findsOneWidget);
    expect(find.text('Remind again'), findsOneWidget);
    await shoot(tester, 'reminded_today');
  });

  testWidgets('22 entries search and filters: payee, item, account, amount, tag, category, project, dates, clear all, Hindi', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1, 9);
    final lastMonth = DateTime(now.year, now.month - 1, 10, 9);
    final categories = await fresh.db.select(fresh.db.categories).get();
    String categoryOf(String seedKey) => categories.firstWhere((category) => category.seedKey == seedKey).id;
    final hdfc = await fresh.read(accountsRepositoryProvider).create(name: 'HDFC', type: 'bank', color: 0xFF1E88E5);
    final carId = await fresh.read(projectsRepositoryProvider).create(name: 'Swift car', icon: 'folder', color: 0xFF1E88E5);
    final entries = fresh.read(entriesRepositoryProvider);
    final milkId = 'milk';
    await entries.saveEntry(
      EntriesRepository.newExpense(id: milkId, amountMinor: 45000, occurredAt: thisMonth, categoryId: categoryOf('groceries'), payee: 'Sharma Dairy', note: 'Morning milk'),
      items: [EntryItemsCompanion.insert(id: 'paneer', entryId: milkId, name: 'Paneer', unitPriceMinor: 45000, amountMinor: 45000)],
    );
    await entries.saveEntry(
      EntriesRepository.newExpense(
        amountMinor: 250000,
        occurredAt: thisMonth,
        categoryId: categoryOf('fuel'),
        accountId: hdfc.id,
        projectId: carId,
        note: 'Highway fill',
      ).copyWith(tags: const Value('#trip')),
    );
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 12000, occurredAt: thisMonth, note: 'Chai').copyWith(tags: const Value('#office')));
    await entries.saveEntry(EntriesRepository.newExpense(kind: 'income', amountMinor: 5000000, occurredAt: thisMonth, categoryId: categoryOf('salary'), payee: 'Acme'));
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 800000, occurredAt: lastMonth, categoryId: categoryOf('rent'), note: 'Old rent'));
    await pumpApp(tester, fresh);

    final search = find.byKey(const ValueKey('entries.search'));
    final results = find.byKey(const ValueKey('entries.resultsCount'));
    final filterSheet = find.byKey(const ValueKey('filter.sheet'));
    Future<void> openFilters() => tapFinder(tester, find.byKey(const ValueKey('entries.filters')), frames: 10);
    Future<void> applyFilters() => tapFinder(tester, find.byKey(const ValueKey('filter.apply')), frames: 10);
    Future<void> clearAll() => tapFinder(tester, find.byKey(const ValueKey('entries.clearAll')), frames: 10);
    Finder tileAmount(int minor) => find.descendant(of: find.byType(EntryTile), matching: find.textContaining(formatMinor(minor, showDecimals: false)));
    void expectResults(int count) {
      expect(find.byType(EntryTile), findsNWidgets(count));
      expect(tester.widget<Text>(results).data, count == 1 ? '1 result' : '$count results');
    }

    await goTab(tester, 'Entries');
    expect(find.byType(EntryTile), findsNWidgets(4));
    expect(results, findsNothing, reason: 'no count until something narrows the list');

    await enterText(tester, search, 'paneer');
    expectResults(1);
    expect(tileAmount(45000), findsOneWidget, reason: 'item names are searched');
    await shoot(tester, 'entries_search_item');
    await enterText(tester, search, 'sharma');
    expectResults(1);
    await enterText(tester, search, 'chai');
    expectResults(1);
    await clearAll();
    expect(find.byType(EntryTile), findsNWidgets(4));
    expect(
      find.descendant(of: search, matching: find.text('chai')),
      findsNothing,
      reason: 'clear all empties the search box',
    );

    await openFilters();
    expect(find.text('Filter entries'), findsOneWidget);
    await scrollTo(tester, find.byKey(const ValueKey('filter.tag.office')), within: filterSheet);
    expect(find.byKey(const ValueKey('filter.tag.trip')), findsOneWidget, reason: 'tags in use are offered');
    await scrollTo(tester, find.byKey(const ValueKey('filter.project')), up: true, within: filterSheet);
    await shoot(tester, 'entry_filter_sheet');
    await tapFinder(tester, find.byKey(ValueKey('filter.account.${hdfc.id}')));
    await enterText(tester, find.byKey(const ValueKey('filter.minAmount')), '1000');
    await enterText(tester, find.byKey(const ValueKey('filter.maxAmount')), '3000');
    await applyFilters();
    expectResults(1);
    expect(find.byKey(const ValueKey('entries.filter.account')), findsOneWidget);
    expect(find.byKey(const ValueKey('entries.filter.amount')), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const ValueKey('entries.filters')), matching: find.text('2')),
      findsOneWidget,
      reason: 'the badge counts active filters',
    );
    await shoot(tester, 'entries_filtered');
    await tapFinder(tester, find.descendant(of: find.byKey(const ValueKey('entries.filter.account')), matching: find.byIcon(Icons.close)));
    expectResults(1);
    await tapFinder(tester, find.descendant(of: find.byKey(const ValueKey('entries.filter.amount')), matching: find.byIcon(Icons.close)));
    expect(find.byType(EntryTile), findsNWidgets(4));

    await openFilters();
    await enterText(tester, find.byKey(const ValueKey('filter.minAmount')), '500');
    await enterText(tester, find.byKey(const ValueKey('filter.maxAmount')), '100');
    expect(find.text('Min is more than max'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('filter.apply'))).onPressed, isNull);
    await tapFinder(tester, find.byKey(const ValueKey('filter.clearAll')));
    await scrollTo(tester, find.byKey(const ValueKey('filter.tag.office')), within: filterSheet);
    await tapFinder(tester, find.byKey(const ValueKey('filter.tag.office')));
    await applyFilters();
    expectResults(1);
    expect(tileAmount(12000), findsOneWidget);
    await clearAll();

    await openFilters();
    await tapFinder(tester, find.byKey(const ValueKey('filter.category')));
    await enterText(tester, find.widgetWithText(TextField, 'Search categories'), 'fuel');
    await tapText(tester, 'Fuel / Petrol / Diesel');
    await tapFinder(tester, find.byKey(const ValueKey('filter.project')));
    await tapFinder(tester, find.byKey(ValueKey('project.option.$carId')));
    await applyFilters();
    expectResults(1);
    expect(find.byKey(const ValueKey('entries.filter.category')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('entries.projectFilter')), matching: find.text('Swift car')), findsOneWidget);
    await clearAll();

    await openFilters();
    await scrollTo(tester, find.byKey(const ValueKey('filter.dates')), within: filterSheet);
    await tapFinder(tester, find.byKey(const ValueKey('filter.dates')), frames: 10);
    await tapFinder(tester, find.byIcon(Icons.edit_outlined));
    final dayFormat = DateFormat.yMd('en');
    await enterText(tester, find.widgetWithText(TextField, 'Start Date'), dayFormat.format(DateTime(lastMonth.year, lastMonth.month, 1)));
    await enterText(tester, find.widgetWithText(TextField, 'End Date'), dayFormat.format(DateTime(lastMonth.year, lastMonth.month, 20)));
    await tapText(tester, 'OK', last: true, frames: 10);
    await applyFilters();
    expectResults(1);
    expect(tileAmount(800000), findsOneWidget, reason: 'a date range reaches outside the selected month');
    expect(find.byType(MonthSwitcher), findsNothing, reason: 'the date filter replaces the month');
    expect(find.byKey(const ValueKey('entries.filter.dates')), findsOneWidget);
    await shoot(tester, 'entries_date_filter');
    await clearAll();
    expect(find.byType(EntryTile), findsNWidgets(4));
    expect(find.byType(MonthSwitcher), findsOneWidget);

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    await enterText(tester, search, 'paneer');
    expect(find.text('1 नतीजा'), findsOneWidget);
    expect(find.text(hi.clearAll), findsOneWidget);
    await shoot(tester, 'hi_entries_search');
    await clearAll();
    await openFilters();
    expect(find.text(hi.filterEntries), findsOneWidget);
    expect(find.text(hi.anyProject), findsOneWidget);
    expect(find.text(hi.showResults), findsOneWidget);
    await shoot(tester, 'hi_entry_filter_sheet');
    await tapFinder(tester, find.byKey(const ValueKey('filter.apply')));
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });

  testWidgets('23 fast entry: calculator keypad, save and add another, Add income link, Hindi', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    await pumpApp(tester, fresh);
    Finder key(String id) => find.byKey(ValueKey(id));
    String textOf(Finder finder) => tester.widget<Text>(finder).data!;
    Future<void> press(String keys) async {
      const ids = {'+': 'plus', '−': 'minus', '×': 'times', '÷': 'divide', '.': 'dot', '<': 'back'};
      for (final char in keys.split('')) {
        await tapFinder(tester, key('calc.key.${ids[char] ?? char}'), frames: 2);
      }
    }

    Future<List<Entry>> entries() => fresh.db.select(fresh.db.entries).get();
    Set<String> selectedKind() => tester.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>, skipOffstage: false)).selected;

    await tapFinder(tester, find.byType(FloatingActionButton));
    await tapFinder(tester, key('editor.calculator'), frames: 10);
    expect(find.text('Calculator'), findsOneWidget);
    await press('0120×3+45');
    expect(textOf(key('calc.display')), '120×3+45', reason: 'a leading zero is replaced');
    expect(textOf(key('calc.result')), '= ${formatMinor(40500)}', reason: 'times binds tighter than plus');
    await shoot(tester, 'calculator_keypad');
    await press('÷0');
    expect(textOf(key('calc.result')), "Can't divide by zero");
    expect(tester.widget<FilledButton>(key('calc.use')).onPressed, isNull);
    await press('<<');
    expect(textOf(key('calc.display')), '120×3+45');
    await tapFinder(tester, key('calc.use'), frames: 10);
    expect(tester.widget<TextField>(_amountField()).controller!.text, '405');

    await _pickCategory(tester, 'groceries', 'Groceries');
    await tapFinder(tester, key('editor.saveAndAddAnother'), frames: 10);
    expect(find.text('Saved. Add the next one.'), findsOneWidget);
    expect(find.byType(ExpenseEditorScreen), findsOneWidget, reason: 'the editor stays open for the next entry');
    expect(tester.widget<TextField>(_amountField()).controller!.text, isEmpty);
    expect(find.text('Uncategorised'), findsOneWidget);
    expect(selectedKind(), {'expense'});
    await shoot(tester, 'editor_saved_add_another');
    final first = (await entries()).single;
    expect(first.amountMinor, 40500);

    await _pickCategory(tester, 'restaurants', 'Restaurants & Cafes');
    await enterText(tester, _amountField(), '60');
    await _saveEntry(tester, formatMinor(6000));
    expect(find.byType(ExpenseEditorScreen), findsNothing, reason: 'plain Save still closes the editor');
    final saved = await entries();
    expect(saved.map((entry) => entry.amountMinor).toSet(), {40500, 6000});
    expect(saved.map((entry) => entry.accountId).toSet(), {first.accountId}, reason: 'the account carries over');
    expect(saved.map((entry) => entry.occurredAt.day).toSet().length, 1, reason: 'the date carries over');

    Future<void> platformNavigation(MethodCall call) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(SystemChannels.navigation.name, SystemChannels.navigation.codec.encodeMethodCall(call), (_) {});
      await settle(tester, 10);
    }

    // The Android "Add income" launcher shortcut opens this link.
    await platformNavigation(const MethodCall('pushRouteInformation', {'location': 'hisab://entry?kind=income', 'state': null}));
    expect(find.byType(ExpenseEditorScreen), findsOneWidget);
    expect(selectedKind(), {'income'});
    await platformNavigation(const MethodCall('popRoute'));
    expect(find.byType(ExpenseEditorScreen), findsNothing, reason: 'system back from a linked editor goes home');

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    await tapFinder(tester, find.byType(FloatingActionButton));
    expect(find.text(hi.saveAndAddAnother), findsOneWidget);
    await tapFinder(tester, key('editor.calculator'), frames: 10);
    expect(find.text(hi.calculator), findsOneWidget);
    await press('250÷4');
    expect(find.text(hi.useAmount(formatMinor(6250))), findsOneWidget);
    await shoot(tester, 'hi_calculator_keypad');
    await tapFinder(tester, key('calc.use'), frames: 10);
    await shoot(tester, 'hi_editor_add_another');
    await goBack(tester);
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });

  testWidgets('24 groups: two members pay one dinner, the editor blocks a wrong total and the list says who paid', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final groups = fresh.read(groupsRepositoryProvider);
    final dinnerGroupId = await groups.createGroup(name: 'Dinner club', icon: 'restaurant', myName: 'You', otherMembers: ['Rahul', 'Priya']);
    final members = await groups.getMembers(dinnerGroupId);
    final me = members.firstWhere((member) => member.isMe).id;
    final rahul = members.firstWhere((member) => member.name == 'Rahul').id;
    final priya = members.firstWhere((member) => member.name == 'Priya').id;
    Finder payerField(String memberId) => find.byKey(Key('payer-amount-$memberId'));

    await pumpApp(tester, fresh);
    await goTab(tester, 'Groups');
    await tapText(tester, 'Dinner club');
    await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Add expense'));
    await _pickCategory(tester, 'restaurants', 'Restaurants & Cafes');
    await enterText(tester, _amountField(), '900');
    await scrollTo(tester, _chip('2+ people'), within: find.byType(ExpenseEditorScreen));
    await tapFinder(tester, _chip('2+ people'));
    expect(tester.widget<ChoiceChip>(_chip('2+ people')).selected, isTrue);
    expect(tester.widget<ChoiceChip>(_chip('You')).selected, isFalse, reason: 'single payer chips clear in multi-payer mode');
    expect(find.text('${formatMinor(90000)} of ${formatMinor(90000)} assigned'), findsOneWidget, reason: 'the current payer starts covering the whole bill');

    await scrollTo(tester, payerField(rahul), within: find.byType(ExpenseEditorScreen));
    await enterText(tester, payerField(rahul), '600');
    expect(find.text('${formatMinor(150000)} of ${formatMinor(90000)} assigned'), findsOneWidget);
    await _saveEntry(tester, formatMinor(90000));
    expect(find.text('Amounts paid must add up to ${formatMinor(90000)}'), findsOneWidget, reason: 'save is blocked until the payers cover the bill');
    expect(find.byType(ExpenseEditorScreen), findsOneWidget);

    await enterText(tester, payerField(me), '300');
    expect(find.text('${formatMinor(90000)} of ${formatMinor(90000)} assigned'), findsOneWidget);
    await scrollTo(tester, find.text('Paid by'), within: find.byType(ExpenseEditorScreen), up: true);
    await shoot(tester, 'group_multiple_payers');
    await _saveEntry(tester, formatMinor(90000));
    expect(find.textContaining('Rahul and you paid ${formatMinor(90000)}'), findsOneWidget);
    await shoot(tester, 'group_expenses_multiple_payers');

    final detail = (await groups.getGroupDetail(dinnerGroupId))!;
    expect(detail.balances.net, {me: 0, rahul: 30000, priya: -30000});
    expect(detail.entries.single.$1.paidByMemberId, rahul, reason: 'the biggest payer is kept as the main payer');

    await tapText(tester, 'Balances');
    expect(find.text('Priya → Rahul'), findsOneWidget);
    await tapText(tester, 'Expenses');
    await tapFinder(tester, find.textContaining('Rahul and you paid'), frames: 12);
    await scrollTo(tester, _chip('2+ people'), within: find.byType(ExpenseEditorScreen));
    expect(tester.widget<ChoiceChip>(_chip('2+ people')).selected, isTrue, reason: 'editing keeps the payers');
    expect(tester.widget<TextFormField>(payerField(rahul)).initialValue, '600');
    expect(tester.widget<TextFormField>(payerField(me)).initialValue, '300');
  });

  testWidgets('30 group settings: type, default split with weights, currency label, notes, leave blocked, archive', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final groups = fresh.read(groupsRepositoryProvider);
    final flatId = await groups.createGroup(name: 'Flat 4B', icon: 'groups', myName: 'You', otherMembers: ['Rahul']);
    final members = await groups.getMembers(flatId);
    final me = members.firstWhere((member) => member.isMe).id;
    final rahul = members.firstWhere((member) => member.name == 'Rahul').id;
    await groups.addSettlement(groupId: flatId, fromMemberId: me, toMemberId: rahul, amountMinor: 50000, occurredAt: DateTime.now());

    await pumpApp(tester, fresh);
    await goTab(tester, 'Groups');
    await tapText(tester, 'Flat 4B');
    await tapFinder(tester, find.byType(PopupMenuButton<String>));
    await tapText(tester, 'Group settings', frames: 12);

    await tapFinder(tester, _chip('Home'));
    var group = (await groups.getGroup(flatId))!;
    expect((group.type, group.icon), ('home', 'home'), reason: 'the generic icon follows the new type');

    await scrollTo(tester, _chip('Shares / ratio'));
    await tapFinder(tester, _chip('Shares / ratio'));
    await scrollTo(tester, find.byTooltip('More shares for Rahul'));
    await tapFinder(tester, find.byTooltip('More shares for Rahul'));
    expect(find.text('1.5 shares'), findsOneWidget);
    await shoot(tester, 'group_settings_shares');

    await scrollTo(tester, find.text('Same as app (${fresh.read(settingsProvider).currencySymbol})'));
    await tapText(tester, 'Same as app (${fresh.read(settingsProvider).currencySymbol})', frames: 12);
    await tapText(tester, '€  ·  EUR', frames: 12);
    expect((await groups.getGroup(flatId))!.currencyLabel, '€');

    await scrollTo(tester, find.text('Add a note for this group'));
    await tapText(tester, 'Add a note for this group', frames: 12);
    await enterText(tester, _dialogField(), 'Rent is due on the 1st');
    await tapFinder(tester, _filled('Save'), frames: 12);
    expect(find.text('Rent is due on the 1st'), findsOneWidget);

    await scrollTo(tester, find.text('Leave group'));
    await tapText(tester, 'Leave group');
    expect(find.text('Settle up first. You can leave once nobody owes you and you owe nobody.'), findsOneWidget);
    await shoot(tester, 'group_settings_bottom');

    await goBack(tester);
    expect(find.text('Rent is due on the 1st'), findsOneWidget, reason: 'notes show on the Expenses tab');
    await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Add expense'), frames: 12);
    await scrollTo(tester, _chip('Shares / ratio'), within: find.byType(ExpenseEditorScreen));
    expect(tester.widget<ChoiceChip>(_chip('Shares / ratio')).selected, isTrue, reason: 'new expenses start from the default split');
    expect(find.textContaining('€'), findsWidgets, reason: 'the editor shows the group currency label');
    await goBack(tester);

    await tapFinder(tester, find.byType(PopupMenuButton<String>));
    await tapText(tester, 'Archive group', frames: 12);
    await tapFinder(tester, _filled('Archive'), frames: 12);
    expect(find.text('This group is archived. Unarchive it to add expenses.'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Add expense'), findsNothing);
    await shoot(tester, 'group_archived');
    await goBack(tester);
    expect(find.text('Archived (1)'), findsOneWidget);
    group = (await groups.getGroup(flatId))!;
    expect((group.defaultSplitMethod, group.archivedAt != null), ('shares', true));
    expect((await groups.getMembers(flatId)).firstWhere((member) => member.id == rahul).weight, 1.5);
  });

  testWidgets('28 groups: edit and delete an expense, undo, then restore it from the activity log', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final groups = fresh.read(groupsRepositoryProvider);
    final movieGroupId = await groups.createGroup(name: 'Movie night', icon: 'movie', myName: 'You', otherMembers: ['Rahul']);
    const title = 'Restaurants & Cafes';
    Finder expenseRow() => find.descendant(of: find.byType(GroupDetailScreen), matching: find.text(title));
    Future<void> deleteFromEditor() async {
      await tapFinder(tester, expenseRow(), frames: 12);
      await tapFinder(tester, find.byIcon(Icons.delete_outline));
      await tapFinder(tester, _filled('Delete'), frames: 12);
    }

    await pumpApp(tester, fresh);
    await goTab(tester, 'Groups');
    await tapText(tester, 'Movie night');
    await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Add expense'));
    await _pickCategory(tester, 'restaurants', title);
    await enterText(tester, _amountField(), '600');
    await _saveEntry(tester, formatMinor(60000));
    await tapFinder(tester, expenseRow(), frames: 12);
    await enterText(tester, _amountField(), '900');
    await _saveEntry(tester, formatMinor(90000));

    await deleteFromEditor();
    expect(find.text('Expense deleted'), findsOneWidget);
    expect(expenseRow(), findsNothing);
    await shoot(tester, 'group_expense_undo');
    await tapText(tester, 'Undo', frames: 12);
    expect(expenseRow(), findsOneWidget, reason: 'Undo brings the expense back');
    expect((await groups.getGroupDetail(movieGroupId))!.entries.single.$2, hasLength(2), reason: 'with both shares');

    await deleteFromEditor();
    expect(expenseRow(), findsNothing);
    await tapFinder(tester, find.byType(PopupMenuButton<String>));
    await tapText(tester, 'Activity', frames: 12);
    expect(find.byType(ActivityScreen), findsOneWidget);
    expect(find.text('You deleted “$title”'), findsNWidgets(2));
    expect(find.text('You restored “$title”'), findsOneWidget);
    expect(find.text('You edited “$title”'), findsOneWidget);
    expect(find.text('You added “$title”'), findsOneWidget);
    expect(find.text('Amount: ${formatMinor(60000)} → ${formatMinor(90000)}'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Restore'), findsOneWidget, reason: 'only the latest deletion offers Restore');
    await shoot(tester, 'group_activity');

    await tapFinder(tester, find.widgetWithText(TextButton, 'Restore'), frames: 12);
    expect(find.text('Expense restored'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Restore'), findsNothing);
    expect(find.text('You restored “$title”'), findsNWidgets(2));
    expect((await groups.getGroupDetail(movieGroupId))!.entries.single.$1.amountMinor, 90000);

    await goBack(tester);
    expect(expenseRow(), findsOneWidget);
    await goBack(tester);
    await tapFinder(tester, find.byTooltip('Activity'), frames: 12);
    expect(find.text('All groups'), findsOneWidget);
    expect(find.textContaining('Movie night ·'), findsWidgets, reason: 'the overall feed names each row\'s group');
    await shoot(tester, 'all_activity');
  });

  testWidgets('29 groups: delete a group, then restore it with its expenses and payments from the activity log', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final groups = fresh.read(groupsRepositoryProvider);
    final clubId = await groups.createGroup(name: 'Book club', icon: 'book', myName: 'You', otherMembers: ['Rahul']);
    final members = await groups.getMembers(clubId);
    final me = members.firstWhere((member) => member.isMe).id;
    final rahul = members.firstWhere((member) => !member.isMe).id;
    await groups.saveGroupExpense(
      EntriesRepository.newExpense(id: 'books', amountMinor: 80000, occurredAt: DateTime.now(), note: 'Books', groupId: clubId, paidByMemberId: me, splitMethod: 'equal'),
      splits: [
        SplitsCompanion.insert(id: 'books-me', entryId: 'books', memberId: me, amountMinor: 40000),
        SplitsCompanion.insert(id: 'books-rahul', entryId: 'books', memberId: rahul, amountMinor: 40000),
      ],
    );
    await groups.addSettlement(groupId: clubId, fromMemberId: rahul, toMemberId: me, amountMinor: 10000);
    final balancesBefore = (await groups.getBalances(clubId)).net;
    await pumpApp(tester, fresh);
    await tapText(tester, 'Groups', frames: 12);
    await tapText(tester, 'Book club', frames: 12);

    await tapFinder(tester, find.byType(PopupMenuButton<String>));
    await tapText(tester, 'Delete group', frames: 8);
    await tapText(tester, 'Delete', last: true, frames: 12);
    expect(find.text('Book club'), findsNothing);

    await tapFinder(tester, find.byTooltip('Activity'), frames: 12);
    expect(find.text('You deleted the group “Book club”'), findsOneWidget);
    expect(find.text('1 expense'), findsOneWidget);
    await tapFinder(tester, find.widgetWithText(TextButton, 'Restore'), frames: 12);
    expect(find.text('Group restored'), findsOneWidget);
    expect(find.text('You restored the group “Book club”'), findsOneWidget);
    expect((await groups.getBalances(clubId)).net, balancesBefore, reason: 'the expense and the payment come back as they were');

    await goBack(tester);
    expect(find.text('Book club'), findsOneWidget);
  });

  testWidgets('25 groups: copy a WhatsApp summary and export the ledger as CSV', (tester) async {
    final exports = <({String fileName, String csv, String subject})>[];
    final fresh = await createApp(overrides: [
      csvFileSharerProvider.overrideWithValue(({required fileName, required csv, required subject}) async {
        exports.add((fileName: fileName, csv: csv, subject: subject));
        return true;
      }),
    ]);
    addTearDown(fresh.container.dispose);
    final groups = fresh.read(groupsRepositoryProvider);
    final entries = fresh.read(entriesRepositoryProvider);
    final tripId = await groups.createGroup(name: 'Goa trip', icon: 'beach', myName: 'You', otherMembers: ['Rahul', 'Priya']);
    final members = await groups.getMembers(tripId);
    final me = members.firstWhere((member) => member.isMe).id;
    final rahul = members.firstWhere((member) => member.name == 'Rahul').id;
    final priya = members.firstWhere((member) => member.name == 'Priya').id;
    final today = DateTime.now();
    await entries.saveEntry(
      EntriesRepository.newExpense(id: 'export-hotel', amountMinor: 90000, occurredAt: today, groupId: tripId, paidByMemberId: rahul, splitMethod: 'equal', note: 'Hotel, sea view'),
      splits: [for (final member in [me, rahul, priya]) SplitsCompanion.insert(id: 'export-hotel-$member', entryId: 'export-hotel', memberId: member, amountMinor: 30000)],
      payers: [
        EntryPayersCompanion.insert(id: 'export-hotel-rahul', entryId: 'export-hotel', memberId: rahul, amountMinor: 60000),
        EntryPayersCompanion.insert(id: 'export-hotel-me', entryId: 'export-hotel', memberId: me, amountMinor: 30000),
      ],
    );

    await pumpApp(tester, fresh);
    await goTab(tester, 'Groups');
    await tapText(tester, 'Goa trip');
    await tapFinder(tester, find.byTooltip('Share summary'));
    expect(find.text('Export as CSV'), findsOneWidget);
    await shoot(tester, 'group_share_options');
    await tapText(tester, 'Copy as text', frames: 12);
    final copied = (await Clipboard.getData('text/plain'))?.text ?? '';
    expect(copied, startsWith('*Goa trip — balances*'));
    expect(copied, contains('Priya owes Rahul ${formatMinor(30000)}'));
    expect(copied, contains('Rahul gets back ${formatMinor(30000)}'));
    expect(copied, contains('Group total: ${formatMinor(90000)}'));
    expect(copied, contains('Your share: ${formatMinor(30000)}'));

    await tapFinder(tester, find.byTooltip('Share summary'));
    await tapFinder(tester, find.byKey(const Key('group-export-csv')), frames: 12);
    expect(exports, hasLength(1));
    final export = exports.single;
    expect(export.fileName, endsWith('.csv'));
    expect(export.fileName, startsWith('goa-trip-'));
    expect(export.subject, 'Goa trip expenses');
    final lines = export.csv.split('\r\n');
    expect(lines.first, startsWith('Date,Description,Category,Cost,Paid by,You paid,'));
    expect(lines[1], contains('"Hotel, sea view"'));
    expect(lines[1], contains(',Rahul 600.00; You 300.00,'));
    expect(lines[2], startsWith(',Total,,900.00,'), reason: 'a closing total row follows the last expense');
  });

  testWidgets('34 groups: split a pizza night by item with a shared delivery line, block an unassigned item, clear assignments', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final groups = fresh.read(groupsRepositoryProvider);
    final pizzaGroupId = await groups.createGroup(name: 'Pizza night', icon: 'restaurant', myName: 'You', otherMembers: ['Rahul', 'Priya']);
    final members = await groups.getMembers(pizzaGroupId);
    final me = members.firstWhere((member) => member.isMe).id;
    final rahul = members.firstWhere((member) => member.name == 'Rahul').id;
    final priya = members.firstWhere((member) => member.name == 'Priya').id;
    Finder assignChip(String memberId) => find.byWidgetPredicate((widget) {
          final key = widget.key;
          return widget is GestureDetector && key is ValueKey<String> && key.value.startsWith('assign-') && key.value.endsWith('-$memberId');
        }, skipOffstage: false);
    bool chipOn(Finder chip) => tester.widget<FilterChip>(find.descendant(of: chip, matching: find.byType(FilterChip))).selected;
    final editor = find.byType(ExpenseEditorScreen);

    await pumpApp(tester, fresh);
    await goTab(tester, 'Groups');
    await tapText(tester, 'Pizza night');
    await tapFinder(tester, find.widgetWithText(FloatingActionButton, 'Add expense'));
    await _pickCategory(tester, 'restaurants', 'Restaurants & Cafes');
    await scrollTo(tester, find.text('Add items to split by item'), within: editor);
    expect(_chip('By item'), findsNothing, reason: 'no items, no by-item split');

    await scrollTo(tester, find.text('Add item'), within: editor, up: true);
    await _addItem(tester, name: 'Pizza', qty: '1', price: '600');
    await _addItem(tester, name: 'Coke', qty: '1', price: '150');
    expect(tester.widget<ChoiceChip>(_chip('By item')).selected, isTrue, reason: 'the first item switches the split to by item');
    expect(chipOn(assignChip(me).last) && chipOn(assignChip(rahul).last) && chipOn(assignChip(priya).last), isTrue, reason: 'everyone shares a new item');

    await scrollTo(tester, assignChip(priya).last, within: editor);
    await tapFinder(tester, assignChip(me).last);
    await tapFinder(tester, assignChip(priya).last);
    await tapFinder(tester, assignChip(rahul).last);
    expect(find.text('Assign "Coke" to someone'), findsWidgets);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('editor.save'))).onPressed, isNull, reason: 'save waits until every item has someone');
    await tapFinder(tester, assignChip(rahul).last);
    expect(find.text('Assign "Coke" to someone'), findsNothing);

    await scrollTo(tester, find.byKey(const Key('byItem.addExtras')), within: editor);
    await tapFinder(tester, find.byKey(const Key('byItem.addExtras')));
    await enterText(tester, find.ancestor(of: find.textContaining('Price per').last, matching: find.byType(TextField)).first, '90');
    final rahulLine = '${formatMinor(38000)} · 2 items · 45%';
    await scrollTo(tester, find.text(rahulLine), within: editor);
    expect(find.text(rahulLine), findsOneWidget, reason: 'pizza 200 + coke 150 + a third of the 90 delivery');
    expect(find.text('${formatMinor(23000)} · 1 item · 27%'), findsNWidgets(2));
    await shoot(tester, 'group_by_item_split');
    await scrollTo(tester, find.text('Pizza'), within: editor, up: true);
    await shoot(tester, 'group_by_item_assign');
    await _saveEntry(tester, formatMinor(84000));

    final detail = (await groups.getGroupDetail(pizzaGroupId))!;
    expect(detail.balances.net, {me: 61000, rahul: -38000, priya: -23000});
    final entryId = detail.entries.single.$1.id;
    final entries = fresh.read(entriesRepositoryProvider);
    expect((await entries.getItemAssignments(entryId)).values.map((ids) => ids.length).toList()..sort(), [1, 3], reason: 'the delivery line is shared, not assigned');

    await tapText(tester, 'Restaurants & Cafes');
    await settle(tester, 8);
    // The reopened editor starts at the top; the split chips are further down (#109).
    await scrollTo(tester, _chip('By item'), within: editor);
    expect(tester.widget<ChoiceChip>(_chip('By item')).selected, isTrue, reason: 'editing keeps the by-item split');
    await scrollTo(tester, assignChip(priya).at(1), within: editor);
    expect([chipOn(assignChip(me).at(1)), chipOn(assignChip(rahul).at(1)), chipOn(assignChip(priya).at(1))], [false, true, false]);

    await scrollTo(tester, _chip('Equally'), within: editor);
    await tapFinder(tester, _chip('Equally'));
    expect(find.text('Item assignments will be cleared'), findsOneWidget);
    await tapFinder(tester, find.byKey(const Key('byItem.clearConfirm')));
    expect(tester.widget<ChoiceChip>(_chip('Equally')).selected, isTrue);
    expect(assignChip(rahul), findsNothing, reason: 'the assign strips go with the by-item split');
    await _saveEntry(tester, formatMinor(84000));
    expect(await entries.getItemAssignments(entryId), isEmpty);
    final equalNet = (await groups.getGroupDetail(pizzaGroupId))!.balances.net;
    expect(equalNet, {me: 56000, rahul: -28000, priya: -28000});
  });

  testWidgets('33 groups: totals for all time and one month, with several payers and an unequal split', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final groups = fresh.read(groupsRepositoryProvider);
    final entries = fresh.read(entriesRepositoryProvider);
    final groupId = await groups.createGroup(name: 'Totals club', icon: 'restaurant', myName: 'You', otherMembers: ['Rahul', 'Priya']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((member) => member.isMe).id;
    final rahul = members.firstWhere((member) => member.name == 'Rahul').id;
    final priya = members.firstWhere((member) => member.name == 'Priya').id;
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 15);
    Future<void> expense(String note, DateTime when, Map<String, int> shares, Map<String, int> paid) async {
      final entryId = newId();
      final total = shares.values.fold(0, (sum, amount) => sum + amount);
      await entries.saveEntry(
        EntriesRepository.newExpense(id: entryId, amountMinor: total, occurredAt: when, note: note, groupId: groupId, paidByMemberId: paid.keys.first, splitMethod: 'exact'),
        splits: [for (final MapEntry(key: member, value: amount) in shares.entries) SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: member, amountMinor: amount)],
        payers: paid.length < 2 ? const [] : [for (final MapEntry(key: member, value: amount) in paid.entries) EntryPayersCompanion.insert(id: newId(), entryId: entryId, memberId: member, amountMinor: amount)],
      );
    }

    // This month: Rahul 600 and I 300 pay a 900 dinner owed 200 / 300 / 400.
    await expense('Dinner', now, {me: 20000, rahul: 30000, priya: 40000}, {rahul: 60000, me: 30000});
    // Last month: Priya pays a 300 taxi shared equally.
    await expense('Taxi', lastMonth, {me: 10000, rahul: 10000, priya: 10000}, {priya: 30000});

    await pumpApp(tester, fresh);
    await goTab(tester, 'Groups');
    await tapText(tester, 'Totals club');
    await tapText(tester, 'Balances');
    final card = find.byKey(kGroupTotalsCardKey);
    expect(find.descendant(of: card, matching: find.text(formatMinor(120000))), findsOneWidget, reason: 'all-time group spending');
    expect(find.descendant(of: card, matching: find.text(formatMinor(30000))), findsNWidgets(2), reason: 'I paid 300 and owe 200 + 100');

    await tapFinder(tester, card, frames: 12);
    expect(find.byType(GroupTotalsScreen), findsOneWidget);
    expect(find.text('2 expenses'), findsOneWidget);
    await shoot(tester, 'group_totals_all_time');

    await tapFinder(tester, find.widgetWithText(ChoiceChip, formatMonthLabel(monthRange(now))), frames: 12);
    expect(find.text('1 expense'), findsOneWidget);
    expect(find.text(formatMinor(90000)), findsWidgets);
    expect(find.text('+${formatMinor(10000)}'), findsOneWidget, reason: 'I paid 300 against a 200 share this month');
    await scrollTo(tester, find.byType(MemberSpendChart), within: find.byType(GroupTotalsScreen));
    await shoot(tester, 'group_totals_month_members');
  });

  testWidgets('26 subscriptions: add from templates, totals, sort by cost, pause, cancel, Hindi', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    await pumpApp(tester, fresh);

    await goTab(tester, 'Settings');
    await scrollTo(tester, find.text('Subscriptions'));
    await tapText(tester, 'Subscriptions');
    expect(find.text('No subscriptions yet'), findsOneWidget);

    Future<void> addFromTemplate(String template, String price) async {
      await tapFinder(tester, find.byType(FloatingActionButton), frames: 10);
      await tapFinder(tester, find.descendant(of: find.byType(DraggableScrollableSheet), matching: find.text(template)), frames: 10);
      await enterText(tester, find.byKey(const Key('subscriptionPrice')), price);
      await tapFinder(tester, _filled('Save'), frames: 12);
    }

    await addFromTemplate('Netflix', '649');
    expect(find.text('₹649'), findsOneWidget, reason: 'monthly total');
    expect(find.text('₹7,788'), findsOneWidget, reason: 'yearly total');
    await addFromTemplate('Mobile recharge', '299');
    expect(find.textContaining('Every 28 days'), findsOneWidget);
    expect(find.text('₹974'), findsOneWidget, reason: '649 + 299 x 365 / 28 / 12');
    expect(find.text('₹11,686'), findsOneWidget);
    final rules = await fresh.db.select(fresh.db.recurringRules).get();
    expect(rules.every((rule) => rule.isSubscription), isTrue);
    expect(rules.firstWhere((rule) => rule.name == 'Mobile recharge').interval, 28);

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Netflix'), lessThan(top('Mobile recharge')), reason: 'cost high to low by default');
    await tapFinder(tester, find.byIcon(Icons.sort));
    await tapText(tester, 'Cost: low to high');
    expect(top('Mobile recharge'), lessThan(top('Netflix')));

    await tapText(tester, 'Netflix');
    await tapText(tester, 'Pause');
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('₹325'), findsOneWidget, reason: 'paused subscriptions leave the totals');

    await tapText(tester, 'Mobile recharge');
    await tapText(tester, 'Mark as cancelled');
    await tapText(tester, 'Mark as cancelled', last: true);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('₹0'), findsNWidgets(2));
    expect((await fresh.db.select(fresh.db.recurringRules).get()).map((rule) => rule.status).toSet(), {'paused', 'ended'});

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    expect(find.text(hi.subscriptions), findsOneWidget);
    expect(find.text(hi.subscriptionPaused), findsOneWidget);
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });

  testWidgets('27 SMS history: outcomes, filter chips, re-process, entry link, Hindi dark, clear', smsHistoryFlow);
  testWidgets(kCardDuesFlowName, cardDuesFlow, timeout: const Timeout(Duration(minutes: 15)));

  testWidgets('31 reminders: create, real OS scheduling, mark paid with a prefilled entry, history, dark, Hindi', (tester) async {
    final gatewayLog = GatewayCallLog();
    final fresh = await createApp(overrides: [recordingGatewayOverride(gatewayLog)]);
    addTearDown(fresh.container.dispose);
    final gateway = fresh.read(notificationGatewayProvider);
    // iOS: grant provisional authorization up front, silently and with no
    // system prompt, so the OS accepts the alerts and lists them (#60).
    expect(await grantProvisionalNotificationsOnIOS(), isTrue, reason: 'iOS provisional authorization; see the header if this fails');
    await startReminderNotifications(fresh.container);
    await pumpApp(tester, fresh);
    final now = DateTime.now();
    DateTime inDays(int days) => DateTime(now.year, now.month, now.day + days);

    await goTab(tester, 'Settings');
    await scrollTo(tester, find.text('Reminders'));
    expect(find.textContaining('Nothing due'), findsOneWidget);
    await tapText(tester, 'Reminders');
    expect(find.text('No reminders yet'), findsOneWidget);
    await shoot(tester, 'reminders_empty');

    await tapText(tester, 'Add reminder');
    expect(find.text('Documents & renewals'), findsOneWidget);
    await shoot(tester, 'new_reminder_sheet');
    await tapFinder(tester, find.byKey(const ValueKey('new-reminder.blank')), frames: 12);
    await enterText(tester, find.byKey(const ValueKey('reminder-title')), 'Electricity bill');
    await enterText(tester, find.byKey(const ValueKey('reminder-amount')), '2100');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
    await shoot(tester, 'reminder_editor');
    await tapFinder(tester, find.byKey(const ValueKey('reminder-save')), frames: 12);
    if (hasText("Get reminded before it's due")) {
      await shoot(tester, 'reminder_permission_sheet');
      await tapText(tester, 'Not now', frames: 12);
    }
    await waitFor(tester, find.text('Electricity bill'));
    final electricity = (await fresh.read(remindersRepositoryProvider).getUpcoming()).single;
    expect(electricity.amountMinor, 210000);

    // The alert is really with the OS: AlarmManager on Android, UNUserNotificationCenter on iOS.
    final electricityPayload = reminderPayload(electricity.id);
    final pending = await gateway.pending();
    expect(pending.where((alert) => alert.payload == electricityPayload), isNotEmpty, reason: 'scheduled with the OS');
    expect(gatewayLog.liveIdsFor(electricityPayload), isNotEmpty, reason: 'scheduled through the gateway');

    final scheduler = fresh.read(reminderSchedulerProvider);
    final card = await scheduler.save(ReminderDraft(kind: ReminderKind.card, title: 'HDFC credit card', dueAt: inDays(-2), amountMinor: 1845000, repeat: ReminderRepeat.monthly));
    await scheduler.save(ReminderDraft(kind: ReminderKind.emi, title: 'Car loan EMI', dueAt: inDays(12), amountMinor: 1250000, repeat: ReminderRepeat.monthly, remindDaysBefore: const [3, 0]));
    await scheduler.save(ReminderDraft(kind: ReminderKind.document, title: 'Passport renewal', dueAt: inDays(40), remindDaysBefore: const [30, 7, 1, 0], repeat: ReminderRepeat.once));
    await settle(tester, 12);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    await shoot(tester, 'reminders_list');

    await tapFinder(tester, find.descendant(of: find.ancestor(of: find.text('Electricity bill'), matching: find.byType(ListTile)), matching: find.byIcon(Icons.check_circle_outline)), frames: 12);
    expect(find.text('Paid Electricity bill?'), findsOneWidget);
    await shoot(tester, 'reminder_paid_sheet');
    await tapText(tester, 'Add entry & mark paid', frames: 16);
    expect(find.byType(ExpenseEditorScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, '2100'), findsOneWidget);
    await shoot(tester, 'reminder_paid_entry');
    // The reminder has no category, so pick one or Save stops at "Pick a category" (#107).
    await _pickCategory(tester, 'electricity', 'Electricity');
    await tapFinder(tester, find.textContaining('Save').last, frames: 16);
    final paid = (await fresh.read(remindersRepositoryProvider).getById(electricity.id))!;
    expect(paid.status, 'done');
    expect(paid.entryId, isNotNull);
    final pendingAfterPaid = await gateway.pending();
    expect(pendingAfterPaid.where((alert) => alert.payload == electricityPayload), isEmpty, reason: 'paid reminder alerts cancelled');
    expect(gatewayLog.liveIdsFor(electricityPayload), isEmpty, reason: 'paid reminder alerts cancelled through the gateway');

    await scheduler.skip(card);
    await tapText(tester, 'History');
    expect(find.textContaining('Paid '), findsOneWidget);
    await shoot(tester, 'reminders_history');
    await tapText(tester, 'Upcoming');

    await fresh.read(settingsProvider.notifier).update((s) => s.copyWith(themeMode: ThemeMode.dark));
    await settle(tester, 8);
    await shoot(tester, 'dark_reminders_list');
    await tapFinder(tester, find.byType(FloatingActionButton), frames: 12);
    await shoot(tester, 'dark_new_reminder_sheet');
    await tapFinder(tester, find.byKey(const ValueKey('new-reminder.preset.puc')), frames: 12);
    await shoot(tester, 'dark_reminder_editor');
    await goBack(tester);

    await fresh.read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: 'hi'));
    await settle(tester, 8);
    final hi = AppLocalizationsHi();
    // Hindi uses "रिमाइंडर" for both the title and the FAB label, so check the title in the app bar (#108).
    expect(find.descendant(of: find.byType(AppBar), matching: find.text(hi.remindersTitle)), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingActionButton), matching: find.text(hi.reminderFab)), findsOneWidget);
    await shoot(tester, 'hi_dark_reminders_list');
    await fresh.read(settingsProvider.notifier).update((s) => s.copyWith(themeMode: ThemeMode.light));
    await settle(tester, 8);
    await shoot(tester, 'hi_reminders_list');
    await tapFinder(tester, find.byType(FloatingActionButton), frames: 12);
    await shoot(tester, 'hi_new_reminder_sheet');
    await tapFinder(tester, find.byKey(const ValueKey('new-reminder.preset.puc')), frames: 12);
    await shoot(tester, 'hi_reminder_editor');
    await goBack(tester);
    await tapText(tester, hi.reminderTabHistory);
    await shoot(tester, 'hi_reminders_history');
    await fresh.read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: 'en'));
    await settle(tester, 6);
    for (final reminder in await fresh.read(remindersRepositoryProvider).getUpcoming()) {
      await scheduler.delete(reminder.id);
    }
  });

  testWidgets('37 groups: schedule a settle-up reminder on the Balances tab, share a nudge, turn it off', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final groups = fresh.read(groupsRepositoryProvider);
    final flatGroupId = await groups.createGroup(name: 'Flat 302', icon: 'home', myName: 'You', otherMembers: ['Ravi']);
    final members = await groups.getMembers(flatGroupId);
    await groups.addSettlement(
      groupId: flatGroupId,
      fromMemberId: members.firstWhere((member) => member.isMe).id,
      toMemberId: members.firstWhere((member) => member.name == 'Ravi').id,
      amountMinor: 50000,
      occurredAt: DateTime.now(),
    );
    await pumpApp(tester, fresh);
    await goTab(tester, 'Groups');
    await tapText(tester, 'Flat 302');
    await tapText(tester, 'Balances');
    await scrollTo(tester, find.text('Remind me to settle up'));
    expect(find.text('Settle-up reminder off'), findsOneWidget);
    await tapText(tester, 'Remind me to settle up');
    await tapText(tester, 'Ravi', last: true);
    await shoot(tester, 'settle_reminder_sheet');
    await tapText(tester, 'Save');
    if (find.text('Not now').evaluate().isNotEmpty) await tapText(tester, 'Not now');
    expect(find.text('Reminder on day 1 every month'), findsOneWidget);
    final schedule = await fresh.read(settleScheduleRepositoryProvider).scheduleOf(flatGroupId);
    expect(schedule?.memberId, members.firstWhere((member) => member.name == 'Ravi').id);
    expect(find.byTooltip('Share a nudge'), findsOneWidget, reason: 'something is owed, so a nudge can be shared');
    await shoot(tester, 'settle_reminder_on');

    await tapText(tester, 'Remind me to settle up');
    await tapText(tester, 'Turn off');
    expect(find.text('Settle-up reminder off'), findsOneWidget);
    expect(await fresh.read(settleScheduleRepositoryProvider).scheduleOf(flatGroupId), isNull);
  });

  testWidgets('32 salary day: set up from Settings, align month start, reminder clears when an SMS salary arrives, Hindi', (tester) async {
    final alerts = _RecordingSalaryAlerts();
    final fresh = await createApp(overrides: [salaryAlertSinkProvider.overrideWithValue(alerts)]);
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    Finder key(String id) => find.byKey(ValueKey(id));
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(monthStartDay: 25));
    if (Platform.isAndroid) {
      // Granted by the driver (see the header), so saving shows no system prompt.
      final permission = await fresh.read(notificationGatewayProvider).permissionState();
      expect(permission.notificationsAllowed, isTrue, reason: 'grant POST_NOTIFICATIONS before flow 32; see the file header');
    }
    await pumpApp(tester, fresh);

    await goTab(tester, 'Settings');
    await scrollTo(tester, key('settingsSalary'));
    expect(find.text('Set up salary day'), findsOneWidget);
    await tapFinder(tester, key('settingsSalary'), frames: 10);
    expect(find.byType(SalarySetupScreen), findsOneWidget);
    expect(tester.widget<FilledButton>(key('salarySave')).onPressed, isNull, reason: 'no amount yet');
    expect(find.text('Your month starts on day 25, salary arrives on day 1'), findsOneWidget);
    await enterText(tester, key('salaryAmount'), '85000');
    await shoot(tester, 'salary_setup');
    await scrollTo(tester, key('salaryTolerance'), within: find.byType(SalarySetupScreen));
    expect(find.text('Up to 4 days'), findsOneWidget, reason: 'default match window');
    expect(find.text('Up to 15%'), findsOneWidget, reason: 'default amount tolerance');
    await shoot(tester, 'salary_detection');
    await tapFinder(tester, key('salarySave'), frames: 10);
    expect(find.text('Start months on day 1?'), findsOneWidget);
    await tapText(tester, 'Align', last: true, frames: 10);
    expect(fresh.read(settingsProvider).monthStartDay, 1);
    final salary = fresh.read(salarySettingsProvider);
    expect(salary.isSetUp, isTrue);
    expect(salary.amountMinor, 8500000);
    final rule = (await (fresh.db.select(fresh.db.recurringRules)..where((t) => t.id.equals(salary.ruleId))).getSingle());
    expect((rule.kind, rule.amountMinor, rule.dayOfMonth, rule.autoPost), ('income', 8500000, 1, false));
    await scrollTo(tester, key('settingsSalary'));
    expect(find.text('${formatMinor(8500000)} on day 1'), findsOneWidget);

    // Expected three days ago, reminder one day after: "Salary not seen yet" is due now.
    // The day change goes through the service like a save on the screen, as if
    // made the day before the salary was due, so the rule and the setup agree
    // and that cycle counts (nothing before the rule's start is late).
    final now = DateTime.now();
    final expected = DateTime(now.year, now.month, now.day - 3);
    final moved = await fresh.read(salaryServiceProvider).saveSalaryRule(
          settings: salary.copyWith(salaryDay: expected.day, shift: SalaryShift.sameDay, reminderDelayDays: 1),
          today: DateTime(expected.year, expected.month, expected.day - 1),
          monthStartDay: fresh.read(settingsProvider).monthStartDay,
        );
    await fresh.read(salarySettingsProvider.notifier).save(moved);
    await settle(tester, 10);
    expect(alerts.last, isA<ScheduleSalaryNotification>());
    expect((alerts.last as ScheduleSalaryNotification).expected, expected);

    // An SMS-added salary entry dismisses it without any user action.
    await fresh.db.into(fresh.db.entries).insert(EntriesCompanion.insert(
          id: 'sms-salary',
          kind: 'income',
          amountMinor: 8450000,
          occurredAt: DateTime(expected.year, expected.month, expected.day, 11),
          source: const Value('sms'),
        ));
    await settle(tester, 10);
    expect(alerts.last, isA<CancelSalaryNotification>());
    final linked = await (fresh.db.select(fresh.db.entries)..where((t) => t.id.equals('sms-salary'))).getSingle();
    expect(linked.recurringId, salary.ruleId, reason: 'the SMS entry settles the rule occurrence');

    await scrollTo(tester, key('settingsSalary'));
    await tapFinder(tester, key('settingsSalary'), frames: 10);
    expect(find.textContaining('Received'), findsOneWidget);
    await shoot(tester, 'salary_received');

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    expect(find.text(hi.salaryTitle), findsWidgets);
    await scrollTo(tester, key('salaryReminderSwitch'), within: find.byType(SalarySetupScreen));
    expect(find.text(hi.salaryTolerance), findsOneWidget);
    expect(find.text(hi.salaryReminder), findsOneWidget);
    await shoot(tester, 'hi_salary_setup');
    await goBack(tester);
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });

  testWidgets('36 upcoming: overdue confirm-first rule, 7/30-day toggle, calendar dots and month switch, Hindi', (tester) async {
    final fresh = await createApp();
    addTearDown(fresh.container.dispose);
    final hi = AppLocalizationsHi();
    final today = startOfDay(DateTime.now());
    Finder key(String id) => find.byKey(ValueKey(id));
    await fresh
        .read(recurringRepositoryProvider)
        .saveRule(
          RecurringRepository.newRule(
            name: 'Rent',
            kind: 'expense',
            amountMinor: 1500000,
            frequency: RecurrenceFrequency.monthly,
            dayOfMonth: today.subtract(const Duration(days: 3)).day,
            startDate: today.subtract(const Duration(days: 3)),
            autoPost: false,
          ),
        );
    await fresh
        .read(remindersRepositoryProvider)
        .save(ReminderDraft(kind: ReminderKind.bill, title: 'Electricity', dueAt: today.add(const Duration(days: 12)), amountMinor: 184000));
    await pumpApp(tester, fresh);

    await scrollTo(tester, find.byKey(kUpcomingCardKey));
    expect(find.text('Rent'), findsOneWidget, reason: 'a confirm-first rule past its date stays on the card');
    expect(find.text('Electricity'), findsNothing, reason: 'a bill 12 days out is outside the 7-day window');
    await shoot(tester, 'upcoming_card_week');
    await tapFinder(tester, key('upcoming.window.month'), frames: 10);
    expect(find.text('Electricity'), findsOneWidget, reason: 'the 30-day window brings the bill in');
    expect(find.text('Rent'), findsNWidgets(2), reason: 'the overdue Rent and next month\'s Rent are two occurrences, each listed once');
    await shoot(tester, 'upcoming_card_month');

    await tapFinder(tester, key('upcoming.calendar'), frames: 10);
    expect(find.byType(UpcomingCalendarScreen), findsOneWidget);
    final monthLabel = tester.widget<Text>(key('upcoming.calendar.month')).data;
    await shoot(tester, 'upcoming_calendar');
    await tapFinder(tester, key('upcoming.calendar.day.${today.day}'), frames: 6);
    await tapFinder(tester, find.byTooltip('Next month'), frames: 6);
    expect(tester.widget<Text>(key('upcoming.calendar.month')).data, isNot(monthLabel), reason: 'the header follows the shown month');
    await goBack(tester);

    await scrollTo(tester, find.byKey(kUpcomingCardKey));
    await tapFinder(tester, find.text('Rent').first, frames: 10);
    expect(find.byKey(const ValueKey('upcoming.confirm.edit')), findsOneWidget, reason: 'an overdue confirm-first item offers Edit as the secondary action');
    await shoot(tester, 'upcoming_confirm_sheet');
    await tapFinder(tester, key('upcoming.confirm.post'), frames: 12);
    expect(find.text('Rent'), findsOneWidget, reason: 'confirming posts the overdue Rent; next month stays listed');

    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester, 10);
    await scrollTo(tester, find.byKey(kUpcomingCardKey));
    expect(find.text(hi.upcoming), findsWidgets);
    await shoot(tester, 'hi_upcoming_card');
    await fresh.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'en'));
    await settle(tester, 6);
  });
}

class _RecordingSalaryAlerts implements SalaryAlertSink {
  final plans = <SalaryNotificationPlan>[];
  SalaryNotificationPlan? get last => plans.isEmpty ? null : plans.last;

  @override
  String get locale => 'en';

  @override
  Future<bool> isPending() async => false;

  @override
  Future<bool> apply(SalaryNotificationPlan plan) async {
    plans.add(plan);
    return true;
  }
}

