import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/app_icons.dart';
import 'package:hisab/core/notifications/notification_gateway.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/sms/sms_notification_prompt.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late SharedPreferences prefs;
  late EntriesRepository entries;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
    ]);
    entries = container.read(entriesRepositoryProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// First value of a stream provider, listened to as a screen would.
  Future<T> firstValue<T>(ProviderListenable<Future<T>> provider) => container.listen(provider, (_, _) {}).read();

  group('selected month', () {
    test('shift moves by whole months, select jumps, reset returns to now', () {
      final month = container.read(selectedMonthProvider.notifier);
      month.select(DateTime(2026, 1, 31));
      month.shift(1);
      expect(container.read(selectedMonthProvider), DateTime(2026, 2, 15), reason: 'anchored mid-month so a short month never skips');
      month.shift(-3);
      expect(container.read(selectedMonthProvider), DateTime(2025, 11, 15));

      month.reset();
      final now = DateTime.now();
      final reset = container.read(selectedMonthProvider);
      expect((reset.year, reset.month), (now.year, now.month));
    });
  });

  group('month streams', () {
    setUp(() async {
      container.read(selectedMonthProvider.notifier).select(DateTime(2026, 10, 15));
      await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 45000, occurredAt: DateTime(2026, 10, 3)).copyWith(tags: const Value('trip #food')));
      await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 15000, occurredAt: DateTime(2026, 10, 3)).copyWith(tags: const Value('Trip')));
      await entries.saveEntry(EntriesRepository.newExpense(kind: 'income', amountMinor: 900000, occurredAt: DateTime(2026, 10, 1)));
      await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 7000, occurredAt: DateTime(2026, 9, 28)));
    });

    test('totals, category totals and daily spend cover the selected month only', () async {
      expect(await firstValue(monthTotalsProvider.future), (expense: 60000, income: 900000));
      expect(await firstValue(monthCategoryTotalsProvider.future), {'': 60000});
      expect(await firstValue(monthDailyExpenseProvider.future), {DateTime(2026, 10, 3): 60000});
    });

    test('a date window lists my entries inside it', () async {
      final window = await firstValue(windowEntriesProvider((start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 2))).future);
      expect(window.map((details) => details.entry.amountMinor), unorderedEquals([900000, 7000]));
    });

    test('tags are listed once whatever their case or hash', () async {
      expect(await firstValue(entryTagsProvider.future), unorderedEquals(['trip', 'food']));
    });
  });

  test('people and payee memory stream what was remembered', () async {
    await container.read(peopleRepositoryProvider).remember(name: 'Priya', email: 'priya@example.com');
    final groceries = (await container.read(categoriesRepositoryProvider).getAll()).first.id;
    await container.read(payeeCategoryRepositoryProvider).remember(kind: 'expense', raw: 'BIGBASKET', categoryId: groceries);

    expect((await firstValue(peopleProvider.future)).map((person) => person.name), ['Priya']);
    expect((await firstValue(payeeCategoriesProvider.future)).single.categoryId, groceries);
    expect((await firstValue(payeeMemoryProvider.future)).values, [groceries]);
  });

  test('undoing a paid reminder deletes the entry that paying it recorded', () async {
    final scheduler = container.read(reminderSchedulerProvider);
    final reminderId = await scheduler.save(ReminderDraft(
      kind: ReminderKind.bill,
      title: 'Electricity',
      amountMinor: 210000,
      dueAt: DateTime.now().add(const Duration(days: 5)),
      repeat: ReminderRepeat.once,
      remindDaysBefore: const [0],
    ));
    const paymentId = 'electricity-payment';
    await entries.saveEntry(EntriesRepository.newExpense(id: paymentId, amountMinor: 210000, occurredAt: DateTime.now()));
    await scheduler.markDone(reminderId, entryId: paymentId);

    await scheduler.undoDone(reminderId);

    expect((await entries.getEntry(paymentId))?.entry.deletedAt, isNotNull);
  });

  test('asking for SMS notifications is remembered and does nothing off Android', () async {
    final prompt = container.read(smsNotificationPromptProvider);
    expect(prompt.asked, isFalse);
    await prompt.askOnce();
    expect(prefs.getBool(SmsNotificationPrompt.key), isTrue);
  });

  test('the notification permission reads through the gateway', () async {
    final state = await container.read(notificationPermissionProvider.future);
    expect(state, isA<NotificationPermissionState>());
    expect(state.notificationsAllowed, isTrue);
  });

  test('every app icon can be picked', () {
    expect(pickableIconNames, isNotEmpty);
    expect(pickableIconNames.toSet(), appIcons.keys.toSet());
    const tap = NotificationTap(payload: 'hisab://reminder/power');
    expect(NotificationTap(payload: tap.payload, actionId: 'snooze').actionId, 'snooze');
  });
}
