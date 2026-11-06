import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/categories/category_suggestion.dart';
import 'package:hisab/domain/sms/sms_categorizer.dart';

CategoryOption _option(String id, List<String> names, {String? parentId, String? seedKey}) => (id: id, parentId: parentId, seedKey: seedKey, names: names);

void main() {
  final options = [
    _option('food', ['Food & Dining', 'खाना-पीना'], seedKey: 'food'),
    _option('sweets', ['Bakery & Sweets', 'बेकरी और मिठाई'], parentId: 'food', seedKey: 'bakery_sweets'),
    _option('tea', ['Snacks, Tea & Coffee'], parentId: 'food', seedKey: 'snacks_tea'),
    _option('transport', ['Transport'], seedKey: 'transport'),
    _option('fuel', ['Fuel'], parentId: 'transport', seedKey: 'fuel'),
    _option('cafe', ['Café visits'], parentId: 'food'),
  ];

  test('foldCategoryName ignores case, spacing and accents', () {
    expect(foldCategoryName('  Café   Visits '), 'cafe visits');
    expect(foldCategoryName('NAÏVE Crème'), 'naive creme');
    expect(foldCategoryName('खाना-पीना'), 'खाना-पीना');
  });

  test('categoryNameFromQuery capitalises the first letter and keeps the rest as typed', () {
    expect(categoryNameFromQuery('  ice   cream '), 'Ice cream');
    expect(categoryNameFromQuery('iPhone case'), 'IPhone case');
    expect(categoryNameFromQuery('आइसक्रीम'), 'आइसक्रीम');
    expect(categoryNameFromQuery('   '), '');
  });

  group('hasCategoryNamed', () {
    test('matches a stored or localised name exactly', () {
      expect(hasCategoryNamed('fuel', options), isTrue);
      expect(hasCategoryNamed(' FOOD  &  dining ', options), isTrue);
      expect(hasCategoryNamed('खाना-पीना', options), isTrue, reason: 'the Hindi label counts');
      expect(hasCategoryNamed('cafe visits', options), isTrue, reason: 'accents ignored');
    });

    test('a partial match is not an exact one', () {
      expect(hasCategoryNamed('food', options), isFalse);
      expect(hasCategoryNamed('ice cream', options), isFalse);
      expect(hasCategoryNamed('', options), isFalse);
    });
  });

  test('existingCategoryNamed looks under the same parent only', () {
    expect(existingCategoryNamed('fuel', options, parentId: 'transport')?.id, 'fuel');
    expect(existingCategoryNamed('Fuel', options), isNull, reason: 'a top-level Fuel would be a different category');
    expect(existingCategoryNamed('transport', options)?.id, 'transport');
    expect(existingCategoryNamed('बेकरी और मिठाई', options, parentId: 'food')?.id, 'sweets');
    expect(existingCategoryNamed('  ', options), isNull);
  });

  group('suggestParentId', () {
    test('follows the category sharing the most words', () {
      expect(suggestParentId('Coffee beans', options), 'food');
      expect(suggestParentId('Fuel for generator', options), 'transport');
      expect(suggestParentId('Sweets box', options), 'food');
      expect(suggestParentId('Transport passes', options), 'transport', reason: 'a top-level match is its own parent');
      expect(suggestParentId(' transport ', options), isNull, reason: 'the name of a top-level category is that category, not a child of it');
      expect(suggestParentId('खाना-पीना', options), isNull);
      expect(suggestParentId('fuel', options), 'transport', reason: 'a subcategory name still points at its parent');
    });

    test('falls back to the keyword guess, then to nothing', () {
      expect(suggestParentId('Ice cream', options, keywordKey: categoryKeyForText('Ice cream')), 'food');
      expect(suggestParentId('Ice cream', options), isNull);
      expect(suggestParentId('Zzz', options, keywordKey: 'not_a_category'), isNull);
    });

    test('words shorter than three letters are ignored', () {
      expect(suggestParentId('Te', options), isNull);
    });
  });

  test('categoryKeyForText reuses the merchant keywords', () {
    expect(categoryKeyForText('Ice cream'), 'bakery_sweets');
    expect(categoryKeyForText('Kulfi'), 'bakery_sweets');
    expect(categoryKeyForText('Petrol'), 'fuel');
    expect(categoryKeyForText('Something new'), isNull);
  });

  test('nextCategoryColor takes the first unused palette colour, then cycles', () {
    expect(nextCategoryColor([1, 2], [1, 2, 3, 4]), 3);
    expect(nextCategoryColor([1, 2, 3, 4, 1], [1, 2, 3, 4]), 2);
    expect(nextCategoryColor([], [7, 8]), 7);
  });
}
