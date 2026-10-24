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

  /// Lets the Drift streams emit, then reads the card's items.
  Future<List<UpcomingItem>> itemsOf(ProviderContainer container) async {
    for (var attempt = 0; attempt < 50; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final overview = container.read(upcomingOverviewProvider);
      if (overview.hasValue) return overview.requireValue.items;
    }
    fail('upcoming overview never loaded');
  }

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
    expect((await itemsOf(container)).map((item) => item.source), [UpcomingSource.reminder], reason: 'the pending reminder stands in for the rule');

    await container.read(remindersRepositoryProvider).markDone(reminderId);
    final items = await itemsOf(container);
    expect(items.where((item) => item.dueAt.month == 10), isEmpty, reason: 'the paid reminder still owns the 25 Oct occurrence');
  });
}
