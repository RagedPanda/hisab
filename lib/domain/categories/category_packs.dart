/// Opt-in category packs: extra categories for a kind of project (a vehicle,
/// a house build, a wedding) that are not in the everyday catalog. A pack is
/// a list of root seeds with children. A seed whose key is already in the
/// catalog is reused (never duplicated); new seeds get their own stable keys
/// so Hindi names and SMS rules can find them. Pure, no Flutter imports.
library;

import 'category_catalog.dart';

class CategoryPack {
  const CategoryPack({required this.key, required this.icon, required this.roots});

  /// Stable key, stored on every category the pack creates (`categories.packKey`).
  final String key;
  final String icon;

  /// Top-level seeds; the first one names the pack in lists.
  final List<CategorySeed> roots;

  CategorySeed get primary => roots.first;
}

/// One seed of a pack, with its parent and whether the user already has it.
class PackPlanItem {
  const PackPlanItem({required this.seed, required this.parentKey, required this.exists});
  final CategorySeed seed;

  /// Seed key of the parent, or null for a root.
  final String? parentKey;
  final bool exists;
}

/// Every seed in [pack], parents before their children, each flagged with
/// whether a category with that seed key is already in [existingSeedKeys].
List<PackPlanItem> planPack(CategoryPack pack, Set<String> existingSeedKeys) => [
      for (final root in pack.roots) ...[
        PackPlanItem(seed: root, parentKey: null, exists: existingSeedKeys.contains(root.key)),
        for (final child in root.children)
          PackPlanItem(seed: child, parentKey: root.key, exists: existingSeedKeys.contains(child.key)),
      ],
    ];

/// The seeds [planPack] would add, i.e. the ones the user does not have yet.
List<PackPlanItem> missingPackItems(CategoryPack pack, Set<String> existingSeedKeys) =>
    planPack(pack, existingSeedKeys).where((item) => !item.exists).toList();

/// A pack counts as added once any category carries its key.
bool isPackAdded(String packKey, Iterable<String?> packKeysInUse) => packKeysInUse.contains(packKey);

CategorySeed _catalogSeed(String key) {
  final seed = findSeed(key);
  if (seed == null) throw ArgumentError.value(key, 'key', 'not in the category catalog');
  return seed;
}

/// A catalog seed reused as-is inside a pack (no children of its own).
CategorySeed _reuse(String key) {
  final seed = _catalogSeed(key);
  return CategorySeed(seed.key, seed.name, icon: seed.icon, color: seed.color, kind: seed.kind, units: seed.units);
}

/// A catalog parent reused as a pack root, carrying the pack's children.
CategorySeed _reuseParent(String key, List<CategorySeed> children) {
  final seed = _catalogSeed(key);
  return CategorySeed(seed.key, seed.name, icon: seed.icon, color: seed.color, kind: seed.kind, children: children);
}

const _vehicleColor = 0xFF1E88E5;
const _constructionColor = 0xFF8D6E63;
const _renovationColor = 0xFF6D4C41;
const _travelColor = 0xFFF9A825;
const _weddingColor = 0xFFD81B60;

// Construction seeds, shared with the renovation pack so the two never duplicate.
const _architect = CategorySeed('build_architect', 'Architect & Engineer Fees', icon: 'request_quote', color: _constructionColor);
const _permits = CategorySeed('build_permits', 'Permits & Approvals', icon: 'badge', color: _constructionColor);
const _survey = CategorySeed('build_survey', 'Soil Test & Survey', icon: 'biotech', color: _constructionColor);
const _registry = CategorySeed('build_registry', 'Registry & Stamp Duty', icon: 'receipt_long', color: _constructionColor);
const _steel = CategorySeed('build_steel', 'Steel', icon: 'construction', color: _constructionColor, units: ['kg', 'ton']);
const _cement = CategorySeed('build_cement', 'Cement', icon: 'construction', color: _constructionColor, units: ['bag']);
const _bricks = CategorySeed('build_bricks', 'Bricks & Blocks', icon: 'roofing', color: _constructionColor, units: ['nos', 'truck']);
const _sand = CategorySeed('build_sand', 'Sand', icon: 'local_shipping', color: _constructionColor, units: ['cft', 'truck']);
const _aggregate = CategorySeed('build_aggregate', 'Aggregate & Stone', icon: 'local_shipping', color: _constructionColor, units: ['cft', 'truck']);
const _rmc = CategorySeed('build_rmc', 'Ready-mix Concrete', icon: 'local_shipping', color: _constructionColor, units: ['cu m']);
const _tiles = CategorySeed('build_tiles', 'Tiles, Marble & Flooring', icon: 'weekend', color: _constructionColor, units: ['sq ft', 'box']);
const _wood = CategorySeed('build_wood', 'Wood, Doors & Windows', icon: 'carpenter', color: _constructionColor);
const _paint = CategorySeed('build_paint', 'Paint', icon: 'brush', color: _constructionColor, units: ['L']);
const _electrical = CategorySeed('build_electrical', 'Electrical Materials', icon: 'electric_bolt', color: _constructionColor);
const _plumbing = CategorySeed('build_plumbing', 'Plumbing & Sanitaryware', icon: 'plumbing', color: _constructionColor);
const _glass = CategorySeed('build_glass', 'Glass & Grills', icon: 'security', color: _constructionColor);
const _kitchen = CategorySeed('build_kitchen', 'Kitchen', icon: 'kitchen', color: _constructionColor);
const _hardware = CategorySeed('build_hardware', 'Hardware & Misc', icon: 'build', color: _constructionColor);
const _contractor = CategorySeed('build_contractor', 'Contractor', icon: 'engineering', color: _constructionColor);
const _mason = CategorySeed('build_mason', 'Mason', icon: 'handyman', color: _constructionColor, units: ['day']);
const _labour = CategorySeed('build_labour', 'Labour & Helpers', icon: 'groups', color: _constructionColor, units: ['day']);
const _electrician = CategorySeed('build_electrician', 'Electrician', icon: 'power', color: _constructionColor);
const _plumber = CategorySeed('build_plumber', 'Plumber', icon: 'plumbing', color: _constructionColor);
const _carpenter = CategorySeed('build_carpenter', 'Carpenter', icon: 'carpenter', color: _constructionColor);
const _painter = CategorySeed('build_painter', 'Painter', icon: 'brush', color: _constructionColor);
const _welder = CategorySeed('build_welder', 'Welder & Fabricator', icon: 'build', color: _constructionColor);
const _tileWorker = CategorySeed('build_tile_worker', 'Tile & Marble Worker', icon: 'handyman', color: _constructionColor);
const _borewell = CategorySeed('build_borewell', 'Borewell & Water', icon: 'water', color: _constructionColor);
const _powerConnection = CategorySeed('build_power_connection', 'Electricity Connection', icon: 'bolt', color: _constructionColor);
const _equipment = CategorySeed('build_equipment', 'Equipment Hire', icon: 'construction', color: _constructionColor, units: ['day', 'hour']);
const _siteTransport = CategorySeed('build_transport', 'Material Transport', icon: 'local_shipping', color: _constructionColor, units: ['truck']);
const _watchman = CategorySeed('build_watchman', 'Watchman & Security', icon: 'shield', color: _constructionColor);
const _waste = CategorySeed('build_waste', 'Waste & Debris Removal', icon: 'cleaning_services', color: _constructionColor);
const _bhoomiPuja = CategorySeed('build_puja', 'Bhoomi Puja & Ceremonies', icon: 'temple_hindu', color: _constructionColor);

final CategoryPack vehiclePack = CategoryPack(key: 'vehicle', icon: 'directions_car', roots: [
  CategorySeed('vehicle', 'Vehicle', icon: 'directions_car', color: _vehicleColor, children: [
    _reuse('fuel'),
    _reuse('vehicle_service'),
    const CategorySeed('vehicle_parts', 'Parts & Spares', icon: 'car_repair', color: _vehicleColor),
    const CategorySeed('vehicle_tyres_battery', 'Tyres & Battery', icon: 'tire_repair', color: _vehicleColor),
    _reuse('vehicle_insurance'),
    const CategorySeed('vehicle_puc', 'PUC', icon: 'eco', color: _vehicleColor),
    const CategorySeed('vehicle_rc_tax', 'RC, Registration & Road Tax', icon: 'badge', color: _vehicleColor),
    _reuse('parking_tolls'),
    _reuse('fines'),
    const CategorySeed('vehicle_accessories', 'Vehicle Accessories', icon: 'local_mall', color: _vehicleColor),
    const CategorySeed('vehicle_wash', 'Washing & Cleaning', icon: 'local_car_wash', color: _vehicleColor),
    _reuse('loan_emi'),
    _reuse('vehicle_purchase'),
    _reuse('ev_charging'),
  ]),
]);

const CategoryPack constructionPack = CategoryPack(key: 'construction', icon: 'construction', roots: [
  CategorySeed('construction', 'Home Construction', icon: 'construction', color: _constructionColor, children: [
    _architect, _permits, _survey, _registry,
    _steel, _cement, _bricks, _sand, _aggregate, _rmc, _tiles, _wood, _paint, _electrical, _plumbing, _glass, _kitchen, _hardware,
    _contractor, _mason, _labour, _electrician, _plumber, _carpenter, _painter, _welder, _tileWorker,
    _borewell, _powerConnection, _equipment, _siteTransport, _watchman, _waste, _bhoomiPuja,
  ]),
]);

final CategoryPack renovationPack = CategoryPack(key: 'renovation', icon: 'format_paint', roots: [
  CategorySeed('renovation', 'Renovation', icon: 'format_paint', color: _renovationColor, children: [
    const CategorySeed('reno_demolition', 'Demolition', icon: 'construction', color: _renovationColor),
    const CategorySeed('reno_civil', 'Civil Work', icon: 'handyman', color: _renovationColor),
    const CategorySeed('reno_modular_kitchen', 'Modular Kitchen', icon: 'kitchen', color: _renovationColor),
    const CategorySeed('reno_bathroom', 'Bathroom', icon: 'bathtub', color: _renovationColor),
    const CategorySeed('reno_interior_designer', 'Interior Designer', icon: 'brush', color: _renovationColor),
    _reuse('furniture'),
    _reuse('appliances'),
    _cement, _sand, _tiles, _wood, _paint, _electrical, _plumbing,
    _contractor, _mason, _electrician, _plumber, _carpenter, _painter, _tileWorker, _waste,
  ]),
]);

final CategoryPack tripPack = CategoryPack(key: 'trip', icon: 'luggage', roots: [
  _reuseParent('travel', [
    _reuse('flights'),
    _reuse('trains_buses'),
    const CategorySeed('trip_local_transport', 'Cab, Auto & Local Transport', icon: 'local_taxi', color: _travelColor),
    const CategorySeed('trip_fuel_tolls', 'Fuel & Tolls (road trip)', icon: 'local_gas_station', color: _travelColor),
    _reuse('hotels'),
    _reuse('trip_food'),
    const CategorySeed('trip_sightseeing', 'Sightseeing & Tickets', icon: 'attractions', color: _travelColor),
    const CategorySeed('trip_shopping', 'Shopping & Souvenirs', icon: 'shopping_bag', color: _travelColor),
    _reuse('visa_travel_insurance'),
    _reuse('forex'),
    const CategorySeed('trip_misc', 'Tips & Misc', icon: 'more_horiz', color: _travelColor),
  ]),
]);

final CategoryPack weddingPack = CategoryPack(key: 'wedding', icon: 'favorite', roots: [
  CategorySeed('wedding', 'Wedding', icon: 'favorite', color: _weddingColor, children: [
    const CategorySeed('wedding_venue', 'Venue & Banquet', icon: 'museum', color: _weddingColor),
    const CategorySeed('wedding_catering', 'Catering', icon: 'restaurant', color: _weddingColor, units: ['plate']),
    const CategorySeed('wedding_decor', 'Decoration & Flowers', icon: 'local_florist', color: _weddingColor),
    const CategorySeed('wedding_outfits', 'Bride & Groom Outfits', icon: 'checkroom', color: _weddingColor),
    const CategorySeed('wedding_family_clothes', 'Family Clothes', icon: 'checkroom', color: _weddingColor),
    _reuse('jewellery'),
    const CategorySeed('wedding_photo', 'Photography & Video', icon: 'camera_alt', color: _weddingColor),
    const CategorySeed('wedding_makeup', 'Makeup & Mehndi', icon: 'face', color: _weddingColor),
    const CategorySeed('wedding_band', 'Band, DJ & Baraat', icon: 'music_note', color: _weddingColor),
    const CategorySeed('wedding_cards', 'Invitation Cards', icon: 'mail', color: _weddingColor),
    const CategorySeed('wedding_pandit', 'Pandit & Puja', icon: 'temple_hindu', color: _weddingColor),
    _reuse('shagun'),
    _reuse('gifts_given'),
    const CategorySeed('wedding_guest_travel', 'Guest Travel & Stay', icon: 'hotel', color: _weddingColor),
    const CategorySeed('wedding_honeymoon', 'Honeymoon', icon: 'beach_access', color: _weddingColor),
    const CategorySeed('wedding_misc', 'Wedding Misc', icon: 'more_horiz', color: _weddingColor),
  ]),
  _reuse('gifts_received'),
]);

const _babyColor = 0xFFF06292;
const _petColor = 0xFF7CB342;
const _medicalColor = 0xFFE53935;
const _educationColor = 0xFF3949AB;
const _incomeColor = 0xFF2E7D32;
const _farmColor = 0xFF689F38;
const _shopColor = 0xFF5D4037;
const _festivalColor = 0xFFFF8F00;
const _eventColor = 0xFF8E24AA;

final CategoryPack babyPack = CategoryPack(key: 'baby', icon: 'child_care', roots: [
  CategorySeed('baby', 'Baby & Child', icon: 'child_care', color: _babyColor, children: [
    const CategorySeed('baby_delivery', 'Delivery & Hospital', icon: 'local_hospital', color: _babyColor),
    const CategorySeed('baby_doctor', 'Doctor & Vaccinations', icon: 'healing', color: _babyColor),
    const CategorySeed('baby_diapers', 'Diapers & Hygiene', icon: 'child_friendly', color: _babyColor, units: ['pack', 'pcs']),
    const CategorySeed('baby_food', 'Food & Formula', icon: 'local_drink', color: _babyColor, units: ['tin', 'pack']),
    const CategorySeed('baby_clothes', 'Baby Clothes', icon: 'checkroom', color: _babyColor),
    const CategorySeed('baby_toys_books', 'Toys & Books', icon: 'toys', color: _babyColor),
    const CategorySeed('baby_gear', 'Gear (pram, crib, car seat)', icon: 'crib', color: _babyColor),
    _reuse('daycare'),
    _reuse('nanny'),
    const CategorySeed('baby_ceremonies', 'Ceremonies & Birthdays', icon: 'cake', color: _babyColor),
    const CategorySeed('baby_playschool', 'Playschool', icon: 'school', color: _babyColor),
  ]),
]);

final CategoryPack petPack = CategoryPack(key: 'pet', icon: 'pets', roots: [
  _reuseParent('pets', [
    _reuse('pet_food'),
    _reuse('vet'),
    const CategorySeed('pet_vaccination', 'Vaccination & Deworming', icon: 'medication', color: _petColor),
    const CategorySeed('pet_medicines', 'Pet Medicines', icon: 'local_pharmacy', color: _petColor),
    _reuse('pet_grooming'),
    const CategorySeed('pet_accessories', 'Pet Accessories & Toys', icon: 'toys', color: _petColor),
    const CategorySeed('pet_boarding', 'Boarding & Walker', icon: 'hiking', color: _petColor),
    const CategorySeed('pet_insurance', 'Pet Insurance & Licence', icon: 'verified_user', color: _petColor),
  ]),
]);

final CategoryPack farmingPack = CategoryPack(key: 'farming', icon: 'eco', roots: [
  const CategorySeed('farming', 'Farming', icon: 'eco', color: _farmColor, children: [
    CategorySeed('farm_seeds', 'Seeds', icon: 'eco', color: _farmColor, units: ['kg', 'bag']),
    CategorySeed('farm_fertiliser', 'Fertiliser', icon: 'yard', color: _farmColor, units: ['bag', 'kg']),
    CategorySeed('farm_pesticides', 'Pesticides', icon: 'water_drop', color: _farmColor, units: ['L', 'bottle']),
    CategorySeed('farm_irrigation', 'Irrigation, Water & Diesel', icon: 'water', color: _farmColor, units: ['L', 'hour']),
    CategorySeed('farm_electricity', 'Farm Electricity', icon: 'electric_bolt', color: _farmColor),
    CategorySeed('farm_labour', 'Farm Labour', icon: 'groups', color: _farmColor, units: ['day']),
    CategorySeed('farm_machine_hire', 'Tractor & Machine Hire', icon: 'engineering', color: _farmColor, units: ['hour', 'acre']),
    CategorySeed('farm_harvest', 'Harvesting & Threshing', icon: 'handyman', color: _farmColor),
    CategorySeed('farm_transport', 'Transport to Mandi', icon: 'local_shipping', color: _farmColor),
    CategorySeed('farm_land_lease', 'Land Lease', icon: 'map', color: _farmColor),
    CategorySeed('farm_storage', 'Storage', icon: 'garage', color: _farmColor),
    CategorySeed('farm_loan_interest', 'Farm Loan Interest', icon: 'percent', color: _farmColor),
    CategorySeed('farm_tools', 'Tools & Repairs', icon: 'build', color: _farmColor),
  ]),
  const CategorySeed('farm_crop_sale', 'Crop Sale', icon: 'sell', color: _incomeColor, kind: CategoryKind.income),
  const CategorySeed('farm_subsidy', 'Subsidy & PM-Kisan', icon: 'account_balance', color: _incomeColor, kind: CategoryKind.income),
  const CategorySeed('farm_dairy_income', 'Dairy & Other Farm Income', icon: 'local_drink', color: _incomeColor, kind: CategoryKind.income),
]);

final CategoryPack shopPack = CategoryPack(key: 'shop', icon: 'storefront', roots: [
  CategorySeed('shop', 'Shop', icon: 'storefront', color: _shopColor, children: [
    const CategorySeed('shop_stock', 'Stock Purchase', icon: 'shopping_basket', color: _shopColor),
    const CategorySeed('shop_rent', 'Shop Rent', icon: 'storefront', color: _shopColor),
    const CategorySeed('shop_electricity', 'Shop Electricity', icon: 'electric_bolt', color: _shopColor),
    const CategorySeed('shop_staff', 'Staff Salary', icon: 'groups', color: _shopColor),
    const CategorySeed('shop_packaging', 'Packaging', icon: 'card_travel', color: _shopColor),
    const CategorySeed('shop_transport', 'Shop Transport', icon: 'local_shipping', color: _shopColor),
    const CategorySeed('shop_licence_gst', 'Licence & GST Paid', icon: 'request_quote', color: _shopColor),
    const CategorySeed('shop_repairs', 'Shop Repairs', icon: 'handyman', color: _shopColor),
  ]),
  const CategorySeed('shop_sales_cash', 'Sales (Cash)', icon: 'payments', color: _incomeColor, kind: CategoryKind.income),
  const CategorySeed('shop_sales_upi', 'Sales (UPI)', icon: 'qr_code', color: _incomeColor, kind: CategoryKind.income),
  const CategorySeed('shop_udhaar_recovered', 'Udhaar Recovered', icon: 'handshake', color: _incomeColor, kind: CategoryKind.income),
]);

final CategoryPack medicalPack = CategoryPack(key: 'medical', icon: 'medical_services', roots: [
  _reuseParent('health', [
    _reuse('doctor'),
    _reuse('medicines'),
    _reuse('lab_tests'),
    _reuse('hospital'),
    const CategorySeed('medical_physio', 'Physio & Therapy', icon: 'self_improvement', color: _medicalColor),
    _reuse('dental_eye'),
    _reuse('health_insurance'),
    const CategorySeed('medical_checkup', 'Preventive Check-up', icon: 'health_and_safety', color: _medicalColor),
  ]),
  _reuse('reimbursement'),
]);

final CategoryPack educationPack = CategoryPack(key: 'education', icon: 'school', roots: [
  _reuseParent('education', [
    _reuse('school_fees'),
    _reuse('tuition'),
    _reuse('study_material'),
    const CategorySeed('edu_uniform', 'Uniform & Shoes', icon: 'checkroom', color: _educationColor),
    const CategorySeed('edu_school_bus', 'School Bus', icon: 'directions_bus', color: _educationColor),
    const CategorySeed('edu_exam_admission', 'Exam & Admission Fees', icon: 'receipt_long', color: _educationColor),
    const CategorySeed('edu_hostel', 'Hostel', icon: 'bed', color: _educationColor),
    const CategorySeed('edu_activities', 'Activities & Sports', icon: 'sports_cricket', color: _educationColor),
    _reuse('courses'),
    _reuse('education_loan'),
  ]),
]);

final CategoryPack festivalPack = CategoryPack(key: 'festival', icon: 'celebration', roots: [
  CategorySeed('festival', 'Festivals', icon: 'celebration', color: _festivalColor, children: [
    _reuse('festivals_puja'),
    const CategorySeed('festival_clothes', 'Festival Clothes', icon: 'checkroom', color: _festivalColor),
    const CategorySeed('festival_gifts', 'Festival Gifts', icon: 'card_giftcard', color: _festivalColor),
    const CategorySeed('festival_sweets', 'Sweets & Food', icon: 'bakery_dining', color: _festivalColor, units: ['kg', 'box']),
    const CategorySeed('festival_decoration', 'Decoration & Lights', icon: 'lightbulb', color: _festivalColor),
    const CategorySeed('festival_puja_items', 'Puja Items', icon: 'temple_hindu', color: _festivalColor),
    const CategorySeed('festival_crackers', 'Crackers', icon: 'celebration', color: _festivalColor),
    const CategorySeed('festival_gold', 'Gold & Jewellery', icon: 'diamond', color: _festivalColor),
    const CategorySeed('festival_travel_home', 'Travel Home', icon: 'train', color: _festivalColor),
    const CategorySeed('festival_bakshish', 'Bakshish & Tips', icon: 'thumb_up', color: _festivalColor),
    _reuse('donation'),
  ]),
]);

final CategoryPack eventPack = CategoryPack(key: 'event', icon: 'cake', roots: [
  const CategorySeed('event', 'Event & Party', icon: 'cake', color: _eventColor, children: [
    CategorySeed('event_venue', 'Event Venue', icon: 'museum', color: _eventColor),
    CategorySeed('event_food_cake', 'Food & Cake', icon: 'cake', color: _eventColor),
    CategorySeed('event_decoration', 'Event Decoration', icon: 'local_florist', color: _eventColor),
    CategorySeed('event_return_gifts', 'Return Gifts', icon: 'card_giftcard', color: _eventColor),
    CategorySeed('event_invites', 'Invites', icon: 'mail', color: _eventColor),
    CategorySeed('event_photography', 'Event Photography', icon: 'camera_alt', color: _eventColor),
    CategorySeed('event_puja', 'Event Puja', icon: 'temple_hindu', color: _eventColor),
  ]),
]);

/// Every pack, in the order shown to the user.
final List<CategoryPack> categoryPacks = [
  vehiclePack, constructionPack, renovationPack, tripPack, weddingPack,
  babyPack, petPack, farmingPack, shopPack, medicalPack, educationPack, festivalPack, eventPack,
];

CategoryPack? packByKey(String? key) {
  for (final pack in categoryPacks) {
    if (pack.key == key) return pack;
  }
  return null;
}

/// Seeds that packs add on top of the catalog (reused catalog seeds excluded),
/// each once even when several packs share it.
List<CategorySeed> packOnlySeeds() {
  final catalogKeys = flattenCatalog().map((seed) => seed.key).toSet();
  final seen = <String>{};
  return [
    for (final pack in categoryPacks)
      for (final seed in flattenCatalog(pack.roots))
        if (!catalogKeys.contains(seed.key) && seen.add(seed.key)) seed,
  ];
}

/// Seed keys that only packs bring (not in the everyday catalog), for one pack.
Set<String> packOwnSeedKeys(CategoryPack pack) {
  final catalogKeys = flattenCatalog().map((seed) => seed.key).toSet();
  return {for (final seed in flattenCatalog(pack.roots)) if (!catalogKeys.contains(seed.key)) seed.key};
}

/// The bits of a stored category that pack removal looks at.
class PackCategoryRef {
  const PackCategoryRef({required this.id, required this.parentId, required this.packKey, required this.isArchived, this.seedKey});
  final String id;
  final String? parentId;
  final String? packKey;
  final bool isArchived;
  final String? seedKey;
}

/// What removing a pack does: [archiveIds] are the pack's categories nothing
/// uses; [keepIds] are in use (or hold a category that is) and stay as
/// ordinary categories without the pack tag; [handOver] maps categories that
/// another added pack also lists to that pack's key, so they stay with it.
class PackRemoval {
  const PackRemoval({required this.archiveIds, required this.keepIds, this.handOver = const {}});
  final List<String> archiveIds;
  final List<String> keepIds;
  final Map<String, String> handOver;
}

/// Plans removing pack [packKey] from [categories]. A category is in use when
/// its id is in [usedIds] or it has a live child that stays (a child from
/// another pack, one the user made, or a used child of this pack). Categories
/// whose seed another added pack in [otherPacks] lists move to that pack.
PackRemoval planPackRemoval({
  required String packKey,
  required List<PackCategoryRef> categories,
  required Set<String> usedIds,
  List<CategoryPack> otherPacks = const [],
}) {
  final addedOthers = addedPackKeys(categories)..remove(packKey);
  final otherOwner = <String, String>{
    for (final pack in otherPacks.where((pack) => addedOthers.contains(pack.key)))
      for (final seedKey in packOwnSeedKeys(pack)) seedKey: pack.key,
  };
  final childrenOf = <String, List<PackCategoryRef>>{};
  for (final category in categories) {
    final parentId = category.parentId;
    if (parentId != null && !category.isArchived) childrenOf.putIfAbsent(parentId, () => []).add(category);
  }
  String? newOwner(PackCategoryRef category) => category.seedKey == null ? null : otherOwner[category.seedKey];
  bool stays(PackCategoryRef category) =>
      category.packKey != packKey ||
      usedIds.contains(category.id) ||
      newOwner(category) != null ||
      (childrenOf[category.id] ?? const []).any(stays);
  final candidates = categories.where((category) => category.packKey == packKey && !category.isArchived).toList();
  return PackRemoval(
    archiveIds: [for (final category in candidates) if (!stays(category)) category.id],
    keepIds: [for (final category in candidates) if (stays(category) && newOwner(category) == null) category.id],
    handOver: {for (final category in candidates) if (newOwner(category) != null) category.id: newOwner(category)!},
  );
}

/// Packs that are on: some live category still carries the pack's key.
Set<String> addedPackKeys(Iterable<PackCategoryRef> categories) => {
      for (final category in categories)
        if (!category.isArchived && category.packKey != null) category.packKey!,
    };
