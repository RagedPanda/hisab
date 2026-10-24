import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/format.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

String weightLabel(String languageCode, double weight) =>
    lookupAppLocalizations(Locale(languageCode)).groupSettingsWeightValue(weight, formatQuantity(weight, null));

void main() {
  test('English share weights use "share" only for exactly one', () {
    expect([for (final weight in [0.5, 1.0, 1.5, 2.0]) weightLabel('en', weight)], ['0.5 shares', '1 share', '1.5 shares', '2 shares']);
  });

  test('Hindi share weights use the singular only for exactly one', () {
    expect([for (final weight in [0.5, 1.0, 1.5, 2.0]) weightLabel('hi', weight)], ['0.5 हिस्से', '1 हिस्सा', '1.5 हिस्से', '2 हिस्से']);
  });
}
