import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/launcher/quick_entry_shortcuts.dart';
import 'package:hisab/features/shell/deep_link.dart';

void main() {
  group('quickEntryShortcuts', () {
    test('keeps the user order and stops at the launcher limit', () {
      final shortcuts = quickEntryShortcuts([
        for (final name in ['Milk', 'Chai', 'Auto', 'Bread']) (id: name.toLowerCase(), label: name, amountText: null),
      ]);
      expect(shortcuts.map((shortcut) => shortcut.shortLabel), ['Milk', 'Chai', 'Auto']);
      expect(kMaxQuickEntryShortcuts, 3);
    });

    test('adds the amount to the long label only', () {
      final shortcut = quickEntryShortcuts([(id: 'q1', label: 'Milk', amountText: '₹30')]).single;
      expect(shortcut.shortLabel, 'Milk');
      expect(shortcut.longLabel, 'Milk · ₹30');
      expect(quickEntryShortcuts([(id: 'q1', label: 'Milk', amountText: null)]).single.longLabel, 'Milk');
    });

    test('prefixes the id so it never clashes with the static shortcuts', () {
      final shortcut = quickEntryShortcuts([(id: 'add_expense', label: 'Milk', amountText: null)]).single;
      expect(shortcut.id, 'quick_add_expense');
    });

    test('links to the editor prefilled from that quick entry', () {
      final shortcut = quickEntryShortcuts([(id: 'a b&c', label: 'Milk', amountText: null)]).single;
      final location = Uri.parse(deepLinkLocation(Uri.parse(shortcut.link))!);
      expect(location.path, '/entry');
      expect(location.queryParameters, {'quick': 'a b&c'});
    });

    test('skips quick entries without a name and trims the rest', () {
      final shortcuts = quickEntryShortcuts([
        (id: 'blank', label: '  ', amountText: null),
        (id: 'milk', label: ' Milk ', amountText: '₹30'),
      ]);
      expect(shortcuts.single.shortLabel, 'Milk');
      expect(shortcuts.single.longLabel, 'Milk · ₹30');
    });

    test('is empty with no quick entries, so the launcher drops them all', () {
      expect(quickEntryShortcuts(const []), isEmpty);
    });
  });
}
