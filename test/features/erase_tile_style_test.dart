import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/theme.dart';
import 'package:hisab/features/shell/widgets/tile_group.dart';

import '../support/app_harness.dart';
import '../support/screen_harness.dart';

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Erase all data is a danger row: red icon and title, plain subtitle, red outline (${mode.name})', (tester) async {
      final container = await createContainer(preferences: {'themeMode': mode.index});
      await pumpAt(tester, container, '/settings');
      final scheme = buildTheme(mode == ThemeMode.dark ? Brightness.dark : Brightness.light).colorScheme;

      final tile = find.byKey(const Key('eraseAllDataTile'));
      await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
      final context = tester.element(tile);
      expect(Theme.of(context).colorScheme.error, scheme.error, reason: 'the app is in $mode');

      final listTile = tester.widget<ListTile>(tile);
      Color? textColor(Widget text) => tester.renderObject<RenderParagraph>(find.descendant(of: tile, matching: find.byWidget(text))).text.style?.color;
      expect(IconTheme.of(tester.element(find.descendant(of: tile, matching: find.byType(Icon)))).color, scheme.error);
      expect(textColor(listTile.title!), scheme.error);
      expect(textColor(listTile.subtitle!), scheme.onSurfaceVariant);

      final group = tester.widget<TileGroup>(find.ancestor(of: tile, matching: find.byType(TileGroup)));
      expect(group.danger, isTrue);
    });
  }
}
