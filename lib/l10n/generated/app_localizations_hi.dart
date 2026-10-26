// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'हिसाब';

  @override
  String get tabHome => 'होम';

  @override
  String get tabEntries => 'लेन-देन';

  @override
  String get tabGroups => 'ग्रुप';

  @override
  String get tabSettings => 'सेटिंग्स';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सेव करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get remove => 'निकालें';

  @override
  String get edit => 'बदलें';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get add => 'जोड़ें';

  @override
  String get ignore => 'अनदेखा करें';

  @override
  String get allow => 'अनुमति दें';

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get ok => 'ठीक है';

  @override
  String get name => 'नाम';

  @override
  String get note => 'नोट';

  @override
  String get moreDetails => 'अधिक विवरण';

  @override
  String get all => 'सभी';

  @override
  String get others => 'अन्य';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get you => 'आप';

  @override
  String youSuffix(String name) {
    return '$name (आप)';
  }

  @override
  String get required => 'आवश्यक';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get manage => 'प्रबंधित करें';

  @override
  String get kindExpense => 'खर्च';

  @override
  String get kindIncome => 'आय';

  @override
  String get kindTransfer => 'ट्रांसफ़र';

  @override
  String get kindExpenses => 'खर्च';

  @override
  String get kindTransfers => 'ट्रांसफ़र';

  @override
  String get uncategorised => 'बिना श्रेणी';

  @override
  String yourShareOf(String group) {
    return '$group · आपका हिस्सा';
  }

  @override
  String get sourceSms => 'एसएमएस';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आइटम',
      one: '1 आइटम',
    );
    return '$_temp0';
  }

  @override
  String get accountTypeBank => 'बैंक खाता';

  @override
  String get accountTypeCard => 'क्रेडिट कार्ड';

  @override
  String get accountTypeWallet => 'वॉलेट/UPI';

  @override
  String get accountTypeCash => 'नकद';

  @override
  String get accounts => 'खाते';

  @override
  String get account => 'खाता';

  @override
  String get newAccount => 'नया खाता';

  @override
  String get editAccount => 'खाता संपादित करें';

  @override
  String get accountNameHint => 'HDFC सेविंग्स, Paytm, नकद';

  @override
  String get outstandingBalance => 'कार्ड पर बकाया';

  @override
  String cardDue(String amount) {
    return 'बकाया $amount';
  }

  @override
  String get currentBalance => 'मौजूदा बैलेंस';

  @override
  String get includeInTotal => 'कुल बैलेंस में शामिल करें';

  @override
  String get excludedFromTotal => 'कुल से बाहर';

  @override
  String asOf(String date) {
    return '$date तक';
  }

  @override
  String get noAccountsTitle => 'अभी कोई खाता नहीं';

  @override
  String get noAccountsBody =>
      'बैंक एसएमएस से मिले खाते अपने बताए गए बैलेंस के साथ अपने-आप जुड़ जाते हैं। हाथ से जोड़े गए लेन-देन चुने हुए खाते का बैलेंस बदलते हैं।';

  @override
  String deleteNamed(String name) {
    return '$name हटाएँ?';
  }

  @override
  String get budgets => 'बजट';

  @override
  String get budget => 'बजट';

  @override
  String get overall => 'कुल';

  @override
  String get category => 'श्रेणी';

  @override
  String get overallMonthlyBudget => 'कुल मासिक बजट';

  @override
  String get budgetForCategory => 'किसी श्रेणी का बजट';

  @override
  String get overallMonthlyLimit => 'कुल मासिक सीमा';

  @override
  String categoryMonthlyLimit(String category) {
    return '$category की मासिक सीमा';
  }

  @override
  String get noBudgetsTitle => 'अभी कोई बजट नहीं';

  @override
  String get noBudgetsBody =>
      'कुल या श्रेणी के हिसाब से मासिक सीमा तय करें। होम पर दिखेगा कि कितना खर्च हुआ और कितना बचा है।';

  @override
  String get removeBudgetQuestion => 'यह बजट हटाएँ?';

  @override
  String budgetOverBy(String amount, String limit) {
    return '$limit से $amount ज़्यादा';
  }

  @override
  String budgetLeftWithDays(String amount, String limit, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '1 दिन',
    );
    return '$limit में से $amount बाकी · $_temp0';
  }

  @override
  String get budgetRemoved => 'बजट हटाया गया';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get setOpeningBalance => 'शुरुआती बैलेंस सेट करें';

  @override
  String get setBudget => 'बजट सेट करें';

  @override
  String get startGroup => 'ग्रुप शुरू करें';

  @override
  String get categories => 'श्रेणियाँ';

  @override
  String unitsLabel(String units) {
    return 'इकाइयाँ: $units';
  }

  @override
  String get addSubcategory => 'उपश्रेणी जोड़ें';

  @override
  String get deleteCategoryBody =>
      'मौजूदा लेन-देन की राशि बनी रहेगी, पर वे बिना श्रेणी के हो जाएँगे।';

  @override
  String get archiveCategory => 'आर्काइव करें (पिकर से छिपाएँ)';

  @override
  String get unarchive => 'आर्काइव से निकालें';

  @override
  String get newCategory => 'नई श्रेणी';

  @override
  String newSubcategoryOf(String parent) {
    return '$parent की नई उपश्रेणी';
  }

  @override
  String editNamed(String name) {
    return '$name संपादित करें';
  }

  @override
  String get unitsForItems => 'आइटम की इकाइयाँ (कॉमा से अलग करें)';

  @override
  String get colour => 'रंग';

  @override
  String get icon => 'आइकन';

  @override
  String get searchCategories => 'श्रेणी खोजें';

  @override
  String get noMatchingCategory => 'कोई मिलती-जुलती श्रेणी नहीं';

  @override
  String moreCount(int count) {
    return '+$count';
  }

  @override
  String get expand => 'खोलें';

  @override
  String get collapse => 'बंद करें';

  @override
  String smsToReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count एसएमएस समीक्षा के लिए',
      one: '1 एसएमएस समीक्षा के लिए',
    );
    return '$_temp0';
  }

  @override
  String get spentThisMonth => 'इस महीने का खर्च';

  @override
  String get income => 'आय';

  @override
  String get saved => 'बचत';

  @override
  String get overspent => 'ज़्यादा खर्च';

  @override
  String get balances => 'बैलेंस';

  @override
  String get spendingByCategory => 'श्रेणी के हिसाब से खर्च';

  @override
  String get recent => 'हाल के';

  @override
  String get noEntriesThisMonthTitle => 'इस महीने कोई लेन-देन नहीं';

  @override
  String get noEntriesThisMonthBody =>
      'पहला खर्च जोड़ने के लिए + दबाएँ, या सेटिंग्स में बैंक एसएमएस पढ़ना चालू करें।';

  @override
  String get newEntry => 'नया लेन-देन';

  @override
  String get editEntry => 'लेन-देन बदलें';

  @override
  String get discardEntryTitle => 'यह लेन-देन छोड़ दें?';

  @override
  String get discardEntryBody => 'आपने जो भरा है वह खो जाएगा।';

  @override
  String get keepEditing => 'भरना जारी रखें';

  @override
  String get discard => 'छोड़ दें';

  @override
  String get groupExpense => 'ग्रुप खर्च';

  @override
  String get deleteEntryQuestion => 'यह लेन-देन हटाएँ?';

  @override
  String totalOfItems(int count) {
    return '$count आइटम का कुल';
  }

  @override
  String get chooseCategory => 'श्रेणी चुनें';

  @override
  String get fromAccount => 'खाते से';

  @override
  String get toAccount => 'खाते में';

  @override
  String get payeeLabel => 'किसे दिया / किससे मिला';

  @override
  String get smsEntryNotice =>
      'एसएमएस से जोड़ा गया। इसे बदलने से बैंक बैलेंस नहीं बदलेगा।';

  @override
  String get saving => 'सेव हो रहा है…';

  @override
  String saveAmount(String amount) {
    return '$amount सेव करें';
  }

  @override
  String get addAccount => 'खाता जोड़ें';

  @override
  String get items => 'आइटम';

  @override
  String get addItem => 'आइटम जोड़ें';

  @override
  String itemSuggestion(String name, String quantity, String price) {
    return '$name · $quantity @ $price';
  }

  @override
  String get itemsHelp =>
      'वैकल्पिक: इस खर्च को मात्रा और दाम के साथ आइटम में बाँटें (जैसे भैंस का दूध 1 लीटर)। हिसाब इन्हें अगली बार याद रखेगा।';

  @override
  String get paidBy => 'किसने दिया';

  @override
  String get split => 'बाँटें';

  @override
  String get invalidAmount => 'सही राशि लिखें, जैसे 250 या 99.50';

  @override
  String get errorAmountZero => 'शून्य से ज़्यादा राशि लिखें';

  @override
  String get errorPickCategory => 'श्रेणी चुनें';

  @override
  String get errorPickBothAccounts => 'ट्रांसफ़र के लिए दोनों खाते चुनें';

  @override
  String get errorPickAccount => 'खाता चुनें';

  @override
  String get errorSameAccount => 'दोनों खाते अलग होने चाहिए';

  @override
  String get errorItemName => 'हर आइटम का नाम ज़रूरी है';

  @override
  String get errorChoosePayer => 'चुनें कि किसने दिया';

  @override
  String get errorFixSplit => 'पहले बँटवारा ठीक करें';

  @override
  String get itemName => 'आइटम का नाम';

  @override
  String get qty => 'मात्रा';

  @override
  String get unit => 'इकाई';

  @override
  String pricePerUnit(String unit) {
    return 'दाम प्रति $unit';
  }

  @override
  String get genericUnit => 'इकाई';

  @override
  String get shareSummary => 'सारांश शेयर करें';

  @override
  String get renameGroup => 'ग्रुप का नाम बदलें';

  @override
  String get deleteGroupBody => 'इस ग्रुप के सभी खर्च हट जाएँगे।';

  @override
  String get simplifyOn => 'उधार सरल करना चालू करें';

  @override
  String get simplifyOff => 'उधार सरल करना बंद करें';

  @override
  String get deleteGroup => 'ग्रुप हटाएँ';

  @override
  String get addMemberFirst => 'पहले कम से कम एक और सदस्य जोड़ें';

  @override
  String get addExpense => 'खर्च जोड़ें';

  @override
  String get members => 'सदस्य';

  @override
  String shareHeader(String group) {
    return '$group — हिसाब';
  }

  @override
  String sharePays(String from, String to, String amount) {
    return '$from $to को $amount देंगे';
  }

  @override
  String get allSettledUp => 'सबका हिसाब बराबर है।';

  @override
  String get sharedFromHisab => 'हिसाब ऐप से शेयर किया गया';

  @override
  String paidByPeople(String payer, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लोग',
      one: '1 व्यक्ति',
    );
    return '$payer ने चुकाया · $_temp0';
  }

  @override
  String yourShare(String amount) {
    return 'आप: $amount';
  }

  @override
  String settlementLine(String from, String to) {
    return '$from ने $to को चुकाया';
  }

  @override
  String get settledPayments => 'चुकाए गए भुगतान';

  @override
  String paymentRecorded(String transfer, String amount) {
    return '$transfer $amount दर्ज हुआ';
  }

  @override
  String get paymentRemoved => 'भुगतान हटाया गया';

  @override
  String get removePayment => 'भुगतान हटाएँ';

  @override
  String get removePaymentBody =>
      'बैलेंस वापस वैसे हो जाएँगे जैसे इस भुगतान से पहले थे।';

  @override
  String get moreOptions => 'और विकल्प';

  @override
  String get noGroupExpensesTitle => 'अभी कोई खर्च नहीं';

  @override
  String get noGroupExpensesBody =>
      'पहला साझा खर्च जोड़ें; किसे कितना देना है, Hisab हिसाब लगा देगा।';

  @override
  String get netBalances => 'कुल हिसाब';

  @override
  String get getsBack => 'मिलेंगे';

  @override
  String get owes => 'देने हैं';

  @override
  String get settleUp => 'हिसाब चुकता करें';

  @override
  String get settleUpSimplified => 'हिसाब चुकता करें (सरल)';

  @override
  String get everyoneSettled => 'सबका हिसाब बराबर है';

  @override
  String transferArrow(String from, String to) {
    return '$from → $to';
  }

  @override
  String get recordPayment => 'भुगतान दर्ज करें';

  @override
  String get settleBeforeRemove =>
      'इस सदस्य को निकालने से पहले उसका हिसाब बराबर करें';

  @override
  String removeNamed(String name) {
    return '$name को निकालें?';
  }

  @override
  String get renameMember => 'सदस्य का नाम बदलें';

  @override
  String get addMember => 'सदस्य जोड़ें';

  @override
  String get memberName => 'सदस्य का नाम';

  @override
  String get membersLocalNotice =>
      'सदस्य इसी डिवाइस पर सहेजे जाते हैं। इनवाइट कोड से साझा सिंक की योजना है; सेटिंग्स → सिंक देखें।';

  @override
  String get newGroup => 'नया ग्रुप';

  @override
  String get groupName => 'ग्रुप का नाम';

  @override
  String get groupNameHint => 'गोवा ट्रिप, फ़्लैट 302…';

  @override
  String get membersCommaSeparated => 'सदस्य (कॉमा से अलग करें)';

  @override
  String get membersHint => 'राहुल, प्रिया, अमन';

  @override
  String get createGroup => 'ग्रुप बनाएँ';

  @override
  String get groups => 'ग्रुप';

  @override
  String get noGroupsTitle => 'दोस्तों के साथ बिल बाँटें';

  @override
  String get noGroupsBody =>
      'ट्रिप, फ़्लैट या डिनर के लिए ग्रुप बनाएँ। खर्च जोड़ें, उन्हें बराबर, प्रतिशत, शेयर या तय राशि में बाँटें और हिसाब चुकता करें।';

  @override
  String get youAreOwed => 'आपको मिलने हैं';

  @override
  String get youOwe => 'आपको देने हैं';

  @override
  String groupSubtitle(int count, String amount) {
    return '$count सदस्य · $amount खर्च';
  }

  @override
  String get youGet => 'आपको मिलेंगे';

  @override
  String get youOweLower => 'आपको देने हैं';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get appearance => 'रूप-रंग';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'डिवाइस की भाषा';

  @override
  String get money => 'पैसा';

  @override
  String get currency => 'मुद्रा';

  @override
  String get currencyChooseTitle => 'अपनी मुद्रा चुनें';

  @override
  String get currencyChooseBody =>
      'Hisab में रकम इसी मुद्रा में दिखेगी। आप इसे बाद में सेटिंग्स में बदल सकते हैं।';

  @override
  String get currencySearchHint => 'कोड, नाम या देश खोजें';

  @override
  String currencyContinue(String currency) {
    return '$currency के साथ आगे बढ़ें';
  }

  @override
  String currencyNoMatch(String query) {
    return '\"$query\" से कोई मुद्रा नहीं मिली';
  }

  @override
  String get monthStartsOn => 'महीना शुरू होता है';

  @override
  String get monthStartsOnHelp => 'अपनी सैलरी की तारीख चुनें';

  @override
  String get monthStartsOnExplain =>
      'बजट और महीने के कुल आपके वेतन चक्र के हिसाब से चलेंगे';

  @override
  String dayNumber(int day) {
    return 'दिन $day';
  }

  @override
  String get monthStartPrompt => 'महीना किस दिन शुरू हो (1–28)';

  @override
  String get automation => 'ऑटोमेशन';

  @override
  String get bankSms => 'बैंक एसएमएस';

  @override
  String get bankSmsOn => 'चालू · इस डिवाइस पर बैंक एसएमएस पढ़ रहा है';

  @override
  String get off => 'बंद';

  @override
  String get yourNameInGroups => 'ग्रुप में आपका नाम';

  @override
  String get yourName => 'आपका नाम';

  @override
  String get backupAndSync => 'बैकअप और सिंक';

  @override
  String get exportBackup => 'एन्क्रिप्टेड बैकअप निर्यात करें';

  @override
  String get exportBackupHelp => 'AES-256, आपके चुने पासफ़्रेज़ से सुरक्षित';

  @override
  String get restoreBackup => 'बैकअप से वापस लाएँ';

  @override
  String get restoreBackupHelp =>
      'मिलाया जाता है; नए स्थानीय बदलाव बने रहते हैं';

  @override
  String get cloudSync => 'क्लाउड सिंक';

  @override
  String get cloudSyncHelp =>
      'आगे: Android पर Google Drive, iOS पर iCloud, बैकअप जैसे ही फ़ॉर्मैट में एंड-टू-एंड एन्क्रिप्टेड।';

  @override
  String get about => 'ऐप के बारे में';

  @override
  String get aboutBody =>
      'मुफ़्त, ओपन सोर्स, कोई विज्ञापन नहीं, कोई अकाउंट नहीं। आपका डेटा आपके डिवाइस पर रहता है।';

  @override
  String get aboutMadeWithBefore => '';

  @override
  String get aboutMadeWithAfter => 'से बनाया गया';

  @override
  String get aboutMadeWithLabel => 'प्यार से बनाया गया';

  @override
  String get backupPassphrase => 'बैकअप पासफ़्रेज़';

  @override
  String get backupPassphraseHelp =>
      'कम से कम 8 अक्षर; वापस लाने के लिए यही चाहिए होगा';

  @override
  String get passphraseTooShort => 'कम से कम 8 अक्षर रखें';

  @override
  String get backupShareSubject => 'हिसाब एन्क्रिप्टेड बैकअप';

  @override
  String restoredRecords(int count) {
    return '$count रिकॉर्ड वापस लाए गए';
  }

  @override
  String restoreFailed(String error) {
    return 'वापस लाना विफल: $error';
  }

  @override
  String get pasted => 'पेस्ट किया गया';

  @override
  String get smsFoundReview => 'लेन-देन मिला। नीचे समीक्षा करें।';

  @override
  String get smsAdded => 'लेन-देन जोड़ा गया।';

  @override
  String get smsDuplicate => 'पहले ही जोड़ा जा चुका है।';

  @override
  String get smsForeignCurrency =>
      'केवल आपकी मुख्य मुद्रा वाले SMS समर्थित हैं, इसलिए यह SMS छोड़ दिया गया।';

  @override
  String get smsNotFound => 'इस टेक्स्ट में कोई लेन-देन नहीं मिला।';

  @override
  String get smsNotificationTitle => 'नया बैंक लेन-देन';

  @override
  String smsNotificationBodyAmount(String amount, String sender) {
    return '$sender से $amount। देखने के लिए टैप करें।';
  }

  @override
  String smsNotificationBody(String sender) {
    return '$sender से। देखने के लिए टैप करें।';
  }

  @override
  String smsNotificationBodyAmountAutoAdd(String amount, String sender) {
    return '$sender से $amount। जोड़ने के लिए हिसाब खोलें।';
  }

  @override
  String smsNotificationBodyAutoAdd(String sender) {
    return '$sender से। जोड़ने के लिए हिसाब खोलें।';
  }

  @override
  String get readBankSmsQuestion => 'बैंक एसएमएस पढ़ें?';

  @override
  String get smsConsentBody =>
      'लेन-देन दर्ज करने और खाते का बैलेंस दिखाने के लिए हिसाब आपके बैंक और UPI ऐप के एसएमएस पढ़ता है। संदेश सिर्फ़ इसी डिवाइस पर पढ़े जाते हैं और कभी अपलोड नहीं होते।';

  @override
  String get smsPermissionDenied => 'एसएमएस की अनुमति नहीं मिली';

  @override
  String scanResult(int scanned, int added, int pending) {
    return '$scanned संदेश देखे: $added जोड़े गए, $pending समीक्षा के लिए बाकी।';
  }

  @override
  String get readBankSmsAuto => 'बैंक एसएमएस अपने-आप पढ़ें';

  @override
  String get smsAndroidOnly =>
      'सिर्फ़ Android पर। डिवाइस पर ही पढ़े जाते हैं, कभी अपलोड नहीं होते।';

  @override
  String get smsNotOnIos =>
      'iOS पर उपलब्ध नहीं। शॉर्टकट इस्तेमाल करें या नीचे पेस्ट करें।';

  @override
  String get smsAutoAddTitle => 'साफ़ लेन-देन अपने-आप जोड़ें';

  @override
  String get smsAutoAddHelp =>
      'चालू: साफ़ बैंक एसएमएस तुरंत जुड़ते हैं, पूर्ववत करने के विकल्प के साथ। अस्पष्ट एसएमएस समीक्षा के लिए रुकते हैं।';

  @override
  String get scanInboxNow => 'अभी इनबॉक्स स्कैन करें';

  @override
  String get scanInboxHelp =>
      'पहली बार पिछले 90 दिन देखता है, फिर सिर्फ़ नए संदेश';

  @override
  String get pasteSms => 'एसएमएस पेस्ट करें';

  @override
  String get pasteSmsHelp => 'iOS और Android दोनों पर काम करता है';

  @override
  String get pasteBankSms => 'बैंक एसएमएस पेस्ट करें';

  @override
  String get pasteBankSmsHint =>
      'Rs.500 debited from A/c XX1234… (बैंक का संदेश जैसा है वैसा)';

  @override
  String toReview(int count) {
    return 'समीक्षा के लिए ($count)';
  }

  @override
  String get nothingWaitingTitle => 'कुछ बाकी नहीं';

  @override
  String get nothingWaitingBody => 'नए बैंक लेन-देन यहाँ दिखेंगे।';

  @override
  String get iosShortcutHelp =>
      'iPhone: एक शॉर्टकट ऑटोमेशन बनाएँ \"जब मुझे \'debited\' वाला संदेश मिले\" → \"URL खोलें\" hisab://sms?text=[Message]। हिसाब खुलेगा और समीक्षा के लिए लेन-देन दिखाएगा।';

  @override
  String get couldNotAddUseEdit => 'जोड़ा नहीं जा सका; बदलें का इस्तेमाल करें';

  @override
  String addAmount(String amount) {
    return '$amount जोड़ें';
  }

  @override
  String get splitDoesNotAddUp => 'बँटवारे का जोड़ कुल से मेल नहीं खाता';

  @override
  String splitsAcross(String amount, int count) {
    return '$amount को $count लोगों में बाँटता है';
  }

  @override
  String get splitEqual => 'बराबर';

  @override
  String get splitExact => 'तय राशि';

  @override
  String get splitPercent => 'प्रतिशत';

  @override
  String get splitShares => 'शेयर/अनुपात';

  @override
  String get splitAdjustment => 'समायोजन';

  @override
  String get splitByItem => 'आइटम के हिसाब से';

  @override
  String get splitHelpEqual => 'हर चुना हुआ व्यक्ति बराबर हिस्सा देता है।';

  @override
  String get splitHelpExact =>
      'हर व्यक्ति की राशि लिखें; जोड़ कुल के बराबर होना चाहिए।';

  @override
  String get splitHelpPercent => 'प्रतिशत लिखें, जोड़ 100 होना चाहिए।';

  @override
  String get splitHelpShares =>
      'शेयर लिखें, जैसे जोड़े के लिए 2 और अकेले के लिए 1।';

  @override
  String get splitHelpAdjustment =>
      'पहले अतिरिक्त राशि ली जाती है, बाकी चुने हुए लोगों में बराबर बँटती है।';

  @override
  String get splitHelpByItem => 'हर आइटम उसे साझा करने वालों में बँटता है।';

  @override
  String get entries => 'लेन-देन';

  @override
  String get searchEntriesHint => 'नाम, नोट, आइटम या श्रेणी खोजें';

  @override
  String get noEntriesTitle => 'अभी यहाँ कुछ नहीं';

  @override
  String get noEntriesBody =>
      'इस महीने के लेन-देन दिन के हिसाब से यहाँ दिखेंगे।';

  @override
  String get settled => 'हिसाब बराबर';

  @override
  String get unitsHint => 'ली, मिली, किलो';

  @override
  String get splitErrorNegativeTotal => 'राशि ऋणात्मक नहीं हो सकती';

  @override
  String get splitErrorNobodyIncluded => 'कम से कम एक व्यक्ति चुनें';

  @override
  String get splitErrorNegativeAmounts => 'राशियाँ ऋणात्मक नहीं हो सकतीं';

  @override
  String splitErrorAmountLeft(String amount) {
    return '$amount बाँटना बाकी है';
  }

  @override
  String splitErrorAmountOver(String amount) {
    return 'कुल से $amount ज़्यादा';
  }

  @override
  String get splitErrorNegativeValues => 'मान ऋणात्मक नहीं हो सकते';

  @override
  String get splitErrorPercentMustTotal => 'प्रतिशत का जोड़ 100 होना चाहिए';

  @override
  String get splitErrorNoShares => 'कम से कम एक शेयर लिखें';

  @override
  String splitErrorPercentLeft(String percent) {
    return '$percent% बाँटना बाकी है';
  }

  @override
  String splitErrorPercentOver(String percent) {
    return '100 से $percent% ज़्यादा';
  }

  @override
  String splitErrorAdjustmentsExceed(String amount) {
    return 'समायोजन कुल $amount से ज़्यादा है';
  }

  @override
  String get splitErrorAdjustmentNegativeShare =>
      'एक समायोजन से किसी का हिस्सा ऋणात्मक हो जाता है';

  @override
  String get splitErrorNoItems => 'कम से कम एक आइटम जोड़ें';

  @override
  String splitErrorItemsExceed(String amount) {
    return 'आइटम कुल से $amount ज़्यादा हैं';
  }

  @override
  String splitErrorItemUnassigned(String item) {
    return '\"$item\" किसी को दें';
  }

  @override
  String get genericItem => 'आइटम';

  @override
  String spentInMonth(String month) {
    return '$month का खर्च';
  }

  @override
  String vsLastMonthUp(int percent, String month) {
    return '▲ $percent% बनाम $month';
  }

  @override
  String vsLastMonthDown(int percent, String month) {
    return '▼ $percent% बनाम $month';
  }

  @override
  String vsLastMonthSame(String month) {
    return '$month जितना';
  }

  @override
  String get dailyAverage => 'रोज़ाना औसत';

  @override
  String perDay(String amount) {
    return '$amount/दिन';
  }

  @override
  String daysOfMonth(int elapsed, int total) {
    return '$total में से $elapsed दिन';
  }

  @override
  String get heroEmptyCaption => 'इस महीने अभी तक कोई खर्च नहीं';

  @override
  String get addFirstEntry => 'अपनी पहली प्रविष्टि जोड़ें';

  @override
  String get copied => 'कॉपी हो गया';

  @override
  String get spendingTrend => 'खर्च का रुझान';

  @override
  String get trendDaily => 'दैनिक';

  @override
  String get trendMonthly => 'मासिक';

  @override
  String get trendEmpty => 'अपना रुझान देखने के लिए कुछ प्रविष्टियाँ जोड़ें';

  @override
  String trendSemantics(String amount) {
    return 'खर्च का रुझान: इस महीने अब तक $amount खर्च';
  }

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get categoriesEmpty => 'आपकी श्रेणियाँ यहाँ दिखेंगी';

  @override
  String percentOf(int percent) {
    return '$percent%';
  }

  @override
  String get budgetsEmptyBody => 'अपनी प्रगति देखने के लिए बजट तय करें';

  @override
  String andMoreCount(int count) {
    return 'और $count और';
  }

  @override
  String youGetAmount(String amount) {
    return 'आपको $amount मिलेंगे';
  }

  @override
  String youOweAmount(String amount) {
    return 'आप पर $amount बकाया';
  }

  @override
  String get upcoming => 'आने वाले';

  @override
  String get upcomingEmpty => 'अगले दो हफ़्तों में कुछ देय नहीं';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सदस्य',
      one: '1 सदस्य',
    );
    return '$_temp0';
  }

  @override
  String get noEntriesYetTitle => 'अभी कोई प्रविष्टि नहीं';

  @override
  String get noEntriesYetBody =>
      '+ से जोड़ें या बैंक एसएमएस चालू करें ताकि ये अपने आप दर्ज हों';

  @override
  String get addEntry => 'प्रविष्टि जोड़ें';

  @override
  String get showAllCategories => 'सभी श्रेणियाँ दिखाएँ';

  @override
  String get projects => 'प्रोजेक्ट';

  @override
  String get project => 'प्रोजेक्ट';

  @override
  String get newProject => 'नया प्रोजेक्ट';

  @override
  String get blankProject => 'खाली प्रोजेक्ट';

  @override
  String get editProject => 'प्रोजेक्ट संपादित करें';

  @override
  String get projectName => 'प्रोजेक्ट का नाम';

  @override
  String get noProjectsTitle => 'अभी कोई प्रोजेक्ट नहीं';

  @override
  String get noProjectsBody =>
      'गाड़ी, घर की मरम्मत, यात्रा या शादी का खर्च उसके अपने बजट के साथ ट्रैक करें।';

  @override
  String get startProject => 'प्रोजेक्ट शुरू करें';

  @override
  String get projectsEmptyBody =>
      'किसी बड़े खर्च को उसके बजट के साथ ट्रैक करने के लिए प्रोजेक्ट शुरू करें';

  @override
  String get projectStatusActive => 'चालू';

  @override
  String get projectStatusCompleted => 'पूरा';

  @override
  String get projectStatusArchived => 'संग्रहित';

  @override
  String get showArchived => 'संग्रहित दिखाएँ';

  @override
  String get hideArchived => 'संग्रहित छिपाएँ';

  @override
  String spentOfBudget(String spent, String budget) {
    return '$budget में से $spent';
  }

  @override
  String spentAmount(String amount) {
    return '$amount खर्च';
  }

  @override
  String leftOfBudget(String amount, String budget) {
    return '$budget में से $amount बाकी';
  }

  @override
  String receivedAmount(String amount) {
    return '$amount वापस मिला';
  }

  @override
  String get noBudgetSet => 'कोई बजट नहीं';

  @override
  String get allTime => 'कुल';

  @override
  String entryCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count प्रविष्टियाँ',
      one: '1 प्रविष्टि',
      zero: 'कोई प्रविष्टि नहीं',
    );
    return '$_temp0';
  }

  @override
  String get noProjectEntriesTitle => 'अभी कोई खर्च नहीं';

  @override
  String get noProjectEntriesBody =>
      'यहाँ से प्रविष्टि जोड़ें, वह इस प्रोजेक्ट में गिनी जाएगी';

  @override
  String get markCompleted => 'पूरा हुआ';

  @override
  String get reopenProject => 'फिर से खोलें';

  @override
  String get archiveProject => 'संग्रहित करें';

  @override
  String get deleteProject => 'प्रोजेक्ट हटाएँ';

  @override
  String get deleteProjectBody =>
      'प्रविष्टियाँ आपके खाते में रहेंगी, बस इस प्रोजेक्ट से हट जाएँगी।';

  @override
  String get projectDeleted => 'प्रोजेक्ट हटाया गया';

  @override
  String get startDate => 'शुरुआत';

  @override
  String get endDate => 'समाप्ति';

  @override
  String get notSet => 'तय नहीं';

  @override
  String get budgetOptional => 'बजट (वैकल्पिक)';

  @override
  String get notes => 'नोट्स';

  @override
  String get projectNotFound => 'यह प्रोजेक्ट हटा दिया गया';

  @override
  String get spentSoFar => 'अब तक खर्च';

  @override
  String get spendingByMonth => 'महीनेवार खर्च';

  @override
  String get projectMarkedCompleted => 'पूरा चिह्नित किया';

  @override
  String get projectArchivedSnack => 'प्रोजेक्ट संग्रहित किया';

  @override
  String get projectReopened => 'प्रोजेक्ट फिर से खोला';

  @override
  String projectDates(String start, String end) {
    return '$start – $end';
  }

  @override
  String sinceDate(String date) {
    return '$date से';
  }

  @override
  String untilDate(String date) {
    return '$date तक';
  }

  @override
  String get startFromTemplate => 'टेम्पलेट से शुरू करें';

  @override
  String get blankProjectHint => 'नाम दें और कुछ भी ट्रैक करें';

  @override
  String get templateVehicle => 'वाहन';

  @override
  String get templateVehicleHint => 'पेट्रोल, सर्विस, बीमा और प्रति किमी खर्च';

  @override
  String get templateConstruction => 'घर निर्माण';

  @override
  String get templateConstructionHint =>
      'सामग्री, मज़दूरी, चरण और प्रति वर्ग फ़ुट खर्च';

  @override
  String get templateRenovation => 'मरम्मत / रिनोवेशन';

  @override
  String get templateRenovationHint => 'कमरेवार खर्च, सामान और कारीगर';

  @override
  String get templateTrip => 'यात्रा';

  @override
  String get templateTripHint => 'सफ़र, ठहरना, खाना और घूमना';

  @override
  String get templateWedding => 'शादी';

  @override
  String get templateWeddingHint => 'वेन्यू, खानपान, कपड़े, वेंडर और शगुन';

  @override
  String get addSuggestedCategories => 'सुझाई गई श्रेणियाँ जोड़ें';

  @override
  String suggestedCategoriesNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नई श्रेणियाँ',
      one: '1 नई श्रेणी',
    );
    return '$_temp0';
  }

  @override
  String suggestedCategoriesReused(int count) {
    return '$count पहले से आपकी सूची में';
  }

  @override
  String get categoryPacks => 'श्रेणी पैक';

  @override
  String get addAPack => 'पैक जोड़ें';

  @override
  String get categoryPacksHint =>
      'ज़िंदगी के किसी हिस्से के लिए तैयार श्रेणियाँ। एक टैप में जोड़ें, जब चाहें हटाएँ।';

  @override
  String packCategoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count श्रेणियाँ',
      one: '1 श्रेणी',
    );
    return '$_temp0';
  }

  @override
  String get packAdded => 'जोड़ा गया';

  @override
  String get addPack => 'पैक जोड़ें';

  @override
  String get removePack => 'पैक हटाएँ';

  @override
  String packAddedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'पैक $count नई श्रेणियों के साथ जुड़ गया',
      one: 'पैक 1 नई श्रेणी के साथ जुड़ गया',
      zero: 'पैक जुड़ गया। इसकी सभी श्रेणियाँ पहले से थीं',
    );
    return '$_temp0';
  }

  @override
  String removePackTitle(String pack) {
    return '$pack हटाएँ?';
  }

  @override
  String removePackMessage(int archived, int kept) {
    return 'बिना इस्तेमाल वाली श्रेणियाँ ($archived) आर्काइव होंगी। इस्तेमाल में आ रही श्रेणियाँ ($kept) आपकी अपनी बनकर रहेंगी।';
  }

  @override
  String get packRemoved => 'पैक हटाया गया';

  @override
  String get packAlreadyHave => 'पहले से आपकी सूची में';

  @override
  String get suggestedCategoriesAllPresent =>
      'सुझाई गई सभी श्रेणियाँ पहले से आपकी सूची में हैं';

  @override
  String get projectDetails => 'प्रोजेक्ट विवरण';

  @override
  String get fieldOdometer => 'ओडोमीटर';

  @override
  String get fieldLitres => 'ईंधन लीटर';

  @override
  String get fieldBuiltUpArea => 'निर्मित क्षेत्र';

  @override
  String get fieldStage => 'चरण';

  @override
  String get fieldQuantity => 'मात्रा';

  @override
  String get fieldRoom => 'कमरा';

  @override
  String get fieldTravellers => 'यात्री';

  @override
  String get fieldEvent => 'समारोह';

  @override
  String get fieldVendor => 'विक्रेता';

  @override
  String get stageFoundation => 'नींव';

  @override
  String get stagePlinth => 'प्लिंथ';

  @override
  String get stageStructure => 'ढाँचा';

  @override
  String get stageBrickwork => 'चिनाई';

  @override
  String get stageRoofSlab => 'छत की ढलाई';

  @override
  String get stagePlaster => 'प्लास्टर';

  @override
  String get stageElectricalPlumbing => 'बिजली और प्लंबिंग';

  @override
  String get stageFlooring => 'फ़र्श';

  @override
  String get stageDoorsWindows => 'दरवाज़े और खिड़कियाँ';

  @override
  String get stagePainting => 'पेंटिंग';

  @override
  String get stageFinishing => 'फ़िनिशिंग';

  @override
  String get roomKitchen => 'रसोई';

  @override
  String get roomBathroom => 'बाथरूम';

  @override
  String get roomBedroom => 'बेडरूम';

  @override
  String get roomLivingRoom => 'बैठक';

  @override
  String get roomDining => 'डाइनिंग';

  @override
  String get roomBalcony => 'बालकनी';

  @override
  String get roomWholeHouse => 'पूरा घर';

  @override
  String get eventRoka => 'रोका';

  @override
  String get eventEngagement => 'सगाई';

  @override
  String get eventHaldi => 'हल्दी';

  @override
  String get eventMehndi => 'मेहंदी';

  @override
  String get eventSangeet => 'संगीत';

  @override
  String get eventWedding => 'शादी';

  @override
  String get eventReception => 'रिसेप्शन';

  @override
  String get projectMetrics => 'आँकड़े';

  @override
  String get costPerKm => 'प्रति किमी ख़र्च';

  @override
  String kmDriven(String km) {
    return '$km किमी चली';
  }

  @override
  String get fuelBought => 'ख़रीदा गया ईंधन';

  @override
  String litresAmount(String litres, String amount) {
    return '$litres लीटर, $amount में';
  }

  @override
  String get pricePerLitre => 'प्रति लीटर दाम';

  @override
  String get costPerSqFt => 'प्रति वर्ग फ़ुट ख़र्च';

  @override
  String areaOf(String area) {
    return '$area वर्ग फ़ुट पर';
  }

  @override
  String get costPerTraveller => 'प्रति यात्री ख़र्च';

  @override
  String travellersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count यात्री',
      one: '1 यात्री',
    );
    return '$_temp0';
  }

  @override
  String spendingByField(String field) {
    return '$field के हिसाब से ख़र्च';
  }

  @override
  String get notPicked => 'नहीं चुना';

  @override
  String get metricsHint =>
      'आँकड़े देखने के लिए एंट्री में प्रोजेक्ट विवरण भरें (ओडोमीटर, चरण, कमरा…)।';

  @override
  String get projectFields => 'फ़ील्ड';

  @override
  String get addField => 'फ़ील्ड जोड़ें';

  @override
  String get fieldName => 'फ़ील्ड का नाम';

  @override
  String get fieldType => 'प्रकार';

  @override
  String get fieldTypeNumber => 'संख्या';

  @override
  String get fieldTypeText => 'टेक्स्ट';

  @override
  String get fieldTypeDate => 'तारीख़';

  @override
  String get fieldTypeChoice => 'विकल्प';

  @override
  String get fieldTypeUnit => 'इकाई के साथ मात्रा';

  @override
  String get fieldUnitOptional => 'इकाई (वैकल्पिक)';

  @override
  String get fieldOptions => 'विकल्प, कॉमा से अलग करें';

  @override
  String get fieldOnEachEntry => 'हर एंट्री में पूछा जाए';

  @override
  String get fieldOncePerProject => 'पूरे प्रोजेक्ट के लिए एक मान';

  @override
  String get fieldDeleted => 'फ़ील्ड हटाया गया';

  @override
  String get deleteField => 'फ़ील्ड हटाएँ';

  @override
  String get setValue => 'मान सेट करें';

  @override
  String get errorFieldName => 'फ़ील्ड को नाम दें';

  @override
  String get errorFieldOptions => 'कम से कम एक विकल्प जोड़ें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get savePayment => 'भुगतान सेव करें';

  @override
  String get recordAPayment => 'कोई भुगतान दर्ज करें';

  @override
  String get recordAPaymentHint =>
      'कोई भी जोड़ी, कोई भी रकम — आंशिक भुगतान भी चलेगा';

  @override
  String get editPayment => 'भुगतान बदलें';

  @override
  String get paymentUpdated => 'भुगतान अपडेट हुआ';

  @override
  String get paymentFrom => 'किसने दिया';

  @override
  String get paymentTo => 'किसे मिला';

  @override
  String get swapDirection => 'उलटें';

  @override
  String get paymentMethod => 'तरीका';

  @override
  String get methodCash => 'नकद';

  @override
  String get methodUpi => 'UPI';

  @override
  String get methodBank => 'बैंक';

  @override
  String get methodOther => 'अन्य';

  @override
  String paymentOverOwed(String amount) {
    return 'बकाया $amount से ज़्यादा; बाकी रकम क्रेडिट बन जाएगी';
  }

  @override
  String paymentNoDebt(String from, String to) {
    return '$from पर अभी $to का कुछ बकाया नहीं; यह भुगतान क्रेडिट बन जाएगा';
  }

  @override
  String paymentVia(String method) {
    return 'भुगतान · $method';
  }

  @override
  String get samePersonError => 'दो अलग लोग चुनें';

  @override
  String get amountLabel => 'रकम';

  @override
  String get filterMine => 'मेरे';

  @override
  String get filterUnsettled => 'बकाया';

  @override
  String get nothingInvolvingYou => 'अभी तक आपसे जुड़ा कुछ नहीं।';

  @override
  String get expensesAllSettled => 'सब चुकता है। नए खर्च यहाँ दिखेंगे।';

  @override
  String settledUpTo(String date) {
    return '$date तक चुकता';
  }

  @override
  String showOlderRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पुरानी एंट्री दिखाएँ',
      one: '1 पुरानी एंट्री दिखाएँ',
    );
    return '$_temp0';
  }

  @override
  String get hideOlderRows => 'पुरानी एंट्री छिपाएँ';

  @override
  String get youLent => 'आपने उधार दिया';

  @override
  String get youBorrowed => 'आपने उधार लिया';

  @override
  String get youPaid => 'आपने दिए';

  @override
  String get youReceived => 'आपको मिले';

  @override
  String get notInvolved => 'शामिल नहीं';

  @override
  String payerPaidAmount(String payer, String amount) {
    return '$payer ने $amount दिए';
  }

  @override
  String youPaidName(String name) {
    return 'आपने $name को दिए';
  }

  @override
  String namePaidYou(String name) {
    return '$name ने आपको दिए';
  }

  @override
  String get addToProject => 'प्रोजेक्ट में जोड़ें';

  @override
  String get chooseProject => 'प्रोजेक्ट चुनें';

  @override
  String get noProject => 'कोई प्रोजेक्ट नहीं';

  @override
  String get noActiveProjects =>
      'कोई चालू प्रोजेक्ट नहीं। प्रोजेक्ट स्क्रीन से नया शुरू करें।';

  @override
  String get remindAction => 'याद दिलाएँ';

  @override
  String get payAction => 'भुगतान करें';

  @override
  String remindName(String name) {
    return '$name को याद दिलाएँ';
  }

  @override
  String payName(String name) {
    return '$name को भुगतान करें';
  }

  @override
  String reminderOwesMe(String name, String amount, String group) {
    return 'नमस्ते $name, एक छोटी-सी याद: $group के लिए आपको मुझे $amount देने हैं।';
  }

  @override
  String reminderIOwe(String name, String amount, String group) {
    return 'नमस्ते $name, $group के लिए मुझे आपको $amount देने हैं। पैसे अभी भेजे जा रहे हैं।';
  }

  @override
  String reminderOwes(String from, String to, String amount, String group) {
    return '$group के लिए $from को $to को $amount देने हैं।';
  }

  @override
  String reminderEveryone(String group) {
    return '$group का हिसाब चुकता करना है:';
  }

  @override
  String owesLine(String from, String to, String amount) {
    return '$from को $to को $amount देने हैं';
  }

  @override
  String get messageLabel => 'संदेश';

  @override
  String get shareAction => 'शेयर करें…';

  @override
  String get copyAction => 'कॉपी करें';

  @override
  String get whatsAppAction => 'WhatsApp';

  @override
  String get smsAction => 'SMS';

  @override
  String get payWithUpi => 'UPI से भुगतान करें';

  @override
  String get noUpiApp =>
      'इस फ़ोन पर कोई UPI ऐप नहीं है। किसी और तरीके से भुगतान करके उसे दर्ज करें।';

  @override
  String couldNotOpenApp(String app) {
    return '$app नहीं खुल सका।';
  }

  @override
  String get didPaymentGoThrough => 'क्या भुगतान हो गया?';

  @override
  String didPaymentGoThroughBody(String amount, String name) {
    return 'अगर $amount $name तक पहुँच गए, तो Hisab इसे आज UPI से भुगतान के रूप में दर्ज करेगा। Hisab आपका UPI ऐप नहीं देख सकता, इसलिए केवल आप पुष्टि कर सकते हैं।';
  }

  @override
  String get yesRecordIt => 'हाँ, दर्ज करें';

  @override
  String get notYet => 'अभी नहीं';

  @override
  String remindedDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन पहले याद दिलाया',
      one: 'कल याद दिलाया',
      zero: 'आज याद दिलाया',
    );
    return '$_temp0';
  }

  @override
  String get remindAgain => 'फिर याद दिलाएँ';

  @override
  String get copiedReminder => 'कॉपी हो गया। इसे किसी भी चैट में पेस्ट करें।';

  @override
  String get nothingToRemind =>
      'सबका हिसाब बराबर है। न किसी को याद दिलाना है, न भुगतान करना है।';

  @override
  String get shareSummaryAnyway => 'फिर भी सारांश शेयर करें';

  @override
  String get shareBalancesSummary => 'बैलेंस का सारांश शेयर करें';

  @override
  String get remindEveryoneWhoOwes => 'जिन पर आपका बकाया है, सबको याद दिलाएँ';

  @override
  String get copyAsText => 'टेक्स्ट के रूप में कॉपी करें';

  @override
  String get phoneOptional => 'फ़ोन (वैकल्पिक)';

  @override
  String get upiIdOptional => 'UPI ID (वैकल्पिक)';

  @override
  String get upiIdHint => 'name@bank';

  @override
  String get invalidUpiId => 'name@bank जैसा UPI ID डालें';

  @override
  String get memberContactLocal =>
      'फ़ोन और UPI ID इसी डिवाइस पर रहते हैं। Hisab इनका इस्तेमाल सिर्फ़ रिमाइंडर और UPI भुगतान भरने के लिए करता है।';

  @override
  String get editMember => 'सदस्य बदलें';

  @override
  String get filters => 'फ़िल्टर';

  @override
  String get filterEntries => 'लेन-देन फ़िल्टर करें';

  @override
  String get anyProject => 'कोई भी प्रोजेक्ट';

  @override
  String get anyCategory => 'कोई भी श्रेणी';

  @override
  String get anyDate => 'कोई भी तारीख़';

  @override
  String get minAmount => 'कम से कम';

  @override
  String get maxAmount => 'ज़्यादा से ज़्यादा';

  @override
  String get dates => 'तारीख़ें';

  @override
  String get tags => 'टैग';

  @override
  String get showResults => 'नतीजे दिखाएँ';

  @override
  String get clearAll => 'सब हटाएँ';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नतीजे',
      one: '1 नतीजा',
    );
    return '$_temp0';
  }

  @override
  String amountFrom(String amount) {
    return '$amount से';
  }

  @override
  String amountUpTo(String amount) {
    return '$amount तक';
  }

  @override
  String amountBetween(String min, String max) {
    return '$min – $max';
  }

  @override
  String get minAboveMax => 'कम से कम रकम ज़्यादा से ज़्यादा से बड़ी है';

  @override
  String get calculator => 'कैलकुलेटर';

  @override
  String useAmount(String amount) {
    return '$amount लगाएँ';
  }

  @override
  String get calcDivideByZero => 'शून्य से भाग नहीं हो सकता';

  @override
  String get calcNegative => 'नतीजा शून्य से कम है';

  @override
  String get calcTooLarge => 'नतीजा बहुत बड़ा है';

  @override
  String get saveAndAddAnother => 'सेव करके और जोड़ें';

  @override
  String get savedAddAnother => 'सेव हो गया। अगला जोड़ें।';

  @override
  String get remindersTitle => 'रिमाइंडर';

  @override
  String remindersUpcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आने वाले',
      one: '1 आने वाला',
      zero: 'कुछ देय नहीं',
    );
    return '$_temp0';
  }

  @override
  String get remindersNotificationsOn => 'सूचनाएँ चालू';

  @override
  String get remindersNotificationsOff => 'सूचनाएँ बंद';

  @override
  String remindersSettingsSubtitle(String count, String state) {
    return '$count · $state';
  }

  @override
  String get reminderTabHistory => 'इतिहास';

  @override
  String get reminderSectionOverdue => 'बकाया';

  @override
  String get reminderSectionThisWeek => 'इस हफ़्ते';

  @override
  String get reminderSectionLater => 'बाद में';

  @override
  String get reminderAdd => 'रिमाइंडर जोड़ें';

  @override
  String get reminderFab => 'रिमाइंडर';

  @override
  String get remindersEmptyTitle => 'अभी कोई रिमाइंडर नहीं';

  @override
  String get remindersEmptyBody =>
      'बिल, किराया, ईएमआई, रिन्यूअल: एक जोड़ें, हिसाब देय तारीख़ से पहले याद दिलाएगा।';

  @override
  String get reminderHistoryEmpty => 'चुकाए और छोड़े गए रिमाइंडर यहाँ दिखेंगे।';

  @override
  String get reminderSkip => 'इस बार छोड़ें';

  @override
  String get reminderDeleted => 'रिमाइंडर हटाया गया';

  @override
  String get reminderMarkedPaid => 'चुकाया गया';

  @override
  String get reminderMarkedDone => 'पूरा हुआ';

  @override
  String get reminderSkipped => 'इस बार छोड़ा गया';

  @override
  String reminderSnoozedUntil(String date) {
    return '$date तक टाला गया';
  }

  @override
  String get reminderAlreadyDone => 'पहले ही चुकाया जा चुका है';

  @override
  String reminderPaidOn(String date) {
    return '$date को चुकाया';
  }

  @override
  String reminderDoneOn(String date) {
    return '$date को पूरा';
  }

  @override
  String reminderSkippedOn(String date) {
    return '$date को छोड़ा';
  }

  @override
  String reminderNextDue(String date) {
    return 'अगली देय तारीख़ $date';
  }

  @override
  String get notifOffBanner =>
      'सूचनाएँ बंद हैं। रिमाइंडर सिर्फ़ ऐप में दिखेंगे।';

  @override
  String get notifTurnOn => 'चालू करें';

  @override
  String get remindersLateNote =>
      'रिमाइंडर देर से आ सकते हैं। \"अलार्म और रिमाइंडर\" की अनुमति दें';

  @override
  String get exactAlarmPromptTitle => 'रिमाइंडर समय पर पाएँ';

  @override
  String get exactAlarmPromptBody =>
      'आपके चुने हुए सही समय पर सूचना देने के लिए Android को हिसाब की \"अलार्म और रिमाइंडर\" सेटिंग चाहिए। इसके बिना रिमाइंडर देर से आ सकते हैं।';

  @override
  String get notifPrePromptTitle => 'देय तारीख़ से पहले याद पाएँ';

  @override
  String get notifPrePromptBody =>
      'हिसाब आपके चुने समय पर सिर्फ़ आपके रिमाइंडर की सूचना भेजेगा। कोई विज्ञापन नहीं।';

  @override
  String reminderPaidSheetTitle(String title) {
    return '$title चुका दिया?';
  }

  @override
  String reminderPaidSheetBody(String amount) {
    return '$amount का खर्च जोड़ें और इसे चुकाया हुआ मानें।';
  }

  @override
  String get reminderAddEntryAndMark => 'एंट्री जोड़ें और चुकाया मानें';

  @override
  String get reminderJustMark => 'बस चुकाया मानें';

  @override
  String get reminderNew => 'नया रिमाइंडर';

  @override
  String get reminderEditTitle => 'रिमाइंडर बदलें';

  @override
  String get reminderKindBill => 'बिल';

  @override
  String get reminderKindEmi => 'ईएमआई';

  @override
  String get reminderKindCard => 'कार्ड बिल';

  @override
  String get reminderKindSubscription => 'सब्सक्रिप्शन';

  @override
  String get reminderKindInsurance => 'बीमा';

  @override
  String get reminderKindDocument => 'दस्तावेज़';

  @override
  String get reminderKindCustom => 'अन्य';

  @override
  String get reminderTitleLabel => 'शीर्षक';

  @override
  String get reminderTitleHint => 'जैसे बिजली का बिल';

  @override
  String get reminderTitleRequired => 'शीर्षक लिखें';

  @override
  String get reminderAmountOptional => 'राशि (वैकल्पिक)';

  @override
  String get reminderDueDate => 'देय तारीख़';

  @override
  String get reminderRepeatLabel => 'दोहराएँ';

  @override
  String get reminderRepeatOnce => 'एक बार';

  @override
  String get reminderRepeatWeekly => 'हर हफ़्ते';

  @override
  String get reminderRepeatMonthly => 'हर महीने';

  @override
  String get reminderRepeatQuarterly => 'हर 3 महीने';

  @override
  String get reminderRepeatYearly => 'हर साल';

  @override
  String get reminderNotifyLabel => 'याद दिलाएँ';

  @override
  String get reminderNotifyOnDay => 'उसी दिन';

  @override
  String reminderNotifyDaysBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन पहले',
      one: '1 दिन पहले',
    );
    return '$_temp0';
  }

  @override
  String get reminderNotifyEnabled => 'सूचना भेजें';

  @override
  String reminderNotifyAt(String time) {
    return '$time बजे';
  }

  @override
  String reminderNotifyPreview(String when) {
    return 'पहली सूचना: $when';
  }

  @override
  String get reminderNoAlertsLeft =>
      'सूचना के सारे समय निकल गए; ऐप में देय दिखेगा।';

  @override
  String get reminderPickDaysError => 'कम से कम एक दिन चुनें';

  @override
  String get reminderSave => 'रिमाइंडर सेव करें';

  @override
  String get reminderNoAccount => 'कोई खाता नहीं';

  @override
  String get reminderChannelName => 'बिल और देय तारीख़ रिमाइंडर';

  @override
  String get reminderChannelDescription =>
      'बिल, ईएमआई, कार्ड बकाया और रिन्यूअल से पहले सूचना';

  @override
  String get reminderMarkPaid => 'चुकाया';

  @override
  String get reminderMarkDone => 'हो गया';

  @override
  String get reminderSnoozeOneDay => '1 दिन टालें';

  @override
  String get reminderDueToday => 'आज देय';

  @override
  String reminderDueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन में देय',
      one: 'कल देय',
    );
    return '$_temp0';
  }

  @override
  String reminderOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन से बकाया',
      one: '1 दिन से बकाया',
    );
    return '$_temp0';
  }

  @override
  String get cardStatementDay => 'स्टेटमेंट की तारीख';

  @override
  String get cardDueDay => 'भुगतान की आखिरी तारीख';

  @override
  String get cardDayNotSet => 'सेट नहीं';

  @override
  String get cardCreditLimit => 'क्रेडिट लिमिट';

  @override
  String get cardLastStatementAmount => 'पिछले स्टेटमेंट की रकम';

  @override
  String get cardDetailsHint =>
      'स्टेटमेंट और ड्यू की तारीख से हिसाब आपका बिलिंग साइकिल दिखाएगा और बिल की तारीख से पहले याद दिलाएगा।';

  @override
  String get cardOutstanding => 'बकाया';

  @override
  String get cardThisCycle => 'इस साइकिल में';

  @override
  String cardCycleDates(String start, String end) {
    return '$start से $end';
  }

  @override
  String get cardLastStatement => 'पिछला स्टेटमेंट';

  @override
  String cardStatementOn(String date) {
    return '$date का स्टेटमेंट';
  }

  @override
  String get cardNoStatement => 'दर्ज नहीं';

  @override
  String get cardAvailableLimit => 'बची हुई लिमिट';

  @override
  String cardOverLimitBy(String amount) {
    return 'लिमिट से $amount ज़्यादा';
  }

  @override
  String cardLimitUsed(int percent, String limit) {
    return '$limit लिमिट का $percent% इस्तेमाल';
  }

  @override
  String cardDueOn(String date) {
    return 'ड्यू $date';
  }

  @override
  String get cardPaid => 'चुका दिया';

  @override
  String cardAmountLeftToPay(String amount) {
    return '$amount चुकाना बाकी';
  }

  @override
  String get cardSetUpDays => 'स्टेटमेंट और ड्यू तारीख सेट करें';

  @override
  String get cardViewTransactions => 'लेन-देन देखें';

  @override
  String get cardNotFound => 'यह कार्ड हटा दिया गया है';

  @override
  String cardNextDue(String date) {
    return 'अगला ड्यू $date';
  }

  @override
  String cardInCredit(String amount) {
    return '$amount क्रेडिट';
  }

  @override
  String cardStatementOverAmountDue(String amount) {
    return 'बकाया राशि ($amount) से ज़्यादा है। इसे उतना करें जितना अभी चुकाना बाकी है।';
  }

  @override
  String get cardBalanceOwed => 'बकाया';

  @override
  String get cardBalanceCredit => 'क्रेडिट में';

  @override
  String get cardCreditOnCard => 'कार्ड पर क्रेडिट';

  @override
  String get balanceInAccount => 'खाते में';

  @override
  String get balanceOverdrawn => 'ओवरड्रॉन';

  @override
  String get smsHistoryTitle => 'SMS इतिहास';

  @override
  String get smsHistoryHelp => 'Hisab ने जो भी मैसेज देखे और उनका क्या हुआ';

  @override
  String get smsOutcomeAdded => 'जोड़ा गया';

  @override
  String get smsOutcomeDuplicate => 'दोहराया गया';

  @override
  String get smsOutcomeIgnored => 'छोड़ा गया';

  @override
  String get smsOutcomeUnparsed => 'पढ़ा नहीं जा सका';

  @override
  String get smsOutcomePending => 'समीक्षा बाकी';

  @override
  String get smsOutcomeUndone => 'वापस लिया';

  @override
  String get smsHistoryNotBank => 'बैंक का मैसेज नहीं';

  @override
  String get smsHistoryDismissed => 'समीक्षा से हटाया गया';

  @override
  String get smsHistoryUnparsedDetail => 'मैसेज में कोई लेनदेन नहीं मिला';

  @override
  String get smsHistoryDuplicateDetail => 'यही मैसेज पहले आ चुका है';

  @override
  String get smsHistoryOpenEntry => 'एंट्री खोलें';

  @override
  String get smsHistoryReprocess => 'फिर से जाँचें';

  @override
  String get smsHistoryClear => 'इतिहास साफ़ करें';

  @override
  String get smsHistoryClearQuestion => 'SMS इतिहास साफ़ करें?';

  @override
  String smsHistoryClearBody(int count) {
    return 'इस डिवाइस से $count मैसेज का टेक्स्ट हट जाएगा। आपकी एंट्री और समीक्षा के लिए बाकी मैसेज बने रहेंगे, और साफ़ किए गए मैसेज दोबारा नहीं जोड़े जाएँगे।';
  }

  @override
  String get smsHistoryClearConfirm => 'साफ़ करें';

  @override
  String get smsHistoryCleared => 'SMS इतिहास साफ़ हो गया';

  @override
  String get smsHistoryEmptyTitle => 'अभी तक कोई मैसेज नहीं';

  @override
  String get smsHistoryEmptyBody =>
      'Hisab जो बैंक SMS पढ़ता है या आप पेस्ट करते हैं, वे यहाँ दिखेंगे।';

  @override
  String get smsHistoryEmptyFiltered => 'इस नतीजे वाला कोई मैसेज नहीं';

  @override
  String get smsHistoryTextNotKept => 'मैसेज का टेक्स्ट नहीं रखा गया';

  @override
  String get recurringRepeat => 'दोहराएँ';

  @override
  String get recurringDoesNotRepeat => 'दोहराया नहीं जाता';

  @override
  String get recurringDaily => 'रोज़';

  @override
  String get recurringWeekly => 'हर हफ़्ते';

  @override
  String get recurringMonthly => 'हर महीने';

  @override
  String get recurringYearly => 'हर साल';

  @override
  String recurringEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर $count दिन',
      one: 'हर दिन',
    );
    return '$_temp0';
  }

  @override
  String recurringEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर $count हफ़्ते',
      one: 'हर हफ़्ते',
    );
    return '$_temp0';
  }

  @override
  String recurringEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर $count महीने',
      one: 'हर महीने',
    );
    return '$_temp0';
  }

  @override
  String recurringEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर $count साल',
      one: 'हर साल',
    );
    return '$_temp0';
  }

  @override
  String recurringOnDay(int day) {
    return '$day तारीख़ को';
  }

  @override
  String get recurringOnLastDay => 'आख़िरी दिन';

  @override
  String recurringOnWeekday(String weekday) {
    return '$weekday को';
  }

  @override
  String recurringOnDate(String date) {
    return '$date को';
  }

  @override
  String recurringUntil(String date) {
    return '$date तक';
  }

  @override
  String recurringTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बार',
      one: '1 बार',
    );
    return '$_temp0';
  }

  @override
  String get recurringInterval => 'हर कितने में';

  @override
  String get recurringLastDayOfMonth => 'महीने के आख़िरी दिन';

  @override
  String get recurringEnds => 'कब ख़त्म हो';

  @override
  String get recurringEndNever => 'कभी नहीं';

  @override
  String get recurringEndOnDate => 'किसी तारीख़ को';

  @override
  String get recurringEndAfter => 'इतनी बार बाद';

  @override
  String get recurringOccurrences => 'कितनी बार';

  @override
  String get recurringAutoPost => 'अपने आप जोड़ें';

  @override
  String get recurringAutoPostHint =>
      'बंद होने पर हर बार आपकी पुष्टि का इंतज़ार होगा';

  @override
  String get recurringStopRepeating => 'न दोहराएँ';

  @override
  String get recurringDone => 'हो गया';

  @override
  String get recurringEndBeforeStart => 'शुरुआत के बाद की तारीख़ चुनें';

  @override
  String get recurringPartOfRule => 'दोहराई जाने वाली एंट्री का हिस्सा';

  @override
  String get recurringTitle => 'दोहराई जाने वाली';

  @override
  String get recurringNew => 'नई दोहराई जाने वाली';

  @override
  String get recurringEdit => 'दोहराई जाने वाली बदलें';

  @override
  String get recurringEmptyTitle => 'अभी कुछ दोहराया नहीं जाता';

  @override
  String get recurringEmptyBody =>
      'किराया, SIP, EMI या सैलरी: एक बार सेट करें, Hisab उसी दिन जोड़ देगा।';

  @override
  String get recurringSectionWaiting => 'आपका इंतज़ार';

  @override
  String get recurringSectionActive => 'चालू';

  @override
  String get recurringSectionPaused => 'रुकी हुई';

  @override
  String get recurringSectionEnded => 'ख़त्म';

  @override
  String recurringNext(String date) {
    return 'अगली $date';
  }

  @override
  String recurringDue(String date) {
    return 'देय $date';
  }

  @override
  String recurringMoreWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'और $count बाक़ी',
      one: 'और 1 बाक़ी',
    );
    return '$_temp0';
  }

  @override
  String get recurringConfirm => 'जोड़ें';

  @override
  String get recurringSkip => 'छोड़ें';

  @override
  String get recurringPause => 'रोकें';

  @override
  String get recurringResume => 'फिर शुरू करें';

  @override
  String get recurringDeleted => 'दोहराई जाने वाली एंट्री हटाई गई';

  @override
  String get recurringAdded => 'एंट्री जोड़ी गई';

  @override
  String get recurringSkipped => 'छोड़ दी गई';

  @override
  String recurringToConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दोहराई जाने वाली एंट्री पुष्टि के लिए',
      one: '1 दोहराई जाने वाली एंट्री पुष्टि के लिए',
    );
    return '$_temp0';
  }

  @override
  String recurringPostedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बार जोड़ी गई',
      one: 'एक बार जोड़ी गई',
      zero: 'अभी नहीं जोड़ी गई',
    );
    return '$_temp0';
  }

  @override
  String get recurringNameLabel => 'नाम (वैकल्पिक)';

  @override
  String get recurringNextOn => 'अगली तारीख़';

  @override
  String get recurringRuleMissing => 'यह दोहराई जाने वाली एंट्री हटा दी गई है';

  @override
  String recurringDecrease(String label) {
    return '$label घटाएँ';
  }

  @override
  String recurringIncrease(String label) {
    return '$label बढ़ाएँ';
  }

  @override
  String get subscriptions => 'सब्सक्रिप्शन';

  @override
  String get subscriptionsMonthlyTotal => 'हर महीने';

  @override
  String get subscriptionsYearlyTotal => 'हर साल';

  @override
  String subscriptionsActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चालू सब्सक्रिप्शन',
      one: '1 चालू सब्सक्रिप्शन',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionsEmptyTitle => 'अभी कोई सब्सक्रिप्शन नहीं';

  @override
  String get subscriptionsEmptyBody =>
      'Netflix, मोबाइल रिचार्ज या जिम जोड़ें और देखें कि हर महीने और हर साल कितना खर्च होता है।';

  @override
  String get subscriptionAdd => 'सब्सक्रिप्शन जोड़ें';

  @override
  String get subscriptionEdit => 'सब्सक्रिप्शन बदलें';

  @override
  String get subscriptionPickService => 'सेवा चुनें';

  @override
  String get subscriptionCustom => 'कुछ और';

  @override
  String get subscriptionPrice => 'हर रिन्यूअल की कीमत';

  @override
  String get subscriptionCycle => 'रिन्यू होता है';

  @override
  String get subscriptionNextRenewal => 'अगला रिन्यूअल';

  @override
  String subscriptionStartedOn(String date) {
    return '$date से शुरू';
  }

  @override
  String get subscriptionAutoPost => 'हर रिन्यूअल पर खर्च में जोड़ें';

  @override
  String get subscriptionAutoPostHelp =>
      'बंद: सिर्फ़ यहाँ दिखेगा, कोई एंट्री नहीं जुड़ेगी';

  @override
  String get subscriptionNameRequired => 'नाम डालें';

  @override
  String get subscriptionPriceRequired => 'कीमत डालें';

  @override
  String subscriptionRenewsOn(String date) {
    return '$date को रिन्यू';
  }

  @override
  String get subscriptionRenewsToday => 'आज रिन्यू';

  @override
  String subscriptionRenewsInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन में रिन्यू',
      one: 'कल रिन्यू',
    );
    return '$_temp0';
  }

  @override
  String subscriptionOverdue(String date) {
    return '$date को देय था';
  }

  @override
  String get subscriptionPaused => 'रुका हुआ';

  @override
  String get subscriptionCancelled => 'रद्द';

  @override
  String get subscriptionPause => 'रोकें';

  @override
  String get subscriptionResume => 'फिर शुरू करें';

  @override
  String get subscriptionMarkCancelled => 'रद्द मार्क करें';

  @override
  String subscriptionCancelConfirm(String name) {
    return '$name को रद्द मार्क करें?';
  }

  @override
  String get subscriptionCancelConfirmBody =>
      'नए खर्च नहीं जुड़ेंगे और यह कुल में नहीं गिना जाएगा। पुरानी एंट्री बनी रहेंगी।';

  @override
  String get subscriptionDeleted => 'सब्सक्रिप्शन हटाया गया';

  @override
  String subscriptionPerMonth(String amount) {
    return '$amount/महीना';
  }

  @override
  String get subscriptionSort => 'क्रम';

  @override
  String get subscriptionSortCostHigh => 'कीमत: ज़्यादा से कम';

  @override
  String get subscriptionSortCostLow => 'कीमत: कम से ज़्यादा';

  @override
  String get subscriptionSortRenewal => 'अगला रिन्यूअल';

  @override
  String get subscriptionSortName => 'नाम';

  @override
  String subscriptionEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर $count दिन',
      one: 'रोज़',
    );
    return '$_temp0';
  }

  @override
  String subscriptionEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर $count हफ़्ते',
      one: 'हर हफ़्ते',
    );
    return '$_temp0';
  }

  @override
  String subscriptionEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर $count महीने',
      one: 'हर महीने',
    );
    return '$_temp0';
  }

  @override
  String subscriptionEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर $count साल',
      one: 'हर साल',
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
  String get subscriptionTemplateMobileRecharge => 'मोबाइल रिचार्ज';

  @override
  String get subscriptionTemplateDth => 'DTH';

  @override
  String get subscriptionTemplateBroadband => 'ब्रॉडबैंड';

  @override
  String get subscriptionTemplateGym => 'जिम';

  @override
  String get subscriptionTemplateCloudStorage => 'क्लाउड स्टोरेज';

  @override
  String get subscriptionTemplateNewsApp => 'न्यूज़ ऐप';

  @override
  String get payersMultiple => '2+ लोग';

  @override
  String get payersHelp => 'हर व्यक्ति ने कितना दिया, लिखें।';

  @override
  String payersAssigned(String assigned, String total) {
    return '$total में से $assigned दर्ज';
  }

  @override
  String payersMustTotal(String total) {
    return 'दी गई रकम का जोड़ $total होना चाहिए';
  }

  @override
  String namesAnd(String first, String last) {
    return '$first और $last';
  }

  @override
  String get youInList => 'आप';

  @override
  String get groupTotalsTitle => 'ग्रुप का कुल हिसाब';

  @override
  String get groupTotalsAllTime => 'अब तक';

  @override
  String get groupTotalsTotalSpent => 'ग्रुप का कुल खर्च';

  @override
  String get groupTotalsYouPaid => 'आपने चुकाया';

  @override
  String get groupTotalsYourShare => 'आपका हिस्सा';

  @override
  String get groupTotalsNetChange => 'आपके बैलेंस में बदलाव';

  @override
  String get groupTotalsPaymentsMade => 'आपके किए भुगतान';

  @override
  String get groupTotalsPaymentsReceived => 'आपको मिले भुगतान';

  @override
  String get groupTotalsByMember => 'सदस्यवार चुकाया और हिस्सा';

  @override
  String get groupTotalsPaid => 'चुकाया';

  @override
  String get groupTotalsShare => 'हिस्सा';

  @override
  String get groupTotalsEmpty => 'इस अवधि में कोई खर्च नहीं';

  @override
  String groupTotalsExpenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खर्च',
      one: '1 खर्च',
    );
    return '$_temp0';
  }

  @override
  String groupTotalsMemberRow(String name, String paid, String share) {
    return '$name: चुकाया $paid, हिस्सा $share';
  }

  @override
  String get groupTotalsOpen => 'पूरा हिसाब देखें';

  @override
  String get groupSettingsTitle => 'ग्रुप सेटिंग्स';

  @override
  String get groupSettingsType => 'प्रकार';

  @override
  String get groupTypeTrip => 'यात्रा';

  @override
  String get groupTypeHome => 'घर';

  @override
  String get groupTypeCouple => 'कपल';

  @override
  String get groupTypeOther => 'अन्य';

  @override
  String get groupSettingsIcon => 'आइकन';

  @override
  String get groupSettingsDefaultSplit => 'डिफ़ॉल्ट बँटवारा';

  @override
  String get groupSettingsDefaultSplitHint =>
      'नए खर्चों के लिए पहले से चुना रहेगा। पहले से जोड़े गए खर्चों का बँटवारा नहीं बदलेगा।';

  @override
  String get groupSettingsWeights => 'हर सदस्य के हिस्से';

  @override
  String groupSettingsWeightValue(num count, String weight) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$weight हिस्से',
      one: '1 हिस्सा',
    );
    return '$_temp0';
  }

  @override
  String groupSettingsWeightLess(String name) {
    return '$name के हिस्से घटाएँ';
  }

  @override
  String groupSettingsWeightMore(String name) {
    return '$name के हिस्से बढ़ाएँ';
  }

  @override
  String get groupSettingsCurrency => 'मुद्रा चिह्न';

  @override
  String get groupSettingsCurrencyHint =>
      'सिर्फ़ इस ग्रुप में दिखने वाला चिह्न बदलता है। रकम बदली नहीं जाती।';

  @override
  String groupSettingsCurrencyAppDefault(String symbol) {
    return 'ऐप जैसा ($symbol)';
  }

  @override
  String get groupSettingsCurrencyOther => 'दूसरा चिह्न';

  @override
  String get groupSettingsSimplify => 'उधार सरल करें';

  @override
  String get groupSettingsSimplifyBody =>
      'उधार को जोड़कर ग्रुप में कम भुगतान करने पड़ते हैं। अगर आशा को रवि को देना है और रवि को मीना को, तो आशा सीधे मीना को दे सकती है। किसी का कुल लेना-देना नहीं बदलता।';

  @override
  String groupSettingsSimplifySaves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'अभी $count भुगतान बचते हैं',
      one: 'अभी 1 भुगतान बचता है',
    );
    return '$_temp0';
  }

  @override
  String get groupSettingsNotes => 'नोट्स';

  @override
  String get groupSettingsNotesHint =>
      'वाई-फ़ाई पासवर्ड, घर के नियम, यात्रा का प्लान';

  @override
  String get groupSettingsNotesAdd => 'इस ग्रुप के लिए नोट जोड़ें';

  @override
  String get groupSettingsManage => 'ग्रुप प्रबंधन';

  @override
  String get groupArchive => 'ग्रुप आर्काइव करें';

  @override
  String groupArchiveTitle(String name) {
    return '$name आर्काइव करें?';
  }

  @override
  String get groupArchiveBody =>
      'ग्रुप, ग्रुप सूची में \'आर्काइव\' में चला जाएगा। कुछ नहीं हटेगा, और आप इसे कभी भी आर्काइव से निकाल सकते हैं।';

  @override
  String get groupArchiveConfirm => 'आर्काइव करें';

  @override
  String get groupUnarchive => 'आर्काइव से निकालें';

  @override
  String get groupArchivedBanner =>
      'यह ग्रुप आर्काइव है। खर्च जोड़ने के लिए इसे आर्काइव से निकालें।';

  @override
  String get groupLeftBanner =>
      'आपने यह ग्रुप छोड़ दिया है। इसका इतिहास यहीं रहेगा।';

  @override
  String groupArchivedSection(int count) {
    return 'आर्काइव ($count)';
  }

  @override
  String get groupLeave => 'ग्रुप छोड़ें';

  @override
  String groupLeaveTitle(String name) {
    return '$name छोड़ें?';
  }

  @override
  String get groupLeaveBody =>
      'आप इस फ़ोन पर ग्रुप से हट जाएँगे और ग्रुप आर्काइव में चला जाएगा, ताकि इसका इतिहास पढ़ा जा सके।';

  @override
  String get groupLeaveConfirm => 'छोड़ें';

  @override
  String get groupLeaveBlocked =>
      'पहले हिसाब चुकता करें। जब न आपको किसी से लेना हो, न किसी को देना, तब ग्रुप छोड़ सकते हैं।';

  @override
  String get groupDeleteUnsettledBody =>
      'इस ग्रुप में अभी हिसाब बाकी है। हटाने पर सभी खर्च और भुगतान हट जाएँगे, और यह वापस नहीं होगा।';

  @override
  String get groupEmptyTrip =>
      'टिकट, ठहरने और खाने के खर्च जैसे-जैसे हों, जोड़ते जाएँ; किसे कितना देना है, Hisab हिसाब लगा देगा।';

  @override
  String get groupEmptyHome =>
      'किराया, बिल और राशन जोड़ें; किसे कितना देना है, Hisab हिसाब लगा देगा।';

  @override
  String get groupEmptyCouple =>
      'साथ के खाने, राशन और घूमने के खर्च जोड़ें; Hisab हिसाब रखेगा।';

  @override
  String get activityTitle => 'गतिविधि';

  @override
  String get activityEmptyTitle => 'अभी कोई गतिविधि नहीं';

  @override
  String get activityEmptyBody =>
      'आप जो खर्च और भुगतान जोड़ते, बदलते या हटाते हैं, वे यहाँ दिखेंगे।';

  @override
  String activityExpenseAdded(String actor, String title) {
    return '$actor ने “$title” जोड़ा';
  }

  @override
  String activityExpenseEdited(String actor, String title) {
    return '$actor ने “$title” बदला';
  }

  @override
  String activityExpenseDeleted(String actor, String title) {
    return '$actor ने “$title” हटाया';
  }

  @override
  String activityExpenseRestored(String actor, String title) {
    return '$actor ने “$title” वापस लाया';
  }

  @override
  String activityPaymentAdded(String actor) {
    return '$actor ने भुगतान दर्ज किया';
  }

  @override
  String activityPaymentEdited(String actor) {
    return '$actor ने भुगतान बदला';
  }

  @override
  String activityPaymentDeleted(String actor) {
    return '$actor ने भुगतान हटाया';
  }

  @override
  String activityPaymentRestored(String actor) {
    return '$actor ने भुगतान वापस लाया';
  }

  @override
  String activityExpenseLine(String amount, String payers) {
    return '$amount · भुगतान: $payers';
  }

  @override
  String activityPaymentLine(String from, String to, String amount) {
    return '$from ने $to को $amount दिए';
  }

  @override
  String activityChangeAmount(String from, String to) {
    return 'राशि: $from → $to';
  }

  @override
  String activityChangeDate(String from, String to) {
    return 'तारीख: $from → $to';
  }

  @override
  String activityChangeDescription(String from, String to) {
    return 'विवरण: $from → $to';
  }

  @override
  String activityChangeCategory(String from, String to) {
    return 'श्रेणी: $from → $to';
  }

  @override
  String activityChangePayers(String from, String to) {
    return 'भुगतान किया: $from → $to';
  }

  @override
  String activityPayerAmount(String name, String amount) {
    return '$name $amount';
  }

  @override
  String activityChangeShare(String name, String from, String to) {
    return '$name का हिस्सा: $from → $to';
  }

  @override
  String activityChangeMyShare(String from, String to) {
    return 'आपका हिस्सा: $from → $to';
  }

  @override
  String activityChangeParties(String from, String to) {
    return 'किसने किसे दिया: $from → $to';
  }

  @override
  String activityPartiesPair(String from, String to) {
    return '$from से $to को';
  }

  @override
  String activityChangeMethod(String from, String to) {
    return 'तरीका: $from → $to';
  }

  @override
  String activityChangeNote(String from, String to) {
    return 'नोट: $from → $to';
  }

  @override
  String get activityNone => 'कुछ नहीं';

  @override
  String get activityRestore => 'वापस लाएँ';

  @override
  String get activityExpenseRestoredSnack => 'खर्च वापस आ गया';

  @override
  String get activityExpenseDeletedSnack => 'खर्च हटाया गया';

  @override
  String get activityAllGroups => 'सभी ग्रुप';

  @override
  String activityGroupDeleted(String actor, String name) {
    return '$actor ने ग्रुप “$name” हटाया';
  }

  @override
  String activityGroupRestored(String actor, String name) {
    return '$actor ने ग्रुप “$name” वापस लाया';
  }

  @override
  String activityGroupEdited(String actor, String name) {
    return '$actor ने ग्रुप “$name” बदला';
  }

  @override
  String activityGroupLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खर्च',
      one: '1 खर्च',
      zero: 'कोई खर्च नहीं',
    );
    return '$_temp0';
  }

  @override
  String get activityPaymentRestoredSnack => 'भुगतान वापस आ गया';

  @override
  String get activityGroupRestoredSnack => 'ग्रुप वापस आ गया';

  @override
  String get activityGroupDeletedSnack => 'ग्रुप हटाया गया';

  @override
  String recurringAddedSkipped(int added, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      added,
      locale: localeName,
      other: '$added जोड़ी गईं',
      one: '1 जोड़ी गई',
      zero: 'कोई नहीं जोड़ी गई',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped छोड़ी गईं',
      one: '1 छोड़ी गई',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get groupExportCsv => 'CSV फ़ाइल के रूप में एक्सपोर्ट करें';

  @override
  String groupExportCsvSubject(String group) {
    return '$group के खर्च';
  }

  @override
  String get groupExportFailed => 'CSV एक्सपोर्ट नहीं हो सका';

  @override
  String get groupCsvDate => 'तारीख';

  @override
  String get groupCsvDescription => 'विवरण';

  @override
  String get groupCsvCost => 'राशि';

  @override
  String get groupCsvPaidBy => 'किसने दिया';

  @override
  String groupCsvPaidColumn(String name) {
    return '$name ने दिया';
  }

  @override
  String groupCsvShareColumn(String name) {
    return '$name का हिस्सा';
  }

  @override
  String groupCsvBalanceColumn(String name) {
    return '$name का बैलेंस';
  }

  @override
  String get groupCsvPayment => 'भुगतान';

  @override
  String get groupSummaryWhoPaysWhom => 'किसे किसको देना है';

  @override
  String get groupSummaryStandings => 'किसका कितना हिसाब';

  @override
  String groupSummaryYouOwe(String name, String amount) {
    return 'आपको $name को $amount देने हैं';
  }

  @override
  String groupSummaryOwesYou(String name, String amount) {
    return '$name को आपको $amount देने हैं';
  }

  @override
  String groupSummaryGetsBack(String name, String amount) {
    return '$name को $amount वापस मिलेंगे';
  }

  @override
  String groupSummaryOwesInTotal(String name, String amount) {
    return '$name को कुल $amount देने हैं';
  }

  @override
  String groupSummaryYouGetBack(String amount) {
    return 'आपको $amount वापस मिलेंगे';
  }

  @override
  String groupSummaryYouOweInTotal(String amount) {
    return 'आपको कुल $amount देने हैं';
  }

  @override
  String get groupCsvTotal => 'कुल';

  @override
  String groupSummaryGroupTotal(String amount) {
    return 'ग्रुप का कुल खर्च: $amount';
  }

  @override
  String groupSummaryYourShare(String amount) {
    return 'आपका हिस्सा: $amount';
  }

  @override
  String groupSummaryMemberShare(String name, String amount) {
    return '$name का हिस्सा: $amount';
  }

  @override
  String get byItemShared => 'साझा';

  @override
  String get byItemSharedHelp => 'जिनके पास कोई आइटम है, उनमें बराबर बँटेगा';

  @override
  String get byItemOnlyMe => 'सिर्फ़ मैं';

  @override
  String get byItemEveryone => 'सभी';

  @override
  String get byItemAddExtras => 'डिलीवरी, टैक्स या टिप';

  @override
  String get byItemHint => 'आइटम के हिसाब से बाँटने के लिए आइटम जोड़ें';

  @override
  String byItemSummary(String amount, int count, int percent) {
    return '$amount · $count आइटम · $percent%';
  }

  @override
  String get byItemClearTitle => 'आइटम का बँटवारा हट जाएगा';

  @override
  String get byItemClearBody =>
      'आइटम बने रहेंगे, और हर आइटम फिर सब में बँटेगा।';

  @override
  String get smsAddedMarker => 'एसएमएस से जोड़ा गया';

  @override
  String smsAutoAddedOne(String amount) {
    return 'एसएमएस से $amount जोड़ा गया';
  }

  @override
  String smsAutoAddedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'एसएमएस से $count एंट्री जोड़ी गईं',
      one: 'एसएमएस से 1 एंट्री जोड़ी गई',
    );
    return '$_temp0';
  }

  @override
  String get smsReviewTitle => 'समीक्षा के लिए एसएमएस';

  @override
  String get smsReviewHelp =>
      'ये संदेश अपने-आप जोड़ने लायक साफ़ नहीं थे। हर एक को जोड़ें, बदलें या अनदेखा करें।';

  @override
  String get smsReviewUnread => 'रकम पढ़ी नहीं जा सकी';

  @override
  String get smsReviewAddManually => 'खुद जोड़ें';

  @override
  String upcomingEmptyWithin(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'अगले $days दिनों में कुछ देय नहीं',
      one: 'कल कुछ देय नहीं',
    );
    return '$_temp0';
  }

  @override
  String get upcomingEmptyHint =>
      'दोहराए जाने वाले बिल, रिमाइंडर और कार्ड की देय तारीख़ें यहाँ दिखेंगी।';

  @override
  String upcomingWindowDays(int days) {
    return '$days दिन';
  }

  @override
  String upcomingOverdueBy(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन से बकाया',
      one: '1 दिन से बकाया',
    );
    return '$_temp0';
  }

  @override
  String get upcomingDueToday => 'आज देय';

  @override
  String get upcomingDueTomorrow => 'कल देय';

  @override
  String upcomingDueInDays(int days, String date) {
    return '$days दिन में · $date';
  }

  @override
  String upcomingOverdueCount(int count) {
    return '$count बकाया';
  }

  @override
  String upcomingDueTotal(String amount) {
    return '$amount चुकाने हैं';
  }

  @override
  String upcomingShowAll(int count) {
    return '$count और';
  }

  @override
  String get upcomingCalendar => 'देय कैलेंडर';

  @override
  String get upcomingCalendarOpen => 'देय कैलेंडर खोलें';

  @override
  String get upcomingCalendarDayEmpty => 'इस दिन कुछ देय नहीं';

  @override
  String get upcomingCalendarPreviousMonth => 'पिछला महीना';

  @override
  String get upcomingCalendarNextMonth => 'अगला महीना';

  @override
  String get upcomingConfirm => 'पुष्टि करें';

  @override
  String get upcomingConfirmPrompt =>
      'यह आपकी पुष्टि का इंतज़ार कर रहा है। इसे अभी अपनी एंट्री में जोड़ें?';

  @override
  String upcomingCalendarDueCount(int count) {
    return '$count देय';
  }

  @override
  String get salaryTitle => 'वेतन';

  @override
  String get salarySetUp => 'वेतन का दिन सेट करें';

  @override
  String get salaryIntro =>
      'हिसाब आपके वेतन को मासिक आय के रूप में जोड़ता है जिसे आप पक्का करते हैं, और न आने पर धीरे से याद दिलाता है।';

  @override
  String salarySummary(String amount, int day) {
    return 'दिन $day को $amount';
  }

  @override
  String get salaryAmount => 'मासिक वेतन';

  @override
  String get salaryAccount => 'किस खाते में आता है';

  @override
  String get salaryAnyAccount => 'कोई भी खाता';

  @override
  String get salaryDay => 'वेतन का दिन';

  @override
  String get salaryShiftLabel => 'छुट्टी या सप्ताहांत पड़ने पर';

  @override
  String get salaryShiftSameDay => 'उसी दिन';

  @override
  String get salaryShiftPrevious => 'पिछला कामकाजी दिन';

  @override
  String get salaryShiftNext => 'अगला कामकाजी दिन';

  @override
  String get salaryHolidays => 'बैंक छुट्टियाँ';

  @override
  String get salaryHolidaysHelp =>
      'वेतन का दिन खिसकने पर इन्हें सप्ताहांत की तरह छोड़ा जाता है';

  @override
  String get salaryAddHoliday => 'छुट्टी जोड़ें';

  @override
  String get salaryReminder => 'न आने पर याद दिलाएँ';

  @override
  String get salaryReminderDelay => 'कब याद दिलाएँ';

  @override
  String salaryDaysAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन बाद',
      one: '1 दिन बाद',
    );
    return '$_temp0';
  }

  @override
  String get salaryAligned => 'आपका महीना पहले से वेतन के दिन से शुरू होता है';

  @override
  String salaryNotAligned(int monthStart, int salaryDay) {
    return 'आपका महीना दिन $monthStart से शुरू होता है, वेतन दिन $salaryDay को आता है';
  }

  @override
  String salaryAlignTitle(int day) {
    return 'महीना दिन $day से शुरू करें?';
  }

  @override
  String get salaryAlignMessage =>
      'बजट और मासिक कुल एक वेतन से अगले वेतन तक गिने जाएँगे।';

  @override
  String get salaryAlignAction => 'मिलाएँ';

  @override
  String get salaryRemove => 'वेतन हटाएँ';

  @override
  String get salaryRemoveBody =>
      'वेतन नियम हटा दिया जाएगा। आपकी पहले की वेतन प्रविष्टियाँ बनी रहेंगी।';

  @override
  String get salaryRemoved => 'वेतन हटाया गया';

  @override
  String get salarySaved => 'वेतन सहेजा गया';

  @override
  String salaryExpectedOn(String date) {
    return 'अपेक्षित $date';
  }

  @override
  String salaryReceivedAmount(String date, String amount) {
    return '$date को $amount मिला';
  }

  @override
  String salaryLateSince(String date) {
    return 'देर हो गई: $date को अपेक्षित था';
  }

  @override
  String salaryLastReceived(String date, String amount) {
    return 'पिछली बार $date को $amount मिला';
  }

  @override
  String salaryNextExpected(String date) {
    return 'अगला अपेक्षित $date';
  }

  @override
  String get salaryNotSeenTitle => 'वेतन अभी नहीं दिखा';

  @override
  String salaryNotSeenBody(String date) {
    return 'यह $date को आना था। आते ही यह अपने आप हट जाएगा।';
  }

  @override
  String get salaryRuleName => 'वेतन';

  @override
  String get salaryMatchWindow => 'कितने दिन पहले आ सकता है';

  @override
  String salaryMatchWindowDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन तक',
      one: '1 दिन तक',
    );
    return '$_temp0';
  }

  @override
  String get salaryTolerance => 'रकम में कितना फ़र्क चलेगा';

  @override
  String salaryTolerancePercent(int percent) {
    return '$percent% तक';
  }

  @override
  String get salaryToleranceExact => 'सिर्फ़ यही रकम';

  @override
  String get salaryDetectionHelp =>
      'कोई आमदनी वेतन मानी जाती है जब रकम इतनी क़रीब हो और वह इससे पहले न आए, या इस चक्र में बाद में कभी भी आए।';

  @override
  String get documentRemindersSection => 'दस्तावेज़ और नवीनीकरण';

  @override
  String get documentRemindersHint =>
      'पीयूसी, बीमा, पासपोर्ट और अन्य समाप्ति तिथियाँ';

  @override
  String get documentPresetVehicleInsurance => 'वाहन बीमा';

  @override
  String get documentPresetPuc => 'पीयूसी प्रमाणपत्र';

  @override
  String get documentPresetRcRenewal => 'आरसी नवीनीकरण';

  @override
  String get documentPresetDrivingLicence => 'ड्राइविंग लाइसेंस';

  @override
  String get documentPresetPassport => 'पासपोर्ट';

  @override
  String get documentPresetHealthInsurance => 'स्वास्थ्य बीमा प्रीमियम';

  @override
  String get documentPresetLifeInsurance => 'जीवन बीमा प्रीमियम';

  @override
  String get documentPresetWarranty => 'वारंटी समाप्ति';

  @override
  String get documentPresetAmc => 'एएमसी नवीनीकरण';

  @override
  String get documentPresetFdMaturity => 'एफ़डी परिपक्वता';

  @override
  String get documentPresetPropertyTax => 'संपत्ति कर';

  @override
  String get documentPresetRentAgreement => 'किराया अनुबंध नवीनीकरण';

  @override
  String get documentNumberLabel => 'दस्तावेज़ संख्या (वैकल्पिक)';

  @override
  String get documentNumberHint => 'पॉलिसी, पंजीकरण या प्रमाणपत्र संख्या';

  @override
  String get documentRemindersOnProject => 'रिमाइंडर';

  @override
  String get reminderRepeatHalfYearly => 'हर 6 महीने';

  @override
  String get reminderRepeatElevenMonths => 'हर 11 महीने';

  @override
  String get reminderRepeatFiveYears => 'हर 5 साल';

  @override
  String get reminderRepeatTenYears => 'हर 10 साल';

  @override
  String get documentPucOlderVehicleHint =>
      'पुराने वाहनों (BS-IV से पहले) को हर 6 महीने पीयूसी चाहिए।';

  @override
  String settleReminderTitle(String group) {
    return 'हिसाब बराबर करें: $group';
  }

  @override
  String settleReminderOwesYou(String name, String amount) {
    return '$name को आपको $amount देने हैं';
  }

  @override
  String settleReminderYouOwe(String name, String amount) {
    return 'आपको $name को $amount देने हैं';
  }

  @override
  String settleReminderPeopleOweYou(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count लोगों को आपको $amount देने हैं',
      one: '1 व्यक्ति को आपको $amount देने हैं',
    );
    return '$_temp0';
  }

  @override
  String settleReminderYouOweTotal(String amount) {
    return 'आपको कुल $amount देने हैं';
  }

  @override
  String get settleReminderSheetTitle => 'हिसाब बराबर करने की याद दिलाएँ';

  @override
  String get settleReminderWith => 'किसके बारे में';

  @override
  String get settleReminderEveryone => 'सभी';

  @override
  String get settleReminderHowOften => 'कितनी बार';

  @override
  String get settleReminderMonthly => 'हर महीने';

  @override
  String get settleReminderWeekly => 'हर हफ़्ते';

  @override
  String get settleReminderOnDay => 'तारीख़';

  @override
  String get settleReminderLastDay => 'आख़िरी दिन';

  @override
  String settleReminderNextAt(String date) {
    return 'अगली याद: $date';
  }

  @override
  String get settleReminderTurnOff => 'बंद करें';

  @override
  String get settleReminderOffLabel => 'हिसाब की याद बंद है';

  @override
  String settleReminderMonthlySummary(String day) {
    return 'हर महीने $day तारीख़ को याद';
  }

  @override
  String settleReminderWeeklySummary(String weekday) {
    return 'हर $weekday को याद';
  }

  @override
  String get settleReminderMonthlyLastDaySummary =>
      'हर महीने के आख़िरी दिन याद';

  @override
  String get groupRecurringAmountFixed =>
      'इस बँटवारे में तय रकमें हैं, इसलिए यहाँ कुल रकम नहीं बदल सकती';

  @override
  String get groupRecurringUpcoming => 'दोहराए जाने वाले';

  @override
  String get settleReminderShareNudge => 'याद दिलाने वाला संदेश भेजें';

  @override
  String get groupRecurringExpenseOnly =>
      'ग्रुप का दोहराने वाला नियम सिर्फ़ खर्च हो सकता है।';

  @override
  String groupRecurringYourShare(String amount) {
    return 'आपका हिस्सा $amount';
  }

  @override
  String get settleReminderPrePromptTitle => 'हिसाब बराबर करने की याद पाएँ';

  @override
  String get settleReminderPrePromptBody =>
      'हिसाब आपके चुने दिन पर सिर्फ़ इस ग्रुप का हिसाब बराबर करने की याद दिलाएगा। कोई विज्ञापन नहीं।';

  @override
  String get smsReminderPaidViaSms => 'एसएमएस से भुगतान हुआ';

  @override
  String get numberFormatTitle => 'संख्या फ़ॉर्मैट';

  @override
  String get numberFormatAutomatic => 'अपने-आप';

  @override
  String get numberFormatAutomaticHelp => 'आपकी मुद्रा और क्षेत्र के हिसाब से';
}
