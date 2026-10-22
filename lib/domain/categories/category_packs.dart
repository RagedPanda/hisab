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
const _travelColor = 0xFF039BE5;
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

/// Every pack, in the order shown to the user.
final List<CategoryPack> categoryPacks = [vehiclePack, constructionPack, renovationPack, tripPack, weddingPack];

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
