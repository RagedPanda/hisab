import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/notification_prefs.dart';
import 'package:hisab/core/notifications/background_actions.dart';
import 'package:hisab/core/notifications/notification_service.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/core/notifications/reminder_scheduler.dart';
import 'package:hisab/core/notifications/sms_entry_payload.dart';
import 'package:hisab/core/settings.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/payee_category_repository.dart';
import 'package:hisab/data/repositories/reminders_repository.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';
import 'package:hisab/data/sms/reminder_payment_adapter.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/data/sms/sms_ingest_service.dart';
import 'package:hisab/data/sms/sms_linked_reminder_scheduler.dart';
import 'package:hisab/data/sms/sms_reminder_linker.dart';
import 'package:hisab/domain/notifications/notification_kinds.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';
import 'package:hisab/domain/sms/payee_category_memory.dart';
import 'package:hisab/domain/sms/sms_outcome.dart';
import 'package:hisab/features/sms/sms_entry_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';
import '../support/app_harness.dart';

// Synthetic messages only.
const _swiggyDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';
const _personDebit = 'Rs.500.00 debited from A/c XX1234 on 21-10-26 to rahul.sharma@okaxis (UPI Ref No 223456789012). Avl bal Rs.15,041.00';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late AppSettings settings;
  late FakeNotificationGateway gateway;
  late ReminderScheduler scheduler;
  late SmsIngestService service;
  final now = DateTime(2026, 11, 5, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = AppSettings.fromPrefs(prefs);
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    scheduler = SmsLinkedReminderScheduler(
      reminders: RemindersRepository(db, clock: () => now),
      smsLog: SmsLogRepository(db),
      notifications: NotificationService(gateway,
          buildAlert: (reminder, alert) => alertRequestFor(reminder, alert, notificationLocalizations('en'), moneyFormat: MoneyFormat.inr), clock: () => now),
      clock: () => now,
    );
    // Wired exactly as the background isolate wires it.
    service = buildSmsIngestService(db, settings, prefs, scheduler);
  });

  tearDown(() => db.close());

  Future<SmsAutoAdded> autoAdd(String body) async {
    final announced = service.autoAdded.first;
    expect(await service.ingest(RawSms(sender: 'VM-HDFCBK', body: body, receivedAt: DateTime(2026, 10, 21, 10)), autoAdd: true), IngestStatus.added);
    return announced;
  }

  Future<void> undoInBackground(SmsAutoAdded added) =>
      runBackgroundAction(UndoSmsEntry((smsId: added.smsId, entryId: added.entryId)), db: db, settings: settings, prefs: prefs, scheduler: scheduler);

  group('Undo from the notification (background isolate)', () {
    test('deletes the entry and marks the SMS ignored', () async {
      final added = await autoAdd(_swiggyDebit);
      await undoInBackground(added);
      expect((await EntriesRepository(db).getEntry(added.entryId))!.entry.deletedAt, isNotNull);
      expect((await SmsLogRepository(db).getById(added.smsId))!.status, SmsLogStatus.ignored);
    });

    test('a second Undo, or one for an entry no longer from that SMS, changes nothing', () async {
      final added = await autoAdd(_swiggyDebit);
      expect(await service.undoAutoAddIfCurrent(smsId: added.smsId, entryId: added.entryId), isTrue);
      expect(await service.undoAutoAddIfCurrent(smsId: added.smsId, entryId: added.entryId), isFalse);

      final other = await autoAdd(_personDebit);
      expect(await service.undoAutoAddIfCurrent(smsId: other.smsId, entryId: 'some-other-entry'), isFalse);
      expect((await EntriesRepository(db).getEntry(other.entryId))!.entry.deletedAt, isNull);
    });

    test('reopens the reminder the SMS had paid', () async {
      final accounts = AccountsRepository(db);
      final reminders = RemindersRepository(db, clock: () => now);
      final smsLog = SmsLogRepository(db);
      final account = await accounts.create(name: 'HDFC 1234', type: 'bank', color: 0, bankName: 'HDFC Bank', last4: '1234');
      final reminderId = await scheduler.save(ReminderDraft(
        kind: ReminderKind.emi,
        title: 'Car loan',
        dueAt: DateTime(2026, 11, 5),
        amountMinor: 1234500,
        accountId: account.id,
        repeat: ReminderRepeat.monthly,
      ));
      await smsLog.record(id: 's1', sender: 'HDFCBK', body: 'emi', receivedAt: now, status: SmsLogStatus.added, entryId: 'e1');
      final linker = SmsReminderLinker(smsLog: smsLog, reminders: ReminderPaymentAdapter(reminders: reminders, scheduler: scheduler, accounts: accounts));
      final emi = ParsedTransaction(
        direction: TxnDirection.debit,
        amountMinor: 1234500,
        instrument: Instrument.emi,
        occurredAt: now,
        raw: 'EMI of Rs 12,345 debited from HDFC Bank A/c XX1234',
        bank: 'HDFC Bank',
        accountLast4: '1234',
      );
      expect(await linker.linkEntry(smsId: 's1', parsed: emi, entryId: 'e1'), reminderId);
      expect((await reminders.getById(reminderId))!.status, ReminderStatus.done);

      await runBackgroundAction(UndoSmsEntry((smsId: 's1', entryId: 'e1')), db: db, settings: settings, prefs: prefs, scheduler: scheduler);

      final reopened = (await reminders.getById(reminderId))!;
      expect(reopened.status, ReminderStatus.pending);
      expect(reopened.entryId, isNull);
      expect((await smsLog.getById('s1'))!.status, SmsLogStatus.ignored);
    });
  });

  group('Change category from the notification', () {
    test('moves the entry and remembers the payee', () async {
      final categories = CategoriesRepository(db);
      final family = await categories.create(name: 'Family', icon: 'category', color: 0xFF2E7D32, kind: 'expense');
      final added = await autoAdd(_personDebit);

      expect(await service.changeSmsEntryCategory(smsId: added.smsId, entryId: added.entryId, categoryId: family), isTrue);

      expect((await EntriesRepository(db).getEntry(added.entryId))!.category?.id, family);
      expect(await PayeeCategoryRepository(db).categoryIdFor(kind: kPayeeExpense, raw: 'rahul.sharma@okaxis'), family);
    });

    test('an undone entry or a category of the other kind is not written', () async {
      final categories = CategoriesRepository(db);
      final income = await categories.create(name: 'Gifts in', icon: 'category', color: 0xFF2E7D32, kind: 'income');
      final food = await categories.create(name: 'Treats', icon: 'category', color: 0xFF2E7D32, kind: 'expense');
      final added = await autoAdd(_swiggyDebit);

      expect(await service.changeSmsEntryCategory(smsId: added.smsId, entryId: added.entryId, categoryId: income), isFalse);
      await service.undoAutoAddIfCurrent(smsId: added.smsId, entryId: added.entryId);
      expect(await service.changeSmsEntryCategory(smsId: added.smsId, entryId: added.entryId, categoryId: food), isFalse);
      expect(await db.select(db.payeeCategories).get(), isEmpty);
    });
  });

  group('SmsEntryNotifier', () {
    SmsEntryNotifier notifier({bool alertsAllowed = true}) => SmsEntryNotifier(
          entries: EntriesRepository(db),
          smsLog: SmsLogRepository(db),
          payeeCategories: PayeeCategoryRepository(db),
          notifications: NotificationService(gateway, buildAlert: (_, _) => throw UnimplementedError()),
          l10n: notificationLocalizations('en'),
          moneyFormat: MoneyFormat.inr,
          alertsAllowed: alertsAllowed,
        );

    test('shows payee, category and account with Change category and Undo', () async {
      final added = await autoAdd(_swiggyDebit);
      await notifier().notify(added);

      final alert = gateway.smsEntries[smsEntryNotificationId(added.smsId)]!;
      expect(alert.title, 'Added ₹459 from SMS');
      expect(alert.body, startsWith('Swiggy · '));
      expect(alert.body.split(' · '), hasLength(3), reason: 'payee, category and account');
      expect(alert.body, isNot(contains('pick a category')));
      expect(smsEntryFromPayload(alert.payload), (smsId: added.smsId, entryId: added.entryId));
      expect(alert.changeCategoryLabel, 'Change category');
      expect(alert.undoLabel, 'Undo');
    });

    test('asks a new person for a category until one is remembered', () async {
      final added = await autoAdd(_personDebit);
      await notifier().notify(added);
      expect(gateway.smsEntries.values.single.body, contains('New payee: pick a category'));

      await PayeeCategoryRepository(db).remember(kind: kPayeeExpense, raw: 'rahul.sharma@okaxis', categoryId: 'family');
      await notifier().notify(added);
      expect(gateway.smsEntries.values.single.body, isNot(contains('pick a category')), reason: 'the same id is replaced, not stacked');
    });

    test('posts nothing while the Bank SMS notification switch is off', () async {
      final added = await autoAdd(_swiggyDebit);
      await notifier(alertsAllowed: false).notify(added);
      expect(gateway.shown, isEmpty);
    });

    test('the provider follows the Bank SMS switch in Settings > Notifications', () async {
      expect((await createContainer()).read(smsEntryNotifierProvider).alertsAllowed, isTrue, reason: 'on until the user turns it off');
      final off = await createContainer(preferences: {notificationChoiceKey(NotificationKind.bankSms): false});
      expect(off.read(smsEntryNotifierProvider).alertsAllowed, isFalse);
    });

    test('an entry already undone posts nothing', () async {
      final added = await autoAdd(_swiggyDebit);
      await service.undoAutoAddIfCurrent(smsId: added.smsId, entryId: added.entryId);
      await notifier().notify(added);
      expect(gateway.smsEntries, isEmpty);
    });
  });
}
