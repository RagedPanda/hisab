import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/entries/entry_filter.dart';

EntryFacts _facts({
  int amountMinor = 50000,
  DateTime? occurredAt,
  String note = '',
  String? payee,
  String? categoryId,
  String? categoryParentId,
  List<String> categoryNames = const [],
  List<String> itemNames = const [],
  String? accountId,
  String? toAccountId,
  String? projectId,
  String tags = '',
}) =>
    EntryFacts(
      amountMinor: amountMinor,
      occurredAt: occurredAt ?? DateTime(2026, 10, 15, 12),
      note: note,
      payee: payee,
      categoryId: categoryId,
      categoryParentId: categoryParentId,
      categoryNames: categoryNames,
      itemNames: itemNames,
      accountId: accountId,
      toAccountId: toAccountId,
      projectId: projectId,
      tags: tags,
    );

void main() {
  group('matchesSearch', () {
    final entry = _facts(payee: 'Sharma Dairy', note: 'Morning milk', itemNames: ['Buffalo milk', 'Paneer'], categoryNames: ['Dairy', 'डेयरी'], tags: '#home');

    test('blank query matches', () => expect(matchesSearch('  ', entry), isTrue));
    test('finds payee ignoring case', () => expect(matchesSearch('sharma', entry), isTrue));
    test('finds note', () => expect(matchesSearch('MORNING', entry), isTrue));
    test('finds item names', () => expect(matchesSearch('paneer', entry), isTrue));
    test('finds localised category names', () => expect(matchesSearch('डेयरी', entry), isTrue));
    test('finds tags', () => expect(matchesSearch('home', entry), isTrue));
    test('misses unrelated text', () => expect(matchesSearch('petrol', entry), isFalse));
    test('a payee-less entry still searches its note', () => expect(matchesSearch('fuel', _facts(note: 'fuel top-up')), isTrue));
  });

  group('matchesEntryFilter', () {
    test('an empty filter lets everything through', () {
      expect(const EntryFilter().isEmpty, isTrue);
      expect(matchesEntryFilter(const EntryFilter(), _facts()), isTrue);
    });

    test('project', () {
      const filter = EntryFilter(projectId: 'p1');
      expect(matchesEntryFilter(filter, _facts(projectId: 'p1')), isTrue);
      expect(matchesEntryFilter(filter, _facts(projectId: 'p2')), isFalse);
      expect(matchesEntryFilter(filter, _facts()), isFalse);
    });

    test('category includes sub-categories; empty id selects uncategorised', () {
      const food = EntryFilter(categoryId: 'food');
      expect(matchesEntryFilter(food, _facts(categoryId: 'food')), isTrue);
      expect(matchesEntryFilter(food, _facts(categoryId: 'dairy', categoryParentId: 'food')), isTrue);
      expect(matchesEntryFilter(food, _facts(categoryId: 'fuel')), isFalse);
      expect(matchesEntryFilter(const EntryFilter(categoryId: ''), _facts()), isTrue);
    });

    test('account matches either side of a transfer', () {
      const filter = EntryFilter(accountId: 'hdfc');
      expect(matchesEntryFilter(filter, _facts(accountId: 'hdfc')), isTrue);
      expect(matchesEntryFilter(filter, _facts(accountId: 'cash', toAccountId: 'hdfc')), isTrue);
      expect(matchesEntryFilter(filter, _facts(accountId: 'cash')), isFalse);
    });

    test('amount bounds are inclusive and ignore sign', () {
      const filter = EntryFilter(minAmountMinor: 10000, maxAmountMinor: 50000);
      expect(matchesEntryFilter(filter, _facts(amountMinor: 10000)), isTrue);
      expect(matchesEntryFilter(filter, _facts(amountMinor: 50000)), isTrue);
      expect(matchesEntryFilter(filter, _facts(amountMinor: -20000)), isTrue);
      expect(matchesEntryFilter(filter, _facts(amountMinor: 9999)), isFalse);
      expect(matchesEntryFilter(filter, _facts(amountMinor: 50001)), isFalse);
      expect(matchesEntryFilter(const EntryFilter(minAmountMinor: 10000), _facts(amountMinor: 900000)), isTrue);
    });

    test('dates are whole days, both inclusive', () {
      final filter = EntryFilter(from: DateTime(2026, 10, 10), to: DateTime(2026, 10, 12));
      expect(matchesEntryFilter(filter, _facts(occurredAt: DateTime(2026, 10, 10))), isTrue);
      expect(matchesEntryFilter(filter, _facts(occurredAt: DateTime(2026, 10, 12, 23, 59))), isTrue);
      expect(matchesEntryFilter(filter, _facts(occurredAt: DateTime(2026, 10, 13))), isFalse);
      expect(matchesEntryFilter(filter, _facts(occurredAt: DateTime(2026, 10, 9, 23, 59))), isFalse);
    });

    test('tag matches a whole tag ignoring case and #', () {
      const filter = EntryFilter(tag: 'Home');
      expect(matchesEntryFilter(filter, _facts(tags: '#home, trip')), isTrue);
      expect(matchesEntryFilter(filter, _facts(tags: 'homework')), isFalse);
    });

    test('every filter that is on must pass', () {
      const filter = EntryFilter(projectId: 'p1', accountId: 'cash');
      expect(matchesEntryFilter(filter, _facts(projectId: 'p1', accountId: 'cash')), isTrue);
      expect(matchesEntryFilter(filter, _facts(projectId: 'p1', accountId: 'hdfc')), isFalse);
    });
  });

  group('EntryFilter', () {
    test('activeCount counts a range once', () {
      expect(EntryFilter(minAmountMinor: 1, maxAmountMinor: 2, from: DateTime(2026), to: DateTime(2026, 2), tag: 'x').activeCount, 3);
    });

    test('copyWith keeps omitted fields and clears with null', () {
      const filter = EntryFilter(projectId: 'p1', categoryId: 'food');
      final next = filter.copyWith(categoryId: null, accountId: 'cash');
      expect(next.projectId, 'p1');
      expect(next.categoryId, isNull);
      expect(next.accountId, 'cash');
    });

    test('dateWindow spans whole days', () {
      final window = EntryFilter(from: DateTime(2026, 10, 10, 15), to: DateTime(2026, 10, 12, 8)).dateWindow!;
      expect(window.start, DateTime(2026, 10, 10));
      expect(window.end, DateTime(2026, 10, 13));
      expect(const EntryFilter().dateWindow, isNull);
    });
  });

  test('formatTags and withTag keep one spelling of each tag', () {
    expect(formatTags(['home', 'trip']), 'home, trip');
    expect(withTag('', 'goa'), 'goa');
    expect(withTag('#home trip', 'Goa'), 'home, trip, Goa');
    expect(withTag('home, Goa', 'goa'), 'home, Goa', reason: 'already there, ignoring case');
  });

  test('parseTags and distinctTags', () {
    expect(parseTags('#home, trip  #Home,,'), ['home', 'trip']);
    expect(parseTags(''), isEmpty);
    expect(distinctTags(['trip, #home', 'Diwali', 'HOME']), ['Diwali', 'home', 'trip']);
  });

  test('validateAmountRange', () {
    expect(validateAmountRange(500, 100), AmountRangeError.minAboveMax);
    expect(validateAmountRange(100, 500), isNull);
    expect(validateAmountRange(null, 500), isNull);
  });
}
