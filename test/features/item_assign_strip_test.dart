import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/split/item_assign_strip.dart';

import '../support/split_harness.dart';

void main() {
  final members = [testMember('me', 'You', isMe: true), testMember('priya', 'Priya'), testMember('rahul', 'Rahul')];

  /// A strip for one item that keeps its own assignment, like the expense editor.
  Widget strip({String label = 'Pizza', List<String> initialMembers = const [], ValueChanged<bool>? onShared}) {
    var memberIds = initialMembers;
    var shared = false;
    return StatefulBuilder(
      builder: (context, setState) => ItemAssignStrip(
        itemId: 'pizza',
        itemLabel: label,
        members: members,
        memberIds: memberIds,
        shared: shared,
        onMembersChanged: (changed) => setState(() => memberIds = changed),
        onSharedChanged: (changed) {
          onShared?.call(changed);
          setState(() => shared = changed);
        },
      ),
    );
  }

  List<String> selectedNames(WidgetTester tester) => [
        for (final chip in tester.widgetList<FilterChip>(find.byType(FilterChip)))
          if (chip.selected) (chip.label as Text).data!,
      ];

  Future<void> longPressMember(WidgetTester tester, String memberId) async {
    await tester.longPress(find.byKey(Key('assign-pizza-$memberId')));
    await tester.pumpAndSettle();
  }

  testWidgets('an item nobody shares asks to be assigned, and tapping avatars toggles who shares it', (tester) async {
    await pumpLocalized(tester, strip());
    expect(find.text('Assign "Pizza" to someone'), findsOneWidget);

    await tester.tap(find.byKey(const Key('assign-pizza-priya')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-pizza-me')));
    await tester.pumpAndSettle();
    expect(selectedNames(tester), ['You', 'Priya']);
    expect(find.textContaining('to someone'), findsNothing);

    await tester.tap(find.byKey(const Key('assign-pizza-me')));
    await tester.pumpAndSettle();
    expect(selectedNames(tester), ['Priya']);
  });

  testWidgets('an unnamed item is called "item" in the warning', (tester) async {
    await pumpLocalized(tester, strip(label: ''));
    expect(find.text('Assign "item" to someone'), findsOneWidget);
  });

  testWidgets('long-press offers Only me and Everyone, and dismissing it keeps the pick', (tester) async {
    await pumpLocalized(tester, strip(initialMembers: const ['priya']));

    await longPressMember(tester, 'rahul');
    await tester.tap(find.text('Everyone'));
    await tester.pumpAndSettle();
    expect(selectedNames(tester), ['You', 'Priya', 'Rahul']);

    await longPressMember(tester, 'rahul');
    await tester.tap(find.text('Only me'));
    await tester.pumpAndSettle();
    expect(selectedNames(tester), ['You']);

    await longPressMember(tester, 'priya');
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(selectedNames(tester), ['You']);
  });

  testWidgets('Shared splits the item among everyone with an item and locks the avatars', (tester) async {
    final sharedChanges = <bool>[];
    await pumpLocalized(tester, strip(initialMembers: const ['priya'], onShared: sharedChanges.add));

    await tester.tap(find.byKey(const Key('assign-shared-pizza')));
    await tester.pumpAndSettle();
    expect(sharedChanges, [true]);
    expect(find.text('Split among everyone with an item'), findsOneWidget);
    expect(selectedNames(tester), ['Shared'], reason: 'member chips show as unpicked while shared');

    await tester.tap(find.byKey(const Key('assign-pizza-rahul')));
    await longPressMember(tester, 'rahul');
    expect(find.text('Only me'), findsNothing, reason: 'no quick picks while shared');
    expect(selectedNames(tester), ['Shared']);
  });
}
