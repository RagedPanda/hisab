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

  /// No description provided for @settlementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payment · tap to remove'**
  String get settlementSubtitle;

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
  /// **'Add the first shared expense with the button below.'**
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

  /// No description provided for @suggestedCategoriesAllPresent.
  ///
  /// In en, this message translates to:
  /// **'All suggested categories are already in your list'**
  String get suggestedCategoriesAllPresent;

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
