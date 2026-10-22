import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hisab'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get tabEntries;

  /// No description provided for @tabGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get tabGroups;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @ignore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignore;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youSuffix(String name);

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @kindExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get kindExpense;

  /// No description provided for @kindIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get kindIncome;

  /// No description provided for @kindTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get kindTransfer;

  /// No description provided for @kindExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get kindExpenses;

  /// No description provided for @kindTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get kindTransfers;

  /// No description provided for @uncategorised.
  ///
  /// In en, this message translates to:
  /// **'Uncategorised'**
  String get uncategorised;

  /// No description provided for @yourShareOf.
  ///
  /// In en, this message translates to:
  /// **'{group} · your share'**
  String yourShareOf(String group);

  /// No description provided for @sourceSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get sourceSms;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountTypeCard;

  /// No description provided for @accountTypeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet / UPI'**
  String get accountTypeWallet;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccount;

  /// No description provided for @accountNameHint.
  ///
  /// In en, this message translates to:
  /// **'HDFC Savings, Paytm, Cash'**
  String get accountNameHint;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount due on the card'**
  String get outstandingBalance;

  /// No description provided for @cardDue.
  ///
  /// In en, this message translates to:
  /// **'Due {amount}'**
  String cardDue(String amount);

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @includeInTotal.
  ///
  /// In en, this message translates to:
  /// **'Include in total balance'**
  String get includeInTotal;

  /// No description provided for @excludedFromTotal.
  ///
  /// In en, this message translates to:
  /// **'excluded from total'**
  String get excludedFromTotal;

  /// No description provided for @asOf.
  ///
  /// In en, this message translates to:
  /// **'as of {date}'**
  String asOf(String date);

  /// No description provided for @noAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccountsTitle;

  /// No description provided for @noAccountsBody.
  ///
  /// In en, this message translates to:
  /// **'Bank accounts detected from SMS are added automatically with their reported balance. Manual entries adjust the balance of the account you pick.'**
  String get noAccountsBody;

  /// No description provided for @deleteNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteNamed(String name);

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @overallMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Overall monthly budget'**
  String get overallMonthlyBudget;

  /// No description provided for @budgetForCategory.
  ///
  /// In en, this message translates to:
  /// **'Budget for a category'**
  String get budgetForCategory;

  /// No description provided for @overallMonthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Overall monthly limit'**
  String get overallMonthlyLimit;

  /// No description provided for @categoryMonthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'{category} monthly limit'**
  String categoryMonthlyLimit(String category);

  /// No description provided for @noBudgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get noBudgetsTitle;

  /// No description provided for @noBudgetsBody.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly limit overall or per category. The dashboard shows pace and what is left.'**
  String get noBudgetsBody;

  /// No description provided for @removeBudgetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this budget?'**
  String get removeBudgetQuestion;

  /// No description provided for @budgetOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over {limit} by {amount}'**
  String budgetOverBy(String amount, String limit);

  /// No description provided for @budgetLeftWithDays.
  ///
  /// In en, this message translates to:
  /// **'{amount} of {limit} left · {days, plural, =1{1 day} other{{days} days}}'**
  String budgetLeftWithDays(String amount, String limit, int days);

  /// No description provided for @budgetRemoved.
  ///
  /// In en, this message translates to:
  /// **'Budget removed'**
  String get budgetRemoved;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @setOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Set opening balance'**
  String get setOpeningBalance;

  /// No description provided for @setBudget.
  ///
  /// In en, this message translates to:
  /// **'Set a budget'**
  String get setBudget;

  /// No description provided for @startGroup.
  ///
  /// In en, this message translates to:
  /// **'Start a group'**
  String get startGroup;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units: {units}'**
  String unitsLabel(String units);

  /// No description provided for @addSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Add subcategory'**
  String get addSubcategory;

  /// No description provided for @deleteCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Existing entries keep their amounts but become uncategorised.'**
  String get deleteCategoryBody;

  /// No description provided for @archiveCategory.
  ///
  /// In en, this message translates to:
  /// **'Archive (hide from picker)'**
  String get archiveCategory;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @newSubcategoryOf.
  ///
  /// In en, this message translates to:
  /// **'New subcategory of {parent}'**
  String newSubcategoryOf(String parent);

  /// No description provided for @editNamed.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editNamed(String name);

  /// No description provided for @unitsForItems.
  ///
  /// In en, this message translates to:
  /// **'Units for items (comma separated)'**
  String get unitsForItems;

  /// No description provided for @colour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colour;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get searchCategories;

  /// No description provided for @noMatchingCategory.
  ///
  /// In en, this message translates to:
  /// **'No matching category'**
  String get noMatchingCategory;

  /// No description provided for @moreCount.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String moreCount(int count);

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @smsToReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 SMS to review} other{{count} SMS to review}}'**
  String smsToReview(int count);

  /// No description provided for @spentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get spentThisMonth;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @overspent.
  ///
  /// In en, this message translates to:
  /// **'Overspent'**
  String get overspent;

  /// No description provided for @balances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get balances;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get spendingByCategory;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @noEntriesThisMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries this month'**
  String get noEntriesThisMonthTitle;

  /// No description provided for @noEntriesThisMonthBody.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first expense, or turn on SMS reading in Settings.'**
  String get noEntriesThisMonthBody;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @groupExpense.
  ///
  /// In en, this message translates to:
  /// **'Group expense'**
  String get groupExpense;

  /// No description provided for @deleteEntryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryQuestion;

  /// No description provided for @totalOfItems.
  ///
  /// In en, this message translates to:
  /// **'Total of {count} items'**
  String totalOfItems(int count);

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get chooseCategory;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get toAccount;

  /// No description provided for @payeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid to / received from'**
  String get payeeLabel;

  /// No description provided for @smsEntryNotice.
  ///
  /// In en, this message translates to:
  /// **'Created from a bank SMS. Editing it will not change your bank balance.'**
  String get smsEntryNotice;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveAmount.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String saveAmount(String amount);

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @itemSuggestion.
  ///
  /// In en, this message translates to:
  /// **'{name} · {quantity} @ {price}'**
  String itemSuggestion(String name, String quantity, String price);

  /// No description provided for @itemsHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional: break this expense into items with quantity and price (e.g. buffalo milk 1 L). Hisab remembers them for next time.'**
  String get itemsHelp;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount, e.g. 250 or 99.50'**
  String get invalidAmount;

  /// No description provided for @errorAmountZero.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get errorAmountZero;

  /// No description provided for @errorPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get errorPickCategory;

  /// No description provided for @errorPickBothAccounts.
  ///
  /// In en, this message translates to:
  /// **'Pick both accounts for a transfer'**
  String get errorPickBothAccounts;

  /// No description provided for @errorItemName.
  ///
  /// In en, this message translates to:
  /// **'Every item needs a name'**
  String get errorItemName;

  /// No description provided for @errorChoosePayer.
  ///
  /// In en, this message translates to:
  /// **'Choose who paid'**
  String get errorChoosePayer;

  /// No description provided for @errorFixSplit.
  ///
  /// In en, this message translates to:
  /// **'Fix the split first'**
  String get errorFixSplit;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemName;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @pricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price per {unit}'**
  String pricePerUnit(String unit);

  /// No description provided for @genericUnit.
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get genericUnit;

  /// No description provided for @shareSummary.
  ///
  /// In en, this message translates to:
  /// **'Share summary'**
  String get shareSummary;

  /// No description provided for @renameGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get renameGroup;

  /// No description provided for @deleteGroupBody.
  ///
  /// In en, this message translates to:
  /// **'All expenses in this group will be removed.'**
  String get deleteGroupBody;

  /// No description provided for @simplifyOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on simplify debts'**
  String get simplifyOn;

  /// No description provided for @simplifyOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off simplify debts'**
  String get simplifyOff;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @addMemberFirst.
  ///
  /// In en, this message translates to:
  /// **'Add at least one more member first'**
  String get addMemberFirst;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @shareHeader.
  ///
  /// In en, this message translates to:
  /// **'{group} — balances'**
  String shareHeader(String group);

  /// No description provided for @sharePays.
  ///
  /// In en, this message translates to:
  /// **'{from} pays {to} {amount}'**
  String sharePays(String from, String to, String amount);

  /// No description provided for @allSettledUp.
  ///
  /// In en, this message translates to:
  /// **'All settled up.'**
  String get allSettledUp;

  /// No description provided for @sharedFromHisab.
  ///
  /// In en, this message translates to:
  /// **'Shared from Hisab'**
  String get sharedFromHisab;

  /// No description provided for @paidByPeople.
  ///
  /// In en, this message translates to:
  /// **'{payer} paid · {count, plural, =1{1 person} other{{count} people}}'**
  String paidByPeople(String payer, int count);

  /// No description provided for @yourShare.
  ///
  /// In en, this message translates to:
  /// **'you: {amount}'**
  String yourShare(String amount);

  /// No description provided for @settlementLine.
  ///
  /// In en, this message translates to:
  /// **'{from} paid {to}'**
  String settlementLine(String from, String to);

  /// No description provided for @settledPayments.
  ///
  /// In en, this message translates to:
  /// **'Settled payments'**
  String get settledPayments;

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded {transfer} {amount}'**
  String paymentRecorded(String transfer, String amount);

  /// No description provided for @paymentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Payment removed'**
  String get paymentRemoved;

  /// No description provided for @removePayment.
  ///
  /// In en, this message translates to:
  /// **'Remove payment'**
  String get removePayment;

  /// No description provided for @removePaymentBody.
  ///
  /// In en, this message translates to:
  /// **'The balances will go back to what they were before this payment.'**
  String get removePaymentBody;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @noGroupExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noGroupExpensesTitle;

  /// No description provided for @noGroupExpensesBody.
  ///
  /// In en, this message translates to:
  /// **'Add the first shared expense; Hisab works out who owes whom.'**
  String get noGroupExpensesBody;

  /// No description provided for @netBalances.
  ///
  /// In en, this message translates to:
  /// **'Net balances'**
  String get netBalances;

  /// No description provided for @getsBack.
  ///
  /// In en, this message translates to:
  /// **'gets back'**
  String get getsBack;

  /// No description provided for @owes.
  ///
  /// In en, this message translates to:
  /// **'owes'**
  String get owes;

  /// No description provided for @settleUp.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get settleUp;

  /// No description provided for @settleUpSimplified.
  ///
  /// In en, this message translates to:
  /// **'Settle up (simplified)'**
  String get settleUpSimplified;

  /// No description provided for @everyoneSettled.
  ///
  /// In en, this message translates to:
  /// **'Everyone is settled up'**
  String get everyoneSettled;

  /// No description provided for @transferArrow.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String transferArrow(String from, String to);

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @settleBeforeRemove.
  ///
  /// In en, this message translates to:
  /// **'Settle this member\'s balance before removing them'**
  String get settleBeforeRemove;

  /// No description provided for @removeNamed.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeNamed(String name);

  /// No description provided for @renameMember.
  ///
  /// In en, this message translates to:
  /// **'Rename member'**
  String get renameMember;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @memberName.
  ///
  /// In en, this message translates to:
  /// **'Member name'**
  String get memberName;

  /// No description provided for @membersLocalNotice.
  ///
  /// In en, this message translates to:
  /// **'Members are stored on this device. Shared sync with invite codes is planned; see Settings → Sync.'**
  String get membersLocalNotice;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Goa trip, Flat 302…'**
  String get groupNameHint;

  /// No description provided for @membersCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Members (comma separated)'**
  String get membersCommaSeparated;

  /// No description provided for @membersHint.
  ///
  /// In en, this message translates to:
  /// **'Rahul, Priya, Aman'**
  String get membersHint;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @noGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Split bills with friends'**
  String get noGroupsTitle;

  /// No description provided for @noGroupsBody.
  ///
  /// In en, this message translates to:
  /// **'Create a group for a trip, flat or dinner. Add expenses, split them equally, by percentage, shares or exact amounts, and settle up.'**
  String get noGroupsBody;

  /// No description provided for @youAreOwed.
  ///
  /// In en, this message translates to:
  /// **'You are owed'**
  String get youAreOwed;

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get youOwe;

  /// No description provided for @groupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} members · {amount} spent'**
  String groupSubtitle(int count, String amount);

  /// No description provided for @youGet.
  ///
  /// In en, this message translates to:
  /// **'you get'**
  String get youGet;

  /// No description provided for @youOweLower.
  ///
  /// In en, this message translates to:
  /// **'you owe'**
  String get youOweLower;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// No description provided for @money.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get money;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'Currency symbol'**
  String get currencySymbol;

  /// No description provided for @monthStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Month starts on'**
  String get monthStartsOn;

  /// No description provided for @monthStartsOnHelp.
  ///
  /// In en, this message translates to:
  /// **'Use your salary date'**
  String get monthStartsOnHelp;

  /// No description provided for @monthStartsOnExplain.
  ///
  /// In en, this message translates to:
  /// **'Budgets and monthly totals follow your pay cycle'**
  String get monthStartsOnExplain;

  /// No description provided for @dayNumber.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dayNumber(int day);

  /// No description provided for @monthStartPrompt.
  ///
  /// In en, this message translates to:
  /// **'Month starts on day (1–28)'**
  String get monthStartPrompt;

  /// No description provided for @automation.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get automation;

  /// No description provided for @bankSms.
  ///
  /// In en, this message translates to:
  /// **'Bank SMS'**
  String get bankSms;

  /// No description provided for @bankSmsOn.
  ///
  /// In en, this message translates to:
  /// **'On · reading bank SMS on this device'**
  String get bankSmsOn;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @yourNameInGroups.
  ///
  /// In en, this message translates to:
  /// **'Your name in groups'**
  String get yourNameInGroups;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @backupAndSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & sync'**
  String get backupAndSync;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export encrypted backup'**
  String get exportBackup;

  /// No description provided for @exportBackupHelp.
  ///
  /// In en, this message translates to:
  /// **'AES-256, protected by a passphrase you choose'**
  String get exportBackupHelp;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupHelp.
  ///
  /// In en, this message translates to:
  /// **'Merges; newer local edits are kept'**
  String get restoreBackupHelp;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get cloudSync;

  /// No description provided for @cloudSyncHelp.
  ///
  /// In en, this message translates to:
  /// **'Coming next: Google Drive on Android, iCloud on iOS, end-to-end encrypted with the same format as backups.'**
  String get cloudSyncHelp;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Free, open source, no ads, no account needed. Your data stays on your device.'**
  String get aboutBody;

  /// No description provided for @backupPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Backup passphrase'**
  String get backupPassphrase;

  /// No description provided for @backupPassphraseHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters; you need it to restore'**
  String get backupPassphraseHelp;

  /// No description provided for @passphraseTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get passphraseTooShort;

  /// No description provided for @backupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Hisab encrypted backup'**
  String get backupShareSubject;

  /// No description provided for @restoredRecords.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} records'**
  String restoredRecords(int count);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @pasted.
  ///
  /// In en, this message translates to:
  /// **'PASTED'**
  String get pasted;

  /// No description provided for @smsFoundReview.
  ///
  /// In en, this message translates to:
  /// **'Transaction found. Review it below.'**
  String get smsFoundReview;

  /// No description provided for @smsAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction added.'**
  String get smsAdded;

  /// No description provided for @smsDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already imported.'**
  String get smsDuplicate;

  /// No description provided for @smsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find a transaction in that text.'**
  String get smsNotFound;

  /// No description provided for @readBankSmsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Read bank SMS?'**
  String get readBankSmsQuestion;

  /// No description provided for @smsConsentBody.
  ///
  /// In en, this message translates to:
  /// **'Hisab reads SMS from your bank and UPI apps to log transactions and show account balances. Messages are processed on this device only and never uploaded. OTPs and promotional SMS are ignored. You can turn this off any time.'**
  String get smsConsentBody;

  /// No description provided for @smsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'SMS permission was not granted'**
  String get smsPermissionDenied;

  /// No description provided for @scanResult.
  ///
  /// In en, this message translates to:
  /// **'Scanned {scanned} messages: {added} added, {pending} waiting for review.'**
  String scanResult(int scanned, int added, int pending);

  /// No description provided for @readBankSmsAuto.
  ///
  /// In en, this message translates to:
  /// **'Read bank SMS automatically'**
  String get readBankSmsAuto;

  /// No description provided for @smsAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Android only. Processed on-device, never uploaded.'**
  String get smsAndroidOnly;

  /// No description provided for @smsNotOnIos.
  ///
  /// In en, this message translates to:
  /// **'Not available on iOS. Use the Shortcut or paste below.'**
  String get smsNotOnIos;

  /// No description provided for @smsAutoAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add transactions without review'**
  String get smsAutoAddTitle;

  /// No description provided for @smsAutoAddHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: new SMS wait in the review list below.'**
  String get smsAutoAddHelp;

  /// No description provided for @scanInboxNow.
  ///
  /// In en, this message translates to:
  /// **'Scan inbox now'**
  String get scanInboxNow;

  /// No description provided for @scanInboxHelp.
  ///
  /// In en, this message translates to:
  /// **'Looks back 90 days the first time, then only new messages'**
  String get scanInboxHelp;

  /// No description provided for @pasteSms.
  ///
  /// In en, this message translates to:
  /// **'Paste an SMS'**
  String get pasteSms;

  /// No description provided for @pasteSmsHelp.
  ///
  /// In en, this message translates to:
  /// **'Works on iOS and Android'**
  String get pasteSmsHelp;

  /// No description provided for @pasteBankSms.
  ///
  /// In en, this message translates to:
  /// **'Paste bank SMS'**
  String get pasteBankSms;

  /// No description provided for @pasteBankSmsHint.
  ///
  /// In en, this message translates to:
  /// **'Rs.500 debited from A/c XX1234…'**
  String get pasteBankSmsHint;

  /// No description provided for @toReview.
  ///
  /// In en, this message translates to:
  /// **'To review ({count})'**
  String toReview(int count);

  /// No description provided for @nothingWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting'**
  String get nothingWaitingTitle;

  /// No description provided for @nothingWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'New bank transactions will show up here.'**
  String get nothingWaitingBody;

  /// No description provided for @iosShortcutHelp.
  ///
  /// In en, this message translates to:
  /// **'iPhone: create a Shortcuts automation \"When I get a message containing \'debited\'\" → \"Open URL\" with hisab:///sms?text=[Message]. Hisab will open and queue the transaction for review.'**
  String get iosShortcutHelp;

  /// No description provided for @couldNotAddUseEdit.
  ///
  /// In en, this message translates to:
  /// **'Could not add this one; use Edit'**
  String get couldNotAddUseEdit;

  /// No description provided for @addAmount.
  ///
  /// In en, this message translates to:
  /// **'Add {amount}'**
  String addAmount(String amount);

  /// No description provided for @splitDoesNotAddUp.
  ///
  /// In en, this message translates to:
  /// **'Split does not add up'**
  String get splitDoesNotAddUp;

  /// No description provided for @splitsAcross.
  ///
  /// In en, this message translates to:
  /// **'Splits {amount} across {count} people'**
  String splitsAcross(String amount, int count);

  /// No description provided for @splitEqual.
  ///
  /// In en, this message translates to:
  /// **'Equally'**
  String get splitEqual;

  /// No description provided for @splitExact.
  ///
  /// In en, this message translates to:
  /// **'Exact amounts'**
  String get splitExact;

  /// No description provided for @splitPercent.
  ///
  /// In en, this message translates to:
  /// **'Percentages'**
  String get splitPercent;

  /// No description provided for @splitShares.
  ///
  /// In en, this message translates to:
  /// **'Shares / ratio'**
  String get splitShares;

  /// No description provided for @splitAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get splitAdjustment;

  /// No description provided for @splitByItem.
  ///
  /// In en, this message translates to:
  /// **'By item'**
  String get splitByItem;

  /// No description provided for @splitHelpEqual.
  ///
  /// In en, this message translates to:
  /// **'Everyone ticked pays the same share.'**
  String get splitHelpEqual;

  /// No description provided for @splitHelpExact.
  ///
  /// In en, this message translates to:
  /// **'Enter the exact amount each person owes; must add up to the total.'**
  String get splitHelpExact;

  /// No description provided for @splitHelpPercent.
  ///
  /// In en, this message translates to:
  /// **'Enter percentages adding up to 100.'**
  String get splitHelpPercent;

  /// No description provided for @splitHelpShares.
  ///
  /// In en, this message translates to:
  /// **'Enter shares, e.g. 2 for a couple and 1 for a single.'**
  String get splitHelpShares;

  /// No description provided for @splitHelpAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Extras are charged first, the rest is split equally among ticked people.'**
  String get splitHelpAdjustment;

  /// No description provided for @splitHelpByItem.
  ///
  /// In en, this message translates to:
  /// **'Each item is split among the people who shared it.'**
  String get splitHelpByItem;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entries;

  /// No description provided for @searchEntriesHint.
  ///
  /// In en, this message translates to:
  /// **'Search payee, note, item or category'**
  String get searchEntriesHint;

  /// No description provided for @noEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noEntriesTitle;

  /// No description provided for @noEntriesBody.
  ///
  /// In en, this message translates to:
  /// **'Entries for this month will appear grouped by day.'**
  String get noEntriesBody;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'settled'**
  String get settled;

  /// No description provided for @unitsHint.
  ///
  /// In en, this message translates to:
  /// **'L, ml, kg'**
  String get unitsHint;

  /// No description provided for @splitErrorNegativeTotal.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot be negative'**
  String get splitErrorNegativeTotal;

  /// No description provided for @splitErrorNobodyIncluded.
  ///
  /// In en, this message translates to:
  /// **'Select at least one person'**
  String get splitErrorNobodyIncluded;

  /// No description provided for @splitErrorNegativeAmounts.
  ///
  /// In en, this message translates to:
  /// **'Amounts cannot be negative'**
  String get splitErrorNegativeAmounts;

  /// No description provided for @splitErrorAmountLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to assign'**
  String splitErrorAmountLeft(String amount);

  /// No description provided for @splitErrorAmountOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over the total'**
  String splitErrorAmountOver(String amount);

  /// No description provided for @splitErrorNegativeValues.
  ///
  /// In en, this message translates to:
  /// **'Values cannot be negative'**
  String get splitErrorNegativeValues;

  /// No description provided for @splitErrorPercentMustTotal.
  ///
  /// In en, this message translates to:
  /// **'Percentages must add up to 100'**
  String get splitErrorPercentMustTotal;

  /// No description provided for @splitErrorNoShares.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one share'**
  String get splitErrorNoShares;

  /// No description provided for @splitErrorPercentLeft.
  ///
  /// In en, this message translates to:
  /// **'{percent}% left to assign'**
  String splitErrorPercentLeft(String percent);

  /// No description provided for @splitErrorPercentOver.
  ///
  /// In en, this message translates to:
  /// **'{percent}% over 100'**
  String splitErrorPercentOver(String percent);

  /// No description provided for @splitErrorAdjustmentsExceed.
  ///
  /// In en, this message translates to:
  /// **'Adjustments exceed the total by {amount}'**
  String splitErrorAdjustmentsExceed(String amount);

  /// No description provided for @splitErrorAdjustmentNegativeShare.
  ///
  /// In en, this message translates to:
  /// **'An adjustment makes a share negative'**
  String get splitErrorAdjustmentNegativeShare;

  /// No description provided for @splitErrorNoItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get splitErrorNoItems;

  /// No description provided for @splitErrorItemsExceed.
  ///
  /// In en, this message translates to:
  /// **'Items exceed the total by {amount}'**
  String splitErrorItemsExceed(String amount);

  /// No description provided for @splitErrorItemUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Assign \"{item}\" to someone'**
  String splitErrorItemUnassigned(String item);

  /// No description provided for @genericItem.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get genericItem;

  /// No description provided for @spentInMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent in {month}'**
  String spentInMonth(String month);

  /// No description provided for @vsLastMonthUp.
  ///
  /// In en, this message translates to:
  /// **'▲ {percent}% vs {month}'**
  String vsLastMonthUp(int percent, String month);

  /// No description provided for @vsLastMonthDown.
  ///
  /// In en, this message translates to:
  /// **'▼ {percent}% vs {month}'**
  String vsLastMonthDown(int percent, String month);

  /// No description provided for @vsLastMonthSame.
  ///
  /// In en, this message translates to:
  /// **'Same as {month}'**
  String vsLastMonthSame(String month);

  /// No description provided for @dailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily avg'**
  String get dailyAverage;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'{amount}/day'**
  String perDay(String amount);

  /// No description provided for @daysOfMonth.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} of {total} days'**
  String daysOfMonth(int elapsed, int total);

  /// No description provided for @heroEmptyCaption.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent yet this month'**
  String get heroEmptyCaption;

  /// No description provided for @addFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Add your first entry'**
  String get addFirstEntry;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @spendingTrend.
  ///
  /// In en, this message translates to:
  /// **'Spending trend'**
  String get spendingTrend;

  /// No description provided for @trendDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get trendDaily;

  /// No description provided for @trendMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get trendMonthly;

  /// No description provided for @trendEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a few entries to see your trend'**
  String get trendEmpty;

  /// No description provided for @trendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Spending trend: {amount} spent so far this month'**
  String trendSemantics(String amount);

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get thisMonth;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your categories will show up here'**
  String get categoriesEmpty;

  /// No description provided for @percentOf.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String percentOf(int percent);

  /// No description provided for @budgetsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Set a budget to see how you\'re tracking'**
  String get budgetsEmptyBody;

  /// No description provided for @andMoreCount.
  ///
  /// In en, this message translates to:
  /// **'and {count, plural, =1{1 more} other{{count} more}}'**
  String andMoreCount(int count);

  /// No description provided for @youGetAmount.
  ///
  /// In en, this message translates to:
  /// **'You get {amount}'**
  String youGetAmount(String amount);

  /// No description provided for @youOweAmount.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String youOweAmount(String amount);

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @upcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing due in the next two weeks'**
  String get upcomingEmpty;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String memberCount(int count);

  /// No description provided for @noEntriesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntriesYetTitle;

  /// No description provided for @noEntriesYetBody.
  ///
  /// In en, this message translates to:
  /// **'Add one with + or turn on Bank SMS to capture them automatically'**
  String get noEntriesYetBody;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntry;

  /// No description provided for @showAllCategories.
  ///
  /// In en, this message translates to:
  /// **'Show all categories'**
  String get showAllCategories;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// No description provided for @blankProject.
  ///
  /// In en, this message translates to:
  /// **'Blank project'**
  String get blankProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @noProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsTitle;

  /// No description provided for @noProjectsBody.
  ///
  /// In en, this message translates to:
  /// **'Track a car, a renovation, a trip or a wedding against its own budget.'**
  String get noProjectsBody;

  /// No description provided for @startProject.
  ///
  /// In en, this message translates to:
  /// **'Start a project'**
  String get startProject;

  /// No description provided for @projectsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start a project to track a big spend against its budget'**
  String get projectsEmptyBody;

  /// No description provided for @projectStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get projectStatusActive;

  /// No description provided for @projectStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectStatusCompleted;

  /// No description provided for @projectStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projectStatusArchived;

  /// No description provided for @showArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get showArchived;

  /// No description provided for @hideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide archived'**
  String get hideArchived;

  /// No description provided for @spentOfBudget.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {budget}'**
  String spentOfBudget(String spent, String budget);

  /// No description provided for @spentAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} spent'**
  String spentAmount(String amount);

  /// No description provided for @leftOfBudget.
  ///
  /// In en, this message translates to:
  /// **'{amount} of {budget} left'**
  String leftOfBudget(String amount, String budget);

  /// No description provided for @receivedAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} came back'**
  String receivedAmount(String amount);

  /// No description provided for @noBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'No budget set'**
  String get noBudgetSet;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'all time'**
  String get allTime;

  /// No description provided for @entryCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No entries} =1{1 entry} other{{count} entries}}'**
  String entryCountLabel(int count);

  /// No description provided for @noProjectEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent yet'**
  String get noProjectEntriesTitle;

  /// No description provided for @noProjectEntriesBody.
  ///
  /// In en, this message translates to:
  /// **'Add an entry from here and it counts towards this project'**
  String get noProjectEntriesBody;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get markCompleted;

  /// No description provided for @reopenProject.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopenProject;

  /// No description provided for @archiveProject.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveProject;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProject;

  /// No description provided for @deleteProjectBody.
  ///
  /// In en, this message translates to:
  /// **'Entries stay in your ledger; they just leave this project.'**
  String get deleteProjectBody;

  /// No description provided for @projectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Project deleted'**
  String get projectDeleted;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @budgetOptional.
  ///
  /// In en, this message translates to:
  /// **'Budget (optional)'**
  String get budgetOptional;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'This project was deleted'**
  String get projectNotFound;

  /// No description provided for @spentSoFar.
  ///
  /// In en, this message translates to:
  /// **'Spent so far'**
  String get spentSoFar;

  /// No description provided for @spendingByMonth.
  ///
  /// In en, this message translates to:
  /// **'Spending by month'**
  String get spendingByMonth;

  /// No description provided for @projectMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Marked completed'**
  String get projectMarkedCompleted;

  /// No description provided for @projectArchivedSnack.
  ///
  /// In en, this message translates to:
  /// **'Project archived'**
  String get projectArchivedSnack;

  /// No description provided for @projectReopened.
  ///
  /// In en, this message translates to:
  /// **'Project reopened'**
  String get projectReopened;

  /// No description provided for @projectDates.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String projectDates(String start, String end);

  /// No description provided for @sinceDate.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String sinceDate(String date);

  /// No description provided for @untilDate.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String untilDate(String date);

  /// No description provided for @startFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'Start from a template'**
  String get startFromTemplate;

  /// No description provided for @blankProjectHint.
  ///
  /// In en, this message translates to:
  /// **'Name it and track anything'**
  String get blankProjectHint;

  /// No description provided for @templateVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get templateVehicle;

  /// No description provided for @templateVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Fuel, service, insurance and cost per km'**
  String get templateVehicleHint;

  /// No description provided for @templateConstruction.
  ///
  /// In en, this message translates to:
  /// **'Home construction'**
  String get templateConstruction;

  /// No description provided for @templateConstructionHint.
  ///
  /// In en, this message translates to:
  /// **'Materials, labour, stages and cost per sq ft'**
  String get templateConstructionHint;

  /// No description provided for @templateRenovation.
  ///
  /// In en, this message translates to:
  /// **'Renovation'**
  String get templateRenovation;

  /// No description provided for @templateRenovationHint.
  ///
  /// In en, this message translates to:
  /// **'Room by room, materials and workers'**
  String get templateRenovationHint;

  /// No description provided for @templateTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get templateTrip;

  /// No description provided for @templateTripHint.
  ///
  /// In en, this message translates to:
  /// **'Travel, stay, food and sightseeing'**
  String get templateTripHint;

  /// No description provided for @templateWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get templateWedding;

  /// No description provided for @templateWeddingHint.
  ///
  /// In en, this message translates to:
  /// **'Venue, catering, outfits, vendors and shagun'**
  String get templateWeddingHint;

  /// No description provided for @addSuggestedCategories.
  ///
  /// In en, this message translates to:
  /// **'Add suggested categories'**
  String get addSuggestedCategories;

  /// No description provided for @suggestedCategoriesNew.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new category} other{{count} new categories}}'**
  String suggestedCategoriesNew(int count);

  /// No description provided for @suggestedCategoriesReused.
  ///
  /// In en, this message translates to:
  /// **'{count} already in your list'**
  String suggestedCategoriesReused(int count);

  /// No description provided for @categoryPacks.
  ///
  /// In en, this message translates to:
  /// **'Category packs'**
  String get categoryPacks;

  /// No description provided for @addAPack.
  ///
  /// In en, this message translates to:
  /// **'Add a pack'**
  String get addAPack;

  /// No description provided for @categoryPacksHint.
  ///
  /// In en, this message translates to:
  /// **'Ready-made sets of categories for a part of your life. Add one in a tap and remove it any time.'**
  String get categoryPacksHint;

  /// No description provided for @packCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 category} other{{count} categories}}'**
  String packCategoryCount(int count);

  /// No description provided for @packAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get packAdded;

  /// No description provided for @addPack.
  ///
  /// In en, this message translates to:
  /// **'Add pack'**
  String get addPack;

  /// No description provided for @removePack.
  ///
  /// In en, this message translates to:
  /// **'Remove pack'**
  String get removePack;

  /// No description provided for @packAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Pack added. You already had all its categories} =1{Pack added with 1 new category} other{Pack added with {count} new categories}}'**
  String packAddedMessage(int count);

  /// No description provided for @removePackTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {pack}?'**
  String removePackTitle(String pack);

  /// No description provided for @removePackMessage.
  ///
  /// In en, this message translates to:
  /// **'Unused categories ({archived}) will be archived. Categories in use ({kept}) stay as your own.'**
  String removePackMessage(int archived, int kept);

  /// No description provided for @packRemoved.
  ///
  /// In en, this message translates to:
  /// **'Pack removed'**
  String get packRemoved;

  /// No description provided for @packAlreadyHave.
  ///
  /// In en, this message translates to:
  /// **'Already in your list'**
  String get packAlreadyHave;

  /// No description provided for @suggestedCategoriesAllPresent.
  ///
  /// In en, this message translates to:
  /// **'All suggested categories are already in your list'**
  String get suggestedCategoriesAllPresent;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project details'**
  String get projectDetails;

  /// No description provided for @fieldOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get fieldOdometer;

  /// No description provided for @fieldLitres.
  ///
  /// In en, this message translates to:
  /// **'Fuel litres'**
  String get fieldLitres;

  /// No description provided for @fieldBuiltUpArea.
  ///
  /// In en, this message translates to:
  /// **'Built-up area'**
  String get fieldBuiltUpArea;

  /// No description provided for @fieldStage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get fieldStage;

  /// No description provided for @fieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fieldQuantity;

  /// No description provided for @fieldRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get fieldRoom;

  /// No description provided for @fieldTravellers.
  ///
  /// In en, this message translates to:
  /// **'Travellers'**
  String get fieldTravellers;

  /// No description provided for @fieldEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get fieldEvent;

  /// No description provided for @fieldVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get fieldVendor;

  /// No description provided for @stageFoundation.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get stageFoundation;

  /// No description provided for @stagePlinth.
  ///
  /// In en, this message translates to:
  /// **'Plinth'**
  String get stagePlinth;

  /// No description provided for @stageStructure.
  ///
  /// In en, this message translates to:
  /// **'Structure'**
  String get stageStructure;

  /// No description provided for @stageBrickwork.
  ///
  /// In en, this message translates to:
  /// **'Brickwork'**
  String get stageBrickwork;

  /// No description provided for @stageRoofSlab.
  ///
  /// In en, this message translates to:
  /// **'Roof slab'**
  String get stageRoofSlab;

  /// No description provided for @stagePlaster.
  ///
  /// In en, this message translates to:
  /// **'Plaster'**
  String get stagePlaster;

  /// No description provided for @stageElectricalPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Electrical & plumbing'**
  String get stageElectricalPlumbing;

  /// No description provided for @stageFlooring.
  ///
  /// In en, this message translates to:
  /// **'Flooring'**
  String get stageFlooring;

  /// No description provided for @stageDoorsWindows.
  ///
  /// In en, this message translates to:
  /// **'Doors & windows'**
  String get stageDoorsWindows;

  /// No description provided for @stagePainting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get stagePainting;

  /// No description provided for @stageFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing'**
  String get stageFinishing;

  /// No description provided for @roomKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get roomKitchen;

  /// No description provided for @roomBathroom.
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get roomBathroom;

  /// No description provided for @roomBedroom.
  ///
  /// In en, this message translates to:
  /// **'Bedroom'**
  String get roomBedroom;

  /// No description provided for @roomLivingRoom.
  ///
  /// In en, this message translates to:
  /// **'Living room'**
  String get roomLivingRoom;

  /// No description provided for @roomDining.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get roomDining;

  /// No description provided for @roomBalcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get roomBalcony;

  /// No description provided for @roomWholeHouse.
  ///
  /// In en, this message translates to:
  /// **'Whole house'**
  String get roomWholeHouse;

  /// No description provided for @eventRoka.
  ///
  /// In en, this message translates to:
  /// **'Roka'**
  String get eventRoka;

  /// No description provided for @eventEngagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get eventEngagement;

  /// No description provided for @eventHaldi.
  ///
  /// In en, this message translates to:
  /// **'Haldi'**
  String get eventHaldi;

  /// No description provided for @eventMehndi.
  ///
  /// In en, this message translates to:
  /// **'Mehndi'**
  String get eventMehndi;

  /// No description provided for @eventSangeet.
  ///
  /// In en, this message translates to:
  /// **'Sangeet'**
  String get eventSangeet;

  /// No description provided for @eventWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get eventWedding;

  /// No description provided for @eventReception.
  ///
  /// In en, this message translates to:
  /// **'Reception'**
  String get eventReception;

  /// No description provided for @projectMetrics.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get projectMetrics;

  /// No description provided for @costPerKm.
  ///
  /// In en, this message translates to:
  /// **'Cost per km'**
  String get costPerKm;

  /// No description provided for @kmDriven.
  ///
  /// In en, this message translates to:
  /// **'{km} km driven'**
  String kmDriven(String km);

  /// No description provided for @fuelBought.
  ///
  /// In en, this message translates to:
  /// **'Fuel bought'**
  String get fuelBought;

  /// No description provided for @litresAmount.
  ///
  /// In en, this message translates to:
  /// **'{litres} L for {amount}'**
  String litresAmount(String litres, String amount);

  /// No description provided for @pricePerLitre.
  ///
  /// In en, this message translates to:
  /// **'Price per litre'**
  String get pricePerLitre;

  /// No description provided for @costPerSqFt.
  ///
  /// In en, this message translates to:
  /// **'Cost per sq ft'**
  String get costPerSqFt;

  /// No description provided for @areaOf.
  ///
  /// In en, this message translates to:
  /// **'over {area} sq ft'**
  String areaOf(String area);

  /// No description provided for @costPerTraveller.
  ///
  /// In en, this message translates to:
  /// **'Cost per traveller'**
  String get costPerTraveller;

  /// No description provided for @travellersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 traveller} other{{count} travellers}}'**
  String travellersCount(int count);

  /// No description provided for @spendingByField.
  ///
  /// In en, this message translates to:
  /// **'Spending by {field}'**
  String spendingByField(String field);

  /// No description provided for @notPicked.
  ///
  /// In en, this message translates to:
  /// **'Not picked'**
  String get notPicked;

  /// No description provided for @metricsHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in project details on entries (odometer, stage, room…) to see metrics here.'**
  String get metricsHint;

  /// No description provided for @projectFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get projectFields;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get addField;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get fieldName;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldType;

  /// No description provided for @fieldTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get fieldTypeNumber;

  /// No description provided for @fieldTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get fieldTypeText;

  /// No description provided for @fieldTypeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldTypeDate;

  /// No description provided for @fieldTypeChoice.
  ///
  /// In en, this message translates to:
  /// **'Choice'**
  String get fieldTypeChoice;

  /// No description provided for @fieldTypeUnit.
  ///
  /// In en, this message translates to:
  /// **'Amount with unit'**
  String get fieldTypeUnit;

  /// No description provided for @fieldUnitOptional.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get fieldUnitOptional;

  /// No description provided for @fieldOptions.
  ///
  /// In en, this message translates to:
  /// **'Options, separated by commas'**
  String get fieldOptions;

  /// No description provided for @fieldOnEachEntry.
  ///
  /// In en, this message translates to:
  /// **'Asked on each entry'**
  String get fieldOnEachEntry;

  /// No description provided for @fieldOncePerProject.
  ///
  /// In en, this message translates to:
  /// **'One value for the project'**
  String get fieldOncePerProject;

  /// No description provided for @fieldDeleted.
  ///
  /// In en, this message translates to:
  /// **'Field deleted'**
  String get fieldDeleted;

  /// No description provided for @deleteField.
  ///
  /// In en, this message translates to:
  /// **'Delete field'**
  String get deleteField;

  /// No description provided for @setValue.
  ///
  /// In en, this message translates to:
  /// **'Set value'**
  String get setValue;

  /// No description provided for @errorFieldName.
  ///
  /// In en, this message translates to:
  /// **'Give the field a name'**
  String get errorFieldName;

  /// No description provided for @errorFieldOptions.
  ///
  /// In en, this message translates to:
  /// **'Add at least one option'**
  String get errorFieldOptions;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @savePayment.
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get savePayment;

  /// No description provided for @recordAPayment.
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get recordAPayment;

  /// No description provided for @recordAPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'Any pair, any amount — partial payments are fine'**
  String get recordAPaymentHint;

  /// No description provided for @editPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit payment'**
  String get editPayment;

  /// No description provided for @paymentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Payment updated'**
  String get paymentUpdated;

  /// No description provided for @paymentFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get paymentFrom;

  /// No description provided for @paymentTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get paymentTo;

  /// No description provided for @swapDirection.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swapDirection;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get paymentMethod;

  /// No description provided for @methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get methodCash;

  /// No description provided for @methodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get methodUpi;

  /// No description provided for @methodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get methodBank;

  /// No description provided for @methodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get methodOther;

  /// No description provided for @paymentOverOwed.
  ///
  /// In en, this message translates to:
  /// **'More than the {amount} owed; the extra becomes a credit'**
  String paymentOverOwed(String amount);

  /// No description provided for @paymentNoDebt.
  ///
  /// In en, this message translates to:
  /// **'{from} owes {to} nothing right now; this payment becomes a credit'**
  String paymentNoDebt(String from, String to);

  /// No description provided for @paymentVia.
  ///
  /// In en, this message translates to:
  /// **'Payment · {method}'**
  String paymentVia(String method);

  /// No description provided for @samePersonError.
  ///
  /// In en, this message translates to:
  /// **'Pick two different people'**
  String get samePersonError;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @filterMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get filterMine;

  /// No description provided for @filterUnsettled.
  ///
  /// In en, this message translates to:
  /// **'Unsettled'**
  String get filterUnsettled;

  /// No description provided for @nothingInvolvingYou.
  ///
  /// In en, this message translates to:
  /// **'Nothing involving you yet.'**
  String get nothingInvolvingYou;

  /// No description provided for @expensesAllSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled up. New expenses will show here.'**
  String get expensesAllSettled;

  /// No description provided for @settledUpTo.
  ///
  /// In en, this message translates to:
  /// **'Settled up to {date}'**
  String settledUpTo(String date);

  /// No description provided for @showOlderRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 older entry} other{Show {count} older entries}}'**
  String showOlderRows(int count);

  /// No description provided for @hideOlderRows.
  ///
  /// In en, this message translates to:
  /// **'Hide older entries'**
  String get hideOlderRows;

  /// No description provided for @youLent.
  ///
  /// In en, this message translates to:
  /// **'you lent'**
  String get youLent;

  /// No description provided for @youBorrowed.
  ///
  /// In en, this message translates to:
  /// **'you borrowed'**
  String get youBorrowed;

  /// No description provided for @youPaid.
  ///
  /// In en, this message translates to:
  /// **'you paid'**
  String get youPaid;

  /// No description provided for @youReceived.
  ///
  /// In en, this message translates to:
  /// **'you received'**
  String get youReceived;

  /// No description provided for @notInvolved.
  ///
  /// In en, this message translates to:
  /// **'not involved'**
  String get notInvolved;

  /// No description provided for @payerPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'{payer} paid {amount}'**
  String payerPaidAmount(String payer, String amount);

  /// No description provided for @youPaidName.
  ///
  /// In en, this message translates to:
  /// **'You paid {name}'**
  String youPaidName(String name);

  /// No description provided for @namePaidYou.
  ///
  /// In en, this message translates to:
  /// **'{name} paid you'**
  String namePaidYou(String name);

  /// No description provided for @addToProject.
  ///
  /// In en, this message translates to:
  /// **'Add to project'**
  String get addToProject;

  /// No description provided for @chooseProject.
  ///
  /// In en, this message translates to:
  /// **'Choose project'**
  String get chooseProject;

  /// No description provided for @noProject.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get noProject;

  /// No description provided for @noActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'No active projects. Start one from the Projects screen.'**
  String get noActiveProjects;

  /// No description provided for @remindAction.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get remindAction;

  /// No description provided for @payAction.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payAction;

  /// No description provided for @remindName.
  ///
  /// In en, this message translates to:
  /// **'Remind {name}'**
  String remindName(String name);

  /// No description provided for @payName.
  ///
  /// In en, this message translates to:
  /// **'Pay {name}'**
  String payName(String name);

  /// No description provided for @reminderOwesMe.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}, a quick reminder: you owe me {amount} for {group}.'**
  String reminderOwesMe(String name, String amount, String group);

  /// No description provided for @reminderIOwe.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}, I owe you {amount} for {group}. Paying now.'**
  String reminderIOwe(String name, String amount, String group);

  /// No description provided for @reminderOwes.
  ///
  /// In en, this message translates to:
  /// **'{from} owes {to} {amount} for {group}.'**
  String reminderOwes(String from, String to, String amount, String group);

  /// No description provided for @reminderEveryone.
  ///
  /// In en, this message translates to:
  /// **'Settling up {group}:'**
  String reminderEveryone(String group);

  /// No description provided for @owesLine.
  ///
  /// In en, this message translates to:
  /// **'{from} owes {to} {amount}'**
  String owesLine(String from, String to, String amount);

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share…'**
  String get shareAction;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @whatsAppAction.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsAppAction;

  /// No description provided for @smsAction.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get smsAction;

  /// No description provided for @payWithUpi.
  ///
  /// In en, this message translates to:
  /// **'Pay with UPI'**
  String get payWithUpi;

  /// No description provided for @noUpiApp.
  ///
  /// In en, this message translates to:
  /// **'No UPI app on this phone. Pay another way, then record it.'**
  String get noUpiApp;

  /// No description provided for @couldNotOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open {app}.'**
  String couldNotOpenApp(String app);

  /// No description provided for @didPaymentGoThrough.
  ///
  /// In en, this message translates to:
  /// **'Did the payment go through?'**
  String get didPaymentGoThrough;

  /// No description provided for @didPaymentGoThroughBody.
  ///
  /// In en, this message translates to:
  /// **'If {amount} reached {name}, Hisab records it as paid by UPI today. Hisab can\'t see your UPI app, so only you can confirm.'**
  String didPaymentGoThroughBody(String amount, String name);

  /// No description provided for @yesRecordIt.
  ///
  /// In en, this message translates to:
  /// **'Yes, record it'**
  String get yesRecordIt;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @remindedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Reminded today} =1{Reminded yesterday} other{Reminded {days} days ago}}'**
  String remindedDaysAgo(int days);

  /// No description provided for @remindAgain.
  ///
  /// In en, this message translates to:
  /// **'Remind again'**
  String get remindAgain;

  /// No description provided for @copiedReminder.
  ///
  /// In en, this message translates to:
  /// **'Copied. Paste it into any chat.'**
  String get copiedReminder;

  /// No description provided for @nothingToRemind.
  ///
  /// In en, this message translates to:
  /// **'Everyone is settled up. Nothing to remind or pay.'**
  String get nothingToRemind;

  /// No description provided for @shareSummaryAnyway.
  ///
  /// In en, this message translates to:
  /// **'Share the summary anyway'**
  String get shareSummaryAnyway;

  /// No description provided for @shareBalancesSummary.
  ///
  /// In en, this message translates to:
  /// **'Share balances summary'**
  String get shareBalancesSummary;

  /// No description provided for @remindEveryoneWhoOwes.
  ///
  /// In en, this message translates to:
  /// **'Remind everyone who owes you'**
  String get remindEveryoneWhoOwes;

  /// No description provided for @copyAsText.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get copyAsText;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @upiIdOptional.
  ///
  /// In en, this message translates to:
  /// **'UPI ID (optional)'**
  String get upiIdOptional;

  /// No description provided for @upiIdHint.
  ///
  /// In en, this message translates to:
  /// **'name@bank'**
  String get upiIdHint;

  /// No description provided for @invalidUpiId.
  ///
  /// In en, this message translates to:
  /// **'Enter a UPI ID like name@bank'**
  String get invalidUpiId;

  /// No description provided for @memberContactLocal.
  ///
  /// In en, this message translates to:
  /// **'Phone and UPI ID stay on this device. Hisab uses them only to fill in reminders and UPI payments.'**
  String get memberContactLocal;

  /// No description provided for @editMember.
  ///
  /// In en, this message translates to:
  /// **'Edit member'**
  String get editMember;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filterEntries.
  ///
  /// In en, this message translates to:
  /// **'Filter entries'**
  String get filterEntries;

  /// No description provided for @anyProject.
  ///
  /// In en, this message translates to:
  /// **'Any project'**
  String get anyProject;

  /// No description provided for @anyCategory.
  ///
  /// In en, this message translates to:
  /// **'Any category'**
  String get anyCategory;

  /// No description provided for @anyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get anyDate;

  /// No description provided for @minAmount.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxAmount;

  /// No description provided for @dates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dates;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// No description provided for @amountFrom.
  ///
  /// In en, this message translates to:
  /// **'From {amount}'**
  String amountFrom(String amount);

  /// No description provided for @amountUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {amount}'**
  String amountUpTo(String amount);

  /// No description provided for @amountBetween.
  ///
  /// In en, this message translates to:
  /// **'{min} – {max}'**
  String amountBetween(String min, String max);

  /// No description provided for @minAboveMax.
  ///
  /// In en, this message translates to:
  /// **'Min is more than max'**
  String get minAboveMax;

  /// No description provided for @calculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculator;

  /// No description provided for @useAmount.
  ///
  /// In en, this message translates to:
  /// **'Use {amount}'**
  String useAmount(String amount);

  /// No description provided for @calcDivideByZero.
  ///
  /// In en, this message translates to:
  /// **'Can\'t divide by zero'**
  String get calcDivideByZero;

  /// No description provided for @calcNegative.
  ///
  /// In en, this message translates to:
  /// **'The result is below zero'**
  String get calcNegative;

  /// No description provided for @calcTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The result is too large'**
  String get calcTooLarge;

  /// No description provided for @saveAndAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Save & add another'**
  String get saveAndAddAnother;

  /// No description provided for @savedAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Saved. Add the next one.'**
  String get savedAddAnother;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @remindersUpcomingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing due} =1{1 upcoming} other{{count} upcoming}}'**
  String remindersUpcomingCount(int count);

  /// No description provided for @remindersNotificationsOn.
  ///
  /// In en, this message translates to:
  /// **'notifications on'**
  String get remindersNotificationsOn;

  /// No description provided for @remindersNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'notifications off'**
  String get remindersNotificationsOff;

  /// No description provided for @remindersSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} · {state}'**
  String remindersSettingsSubtitle(String count, String state);

  /// No description provided for @reminderTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get reminderTabHistory;

  /// No description provided for @reminderSectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get reminderSectionOverdue;

  /// No description provided for @reminderSectionThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get reminderSectionThisWeek;

  /// No description provided for @reminderSectionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get reminderSectionLater;

  /// No description provided for @reminderAdd.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get reminderAdd;

  /// No description provided for @reminderFab.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderFab;

  /// No description provided for @remindersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get remindersEmptyTitle;

  /// No description provided for @remindersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Bills, rent, EMIs, renewals: add one and Hisab will nudge you before it\'s due.'**
  String get remindersEmptyBody;

  /// No description provided for @reminderHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Paid and skipped reminders show up here.'**
  String get reminderHistoryEmpty;

  /// No description provided for @reminderSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this time'**
  String get reminderSkip;

  /// No description provided for @reminderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted'**
  String get reminderDeleted;

  /// No description provided for @reminderMarkedPaid.
  ///
  /// In en, this message translates to:
  /// **'Marked paid'**
  String get reminderMarkedPaid;

  /// No description provided for @reminderMarkedDone.
  ///
  /// In en, this message translates to:
  /// **'Marked done'**
  String get reminderMarkedDone;

  /// No description provided for @reminderSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped this time'**
  String get reminderSkipped;

  /// No description provided for @reminderSnoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {date}'**
  String reminderSnoozedUntil(String date);

  /// No description provided for @reminderAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'Already marked paid'**
  String get reminderAlreadyDone;

  /// No description provided for @reminderPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String reminderPaidOn(String date);

  /// No description provided for @reminderDoneOn.
  ///
  /// In en, this message translates to:
  /// **'Done {date}'**
  String reminderDoneOn(String date);

  /// No description provided for @reminderSkippedOn.
  ///
  /// In en, this message translates to:
  /// **'Skipped {date}'**
  String reminderSkippedOn(String date);

  /// No description provided for @reminderNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due {date}'**
  String reminderNextDue(String date);

  /// No description provided for @notifOffBanner.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Reminders will only show in the app.'**
  String get notifOffBanner;

  /// No description provided for @notifTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get notifTurnOn;

  /// No description provided for @reminderExactAlarmNote.
  ///
  /// In en, this message translates to:
  /// **'Alerts may come a few minutes late. Exact timing needs the Alarms & reminders permission.'**
  String get reminderExactAlarmNote;

  /// No description provided for @notifPrePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded before it\'s due'**
  String get notifPrePromptTitle;

  /// No description provided for @notifPrePromptBody.
  ///
  /// In en, this message translates to:
  /// **'Hisab sends a notification at the time you choose, only for your reminders. No marketing.'**
  String get notifPrePromptBody;

  /// No description provided for @reminderPaidSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid {title}?'**
  String reminderPaidSheetTitle(String title);

  /// No description provided for @reminderPaidSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Add an expense of {amount} and mark this paid.'**
  String reminderPaidSheetBody(String amount);

  /// No description provided for @reminderAddEntryAndMark.
  ///
  /// In en, this message translates to:
  /// **'Add entry & mark paid'**
  String get reminderAddEntryAndMark;

  /// No description provided for @reminderJustMark.
  ///
  /// In en, this message translates to:
  /// **'Just mark paid'**
  String get reminderJustMark;

  /// No description provided for @reminderNew.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get reminderNew;

  /// No description provided for @reminderEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get reminderEditTitle;

  /// No description provided for @reminderKindBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get reminderKindBill;

  /// No description provided for @reminderKindEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get reminderKindEmi;

  /// No description provided for @reminderKindCard.
  ///
  /// In en, this message translates to:
  /// **'Card bill'**
  String get reminderKindCard;

  /// No description provided for @reminderKindSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get reminderKindSubscription;

  /// No description provided for @reminderKindInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get reminderKindInsurance;

  /// No description provided for @reminderKindDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get reminderKindDocument;

  /// No description provided for @reminderKindCustom.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reminderKindCustom;

  /// No description provided for @reminderTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reminderTitleLabel;

  /// No description provided for @reminderTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Electricity bill'**
  String get reminderTitleHint;

  /// No description provided for @reminderTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get reminderTitleRequired;

  /// No description provided for @reminderAmountOptional.
  ///
  /// In en, this message translates to:
  /// **'Amount (optional)'**
  String get reminderAmountOptional;

  /// No description provided for @reminderDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get reminderDueDate;

  /// No description provided for @reminderRepeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get reminderRepeatLabel;

  /// No description provided for @reminderRepeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get reminderRepeatOnce;

  /// No description provided for @reminderRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get reminderRepeatWeekly;

  /// No description provided for @reminderRepeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get reminderRepeatMonthly;

  /// No description provided for @reminderRepeatQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Every 3 months'**
  String get reminderRepeatQuarterly;

  /// No description provided for @reminderRepeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get reminderRepeatYearly;

  /// No description provided for @reminderNotifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get reminderNotifyLabel;

  /// No description provided for @reminderNotifyOnDay.
  ///
  /// In en, this message translates to:
  /// **'On the day'**
  String get reminderNotifyOnDay;

  /// No description provided for @reminderNotifyDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day before} other{{days} days before}}'**
  String reminderNotifyDaysBefore(int days);

  /// No description provided for @reminderNotifyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get reminderNotifyEnabled;

  /// No description provided for @reminderNotifyAt.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String reminderNotifyAt(String time);

  /// No description provided for @reminderNotifyPreview.
  ///
  /// In en, this message translates to:
  /// **'First alert: {when}'**
  String reminderNotifyPreview(String when);

  /// No description provided for @reminderNoAlertsLeft.
  ///
  /// In en, this message translates to:
  /// **'All alert times have passed; it will show as due in the app.'**
  String get reminderNoAlertsLeft;

  /// No description provided for @reminderPickDaysError.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day'**
  String get reminderPickDaysError;

  /// No description provided for @reminderSave.
  ///
  /// In en, this message translates to:
  /// **'Save reminder'**
  String get reminderSave;

  /// No description provided for @reminderNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account'**
  String get reminderNoAccount;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Bill & due-date reminders'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Alerts before bills, EMIs, card dues and renewals are due'**
  String get reminderChannelDescription;

  /// No description provided for @reminderMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get reminderMarkPaid;

  /// No description provided for @reminderMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reminderMarkDone;

  /// No description provided for @reminderSnoozeOneDay.
  ///
  /// In en, this message translates to:
  /// **'Snooze 1 day'**
  String get reminderSnoozeOneDay;

  /// No description provided for @reminderDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get reminderDueToday;

  /// No description provided for @reminderDueInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Due tomorrow} other{Due in {days} days}}'**
  String reminderDueInDays(int days);

  /// No description provided for @reminderOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Overdue by 1 day} other{Overdue by {days} days}}'**
  String reminderOverdueDays(int days);

  /// No description provided for @documentRemindersSection.
  ///
  /// In en, this message translates to:
  /// **'Documents & renewals'**
  String get documentRemindersSection;

  /// No description provided for @documentRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'PUC, insurance, passport and other expiry dates'**
  String get documentRemindersHint;

  /// No description provided for @documentPresetVehicleInsurance.
  ///
  /// In en, this message translates to:
  /// **'Vehicle insurance'**
  String get documentPresetVehicleInsurance;

  /// No description provided for @documentPresetPuc.
  ///
  /// In en, this message translates to:
  /// **'PUC certificate'**
  String get documentPresetPuc;

  /// No description provided for @documentPresetRcRenewal.
  ///
  /// In en, this message translates to:
  /// **'RC renewal'**
  String get documentPresetRcRenewal;

  /// No description provided for @documentPresetDrivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get documentPresetDrivingLicence;

  /// No description provided for @documentPresetPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get documentPresetPassport;

  /// No description provided for @documentPresetHealthInsurance.
  ///
  /// In en, this message translates to:
  /// **'Health insurance premium'**
  String get documentPresetHealthInsurance;

  /// No description provided for @documentPresetLifeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Life insurance premium'**
  String get documentPresetLifeInsurance;

  /// No description provided for @documentPresetWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty expiry'**
  String get documentPresetWarranty;

  /// No description provided for @documentPresetAmc.
  ///
  /// In en, this message translates to:
  /// **'AMC renewal'**
  String get documentPresetAmc;

  /// No description provided for @documentPresetFdMaturity.
  ///
  /// In en, this message translates to:
  /// **'FD maturity'**
  String get documentPresetFdMaturity;

  /// No description provided for @documentPresetPropertyTax.
  ///
  /// In en, this message translates to:
  /// **'Property tax'**
  String get documentPresetPropertyTax;

  /// No description provided for @documentPresetRentAgreement.
  ///
  /// In en, this message translates to:
  /// **'Rent agreement renewal'**
  String get documentPresetRentAgreement;

  /// No description provided for @documentNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Document number (optional)'**
  String get documentNumberLabel;

  /// No description provided for @documentNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Policy, registration or certificate number'**
  String get documentNumberHint;

  /// No description provided for @documentRemindersOnProject.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get documentRemindersOnProject;

  /// No description provided for @reminderRepeatHalfYearly.
  ///
  /// In en, this message translates to:
  /// **'Every 6 months'**
  String get reminderRepeatHalfYearly;

  /// No description provided for @reminderRepeatElevenMonths.
  ///
  /// In en, this message translates to:
  /// **'Every 11 months'**
  String get reminderRepeatElevenMonths;

  /// No description provided for @reminderRepeatFiveYears.
  ///
  /// In en, this message translates to:
  /// **'Every 5 years'**
  String get reminderRepeatFiveYears;

  /// No description provided for @reminderRepeatTenYears.
  ///
  /// In en, this message translates to:
  /// **'Every 10 years'**
  String get reminderRepeatTenYears;

  /// No description provided for @documentPucOlderVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Older vehicles (before BS-IV) need PUC every 6 months.'**
  String get documentPucOlderVehicleHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
