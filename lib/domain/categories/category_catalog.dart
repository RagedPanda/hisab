/// Built-in category catalog seeded into the database on first launch.
/// Icons are keys into the app icon catalog (see core/app_icons.dart) so this
/// file stays free of Flutter imports and can be unit tested.
library;

enum CategoryKind { expense, income, transfer }

class CategorySeed {
  const CategorySeed(
    this.key,
    this.name, {
    required this.icon,
    required this.color,
    this.kind = CategoryKind.expense,
    this.children = const [],
    this.units = const [],
  });

  /// Stable key, used for SMS categorisation rules and for merging seeds on
  /// upgrade without duplicating user-renamed categories.
  final String key;
  final String name;
  final String icon;

  /// ARGB hex without the leading `#`, e.g. `FF6D4C41`.
  final int color;
  final CategoryKind kind;
  final List<CategorySeed> children;

  /// Suggested quantity units for item entries in this category.
  final List<String> units;
}

const _food = 0xFFEF6C00;
const _transport = 0xFF1E88E5;
const _home = 0xFF6D4C41;
const _bills = 0xFF00897B;
const _health = 0xFFE53935;
const _shopping = 0xFF8E24AA;
const _fun = 0xFFD81B60;
const _education = 0xFF3949AB;
const _family = 0xFFF4511E;
const _personal = 0xFF00ACC1;
const _travel = 0xFF039BE5;
const _finance = 0xFF43A047;
const _pets = 0xFF7CB342;
const _giving = 0xFFFB8C00;
const _help = 0xFF5E35B1;
const _social = 0xFFC0CA33;
const _business = 0xFF546E7A;
const _misc = 0xFF757575;
const _income = 0xFF2E7D32;
const _transfer = 0xFF607D8B;

const List<CategorySeed> categoryCatalog = [
  CategorySeed('food', 'Food & Dining', icon: 'restaurant', color: _food, children: [
    CategorySeed('groceries', 'Groceries', icon: 'shopping_basket', color: _food, units: ['kg', 'g', 'pcs', 'pack']),
    CategorySeed('milk_dairy', 'Milk & Dairy', icon: 'water_drop', color: _food, units: ['L', 'ml', 'kg', 'pcs']),
    CategorySeed('vegetables_fruits', 'Vegetables & Fruits', icon: 'eco', color: _food, units: ['kg', 'g', 'dozen', 'pcs']),
    CategorySeed('restaurants', 'Restaurants & Cafes', icon: 'local_dining', color: _food),
    CategorySeed('food_delivery', 'Food Delivery', icon: 'delivery_dining', color: _food),
    CategorySeed('snacks_tea', 'Snacks, Tea & Coffee', icon: 'coffee', color: _food, units: ['pcs', 'cup']),
    CategorySeed('bakery_sweets', 'Bakery & Sweets', icon: 'cake', color: _food, units: ['kg', 'pcs']),
    CategorySeed('meat_fish_eggs', 'Meat, Fish & Eggs', icon: 'set_meal', color: _food, units: ['kg', 'dozen', 'pcs']),
    CategorySeed('drinking_water', 'Drinking Water', icon: 'local_drink', color: _food, units: ['can', 'L']),
    CategorySeed('alcohol', 'Alcohol & Bar', icon: 'wine_bar', color: _food),
    CategorySeed('tiffin', 'Tiffin / Mess', icon: 'lunch_dining', color: _food),
  ]),
  CategorySeed('transport', 'Transport', icon: 'directions_car', color: _transport, children: [
    CategorySeed('fuel', 'Fuel / Petrol / Diesel', icon: 'local_gas_station', color: _transport, units: ['L']),
    CategorySeed('cab_auto', 'Cab, Auto & Bike Taxi', icon: 'local_taxi', color: _transport),
    CategorySeed('public_transport', 'Bus, Metro & Local Train', icon: 'directions_bus', color: _transport),
    CategorySeed('parking_tolls', 'Parking & Tolls (FASTag)', icon: 'local_parking', color: _transport),
    CategorySeed('vehicle_service', 'Vehicle Service & Repairs', icon: 'build', color: _transport),
    CategorySeed('vehicle_insurance', 'Vehicle Insurance & PUC', icon: 'verified_user', color: _transport),
    CategorySeed('ev_charging', 'EV Charging', icon: 'ev_station', color: _transport, units: ['kWh']),
    CategorySeed('vehicle_purchase', 'Vehicle Purchase / EMI', icon: 'two_wheeler', color: _transport),
  ]),
  CategorySeed('housing', 'Housing', icon: 'home', color: _home, children: [
    CategorySeed('rent', 'Rent', icon: 'house', color: _home),
    CategorySeed('society_maintenance', 'Society Maintenance', icon: 'apartment', color: _home),
    CategorySeed('home_repairs', 'Repairs & Plumbing', icon: 'handyman', color: _home),
    CategorySeed('furniture', 'Furniture & Decor', icon: 'chair', color: _home),
    CategorySeed('appliances', 'Appliances', icon: 'kitchen', color: _home),
    CategorySeed('home_loan', 'Home Loan EMI', icon: 'account_balance', color: _home),
    CategorySeed('property_tax', 'Property Tax', icon: 'receipt_long', color: _home),
    CategorySeed('cleaning_supplies', 'Cleaning & Household Supplies', icon: 'cleaning_services', color: _home, units: ['pcs', 'L', 'kg']),
  ]),
  CategorySeed('bills', 'Bills & Utilities', icon: 'receipt', color: _bills, children: [
    CategorySeed('electricity', 'Electricity', icon: 'bolt', color: _bills, units: ['unit']),
    CategorySeed('water_bill', 'Water', icon: 'water', color: _bills),
    CategorySeed('gas_lpg', 'Gas / LPG Cylinder', icon: 'propane_tank', color: _bills, units: ['cylinder']),
    CategorySeed('mobile_recharge', 'Mobile Recharge & Postpaid', icon: 'smartphone', color: _bills),
    CategorySeed('internet', 'Internet / Broadband', icon: 'wifi', color: _bills),
    CategorySeed('dth_cable', 'DTH / Cable TV', icon: 'tv', color: _bills),
    CategorySeed('ott', 'OTT & Streaming', icon: 'play_circle', color: _bills),
    CategorySeed('software_subscriptions', 'Software & Cloud Subscriptions', icon: 'cloud', color: _bills),
  ]),
  CategorySeed('health', 'Health & Medical', icon: 'medical_services', color: _health, children: [
    CategorySeed('medicines', 'Medicines & Pharmacy', icon: 'medication', color: _health, units: ['strip', 'pcs', 'bottle']),
    CategorySeed('doctor', 'Doctor & Consultation', icon: 'stethoscope', color: _health),
    CategorySeed('hospital', 'Hospital & Surgery', icon: 'local_hospital', color: _health),
    CategorySeed('lab_tests', 'Lab Tests & Diagnostics', icon: 'biotech', color: _health),
    CategorySeed('dental_eye', 'Dental & Eye Care', icon: 'visibility', color: _health),
    CategorySeed('health_insurance', 'Health Insurance', icon: 'health_and_safety', color: _health),
    CategorySeed('fitness', 'Gym, Yoga & Fitness', icon: 'fitness_center', color: _health),
    CategorySeed('supplements', 'Supplements & Wellness', icon: 'spa', color: _health),
  ]),
  CategorySeed('shopping', 'Shopping', icon: 'shopping_bag', color: _shopping, children: [
    CategorySeed('clothing', 'Clothing & Footwear', icon: 'checkroom', color: _shopping),
    CategorySeed('electronics', 'Electronics & Gadgets', icon: 'devices', color: _shopping),
    CategorySeed('online_shopping', 'Online Shopping', icon: 'shopping_cart', color: _shopping),
    CategorySeed('jewellery', 'Jewellery & Accessories', icon: 'diamond', color: _shopping),
    CategorySeed('books_stationery', 'Books & Stationery', icon: 'menu_book', color: _shopping),
    CategorySeed('gifts_given', 'Gifts', icon: 'card_giftcard', color: _shopping),
    CategorySeed('sports_hobby', 'Sports & Hobby Gear', icon: 'sports_cricket', color: _shopping),
    CategorySeed('toys', 'Toys & Games', icon: 'toys', color: _shopping),
  ]),
  CategorySeed('entertainment', 'Entertainment', icon: 'movie', color: _fun, children: [
    CategorySeed('movies', 'Movies & Theatre', icon: 'theaters', color: _fun),
    CategorySeed('events', 'Events & Concerts', icon: 'confirmation_number', color: _fun),
    CategorySeed('gaming', 'Gaming', icon: 'sports_esports', color: _fun),
    CategorySeed('music', 'Music', icon: 'music_note', color: _fun),
    CategorySeed('outings', 'Outings & Parties', icon: 'celebration', color: _fun),
    CategorySeed('books_magazines', 'Books & Magazines', icon: 'auto_stories', color: _fun),
  ]),
  CategorySeed('education', 'Education', icon: 'school', color: _education, children: [
    CategorySeed('school_fees', 'School / College Fees', icon: 'account_balance', color: _education),
    CategorySeed('tuition', 'Tuition & Coaching', icon: 'cast_for_education', color: _education),
    CategorySeed('courses', 'Online Courses & Exams', icon: 'laptop', color: _education),
    CategorySeed('study_material', 'Books & Study Material', icon: 'import_contacts', color: _education),
    CategorySeed('education_loan', 'Education Loan EMI', icon: 'account_balance_wallet', color: _education),
  ]),
  CategorySeed('family', 'Family & Kids', icon: 'family_restroom', color: _family, children: [
    CategorySeed('kids', 'Kids & Baby Care', icon: 'child_care', color: _family, units: ['pack', 'pcs']),
    CategorySeed('parents_support', 'Parents / Family Support', icon: 'elderly', color: _family),
    CategorySeed('daycare', 'Daycare & Activities', icon: 'child_friendly', color: _family),
    CategorySeed('pocket_money', 'Pocket Money', icon: 'savings', color: _family),
  ]),
  CategorySeed('personal_care', 'Personal Care', icon: 'face', color: _personal, children: [
    CategorySeed('salon', 'Salon, Barber & Spa', icon: 'content_cut', color: _personal),
    CategorySeed('cosmetics', 'Cosmetics & Grooming', icon: 'brush', color: _personal),
    CategorySeed('laundry', 'Laundry & Dry Cleaning', icon: 'local_laundry_service', color: _personal, units: ['pcs', 'kg']),
    CategorySeed('tailoring', 'Tailoring', icon: 'straighten', color: _personal),
  ]),
  CategorySeed('travel', 'Travel & Vacation', icon: 'flight', color: _travel, children: [
    CategorySeed('flights', 'Flights', icon: 'flight_takeoff', color: _travel),
    CategorySeed('trains_buses', 'Trains & Intercity Bus', icon: 'train', color: _travel),
    CategorySeed('hotels', 'Hotels & Stays', icon: 'hotel', color: _travel),
    CategorySeed('trip_food', 'Trip Food & Activities', icon: 'beach_access', color: _travel),
    CategorySeed('visa_travel_insurance', 'Visa & Travel Insurance', icon: 'badge', color: _travel),
    CategorySeed('forex', 'Forex & Currency Exchange', icon: 'currency_exchange', color: _travel),
  ]),
  CategorySeed('finance', 'Finance & Insurance', icon: 'account_balance', color: _finance, children: [
    CategorySeed('loan_emi', 'Loan EMI', icon: 'payments', color: _finance),
    CategorySeed('credit_card_bill', 'Credit Card Bill', icon: 'credit_card', color: _finance),
    CategorySeed('bank_charges', 'Bank Charges & Fees', icon: 'account_balance_wallet', color: _finance),
    CategorySeed('life_insurance', 'Life Insurance Premium', icon: 'shield', color: _finance),
    CategorySeed('investments', 'Investments & SIP', icon: 'trending_up', color: _finance),
    CategorySeed('taxes', 'Taxes', icon: 'request_quote', color: _finance),
    CategorySeed('interest_paid', 'Interest & Late Fees', icon: 'percent', color: _finance),
    CategorySeed('lending', 'Money Lent to Others', icon: 'handshake', color: _finance),
  ]),
  CategorySeed('household_help', 'Household Help', icon: 'cleaning_services', color: _help, children: [
    CategorySeed('maid', 'Maid / Cleaning', icon: 'person', color: _help),
    CategorySeed('cook', 'Cook', icon: 'soup_kitchen', color: _help),
    CategorySeed('driver', 'Driver', icon: 'drive_eta', color: _help),
    CategorySeed('security_gardener', 'Security, Gardener & Others', icon: 'yard', color: _help),
    CategorySeed('nanny', 'Nanny / Caretaker', icon: 'escalator_warning', color: _help),
  ]),
  CategorySeed('social', 'Social & Festivals', icon: 'celebration', color: _social, children: [
    CategorySeed('festivals_puja', 'Festivals & Puja', icon: 'temple_hindu', color: _social),
    CategorySeed('weddings_functions', 'Weddings & Functions', icon: 'favorite', color: _social),
    CategorySeed('shagun', 'Shagun / Cash Gifts', icon: 'redeem', color: _social),
    CategorySeed('guests', 'Guests & Hosting', icon: 'groups', color: _social),
  ]),
  CategorySeed('giving', 'Donations & Charity', icon: 'volunteer_activism', color: _giving, children: [
    CategorySeed('donation', 'Donation', icon: 'favorite_border', color: _giving),
    CategorySeed('religious', 'Religious Offerings', icon: 'self_improvement', color: _giving),
    CategorySeed('tips', 'Tips', icon: 'thumb_up', color: _giving),
  ]),
  CategorySeed('pets', 'Pets', icon: 'pets', color: _pets, children: [
    CategorySeed('pet_food', 'Pet Food', icon: 'set_meal', color: _pets, units: ['kg', 'pack']),
    CategorySeed('vet', 'Vet & Medicines', icon: 'healing', color: _pets),
    CategorySeed('pet_grooming', 'Grooming & Accessories', icon: 'content_cut', color: _pets),
  ]),
  CategorySeed('business', 'Business & Work', icon: 'work', color: _business, children: [
    CategorySeed('office_supplies', 'Office Supplies', icon: 'print', color: _business),
    CategorySeed('professional_fees', 'Professional Fees (CA, Legal)', icon: 'gavel', color: _business),
    CategorySeed('business_travel', 'Work Travel (reimbursable)', icon: 'work_outline', color: _business),
    CategorySeed('tools_software', 'Tools & Software', icon: 'terminal', color: _business),
    CategorySeed('marketing', 'Marketing & Ads', icon: 'campaign', color: _business),
  ]),
  CategorySeed('misc', 'Miscellaneous', icon: 'more_horiz', color: _misc, children: [
    CategorySeed('atm_cash', 'Cash Spent (untracked)', icon: 'local_atm', color: _misc),
    CategorySeed('fines', 'Fines & Penalties', icon: 'gavel', color: _misc),
    CategorySeed('lost_money', 'Lost / Stolen', icon: 'money_off', color: _misc),
    CategorySeed('other_expense', 'Other', icon: 'category', color: _misc),
  ]),

  // Income
  CategorySeed('salary', 'Salary', icon: 'payments', color: _income, kind: CategoryKind.income),
  CategorySeed('business_income', 'Business Income', icon: 'storefront', color: _income, kind: CategoryKind.income),
  CategorySeed('freelance', 'Freelance & Side Income', icon: 'laptop_mac', color: _income, kind: CategoryKind.income),
  CategorySeed('interest', 'Interest', icon: 'percent', color: _income, kind: CategoryKind.income),
  CategorySeed('dividends', 'Dividends & Capital Gains', icon: 'trending_up', color: _income, kind: CategoryKind.income),
  CategorySeed('rental_income', 'Rental Income', icon: 'house', color: _income, kind: CategoryKind.income),
  CategorySeed('refunds_cashback', 'Refunds & Cashback', icon: 'replay', color: _income, kind: CategoryKind.income),
  CategorySeed('gifts_received', 'Gifts Received', icon: 'redeem', color: _income, kind: CategoryKind.income),
  CategorySeed('reimbursement', 'Reimbursements', icon: 'receipt_long', color: _income, kind: CategoryKind.income),
  CategorySeed('bonus', 'Bonus & Incentives', icon: 'stars', color: _income, kind: CategoryKind.income),
  CategorySeed('pension', 'Pension & Benefits', icon: 'elderly', color: _income, kind: CategoryKind.income),
  CategorySeed('money_returned', 'Money Returned (lent)', icon: 'handshake', color: _income, kind: CategoryKind.income),
  CategorySeed('other_income', 'Other Income', icon: 'add_circle', color: _income, kind: CategoryKind.income),

  // Transfers (neither spend nor income)
  CategorySeed('self_transfer', 'Self Transfer', icon: 'swap_horiz', color: _transfer, kind: CategoryKind.transfer),
  CategorySeed('cash_withdrawal', 'Cash Withdrawal (ATM)', icon: 'local_atm', color: _transfer, kind: CategoryKind.transfer),
  CategorySeed('credit_card_payment', 'Credit Card Payment', icon: 'credit_score', color: _transfer, kind: CategoryKind.transfer),
  CategorySeed('wallet_topup', 'Wallet Top-up', icon: 'account_balance_wallet', color: _transfer, kind: CategoryKind.transfer),
  CategorySeed('investment_transfer', 'To Investment Account', icon: 'savings', color: _transfer, kind: CategoryKind.transfer),
];

/// Flat list of every seed (parents followed by children) for lookups.
Iterable<CategorySeed> flattenCatalog([List<CategorySeed> seeds = categoryCatalog]) sync* {
  for (final seed in seeds) {
    yield seed;
    yield* flattenCatalog(seed.children);
  }
}

CategorySeed? findSeed(String key) {
  for (final seed in flattenCatalog()) {
    if (seed.key == key) return seed;
  }
  return null;
}
