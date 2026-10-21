import 'package:flutter/widgets.dart';

import '../data/db/database.dart';
import '../domain/categories/category_catalog.dart';

/// Translated names for the built-in categories, keyed by language code and
/// then by the seed key from `category_catalog.dart`. English is the catalog
/// itself. To add a language, add one map here; keys you leave out fall back
/// to English. User-renamed categories always keep the user's name.
const Map<String, Map<String, String>> localizedCategoryNames = {
  // 'hi': {'food': 'खाना-पीना', 'groceries': 'किराना', ...},
};

final Map<String, String> _englishNameBySeedKey = {
  for (final seed in flattenCatalog()) seed.key: seed.name,
};

/// Display name for a category in [locale]: the user's own name if they
/// renamed it, otherwise the translation for its seed key, otherwise English.
String categoryDisplayName(Category category, Locale locale) {
  final seedKey = category.seedKey;
  if (seedKey == null) return category.name;
  final english = _englishNameBySeedKey[seedKey];
  if (english != null && english != category.name) return category.name;
  return localizedCategoryNames[locale.languageCode]?[seedKey] ?? category.name;
}

extension CategoryDisplayName on Category {
  String displayName(BuildContext context) => categoryDisplayName(this, Localizations.localeOf(context));
}
