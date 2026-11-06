import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/entries/entry_filter.dart';
import 'package:hisab/domain/entries/tag_edits.dart';

void main() {
  group('tagNameFrom', () {
    test('tidies one tag the way parseTags does', () {
      expect(tagNameFrom('  #Ice   cream '), 'Ice cream');
      expect(tagNameFrom('##trip'), 'trip');
      expect(tagNameFrom('दिवाली  ख़रीदारी'), 'दिवाली ख़रीदारी');
    });

    test('refuses blanks and anything that would make more than one tag', () {
      for (final input in ['', '   ', '#', 'food, trip', 'food,', 'खाना，यात्रा', 'a、b', '#food #trip', 'food #trip', 'two\nlines']) {
        expect(tagNameFrom(input), isNull, reason: input);
      }
    });
  });

  group('countTags', () {
    test('counts entries per tag, most used first, then by name', () {
      expect(countTags(['trip, food', 'Food', 'goa', 'trip', '#food #Goa', '']), [
        (tag: 'food', count: 3),
        (tag: 'goa', count: 2),
        (tag: 'trip', count: 2),
      ]);
    });

    test('ties sort by name ignoring case, and a tag twice on one entry counts once', () {
      expect(countTags(['beta, Alpha', 'alpha, ALPHA', 'Beta']), [(tag: 'Alpha', count: 2), (tag: 'beta', count: 2)]);
    });

    test('Hindi tags and tags with spaces', () {
      expect(countTags(['दिवाली, ice cream', 'Ice  Cream', 'दिवाली']), [(tag: 'ice cream', count: 2), (tag: 'दिवाली', count: 2)]);
    });

    test('nothing tagged gives nothing', () => expect(countTags(['', '  ', ', ,']), isEmpty));
  });

  group('otherTagNamed', () {
    const tags = ['Trip', 'food', 'दिवाली'];

    test('finds another tag ignoring case', () {
      expect(otherTagNamed('trip', tags, except: 'goa'), 'Trip');
      expect(otherTagNamed('दिवाली', tags, except: 'goa'), 'दिवाली');
      expect(otherTagNamed('new', tags, except: 'goa'), isNull);
    });

    test('a case change of the tag itself is not a merge', () => expect(otherTagNamed('TRIP', tags, except: 'trip'), isNull));
  });

  group('withTagRenamed', () {
    test('renames in place, ignoring case', () {
      expect(withTagRenamed('home, Goa, food', 'goa', 'Goa 2026'), 'home, Goa 2026, food');
      expect(withTagRenamed('#home #goa', 'GOA', 'beach'), 'home, beach');
    });

    test('leaves text without the tag exactly as it was', () {
      expect(withTagRenamed('#home  #trip', 'goa', 'beach'), '#home  #trip');
      expect(withTagRenamed('', 'goa', 'beach'), '');
      expect(withTagRenamed('goa trip', 'goa', 'beach'), 'goa trip', reason: 'a tag only matches whole');
    });

    test('merging onto a tag the entry already has leaves one, spelled as the target', () {
      expect(withTagRenamed('goa, trip', 'goa', 'trip'), 'trip');
      expect(withTagRenamed('Trip, goa, food', 'goa', 'trip'), 'trip, food');
      expect(withTagRenamed('food, goa, TRIP', 'goa', 'Trip'), 'food, Trip');
    });

    test('a case-only rename respells it', () => expect(withTagRenamed('food, trip', 'trip', 'Trip'), 'food, Trip'));

    test('Hindi and spaced tags', () {
      expect(withTagRenamed('दिवाली, ice cream', 'ice cream', 'मिठाई'), 'दिवाली, मिठाई');
      expect(withTagRenamed('दिवाली, मिठाई', 'दिवाली', 'मिठाई'), 'मिठाई');
    });
  });

  group('withoutTag', () {
    test('removes the tag ignoring case and keeps the rest in order', () {
      expect(withoutTag('home, Trip, food', 'trip'), 'home, food');
      expect(withoutTag('#ice cream #दिवाली', 'दिवाली'), 'ice cream');
      expect(withoutTag('trip', 'TRIP'), '');
    });

    test('leaves text without the tag exactly as it was', () => expect(withoutTag('#home  #food', 'trip'), '#home  #food'));
  });
}
