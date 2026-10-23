// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hisab';

  @override
  String get tabHome => 'Home';

  @override
  String get tabEntries => 'Entries';

  @override
  String get tabGroups => 'Groups';

  @override
  String get tabSettings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get edit => 'Edit';

  @override
  String get rename => 'Rename';

  @override
  String get add => 'Add';

  @override
  String get ignore => 'Ignore';

  @override
  String get allow => 'Allow';

  @override
  String get notNow => 'Not now';

  @override
  String get ok => 'OK';

  @override
  String get name => 'Name';

  @override
  String get note => 'Note';

  @override
  String get all => 'All';

  @override
  String get others => 'Others';

  @override
  String get unknown => 'Unknown';

  @override
  String get you => 'You';

  @override
  String youSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get required => 'Required';

  @override
  String get seeAll => 'See all';

  @override
  String get manage => 'Manage';

  @override
  String get kindExpense => 'Expense';

  @override
  String get kindIncome => 'Income';

  @override
  String get kindTransfer => 'Transfer';

  @override
  String get kindExpenses => 'Expenses';

  @override
  String get kindTransfers => 'Transfers';

  @override
  String get uncategorised => 'Uncategorised';

  @override
  String yourShareOf(String group) {
    return '$group · your share';
  }

  @override
  String get sourceSms => 'SMS';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get accountTypeBank => 'Bank account';

  @override
  String get accountTypeCard => 'Credit card';

  @override
  String get accountTypeWallet => 'Wallet / UPI';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accounts => 'Accounts';

  @override
  String get account => 'Account';

  @override
  String get newAccount => 'New account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get accountNameHint => 'HDFC Savings, Paytm, Cash';

  @override
  String get outstandingBalance => 'Amount due on the card';

  @override
  String cardDue(String amount) {
    return 'Due $amount';
  }

  @override
  String get currentBalance => 'Current balance';

  @override
  String get includeInTotal => 'Include in total balance';

  @override
  String get excludedFromTotal => 'excluded from total';

  @override
  String asOf(String date) {
    return 'as of $date';
  }

  @override
  String get noAccountsTitle => 'No accounts yet';

  @override
  String get noAccountsBody =>
      'Bank accounts detected from SMS are added automatically with their reported balance. Manual entries adjust the balance of the account you pick.';

  @override
  String deleteNamed(String name) {
    return 'Delete $name?';
  }

  @override
  String get budgets => 'Budgets';

  @override
  String get budget => 'Budget';

  @override
  String get overall => 'Overall';

  @override
  String get category => 'Category';

  @override
  String get overallMonthlyBudget => 'Overall monthly budget';

  @override
  String get budgetForCategory => 'Budget for a category';

  @override
  String get overallMonthlyLimit => 'Overall monthly limit';

  @override
  String categoryMonthlyLimit(String category) {
    return '$category monthly limit';
  }

  @override
  String get noBudgetsTitle => 'No budgets yet';

  @override
  String get noBudgetsBody =>
      'Set a monthly limit overall or per category. The dashboard shows pace and what is left.';

  @override
  String get removeBudgetQuestion => 'Remove this budget?';

  @override
  String budgetOverBy(String amount, String limit) {
    return 'Over $limit by $amount';
  }

  @override
  String budgetLeftWithDays(String amount, String limit, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$amount of $limit left · $_temp0';
  }

  @override
  String get budgetRemoved => 'Budget removed';

  @override
  String get undo => 'Undo';

  @override
  String get setOpeningBalance => 'Set opening balance';

  @override
  String get setBudget => 'Set a budget';

  @override
  String get startGroup => 'Start a group';

  @override
  String get categories => 'Categories';

  @override
  String unitsLabel(String units) {
    return 'Units: $units';
  }

  @override
  String get addSubcategory => 'Add subcategory';

  @override
  String get deleteCategoryBody =>
      'Existing entries keep their amounts but become uncategorised.';

  @override
  String get archiveCategory => 'Archive (hide from picker)';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get newCategory => 'New category';

  @override
  String newSubcategoryOf(String parent) {
    return 'New subcategory of $parent';
  }

  @override
  String editNamed(String name) {
    return 'Edit $name';
  }

  @override
  String get unitsForItems => 'Units for items (comma separated)';

  @override
  String get colour => 'Colour';

  @override
  String get icon => 'Icon';

  @override
  String get searchCategories => 'Search categories';

  @override
  String get noMatchingCategory => 'No matching category';

  @override
  String moreCount(int count) {
    return '+$count';
  }

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String smsToReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SMS to review',
      one: '1 SMS to review',
    );
    return '$_temp0';
  }

  @override
  String get spentThisMonth => 'Spent this month';

  @override
  String get income => 'Income';

  @override
  String get saved => 'Saved';

  @override
  String get overspent => 'Overspent';

  @override
  String get balances => 'Balances';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get recent => 'Recent';

  @override
  String get noEntriesThisMonthTitle => 'No entries this month';

  @override
  String get noEntriesThisMonthBody =>
      'Tap + to add your first expense, or turn on SMS reading in Settings.';

  @override
  String get newEntry => 'New entry';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get groupExpense => 'Group expense';

  @override
  String get deleteEntryQuestion => 'Delete this entry?';

  @override
  String totalOfItems(int count) {
    return 'Total of $count items';
  }

  @override
  String get chooseCategory => 'Choose category';

  @override
  String get fromAccount => 'From account';

  @override
  String get toAccount => 'To account';

  @override
  String get payeeLabel => 'Paid to / received from';

  @override
  String get smsEntryNotice =>
      'Created from a bank SMS. Editing it will not change your bank balance.';

  @override
  String get saving => 'Saving…';

  @override
  String saveAmount(String amount) {
    return 'Save $amount';
  }

  @override
  String get addAccount => 'Add account';

  @override
  String get items => 'Items';

  @override
  String get addItem => 'Add item';

  @override
  String itemSuggestion(String name, String quantity, String price) {
    return '$name · $quantity @ $price';
  }

  @override
  String get itemsHelp =>
      'Optional: break this expense into items with quantity and price (e.g. buffalo milk 1 L). Hisab remembers them for next time.';

  @override
  String get paidBy => 'Paid by';

  @override
  String get split => 'Split';

  @override
  String get invalidAmount => 'Enter a valid amount, e.g. 250 or 99.50';

  @override
  String get errorAmountZero => 'Enter an amount greater than zero';

  @override
  String get errorPickCategory => 'Pick a category';

  @override
  String get errorPickBothAccounts => 'Pick both accounts for a transfer';

  @override
  String get errorItemName => 'Every item needs a name';

  @override
  String get errorChoosePayer => 'Choose who paid';

  @override
  String get errorFixSplit => 'Fix the split first';

  @override
  String get itemName => 'Item name';

  @override
  String get qty => 'Qty';

  @override
  String get unit => 'Unit';

  @override
  String pricePerUnit(String unit) {
    return 'Price per $unit';
  }

  @override
  String get genericUnit => 'unit';

  @override
  String get shareSummary => 'Share summary';

  @override
  String get renameGroup => 'Rename group';

  @override
  String get deleteGroupBody => 'All expenses in this group will be removed.';

  @override
  String get simplifyOn => 'Turn on simplify debts';

  @override
  String get simplifyOff => 'Turn off simplify debts';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get addMemberFirst => 'Add at least one more member first';

  @override
  String get addExpense => 'Add expense';

  @override
  String get members => 'Members';

  @override
  String shareHeader(String group) {
    return '$group — balances';
  }

  @override
  String sharePays(String from, String to, String amount) {
    return '$from pays $to $amount';
  }

  @override
  String get allSettledUp => 'All settled up.';

  @override
  String get sharedFromHisab => 'Shared from Hisab';

  @override
  String paidByPeople(String payer, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$payer paid · $_temp0';
  }

  @override
  String yourShare(String amount) {
    return 'you: $amount';
  }

  @override
  String settlementLine(String from, String to) {
    return '$from paid $to';
  }

  @override
  String get settledPayments => 'Settled payments';

  @override
  String paymentRecorded(String transfer, String amount) {
    return 'Recorded $transfer $amount';
  }

  @override
  String get paymentRemoved => 'Payment removed';

  @override
  String get removePayment => 'Remove payment';

  @override
  String get removePaymentBody =>
      'The balances will go back to what they were before this payment.';

  @override
  String get moreOptions => 'More options';

  @override
  String get noGroupExpensesTitle => 'No expenses yet';

  @override
  String get noGroupExpensesBody =>
      'Add the first shared expense; Hisab works out who owes whom.';

  @override
  String get netBalances => 'Net balances';

  @override
  String get getsBack => 'gets back';

  @override
  String get owes => 'owes';

  @override
  String get settleUp => 'Settle up';

  @override
  String get settleUpSimplified => 'Settle up (simplified)';

  @override
  String get everyoneSettled => 'Everyone is settled up';

  @override
  String transferArrow(String from, String to) {
    return '$from → $to';
  }

  @override
  String get recordPayment => 'Record payment';

  @override
  String get settleBeforeRemove =>
      'Settle this member\'s balance before removing them';

  @override
  String removeNamed(String name) {
    return 'Remove $name?';
  }

  @override
  String get renameMember => 'Rename member';

  @override
  String get addMember => 'Add member';

  @override
  String get memberName => 'Member name';

  @override
  String get membersLocalNotice =>
      'Members are stored on this device. Shared sync with invite codes is planned; see Settings → Sync.';

  @override
  String get newGroup => 'New group';

  @override
  String get groupName => 'Group name';

  @override
  String get groupNameHint => 'Goa trip, Flat 302…';

  @override
  String get membersCommaSeparated => 'Members (comma separated)';

  @override
  String get membersHint => 'Rahul, Priya, Aman';

  @override
  String get createGroup => 'Create group';

  @override
  String get groups => 'Groups';

  @override
  String get noGroupsTitle => 'Split bills with friends';

  @override
  String get noGroupsBody =>
      'Create a group for a trip, flat or dinner. Add expenses, split them equally, by percentage, shares or exact amounts, and settle up.';

  @override
  String get youAreOwed => 'You are owed';

  @override
  String get youOwe => 'You owe';

  @override
  String groupSubtitle(int count, String amount) {
    return '$count members · $amount spent';
  }

  @override
  String get youGet => 'you get';

  @override
  String get youOweLower => 'you owe';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get money => 'Money';

  @override
  String get currencySymbol => 'Currency symbol';

  @override
  String get monthStartsOn => 'Month starts on';

  @override
  String get monthStartsOnHelp => 'Use your salary date';

  @override
  String get monthStartsOnExplain =>
      'Budgets and monthly totals follow your pay cycle';

  @override
  String dayNumber(int day) {
    return 'Day $day';
  }

  @override
  String get monthStartPrompt => 'Month starts on day (1–28)';

  @override
  String get automation => 'Automation';

  @override
  String get bankSms => 'Bank SMS';

  @override
  String get bankSmsOn => 'On · reading bank SMS on this device';

  @override
  String get off => 'Off';

  @override
  String get yourNameInGroups => 'Your name in groups';

  @override
  String get yourName => 'Your name';

  @override
  String get backupAndSync => 'Backup & sync';

  @override
  String get exportBackup => 'Export encrypted backup';

  @override
  String get exportBackupHelp =>
      'AES-256, protected by a passphrase you choose';

  @override
  String get restoreBackup => 'Restore from backup';

  @override
  String get restoreBackupHelp => 'Merges; newer local edits are kept';

  @override
  String get cloudSync => 'Cloud sync';

  @override
  String get cloudSyncHelp =>
      'Coming next: Google Drive on Android, iCloud on iOS, end-to-end encrypted with the same format as backups.';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Free, open source, no ads, no account needed. Your data stays on your device.';

  @override
  String get backupPassphrase => 'Backup passphrase';

  @override
  String get backupPassphraseHelp =>
      'At least 8 characters; you need it to restore';

  @override
  String get passphraseTooShort => 'Use at least 8 characters';

  @override
  String get backupShareSubject => 'Hisab encrypted backup';

  @override
  String restoredRecords(int count) {
    return 'Restored $count records';
  }

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get pasted => 'PASTED';

  @override
  String get smsFoundReview => 'Transaction found. Review it below.';

  @override
  String get smsAdded => 'Transaction added.';

  @override
  String get smsDuplicate => 'Already imported.';

  @override
  String get smsNotFound => 'Could not find a transaction in that text.';

  @override
  String get readBankSmsQuestion => 'Read bank SMS?';

  @override
  String get smsConsentBody =>
      'Hisab reads SMS from your bank and UPI apps to log transactions and show account balances. Messages are processed on this device only and never uploaded. OTPs and promotional SMS are ignored. You can turn this off any time.';

  @override
  String get smsPermissionDenied => 'SMS permission was not granted';

  @override
  String scanResult(int scanned, int added, int pending) {
    return 'Scanned $scanned messages: $added added, $pending waiting for review.';
  }

  @override
  String get readBankSmsAuto => 'Read bank SMS automatically';

  @override
  String get smsAndroidOnly =>
      'Android only. Processed on-device, never uploaded.';

  @override
  String get smsNotOnIos =>
      'Not available on iOS. Use the Shortcut or paste below.';

  @override
  String get smsAutoAddTitle => 'Add transactions without review';

  @override
  String get smsAutoAddHelp => 'Off: new SMS wait in the review list below.';

  @override
  String get scanInboxNow => 'Scan inbox now';

  @override
  String get scanInboxHelp =>
      'Looks back 90 days the first time, then only new messages';

  @override
  String get pasteSms => 'Paste an SMS';

  @override
  String get pasteSmsHelp => 'Works on iOS and Android';

  @override
  String get pasteBankSms => 'Paste bank SMS';

  @override
  String get pasteBankSmsHint => 'Rs.500 debited from A/c XX1234…';

  @override
  String toReview(int count) {
    return 'To review ($count)';
  }

  @override
  String get nothingWaitingTitle => 'Nothing waiting';

  @override
  String get nothingWaitingBody => 'New bank transactions will show up here.';

  @override
  String get iosShortcutHelp =>
      'iPhone: create a Shortcuts automation \"When I get a message containing \'debited\'\" → \"Open URL\" with hisab:///sms?text=[Message]. Hisab will open and queue the transaction for review.';

  @override
  String get couldNotAddUseEdit => 'Could not add this one; use Edit';

  @override
  String addAmount(String amount) {
    return 'Add $amount';
  }

  @override
  String get splitDoesNotAddUp => 'Split does not add up';

  @override
  String splitsAcross(String amount, int count) {
    return 'Splits $amount across $count people';
  }

  @override
  String get splitEqual => 'Equally';

  @override
  String get splitExact => 'Exact amounts';

  @override
  String get splitPercent => 'Percentages';

  @override
  String get splitShares => 'Shares / ratio';

  @override
  String get splitAdjustment => 'Adjustments';

  @override
  String get splitByItem => 'By item';

  @override
  String get splitHelpEqual => 'Everyone ticked pays the same share.';

  @override
  String get splitHelpExact =>
      'Enter the exact amount each person owes; must add up to the total.';

  @override
  String get splitHelpPercent => 'Enter percentages adding up to 100.';

  @override
  String get splitHelpShares =>
      'Enter shares, e.g. 2 for a couple and 1 for a single.';

  @override
  String get splitHelpAdjustment =>
      'Extras are charged first, the rest is split equally among ticked people.';

  @override
  String get splitHelpByItem =>
      'Each item is split among the people who shared it.';

  @override
  String get entries => 'Entries';

  @override
  String get searchEntriesHint => 'Search payee, note, item or category';

  @override
  String get noEntriesTitle => 'Nothing here yet';

  @override
  String get noEntriesBody =>
      'Entries for this month will appear grouped by day.';

  @override
  String get settled => 'settled';

  @override
  String get unitsHint => 'L, ml, kg';

  @override
  String get splitErrorNegativeTotal => 'Amount cannot be negative';

  @override
  String get splitErrorNobodyIncluded => 'Select at least one person';

  @override
  String get splitErrorNegativeAmounts => 'Amounts cannot be negative';

  @override
  String splitErrorAmountLeft(String amount) {
    return '$amount left to assign';
  }

  @override
  String splitErrorAmountOver(String amount) {
    return '$amount over the total';
  }

  @override
  String get splitErrorNegativeValues => 'Values cannot be negative';

  @override
  String get splitErrorPercentMustTotal => 'Percentages must add up to 100';

  @override
  String get splitErrorNoShares => 'Enter at least one share';

  @override
  String splitErrorPercentLeft(String percent) {
    return '$percent% left to assign';
  }

  @override
  String splitErrorPercentOver(String percent) {
    return '$percent% over 100';
  }

  @override
  String splitErrorAdjustmentsExceed(String amount) {
    return 'Adjustments exceed the total by $amount';
  }

  @override
  String get splitErrorAdjustmentNegativeShare =>
      'An adjustment makes a share negative';

  @override
  String get splitErrorNoItems => 'Add at least one item';

  @override
  String splitErrorItemsExceed(String amount) {
    return 'Items exceed the total by $amount';
  }

  @override
  String splitErrorItemUnassigned(String item) {
    return 'Assign \"$item\" to someone';
  }

  @override
  String get genericItem => 'item';

  @override
  String spentInMonth(String month) {
    return 'Spent in $month';
  }

  @override
  String vsLastMonthUp(int percent, String month) {
    return '▲ $percent% vs $month';
  }

  @override
  String vsLastMonthDown(int percent, String month) {
    return '▼ $percent% vs $month';
  }

  @override
  String vsLastMonthSame(String month) {
    return 'Same as $month';
  }

  @override
  String get dailyAverage => 'Daily avg';

  @override
  String perDay(String amount) {
    return '$amount/day';
  }

  @override
  String daysOfMonth(int elapsed, int total) {
    return '$elapsed of $total days';
  }

  @override
  String get heroEmptyCaption => 'Nothing spent yet this month';

  @override
  String get addFirstEntry => 'Add your first entry';

  @override
  String get copied => 'Copied';

  @override
  String get spendingTrend => 'Spending trend';

  @override
  String get trendDaily => 'Daily';

  @override
  String get trendMonthly => 'Monthly';

  @override
  String get trendEmpty => 'Add a few entries to see your trend';

  @override
  String trendSemantics(String amount) {
    return 'Spending trend: $amount spent so far this month';
  }

  @override
  String get thisMonth => 'this month';

  @override
  String get categoriesEmpty => 'Your categories will show up here';

  @override
  String percentOf(int percent) {
    return '$percent%';
  }

  @override
  String get budgetsEmptyBody => 'Set a budget to see how you\'re tracking';

  @override
  String andMoreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more',
      one: '1 more',
    );
    return 'and $_temp0';
  }

  @override
  String youGetAmount(String amount) {
    return 'You get $amount';
  }

  @override
  String youOweAmount(String amount) {
    return 'You owe $amount';
  }

  @override
  String get upcoming => 'Upcoming';

  @override
  String get upcomingEmpty => 'Nothing due in the next two weeks';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get noEntriesYetTitle => 'No entries yet';

  @override
  String get noEntriesYetBody =>
      'Add one with + or turn on Bank SMS to capture them automatically';

  @override
  String get addEntry => 'Add entry';

  @override
  String get showAllCategories => 'Show all categories';

  @override
  String get projects => 'Projects';

  @override
  String get project => 'Project';

  @override
  String get newProject => 'New project';

  @override
  String get blankProject => 'Blank project';

  @override
  String get editProject => 'Edit project';

  @override
  String get projectName => 'Project name';

  @override
  String get noProjectsTitle => 'No projects yet';

  @override
  String get noProjectsBody =>
      'Track a car, a renovation, a trip or a wedding against its own budget.';

  @override
  String get startProject => 'Start a project';

  @override
  String get projectsEmptyBody =>
      'Start a project to track a big spend against its budget';

  @override
  String get projectStatusActive => 'Active';

  @override
  String get projectStatusCompleted => 'Completed';

  @override
  String get projectStatusArchived => 'Archived';

  @override
  String get showArchived => 'Show archived';

  @override
  String get hideArchived => 'Hide archived';

  @override
  String spentOfBudget(String spent, String budget) {
    return '$spent of $budget';
  }

  @override
  String spentAmount(String amount) {
    return '$amount spent';
  }

  @override
  String leftOfBudget(String amount, String budget) {
    return '$amount of $budget left';
  }

  @override
  String receivedAmount(String amount) {
    return '$amount came back';
  }

  @override
  String get noBudgetSet => 'No budget set';

  @override
  String get allTime => 'all time';

  @override
  String entryCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get noProjectEntriesTitle => 'Nothing spent yet';

  @override
  String get noProjectEntriesBody =>
      'Add an entry from here and it counts towards this project';

  @override
  String get markCompleted => 'Mark completed';

  @override
  String get reopenProject => 'Reopen';

  @override
  String get archiveProject => 'Archive';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get deleteProjectBody =>
      'Entries stay in your ledger; they just leave this project.';

  @override
  String get projectDeleted => 'Project deleted';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get notSet => 'Not set';

  @override
  String get budgetOptional => 'Budget (optional)';

  @override
  String get notes => 'Notes';

  @override
  String get projectNotFound => 'This project was deleted';

  @override
  String get spentSoFar => 'Spent so far';

  @override
  String get spendingByMonth => 'Spending by month';

  @override
  String get projectMarkedCompleted => 'Marked completed';

  @override
  String get projectArchivedSnack => 'Project archived';

  @override
  String get projectReopened => 'Project reopened';

  @override
  String projectDates(String start, String end) {
    return '$start – $end';
  }

  @override
  String sinceDate(String date) {
    return 'Since $date';
  }

  @override
  String untilDate(String date) {
    return 'Until $date';
  }

  @override
  String get startFromTemplate => 'Start from a template';

  @override
  String get blankProjectHint => 'Name it and track anything';

  @override
  String get templateVehicle => 'Vehicle';

  @override
  String get templateVehicleHint => 'Fuel, service, insurance and cost per km';

  @override
  String get templateConstruction => 'Home construction';

  @override
  String get templateConstructionHint =>
      'Materials, labour, stages and cost per sq ft';

  @override
  String get templateRenovation => 'Renovation';

  @override
  String get templateRenovationHint => 'Room by room, materials and workers';

  @override
  String get templateTrip => 'Trip';

  @override
  String get templateTripHint => 'Travel, stay, food and sightseeing';

  @override
  String get templateWedding => 'Wedding';

  @override
  String get templateWeddingHint =>
      'Venue, catering, outfits, vendors and shagun';

  @override
  String get addSuggestedCategories => 'Add suggested categories';

  @override
  String suggestedCategoriesNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new categories',
      one: '1 new category',
    );
    return '$_temp0';
  }

  @override
  String suggestedCategoriesReused(int count) {
    return '$count already in your list';
  }

  @override
  String get categoryPacks => 'Category packs';

  @override
  String get addAPack => 'Add a pack';

  @override
  String get categoryPacksHint =>
      'Ready-made sets of categories for a part of your life. Add one in a tap and remove it any time.';

  @override
  String packCategoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$_temp0';
  }

  @override
  String get packAdded => 'Added';

  @override
  String get addPack => 'Add pack';

  @override
  String get removePack => 'Remove pack';

  @override
  String packAddedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pack added with $count new categories',
      one: 'Pack added with 1 new category',
      zero: 'Pack added. You already had all its categories',
    );
    return '$_temp0';
  }

  @override
  String removePackTitle(String pack) {
    return 'Remove $pack?';
  }

  @override
  String removePackMessage(int archived, int kept) {
    return 'Unused categories ($archived) will be archived. Categories in use ($kept) stay as your own.';
  }

  @override
  String get packRemoved => 'Pack removed';

  @override
  String get packAlreadyHave => 'Already in your list';

  @override
  String get suggestedCategoriesAllPresent =>
      'All suggested categories are already in your list';

  @override
  String get projectDetails => 'Project details';

  @override
  String get fieldOdometer => 'Odometer';

  @override
  String get fieldLitres => 'Fuel litres';

  @override
  String get fieldBuiltUpArea => 'Built-up area';

  @override
  String get fieldStage => 'Stage';

  @override
  String get fieldQuantity => 'Quantity';

  @override
  String get fieldRoom => 'Room';

  @override
  String get fieldTravellers => 'Travellers';

  @override
  String get fieldEvent => 'Event';

  @override
  String get fieldVendor => 'Vendor';

  @override
  String get stageFoundation => 'Foundation';

  @override
  String get stagePlinth => 'Plinth';

  @override
  String get stageStructure => 'Structure';

  @override
  String get stageBrickwork => 'Brickwork';

  @override
  String get stageRoofSlab => 'Roof slab';

  @override
  String get stagePlaster => 'Plaster';

  @override
  String get stageElectricalPlumbing => 'Electrical & plumbing';

  @override
  String get stageFlooring => 'Flooring';

  @override
  String get stageDoorsWindows => 'Doors & windows';

  @override
  String get stagePainting => 'Painting';

  @override
  String get stageFinishing => 'Finishing';

  @override
  String get roomKitchen => 'Kitchen';

  @override
  String get roomBathroom => 'Bathroom';

  @override
  String get roomBedroom => 'Bedroom';

  @override
  String get roomLivingRoom => 'Living room';

  @override
  String get roomDining => 'Dining';

  @override
  String get roomBalcony => 'Balcony';

  @override
  String get roomWholeHouse => 'Whole house';

  @override
  String get eventRoka => 'Roka';

  @override
  String get eventEngagement => 'Engagement';

  @override
  String get eventHaldi => 'Haldi';

  @override
  String get eventMehndi => 'Mehndi';

  @override
  String get eventSangeet => 'Sangeet';

  @override
  String get eventWedding => 'Wedding';

  @override
  String get eventReception => 'Reception';

  @override
  String get projectMetrics => 'Metrics';

  @override
  String get costPerKm => 'Cost per km';

  @override
  String kmDriven(String km) {
    return '$km km driven';
  }

  @override
  String get fuelBought => 'Fuel bought';

  @override
  String litresAmount(String litres, String amount) {
    return '$litres L for $amount';
  }

  @override
  String get pricePerLitre => 'Price per litre';

  @override
  String get costPerSqFt => 'Cost per sq ft';

  @override
  String areaOf(String area) {
    return 'over $area sq ft';
  }

  @override
  String get costPerTraveller => 'Cost per traveller';

  @override
  String travellersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count travellers',
      one: '1 traveller',
    );
    return '$_temp0';
  }

  @override
  String spendingByField(String field) {
    return 'Spending by $field';
  }

  @override
  String get notPicked => 'Not picked';

  @override
  String get metricsHint =>
      'Fill in project details on entries (odometer, stage, room…) to see metrics here.';

  @override
  String get projectFields => 'Fields';

  @override
  String get addField => 'Add field';

  @override
  String get fieldName => 'Field name';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldTypeNumber => 'Number';

  @override
  String get fieldTypeText => 'Text';

  @override
  String get fieldTypeDate => 'Date';

  @override
  String get fieldTypeChoice => 'Choice';

  @override
  String get fieldTypeUnit => 'Amount with unit';

  @override
  String get fieldUnitOptional => 'Unit (optional)';

  @override
  String get fieldOptions => 'Options, separated by commas';

  @override
  String get fieldOnEachEntry => 'Asked on each entry';

  @override
  String get fieldOncePerProject => 'One value for the project';

  @override
  String get fieldDeleted => 'Field deleted';

  @override
  String get deleteField => 'Delete field';

  @override
  String get setValue => 'Set value';

  @override
  String get errorFieldName => 'Give the field a name';

  @override
  String get errorFieldOptions => 'Add at least one option';

  @override
  String get clear => 'Clear';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get savePayment => 'Save payment';

  @override
  String get recordAPayment => 'Record a payment';

  @override
  String get recordAPaymentHint =>
      'Any pair, any amount — partial payments are fine';

  @override
  String get editPayment => 'Edit payment';

  @override
  String get paymentUpdated => 'Payment updated';

  @override
  String get paymentFrom => 'From';

  @override
  String get paymentTo => 'To';

  @override
  String get swapDirection => 'Swap';

  @override
  String get paymentMethod => 'Method';

  @override
  String get methodCash => 'Cash';

  @override
  String get methodUpi => 'UPI';

  @override
  String get methodBank => 'Bank';

  @override
  String get methodOther => 'Other';

  @override
  String paymentOverOwed(String amount) {
    return 'More than the $amount owed; the extra becomes a credit';
  }

  @override
  String paymentNoDebt(String from, String to) {
    return '$from owes $to nothing right now; this payment becomes a credit';
  }

  @override
  String paymentVia(String method) {
    return 'Payment · $method';
  }

  @override
  String get samePersonError => 'Pick two different people';

  @override
  String get amountLabel => 'Amount';

  @override
  String get filterMine => 'Mine';

  @override
  String get filterUnsettled => 'Unsettled';

  @override
  String get nothingInvolvingYou => 'Nothing involving you yet.';

  @override
  String get expensesAllSettled =>
      'All settled up. New expenses will show here.';

  @override
  String settledUpTo(String date) {
    return 'Settled up to $date';
  }

  @override
  String showOlderRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count older entries',
      one: 'Show 1 older entry',
    );
    return '$_temp0';
  }

  @override
  String get hideOlderRows => 'Hide older entries';

  @override
  String get youLent => 'you lent';

  @override
  String get youBorrowed => 'you borrowed';

  @override
  String get youPaid => 'you paid';

  @override
  String get youReceived => 'you received';

  @override
  String get notInvolved => 'not involved';

  @override
  String payerPaidAmount(String payer, String amount) {
    return '$payer paid $amount';
  }

  @override
  String youPaidName(String name) {
    return 'You paid $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name paid you';
  }

  @override
  String get addToProject => 'Add to project';

  @override
  String get chooseProject => 'Choose project';

  @override
  String get noProject => 'No project';

  @override
  String get noActiveProjects =>
      'No active projects. Start one from the Projects screen.';

  @override
  String get remindAction => 'Remind';

  @override
  String get payAction => 'Pay';

  @override
  String remindName(String name) {
    return 'Remind $name';
  }

  @override
  String payName(String name) {
    return 'Pay $name';
  }

  @override
  String reminderOwesMe(String name, String amount, String group) {
    return 'Hi $name, a quick reminder: you owe me $amount for $group.';
  }

  @override
  String reminderIOwe(String name, String amount, String group) {
    return 'Hi $name, I owe you $amount for $group. Paying now.';
  }

  @override
  String reminderOwes(String from, String to, String amount, String group) {
    return '$from owes $to $amount for $group.';
  }

  @override
  String reminderEveryone(String group) {
    return 'Settling up $group:';
  }

  @override
  String owesLine(String from, String to, String amount) {
    return '$from owes $to $amount';
  }

  @override
  String get messageLabel => 'Message';

  @override
  String get shareAction => 'Share…';

  @override
  String get copyAction => 'Copy';

  @override
  String get whatsAppAction => 'WhatsApp';

  @override
  String get smsAction => 'SMS';

  @override
  String get payWithUpi => 'Pay with UPI';

  @override
  String get noUpiApp =>
      'No UPI app on this phone. Pay another way, then record it.';

  @override
  String couldNotOpenApp(String app) {
    return 'Couldn\'t open $app.';
  }

  @override
  String get didPaymentGoThrough => 'Did the payment go through?';

  @override
  String didPaymentGoThroughBody(String amount, String name) {
    return 'If $amount reached $name, Hisab records it as paid by UPI today. Hisab can\'t see your UPI app, so only you can confirm.';
  }

  @override
  String get yesRecordIt => 'Yes, record it';

  @override
  String get notYet => 'Not yet';

  @override
  String remindedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Reminded $days days ago',
      one: 'Reminded yesterday',
      zero: 'Reminded today',
    );
    return '$_temp0';
  }

  @override
  String get remindAgain => 'Remind again';

  @override
  String get copiedReminder => 'Copied. Paste it into any chat.';

  @override
  String get nothingToRemind =>
      'Everyone is settled up. Nothing to remind or pay.';

  @override
  String get shareSummaryAnyway => 'Share the summary anyway';

  @override
  String get shareBalancesSummary => 'Share balances summary';

  @override
  String get remindEveryoneWhoOwes => 'Remind everyone who owes you';

  @override
  String get copyAsText => 'Copy as text';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get upiIdOptional => 'UPI ID (optional)';

  @override
  String get upiIdHint => 'name@bank';

  @override
  String get invalidUpiId => 'Enter a UPI ID like name@bank';

  @override
  String get memberContactLocal =>
      'Phone and UPI ID stay on this device. Hisab uses them only to fill in reminders and UPI payments.';

  @override
  String get editMember => 'Edit member';

  @override
  String get filters => 'Filters';

  @override
  String get filterEntries => 'Filter entries';

  @override
  String get anyProject => 'Any project';

  @override
  String get anyCategory => 'Any category';

  @override
  String get anyDate => 'Any date';

  @override
  String get minAmount => 'Min';

  @override
  String get maxAmount => 'Max';

  @override
  String get dates => 'Dates';

  @override
  String get tags => 'Tags';

  @override
  String get showResults => 'Show results';

  @override
  String get clearAll => 'Clear all';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String amountFrom(String amount) {
    return 'From $amount';
  }

  @override
  String amountUpTo(String amount) {
    return 'Up to $amount';
  }

  @override
  String amountBetween(String min, String max) {
    return '$min – $max';
  }

  @override
  String get minAboveMax => 'Min is more than max';

  @override
  String get calculator => 'Calculator';

  @override
  String useAmount(String amount) {
    return 'Use $amount';
  }

  @override
  String get calcDivideByZero => 'Can\'t divide by zero';

  @override
  String get calcNegative => 'The result is below zero';

  @override
  String get calcTooLarge => 'The result is too large';

  @override
  String get saveAndAddAnother => 'Save & add another';

  @override
  String get savedAddAnother => 'Saved. Add the next one.';

  @override
  String get recurringRepeat => 'Repeat';

  @override
  String get recurringDoesNotRepeat => 'Does not repeat';

  @override
  String get recurringDaily => 'Daily';

  @override
  String get recurringWeekly => 'Weekly';

  @override
  String get recurringMonthly => 'Monthly';

  @override
  String get recurringYearly => 'Yearly';

  @override
  String recurringEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String recurringEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String recurringEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String recurringEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String recurringOnDay(int day) {
    return 'on day $day';
  }

  @override
  String get recurringOnLastDay => 'on the last day';

  @override
  String recurringOnWeekday(String weekday) {
    return 'on $weekday';
  }

  @override
  String recurringOnDate(String date) {
    return 'on $date';
  }

  @override
  String recurringUntil(String date) {
    return 'until $date';
  }

  @override
  String recurringTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get recurringInterval => 'Repeat every';

  @override
  String get recurringLastDayOfMonth => 'On the last day of the month';

  @override
  String get recurringEnds => 'Ends';

  @override
  String get recurringEndNever => 'Never';

  @override
  String get recurringEndOnDate => 'On a date';

  @override
  String get recurringEndAfter => 'After';

  @override
  String get recurringOccurrences => 'Number of times';

  @override
  String get recurringAutoPost => 'Add automatically';

  @override
  String get recurringAutoPostHint =>
      'When off, each one waits for you to confirm';

  @override
  String get recurringStopRepeating => 'Don\'t repeat';

  @override
  String get recurringDone => 'Done';

  @override
  String get recurringEndBeforeStart =>
      'Pick an end date on or after the start';

  @override
  String get recurringPartOfRule => 'Part of a recurring entry';

  @override
  String get recurringTitle => 'Recurring';

  @override
  String get recurringNew => 'New recurring';

  @override
  String get recurringEdit => 'Edit recurring';

  @override
  String get recurringEmptyTitle => 'Nothing repeats yet';

  @override
  String get recurringEmptyBody =>
      'Rent, SIP, EMI or salary: set it once and Hisab adds it on the day.';

  @override
  String get recurringSectionWaiting => 'Waiting for you';

  @override
  String get recurringSectionActive => 'Active';

  @override
  String get recurringSectionPaused => 'Paused';

  @override
  String get recurringSectionEnded => 'Ended';

  @override
  String recurringNext(String date) {
    return 'Next $date';
  }

  @override
  String recurringDue(String date) {
    return 'Due $date';
  }

  @override
  String recurringMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more waiting',
      one: 'and 1 more waiting',
    );
    return '$_temp0';
  }

  @override
  String get recurringConfirm => 'Add';

  @override
  String get recurringSkip => 'Skip';

  @override
  String get recurringPause => 'Pause';

  @override
  String get recurringResume => 'Resume';

  @override
  String get recurringDeleted => 'Recurring entry deleted';

  @override
  String get recurringAdded => 'Entry added';

  @override
  String get recurringSkipped => 'Skipped';

  @override
  String recurringToConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recurring entries to confirm',
      one: '1 recurring entry to confirm',
    );
    return '$_temp0';
  }

  @override
  String recurringPostedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count times',
      one: 'Added once',
      zero: 'Not added yet',
    );
    return '$_temp0';
  }

  @override
  String get recurringNameLabel => 'Name (optional)';

  @override
  String get recurringNextOn => 'Next on';

  @override
  String get recurringRuleMissing => 'This recurring entry was deleted';

  @override
  String recurringDecrease(String label) {
    return 'Decrease $label';
  }

  @override
  String recurringIncrease(String label) {
    return 'Increase $label';
  }

  @override
  String get payersMultiple => '2+ people';

  @override
  String get payersHelp => 'Enter how much each person paid.';

  @override
  String payersAssigned(String assigned, String total) {
    return '$assigned of $total assigned';
  }

  @override
  String payersMustTotal(String total) {
    return 'Amounts paid must add up to $total';
  }

  @override
  String namesAnd(String first, String last) {
    return '$first and $last';
  }

  @override
  String get youInList => 'you';

  @override
  String recurringAddedSkipped(int added, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added added',
      one: '1 added',
      zero: 'None added',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped skipped',
      one: '1 skipped',
    );
    return '$_temp0, $_temp1';
  }
}
