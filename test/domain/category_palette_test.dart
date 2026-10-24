import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/categories/category_catalog.dart';

/// CIE L*a*b* (D65) of an ARGB colour.
List<double> toLab(int argb) {
  double linear(int channel) {
    final value = channel / 255;
    return value > 0.04045 ? math.pow((value + 0.055) / 1.055, 2.4).toDouble() : value / 12.92;
  }

  final red = linear((argb >> 16) & 0xFF), green = linear((argb >> 8) & 0xFF), blue = linear(argb & 0xFF);
  final x = (red * 0.4124 + green * 0.3576 + blue * 0.1805) / 0.95047;
  final y = red * 0.2126 + green * 0.7152 + blue * 0.0722;
  final z = (red * 0.0193 + green * 0.1192 + blue * 0.9505) / 1.08883;
  double curve(double value) => value > 0.008856 ? math.pow(value, 1 / 3).toDouble() : 7.787 * value + 16 / 116;
  return [116 * curve(y) - 16, 500 * (curve(x) - curve(y)), 200 * (curve(y) - curve(z))];
}

double deltaE(int first, int second) {
  final a = toLab(first), b = toLab(second);
  return math.sqrt(math.pow(a[0] - b[0], 2) + math.pow(a[1] - b[1], 2) + math.pow(a[2] - b[2], 2));
}

void main() {
  final expenseParents = categoryCatalog.where((seed) => seed.kind == CategoryKind.expense).toList();

  test('every two expense parents have clearly different colours', () {
    for (var first = 0; first < expenseParents.length; first++) {
      for (var second = first + 1; second < expenseParents.length; second++) {
        final a = expenseParents[first], b = expenseParents[second];
        expect(deltaE(a.color, b.color), greaterThanOrEqualTo(20), reason: '${a.key} vs ${b.key}');
      }
    }
  });

  test('Transport and Travel are no longer two blues', () {
    expect(deltaE(findSeed('transport')!.color, findSeed('travel')!.color), greaterThan(50));
  });

  test('a seed on a retired default moves to its current colour, once', () {
    final travel = findSeed('travel')!.color;
    expect(recolouredSeed(current: 0xFF039BE5, seedColor: travel), travel);
    expect(recolouredSeed(current: travel, seedColor: travel), isNull);
  });

  test('a colour the user picked, or a retired colour meant for another seed, is left alone', () {
    expect(recolouredSeed(current: 0xFF123456, seedColor: findSeed('travel')!.color), isNull);
    // Old Social lime is now Family's colour; a Family row on it stays put.
    expect(recolouredSeed(current: 0xFFC0CA33, seedColor: findSeed('family')!.color), isNull);
    expect(recolouredSeed(current: 0xFFC0CA33, seedColor: findSeed('social')!.color), findSeed('social')!.color);
  });

  test('retired colours never map back onto another retired colour', () {
    for (final replacement in retiredSeedColors.values) {
      expect(retiredSeedColors[replacement], anyOf(isNull, isNot(replacement)));
    }
  });
}
