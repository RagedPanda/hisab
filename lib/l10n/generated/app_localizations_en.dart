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
  String get moreDetails => 'More details';

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
  String get defaultAccount => 'Default account';

  @override
  String get defaultAccountHelp => 'New entries start on this account';

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
  String get howMuch => 'How much?';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get discardEntryTitle => 'Discard this entry?';

  @override
  String get discardEntryBody => 'What you entered will be lost.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get groupExpense => 'Group expense';

  @override
  String get copiedFromLastEntry => 'Filled in from the last expense';

  @override
  String get startBlank => 'Start blank';

  @override
  String get entryAgain => 'Add again for today';

  @override
  String get copiedFromEntry =>
      'A copy dated today. Change anything, then save.';

  @override
  String get deleteEntryQuestion => 'Delete this entry?';

  @override
  String get splitThis => 'Split this';

  @override
  String get splitThisPickGroup => 'Split with which group?';

  @override
  String get splitThisHint =>
      'Saving moves this entry into the group. Only your share counts as spent.';

  @override
  String splitThisDone(String group) {
    return 'Moved to $group. Only your share counts as spent.';
  }

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
      'Added from SMS. Editing it will not change your bank balance.';

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
  String get quickEntries => 'Quick entries';

  @override
  String get quickEntriesHint => 'One-tap spends on Home';

  @override
  String get saveAsQuickEntry => 'Save as quick entry';

  @override
  String get saveQuickEntry => 'Save quick entry';

  @override
  String get newQuickEntry => 'New quick entry';

  @override
  String get editQuickEntry => 'Edit quick entry';

  @override
  String get quickEntryName => 'Name on the chip';

  @override
  String get quickEntrySaved =>
      'Saved as a quick entry. Tap it on Home to add it.';

  @override
  String quickEntryConfirm(String label) {
    return 'Add $label?';
  }

  @override
  String quickEntryAdded(String label, String amount) {
    return 'Added $label · $amount';
  }

  @override
  String quickEntriesMore(int count) {
    return '+$count more';
  }

  @override
  String get quickEntriesShown => 'Shown on Home';

  @override
  String quickEntriesShownHint(int count) {
    return '$count chips; the rest go behind +more';
  }

  @override
  String get quickEntriesEmpty =>
      'No quick entries yet. Add one here, or open any entry and tap the bolt to save it as one.';

  @override
  String get quickEntryNoAmount => 'Opens the editor';

  @override
  String sameAsLastTime(int count) {
    return 'Same as last time · $count items';
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
  String get errorPickAccount => 'Pick an account';

  @override
  String get errorSameAccount => 'From and To must be different accounts';

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
  String get groupsTotalsSeparator => ' · ';

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
  String get advancedSettings => 'Advanced';

  @override
  String get currency => 'Currency';

  @override
  String get currencyChooseTitle => 'Choose your currency';

  @override
  String get currencyChooseBody =>
      'Amounts in Hisab show in this currency. You can change it later in Settings.';

  @override
  String get currencySearchHint => 'Search code, name or country';

  @override
  String currencyContinue(String currency) {
    return 'Continue with $currency';
  }

  @override
  String currencyNoMatch(String query) {
    return 'No currency matches \"$query\"';
  }

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
  String get eraseAllData => 'Erase all data';

  @override
  String get eraseAllDataHelp =>
      'Deletes every entry, account, group and setting on this phone';

  @override
  String get eraseAllDataTitle => 'Erase everything?';

  @override
  String eraseAllDataBody(String word) {
    return 'This removes all entries, accounts, groups, budgets, reminders and settings from this phone. It can\'t be undone. Backups already on Google Drive are kept.\n\nType $word to confirm.';
  }

  @override
  String eraseConfirmLabel(String word) {
    return 'Type $word';
  }

  @override
  String get eraseAction => 'Erase';

  @override
  String get dataErased => 'All data erased. Hisab is back to a fresh start.';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Free, open source, no ads, no account needed. Your data stays on your device.';

  @override
  String get aboutMadeWithBefore => 'Made with';

  @override
  String get aboutMadeWithAfter => '';

  @override
  String get aboutMadeWithLabel => 'Made with love';

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
  String get driveBackupTitle => 'Back up to Google Drive';

  @override
  String get driveBackupWhy =>
      'Optional. An encrypted copy in your own Drive; Hisab can only see its own files.';

  @override
  String get driveConsentTitle => 'Back up & sync with Google Drive';

  @override
  String get driveConsentOptional => 'optional';

  @override
  String get driveConsentOffline =>
      'Hisab works fully offline. Your data stays on this phone and nothing is ever sent anywhere — unless you turn this on.';

  @override
  String get driveConsentWhat =>
      'Turn on Drive sync and Hisab keeps an encrypted copy of your data in your own Google Drive, so you can restore everything if you lose or change your phone, and share a group with friends and family.';

  @override
  String get driveConsentWhyLead => 'Why Hisab asks for Drive access:';

  @override
  String get driveConsentWhy =>
      'only to read and write its own files in your Drive.';

  @override
  String get driveConsentCannotSee =>
      'It cannot see your photos, documents, or anything else in your Drive.';

  @override
  String get driveConsentEncrypted =>
      'The data is encrypted — Google can\'t read it, and neither can we. There is no Hisab server.';

  @override
  String get driveConsentTurnOff =>
      'You can turn this off and disconnect any time, and delete the Drive copy with one tap.';

  @override
  String get driveConsentSkip =>
      'Don\'t want it? Just skip this — Hisab works exactly the same without it.';

  @override
  String get driveSkipForNow => 'Skip for now';

  @override
  String get driveConnect => 'Connect Google Drive';

  @override
  String driveConnectedAs(String email) {
    return 'Connected as $email';
  }

  @override
  String driveLastBackup(String time) {
    return 'Last backup: $time';
  }

  @override
  String get driveNoBackupYet => 'No backup in Drive yet';

  @override
  String get driveCheckingBackup => 'Checking Google Drive…';

  @override
  String get driveBackupStatusUnknown => 'Couldn\'t check Google Drive';

  @override
  String get driveBackUpNow => 'Back up now';

  @override
  String get driveBackUpNowHelp =>
      'Encrypts everything with your passphrase and replaces the Drive copy';

  @override
  String get driveRestore => 'Restore from Drive';

  @override
  String get driveDisconnect => 'Disconnect';

  @override
  String get driveDisconnectHelp =>
      'Stops using this Google account; the Drive copy stays until you delete it';

  @override
  String get driveDeleteCopy => 'Delete Drive copy';

  @override
  String get driveDeleteCopyHelp =>
      'Removes Hisab\'s backup from your Google Drive';

  @override
  String get driveDeleteConfirm =>
      'Delete the backup in your Google Drive? Data on this phone is not affected.';

  @override
  String get driveBackedUp => 'Backed up to Google Drive';

  @override
  String get driveCopyDeleted => 'Drive copy deleted';

  @override
  String get driveDisconnected => 'Disconnected from Google Drive';

  @override
  String get driveErrorCancelled => 'Google sign-in was cancelled';

  @override
  String get driveErrorOffline =>
      'Couldn\'t reach Google Drive. Check your connection and try again.';

  @override
  String get driveErrorNotFound => 'No Hisab backup found in this Google Drive';

  @override
  String get driveErrorWrongPassphrase =>
      'Wrong passphrase, or the backup is damaged';

  @override
  String driveErrorUnknown(String error) {
    return 'Google Drive failed: $error';
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
  String get smsForeignCurrency =>
      'Only SMS in your home currency are supported, so this one was ignored.';

  @override
  String get smsNotFound => 'Could not find a transaction in that text.';

  @override
  String get smsNotificationTitle => 'New bank transaction';

  @override
  String smsNotificationBodyAmount(String amount, String sender) {
    return '$amount from $sender. Tap to review.';
  }

  @override
  String smsNotificationBody(String sender) {
    return 'From $sender. Tap to review.';
  }

  @override
  String smsNotificationBodyAmountAutoAdd(String amount, String sender) {
    return '$amount from $sender. Open Hisab to add it.';
  }

  @override
  String smsNotificationBodyAutoAdd(String sender) {
    return 'From $sender. Open Hisab to add it.';
  }

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
  String get smsAutoAddTitle => 'Add clear transactions automatically';

  @override
  String get smsAutoAddHelp =>
      'On: clear bank SMS are added right away with Undo. Unclear ones wait for review.';

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
  String get emailOptional => 'Email (optional)';

  @override
  String get invalidEmail => 'Enter an email like name@example.com';

  @override
  String get memberContactLocal =>
      'Email, phone and UPI ID stay on this device. Hisab uses them only to suggest people you added before, and to fill in reminders and UPI payments.';

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
  String get tagsHint => 'Comma separated, e.g. home, trip';

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
  String get filteredTotal => 'Total spent';

  @override
  String itemBoughtTimes(String quantity, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$quantity · $_temp0';
  }

  @override
  String moreItems(int count) {
    return '+$count more items';
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
  String get remindersTitle => 'Reminders';

  @override
  String remindersUpcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming',
      one: '1 upcoming',
      zero: 'Nothing due',
    );
    return '$_temp0';
  }

  @override
  String get remindersNotificationsOn => 'notifications on';

  @override
  String get remindersNotificationsOff => 'notifications off';

  @override
  String remindersSettingsSubtitle(String count, String state) {
    return '$count · $state';
  }

  @override
  String get reminderTabHistory => 'History';

  @override
  String get reminderSectionOverdue => 'Overdue';

  @override
  String get reminderSectionThisWeek => 'This week';

  @override
  String get reminderSectionLater => 'Later';

  @override
  String get reminderAdd => 'Add reminder';

  @override
  String get reminderFab => 'Reminder';

  @override
  String get remindersEmptyTitle => 'No reminders yet';

  @override
  String get remindersEmptyBody =>
      'Bills, rent, EMIs, renewals: add one and Hisab will nudge you before it\'s due.';

  @override
  String get reminderHistoryEmpty => 'Paid and skipped reminders show up here.';

  @override
  String get reminderSkip => 'Skip this time';

  @override
  String get reminderDeleted => 'Reminder deleted';

  @override
  String get reminderMarkedPaid => 'Marked paid';

  @override
  String get reminderMarkedDone => 'Marked done';

  @override
  String get reminderSkipped => 'Skipped this time';

  @override
  String reminderSnoozedUntil(String date) {
    return 'Snoozed until $date';
  }

  @override
  String get reminderAlreadyDone => 'Already marked paid';

  @override
  String reminderPaidOn(String date) {
    return 'Paid $date';
  }

  @override
  String reminderDoneOn(String date) {
    return 'Done $date';
  }

  @override
  String reminderSkippedOn(String date) {
    return 'Skipped $date';
  }

  @override
  String reminderNextDue(String date) {
    return 'Next due $date';
  }

  @override
  String get notifOffBanner =>
      'Notifications are off. Reminders will only show in the app.';

  @override
  String get notifTurnOn => 'Turn on';

  @override
  String get remindersLateNote =>
      'Reminders may arrive late. Allow Alarms & reminders';

  @override
  String get exactAlarmPromptTitle => 'Get reminders on time';

  @override
  String get exactAlarmPromptBody =>
      'To alert you at the exact time you set, Android needs Hisab\'s \"Alarms & reminders\" setting. Without it, reminders may arrive late.';

  @override
  String get notifPrePromptTitle => 'Get reminded before it\'s due';

  @override
  String get notifPrePromptBody =>
      'Hisab sends a notification at the time you choose, only for your reminders. No marketing.';

  @override
  String reminderPaidSheetTitle(String title) {
    return 'Paid $title?';
  }

  @override
  String reminderPaidSheetBody(String amount) {
    return 'Add an expense of $amount and mark this paid.';
  }

  @override
  String get reminderAddEntryAndMark => 'Add entry & mark paid';

  @override
  String get reminderJustMark => 'Just mark paid';

  @override
  String get reminderNew => 'New reminder';

  @override
  String get reminderEditTitle => 'Edit reminder';

  @override
  String get reminderKindBill => 'Bill';

  @override
  String get reminderKindEmi => 'EMI';

  @override
  String get reminderKindCard => 'Card bill';

  @override
  String get reminderKindSubscription => 'Subscription';

  @override
  String get reminderKindInsurance => 'Insurance';

  @override
  String get reminderKindDocument => 'Document';

  @override
  String get reminderKindCustom => 'Other';

  @override
  String get reminderTitleLabel => 'Title';

  @override
  String get reminderTitleHint => 'e.g. Electricity bill';

  @override
  String get reminderTitleRequired => 'Enter a title';

  @override
  String get reminderAmountOptional => 'Amount (optional)';

  @override
  String get reminderDueDate => 'Due date';

  @override
  String get reminderRepeatLabel => 'Repeat';

  @override
  String get reminderRepeatOnce => 'Once';

  @override
  String get reminderRepeatWeekly => 'Every week';

  @override
  String get reminderRepeatMonthly => 'Every month';

  @override
  String get reminderRepeatQuarterly => 'Every 3 months';

  @override
  String get reminderRepeatYearly => 'Every year';

  @override
  String get reminderNotifyLabel => 'Remind me';

  @override
  String get reminderNotifyOnDay => 'On the day';

  @override
  String reminderNotifyDaysBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get reminderNotifyEnabled => 'Notify me';

  @override
  String reminderNotifyAt(String time) {
    return 'At $time';
  }

  @override
  String reminderNotifyPreview(String when) {
    return 'First alert: $when';
  }

  @override
  String get reminderNoAlertsLeft =>
      'All alert times have passed; it will show as due in the app.';

  @override
  String get reminderPickDaysError => 'Pick at least one day';

  @override
  String get reminderSave => 'Save reminder';

  @override
  String get reminderNoAccount => 'No account';

  @override
  String get reminderChannelName => 'Bill & due-date reminders';

  @override
  String get reminderChannelDescription =>
      'Alerts before bills, EMIs, card dues and renewals are due';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsSettingsSubtitle(int on, int total) {
    return '$on of $total on';
  }

  @override
  String get notificationsIntro =>
      'Pick what Hisab may notify you about. Each one starts off; turn on only what helps.';

  @override
  String get notificationsBlocked =>
      'Notifications are blocked for Hisab on this phone.';

  @override
  String get notificationsAllow => 'Allow';

  @override
  String get notificationsShowSample => 'Show sample';

  @override
  String get notificationsSampleSent =>
      'Sample sent. Pull down the notification shade to see it.';

  @override
  String notificationsSampleTitle(String title) {
    return 'Sample · $title';
  }

  @override
  String get notificationsUpdatesChannel => 'Daily summary and samples';

  @override
  String get notificationsUpdatesChannelDescription =>
      'The evening summary and samples sent from Settings';

  @override
  String get notifKindReminders => 'Reminders';

  @override
  String get notifKindRemindersHelp =>
      'Bills, documents, card dues and group settle-ups you set reminders for';

  @override
  String get notifKindSalary => 'Salary not seen yet';

  @override
  String get notifKindSalaryHelp =>
      'When your salary has not arrived by its expected day';

  @override
  String get notifKindSalaryNeedsSetup => 'Set up salary first';

  @override
  String get notifKindBankSms => 'New bank SMS';

  @override
  String get notifKindBankSmsHelp =>
      'A bank transaction SMS arrived while Hisab was closed';

  @override
  String get notifKindBankSmsNeedsSetup => 'Works once Bank SMS is on';

  @override
  String get notifKindEveningSummary => 'Evening summary';

  @override
  String get notifKindEveningSummaryHelp =>
      'Today\'s spend, SMS to review and bills due in the next 3 days';

  @override
  String get eveningSummaryTime => 'Summary time';

  @override
  String get eveningSummaryTitle => 'Your day in Hisab';

  @override
  String eveningSummarySpent(String amount) {
    return 'Spent $amount today';
  }

  @override
  String get eveningSummaryNothingSpent => 'Nothing spent today';

  @override
  String eveningSummaryReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SMS to review',
      one: '1 SMS to review',
    );
    return '$_temp0';
  }

  @override
  String eveningSummaryDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills due in the next 3 days',
      one: '1 bill due in the next 3 days',
    );
    return '$_temp0';
  }

  @override
  String get notifSampleReminderTitle => 'Electricity bill';

  @override
  String get reminderMarkPaid => 'Mark paid';

  @override
  String get reminderMarkDone => 'Done';

  @override
  String get reminderSnoozeOneDay => 'Snooze 1 day';

  @override
  String get reminderDueToday => 'Due today';

  @override
  String reminderDueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $days days',
      one: 'Due tomorrow',
    );
    return '$_temp0';
  }

  @override
  String reminderOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Overdue by $days days',
      one: 'Overdue by 1 day',
    );
    return '$_temp0';
  }

  @override
  String get cardStatementDay => 'Statement day';

  @override
  String get cardDueDay => 'Payment due day';

  @override
  String get cardDayNotSet => 'Not set';

  @override
  String get cardCreditLimit => 'Credit limit';

  @override
  String get cardLastStatementAmount => 'Last statement amount';

  @override
  String get cardDetailsHint =>
      'Statement and due days let Hisab show your billing cycle and remind you before the bill is due.';

  @override
  String get cardOutstanding => 'Outstanding';

  @override
  String get cardThisCycle => 'This cycle';

  @override
  String cardCycleDates(String start, String end) {
    return '$start to $end';
  }

  @override
  String get cardLastStatement => 'Last statement';

  @override
  String cardStatementOn(String date) {
    return 'Statement of $date';
  }

  @override
  String get cardNoStatement => 'Not recorded';

  @override
  String get cardAvailableLimit => 'Available limit';

  @override
  String cardOverLimitBy(String amount) {
    return 'Over limit by $amount';
  }

  @override
  String cardLimitUsed(int percent, String limit) {
    return '$percent% of $limit limit used';
  }

  @override
  String cardDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get cardPaid => 'Paid';

  @override
  String cardAmountLeftToPay(String amount) {
    return '$amount left to pay';
  }

  @override
  String get cardSetUpDays => 'Set statement and due days';

  @override
  String get cardViewTransactions => 'View transactions';

  @override
  String get cardNotFound => 'This card was deleted';

  @override
  String cardNextDue(String date) {
    return 'Next due $date';
  }

  @override
  String cardInCredit(String amount) {
    return '$amount credit';
  }

  @override
  String cardStatementOverAmountDue(String amount) {
    return 'More than the amount due ($amount). Lower it to what is still unpaid.';
  }

  @override
  String get cardBalanceOwed => 'Amount due';

  @override
  String get cardBalanceCredit => 'In credit';

  @override
  String get cardCreditOnCard => 'Credit on the card';

  @override
  String get balanceInAccount => 'In account';

  @override
  String get balanceOverdrawn => 'Overdrawn';

  @override
  String get smsHistoryTitle => 'SMS history';

  @override
  String get smsHistoryHelp =>
      'Every message Hisab processed and what happened to it';

  @override
  String get smsOutcomeAdded => 'Added';

  @override
  String get smsOutcomeDuplicate => 'Duplicate';

  @override
  String get smsOutcomeIgnored => 'Ignored';

  @override
  String get smsOutcomeUnparsed => 'Unreadable';

  @override
  String get smsOutcomePending => 'Pending';

  @override
  String get smsOutcomeUndone => 'Undone';

  @override
  String get smsHistoryNotBank => 'Not a bank message';

  @override
  String get smsHistoryDismissed => 'Dismissed from review';

  @override
  String get smsHistoryUnparsedDetail => 'No transaction found in the text';

  @override
  String get smsHistoryDuplicateDetail => 'Same message already processed';

  @override
  String get smsHistoryOpenEntry => 'Open entry';

  @override
  String get smsHistoryReprocess => 'Process again';

  @override
  String get smsHistoryClear => 'Clear history';

  @override
  String get smsHistoryClearQuestion => 'Clear SMS history?';

  @override
  String smsHistoryClearBody(int count) {
    return 'Removes the text of $count processed messages from this device. Your entries and messages waiting for review stay, and cleared messages are never imported again.';
  }

  @override
  String get smsHistoryClearConfirm => 'Clear';

  @override
  String get smsHistoryCleared => 'SMS history cleared';

  @override
  String get smsHistoryEmptyTitle => 'No messages processed yet';

  @override
  String get smsHistoryEmptyBody =>
      'Bank SMS that Hisab reads or that you paste show up here.';

  @override
  String get smsHistoryEmptyFiltered => 'No messages with this outcome';

  @override
  String get smsHistoryTextNotKept => 'Message text not kept';

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
  String get subscriptions => 'Subscriptions';

  @override
  String get subscriptionsMonthlyTotal => 'Per month';

  @override
  String get subscriptionsYearlyTotal => 'Per year';

  @override
  String subscriptionsActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active subscriptions',
      one: '1 active subscription',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionsEmptyTitle => 'No subscriptions yet';

  @override
  String get subscriptionsEmptyBody =>
      'Add Netflix, your phone recharge or the gym to see what they cost you each month and year.';

  @override
  String get subscriptionAdd => 'Add subscription';

  @override
  String get subscriptionEdit => 'Edit subscription';

  @override
  String get subscriptionPickService => 'Pick a service';

  @override
  String get subscriptionCustom => 'Something else';

  @override
  String get subscriptionPrice => 'Price per renewal';

  @override
  String get subscriptionCycle => 'Renews';

  @override
  String get subscriptionNextRenewal => 'Next renewal';

  @override
  String subscriptionStartedOn(String date) {
    return 'Started $date';
  }

  @override
  String get subscriptionAutoPost => 'Add to expenses on each renewal';

  @override
  String get subscriptionAutoPostHelp =>
      'Off: tracked here only, no entries are added';

  @override
  String get subscriptionNameRequired => 'Enter a name';

  @override
  String get subscriptionPriceRequired => 'Enter the price';

  @override
  String subscriptionRenewsOn(String date) {
    return 'Renews $date';
  }

  @override
  String get subscriptionRenewsToday => 'Renews today';

  @override
  String subscriptionRenewsInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Renews in $days days',
      one: 'Renews tomorrow',
    );
    return '$_temp0';
  }

  @override
  String subscriptionOverdue(String date) {
    return 'Was due $date';
  }

  @override
  String get subscriptionPaused => 'Paused';

  @override
  String get subscriptionCancelled => 'Cancelled';

  @override
  String get subscriptionPause => 'Pause';

  @override
  String get subscriptionResume => 'Resume';

  @override
  String get subscriptionMarkCancelled => 'Mark as cancelled';

  @override
  String subscriptionCancelConfirm(String name) {
    return 'Mark $name as cancelled?';
  }

  @override
  String get subscriptionCancelConfirmBody =>
      'No new charges are added and it leaves the totals. Past entries stay.';

  @override
  String get subscriptionDeleted => 'Subscription deleted';

  @override
  String subscriptionPerMonth(String amount) {
    return '$amount/month';
  }

  @override
  String get subscriptionSort => 'Sort';

  @override
  String get subscriptionSortCostHigh => 'Cost: high to low';

  @override
  String get subscriptionSortCostLow => 'Cost: low to high';

  @override
  String get subscriptionSortRenewal => 'Next renewal';

  @override
  String get subscriptionSortName => 'Name';

  @override
  String subscriptionEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String subscriptionEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String subscriptionEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String subscriptionEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionTemplateNetflix => 'Netflix';

  @override
  String get subscriptionTemplateAmazonPrime => 'Amazon Prime';

  @override
  String get subscriptionTemplateJiohotstar => 'JioHotstar';

  @override
  String get subscriptionTemplateSpotify => 'Spotify';

  @override
  String get subscriptionTemplateYoutubePremium => 'YouTube Premium';

  @override
  String get subscriptionTemplateMobileRecharge => 'Mobile recharge';

  @override
  String get subscriptionTemplateDth => 'DTH';

  @override
  String get subscriptionTemplateBroadband => 'Broadband';

  @override
  String get subscriptionTemplateGym => 'Gym';

  @override
  String get subscriptionTemplateCloudStorage => 'Cloud storage';

  @override
  String get subscriptionTemplateNewsApp => 'News app';

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
  String get groupTotalsTitle => 'Group totals';

  @override
  String get groupTotalsAllTime => 'All time';

  @override
  String get groupTotalsTotalSpent => 'Group total';

  @override
  String get groupTotalsYouPaid => 'You paid';

  @override
  String get groupTotalsYourShare => 'Your share';

  @override
  String get groupTotalsNetChange => 'Change in your balance';

  @override
  String get groupTotalsPaymentsMade => 'Payments you made';

  @override
  String get groupTotalsPaymentsReceived => 'Payments you received';

  @override
  String get groupTotalsByMember => 'Paid and share by member';

  @override
  String get groupTotalsPaid => 'Paid';

  @override
  String get groupTotalsShare => 'Share';

  @override
  String get groupTotalsEmpty => 'No expenses in this period';

  @override
  String groupTotalsExpenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String groupTotalsMemberRow(String name, String paid, String share) {
    return '$name: paid $paid, share $share';
  }

  @override
  String get groupTotalsOpen => 'See totals';

  @override
  String get groupSettingsTitle => 'Group settings';

  @override
  String get groupSettingsType => 'Type';

  @override
  String get groupTypeTrip => 'Trip';

  @override
  String get groupTypeHome => 'Home';

  @override
  String get groupTypeCouple => 'Couple';

  @override
  String get groupTypeOther => 'Other';

  @override
  String get groupSettingsIcon => 'Icon';

  @override
  String get groupSettingsDefaultSplit => 'Default split';

  @override
  String get groupSettingsDefaultSplitHint =>
      'Pre-selected for new expenses. Expenses already added keep their split.';

  @override
  String get groupSettingsWeights => 'Shares per member';

  @override
  String groupSettingsWeightValue(num count, String weight) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$weight shares',
      one: '1 share',
    );
    return '$_temp0';
  }

  @override
  String groupSettingsWeightLess(String name) {
    return 'Fewer shares for $name';
  }

  @override
  String groupSettingsWeightMore(String name) {
    return 'More shares for $name';
  }

  @override
  String get groupSettingsCurrency => 'Currency label';

  @override
  String get groupSettingsCurrencyHint =>
      'Only changes the symbol shown in this group. Amounts are not converted.';

  @override
  String groupSettingsCurrencyAppDefault(String symbol) {
    return 'Same as app ($symbol)';
  }

  @override
  String get groupSettingsCurrencyOther => 'Other symbol';

  @override
  String get groupSettingsSimplify => 'Simplify debts';

  @override
  String get groupSettingsSimplifyBody =>
      'Combines debts so the group needs fewer repayments. If Asha owes Ravi and Ravi owes Meena, Asha can pay Meena directly. Nobody pays or gets back a different total.';

  @override
  String groupSettingsSimplifySaves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saves $count repayments right now',
      one: 'Saves 1 repayment right now',
    );
    return '$_temp0';
  }

  @override
  String get groupSettingsNotes => 'Notes';

  @override
  String get groupSettingsNotesHint => 'Wi-Fi password, house rules, trip plan';

  @override
  String get groupSettingsNotesAdd => 'Add a note for this group';

  @override
  String get groupSettingsManage => 'Manage group';

  @override
  String get groupArchive => 'Archive group';

  @override
  String groupArchiveTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String get groupArchiveBody =>
      'The group moves to Archived on the groups list. Nothing is deleted, and you can unarchive it any time.';

  @override
  String get groupArchiveConfirm => 'Archive';

  @override
  String get groupUnarchive => 'Unarchive';

  @override
  String get groupArchivedBanner =>
      'This group is archived. Unarchive it to add expenses.';

  @override
  String get groupLeftBanner => 'You left this group. Its history stays here.';

  @override
  String groupArchivedSection(int count) {
    return 'Archived ($count)';
  }

  @override
  String get groupLeave => 'Leave group';

  @override
  String groupLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get groupLeaveBody =>
      'You are removed from the group on this phone and it moves to Archived, so its history stays readable.';

  @override
  String get groupLeaveConfirm => 'Leave';

  @override
  String get groupLeaveBlocked =>
      'Settle up first. You can leave once nobody owes you and you owe nobody.';

  @override
  String get groupDeleteUnsettledBody =>
      'This group still has unsettled balances. Deleting it removes every expense and payment, and it cannot be undone.';

  @override
  String get groupEmptyTrip =>
      'Add tickets, stays and meals as you go; Hisab works out who owes whom.';

  @override
  String get groupEmptyHome =>
      'Add rent, bills and groceries; Hisab works out who owes whom.';

  @override
  String get groupEmptyCouple =>
      'Add the dinners, groceries and trips you share; Hisab keeps the balance.';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityEmptyTitle => 'No activity yet';

  @override
  String get activityEmptyBody =>
      'Expenses and payments you add, edit or delete show up here.';

  @override
  String activityExpenseAdded(String actor, String title) {
    return '$actor added “$title”';
  }

  @override
  String activityExpenseEdited(String actor, String title) {
    return '$actor edited “$title”';
  }

  @override
  String activityExpenseDeleted(String actor, String title) {
    return '$actor deleted “$title”';
  }

  @override
  String activityExpenseRestored(String actor, String title) {
    return '$actor restored “$title”';
  }

  @override
  String activityPaymentAdded(String actor) {
    return '$actor recorded a payment';
  }

  @override
  String activityPaymentEdited(String actor) {
    return '$actor edited a payment';
  }

  @override
  String activityPaymentDeleted(String actor) {
    return '$actor removed a payment';
  }

  @override
  String activityPaymentRestored(String actor) {
    return '$actor restored a payment';
  }

  @override
  String activityExpenseLine(String amount, String payers) {
    return '$amount · paid by $payers';
  }

  @override
  String activityPaymentLine(String from, String to, String amount) {
    return '$from paid $to $amount';
  }

  @override
  String activityChangeAmount(String from, String to) {
    return 'Amount: $from → $to';
  }

  @override
  String activityChangeDate(String from, String to) {
    return 'Date: $from → $to';
  }

  @override
  String activityChangeDescription(String from, String to) {
    return 'Description: $from → $to';
  }

  @override
  String activityChangeCategory(String from, String to) {
    return 'Category: $from → $to';
  }

  @override
  String activityChangePayers(String from, String to) {
    return 'Paid by: $from → $to';
  }

  @override
  String activityPayerAmount(String name, String amount) {
    return '$name $amount';
  }

  @override
  String activityChangeShare(String name, String from, String to) {
    return '$name\'s share: $from → $to';
  }

  @override
  String activityChangeMyShare(String from, String to) {
    return 'Your share: $from → $to';
  }

  @override
  String activityChangeParties(String from, String to) {
    return 'Who paid whom: $from → $to';
  }

  @override
  String activityPartiesPair(String from, String to) {
    return '$from to $to';
  }

  @override
  String activityChangeMethod(String from, String to) {
    return 'Method: $from → $to';
  }

  @override
  String activityChangeNote(String from, String to) {
    return 'Note: $from → $to';
  }

  @override
  String get activityNone => 'none';

  @override
  String get activityRestore => 'Restore';

  @override
  String get activityExpenseRestoredSnack => 'Expense restored';

  @override
  String get activityExpenseDeletedSnack => 'Expense deleted';

  @override
  String get activityAllGroups => 'All groups';

  @override
  String activityGroupDeleted(String actor, String name) {
    return '$actor deleted the group “$name”';
  }

  @override
  String activityGroupRestored(String actor, String name) {
    return '$actor restored the group “$name”';
  }

  @override
  String activityGroupEdited(String actor, String name) {
    return '$actor changed the group “$name”';
  }

  @override
  String activityGroupLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
      zero: 'No expenses',
    );
    return '$_temp0';
  }

  @override
  String get activityPaymentRestoredSnack => 'Payment restored';

  @override
  String get activityGroupRestoredSnack => 'Group restored';

  @override
  String get activityGroupDeletedSnack => 'Group deleted';

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

  @override
  String get groupExportCsv => 'Export as CSV';

  @override
  String groupExportCsvSubject(String group) {
    return '$group expenses';
  }

  @override
  String get groupExportFailed => 'Couldn\'t export the CSV';

  @override
  String get groupCsvDate => 'Date';

  @override
  String get groupCsvDescription => 'Description';

  @override
  String get groupCsvCost => 'Cost';

  @override
  String get groupCsvPaidBy => 'Paid by';

  @override
  String groupCsvPaidColumn(String name) {
    return '$name paid';
  }

  @override
  String groupCsvShareColumn(String name) {
    return '$name share';
  }

  @override
  String groupCsvBalanceColumn(String name) {
    return '$name balance';
  }

  @override
  String get groupCsvPayment => 'Payment';

  @override
  String get groupSummaryWhoPaysWhom => 'Who pays whom';

  @override
  String get groupSummaryStandings => 'Where everyone stands';

  @override
  String groupSummaryYouOwe(String name, String amount) {
    return 'You owe $name $amount';
  }

  @override
  String groupSummaryOwesYou(String name, String amount) {
    return '$name owes you $amount';
  }

  @override
  String groupSummaryGetsBack(String name, String amount) {
    return '$name gets back $amount';
  }

  @override
  String groupSummaryOwesInTotal(String name, String amount) {
    return '$name owes $amount in total';
  }

  @override
  String groupSummaryYouGetBack(String amount) {
    return 'You get back $amount';
  }

  @override
  String groupSummaryYouOweInTotal(String amount) {
    return 'You owe $amount in total';
  }

  @override
  String get groupCsvTotal => 'Total';

  @override
  String groupSummaryGroupTotal(String amount) {
    return 'Group total: $amount';
  }

  @override
  String groupSummaryYourShare(String amount) {
    return 'Your share: $amount';
  }

  @override
  String groupSummaryMemberShare(String name, String amount) {
    return '$name\'s share: $amount';
  }

  @override
  String get byItemShared => 'Shared';

  @override
  String get byItemSharedHelp => 'Split among everyone with an item';

  @override
  String get byItemOnlyMe => 'Only me';

  @override
  String get byItemEveryone => 'Everyone';

  @override
  String get byItemAddExtras => 'Delivery, tax or tip';

  @override
  String get byItemHint => 'Add items to split by item';

  @override
  String byItemSummary(String amount, int count, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$amount · $_temp0 · $percent%';
  }

  @override
  String get byItemClearTitle => 'Item assignments will be cleared';

  @override
  String get byItemClearBody =>
      'Items stay, and everyone shares each one again.';

  @override
  String get smsAddedMarker => 'Added from SMS';

  @override
  String smsAutoAddedOne(String amount) {
    return 'Added $amount from SMS';
  }

  @override
  String smsAutoAddedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count entries from SMS',
      one: 'Added 1 entry from SMS',
    );
    return '$_temp0';
  }

  @override
  String get smsReviewTitle => 'SMS to review';

  @override
  String get smsReviewHelp =>
      'These messages were not clear enough to add on their own. Add, edit or ignore each one.';

  @override
  String get smsReviewUnread => 'Could not read the amount';

  @override
  String get smsReviewAddManually => 'Add manually';

  @override
  String upcomingWindowDays(int days) {
    return '$days days';
  }

  @override
  String upcomingOverdueBy(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Overdue by $days days',
      one: 'Overdue by 1 day',
    );
    return '$_temp0';
  }

  @override
  String get upcomingDueToday => 'Due today';

  @override
  String get upcomingDueTomorrow => 'Due tomorrow';

  @override
  String upcomingDueInDays(int days, String date) {
    return 'In $days days · $date';
  }

  @override
  String upcomingOverdueCount(int count) {
    return '$count overdue';
  }

  @override
  String upcomingDueTotal(String amount) {
    return '$amount to pay';
  }

  @override
  String upcomingShowAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more',
      one: '1 more',
    );
    return '$_temp0';
  }

  @override
  String get upcomingCalendar => 'Due calendar';

  @override
  String get upcomingCalendarOpen => 'Open due calendar';

  @override
  String get upcomingCalendarDayEmpty => 'Nothing due on this day';

  @override
  String get upcomingCalendarPreviousMonth => 'Previous month';

  @override
  String get upcomingCalendarNextMonth => 'Next month';

  @override
  String get spendingCalendar => 'Spending calendar';

  @override
  String get spendingCalendarOpen => 'Open spending calendar';

  @override
  String get spendingCalendarDayEmpty => 'Nothing spent on this day';

  @override
  String spendingCalendarSpent(String amount) {
    return '$amount spent';
  }

  @override
  String get upcomingConfirm => 'Confirm';

  @override
  String get upcomingConfirmPrompt =>
      'This is waiting for you to confirm. Add it to your entries now?';

  @override
  String upcomingCalendarDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count due',
      one: '1 due',
    );
    return '$_temp0';
  }

  @override
  String get salaryTitle => 'Salary';

  @override
  String get salarySetUp => 'Set up salary day';

  @override
  String get salaryIntro =>
      'Hisab adds your salary as a monthly income you confirm, and gently reminds you if it has not arrived.';

  @override
  String salarySummary(String amount, int day) {
    return '$amount on day $day';
  }

  @override
  String get salaryAmount => 'Monthly salary';

  @override
  String get salaryAccount => 'Credited to';

  @override
  String get salaryAnyAccount => 'Any account';

  @override
  String get salaryDay => 'Salary day';

  @override
  String get salaryShiftLabel => 'On a weekend or holiday';

  @override
  String get salaryShiftSameDay => 'Same day';

  @override
  String get salaryShiftPrevious => 'Previous working day';

  @override
  String get salaryShiftNext => 'Next working day';

  @override
  String get salaryHolidays => 'Bank holidays';

  @override
  String get salaryHolidaysHelp =>
      'Skipped like weekends when the salary day moves';

  @override
  String get salaryAddHoliday => 'Add holiday';

  @override
  String get salaryReminder => 'Remind me if it has not arrived';

  @override
  String get salaryReminderDelay => 'Remind after';

  @override
  String salaryDaysAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days after',
      one: '1 day after',
    );
    return '$_temp0';
  }

  @override
  String get salaryAligned => 'Your month already starts on payday';

  @override
  String salaryNotAligned(int monthStart, int salaryDay) {
    return 'Your month starts on day $monthStart, salary arrives on day $salaryDay';
  }

  @override
  String salaryAlignTitle(int day) {
    return 'Start months on day $day?';
  }

  @override
  String get salaryAlignMessage =>
      'Budgets and monthly totals will run from one salary to the next.';

  @override
  String get salaryAlignAction => 'Align';

  @override
  String get salaryRemove => 'Remove salary';

  @override
  String get salaryRemoveBody =>
      'The Salary rule will be deleted. Salary entries you already have are kept.';

  @override
  String get salaryRemoved => 'Salary removed';

  @override
  String get salarySaved => 'Salary saved';

  @override
  String salaryExpectedOn(String date) {
    return 'Expected $date';
  }

  @override
  String salaryReceivedAmount(String date, String amount) {
    return 'Received $amount on $date';
  }

  @override
  String salaryLateSince(String date) {
    return 'Late: expected $date';
  }

  @override
  String salaryLastReceived(String date, String amount) {
    return 'Last received $amount on $date';
  }

  @override
  String salaryNextExpected(String date) {
    return 'Next expected $date';
  }

  @override
  String get salaryNotSeenTitle => 'Salary not seen yet';

  @override
  String salaryNotSeenBody(String date) {
    return 'It was expected on $date. This clears by itself once it arrives.';
  }

  @override
  String get salaryRuleName => 'Salary';

  @override
  String get salaryMatchWindow => 'Can arrive early by';

  @override
  String salaryMatchWindowDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Up to $days days',
      one: 'Up to 1 day',
    );
    return '$_temp0';
  }

  @override
  String get salaryTolerance => 'Amount can differ by';

  @override
  String salaryTolerancePercent(int percent) {
    return 'Up to $percent%';
  }

  @override
  String get salaryToleranceExact => 'Exact amount only';

  @override
  String get salaryDetectionHelp =>
      'An income counts as salary when it is this close to the amount and arrives no earlier than this, or any day later in the cycle.';

  @override
  String get documentRemindersSection => 'Documents & renewals';

  @override
  String get documentRemindersHint =>
      'PUC, insurance, passport and other expiry dates';

  @override
  String get documentPresetVehicleInsurance => 'Vehicle insurance';

  @override
  String get documentPresetPuc => 'PUC certificate';

  @override
  String get documentPresetRcRenewal => 'RC renewal';

  @override
  String get documentPresetDrivingLicence => 'Driving licence';

  @override
  String get documentPresetPassport => 'Passport';

  @override
  String get documentPresetHealthInsurance => 'Health insurance premium';

  @override
  String get documentPresetLifeInsurance => 'Life insurance premium';

  @override
  String get documentPresetWarranty => 'Warranty expiry';

  @override
  String get documentPresetAmc => 'AMC renewal';

  @override
  String get documentPresetFdMaturity => 'FD maturity';

  @override
  String get documentPresetPropertyTax => 'Property tax';

  @override
  String get documentPresetRentAgreement => 'Rent agreement renewal';

  @override
  String get documentNumberLabel => 'Document number (optional)';

  @override
  String get documentNumberHint => 'Policy, registration or certificate number';

  @override
  String get documentRemindersOnProject => 'Reminders';

  @override
  String get reminderRepeatHalfYearly => 'Every 6 months';

  @override
  String get reminderRepeatElevenMonths => 'Every 11 months';

  @override
  String get reminderRepeatFiveYears => 'Every 5 years';

  @override
  String get reminderRepeatTenYears => 'Every 10 years';

  @override
  String get documentPucOlderVehicleHint =>
      'Older vehicles (before BS-IV) need PUC every 6 months.';

  @override
  String settleReminderTitle(String group) {
    return 'Settle up: $group';
  }

  @override
  String settleReminderOwesYou(String name, String amount) {
    return '$name owes you $amount';
  }

  @override
  String settleReminderYouOwe(String name, String amount) {
    return 'You owe $name $amount';
  }

  @override
  String settleReminderPeopleOweYou(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people owe you $amount',
      one: '1 person owes you $amount',
    );
    return '$_temp0';
  }

  @override
  String settleReminderYouOweTotal(String amount) {
    return 'You owe $amount in all';
  }

  @override
  String get settleReminderSheetTitle => 'Remind me to settle up';

  @override
  String get settleReminderWith => 'About';

  @override
  String get settleReminderEveryone => 'Everyone';

  @override
  String get settleReminderHowOften => 'How often';

  @override
  String get settleReminderMonthly => 'Monthly';

  @override
  String get settleReminderWeekly => 'Weekly';

  @override
  String get settleReminderOnDay => 'On day';

  @override
  String get settleReminderLastDay => 'Last day';

  @override
  String settleReminderNextAt(String date) {
    return 'Next reminder: $date';
  }

  @override
  String get settleReminderTurnOff => 'Turn off';

  @override
  String get settleReminderOffLabel => 'Settle-up reminder off';

  @override
  String settleReminderMonthlySummary(String day) {
    return 'Reminder on day $day every month';
  }

  @override
  String settleReminderWeeklySummary(String weekday) {
    return 'Reminder every $weekday';
  }

  @override
  String get settleReminderMonthlyLastDaySummary =>
      'Reminder on the last day of every month';

  @override
  String get groupRecurringAmountFixed =>
      'This split uses fixed amounts, so the total can\'t change here';

  @override
  String get groupRecurringUpcoming => 'Repeating';

  @override
  String get settleReminderShareNudge => 'Share a nudge';

  @override
  String get groupRecurringExpenseOnly =>
      'A group repeating rule can only be an expense.';

  @override
  String groupRecurringYourShare(String amount) {
    return 'your share $amount';
  }

  @override
  String get settleReminderPrePromptTitle => 'Get reminded to settle up';

  @override
  String get settleReminderPrePromptBody =>
      'Hisab sends a notification on the day you choose, only to remind you to settle up with this group. No marketing.';

  @override
  String get smsReminderPaidViaSms => 'Paid via SMS';

  @override
  String heroToday(String amount) {
    return 'Today $amount';
  }

  @override
  String heroTodaySemantics(String amount) {
    return 'Spent today $amount. Show today\'s entries';
  }

  @override
  String get numberFormatTitle => 'Number format';

  @override
  String get numberFormatAutomatic => 'Automatic';

  @override
  String get numberFormatAutomaticHelp => 'Follows your currency and region';

  @override
  String get smsPayeesTitle => 'Remembered payees';

  @override
  String get smsPayeesHelp =>
      'Categories you chose for a payee, used for their next SMS';

  @override
  String get smsPayeesEmptyTitle => 'No payees remembered yet';

  @override
  String get smsPayeesEmptyBody =>
      'Change the category of an entry added from an SMS and Hisab uses it for that payee\'s next messages.';

  @override
  String smsPayeeForget(String payee) {
    return 'Forget $payee';
  }

  @override
  String smsPayeeForgotten(String payee) {
    return '$payee forgotten';
  }

  @override
  String smsPayeeAskTitle(String payee) {
    return 'New person. Pick a category once for $payee';
  }

  @override
  String get smsPayeePickCategory => 'Pick category';

  @override
  String smsPayeeRemembered(String category, String payee) {
    return 'Hisab will use $category for $payee from now on';
  }

  @override
  String safeToSpendPerDay(String amount) {
    return 'Safe to spend $amount/day';
  }

  @override
  String get safeToSpendOverBudget => 'Over budget';

  @override
  String get smsEntryChannelName => 'Added from SMS';

  @override
  String get smsEntryChannelDescription =>
      'Entries Hisab added from bank SMS, with Change category and Undo';

  @override
  String get smsEntryChangeCategory => 'Change category';

  @override
  String get smsEntryNewPayeeHint => 'New payee: pick a category';

  @override
  String get smsEntryGoneTitle => 'This entry no longer exists';

  @override
  String get smsEntryGoneBody => 'It was undone or deleted.';

  @override
  String smsEntryCategoryChanged(String category) {
    return 'Category changed to $category';
  }

  @override
  String get shortcutsTitle => 'Shortcuts & widget';

  @override
  String get shortcutsHint =>
      'Add an expense from the notification shade, Quick Settings or Home screen';

  @override
  String get launcherShortcutsHelp =>
      'Long-press the Hisab icon for Add expense, Add income and your first two quick entries.';

  @override
  String get addExpenseNotification => 'Add expense notification';

  @override
  String get addExpenseNotificationHint =>
      'Keeps an Add expense shortcut in the notification shade';

  @override
  String get addExpenseNotificationChannel => 'Add expense shortcut';

  @override
  String get addExpenseNotificationBody => 'Tap to log a spend';

  @override
  String get addExpenseNotificationBlocked =>
      'Allow notifications for Hisab to show the shortcut';

  @override
  String get quickSettingsTile => 'Quick Settings tile';

  @override
  String get quickSettingsTileHint =>
      'Add expense from the panel you swipe down';

  @override
  String get quickSettingsTileManual =>
      'Swipe down twice from the top of the screen, tap the pencil to edit, then drag Hisab\'s Add expense tile into place.';

  @override
  String get homeScreenWidget => 'Home screen widget';

  @override
  String get homeScreenWidgetHint =>
      'This month\'s spend vs last month, with + to add';

  @override
  String get homeScreenWidgetManual =>
      'Long-press an empty spot on your Home screen, tap Widgets and pick Hisab.';

  @override
  String get widgetBackground => 'Widget background';

  @override
  String widgetBackgroundValue(int percent) {
    return '$percent% opaque';
  }

  @override
  String widgetLastMonth(String month, String amount) {
    return '$month: $amount';
  }

  @override
  String cardFromSms(String date) {
    return 'From SMS, $date';
  }

  @override
  String cardMinimumDue(String amount) {
    return 'Minimum due $amount';
  }

  @override
  String cardSmsAvailableLimit(String amount, String date) {
    return '$amount available, from SMS, $date';
  }

  @override
  String get smsCardUpdated => 'Card details updated.';

  @override
  String get scheduledBackupTitle => 'Scheduled backup';

  @override
  String get scheduledBackupOff =>
      'Off · back up on its own to a folder you choose';

  @override
  String scheduledBackupSummary(String frequency, String status) {
    return '$frequency · $status';
  }

  @override
  String get backupFrequency => 'How often';

  @override
  String get backupFrequencyOff => 'Off';

  @override
  String get backupFrequencyDaily => 'Daily';

  @override
  String get backupFrequencyWeekly => 'Weekly';

  @override
  String get backupFrequencyMonthly => 'Monthly';

  @override
  String get backupFolder => 'Folder';

  @override
  String get backupFolderNotChosen => 'Choose a folder';

  @override
  String get backupFolderHelp =>
      'Any folder on this phone or a synced one, such as Drive, OneDrive or an SD card';

  @override
  String get backupsKept => 'Backups to keep';

  @override
  String backupsKeptValue(int count) {
    return 'Last $count';
  }

  @override
  String get backupsKeptHelp =>
      'Older Hisab backups in this folder are deleted; other files are never touched';

  @override
  String get backupIncludeDrive => 'Also update the Google Drive copy';

  @override
  String get backupIncludeDriveHelp =>
      'Replaces the Drive copy on the same schedule, when Hisab is open';

  @override
  String get backupIncludeDriveNotConnected =>
      'Connect Back up to Google Drive first';

  @override
  String get scheduledBackupPassphraseSaved =>
      'Saved in this phone\'s secure storage, so backups run without asking';

  @override
  String get scheduledBackupPassphraseMissing =>
      'Not set: scheduled backups can\'t run';

  @override
  String get scheduledBackupPassphraseNote =>
      'Scheduled backups are encrypted with this passphrase. It stays in this phone\'s secure storage so a backup can run without asking. You need it to restore, so keep a copy somewhere safe.';

  @override
  String get scheduledBackupWhenBackground =>
      'Runs in the background once it is due (Android picks the moment, usually within a few hours) and whenever you open Hisab.';

  @override
  String get scheduledBackupWhenOnOpen =>
      'Runs when you open Hisab and a backup is due.';

  @override
  String get scheduledBackupSaved => 'Backup saved';

  @override
  String scheduledBackupFailedNow(String reason) {
    return 'Backup failed: $reason';
  }

  @override
  String scheduledBackupLast(String time, String place) {
    return 'Last backup: $time, $place';
  }

  @override
  String get scheduledBackupNone => 'No backup yet';

  @override
  String scheduledBackupFailed(String time, String reason) {
    return 'Backup failed $time: $reason';
  }

  @override
  String get scheduledBackupGoogleDrive => 'Google Drive';

  @override
  String get backupFailureNoPassphrase => 'no passphrase saved on this phone';

  @override
  String get backupFailureNoFolder => 'no folder chosen';

  @override
  String get backupFailureFolderUnavailable =>
      'the folder can\'t be reached; choose it again';

  @override
  String get backupFailureSignInNeeded =>
      'Google needs you to sign in again in Back up to Google Drive';

  @override
  String get backupFailureOffline => 'no internet connection';

  @override
  String backupFailureUnknown(String error) {
    return '$error';
  }

  @override
  String get appLockTitle => 'App lock';

  @override
  String get appLockSettingsHint =>
      'Ask for your fingerprint, face or screen lock to open Hisab';

  @override
  String appLockOnSummary(String timeout) {
    return 'On, locks $timeout';
  }

  @override
  String get appLockSwitch => 'Lock Hisab';

  @override
  String get appLockSwitchHelp =>
      'Uses your phone\'s fingerprint, face or screen lock (PIN, pattern or password). There is no separate PIN to forget.';

  @override
  String get appLockAfter => 'Lock again after leaving Hisab';

  @override
  String get appLockImmediately => 'immediately';

  @override
  String get appLockOneMinute => 'after 1 minute';

  @override
  String get appLockFiveMinutes => 'after 5 minutes';

  @override
  String get appLockImmediatelyShort => 'Immediately';

  @override
  String get appLockOneMinuteShort => '1 min';

  @override
  String get appLockFiveMinutesShort => '5 min';

  @override
  String get appLockHideInRecents => 'Hide in recent apps';

  @override
  String get appLockHideInRecentsHelp =>
      'Shows a blank card in the recent apps list. Screenshots of Hisab are blocked too.';

  @override
  String get appLockNoScreenLock =>
      'Your phone has no screen lock. Set a PIN, pattern or password in your phone\'s settings, then turn on app lock.';

  @override
  String get appLockEnableReason => 'Confirm it\'s you to turn on app lock';

  @override
  String get appLockPromptReason => 'Unlock Hisab';

  @override
  String get appLockLockedTitle => 'Hisab is locked';

  @override
  String get appLockLockedHint =>
      'Use your fingerprint, face or screen lock to open it.';

  @override
  String get appLockUnlock => 'Unlock';

  @override
  String get appLockLockedOut => 'Too many tries. Wait a little and try again.';

  @override
  String get cardLast4 => 'Last 4 digits';

  @override
  String get cardLast4Invalid => 'Enter 4 digits, or leave it empty.';
}
