import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/payee_category_repository.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/data/sms/sms_ingest_service.dart';
import 'package:hisab/data/sms/sms_sync_cursor.dart';
import 'package:hisab/domain/sms/payee_category_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Synthetic messages only.
const _swiggyDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';
const _swiggyAgain = 'Rs.212.00 debited from A/c XX1234 on 22-10-26 to swiggy@ybl (UPI Ref No 123456789013). Avl bal Rs.15,329.00';
const _personDebit = 'Rs.500.00 debited from A/c XX1234 on 21-10-26 to rahul.sharma@okaxis (UPI Ref No 223456789012). Avl bal Rs.15,041.00';
const _personAgain = 'Rs.700.00 debited from A/c XX1234 on 23-10-26 to rahul.sharma@okaxis (UPI Ref No 223456789013). Avl bal Rs.14,341.00';

void main() {
  late AppDatabase db;
  late CategoriesRepository categories;
  late EntriesRepository entries;
  late SmsLogRepository smsLog;
  late PayeeCategoryRepository memory;
  late SmsIngestService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    categories = CategoriesRepository(db);
    entries = EntriesRepository(db);
    smsLog = SmsLogRepository(db);
    memory = PayeeCategoryRepository(db);
    service = SmsIngestService(
      smsLog: smsLog,
      accounts: AccountsRepository(db),
      categories: categories,
      entries: entries,
      payeeCategories: memory,
      cursor: SmsSyncCursor(await SharedPreferences.getInstance()),
      homeCurrencyCode: () => 'INR',
    );
  });

  tearDown(() => db.close());

  Future<String> expenseCategory(String name) => categories.create(name: name, icon: 'category', color: 0xFF2E7D32, kind: 'expense');

  Future<SmsAutoAdded> autoAdd(String body, DateTime receivedAt) async {
    final announced = service.autoAdded.first;
    final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: body, receivedAt: receivedAt), autoAdd: true);
    expect(status, IngestStatus.added);
    return announced;
  }

  Future<String?> categoryOf(String entryId) async => (await entries.getEntry(entryId))!.category?.id;

  group('PayeeCategoryRepository', () {
    test('remembers by VPA and finds the payee by VPA or by name', () async {
      await memory.remember(kind: kPayeeExpense, raw: 'Rahul.Sharma@okaxis', categoryId: 'family');
      final row = (await memory.watchAll().first).single;
      expect(row.id, 'expense|vpa:rahul.sharma@okaxis');
      expect(row.payee, 'Rahul Sharma');
      expect(await memory.categoryIdFor(kind: kPayeeExpense, raw: 'rahul.sharma@okaxis'), 'family');
      expect(await memory.categoryIdFor(kind: kPayeeIncome, raw: 'rahul.sharma@okaxis'), isNull, reason: 'each side keeps its own category');
    });

    test('a newer choice replaces the older one', () async {
      await memory.remember(kind: kPayeeExpense, raw: 'SWIGGY', categoryId: 'food');
      await memory.remember(kind: kPayeeExpense, raw: 'swiggy', categoryId: 'treats');
      expect(await memory.watchMemory().first, {'expense|name:swiggy': 'treats'});
    });

    test('forgetting hides the row and remembering again revives it', () async {
      await memory.remember(kind: kPayeeExpense, raw: 'SWIGGY', categoryId: 'food');
      await memory.forget('expense|name:swiggy');
      expect(await memory.watchAll().first, isEmpty);
      expect(await memory.categoryIdFor(kind: kPayeeExpense, raw: 'SWIGGY'), isNull);

      await memory.remember(kind: kPayeeExpense, raw: 'SWIGGY', categoryId: 'treats');
      expect(await memory.categoryIdFor(kind: kPayeeExpense, raw: 'SWIGGY'), 'treats');
    });

    test('an SMS without a payee is not remembered', () async {
      await memory.remember(kind: kPayeeExpense, raw: null, categoryId: 'food');
      await memory.remember(kind: kPayeeExpense, raw: '  ', categoryId: 'food');
      expect(await db.select(db.payeeCategories).get(), isEmpty);
    });
  });

  group('SMS ingest with payee memory', () {
    final received = DateTime(2026, 10, 21, 10, 0);

    test('without a memory the keyword rules pick the category', () async {
      final added = await autoAdd(_swiggyDebit, received);
      expect(await categoryOf(added.entryId), (await categories.findBySeedKey('food_delivery'))?.id);
    });

    test('a corrected payee gets its remembered category ahead of the keyword rules', () async {
      final treats = await expenseCategory('Treats');
      final first = await autoAdd(_swiggyDebit, received);
      await service.rememberCategoryForSms(first.smsId, treats);

      final second = await autoAdd(_swiggyAgain, received.add(const Duration(days: 1)));
      expect(await categoryOf(second.entryId), treats);
    });

    test('approving a pending SMS uses the remembered category', () async {
      final family = await expenseCategory('Family');
      await memory.remember(kind: kPayeeExpense, raw: 'rahul.sharma@okaxis', categoryId: family);
      await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _personDebit, receivedAt: received), autoAdd: false);
      final pending = (await smsLog.watchPending().first).single;

      final entryId = await service.approvePending(pending);
      expect(await categoryOf(entryId!), family);
    });

    test('a person answered once is not asked about again', () async {
      final family = await expenseCategory('Family');
      final first = await autoAdd(_personDebit, received);
      final payee = parsedSmsPayee((await smsLog.getById(first.smsId))!.parsedJson)!;
      expect(asksForPayeeCategory(payee, await memory.watchMemory().first), isTrue);

      await service.rememberCategoryForSms(first.smsId, family);
      expect(asksForPayeeCategory(payee, await memory.watchMemory().first), isFalse);
      final second = await autoAdd(_personAgain, received.add(const Duration(days: 2)));
      expect(await categoryOf(second.entryId), family);
    });

    test('an archived, deleted or other-kind category is ignored', () async {
      final archived = await expenseCategory('Old');
      await memory.remember(kind: kPayeeExpense, raw: 'swiggy@ybl', categoryId: archived);
      await categories.setArchived(archived, true);
      expect(await service.rememberedCategoryFor(kind: kPayeeExpense, counterparty: 'swiggy@ybl'), isNull);

      final deleted = await expenseCategory('Gone');
      await memory.remember(kind: kPayeeExpense, raw: 'swiggy@ybl', categoryId: deleted);
      await categories.delete(deleted);
      final added = await autoAdd(_swiggyDebit, received);
      expect(await categoryOf(added.entryId), (await categories.findBySeedKey('food_delivery'))?.id, reason: 'falls back to the keyword rules');
    });

    test('rememberCategoryForSms refuses a category of the other kind', () async {
      final salary = await categories.create(name: 'Gifts in', icon: 'category', color: 0xFF2E7D32, kind: 'income');
      final added = await autoAdd(_swiggyDebit, received);
      await service.rememberCategoryForSms(added.smsId, salary);
      expect(await db.select(db.payeeCategories).get(), isEmpty);
    });
  });

  test('a backup carries remembered payees to a fresh device, keeping deletions', () async {
    final restoredDb = AppDatabase(NativeDatabase.memory());
    addTearDown(restoredDb.close);
    await memory.remember(kind: kPayeeExpense, raw: 'rahul.sharma@okaxis', categoryId: 'family');
    await memory.remember(kind: kPayeeExpense, raw: 'SWIGGY', categoryId: 'food');
    await memory.forget('expense|name:swiggy');

    final payload = await BackupService(db).snapshot();
    expect(payload['payeeCategories'], hasLength(2));
    await BackupService(restoredDb).importSnapshot(payload);

    final restored = PayeeCategoryRepository(restoredDb);
    expect(await restored.watchMemory().first, {'expense|vpa:rahul.sharma@okaxis': 'family'});
    expect((await restoredDb.select(restoredDb.payeeCategories).get()).length, 2);
  });
}
