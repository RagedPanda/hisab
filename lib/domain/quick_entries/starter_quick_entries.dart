/// The quick entries a new install starts with, so Home shows what the
/// strip is for before the user saves one. They carry no amount, so a tap
/// opens the editor prefilled; the user can edit, add or delete them. Pure.
library;

/// One starter: a fixed id, so a backup restored onto another install
/// merges with its copy instead of doubling it, and the seeded category
/// it files under.
typedef StarterQuickEntry = ({String id, String label, String categorySeedKey});

const List<StarterQuickEntry> kStarterQuickEntries = [
  (id: 'seed.quick.milk', label: 'Milk', categorySeedKey: 'milk_dairy'),
  (id: 'seed.quick.tea', label: 'Tea & snacks', categorySeedKey: 'snacks_tea'),
  (id: 'seed.quick.petrol', label: 'Petrol', categorySeedKey: 'fuel'),
  (id: 'seed.quick.auto', label: 'Auto / cab', categorySeedKey: 'cab_auto'),
];

/// The starters to insert, each with its category id from [categoryIdBySeedKey]
/// (null when that category is missing), or none when the install already
/// had quick entries ([hasAnyQuickEntry], deleted ones included), so a user
/// who removed them never gets them back.
List<({StarterQuickEntry starter, String? categoryId, int sortOrder})> starterQuickEntryRows({
  required bool hasAnyQuickEntry,
  required Map<String, String> categoryIdBySeedKey,
}) =>
    hasAnyQuickEntry
        ? const []
        : [
            for (final (index, starter) in kStarterQuickEntries.indexed)
              (starter: starter, categoryId: categoryIdBySeedKey[starter.categorySeedKey], sortOrder: index),
          ];
