import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/people/people.dart';

void main() {
  group('normaliseEmail', () {
    test('trims and lowercases an email', () {
      expect(normaliseEmail('  Amit@Gmail.COM '), 'amit@gmail.com');
    });

    test('is null for blank text or text that is not an email', () {
      for (final raw in [null, '', '   ', 'amit', 'amit@gmail', '@gmail.com', 'amit kumar@gmail.com']) {
        expect(normaliseEmail(raw), isNull, reason: '$raw');
      }
    });

    test('a blank email is not an error, a malformed one is', () {
      expect(isInvalidEmail('  '), isFalse);
      expect(isInvalidEmail('amit@gmail'), isTrue);
      expect(isInvalidEmail('amit@gmail.com'), isFalse);
    });
  });

  group('matchingPeople', () {
    const amit = (name: 'Amit', email: 'amit@gmail.com');
    const kamala = (name: 'Kamala', email: 'kamala@yahoo.com');
    const riya = (name: 'Riya', email: 'riya.amit@outlook.com');
    const people = [riya, kamala, amit];

    test('a blank query suggests nobody', () {
      expect(matchingPeople(people, '  '), isEmpty);
    });

    test('matches name or email, ignoring case, prefix matches first', () {
      expect(matchingPeople(people, 'AM'), [amit, kamala, riya]);
      expect(matchingPeople(people, 'yahoo'), [kamala]);
    });

    test('skips people already in the group', () {
      expect(matchingPeople(people, 'am', excludeEmails: {'amit@gmail.com'}), [kamala, riya]);
    });

    test('returns at most the limit', () {
      expect(matchingPeople(people, 'a', limit: 2), hasLength(2));
    });
  });
}
