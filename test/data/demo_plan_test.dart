import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/debug/demo_plan.dart';

void main() {
  final now = DateTime(2026, 10, 21, 12);

  test('demo plan is deterministic and stays inside the six-month window', () {
    final first = planDemoEntries(count: 300, now: now);
    final second = planDemoEntries(count: 300, now: now);
    expect(first.length, second.length);
    expect(first.map((e) => e.amountMinor).toList(), second.map((e) => e.amountMinor).toList());
    expect(first.where((e) => e.kind == 'expense').length, greaterThan(280));
    expect(first.every((e) => !e.occurredAt.isAfter(now)), isTrue);
    expect(first.every((e) => !e.occurredAt.isBefore(DateTime(2026, 5, 1))), isTrue);
    expect(first.where((e) => e.categoryKey == 'salary').length, 6);
  });
}
