/// Launcher shortcuts (long-press the app icon) built from the user's quick
/// entries. Pure: the platform side only publishes what this returns.
library;

/// Dynamic shortcuts shown after the two static ones (Add expense, Add
/// income). Pixel Launcher and most others show four in all, so two keeps
/// every one visible.
const int kMaxQuickEntryShortcuts = 2;

/// Prefix of a quick-entry shortcut id, so they never clash with the static
/// `add_expense` / `add_income` ids.
const String kQuickEntryShortcutPrefix = 'quick_';

/// One launcher shortcut: what it says and the hisab:// link it opens.
class LauncherShortcut {
  const LauncherShortcut({required this.id, required this.shortLabel, required this.longLabel, required this.link});
  final String id;
  final String shortLabel;
  final String longLabel;
  final String link;

  Map<String, String> toMap() => {'id': id, 'shortLabel': shortLabel, 'longLabel': longLabel, 'link': link};

  @override
  bool operator ==(Object other) =>
      other is LauncherShortcut && other.id == id && other.shortLabel == shortLabel && other.longLabel == longLabel && other.link == link;

  @override
  int get hashCode => Object.hash(id, shortLabel, longLabel, link);
}

/// The quick entry fields a shortcut needs; [amountText] is the formatted
/// amount, or null when the quick entry asks for one each time.
typedef QuickEntryShortcutSource = ({String id, String label, String? amountText});

/// The first [max] of [quickEntries], in the user's order (Settings → Quick
/// entries). Each opens the editor prefilled from that quick entry; the long
/// label adds the amount when there is one ("Milk · ₹30").
List<LauncherShortcut> quickEntryShortcuts(Iterable<QuickEntryShortcutSource> quickEntries, {int max = kMaxQuickEntryShortcuts}) => [
      for (final quick in quickEntries.where((quick) => quick.label.trim().isNotEmpty).take(max))
        LauncherShortcut(
          id: '$kQuickEntryShortcutPrefix${quick.id}',
          shortLabel: quick.label.trim(),
          longLabel: quick.amountText == null ? quick.label.trim() : '${quick.label.trim()} · ${quick.amountText}',
          link: Uri(scheme: 'hisab', host: 'entry', queryParameters: {'quick': quick.id}).toString(),
        ),
    ];
