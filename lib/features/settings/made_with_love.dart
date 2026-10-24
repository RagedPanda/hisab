import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Last line of Settings > About: "Made with" and a red heart icon. The words
/// around the heart are separate strings so each language can order them
/// naturally. Screen readers hear a single label instead of the pieces.
class MadeWithLove extends StatelessWidget {
  const MadeWithLove({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final heartSize = (style?.fontSize ?? 12) + 2;
    return Semantics(
      key: const ValueKey('about-made-with-love'),
      label: l10n.aboutMadeWithLabel,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text.rich(
          TextSpan(style: style, children: [
            if (l10n.aboutMadeWithBefore.isNotEmpty) TextSpan(text: '${l10n.aboutMadeWithBefore} '),
            WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.favorite, color: Colors.red, size: heartSize)),
            if (l10n.aboutMadeWithAfter.isNotEmpty) TextSpan(text: ' ${l10n.aboutMadeWithAfter}'),
          ]),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
