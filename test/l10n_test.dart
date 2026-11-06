import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/categories/category_catalog.dart';
import 'package:hisab/domain/categories/category_packs.dart';
import 'package:hisab/l10n/category_names.dart';
import 'package:hisab/l10n/generated/app_localizations_hi.dart';

void main() {
  final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
  final messageKeys = english.keys.where((key) => !key.startsWith('@')).toSet();
  final placeholders = RegExp(r'\{(\w+)\}');

  for (final language in ['hi']) {
    final translated = jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync()) as Map<String, dynamic>;
    test('$language dictionary covers every English key', () {
      final missing = messageKeys.difference(translated.keys.toSet());
      expect(missing, isEmpty, reason: 'missing in app_$language.arb');
      final extra = translated.keys.where((key) => !key.startsWith('@')).toSet().difference(messageKeys);
      expect(extra, isEmpty, reason: 'not in app_en.arb');
    });
    test('$language dictionary keeps every placeholder', () {
      for (final key in messageKeys) {
        final expected = placeholders.allMatches(english[key] as String).map((m) => m.group(1)).toSet();
        final actual = placeholders.allMatches(translated[key] as String).map((m) => m.group(1)).toSet();
        expect(actual, expected, reason: key);
      }
    });
    test('$language category names cover every seed key', () {
      final seedKeys = [...flattenCatalog(), ...packOnlySeeds()].map((seed) => seed.key).toSet();
      final names = localizedCategoryNames[language]!;
      expect(seedKeys.difference(names.keys.toSet()), isEmpty);
      expect(names.keys.toSet().difference(seedKeys), isEmpty);
      expect(names.values.where((name) => name.trim().isEmpty), isEmpty);
    });
  }

  test('Hindi counts zero results as zero, not one', () {
    // Hindi plural rules put 0 in "one", so a bare =1 case would read "1 नतीजा".
    final hindi = AppLocalizationsHi();
    expect(hindi.resultsCount(0), '0 नतीजे');
    expect(hindi.resultsCount(1), '1 नतीजा');
    expect(hindi.resultsCount(4), '4 नतीजे');
  });
}
