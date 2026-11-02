import 'package:flutter/material.dart';

/// Where a row's title starts in a [ListTile] with a 24px leading icon:
/// 16 padding + 24 icon + 16 gap. Dividers start here, Android Settings style.
const double kTileTitleInset = 56;

/// Shorter rows without [VisualDensity.compact]'s narrower title gap, which
/// would pull the title 4px left of the [kTileTitleInset] dividers.
const VisualDensity kCompactRowDensity = VisualDensity(vertical: -2);

/// [rows] with [separator] between each neighbouring pair (none at the ends).
List<Widget> separatedRows(List<Widget> rows, Widget separator) => [
      for (final (index, row) in rows.indexed) ...[
        if (index > 0) separator,
        row,
      ],
    ];

/// A card of settings-style rows with a thin inset divider between them, so
/// each row reads as its own target. [danger] outlines the card in the error
/// colour for destructive rows such as "Erase all data".
class TileGroup extends StatelessWidget {
  const TileGroup({super.key, required this.children, this.indent = kTileTitleInset, this.danger = false});
  final List<Widget> children;

  /// Start inset of the dividers; 16 for rows without a leading icon.
  final double indent;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: danger
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
            )
          : null,
      child: Column(children: separatedRows(children, Divider(height: 1, indent: indent))),
    );
  }
}
