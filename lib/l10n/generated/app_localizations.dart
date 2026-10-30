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

  /// Header of the collapsible section that hides advanced fields in the entry editor
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get moreDetails;

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

  /// No description provided for @defaultAccount.
  ///
  /// In en, this message translates to:
  /// **'Default account'**
  String get defaultAccount;

  /// No description provided for @defaultAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'New entries start on this account'**
  String get defaultAccountHelp;

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

  /// No description provided for @howMuch.
  ///
  /// In en, this message translates to:
  /// **'How much?'**
  String get howMuch;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @discardEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this entry?'**
  String get discardEntryTitle;

  /// No description provided for @discardEntryBody.
  ///
  /// In en, this message translates to:
  /// **'What you entered will be lost.'**
  String get discardEntryBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @groupExpense.
  ///
  /// In en, this message translates to:
  /// **'Group expense'**
  String get groupExpense;

  /// Group expense editor: the form starts as a copy of the group's latest expense
  ///
  /// In en, this message translates to:
  /// **'Filled in from the last expense'**
  String get copiedFromLastEntry;

  /// No description provided for @startBlank.
  ///
  /// In en, this message translates to:
  /// **'Start blank'**
  String get startBlank;

  /// Entry editor action: copy this saved entry to a new one dated today
  ///
  /// In en, this message translates to:
  /// **'Add again for today'**
  String get entryAgain;

  /// No description provided for @copiedFromEntry.
  ///
  /// In en, this message translates to:
  /// **'A copy dated today. Change anything, then save.'**
  String get copiedFromEntry;

  /// No description provided for @deleteEntryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryQuestion;

  /// No description provided for @splitThis.
  ///
  /// In en, this message translates to:
  /// **'Split this'**
  String get splitThis;

  /// No description provided for @splitThisPickGroup.
  ///
  /// In en, this message translates to:
  /// **'Split with which group?'**
  String get splitThisPickGroup;

  /// No description provided for @splitThisHint.
  ///
  /// In en, this message translates to:
  /// **'Saving moves this entry into the group. Only your share counts as spent.'**
  String get splitThisHint;

  /// No description provided for @splitThisDone.
  ///
  /// In en, this message translates to:
  /// **'Moved to {group}. Only your share counts as spent.'**
  String splitThisDone(String group);

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
  /// **'Added from SMS. Editing it will not change your bank balance.'**
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

  /// Saved spends shown as one-tap chips on Home
  ///
  /// In en, this message translates to:
  /// **'Quick entries'**
  String get quickEntries;

  /// No description provided for @quickEntriesHint.
  ///
  /// In en, this message translates to:
  /// **'One-tap spends on Home'**
  String get quickEntriesHint;

  /// No description provided for @saveAsQuickEntry.
  ///
  /// In en, this message translates to:
  /// **'Save as quick entry'**
  String get saveAsQuickEntry;

  /// No description provided for @saveQuickEntry.
  ///
  /// In en, this message translates to:
  /// **'Save quick entry'**
  String get saveQuickEntry;

  /// No description provided for @newQuickEntry.
  ///
  /// In en, this message translates to:
  /// **'New quick entry'**
  String get newQuickEntry;

  /// No description provided for @editQuickEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit quick entry'**
  String get editQuickEntry;

  /// No description provided for @quickEntryName.
  ///
  /// In en, this message translates to:
  /// **'Name on the chip'**
  String get quickEntryName;

  /// No description provided for @quickEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as a quick entry. Tap it on Home to add it.'**
  String get quickEntrySaved;

  /// No description provided for @quickEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add {label}?'**
  String quickEntryConfirm(String label);

  /// No description provided for @quickEntryAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {label} · {amount}'**
  String quickEntryAdded(String label, String amount);

  /// No description provided for @quickEntriesMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String quickEntriesMore(int count);

  /// No description provided for @quickEntriesShown.
  ///
  /// In en, this message translates to:
  /// **'Shown on Home'**
  String get quickEntriesShown;

  /// No description provided for @quickEntriesShownHint.
  ///
  /// In en, this message translates to:
  /// **'{count} chips; the rest go behind +more'**
  String quickEntriesShownHint(int count);

  /// No description provided for @quickEntriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No quick entries yet. Add one here, or open any entry and tap the bolt to save it as one.'**
  String get quickEntriesEmpty;

  /// No description provided for @quickEntryNoAmount.
  ///
  /// In en, this message translates to:
  /// **'Opens the editor'**
  String get quickEntryNoAmount;

  /// Chip in the entry editor that adds every item of the latest bill in the chosen category
  ///
  /// In en, this message translates to:
  /// **'Same as last time · {count} items'**
  String sameAsLastTime(int count);

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

  /// No description provided for @errorPickAccount.
  ///
  /// In en, this message translates to:
  /// **'Pick an account'**
  String get errorPickAccount;

  /// No description provided for @errorSameAccount.
  ///
  /// In en, this message translates to:
  /// **'From and To must be different accounts'**
  String get errorSameAccount;

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

  /// Joins the per-currency totals in the Groups list summary, e.g. ₹0 · AED 1,400.
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get groupsTotalsSeparator;

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

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedSettings;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @currencyChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your currency'**
  String get currencyChooseTitle;

  /// No description provided for @currencyChooseBody.
  ///
  /// In en, this message translates to:
  /// **'Amounts in Hisab show in this currency. You can change it later in Settings.'**
  String get currencyChooseBody;

  /// No description provided for @currencySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search code, name or country'**
  String get currencySearchHint;

  /// No description provided for @currencyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue with {currency}'**
  String currencyContinue(String currency);

  /// No description provided for @currencyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No currency matches \"{query}\"'**
  String currencyNoMatch(String query);

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

  /// No description provided for @eraseAllData.
  ///
  /// In en, this message translates to:
  /// **'Erase all data'**
  String get eraseAllData;

  /// No description provided for @eraseAllDataHelp.
  ///
  /// In en, this message translates to:
  /// **'Deletes every entry, account, group and setting on this phone'**
  String get eraseAllDataHelp;

  /// No description provided for @eraseAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase everything?'**
  String get eraseAllDataTitle;

  /// No description provided for @eraseAllDataBody.
  ///
  /// In en, this message translates to:
  /// **'This removes all entries, accounts, groups, budgets, reminders and settings from this phone. It can\'t be undone. Backups already on Google Drive are kept.\n\nType {word} to confirm.'**
  String eraseAllDataBody(String word);

  /// No description provided for @eraseConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Type {word}'**
  String eraseConfirmLabel(String word);

  /// No description provided for @eraseAction.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get eraseAction;

  /// No description provided for @dataErased.
  ///
  /// In en, this message translates to:
  /// **'All data erased. Hisab is back to a fresh start.'**
  String get dataErased;

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

  /// Text shown before the red heart icon at the bottom of Settings > About. May be empty.
  ///
  /// In en, this message translates to:
  /// **'Made with'**
  String get aboutMadeWithBefore;

  /// Text shown after the red heart icon at the bottom of Settings > About. May be empty.
  ///
  /// In en, this message translates to:
  /// **''**
  String get aboutMadeWithAfter;

  /// Screen reader label for the Made with heart line.
  ///
  /// In en, this message translates to:
  /// **'Made with love'**
  String get aboutMadeWithLabel;

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

  /// No description provided for @driveBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up to Google Drive'**
  String get driveBackupTitle;

  /// No description provided for @driveBackupWhy.
  ///
  /// In en, this message translates to:
  /// **'Optional. An encrypted copy in your own Drive; Hisab can only see its own files.'**
  String get driveBackupWhy;

  /// No description provided for @driveConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up & sync with Google Drive'**
  String get driveConsentTitle;

  /// No description provided for @driveConsentOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get driveConsentOptional;

  /// No description provided for @driveConsentOffline.
  ///
  /// In en, this message translates to:
  /// **'Hisab works fully offline. Your data stays on this phone and nothing is ever sent anywhere — unless you turn this on.'**
  String get driveConsentOffline;

  /// No description provided for @driveConsentWhat.
  ///
  /// In en, this message translates to:
  /// **'Turn on Drive sync and Hisab keeps an encrypted copy of your data in your own Google Drive, so you can restore everything if you lose or change your phone, and share a group with friends and family.'**
  String get driveConsentWhat;

  /// No description provided for @driveConsentWhyLead.
  ///
  /// In en, this message translates to:
  /// **'Why Hisab asks for Drive access:'**
  String get driveConsentWhyLead;

  /// No description provided for @driveConsentWhy.
  ///
  /// In en, this message translates to:
  /// **'only to read and write its own files in your Drive.'**
  String get driveConsentWhy;

  /// No description provided for @driveConsentCannotSee.
  ///
  /// In en, this message translates to:
  /// **'It cannot see your photos, documents, or anything else in your Drive.'**
  String get driveConsentCannotSee;

  /// No description provided for @driveConsentEncrypted.
  ///
  /// In en, this message translates to:
  /// **'The data is encrypted — Google can\'t read it, and neither can we. There is no Hisab server.'**
  String get driveConsentEncrypted;

  /// No description provided for @driveConsentTurnOff.
  ///
  /// In en, this message translates to:
  /// **'You can turn this off and disconnect any time, and delete the Drive copy with one tap.'**
  String get driveConsentTurnOff;

  /// No description provided for @driveConsentSkip.
  ///
  /// In en, this message translates to:
  /// **'Don\'t want it? Just skip this — Hisab works exactly the same without it.'**
  String get driveConsentSkip;

  /// No description provided for @driveSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get driveSkipForNow;

  /// No description provided for @driveConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive'**
  String get driveConnect;

  /// No description provided for @driveConnectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as {email}'**
  String driveConnectedAs(String email);

  /// No description provided for @driveLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {time}'**
  String driveLastBackup(String time);

  /// No description provided for @driveNoBackupYet.
  ///
  /// In en, this message translates to:
  /// **'No backup in Drive yet'**
  String get driveNoBackupYet;

  /// No description provided for @driveCheckingBackup.
  ///
  /// In en, this message translates to:
  /// **'Checking Google Drive…'**
  String get driveCheckingBackup;

  /// No description provided for @driveBackupStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check Google Drive'**
  String get driveBackupStatusUnknown;

  /// No description provided for @driveBackUpNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get driveBackUpNow;

  /// No description provided for @driveBackUpNowHelp.
  ///
  /// In en, this message translates to:
  /// **'Encrypts everything with your passphrase and replaces the Drive copy'**
  String get driveBackUpNowHelp;

  /// No description provided for @driveRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from Drive'**
  String get driveRestore;

  /// No description provided for @driveDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get driveDisconnect;

  /// No description provided for @driveDisconnectHelp.
  ///
  /// In en, this message translates to:
  /// **'Stops using this Google account; the Drive copy stays until you delete it'**
  String get driveDisconnectHelp;

  /// No description provided for @driveDeleteCopy.
  ///
  /// In en, this message translates to:
  /// **'Delete Drive copy'**
  String get driveDeleteCopy;

  /// No description provided for @driveDeleteCopyHelp.
  ///
  /// In en, this message translates to:
  /// **'Removes Hisab\'s backup from your Google Drive'**
  String get driveDeleteCopyHelp;

  /// No description provided for @driveDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the backup in your Google Drive? Data on this phone is not affected.'**
  String get driveDeleteConfirm;

  /// No description provided for @driveBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Backed up to Google Drive'**
  String get driveBackedUp;

  /// No description provided for @driveCopyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Drive copy deleted'**
  String get driveCopyDeleted;

  /// No description provided for @driveDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from Google Drive'**
  String get driveDisconnected;

  /// No description provided for @driveErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled'**
  String get driveErrorCancelled;

  /// No description provided for @driveErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Google Drive. Check your connection and try again.'**
  String get driveErrorOffline;

  /// No description provided for @driveErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'No Hisab backup found in this Google Drive'**
  String get driveErrorNotFound;

  /// No description provided for @driveErrorWrongPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Wrong passphrase, or the backup is damaged'**
  String get driveErrorWrongPassphrase;

  /// No description provided for @driveErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Google Drive failed: {error}'**
  String driveErrorUnknown(String error);

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

  /// No description provided for @smsForeignCurrency.
  ///
  /// In en, this message translates to:
  /// **'Only SMS in your home currency are supported, so this one was ignored.'**
  String get smsForeignCurrency;

  /// No description provided for @smsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find a transaction in that text.'**
  String get smsNotFound;

  /// No description provided for @smsNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'New bank transaction'**
  String get smsNotificationTitle;

  /// No description provided for @smsNotificationBodyAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} from {sender}. Tap to review.'**
  String smsNotificationBodyAmount(String amount, String sender);

  /// No description provided for @smsNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'From {sender}. Tap to review.'**
  String smsNotificationBody(String sender);

  /// No description provided for @smsNotificationBodyAmountAutoAdd.
  ///
  /// In en, this message translates to:
  /// **'{amount} from {sender}. Open Hisab to add it.'**
  String smsNotificationBodyAmountAutoAdd(String amount, String sender);

  /// No description provided for @smsNotificationBodyAutoAdd.
  ///
  /// In en, this message translates to:
  /// **'From {sender}. Open Hisab to add it.'**
  String smsNotificationBodyAutoAdd(String sender);

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
  /// **'Add clear transactions automatically'**
  String get smsAutoAddTitle;

  /// No description provided for @smsAutoAddHelp.
  ///
  /// In en, this message translates to:
  /// **'On: clear bank SMS are added right away with Undo. Unclear ones wait for review.'**
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

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter an email like name@example.com'**
  String get invalidEmail;

  /// No description provided for @memberContactLocal.
  ///
  /// In en, this message translates to:
  /// **'Email, phone and UPI ID stay on this device. Hisab uses them only to suggest people you added before, and to fill in reminders and UPI payments.'**
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

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, e.g. home, trip'**
  String get tagsHint;

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

  /// No description provided for @filteredTotal.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get filteredTotal;

  /// No description provided for @itemBoughtTimes.
  ///
  /// In en, this message translates to:
  /// **'{quantity} · {count, plural, =1{1 time} other{{count} times}}'**
  String itemBoughtTimes(String quantity, int count);

  /// No description provided for @moreItems.
  ///
  /// In en, this message translates to:
  /// **'+{count} more items'**
  String moreItems(int count);

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

  /// No description provided for @remindersLateNote.
  ///
  /// In en, this message translates to:
  /// **'Reminders may arrive late. Allow Alarms & reminders'**
  String get remindersLateNote;

  /// No description provided for @exactAlarmPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminders on time'**
  String get exactAlarmPromptTitle;

  /// No description provided for @exactAlarmPromptBody.
  ///
  /// In en, this message translates to:
  /// **'To alert you at the exact time you set, Android needs Hisab\'s \"Alarms & reminders\" setting. Without it, reminders may arrive late.'**
  String get exactAlarmPromptBody;

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

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{on} of {total} on'**
  String notificationsSettingsSubtitle(int on, int total);

  /// No description provided for @notificationsIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick what Hisab may notify you about. Each one starts off; turn on only what helps.'**
  String get notificationsIntro;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked for Hisab on this phone.'**
  String get notificationsBlocked;

  /// No description provided for @notificationsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get notificationsAllow;

  /// No description provided for @notificationsShowSample.
  ///
  /// In en, this message translates to:
  /// **'Show sample'**
  String get notificationsShowSample;

  /// No description provided for @notificationsSampleSent.
  ///
  /// In en, this message translates to:
  /// **'Sample sent. Pull down the notification shade to see it.'**
  String get notificationsSampleSent;

  /// No description provided for @notificationsSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample · {title}'**
  String notificationsSampleTitle(String title);

  /// No description provided for @notificationsUpdatesChannel.
  ///
  /// In en, this message translates to:
  /// **'Daily summary and samples'**
  String get notificationsUpdatesChannel;

  /// No description provided for @notificationsUpdatesChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'The evening summary and samples sent from Settings'**
  String get notificationsUpdatesChannelDescription;

  /// No description provided for @notifKindReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifKindReminders;

  /// No description provided for @notifKindRemindersHelp.
  ///
  /// In en, this message translates to:
  /// **'Bills, documents, card dues and group settle-ups you set reminders for'**
  String get notifKindRemindersHelp;

  /// No description provided for @notifKindSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary not seen yet'**
  String get notifKindSalary;

  /// No description provided for @notifKindSalaryHelp.
  ///
  /// In en, this message translates to:
  /// **'When your salary has not arrived by its expected day'**
  String get notifKindSalaryHelp;

  /// No description provided for @notifKindSalaryNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Set up salary first'**
  String get notifKindSalaryNeedsSetup;

  /// No description provided for @notifKindBankSms.
  ///
  /// In en, this message translates to:
  /// **'New bank SMS'**
  String get notifKindBankSms;

  /// No description provided for @notifKindBankSmsHelp.
  ///
  /// In en, this message translates to:
  /// **'A bank transaction SMS arrived while Hisab was closed'**
  String get notifKindBankSmsHelp;

  /// No description provided for @notifKindBankSmsNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Works once Bank SMS is on'**
  String get notifKindBankSmsNeedsSetup;

  /// No description provided for @notifKindEveningSummary.
  ///
  /// In en, this message translates to:
  /// **'Evening summary'**
  String get notifKindEveningSummary;

  /// No description provided for @notifKindEveningSummaryHelp.
  ///
  /// In en, this message translates to:
  /// **'Today\'s spend, SMS to review and bills due in the next 3 days'**
  String get notifKindEveningSummaryHelp;

  /// No description provided for @eveningSummaryTime.
  ///
  /// In en, this message translates to:
  /// **'Summary time'**
  String get eveningSummaryTime;

  /// No description provided for @eveningSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your day in Hisab'**
  String get eveningSummaryTitle;

  /// No description provided for @eveningSummarySpent.
  ///
  /// In en, this message translates to:
  /// **'Spent {amount} today'**
  String eveningSummarySpent(String amount);

  /// No description provided for @eveningSummaryNothingSpent.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent today'**
  String get eveningSummaryNothingSpent;

  /// No description provided for @eveningSummaryReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 SMS to review} other{{count} SMS to review}}'**
  String eveningSummaryReview(int count);

  /// No description provided for @eveningSummaryDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bill due in the next 3 days} other{{count} bills due in the next 3 days}}'**
  String eveningSummaryDue(int count);

  /// No description provided for @notifSampleReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Electricity bill'**
  String get notifSampleReminderTitle;

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

  /// No description provided for @cardStatementDay.
  ///
  /// In en, this message translates to:
  /// **'Statement day'**
  String get cardStatementDay;

  /// No description provided for @cardDueDay.
  ///
  /// In en, this message translates to:
  /// **'Payment due day'**
  String get cardDueDay;

  /// No description provided for @cardDayNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get cardDayNotSet;

  /// No description provided for @cardCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get cardCreditLimit;

  /// No description provided for @cardLastStatementAmount.
  ///
  /// In en, this message translates to:
  /// **'Last statement amount'**
  String get cardLastStatementAmount;

  /// No description provided for @cardDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Statement and due days let Hisab show your billing cycle and remind you before the bill is due.'**
  String get cardDetailsHint;

  /// No description provided for @cardOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get cardOutstanding;

  /// No description provided for @cardThisCycle.
  ///
  /// In en, this message translates to:
  /// **'This cycle'**
  String get cardThisCycle;

  /// No description provided for @cardCycleDates.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String cardCycleDates(String start, String end);

  /// No description provided for @cardLastStatement.
  ///
  /// In en, this message translates to:
  /// **'Last statement'**
  String get cardLastStatement;

  /// No description provided for @cardStatementOn.
  ///
  /// In en, this message translates to:
  /// **'Statement of {date}'**
  String cardStatementOn(String date);

  /// No description provided for @cardNoStatement.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get cardNoStatement;

  /// No description provided for @cardAvailableLimit.
  ///
  /// In en, this message translates to:
  /// **'Available limit'**
  String get cardAvailableLimit;

  /// No description provided for @cardOverLimitBy.
  ///
  /// In en, this message translates to:
  /// **'Over limit by {amount}'**
  String cardOverLimitBy(String amount);

  /// No description provided for @cardLimitUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of {limit} limit used'**
  String cardLimitUsed(int percent, String limit);

  /// No description provided for @cardDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String cardDueOn(String date);

  /// No description provided for @cardPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get cardPaid;

  /// No description provided for @cardAmountLeftToPay.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to pay'**
  String cardAmountLeftToPay(String amount);

  /// No description provided for @cardSetUpDays.
  ///
  /// In en, this message translates to:
  /// **'Set statement and due days'**
  String get cardSetUpDays;

  /// No description provided for @cardViewTransactions.
  ///
  /// In en, this message translates to:
  /// **'View transactions'**
  String get cardViewTransactions;

  /// No description provided for @cardNotFound.
  ///
  /// In en, this message translates to:
  /// **'This card was deleted'**
  String get cardNotFound;

  /// No description provided for @cardNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due {date}'**
  String cardNextDue(String date);

  /// No description provided for @cardInCredit.
  ///
  /// In en, this message translates to:
  /// **'{amount} credit'**
  String cardInCredit(String amount);

  /// No description provided for @cardStatementOverAmountDue.
  ///
  /// In en, this message translates to:
  /// **'More than the amount due ({amount}). Lower it to what is still unpaid.'**
  String cardStatementOverAmountDue(String amount);

  /// No description provided for @cardBalanceOwed.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get cardBalanceOwed;

  /// No description provided for @cardBalanceCredit.
  ///
  /// In en, this message translates to:
  /// **'In credit'**
  String get cardBalanceCredit;

  /// No description provided for @cardCreditOnCard.
  ///
  /// In en, this message translates to:
  /// **'Credit on the card'**
  String get cardCreditOnCard;

  /// No description provided for @balanceInAccount.
  ///
  /// In en, this message translates to:
  /// **'In account'**
  String get balanceInAccount;

  /// No description provided for @balanceOverdrawn.
  ///
  /// In en, this message translates to:
  /// **'Overdrawn'**
  String get balanceOverdrawn;

  /// No description provided for @smsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS history'**
  String get smsHistoryTitle;

  /// No description provided for @smsHistoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Every message Hisab processed and what happened to it'**
  String get smsHistoryHelp;

  /// No description provided for @smsOutcomeAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get smsOutcomeAdded;

  /// No description provided for @smsOutcomeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get smsOutcomeDuplicate;

  /// No description provided for @smsOutcomeIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get smsOutcomeIgnored;

  /// No description provided for @smsOutcomeUnparsed.
  ///
  /// In en, this message translates to:
  /// **'Unreadable'**
  String get smsOutcomeUnparsed;

  /// No description provided for @smsOutcomePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get smsOutcomePending;

  /// No description provided for @smsOutcomeUndone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get smsOutcomeUndone;

  /// No description provided for @smsHistoryNotBank.
  ///
  /// In en, this message translates to:
  /// **'Not a bank message'**
  String get smsHistoryNotBank;

  /// No description provided for @smsHistoryDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed from review'**
  String get smsHistoryDismissed;

  /// No description provided for @smsHistoryUnparsedDetail.
  ///
  /// In en, this message translates to:
  /// **'No transaction found in the text'**
  String get smsHistoryUnparsedDetail;

  /// No description provided for @smsHistoryDuplicateDetail.
  ///
  /// In en, this message translates to:
  /// **'Same message already processed'**
  String get smsHistoryDuplicateDetail;

  /// No description provided for @smsHistoryOpenEntry.
  ///
  /// In en, this message translates to:
  /// **'Open entry'**
  String get smsHistoryOpenEntry;

  /// No description provided for @smsHistoryReprocess.
  ///
  /// In en, this message translates to:
  /// **'Process again'**
  String get smsHistoryReprocess;

  /// No description provided for @smsHistoryClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get smsHistoryClear;

  /// No description provided for @smsHistoryClearQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear SMS history?'**
  String get smsHistoryClearQuestion;

  /// No description provided for @smsHistoryClearBody.
  ///
  /// In en, this message translates to:
  /// **'Removes the text of {count} processed messages from this device. Your entries and messages waiting for review stay, and cleared messages are never imported again.'**
  String smsHistoryClearBody(int count);

  /// No description provided for @smsHistoryClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get smsHistoryClearConfirm;

  /// No description provided for @smsHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'SMS history cleared'**
  String get smsHistoryCleared;

  /// No description provided for @smsHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages processed yet'**
  String get smsHistoryEmptyTitle;

  /// No description provided for @smsHistoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Bank SMS that Hisab reads or that you paste show up here.'**
  String get smsHistoryEmptyBody;

  /// No description provided for @smsHistoryEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No messages with this outcome'**
  String get smsHistoryEmptyFiltered;

  /// No description provided for @smsHistoryTextNotKept.
  ///
  /// In en, this message translates to:
  /// **'Message text not kept'**
  String get smsHistoryTextNotKept;

  /// No description provided for @recurringRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get recurringRepeat;

  /// No description provided for @recurringDoesNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get recurringDoesNotRepeat;

  /// No description provided for @recurringDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurringDaily;

  /// No description provided for @recurringWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurringWeekly;

  /// No description provided for @recurringMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurringMonthly;

  /// No description provided for @recurringYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurringYearly;

  /// No description provided for @recurringEveryDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} other{Every {count} days}}'**
  String recurringEveryDays(int count);

  /// No description provided for @recurringEveryWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every week} other{Every {count} weeks}}'**
  String recurringEveryWeeks(int count);

  /// No description provided for @recurringEveryMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every month} other{Every {count} months}}'**
  String recurringEveryMonths(int count);

  /// No description provided for @recurringEveryYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every year} other{Every {count} years}}'**
  String recurringEveryYears(int count);

  /// No description provided for @recurringOnDay.
  ///
  /// In en, this message translates to:
  /// **'on day {day}'**
  String recurringOnDay(int day);

  /// No description provided for @recurringOnLastDay.
  ///
  /// In en, this message translates to:
  /// **'on the last day'**
  String get recurringOnLastDay;

  /// No description provided for @recurringOnWeekday.
  ///
  /// In en, this message translates to:
  /// **'on {weekday}'**
  String recurringOnWeekday(String weekday);

  /// No description provided for @recurringOnDate.
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String recurringOnDate(String date);

  /// No description provided for @recurringUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String recurringUntil(String date);

  /// No description provided for @recurringTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String recurringTimes(int count);

  /// No description provided for @recurringInterval.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get recurringInterval;

  /// No description provided for @recurringLastDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'On the last day of the month'**
  String get recurringLastDayOfMonth;

  /// No description provided for @recurringEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get recurringEnds;

  /// No description provided for @recurringEndNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get recurringEndNever;

  /// No description provided for @recurringEndOnDate.
  ///
  /// In en, this message translates to:
  /// **'On a date'**
  String get recurringEndOnDate;

  /// No description provided for @recurringEndAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get recurringEndAfter;

  /// No description provided for @recurringOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Number of times'**
  String get recurringOccurrences;

  /// No description provided for @recurringAutoPost.
  ///
  /// In en, this message translates to:
  /// **'Add automatically'**
  String get recurringAutoPost;

  /// No description provided for @recurringAutoPostHint.
  ///
  /// In en, this message translates to:
  /// **'When off, each one waits for you to confirm'**
  String get recurringAutoPostHint;

  /// No description provided for @recurringStopRepeating.
  ///
  /// In en, this message translates to:
  /// **'Don\'t repeat'**
  String get recurringStopRepeating;

  /// No description provided for @recurringDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get recurringDone;

  /// No description provided for @recurringEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Pick an end date on or after the start'**
  String get recurringEndBeforeStart;

  /// No description provided for @recurringPartOfRule.
  ///
  /// In en, this message translates to:
  /// **'Part of a recurring entry'**
  String get recurringPartOfRule;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringTitle;

  /// No description provided for @recurringNew.
  ///
  /// In en, this message translates to:
  /// **'New recurring'**
  String get recurringNew;

  /// No description provided for @recurringEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring'**
  String get recurringEdit;

  /// No description provided for @recurringEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing repeats yet'**
  String get recurringEmptyTitle;

  /// No description provided for @recurringEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Rent, SIP, EMI or salary: set it once and Hisab adds it on the day.'**
  String get recurringEmptyBody;

  /// No description provided for @recurringSectionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get recurringSectionWaiting;

  /// No description provided for @recurringSectionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringSectionActive;

  /// No description provided for @recurringSectionPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringSectionPaused;

  /// No description provided for @recurringSectionEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get recurringSectionEnded;

  /// No description provided for @recurringNext.
  ///
  /// In en, this message translates to:
  /// **'Next {date}'**
  String recurringNext(String date);

  /// No description provided for @recurringDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String recurringDue(String date);

  /// No description provided for @recurringMoreWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more waiting} other{and {count} more waiting}}'**
  String recurringMoreWaiting(int count);

  /// No description provided for @recurringConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get recurringConfirm;

  /// No description provided for @recurringSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get recurringSkip;

  /// No description provided for @recurringPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recurringPause;

  /// No description provided for @recurringResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recurringResume;

  /// No description provided for @recurringDeleted.
  ///
  /// In en, this message translates to:
  /// **'Recurring entry deleted'**
  String get recurringDeleted;

  /// No description provided for @recurringAdded.
  ///
  /// In en, this message translates to:
  /// **'Entry added'**
  String get recurringAdded;

  /// No description provided for @recurringSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get recurringSkipped;

  /// No description provided for @recurringToConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recurring entry to confirm} other{{count} recurring entries to confirm}}'**
  String recurringToConfirm(int count);

  /// No description provided for @recurringPostedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not added yet} =1{Added once} other{Added {count} times}}'**
  String recurringPostedCount(int count);

  /// No description provided for @recurringNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get recurringNameLabel;

  /// No description provided for @recurringNextOn.
  ///
  /// In en, this message translates to:
  /// **'Next on'**
  String get recurringNextOn;

  /// No description provided for @recurringRuleMissing.
  ///
  /// In en, this message translates to:
  /// **'This recurring entry was deleted'**
  String get recurringRuleMissing;

  /// No description provided for @recurringDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease {label}'**
  String recurringDecrease(String label);

  /// No description provided for @recurringIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase {label}'**
  String recurringIncrease(String label);

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @subscriptionsMonthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get subscriptionsMonthlyTotal;

  /// No description provided for @subscriptionsYearlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Per year'**
  String get subscriptionsYearlyTotal;

  /// No description provided for @subscriptionsActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active subscription} other{{count} active subscriptions}}'**
  String subscriptionsActiveCount(int count);

  /// No description provided for @subscriptionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get subscriptionsEmptyTitle;

  /// No description provided for @subscriptionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add Netflix, your phone recharge or the gym to see what they cost you each month and year.'**
  String get subscriptionsEmptyBody;

  /// No description provided for @subscriptionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get subscriptionAdd;

  /// No description provided for @subscriptionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get subscriptionEdit;

  /// No description provided for @subscriptionPickService.
  ///
  /// In en, this message translates to:
  /// **'Pick a service'**
  String get subscriptionPickService;

  /// No description provided for @subscriptionCustom.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get subscriptionCustom;

  /// No description provided for @subscriptionPrice.
  ///
  /// In en, this message translates to:
  /// **'Price per renewal'**
  String get subscriptionPrice;

  /// No description provided for @subscriptionCycle.
  ///
  /// In en, this message translates to:
  /// **'Renews'**
  String get subscriptionCycle;

  /// No description provided for @subscriptionNextRenewal.
  ///
  /// In en, this message translates to:
  /// **'Next renewal'**
  String get subscriptionNextRenewal;

  /// No description provided for @subscriptionStartedOn.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String subscriptionStartedOn(String date);

  /// No description provided for @subscriptionAutoPost.
  ///
  /// In en, this message translates to:
  /// **'Add to expenses on each renewal'**
  String get subscriptionAutoPost;

  /// No description provided for @subscriptionAutoPostHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: tracked here only, no entries are added'**
  String get subscriptionAutoPostHelp;

  /// No description provided for @subscriptionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get subscriptionNameRequired;

  /// No description provided for @subscriptionPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the price'**
  String get subscriptionPriceRequired;

  /// No description provided for @subscriptionRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews {date}'**
  String subscriptionRenewsOn(String date);

  /// No description provided for @subscriptionRenewsToday.
  ///
  /// In en, this message translates to:
  /// **'Renews today'**
  String get subscriptionRenewsToday;

  /// No description provided for @subscriptionRenewsInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Renews tomorrow} other{Renews in {days} days}}'**
  String subscriptionRenewsInDays(int days);

  /// No description provided for @subscriptionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Was due {date}'**
  String subscriptionOverdue(String date);

  /// No description provided for @subscriptionPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get subscriptionPaused;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subscriptionCancelled;

  /// No description provided for @subscriptionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get subscriptionPause;

  /// No description provided for @subscriptionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get subscriptionResume;

  /// No description provided for @subscriptionMarkCancelled.
  ///
  /// In en, this message translates to:
  /// **'Mark as cancelled'**
  String get subscriptionMarkCancelled;

  /// No description provided for @subscriptionCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark {name} as cancelled?'**
  String subscriptionCancelConfirm(String name);

  /// No description provided for @subscriptionCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'No new charges are added and it leaves the totals. Past entries stay.'**
  String get subscriptionCancelConfirmBody;

  /// No description provided for @subscriptionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Subscription deleted'**
  String get subscriptionDeleted;

  /// No description provided for @subscriptionPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount}/month'**
  String subscriptionPerMonth(String amount);

  /// No description provided for @subscriptionSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get subscriptionSort;

  /// No description provided for @subscriptionSortCostHigh.
  ///
  /// In en, this message translates to:
  /// **'Cost: high to low'**
  String get subscriptionSortCostHigh;

  /// No description provided for @subscriptionSortCostLow.
  ///
  /// In en, this message translates to:
  /// **'Cost: low to high'**
  String get subscriptionSortCostLow;

  /// No description provided for @subscriptionSortRenewal.
  ///
  /// In en, this message translates to:
  /// **'Next renewal'**
  String get subscriptionSortRenewal;

  /// No description provided for @subscriptionSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get subscriptionSortName;

  /// No description provided for @subscriptionEveryDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} other{Every {count} days}}'**
  String subscriptionEveryDays(int count);

  /// No description provided for @subscriptionEveryWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every week} other{Every {count} weeks}}'**
  String subscriptionEveryWeeks(int count);

  /// No description provided for @subscriptionEveryMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every month} other{Every {count} months}}'**
  String subscriptionEveryMonths(int count);

  /// No description provided for @subscriptionEveryYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every year} other{Every {count} years}}'**
  String subscriptionEveryYears(int count);

  /// No description provided for @subscriptionTemplateNetflix.
  ///
  /// In en, this message translates to:
  /// **'Netflix'**
  String get subscriptionTemplateNetflix;

  /// No description provided for @subscriptionTemplateAmazonPrime.
  ///
  /// In en, this message translates to:
  /// **'Amazon Prime'**
  String get subscriptionTemplateAmazonPrime;

  /// No description provided for @subscriptionTemplateJiohotstar.
  ///
  /// In en, this message translates to:
  /// **'JioHotstar'**
  String get subscriptionTemplateJiohotstar;

  /// No description provided for @subscriptionTemplateSpotify.
  ///
  /// In en, this message translates to:
  /// **'Spotify'**
  String get subscriptionTemplateSpotify;

  /// No description provided for @subscriptionTemplateYoutubePremium.
  ///
  /// In en, this message translates to:
  /// **'YouTube Premium'**
  String get subscriptionTemplateYoutubePremium;

  /// No description provided for @subscriptionTemplateMobileRecharge.
  ///
  /// In en, this message translates to:
  /// **'Mobile recharge'**
  String get subscriptionTemplateMobileRecharge;

  /// No description provided for @subscriptionTemplateDth.
  ///
  /// In en, this message translates to:
  /// **'DTH'**
  String get subscriptionTemplateDth;

  /// No description provided for @subscriptionTemplateBroadband.
  ///
  /// In en, this message translates to:
  /// **'Broadband'**
  String get subscriptionTemplateBroadband;

  /// No description provided for @subscriptionTemplateGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get subscriptionTemplateGym;

  /// No description provided for @subscriptionTemplateCloudStorage.
  ///
  /// In en, this message translates to:
  /// **'Cloud storage'**
  String get subscriptionTemplateCloudStorage;

  /// No description provided for @subscriptionTemplateNewsApp.
  ///
  /// In en, this message translates to:
  /// **'News app'**
  String get subscriptionTemplateNewsApp;

  /// No description provided for @payersMultiple.
  ///
  /// In en, this message translates to:
  /// **'2+ people'**
  String get payersMultiple;

  /// No description provided for @payersHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter how much each person paid.'**
  String get payersHelp;

  /// No description provided for @payersAssigned.
  ///
  /// In en, this message translates to:
  /// **'{assigned} of {total} assigned'**
  String payersAssigned(String assigned, String total);

  /// No description provided for @payersMustTotal.
  ///
  /// In en, this message translates to:
  /// **'Amounts paid must add up to {total}'**
  String payersMustTotal(String total);

  /// No description provided for @namesAnd.
  ///
  /// In en, this message translates to:
  /// **'{first} and {last}'**
  String namesAnd(String first, String last);

  /// No description provided for @youInList.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get youInList;

  /// No description provided for @groupTotalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group totals'**
  String get groupTotalsTitle;

  /// No description provided for @groupTotalsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get groupTotalsAllTime;

  /// No description provided for @groupTotalsTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Group total'**
  String get groupTotalsTotalSpent;

  /// No description provided for @groupTotalsYouPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get groupTotalsYouPaid;

  /// No description provided for @groupTotalsYourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share'**
  String get groupTotalsYourShare;

  /// No description provided for @groupTotalsNetChange.
  ///
  /// In en, this message translates to:
  /// **'Change in your balance'**
  String get groupTotalsNetChange;

  /// No description provided for @groupTotalsPaymentsMade.
  ///
  /// In en, this message translates to:
  /// **'Payments you made'**
  String get groupTotalsPaymentsMade;

  /// No description provided for @groupTotalsPaymentsReceived.
  ///
  /// In en, this message translates to:
  /// **'Payments you received'**
  String get groupTotalsPaymentsReceived;

  /// No description provided for @groupTotalsByMember.
  ///
  /// In en, this message translates to:
  /// **'Paid and share by member'**
  String get groupTotalsByMember;

  /// No description provided for @groupTotalsPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get groupTotalsPaid;

  /// No description provided for @groupTotalsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get groupTotalsShare;

  /// No description provided for @groupTotalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period'**
  String get groupTotalsEmpty;

  /// No description provided for @groupTotalsExpenseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expense} other{{count} expenses}}'**
  String groupTotalsExpenseCount(int count);

  /// No description provided for @groupTotalsMemberRow.
  ///
  /// In en, this message translates to:
  /// **'{name}: paid {paid}, share {share}'**
  String groupTotalsMemberRow(String name, String paid, String share);

  /// No description provided for @groupTotalsOpen.
  ///
  /// In en, this message translates to:
  /// **'See totals'**
  String get groupTotalsOpen;

  /// No description provided for @groupSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group settings'**
  String get groupSettingsTitle;

  /// No description provided for @groupSettingsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get groupSettingsType;

  /// No description provided for @groupTypeTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get groupTypeTrip;

  /// No description provided for @groupTypeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get groupTypeHome;

  /// No description provided for @groupTypeCouple.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get groupTypeCouple;

  /// No description provided for @groupTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get groupTypeOther;

  /// No description provided for @groupSettingsIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get groupSettingsIcon;

  /// No description provided for @groupSettingsDefaultSplit.
  ///
  /// In en, this message translates to:
  /// **'Default split'**
  String get groupSettingsDefaultSplit;

  /// No description provided for @groupSettingsDefaultSplitHint.
  ///
  /// In en, this message translates to:
  /// **'Pre-selected for new expenses. Expenses already added keep their split.'**
  String get groupSettingsDefaultSplitHint;

  /// No description provided for @groupSettingsWeights.
  ///
  /// In en, this message translates to:
  /// **'Shares per member'**
  String get groupSettingsWeights;

  /// A member's share weight; count is the weight as a number, weight is it formatted (1.5).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 share} other{{weight} shares}}'**
  String groupSettingsWeightValue(num count, String weight);

  /// No description provided for @groupSettingsWeightLess.
  ///
  /// In en, this message translates to:
  /// **'Fewer shares for {name}'**
  String groupSettingsWeightLess(String name);

  /// No description provided for @groupSettingsWeightMore.
  ///
  /// In en, this message translates to:
  /// **'More shares for {name}'**
  String groupSettingsWeightMore(String name);

  /// No description provided for @groupSettingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency label'**
  String get groupSettingsCurrency;

  /// No description provided for @groupSettingsCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Only changes the symbol shown in this group. Amounts are not converted.'**
  String get groupSettingsCurrencyHint;

  /// No description provided for @groupSettingsCurrencyAppDefault.
  ///
  /// In en, this message translates to:
  /// **'Same as app ({symbol})'**
  String groupSettingsCurrencyAppDefault(String symbol);

  /// No description provided for @groupSettingsCurrencyOther.
  ///
  /// In en, this message translates to:
  /// **'Other symbol'**
  String get groupSettingsCurrencyOther;

  /// No description provided for @groupSettingsSimplify.
  ///
  /// In en, this message translates to:
  /// **'Simplify debts'**
  String get groupSettingsSimplify;

  /// No description provided for @groupSettingsSimplifyBody.
  ///
  /// In en, this message translates to:
  /// **'Combines debts so the group needs fewer repayments. If Asha owes Ravi and Ravi owes Meena, Asha can pay Meena directly. Nobody pays or gets back a different total.'**
  String get groupSettingsSimplifyBody;

  /// No description provided for @groupSettingsSimplifySaves.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saves 1 repayment right now} other{Saves {count} repayments right now}}'**
  String groupSettingsSimplifySaves(int count);

  /// No description provided for @groupSettingsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get groupSettingsNotes;

  /// No description provided for @groupSettingsNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi password, house rules, trip plan'**
  String get groupSettingsNotesHint;

  /// No description provided for @groupSettingsNotesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a note for this group'**
  String get groupSettingsNotesAdd;

  /// No description provided for @groupSettingsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage group'**
  String get groupSettingsManage;

  /// No description provided for @groupArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive group'**
  String get groupArchive;

  /// No description provided for @groupArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String groupArchiveTitle(String name);

  /// No description provided for @groupArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'The group moves to Archived on the groups list. Nothing is deleted, and you can unarchive it any time.'**
  String get groupArchiveBody;

  /// No description provided for @groupArchiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get groupArchiveConfirm;

  /// No description provided for @groupUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get groupUnarchive;

  /// No description provided for @groupArchivedBanner.
  ///
  /// In en, this message translates to:
  /// **'This group is archived. Unarchive it to add expenses.'**
  String get groupArchivedBanner;

  /// No description provided for @groupLeftBanner.
  ///
  /// In en, this message translates to:
  /// **'You left this group. Its history stays here.'**
  String get groupLeftBanner;

  /// No description provided for @groupArchivedSection.
  ///
  /// In en, this message translates to:
  /// **'Archived ({count})'**
  String groupArchivedSection(int count);

  /// No description provided for @groupLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get groupLeave;

  /// No description provided for @groupLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String groupLeaveTitle(String name);

  /// No description provided for @groupLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You are removed from the group on this phone and it moves to Archived, so its history stays readable.'**
  String get groupLeaveBody;

  /// No description provided for @groupLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get groupLeaveConfirm;

  /// No description provided for @groupLeaveBlocked.
  ///
  /// In en, this message translates to:
  /// **'Settle up first. You can leave once nobody owes you and you owe nobody.'**
  String get groupLeaveBlocked;

  /// No description provided for @groupDeleteUnsettledBody.
  ///
  /// In en, this message translates to:
  /// **'This group still has unsettled balances. Deleting it removes every expense and payment, and it cannot be undone.'**
  String get groupDeleteUnsettledBody;

  /// No description provided for @groupEmptyTrip.
  ///
  /// In en, this message translates to:
  /// **'Add tickets, stays and meals as you go; Hisab works out who owes whom.'**
  String get groupEmptyTrip;

  /// No description provided for @groupEmptyHome.
  ///
  /// In en, this message translates to:
  /// **'Add rent, bills and groceries; Hisab works out who owes whom.'**
  String get groupEmptyHome;

  /// No description provided for @groupEmptyCouple.
  ///
  /// In en, this message translates to:
  /// **'Add the dinners, groceries and trips you share; Hisab keeps the balance.'**
  String get groupEmptyCouple;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get activityEmptyTitle;

  /// No description provided for @activityEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Expenses and payments you add, edit or delete show up here.'**
  String get activityEmptyBody;

  /// No description provided for @activityExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'{actor} added “{title}”'**
  String activityExpenseAdded(String actor, String title);

  /// No description provided for @activityExpenseEdited.
  ///
  /// In en, this message translates to:
  /// **'{actor} edited “{title}”'**
  String activityExpenseEdited(String actor, String title);

  /// No description provided for @activityExpenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'{actor} deleted “{title}”'**
  String activityExpenseDeleted(String actor, String title);

  /// No description provided for @activityExpenseRestored.
  ///
  /// In en, this message translates to:
  /// **'{actor} restored “{title}”'**
  String activityExpenseRestored(String actor, String title);

  /// No description provided for @activityPaymentAdded.
  ///
  /// In en, this message translates to:
  /// **'{actor} recorded a payment'**
  String activityPaymentAdded(String actor);

  /// No description provided for @activityPaymentEdited.
  ///
  /// In en, this message translates to:
  /// **'{actor} edited a payment'**
  String activityPaymentEdited(String actor);

  /// No description provided for @activityPaymentDeleted.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed a payment'**
  String activityPaymentDeleted(String actor);

  /// No description provided for @activityPaymentRestored.
  ///
  /// In en, this message translates to:
  /// **'{actor} restored a payment'**
  String activityPaymentRestored(String actor);

  /// No description provided for @activityExpenseLine.
  ///
  /// In en, this message translates to:
  /// **'{amount} · paid by {payers}'**
  String activityExpenseLine(String amount, String payers);

  /// No description provided for @activityPaymentLine.
  ///
  /// In en, this message translates to:
  /// **'{from} paid {to} {amount}'**
  String activityPaymentLine(String from, String to, String amount);

  /// No description provided for @activityChangeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount: {from} → {to}'**
  String activityChangeAmount(String from, String to);

  /// No description provided for @activityChangeDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {from} → {to}'**
  String activityChangeDate(String from, String to);

  /// No description provided for @activityChangeDescription.
  ///
  /// In en, this message translates to:
  /// **'Description: {from} → {to}'**
  String activityChangeDescription(String from, String to);

  /// No description provided for @activityChangeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category: {from} → {to}'**
  String activityChangeCategory(String from, String to);

  /// No description provided for @activityChangePayers.
  ///
  /// In en, this message translates to:
  /// **'Paid by: {from} → {to}'**
  String activityChangePayers(String from, String to);

  /// One payer and what they paid, in a list of several payers.
  ///
  /// In en, this message translates to:
  /// **'{name} {amount}'**
  String activityPayerAmount(String name, String amount);

  /// No description provided for @activityChangeShare.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s share: {from} → {to}'**
  String activityChangeShare(String name, String from, String to);

  /// No description provided for @activityChangeMyShare.
  ///
  /// In en, this message translates to:
  /// **'Your share: {from} → {to}'**
  String activityChangeMyShare(String from, String to);

  /// No description provided for @activityChangeParties.
  ///
  /// In en, this message translates to:
  /// **'Who paid whom: {from} → {to}'**
  String activityChangeParties(String from, String to);

  /// No description provided for @activityPartiesPair.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String activityPartiesPair(String from, String to);

  /// No description provided for @activityChangeMethod.
  ///
  /// In en, this message translates to:
  /// **'Method: {from} → {to}'**
  String activityChangeMethod(String from, String to);

  /// No description provided for @activityChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {from} → {to}'**
  String activityChangeNote(String from, String to);

  /// No description provided for @activityNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get activityNone;

  /// No description provided for @activityRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get activityRestore;

  /// No description provided for @activityExpenseRestoredSnack.
  ///
  /// In en, this message translates to:
  /// **'Expense restored'**
  String get activityExpenseRestoredSnack;

  /// No description provided for @activityExpenseDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get activityExpenseDeletedSnack;

  /// No description provided for @activityAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get activityAllGroups;

  /// No description provided for @activityGroupDeleted.
  ///
  /// In en, this message translates to:
  /// **'{actor} deleted the group “{name}”'**
  String activityGroupDeleted(String actor, String name);

  /// No description provided for @activityGroupRestored.
  ///
  /// In en, this message translates to:
  /// **'{actor} restored the group “{name}”'**
  String activityGroupRestored(String actor, String name);

  /// No description provided for @activityGroupEdited.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the group “{name}”'**
  String activityGroupEdited(String actor, String name);

  /// No description provided for @activityGroupLine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No expenses} =1{1 expense} other{{count} expenses}}'**
  String activityGroupLine(int count);

  /// No description provided for @activityPaymentRestoredSnack.
  ///
  /// In en, this message translates to:
  /// **'Payment restored'**
  String get activityPaymentRestoredSnack;

  /// No description provided for @activityGroupRestoredSnack.
  ///
  /// In en, this message translates to:
  /// **'Group restored'**
  String get activityGroupRestoredSnack;

  /// No description provided for @activityGroupDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Group deleted'**
  String get activityGroupDeletedSnack;

  /// No description provided for @recurringAddedSkipped.
  ///
  /// In en, this message translates to:
  /// **'{added, plural, =0{None added} =1{1 added} other{{added} added}}, {skipped, plural, =1{1 skipped} other{{skipped} skipped}}'**
  String recurringAddedSkipped(int added, int skipped);

  /// No description provided for @groupExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get groupExportCsv;

  /// No description provided for @groupExportCsvSubject.
  ///
  /// In en, this message translates to:
  /// **'{group} expenses'**
  String groupExportCsvSubject(String group);

  /// No description provided for @groupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export the CSV'**
  String get groupExportFailed;

  /// No description provided for @groupCsvDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get groupCsvDate;

  /// No description provided for @groupCsvDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupCsvDescription;

  /// No description provided for @groupCsvCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get groupCsvCost;

  /// No description provided for @groupCsvPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get groupCsvPaidBy;

  /// No description provided for @groupCsvPaidColumn.
  ///
  /// In en, this message translates to:
  /// **'{name} paid'**
  String groupCsvPaidColumn(String name);

  /// No description provided for @groupCsvShareColumn.
  ///
  /// In en, this message translates to:
  /// **'{name} share'**
  String groupCsvShareColumn(String name);

  /// No description provided for @groupCsvBalanceColumn.
  ///
  /// In en, this message translates to:
  /// **'{name} balance'**
  String groupCsvBalanceColumn(String name);

  /// No description provided for @groupCsvPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get groupCsvPayment;

  /// No description provided for @groupSummaryWhoPaysWhom.
  ///
  /// In en, this message translates to:
  /// **'Who pays whom'**
  String get groupSummaryWhoPaysWhom;

  /// No description provided for @groupSummaryStandings.
  ///
  /// In en, this message translates to:
  /// **'Where everyone stands'**
  String get groupSummaryStandings;

  /// No description provided for @groupSummaryYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {name} {amount}'**
  String groupSummaryYouOwe(String name, String amount);

  /// No description provided for @groupSummaryOwesYou.
  ///
  /// In en, this message translates to:
  /// **'{name} owes you {amount}'**
  String groupSummaryOwesYou(String name, String amount);

  /// No description provided for @groupSummaryGetsBack.
  ///
  /// In en, this message translates to:
  /// **'{name} gets back {amount}'**
  String groupSummaryGetsBack(String name, String amount);

  /// No description provided for @groupSummaryOwesInTotal.
  ///
  /// In en, this message translates to:
  /// **'{name} owes {amount} in total'**
  String groupSummaryOwesInTotal(String name, String amount);

  /// No description provided for @groupSummaryYouGetBack.
  ///
  /// In en, this message translates to:
  /// **'You get back {amount}'**
  String groupSummaryYouGetBack(String amount);

  /// No description provided for @groupSummaryYouOweInTotal.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount} in total'**
  String groupSummaryYouOweInTotal(String amount);

  /// No description provided for @groupCsvTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get groupCsvTotal;

  /// No description provided for @groupSummaryGroupTotal.
  ///
  /// In en, this message translates to:
  /// **'Group total: {amount}'**
  String groupSummaryGroupTotal(String amount);

  /// No description provided for @groupSummaryYourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share: {amount}'**
  String groupSummaryYourShare(String amount);

  /// No description provided for @groupSummaryMemberShare.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s share: {amount}'**
  String groupSummaryMemberShare(String name, String amount);

  /// No description provided for @byItemShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get byItemShared;

  /// No description provided for @byItemSharedHelp.
  ///
  /// In en, this message translates to:
  /// **'Split among everyone with an item'**
  String get byItemSharedHelp;

  /// No description provided for @byItemOnlyMe.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get byItemOnlyMe;

  /// No description provided for @byItemEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get byItemEveryone;

  /// No description provided for @byItemAddExtras.
  ///
  /// In en, this message translates to:
  /// **'Delivery, tax or tip'**
  String get byItemAddExtras;

  /// No description provided for @byItemHint.
  ///
  /// In en, this message translates to:
  /// **'Add items to split by item'**
  String get byItemHint;

  /// No description provided for @byItemSummary.
  ///
  /// In en, this message translates to:
  /// **'{amount} · {count, plural, =1{1 item} other{{count} items}} · {percent}%'**
  String byItemSummary(String amount, int count, int percent);

  /// No description provided for @byItemClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Item assignments will be cleared'**
  String get byItemClearTitle;

  /// No description provided for @byItemClearBody.
  ///
  /// In en, this message translates to:
  /// **'Items stay, and everyone shares each one again.'**
  String get byItemClearBody;

  /// No description provided for @smsAddedMarker.
  ///
  /// In en, this message translates to:
  /// **'Added from SMS'**
  String get smsAddedMarker;

  /// No description provided for @smsAutoAddedOne.
  ///
  /// In en, this message translates to:
  /// **'Added {amount} from SMS'**
  String smsAutoAddedOne(String amount);

  /// No description provided for @smsAutoAddedMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 entry from SMS} other{Added {count} entries from SMS}}'**
  String smsAutoAddedMany(int count);

  /// No description provided for @smsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS to review'**
  String get smsReviewTitle;

  /// No description provided for @smsReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'These messages were not clear enough to add on their own. Add, edit or ignore each one.'**
  String get smsReviewHelp;

  /// No description provided for @smsReviewUnread.
  ///
  /// In en, this message translates to:
  /// **'Could not read the amount'**
  String get smsReviewUnread;

  /// No description provided for @smsReviewAddManually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get smsReviewAddManually;

  /// No description provided for @upcomingWindowDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String upcomingWindowDays(int days);

  /// No description provided for @upcomingOverdueBy.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Overdue by 1 day} other{Overdue by {days} days}}'**
  String upcomingOverdueBy(int days);

  /// No description provided for @upcomingDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get upcomingDueToday;

  /// No description provided for @upcomingDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get upcomingDueTomorrow;

  /// No description provided for @upcomingDueInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days · {date}'**
  String upcomingDueInDays(int days, String date);

  /// No description provided for @upcomingOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String upcomingOverdueCount(int count);

  /// No description provided for @upcomingDueTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} to pay'**
  String upcomingDueTotal(String amount);

  /// No description provided for @upcomingShowAll.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more} other{{count} more}}'**
  String upcomingShowAll(int count);

  /// No description provided for @upcomingCalendar.
  ///
  /// In en, this message translates to:
  /// **'Due calendar'**
  String get upcomingCalendar;

  /// No description provided for @upcomingCalendarOpen.
  ///
  /// In en, this message translates to:
  /// **'Open due calendar'**
  String get upcomingCalendarOpen;

  /// No description provided for @upcomingCalendarDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing due on this day'**
  String get upcomingCalendarDayEmpty;

  /// No description provided for @upcomingCalendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get upcomingCalendarPreviousMonth;

  /// No description provided for @upcomingCalendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get upcomingCalendarNextMonth;

  /// No description provided for @spendingCalendar.
  ///
  /// In en, this message translates to:
  /// **'Spending calendar'**
  String get spendingCalendar;

  /// No description provided for @spendingCalendarOpen.
  ///
  /// In en, this message translates to:
  /// **'Open spending calendar'**
  String get spendingCalendarOpen;

  /// No description provided for @spendingCalendarDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent on this day'**
  String get spendingCalendarDayEmpty;

  /// No description provided for @spendingCalendarSpent.
  ///
  /// In en, this message translates to:
  /// **'{amount} spent'**
  String spendingCalendarSpent(String amount);

  /// No description provided for @upcomingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get upcomingConfirm;

  /// No description provided for @upcomingConfirmPrompt.
  ///
  /// In en, this message translates to:
  /// **'This is waiting for you to confirm. Add it to your entries now?'**
  String get upcomingConfirmPrompt;

  /// No description provided for @upcomingCalendarDueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 due} other{{count} due}}'**
  String upcomingCalendarDueCount(int count);

  /// No description provided for @salaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salaryTitle;

  /// No description provided for @salarySetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up salary day'**
  String get salarySetUp;

  /// No description provided for @salaryIntro.
  ///
  /// In en, this message translates to:
  /// **'Hisab adds your salary as a monthly income you confirm, and gently reminds you if it has not arrived.'**
  String get salaryIntro;

  /// No description provided for @salarySummary.
  ///
  /// In en, this message translates to:
  /// **'{amount} on day {day}'**
  String salarySummary(String amount, int day);

  /// No description provided for @salaryAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly salary'**
  String get salaryAmount;

  /// No description provided for @salaryAccount.
  ///
  /// In en, this message translates to:
  /// **'Credited to'**
  String get salaryAccount;

  /// No description provided for @salaryAnyAccount.
  ///
  /// In en, this message translates to:
  /// **'Any account'**
  String get salaryAnyAccount;

  /// No description provided for @salaryDay.
  ///
  /// In en, this message translates to:
  /// **'Salary day'**
  String get salaryDay;

  /// No description provided for @salaryShiftLabel.
  ///
  /// In en, this message translates to:
  /// **'On a weekend or holiday'**
  String get salaryShiftLabel;

  /// No description provided for @salaryShiftSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same day'**
  String get salaryShiftSameDay;

  /// No description provided for @salaryShiftPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous working day'**
  String get salaryShiftPrevious;

  /// No description provided for @salaryShiftNext.
  ///
  /// In en, this message translates to:
  /// **'Next working day'**
  String get salaryShiftNext;

  /// No description provided for @salaryHolidays.
  ///
  /// In en, this message translates to:
  /// **'Bank holidays'**
  String get salaryHolidays;

  /// No description provided for @salaryHolidaysHelp.
  ///
  /// In en, this message translates to:
  /// **'Skipped like weekends when the salary day moves'**
  String get salaryHolidaysHelp;

  /// No description provided for @salaryAddHoliday.
  ///
  /// In en, this message translates to:
  /// **'Add holiday'**
  String get salaryAddHoliday;

  /// No description provided for @salaryReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me if it has not arrived'**
  String get salaryReminder;

  /// No description provided for @salaryReminderDelay.
  ///
  /// In en, this message translates to:
  /// **'Remind after'**
  String get salaryReminderDelay;

  /// No description provided for @salaryDaysAfter.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day after} other{{days} days after}}'**
  String salaryDaysAfter(int days);

  /// No description provided for @salaryAligned.
  ///
  /// In en, this message translates to:
  /// **'Your month already starts on payday'**
  String get salaryAligned;

  /// No description provided for @salaryNotAligned.
  ///
  /// In en, this message translates to:
  /// **'Your month starts on day {monthStart}, salary arrives on day {salaryDay}'**
  String salaryNotAligned(int monthStart, int salaryDay);

  /// No description provided for @salaryAlignTitle.
  ///
  /// In en, this message translates to:
  /// **'Start months on day {day}?'**
  String salaryAlignTitle(int day);

  /// No description provided for @salaryAlignMessage.
  ///
  /// In en, this message translates to:
  /// **'Budgets and monthly totals will run from one salary to the next.'**
  String get salaryAlignMessage;

  /// No description provided for @salaryAlignAction.
  ///
  /// In en, this message translates to:
  /// **'Align'**
  String get salaryAlignAction;

  /// No description provided for @salaryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove salary'**
  String get salaryRemove;

  /// No description provided for @salaryRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The Salary rule will be deleted. Salary entries you already have are kept.'**
  String get salaryRemoveBody;

  /// No description provided for @salaryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Salary removed'**
  String get salaryRemoved;

  /// No description provided for @salarySaved.
  ///
  /// In en, this message translates to:
  /// **'Salary saved'**
  String get salarySaved;

  /// No description provided for @salaryExpectedOn.
  ///
  /// In en, this message translates to:
  /// **'Expected {date}'**
  String salaryExpectedOn(String date);

  /// No description provided for @salaryReceivedAmount.
  ///
  /// In en, this message translates to:
  /// **'Received {amount} on {date}'**
  String salaryReceivedAmount(String date, String amount);

  /// No description provided for @salaryLateSince.
  ///
  /// In en, this message translates to:
  /// **'Late: expected {date}'**
  String salaryLateSince(String date);

  /// No description provided for @salaryLastReceived.
  ///
  /// In en, this message translates to:
  /// **'Last received {amount} on {date}'**
  String salaryLastReceived(String date, String amount);

  /// No description provided for @salaryNextExpected.
  ///
  /// In en, this message translates to:
  /// **'Next expected {date}'**
  String salaryNextExpected(String date);

  /// No description provided for @salaryNotSeenTitle.
  ///
  /// In en, this message translates to:
  /// **'Salary not seen yet'**
  String get salaryNotSeenTitle;

  /// No description provided for @salaryNotSeenBody.
  ///
  /// In en, this message translates to:
  /// **'It was expected on {date}. This clears by itself once it arrives.'**
  String salaryNotSeenBody(String date);

  /// No description provided for @salaryRuleName.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salaryRuleName;

  /// No description provided for @salaryMatchWindow.
  ///
  /// In en, this message translates to:
  /// **'Can arrive early by'**
  String get salaryMatchWindow;

  /// No description provided for @salaryMatchWindowDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Up to 1 day} other{Up to {days} days}}'**
  String salaryMatchWindowDays(int days);

  /// No description provided for @salaryTolerance.
  ///
  /// In en, this message translates to:
  /// **'Amount can differ by'**
  String get salaryTolerance;

  /// No description provided for @salaryTolerancePercent.
  ///
  /// In en, this message translates to:
  /// **'Up to {percent}%'**
  String salaryTolerancePercent(int percent);

  /// No description provided for @salaryToleranceExact.
  ///
  /// In en, this message translates to:
  /// **'Exact amount only'**
  String get salaryToleranceExact;

  /// No description provided for @salaryDetectionHelp.
  ///
  /// In en, this message translates to:
  /// **'An income counts as salary when it is this close to the amount and arrives no earlier than this, or any day later in the cycle.'**
  String get salaryDetectionHelp;

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

  /// No description provided for @settleReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle up: {group}'**
  String settleReminderTitle(String group);

  /// No description provided for @settleReminderOwesYou.
  ///
  /// In en, this message translates to:
  /// **'{name} owes you {amount}'**
  String settleReminderOwesYou(String name, String amount);

  /// No description provided for @settleReminderYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {name} {amount}'**
  String settleReminderYouOwe(String name, String amount);

  /// No description provided for @settleReminderPeopleOweYou.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person owes you {amount}} other{{count} people owe you {amount}}}'**
  String settleReminderPeopleOweYou(int count, String amount);

  /// No description provided for @settleReminderYouOweTotal.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount} in all'**
  String settleReminderYouOweTotal(String amount);

  /// No description provided for @settleReminderSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me to settle up'**
  String get settleReminderSheetTitle;

  /// No description provided for @settleReminderWith.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settleReminderWith;

  /// No description provided for @settleReminderEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get settleReminderEveryone;

  /// No description provided for @settleReminderHowOften.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get settleReminderHowOften;

  /// No description provided for @settleReminderMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get settleReminderMonthly;

  /// No description provided for @settleReminderWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get settleReminderWeekly;

  /// No description provided for @settleReminderOnDay.
  ///
  /// In en, this message translates to:
  /// **'On day'**
  String get settleReminderOnDay;

  /// No description provided for @settleReminderLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get settleReminderLastDay;

  /// No description provided for @settleReminderNextAt.
  ///
  /// In en, this message translates to:
  /// **'Next reminder: {date}'**
  String settleReminderNextAt(String date);

  /// No description provided for @settleReminderTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get settleReminderTurnOff;

  /// No description provided for @settleReminderOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Settle-up reminder off'**
  String get settleReminderOffLabel;

  /// No description provided for @settleReminderMonthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Reminder on day {day} every month'**
  String settleReminderMonthlySummary(String day);

  /// No description provided for @settleReminderWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Reminder every {weekday}'**
  String settleReminderWeeklySummary(String weekday);

  /// No description provided for @settleReminderMonthlyLastDaySummary.
  ///
  /// In en, this message translates to:
  /// **'Reminder on the last day of every month'**
  String get settleReminderMonthlyLastDaySummary;

  /// No description provided for @groupRecurringAmountFixed.
  ///
  /// In en, this message translates to:
  /// **'This split uses fixed amounts, so the total can\'t change here'**
  String get groupRecurringAmountFixed;

  /// No description provided for @groupRecurringUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Repeating'**
  String get groupRecurringUpcoming;

  /// No description provided for @settleReminderShareNudge.
  ///
  /// In en, this message translates to:
  /// **'Share a nudge'**
  String get settleReminderShareNudge;

  /// No description provided for @groupRecurringExpenseOnly.
  ///
  /// In en, this message translates to:
  /// **'A group repeating rule can only be an expense.'**
  String get groupRecurringExpenseOnly;

  /// No description provided for @groupRecurringYourShare.
  ///
  /// In en, this message translates to:
  /// **'your share {amount}'**
  String groupRecurringYourShare(String amount);

  /// No description provided for @settleReminderPrePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to settle up'**
  String get settleReminderPrePromptTitle;

  /// No description provided for @settleReminderPrePromptBody.
  ///
  /// In en, this message translates to:
  /// **'Hisab sends a notification on the day you choose, only to remind you to settle up with this group. No marketing.'**
  String get settleReminderPrePromptBody;

  /// Label on a reminder that a matching bank SMS marked done
  ///
  /// In en, this message translates to:
  /// **'Paid via SMS'**
  String get smsReminderPaidViaSms;

  /// No description provided for @heroToday.
  ///
  /// In en, this message translates to:
  /// **'Today {amount}'**
  String heroToday(String amount);

  /// No description provided for @heroTodaySemantics.
  ///
  /// In en, this message translates to:
  /// **'Spent today {amount}. Show today\'s entries'**
  String heroTodaySemantics(String amount);

  /// No description provided for @numberFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Number format'**
  String get numberFormatTitle;

  /// No description provided for @numberFormatAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get numberFormatAutomatic;

  /// No description provided for @numberFormatAutomaticHelp.
  ///
  /// In en, this message translates to:
  /// **'Follows your currency and region'**
  String get numberFormatAutomaticHelp;

  /// No description provided for @smsPayeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Remembered payees'**
  String get smsPayeesTitle;

  /// No description provided for @smsPayeesHelp.
  ///
  /// In en, this message translates to:
  /// **'Categories you chose for a payee, used for their next SMS'**
  String get smsPayeesHelp;

  /// No description provided for @smsPayeesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No payees remembered yet'**
  String get smsPayeesEmptyTitle;

  /// No description provided for @smsPayeesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Change the category of an entry added from an SMS and Hisab uses it for that payee\'s next messages.'**
  String get smsPayeesEmptyBody;

  /// No description provided for @smsPayeeForget.
  ///
  /// In en, this message translates to:
  /// **'Forget {payee}'**
  String smsPayeeForget(String payee);

  /// No description provided for @smsPayeeForgotten.
  ///
  /// In en, this message translates to:
  /// **'{payee} forgotten'**
  String smsPayeeForgotten(String payee);

  /// No description provided for @smsPayeeAskTitle.
  ///
  /// In en, this message translates to:
  /// **'New person. Pick a category once for {payee}'**
  String smsPayeeAskTitle(String payee);

  /// No description provided for @smsPayeePickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick category'**
  String get smsPayeePickCategory;

  /// No description provided for @smsPayeeRemembered.
  ///
  /// In en, this message translates to:
  /// **'Hisab will use {category} for {payee} from now on'**
  String smsPayeeRemembered(String category, String payee);

  /// No description provided for @safeToSpendPerDay.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend {amount}/day'**
  String safeToSpendPerDay(String amount);

  /// No description provided for @safeToSpendOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get safeToSpendOverBudget;

  /// No description provided for @smsEntryChannelName.
  ///
  /// In en, this message translates to:
  /// **'Added from SMS'**
  String get smsEntryChannelName;

  /// No description provided for @smsEntryChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Entries Hisab added from bank SMS, with Change category and Undo'**
  String get smsEntryChannelDescription;

  /// No description provided for @smsEntryChangeCategory.
  ///
  /// In en, this message translates to:
  /// **'Change category'**
  String get smsEntryChangeCategory;

  /// No description provided for @smsEntryNewPayeeHint.
  ///
  /// In en, this message translates to:
  /// **'New payee: pick a category'**
  String get smsEntryNewPayeeHint;

  /// No description provided for @smsEntryGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'This entry no longer exists'**
  String get smsEntryGoneTitle;

  /// No description provided for @smsEntryGoneBody.
  ///
  /// In en, this message translates to:
  /// **'It was undone or deleted.'**
  String get smsEntryGoneBody;

  /// No description provided for @smsEntryCategoryChanged.
  ///
  /// In en, this message translates to:
  /// **'Category changed to {category}'**
  String smsEntryCategoryChanged(String category);

  /// No description provided for @shortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts & widget'**
  String get shortcutsTitle;

  /// No description provided for @shortcutsHint.
  ///
  /// In en, this message translates to:
  /// **'Add an expense from the notification shade, Quick Settings or Home screen'**
  String get shortcutsHint;

  /// No description provided for @launcherShortcutsHelp.
  ///
  /// In en, this message translates to:
  /// **'Long-press the Hisab icon for Add expense, Add income and your first two quick entries.'**
  String get launcherShortcutsHelp;

  /// No description provided for @addExpenseNotification.
  ///
  /// In en, this message translates to:
  /// **'Add expense notification'**
  String get addExpenseNotification;

  /// No description provided for @addExpenseNotificationHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps an Add expense shortcut in the notification shade'**
  String get addExpenseNotificationHint;

  /// No description provided for @addExpenseNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Add expense shortcut'**
  String get addExpenseNotificationChannel;

  /// No description provided for @addExpenseNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to log a spend'**
  String get addExpenseNotificationBody;

  /// No description provided for @addExpenseNotificationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for Hisab to show the shortcut'**
  String get addExpenseNotificationBlocked;

  /// No description provided for @quickSettingsTile.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings tile'**
  String get quickSettingsTile;

  /// No description provided for @quickSettingsTileHint.
  ///
  /// In en, this message translates to:
  /// **'Add expense from the panel you swipe down'**
  String get quickSettingsTileHint;

  /// No description provided for @quickSettingsTileManual.
  ///
  /// In en, this message translates to:
  /// **'Swipe down twice from the top of the screen, tap the pencil to edit, then drag Hisab\'s Add expense tile into place.'**
  String get quickSettingsTileManual;

  /// No description provided for @homeScreenWidget.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get homeScreenWidget;

  /// No description provided for @homeScreenWidgetHint.
  ///
  /// In en, this message translates to:
  /// **'This month\'s spend vs last month, with + to add'**
  String get homeScreenWidgetHint;

  /// No description provided for @homeScreenWidgetManual.
  ///
  /// In en, this message translates to:
  /// **'Long-press an empty spot on your Home screen, tap Widgets and pick Hisab.'**
  String get homeScreenWidgetManual;

  /// No description provided for @widgetBackground.
  ///
  /// In en, this message translates to:
  /// **'Widget background'**
  String get widgetBackground;

  /// No description provided for @widgetBackgroundValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}% opaque'**
  String widgetBackgroundValue(int percent);

  /// No description provided for @widgetLastMonth.
  ///
  /// In en, this message translates to:
  /// **'{month}: {amount}'**
  String widgetLastMonth(String month, String amount);

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockTitle;

  /// No description provided for @appLockSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Ask for your fingerprint, face or screen lock to open Hisab'**
  String get appLockSettingsHint;

  /// No description provided for @appLockOnSummary.
  ///
  /// In en, this message translates to:
  /// **'On, locks {timeout}'**
  String appLockOnSummary(String timeout);

  /// No description provided for @appLockSwitch.
  ///
  /// In en, this message translates to:
  /// **'Lock Hisab'**
  String get appLockSwitch;

  /// No description provided for @appLockSwitchHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses your phone\'s fingerprint, face or screen lock (PIN, pattern or password). There is no separate PIN to forget.'**
  String get appLockSwitchHelp;

  /// No description provided for @appLockAfter.
  ///
  /// In en, this message translates to:
  /// **'Lock again after leaving Hisab'**
  String get appLockAfter;

  /// No description provided for @appLockImmediately.
  ///
  /// In en, this message translates to:
  /// **'immediately'**
  String get appLockImmediately;

  /// No description provided for @appLockOneMinute.
  ///
  /// In en, this message translates to:
  /// **'after 1 minute'**
  String get appLockOneMinute;

  /// No description provided for @appLockFiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'after 5 minutes'**
  String get appLockFiveMinutes;

  /// No description provided for @appLockImmediatelyShort.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get appLockImmediatelyShort;

  /// No description provided for @appLockOneMinuteShort.
  ///
  /// In en, this message translates to:
  /// **'1 min'**
  String get appLockOneMinuteShort;

  /// No description provided for @appLockFiveMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'5 min'**
  String get appLockFiveMinutesShort;

  /// No description provided for @appLockHideInRecents.
  ///
  /// In en, this message translates to:
  /// **'Hide in recent apps'**
  String get appLockHideInRecents;

  /// No description provided for @appLockHideInRecentsHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows a blank card in the recent apps list. Screenshots of Hisab are blocked too.'**
  String get appLockHideInRecentsHelp;

  /// No description provided for @appLockNoScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Your phone has no screen lock. Set a PIN, pattern or password in your phone\'s settings, then turn on app lock.'**
  String get appLockNoScreenLock;

  /// No description provided for @appLockEnableReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to turn on app lock'**
  String get appLockEnableReason;

  /// No description provided for @appLockPromptReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Hisab'**
  String get appLockPromptReason;

  /// No description provided for @appLockLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hisab is locked'**
  String get appLockLockedTitle;

  /// No description provided for @appLockLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint, face or screen lock to open it.'**
  String get appLockLockedHint;

  /// No description provided for @appLockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLockUnlock;

  /// No description provided for @appLockLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a little and try again.'**
  String get appLockLockedOut;
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
