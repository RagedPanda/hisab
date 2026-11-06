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

  group('Hindi plurals with zero', () {
    final hindi = AppLocalizationsHi();
    // Each message at a given count; amounts avoid the digit 1 so a stray singular shows.
    final messages = <String, String Function(int)>{
      'itemCount': hindi.itemCount,
      'budgetLeftWithDays': (n) => hindi.budgetLeftWithDays('₹500', '₹900', n),
      'smsToReview': hindi.smsToReview,
      'paidByPeople': (n) => hindi.paidByPeople('रवि', n),
      'memberCount': hindi.memberCount,
      'suggestedCategoriesNew': hindi.suggestedCategoriesNew,
      'packCategoryCount': hindi.packCategoryCount,
      'travellersCount': hindi.travellersCount,
      'showOlderRows': hindi.showOlderRows,
      'itemBoughtTimes': (n) => hindi.itemBoughtTimes('2 kg', n),
      'reminderNotifyDaysBefore': hindi.reminderNotifyDaysBefore,
      'eveningSummaryReview': hindi.eveningSummaryReview,
      'eveningSummaryDue': hindi.eveningSummaryDue,
      'reminderDueInDays': hindi.reminderDueInDays,
      'reminderOverdueDays': hindi.reminderOverdueDays,
      'recurringEveryDays': hindi.recurringEveryDays,
      'recurringEveryWeeks': hindi.recurringEveryWeeks,
      'recurringEveryMonths': hindi.recurringEveryMonths,
      'recurringEveryYears': hindi.recurringEveryYears,
      'recurringTimes': hindi.recurringTimes,
      'recurringMoreWaiting': hindi.recurringMoreWaiting,
      'recurringToConfirm': hindi.recurringToConfirm,
      'subscriptionsActiveCount': hindi.subscriptionsActiveCount,
      'subscriptionRenewsInDays': hindi.subscriptionRenewsInDays,
      'subscriptionEveryDays': hindi.subscriptionEveryDays,
      'subscriptionEveryWeeks': hindi.subscriptionEveryWeeks,
      'subscriptionEveryMonths': hindi.subscriptionEveryMonths,
      'subscriptionEveryYears': hindi.subscriptionEveryYears,
      'groupTotalsExpenseCount': hindi.groupTotalsExpenseCount,
      'groupSettingsWeightValue': (n) => hindi.groupSettingsWeightValue(n, '$n'),
      'groupSettingsSimplifySaves': hindi.groupSettingsSimplifySaves,
      'recurringAddedSkipped (skipped)': (n) => hindi.recurringAddedSkipped(2, n),
      'smsAutoAddedMany': hindi.smsAutoAddedMany,
      'upcomingOverdueBy': hindi.upcomingOverdueBy,
      'salaryDaysAfter': hindi.salaryDaysAfter,
      'salaryMatchWindowDays': hindi.salaryMatchWindowDays,
      'settleReminderPeopleOweYou': (n) => hindi.settleReminderPeopleOweYou(n, '₹500'),
      'settleWithAction': hindi.settleWithAction,
      'settleWithRecorded': (n) => hindi.settleWithRecorded('रवि', n),
      'removeTagTitle': (n) => hindi.removeTagTitle('ghar', n),
      'resultsCount': hindi.resultsCount,
    };
    final standaloneOne = RegExp(r'(?<!\d)1(?!\d)');

    test('no message reads as singular for 0', () {
      for (final MapEntry(key: name, value: message) in messages.entries) {
        expect(message(0), isNot(message(1)), reason: name);
        expect(message(0), isNot(contains(standaloneOne)), reason: name);
      }
    });

    test('spot checks', () {
      expect(hindi.itemCount(0), '0 आइटम');
      expect(hindi.memberCount(0), '0 सदस्य');
      expect(hindi.smsToReview(0), '0 एसएमएस समीक्षा के लिए');
      expect(hindi.reminderDueInDays(0), 'आज देय');
      expect(hindi.reminderDueInDays(1), 'कल देय');
      expect(hindi.subscriptionRenewsInDays(0), 'आज रिन्यू');
      expect(hindi.removeTagTitle('ghar', 0), '0 प्रविष्टियों से #ghar हटाएँ?');
      expect(hindi.removeTagTitle('ghar', 1), '1 प्रविष्टि से #ghar हटाएँ?');
      expect(hindi.recurringAddedSkipped(0, 0), 'कोई नहीं जोड़ी गई, 0 छोड़ी गईं');
    });

    test('every Hindi plural with =1 also has =0', () {
      // Hindi plural rules put 0 in "one", so a =1 case without =0 reads "1 ..." for zero.
      final arb = jsonDecode(File('lib/l10n/app_hi.arb').readAsStringSync()) as Map<String, dynamic>;
      for (final MapEntry(:key, :value) in arb.entries) {
        if (key.startsWith('@')) continue;
        for (final selectors in pluralSelectors(value as String)) {
          if (selectors.contains('=1') || selectors.contains('one')) expect(selectors, contains('=0'), reason: key);
        }
      }
    });
  });
}

/// The branch selectors (`=0`, `=1`, `other`, ...) of each ICU plural in [message].
List<Set<String>> pluralSelectors(String message) {
  int closing(String text, int open) {
    var depth = 0;
    for (var index = open; index < text.length; index++) {
      if (text[index] == '{') depth++;
      if (text[index] == '}' && --depth == 0) return index;
    }
    throw FormatException('unbalanced braces', text);
  }

  final selector = RegExp(r'\s*(=\d+|\w+)\{');
  return [
    for (final plural in RegExp(r'\{\w+, plural, ').allMatches(message))
      () {
        final body = message.substring(plural.end, closing(message, plural.start));
        final selectors = <String>{};
        var index = 0;
        while (index < body.length) {
          final match = selector.matchAsPrefix(body, index)!;
          selectors.add(match.group(1)!);
          index = closing(body, match.end - 1) + 1;
        }
        return selectors;
      }(),
  ];
}
