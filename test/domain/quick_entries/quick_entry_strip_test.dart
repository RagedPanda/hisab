import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/quick_entries/quick_entry_strip.dart';

void main() {
  group('splitQuickEntries', () {
    test('shows the first few and counts the rest', () {
      final split = splitQuickEntries(['a', 'b', 'c', 'd', 'e', 'f'], 4);
      expect(split.shown, ['a', 'b', 'c', 'd']);
      expect(split.hidden, 2);
    });

    test('shows a lone leftover instead of a "+1 more" chip', () {
      final split = splitQuickEntries(['a', 'b', 'c', 'd', 'e'], 4);
      expect(split.shown, ['a', 'b', 'c', 'd', 'e']);
      expect(split.hidden, 0);
    });

    test('shows everything when there are no more than asked', () {
      expect(splitQuickEntries(['a', 'b'], 4).shown, ['a', 'b']);
      expect(splitQuickEntries(<String>[], 4).hidden, 0);
    });
  });

  test('clampQuickEntriesShown keeps the count between the minimum and maximum', () {
    expect(clampQuickEntriesShown(0), kMinQuickEntriesShown);
    expect(clampQuickEntriesShown(5), 5);
    expect(clampQuickEntriesShown(99), kMaxQuickEntriesShown);
  });

  group('reorderedIds', () {
    test('moves a row down', () => expect(reorderedIds(['a', 'b', 'c', 'd'], 0, 2), ['b', 'c', 'a', 'd']));
    test('moves a row up', () => expect(reorderedIds(['a', 'b', 'c', 'd'], 3, 1), ['a', 'd', 'b', 'c']));
    test('moves a row to the end', () => expect(reorderedIds(['a', 'b', 'c'], 0, 2), ['b', 'c', 'a']));
    test('leaves the order alone when dropped in place', () => expect(reorderedIds(['a', 'b', 'c'], 1, 1), ['a', 'b', 'c']));
  });
}
