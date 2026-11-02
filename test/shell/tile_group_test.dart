import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/theme.dart';
import 'package:hisab/features/shell/widgets/tile_group.dart';

Future<void> _pumpGroup(WidgetTester tester, TileGroup group, {Brightness brightness = Brightness.light}) =>
    tester.pumpWidget(MaterialApp(theme: buildTheme(brightness), home: Scaffold(body: ListView(children: [group]))));

void main() {
  group('separatedRows', () {
    const separator = SizedBox.shrink();
    const first = Text('a');
    const second = Text('b');
    const third = Text('c');

    test('puts the separator only between neighbours', () {
      expect(separatedRows(const [first, second, third], separator), [first, separator, second, separator, third]);
    });

    test('leaves a single row or none alone', () {
      expect(separatedRows(const [first], separator), [first]);
      expect(separatedRows(const [], separator), isEmpty);
    });
  });

  testWidgets('N rows get N-1 dividers inset to the title', (tester) async {
    await _pumpGroup(
      tester,
      const TileGroup(children: [
        ListTile(leading: Icon(Icons.abc), title: Text('one')),
        ListTile(leading: Icon(Icons.abc), title: Text('two')),
        ListTile(leading: Icon(Icons.abc), title: Text('three')),
        ListTile(leading: Icon(Icons.abc), title: Text('four')),
      ]),
    );
    expect(find.byType(ListTile), findsNWidgets(4));
    expect(find.byType(Divider), findsNWidgets(3));
    final divider = tester.widget<Divider>(find.byType(Divider).first);
    expect(divider.indent, kTileTitleInset);
    // The inset lines up with where the title text starts.
    final titleStart = tester.getTopLeft(find.text('two')).dx - tester.getTopLeft(find.byType(Card)).dx;
    expect(titleStart, kTileTitleInset);
  });

  testWidgets('a single row has no divider', (tester) async {
    await _pumpGroup(tester, const TileGroup(children: [ListTile(title: Text('only'))]));
    expect(find.byType(Divider), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('danger outlines the card in the error colour ($brightness)', (tester) async {
      await _pumpGroup(tester, const TileGroup(danger: true, children: [ListTile(title: Text('erase'))]), brightness: brightness);
      final shape = tester.widget<Card>(find.byType(Card)).shape! as RoundedRectangleBorder;
      final error = buildTheme(brightness).colorScheme.error;
      expect(shape.side.color.toARGB32() & 0xFFFFFF, error.toARGB32() & 0xFFFFFF);
      expect(shape.side.color.a, closeTo(0.5, 0.01));
    });
  }

  testWidgets('a plain group keeps the theme card shape', (tester) async {
    await _pumpGroup(tester, const TileGroup(children: [ListTile(title: Text('row'))]));
    expect(tester.widget<Card>(find.byType(Card)).shape, isNull);
  });
}
