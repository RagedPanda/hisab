import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/transactions/transactions_screen.dart';

void main() {
  final day = DateTime(2026, 10, 24);

  test('a day route loads exactly that calendar day', () {
    final window = RouteFilters(day: day).asFilter.dateWindow!;
    expect(window.start, DateTime(2026, 10, 24));
    expect(window.end, DateTime(2026, 10, 25));
  });

  test('day links round-trip and the chip removes only the day', () {
    expect(entriesForDayLocation(DateTime(2026, 10, 24, 18, 5)), '/transactions?day=2026-10-24');
    final filters = RouteFilters(categoryId: 'food', day: day);
    expect(filters.isEmpty, isFalse);
    expect(filters.locationWithout(day: true), '/transactions?category=food');
    expect(filters.locationWithout(category: true), '/transactions?day=2026-10-24');
    expect(RouteFilters(day: day).locationWithout(day: true), '/transactions');
  });
}
