import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/upcoming/upcoming_items.dart';
import 'package:hisab/features/upcoming/upcoming_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 10, 22);

  Future<ProviderContainer> containerWith(AppDatabase db) async {
    SharedPreferences.setMockInitialValues({kUpcomingWindowPrefKey: 'month'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        upcomingTodayProvider.overrideWithValue(today),
      ],
    );
    addTearDown(container.dispose);
    container.listen(upcomingOverviewProvider, (_, _) {});
    return container;
  }

  /// Lets the Drift streams emit, then reads the card's items once [settled]
  /// holds, so a read never sees the state from before the last write.
  Future<List<UpcomingItem>> itemsOf(ProviderContainer container, {required bool Function(List<UpcomingItem> items) settled}) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final overview = container.read(upcomingOverviewProvider);
      if (overview.hasValue && settled(overview.requireValue.items)) return overview.requireValue.items;
    }
    fail('upcoming overview never settled');
  }

  bool hasReminder(List<UpcomingItem> items) => items.any((item) => item.source == UpcomingSource.reminder);

  test('marking a linked reminder paid keeps its rule occurrence off the card', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = await containerWith(db);
    final ruleId = await container.read(recurringRepositoryProvider).saveRule(
      RecurringRepository.newRule(
        name: 'Rent',
        kind: 'expense',
        amountMinor: 1500000,
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 25,
        startDate: DateTime(2026, 10, 25, 9),
        autoPost: false,
      ),
    );
    final reminderId = await container.read(remindersRepositoryProvider).save(
      ReminderDraft(kind: ReminderKind.bill, title: 'Rent', dueAt: DateTime(2026, 10, 25), amountMinor: 1500000, recurringId: ruleId),
    );
    expect((await itemsOf(container, settled: hasReminder)).map((item) => item.source), [UpcomingSource.reminder], reason: 'the pending reminder stands in for the rule');

    final seen = <List<UpcomingItem>>[];
    container.listen(upcomingOverviewProvider, (_, next) => next.whenData((overview) => seen.add(overview.items)));
    await container.read(remindersRepositoryProvider).markDone(reminderId);
    await itemsOf(container, settled: (items) => !hasReminder(items));
    expect(seen.expand((items) => items).where((item) => item.dueAt.month == 10 && item.source == UpcomingSource.recurring), isEmpty, reason: 'the paid reminder owns the 25 Oct occurrence at every step, so the rule never flashes back');
  });
}
