import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/split_this.dart';

void main() {
  group('canSplitEntry', () {
    test('a personal expense can be split', () {
      expect(canSplitEntry(kind: 'expense', groupId: null), isTrue);
    });

    test('income and transfers cannot', () {
      expect(canSplitEntry(kind: 'income', groupId: null), isFalse);
      expect(canSplitEntry(kind: 'transfer', groupId: null), isFalse);
    });

    test('an expense already in a group cannot', () {
      expect(canSplitEntry(kind: 'expense', groupId: 'g1'), isFalse);
    });
  });

  group('splitTargetGroups', () {
    List<String> targets(List<({String name, bool archived, bool me})> groups) => [
          for (final group in splitTargetGroups(groups, isArchived: (group) => group.archived, includesMe: (group) => group.me)) group.name,
        ];

    test('keeps live groups I am in, in order', () {
      expect(
        targets([(name: 'Flat', archived: false, me: true), (name: 'Goa', archived: false, me: true)]),
        ['Flat', 'Goa'],
      );
    });

    test('leaves out archived groups and ones I left', () {
      expect(
        targets([(name: 'Old trip', archived: true, me: true), (name: 'Left', archived: false, me: false), (name: 'Flat', archived: false, me: true)]),
        ['Flat'],
      );
    });

    test('no groups gives none', () {
      expect(targets([]), isEmpty);
    });
  });
}
