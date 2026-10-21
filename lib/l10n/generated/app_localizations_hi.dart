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
  String get tabHome => 'घर';

  @override
  String get tabEntries => 'प्रविष्टियां';

  @override
  String get tabGroups => 'समूह';

  @override
  String get tabSettings => 'सेटिंग्स';

  @override
  String get cancel => 'रद्द करना';

  @override
  String get save => 'बचाना';

  @override
  String get delete => 'मिटाना';

  @override
  String get remove => 'निकालना';

  @override
  String get edit => 'संपादन करना';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get add => 'जोड़ना';

  @override
  String get ignore => 'अनदेखा करना';

  @override
  String get allow => 'अनुमति दें';

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get ok => 'ठीक है';

  @override
  String get name => 'नाम';

  @override
  String get note => 'टिप्पणी';

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
  String get manage => 'प्रबंधित करना';

  @override
  String get kindExpense => 'व्यय';

  @override
  String get kindIncome => 'आय';

  @override
  String get kindTransfer => 'स्थानांतरण';

  @override
  String get kindExpenses => 'खर्च';

  @override
  String get kindTransfers => 'स्थानांतरण';

  @override
  String get uncategorised => 'अवर्गीकृत';

  @override
  String yourShareOf(String group) {
    return '$group · आपका हिस्सा';
  }

  @override
  String get sourceSms => 'SMS';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आइटम',
      one: '1 समान',
    );
    return '$_temp0';
  }

  @override
  String get accountTypeBank => 'बैंक खाता';

  @override
  String get accountTypeCard => 'क्रेडिट कार्ड';

  @override
  String get accountTypeWallet => 'वॉलेट/यूपीआई';

  @override
  String get accountTypeCash => 'नकद';

  @override
  String get accounts => 'हिसाब किताब';

  @override
  String get account => 'खाता';

  @override
  String get newAccount => 'नया खाता';

  @override
  String get editAccount => 'खाता संपादित करें';

  @override
  String get accountNameHint => 'एचडीएफसी सेविंग्स, पेटीएम, कैश';

  @override
  String get outstandingBalance => 'कार्ड पर बकाया राशि';

  @override
  String cardDue(String amount) {
    return 'बकाया $amount';
  }

  @override
  String get currentBalance => 'वर्तमान शेष';

  @override
  String get includeInTotal => 'कुल शेष में शामिल करें';

  @override
  String get excludedFromTotal => 'कुल से बाहर रखा गया';

  @override
  String asOf(String date) {
    return '$date तक';
  }

  @override
  String get noAccountsTitle => 'अभी तक कोई खाता नहीं';

  @override
  String get noAccountsBody =>
      'एसएमएस से पता लगाए गए बैंक खाते स्वचालित रूप से उनके रिपोर्ट किए गए शेष के साथ जुड़ जाते हैं। मैन्युअल प्रविष्टियाँ आपके द्वारा चुने गए खाते के शेष को समायोजित करती हैं।';

  @override
  String deleteNamed(String name) {
    return '$name हटाएं?';
  }

  @override
  String get budgets => 'बजट';

  @override
  String get budget => 'बजट';

  @override
  String get overall => 'कुल मिलाकर';

  @override
  String get category => 'वर्ग';

  @override
  String get overallMonthlyBudget => 'कुल मिलाकर मासिक बजट';

  @override
  String get budgetForCategory => 'एक वर्ग के लिए बजट';

  @override
  String get overallMonthlyLimit => 'कुल मिलाकर मासिक सीमा';

  @override
  String categoryMonthlyLimit(String category) {
    return '$category मासिक सीमा';
  }

  @override
  String get noBudgetsTitle => 'अभी कोई बजट नहीं है';

  @override
  String get noBudgetsBody =>
      'समग्र या प्रति श्रेणी एक मासिक सीमा निर्धारित करें। डैशबोर्ड गति दिखाता है और क्या बचा है।';

  @override
  String get removeBudgetQuestion => 'यह बजट निकालें?';

  @override
  String budgetOverBy(String amount) {
    return '$amount से अधिक';
  }

  @override
  String budgetLeftOf(String left, String limit) {
    return '$limit में से $left बचे';
  }

  @override
  String budgetLeftWithDays(String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '1 दिन',
    );
    return '$amount बचे · $_temp0';
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
      'मौजूदा प्रविष्टियाँ अपनी मात्रा रखती हैं लेकिन अवर्गीकृत हो जाती हैं।';

  @override
  String get archiveCategory => 'पुरालेख (पिकर से छिपाएँ)';

  @override
  String get unarchive => 'संग्रह से निकालें';

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
  String get unitsForItems => 'वस्तुओं के लिए इकाइयाँ (अल्पविराम से अलग)';

  @override
  String get colour => 'रंग';

  @override
  String get icon => 'आइकन';

  @override
  String get searchCategories => 'श्रेणियां खोजें';

  @override
  String get noMatchingCategory => 'कोई मेल खाती श्रेणी नहीं';

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
      other: '$count समीक्षा के लिए एसएमएस करें',
      one: 'समीक्षा के लिए 1 एसएमएस',
    );
    return '$_temp0';
  }

  @override
  String get spentThisMonth => 'इस महीने बिताया';

  @override
  String get income => 'आय';

  @override
  String get saved => 'सहेजा गया';

  @override
  String get overspent => 'अधिव्यय';

  @override
  String get balances => 'शेष';

  @override
  String get spendingByCategory => 'श्रेणी के अनुसार खर्च';

  @override
  String get recent => 'हाल ही का';

  @override
  String get noEntriesThisMonthTitle => 'इस महीने कोई प्रविष्टि नहीं';

  @override
  String get noEntriesThisMonthBody =>
      'अपना पहला खर्च जोड़ने के लिए + टैप करें, या सेटिंग्स में एसएमएस रीडिंग चालू करें।';

  @override
  String get newEntry => 'नई प्रविष्टि';

  @override
  String get editEntry => 'प्रविष्टि संपादित करें';

  @override
  String get groupExpense => 'समूह व्यय';

  @override
  String get deleteEntryQuestion => 'यह प्रविष्टि हटाएं?';

  @override
  String totalOfItems(int count) {
    return 'कुल $count आइटम';
  }

  @override
  String get chooseCategory => 'श्रेणी का चयन करें';

  @override
  String get fromAccount => 'खाते से';

  @override
  String get toAccount => 'खाते में';

  @override
  String get payeeLabel => 'को भुगतान किया गया/प्राप्त किया गया';

  @override
  String get smsEntryNotice =>
      'एक बैंक एसएमएस से बनाया गया. इसे संपादित करने से आपका बैंक बैलेंस नहीं बदलेगा.';

  @override
  String get saving => 'सहेजा जा रहा है...';

  @override
  String saveAmount(String amount) {
    return '$amount सहेजें';
  }

  @override
  String get addAccount => 'खाता जोड़ें';

  @override
  String get items => 'सामान';

  @override
  String get addItem => 'मद जोड़ें';

  @override
  String itemSuggestion(String name, String quantity, String price) {
    return '$name · $quantity @ $price';
  }

  @override
  String get itemsHelp =>
      'वैकल्पिक: इस खर्च को मात्रा और कीमत के साथ आइटमों में विभाजित करें (उदाहरण के लिए भैंस का दूध 1 लीटर)। हिसाब उन्हें अगली बार याद रखेगा।';

  @override
  String get paidBy => 'द्वारा भुगतान किया गया';

  @override
  String get split => 'विभाजित करना';

  @override
  String get invalidAmount => 'सही राशि दर्ज करें, जैसे 250 या 99.50';

  @override
  String get errorAmountZero => 'शून्य से अधिक राशि दर्ज करें';

  @override
  String get errorPickCategory => 'एक श्रेणी चुनें';

  @override
  String get errorPickBothAccounts => 'स्थानांतरण के लिए दोनों खाते चुनें';

  @override
  String get errorItemName => 'प्रत्येक वस्तु को एक नाम की आवश्यकता होती है';

  @override
  String get errorChoosePayer => 'चुनें कि किसने भुगतान किया';

  @override
  String get errorFixSplit => 'पहले विभाजन को ठीक करें';

  @override
  String get itemName => 'आइटम नाम';

  @override
  String get qty => 'मात्रा';

  @override
  String get unit => 'इकाई';

  @override
  String pricePerUnit(String unit) {
    return 'मूल्य प्रति $unit';
  }

  @override
  String get genericUnit => 'इकाई';

  @override
  String get shareSummary => 'सारांश साझा करें';

  @override
  String get renameGroup => 'समूह का नाम बदलें';

  @override
  String get deleteGroupBody => 'इस समूह में सभी खर्च हटा दिए जाएंगे.';

  @override
  String get simplifyOn => 'ऋणों को सरल बनाएं चालू करें';

  @override
  String get simplifyOff => 'ऋणों को सरल बनाना बंद करें';

  @override
  String get deleteGroup => 'समूह हटाएँ';

  @override
  String get addMemberFirst => 'पहले कम से कम एक और सदस्य जोड़ें';

  @override
  String get addExpense => 'व्यय जोड़ें';

  @override
  String get members => 'सदस्यों';

  @override
  String shareHeader(String group) {
    return '$group - संतुलन';
  }

  @override
  String sharePays(String from, String to, String amount) {
    return '$from भुगतान $to $amount';
  }

  @override
  String get allSettledUp => 'सब व्यवस्थित हो गया.';

  @override
  String get sharedFromHisab => 'हिसाब से साझा किया गया';

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
  String get settlementSubtitle => 'भुगतान · हटाने के लिए टैप करें';

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
  String get noGroupExpensesBody => 'नीचे दिए गए बटन से पहला साझा व्यय जोड़ें।';

  @override
  String get netBalances => 'शुद्ध शेष';

  @override
  String get getsBack => 'वापस हो जाता है';

  @override
  String get owes => 'बकाया';

  @override
  String get settleUp => 'सेटल हो';

  @override
  String get settleUpSimplified => 'व्यवस्थित करें (सरलीकृत)';

  @override
  String get everyoneSettled => 'हर कोई व्यवस्थित हो गया है';

  @override
  String transferArrow(String from, String to) {
    return '$from → $to';
  }

  @override
  String get recordPayment => 'भुगतान रिकॉर्ड करें';

  @override
  String get settleBeforeRemove =>
      'उन्हें हटाने से पहले इस सदस्य का संतुलन व्यवस्थित करें';

  @override
  String removeNamed(String name) {
    return '$name हटाएं?';
  }

  @override
  String get renameMember => 'सदस्य का नाम बदलें';

  @override
  String get addMember => 'सदस्य जोड़ें';

  @override
  String get memberName => 'सदस्य का नाम';

  @override
  String get membersLocalNotice =>
      'सदस्यों को इस डिवाइस पर संग्रहीत किया जाता है. आमंत्रण कोड के साथ साझा सिंक की योजना बनाई गई है; सेटिंग्स → सिंक देखें।';

  @override
  String get newGroup => 'नया समूह';

  @override
  String get groupName => 'समूह नाम';

  @override
  String get groupNameHint => 'गोवा यात्रा, फ्लैट 302…';

  @override
  String get membersCommaSeparated => 'सदस्य (अल्पविराम से अलग)';

  @override
  String get membersHint => 'राहुल, प्रिया, अमन';

  @override
  String get createGroup => 'समूह बनाना';

  @override
  String get groups => 'समूह';

  @override
  String get noGroupsTitle => 'मित्रों के साथ बिल बाँटें';

  @override
  String get noGroupsBody =>
      'किसी यात्रा, फ्लैट या रात्रिभोज के लिए एक समूह बनाएं। खर्च जोड़ें, उन्हें समान रूप से, प्रतिशत, शेयर या सटीक मात्रा के आधार पर विभाजित करें और व्यवस्थित करें।';

  @override
  String get youAreOwed => 'आप पर बकाया है';

  @override
  String get youOwe => 'आप ऋणी हैं';

  @override
  String groupSubtitle(int count, String amount) {
    return '$count सदस्य · $amount खर्च';
  }

  @override
  String get youGet => 'आपको मिला';

  @override
  String get youOweLower => 'आप ऋणी हैं';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get appearance => 'उपस्थिति';

  @override
  String get themeSystem => 'प्रणाली';

  @override
  String get themeLight => 'रोशनी';

  @override
  String get themeDark => 'अँधेरा';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'डिवाइस भाषा';

  @override
  String get money => 'धन';

  @override
  String get currencySymbol => 'मुद्रा चिन्ह';

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
  String get monthStartPrompt => 'माह की शुरुआत दिन (1-28) से होती है';

  @override
  String get automation => 'स्वचालन';

  @override
  String get bankSms => 'बैंक एसएमएस';

  @override
  String get bankSmsOn => 'चालू · इस डिवाइस पर बैंक एसएमएस पढ़ रहा है';

  @override
  String get off => 'बंद';

  @override
  String get yourNameInGroups => 'समूहों में आपका नाम';

  @override
  String get yourName => 'आपका नाम';

  @override
  String get backupAndSync => 'बैकअप और सिंक';

  @override
  String get exportBackup => 'एन्क्रिप्टेड बैकअप निर्यात करें';

  @override
  String get exportBackupHelp =>
      'एईएस-256, आपके द्वारा चुने गए पासफ़्रेज़ द्वारा संरक्षित';

  @override
  String get restoreBackup => 'बैकअप से पुनर्स्थापित करें';

  @override
  String get restoreBackupHelp => 'विलय; नये स्थानीय संपादन रखे गये हैं';

  @override
  String get cloudSync => 'क्लाउड सिंक';

  @override
  String get cloudSyncHelp =>
      'अगला: एंड्रॉइड पर Google ड्राइव, iOS पर iCloud, बैकअप के समान प्रारूप के साथ एंड-टू-एंड एन्क्रिप्टेड।';

  @override
  String get about => 'के बारे में';

  @override
  String get aboutBody =>
      'निःशुल्क, खुला स्रोत, कोई विज्ञापन नहीं, किसी खाते की आवश्यकता नहीं। आपका डेटा आपके डिवाइस पर रहता है.';

  @override
  String get backupPassphrase => 'बैकअप पासफ़्रेज़';

  @override
  String get backupPassphraseHelp =>
      'कम से कम 8 अक्षर; पुनर्स्थापित करने के लिए आपको इसकी आवश्यकता है';

  @override
  String get passphraseTooShort => 'कम से कम 8 अक्षरों का प्रयोग करें';

  @override
  String get backupShareSubject => 'हिसाब एन्क्रिप्टेड बैकअप';

  @override
  String restoredRecords(int count) {
    return '$count रिकॉर्ड पुनर्स्थापित किए गए';
  }

  @override
  String restoreFailed(String error) {
    return 'पुनर्स्थापना विफल: $error';
  }

  @override
  String get pasted => 'PASTED';

  @override
  String get smsFoundReview => 'लेन-देन मिला. नीचे इसकी समीक्षा करें.';

  @override
  String get smsAdded => 'लेन-देन जोड़ा गया.';

  @override
  String get smsDuplicate => 'पहले ही आयात किया जा चुका है.';

  @override
  String get smsNotFound => 'उस पाठ में कोई लेन-देन नहीं मिल सका.';

  @override
  String get readBankSmsQuestion => 'बैंक एसएमएस पढ़ें?';

  @override
  String get smsConsentBody =>
      'लेन-देन लॉग करने और खाते की शेष राशि दिखाने के लिए हिसाब आपके बैंक और यूपीआई ऐप्स से एसएमएस पढ़ता है। संदेशों को केवल इस डिवाइस पर संसाधित किया जाता है और कभी अपलोड नहीं किया जाता है। ओटीपी और प्रमोशनल एसएमएस को नजरअंदाज कर दिया जाता है। आप इसे किसी भी समय बंद कर सकते हैं.';

  @override
  String get smsPermissionDenied => 'एसएमएस की अनुमति नहीं दी गई';

  @override
  String scanResult(int scanned, int added, int pending) {
    return 'स्कैन किए गए $scanned संदेश: $added जोड़े गए, $pending समीक्षा की प्रतीक्षा में हैं।';
  }

  @override
  String get readBankSmsAuto => 'बैंक एसएमएस स्वचालित रूप से पढ़ें';

  @override
  String get smsAndroidOnly =>
      'केवल एंड्रॉइड. डिवाइस पर संसाधित, कभी अपलोड नहीं किया गया।';

  @override
  String get smsNotOnIos =>
      'आईओएस पर उपलब्ध नहीं है. शॉर्टकट का उपयोग करें या नीचे पेस्ट करें।';

  @override
  String get smsAutoAddTitle => 'बिना समीक्षा के लेनदेन जोड़ें';

  @override
  String get smsAutoAddHelp =>
      'बंद: नया एसएमएस नीचे समीक्षा सूची में प्रतीक्षा करें।';

  @override
  String get scanInboxNow => 'अभी इनबॉक्स स्कैन करें';

  @override
  String get scanInboxHelp =>
      'पहली बार 90 दिन पीछे देखता हूँ, तो केवल नये सन्देश';

  @override
  String get pasteSms => 'एक एसएमएस चिपकाएँ';

  @override
  String get pasteSmsHelp => 'आईओएस और एंड्रॉइड पर काम करता है';

  @override
  String get pasteBankSms => 'बैंक एसएमएस चिपकाएँ';

  @override
  String get pasteBankSmsHint => 'Rs.500 debited from A/c XX1234…';

  @override
  String toReview(int count) {
    return 'समीक्षा करने के लिए ($count)';
  }

  @override
  String get nothingWaitingTitle => 'कुछ भी इंतज़ार नहीं';

  @override
  String get nothingWaitingBody => 'नए बैंक लेनदेन यहां दिखाई देंगे.';

  @override
  String get iosShortcutHelp =>
      'iPhone: एक शॉर्टकट ऑटोमेशन बनाएं \"जब मुझे \'डेबिट\' वाला संदेश मिले\" → Hisab:///sms?text=[Message] के साथ \"URL खोलें\"। हिसाब खुलेगा और समीक्षा के लिए लेन-देन को कतारबद्ध करेगा।';

  @override
  String get couldNotAddUseEdit =>
      'इसे जोड़ा नहीं जा सका; संपादित करें का उपयोग करें';

  @override
  String addAmount(String amount) {
    return '$amount जोड़ें';
  }

  @override
  String get splitDoesNotAddUp => 'बंटवारा नहीं जुड़ता';

  @override
  String splitsAcross(String amount, int count) {
    return '$amount को $count लोगों में विभाजित करता है';
  }

  @override
  String get splitEqual => 'समान रूप से';

  @override
  String get splitExact => 'सटीक मात्रा';

  @override
  String get splitPercent => 'प्रतिशत';

  @override
  String get splitShares => 'शेयर/अनुपात';

  @override
  String get splitAdjustment => 'समायोजन';

  @override
  String get splitByItem => 'आइटम द्वारा';

  @override
  String get splitHelpEqual =>
      'टिक किया हुआ प्रत्येक व्यक्ति समान हिस्से का भुगतान करता है।';

  @override
  String get splitHelpExact =>
      'प्रत्येक व्यक्ति पर बकाया राशि दर्ज करें; कुल में जोड़ना होगा.';

  @override
  String get splitHelpPercent => '100 तक जोड़कर प्रतिशत दर्ज करें।';

  @override
  String get splitHelpShares =>
      'शेयर दर्ज करें, उदा. जोड़े के लिए 2 और एकल के लिए 1।';

  @override
  String get splitHelpAdjustment =>
      'पहले अतिरिक्त शुल्क लिया जाता है, बाकी को टिक वाले लोगों के बीच समान रूप से विभाजित किया जाता है।';

  @override
  String get splitHelpByItem =>
      'प्रत्येक आइटम को उसे साझा करने वाले लोगों के बीच विभाजित किया गया है।';

  @override
  String get entries => 'प्रविष्टियां';

  @override
  String get searchEntriesHint => 'आदाता, नोट, वस्तु या श्रेणी खोजें';

  @override
  String get noEntriesTitle => 'अभी तक यहां कुछ भी नहीं है';

  @override
  String get noEntriesBody =>
      'इस महीने की प्रविष्टियाँ दिन के अनुसार समूहीकृत दिखाई देंगी।';

  @override
  String get settled => 'बसे';

  @override
  String get unitsHint => 'L, ml, kg';

  @override
  String get splitErrorNegativeTotal => 'राशि ऋणात्मक नहीं हो सकती';

  @override
  String get splitErrorNobodyIncluded => 'कम से कम एक व्यक्ति का चयन करें';

  @override
  String get splitErrorNegativeAmounts => 'राशियाँ ऋणात्मक नहीं हो सकतीं';

  @override
  String splitErrorAmountLeft(String amount) {
    return '$amount असाइन करना बाकी है';
  }

  @override
  String splitErrorAmountOver(String amount) {
    return '$amount कुल से अधिक';
  }

  @override
  String get splitErrorNegativeValues => 'मान नकारात्मक नहीं हो सकते';

  @override
  String get splitErrorPercentMustTotal => 'प्रतिशतों का योग 100 तक होना चाहिए';

  @override
  String get splitErrorNoShares => 'कम से कम एक शेयर दर्ज करें';

  @override
  String splitErrorPercentLeft(String percent) {
    return '$percent% असाइन करना बाकी है';
  }

  @override
  String splitErrorPercentOver(String percent) {
    return '100 से अधिक $percent%';
  }

  @override
  String splitErrorAdjustmentsExceed(String amount) {
    return 'समायोजन कुल $amount से अधिक है';
  }

  @override
  String get splitErrorAdjustmentNegativeShare =>
      'एक समायोजन किसी शेयर को नकारात्मक बना देता है';

  @override
  String get splitErrorNoItems => 'कम से कम एक आइटम जोड़ें';

  @override
  String splitErrorItemsExceed(String amount) {
    return 'आइटम कुल से $amount अधिक हैं';
  }

  @override
  String splitErrorItemUnassigned(String item) {
    return 'किसी को \"$item\" असाइन करें';
  }

  @override
  String get genericItem => 'वस्तु';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';
}
