/// Suggests a category key for a parsed transaction from merchant keywords.
/// Keys refer to [categoryCatalog]. Pure.
library;

import 'parsed_transaction.dart';

const Map<String, List<String>> _debitRules = {
  'food_delivery': ['swiggy', 'zomato', 'eatsure', 'dominos', 'domino', 'pizza hut', 'box8', 'faasos'],
  'groceries': [
    'blinkit',
    'zepto',
    'bigbasket',
    'instamart',
    'dmart',
    'd mart',
    'grofers',
    'jiomart',
    'reliance fresh',
    'reliance smart',
    'more retail',
    'spencer',
    'nature basket',
    'kirana',
    'supermarket',
    'super market',
    'grocery',
  ],
  'milk_dairy': ['milk', 'dairy', 'amul', 'mother dairy', 'nandini', 'country delight', 'milkbasket'],
  'restaurants': ['restaurant', 'cafe', 'coffee', 'starbucks', 'mcdonald', 'kfc', 'burger', 'subway', 'barbeque', 'bbq', 'dhaba', 'hotel', 'biryani', 'chai', 'bakery', 'eatery', 'kitchen', 'foods'],
  'cab_auto': ['uber', 'ola', 'rapido', 'namma yatri', 'blusmart', 'meru', 'auto rickshaw', 'autorickshaw'],
  'public_transport': ['bmtc', 'best bus', 'metro', 'dmrc', 'bmrcl', 'mmrda', 'irctc local', 'chalo', 'tummoc'],
  'trains_buses': ['irctc', 'redbus', 'abhibus', 'ksrtc', 'msrtc', 'apsrtc', 'tsrtc', 'railway'],
  'flights': ['indigo', 'air india', 'airindia', 'vistara', 'akasa', 'spicejet', 'makemytrip', 'mmt', 'goibibo', 'cleartrip', 'ixigo', 'easemytrip', 'yatra'],
  'hotels': ['oyo', 'treebo', 'fabhotel', 'airbnb', 'booking.com', 'agoda', 'taj', 'marriott', 'resort'],
  'fuel': ['petrol', 'diesel', 'hpcl', 'bpcl', 'iocl', 'indian oil', 'indianoil', 'bharat petroleum', 'hindustan petroleum', 'shell', 'nayara', 'fuel', 'filling station', 'service station'],
  'parking_tolls': ['fastag', 'toll', 'parking', 'nhai'],
  'vehicle_service': ['service centre', 'service center', 'motors', 'garage', 'tyre', 'tyres', 'gomechanic'],
  'online_shopping': ['amazon', 'flipkart', 'myntra', 'meesho', 'ajio', 'snapdeal', 'tata cliq', 'nykaa fashion', 'shopsy'],
  'electronics': ['croma', 'reliance digital', 'vijay sales', 'apple store', 'samsung', 'mi store', 'boat'],
  'clothing': ['zudio', 'westside', 'pantaloons', 'max fashion', 'lifestyle', 'h&m', 'zara', 'uniqlo', 'levis', 'bata', 'decathlon', 'trends', 'fabindia', 'manyavar'],
  'cosmetics': ['nykaa', 'purplle', 'sephora', 'mamaearth'],
  'salon': ['salon', 'saloon', 'barber', 'spa', 'urban company', 'urbanclap', 'parlour', 'parlor'],
  'ott': ['netflix', 'spotify', 'hotstar', 'prime video', 'primevideo', 'youtube premium', 'sonyliv', 'zee5', 'jiocinema', 'apple music', 'gaana', 'wynk', 'audible'],
  'software_subscriptions': [
    'google play',
    'google one',
    'google storage',
    'icloud',
    'apple.com',
    'apple services',
    'microsoft',
    'adobe',
    'openai',
    'chatgpt',
    'claude',
    'anthropic',
    'github',
    'notion',
    'canva',
    'dropbox',
    'aws',
    'cloud',
  ],
  'mobile_recharge': ['jio', 'airtel', 'vodafone', 'vi ', 'bsnl', 'recharge', 'prepaid', 'postpaid'],
  'internet': ['broadband', 'act fibernet', 'hathway', 'tikona', 'excitel', 'you broadband', 'jiofiber', 'airtel xstream', 'wifi'],
  'dth_cable': ['tata play', 'tatasky', 'dish tv', 'd2h', 'airtel dth', 'sun direct', 'cable'],
  'electricity': [
    'electricity',
    'bescom',
    'tneb',
    'tangedco',
    'mseb',
    'msedcl',
    'tata power',
    'adani electricity',
    'bses',
    'torrent power',
    'kseb',
    'uppcl',
    'pspcl',
    'cesc',
    'jvvnl',
    'mahadiscom',
    'wbsedcl',
    'apspdcl',
    'tsspdcl',
    'dhbvn',
    'uhbvn',
  ],
  'water_bill': ['water bill', 'bwssb', 'jal board', 'water supply', 'jal'],
  'gas_lpg': ['indane', 'hp gas', 'bharat gas', 'bharatgas', 'lpg', 'cylinder', 'png', 'mahanagar gas', 'igl', 'adani gas', 'gujarat gas'],
  'medicines': ['pharmacy', 'pharma', 'medical', 'medplus', 'apollo pharmacy', 'apollopharmacy', 'pharmeasy', '1mg', 'netmeds', 'chemist', 'medicine', 'drug'],
  'hospital': ['hospital', 'clinic', 'apollo', 'fortis', 'manipal', 'max healthcare', 'narayana', 'aiims', 'medanta', 'nursing home'],
  'lab_tests': ['diagnostic', 'pathology', 'lab', 'thyrocare', 'metropolis', 'dr lal', 'srl', 'healthians', 'redcliffe'],
  'fitness': ['cult', 'cultfit', 'gym', 'fitness', 'yoga', 'decathlon play'],
  'health_insurance': ['star health', 'niva bupa', 'care health', 'hdfc ergo health', 'icici lombard health', 'aditya birla health', 'mediclaim'],
  'life_insurance': ['lic', 'life insurance', 'hdfc life', 'icici pru', 'sbi life', 'max life', 'bajaj allianz life', 'tata aia', 'policy'],
  'vehicle_insurance': ['acko', 'motor insurance', 'vehicle insurance', 'car insurance', 'bike insurance', 'two wheeler insurance'],
  'investments': [
    'zerodha',
    'groww',
    'upstox',
    'kuvera',
    'coin',
    'mutual fund',
    'sip',
    'nps',
    'ppf',
    'angel one',
    'angelone',
    'paytm money',
    'indmoney',
    'et money',
    'etmoney',
    'smallcase',
    'icici direct',
    'hdfc securities',
    'kotak securities',
    'sbi mf',
    'nippon',
    'axis mf',
    'bse',
    'nse',
    'cams',
    'kfintech',
    'demat',
    'rd ',
    'fd ',
  ],
  'loan_emi': ['emi', 'loan', 'bajaj finserv', 'bajaj finance', 'hdb', 'tata capital', 'home credit', 'kreditbee', 'moneyview', 'navi', 'lazypay', 'simpl'],
  'credit_card_payment': ['cred', 'credit card payment', 'card payment', 'cc payment', 'payment received'],
  'rent': ['rent', 'nobroker', 'housing.com', 'landlord'],
  'society_maintenance': ['maintenance', 'society', 'apartment', 'mygate', 'nobroker hood', 'adda'],
  'home_repairs': ['plumber', 'electrician', 'carpenter', 'repair', 'hardware', 'paint'],
  'furniture': ['ikea', 'pepperfry', 'urban ladder', 'furniture', 'home centre', 'homecentre', 'nilkamal'],
  'appliances': ['appliance', 'lg ', 'whirlpool', 'voltas', 'daikin', 'bluestar'],
  'movies': ['bookmyshow', 'pvr', 'inox', 'cinepolis', 'cinema', 'movie', 'theatre', 'theater', 'paytm insider', 'district'],
  'gaming': ['steam', 'playstation', 'xbox', 'nintendo', 'epic games', 'dream11', 'mpl', 'winzo', 'rummy', 'bgmi', 'free fire'],
  'events': ['concert', 'insider', 'zomaland', 'ticket'],
  'school_fees': ['school', 'college', 'university', 'tuition fee', 'fees', 'fee '],
  'tuition': ['tuition', 'coaching', 'classes', 'academy', 'byju', 'vedantu', 'physics wallah', 'unacademy', 'aakash', 'allen'],
  'courses': ['udemy', 'coursera', 'upgrad', 'simplilearn', 'skillshare', 'linkedin learning', 'pluralsight', 'scaler'],
  'books_stationery': ['bookstore', 'book store', 'crossword', 'sapna', 'stationery', 'stationary', 'amazon kindle', 'kindle'],
  'kids': ['firstcry', 'first cry', 'hopscotch', 'diaper', 'pampers', 'huggies', 'baby'],
  'pets': ['petshop', 'pet shop', 'heads up for tails', 'supertails', 'vet', 'pedigree', 'royal canin', 'drools'],
  'donation': ['donation', 'donate', 'charity', 'ngo', 'trust', 'foundation', 'giveindia', 'ketto', 'milaap', 'pm cares', 'relief fund'],
  'religious': ['temple', 'mandir', 'gurudwara', 'church', 'mosque', 'masjid', 'devasthanam', 'tirupati', 'ttd', 'iskcon', 'dharmasthala'],
  'laundry': ['laundry', 'dry clean', 'dryclean', 'dhobi', 'ironing', 'uclean'],
  'drinking_water': ['bisleri', 'kinley', 'aquafina', 'water can', 'mineral water'],
  'alcohol': ['wine', 'liquor', 'bar ', 'pub', 'brewery', 'beer', 'tasmac', 'bevco', 'wines'],
  'bakery_sweets': ['sweets', 'mithai', 'haldiram', 'bikanervala', 'cake', 'theobroma'],
  'toys': ['hamleys', 'toys', 'lego', 'funskool'],
  'bank_charges': ['charges', 'fee charged', 'annual fee', 'sms charges', 'atm charges', 'penalty', 'gst', 'service charge', 'amb charge', 'non maintenance'],
  'taxes': ['income tax', 'tax payment', 'advance tax', 'tds', 'gst payment', 'property tax', 'challan'],
  'cash_withdrawal': ['atm', 'cash withdrawal', 'withdrawn at', 'cash wdl', 'awb'],
  'self_transfer': ['self transfer', 'own account', 'to self'],
  'wallet_topup': ['wallet', 'paytm wallet', 'phonepe wallet', 'amazon pay balance', 'mobikwik', 'freecharge', 'added to'],
  'jewellery': ['jeweller', 'jewellery', 'jewelry', 'tanishq', 'kalyan', 'malabar gold', 'caratlane', 'bluestone', 'gold'],
  'sports_hobby': ['sports', 'cricket', 'badminton', 'cycle', 'bicycle'],
  'office_supplies': ['printing', 'xerox', 'print', 'courier', 'dtdc', 'delhivery', 'bluedart', 'india post', 'postal'],
  'marketing': ['google ads', 'facebook ads', 'meta ads', 'adwords'],
  'tools_software': ['saas', 'hosting', 'domain', 'godaddy', 'hostinger', 'namecheap', 'digitalocean', 'vercel', 'jetbrains'],
  'forex': ['forex', 'currency exchange', 'thomas cook', 'bookmyforex'],
  'visa_travel_insurance': ['visa', 'vfs', 'travel insurance'],
};

const Map<String, List<String>> _creditRules = {
  'salary': ['salary', 'sal ', 'payroll', 'wages', 'stipend', 'neft-sal', 'sal credit'],
  'interest': ['interest', 'int.', 'int credited', 'fd interest', 'sb int', 'savings interest'],
  'dividends': ['dividend', 'div ', 'capital gain', 'redemption', 'mf redemption'],
  'refunds_cashback': ['refund', 'cashback', 'reversal', 'reversed', 'chargeback', 'returned'],
  'rental_income': ['rent'],
  'reimbursement': ['reimburse', 'claim', 'expense claim'],
  'bonus': ['bonus', 'incentive', 'reward', 'gratuity'],
  'pension': ['pension', 'epf', 'pf ', 'provident'],
  'freelance': ['upwork', 'fiverr', 'toptal', 'payoneer', 'wise', 'paypal', 'razorpay', 'stripe', 'invoice'],
  'business_income': ['payment from', 'order', 'sale', 'settlement', 'cashfree', 'payu', 'paytm business'],
  'gifts_received': ['gift', 'shagun', 'blessing'],
  'wallet_topup': ['added to', 'wallet'],
  'self_transfer': ['self', 'own account'],
};

/// Message kinds that settle the category on their own, whatever the
/// merchant text says.
const Map<TxnKind, String> _kindCategories = {
  TxnKind.salary: 'salary',
  TxnKind.refund: 'refunds_cashback',
  TxnKind.atmWithdrawal: 'cash_withdrawal',
  TxnKind.emi: 'loan_emi',
  TxnKind.walletTopUp: 'wallet_topup',
};

/// Index of [keyword] in [haystack] as a whole word (letters/digits on
/// either side break the match), or -1.
int _indexOfWord(String haystack, String keyword) {
  final trimmed = keyword.trim();
  final pattern = RegExp('(?<![a-z0-9])${RegExp.escape(trimmed)}(?![a-z0-9])');
  return pattern.firstMatch(haystack)?.start ?? -1;
}

/// Keywords this long are distinctive enough to match inside a longer
/// token, which is how UPI handles such as `apollopharmacy@ybl` are spelt.
const _substringMinLength = 6;

int _indexOfSubstring(String haystack, String keyword) {
  final trimmed = keyword.trim();
  return trimmed.length < _substringMinLength ? -1 : haystack.indexOf(trimmed);
}

String? _bestMatch(String haystack, Map<String, List<String>> rules, int Function(String, String) indexOf) {
  String? best;
  var bestIndex = haystack.length + 1;
  var bestLength = 0;
  for (final entry in rules.entries) {
    for (final keyword in entry.value) {
      final index = indexOf(haystack, keyword);
      if (index < 0) continue;
      // Prefer the keyword that appears earliest; longer keyword wins ties.
      if (index < bestIndex || (index == bestIndex && keyword.length > bestLength)) {
        best = entry.key;
        bestIndex = index;
        bestLength = keyword.length;
      }
    }
  }
  return best;
}

/// Returns the best category key for [txn], falling back to a generic key.
/// Whole-word matches win; a glued-together handle falls back to substrings.
String suggestCategoryKey(ParsedTransaction txn) {
  final haystack = '${txn.counterparty ?? ''} ${txn.raw}'.toLowerCase();
  final rules = txn.isDebit ? _debitRules : _creditRules;
  if (txn.isDebit && txn.instrument == Instrument.atm) return 'cash_withdrawal';
  if (!txn.isDebit && txn.isCreditCard) return 'credit_card_payment';
  final byKind = _kindCategories[txn.kind];
  if (byKind != null) return byKind;

  final best = _bestMatch(haystack, rules, _indexOfWord) ?? _bestMatch(haystack, rules, _indexOfSubstring);
  if (best != null) return best;
  return txn.isDebit ? 'other_expense' : 'other_income';
}
