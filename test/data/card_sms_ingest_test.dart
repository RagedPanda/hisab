import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/data/sms/sms_ingest_service.dart';
import 'package:hisab/data/sms/sms_sync_cursor.dart';
import 'package:hisab/domain/sms/sms_outcome.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Made-up card and account digits; formats follow the banks' public SMS.
const _cardSpend = 'Rs 1,250.00 spent on HDFC Bank Credit Card XX4521 at AMAZON on 2026-10-20. Avl Lmt: Rs 76,543.21';
const _statement = 'Statement for HDFC Bank Credit Card XX4521 dated 12-10-26: Total Amt Due Rs 23,456.78, Min Amt Due Rs 1,180.00, Due Date 01-11-26.';
const _cardPayment = 'Payment of Rs 12,000.00 received on your HDFC Bank Credit Card ending 4521 on 21-10-2026. Available limit Rs 88,543.21. Thank you.';
const _bankDebit = 'Rs 12,000.00 debited from HDFC Bank A/c XX7781 on 21-10-26 towards HDFC Credit Card bill. Avl Bal Rs 30,000.00';

void main() {
  late AppDatabase db;
  late AccountsRepository accounts;
  late SmsLogRepository smsLog;
  late SmsIngestService service;
  var defaultAccountId = '';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    accounts = AccountsRepository(db);
    smsLog = SmsLogRepository(db);
    defaultAccountId = '';
    service = SmsIngestService(
      smsLog: smsLog,
      accounts: accounts,
      categories: CategoriesRepository(db),
      entries: EntriesRepository(db),
      cursor: SmsSyncCursor(await SharedPreferences.getInstance()),
      homeCurrencyCode: () => 'INR',
      defaultAccountId: () => defaultAccountId,
    );
  });

  tearDown(() => db.close());

  Future<IngestStatus> ingest(String body, {DateTime? at, bool autoAdd = true, String sender = 'VM-HDFCBK-S'}) =>
      service.ingest(RawSms(sender: sender, body: body, receivedAt: at ?? DateTime(2026, 10, 21, 12)), autoAdd: autoAdd);
  Future<Account?> card() => accounts.findBySmsKey('HDFC Bank:cc:4521');
  Future<List<Entry>> liveEntries() => (db.select(db.entries)..where((t) => t.deletedAt.isNull())).get();
  Future<Account> bank() => accounts.create(name: 'HDFC Savings', type: 'bank', color: 0, bankName: 'HDFC Bank', last4: '7781', smsKey: 'HDFC Bank:ac:7781');

  group('available limit', () {
    test('a card spend keeps the limit it reports on the card', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9));
      final saved = await card();
      expect(saved!.availableLimitMinor, 7654321);
      expect(saved.availableLimitAt, isNotNull);
    });

    test('an older message read later leaves the newer limit', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9));
      await ingest(_cardPayment);
      await ingest('Rs 99.00 spent on HDFC Bank Credit Card XX4521 at ZOMATO on 2026-10-19. Avl Lmt: Rs 70,000.00', at: DateTime(2026, 10, 19, 9));
      expect((await card())!.availableLimitMinor, 8854321);
    });
  });

  group('statement', () {
    test('fills the card statement, minimum due and days', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9));
      final received = DateTime(2026, 10, 13, 10);
      expect(await ingest(_statement, at: received), IngestStatus.cardUpdated);
      final saved = (await card())!;
      expect(saved.lastStatementMinor, 2345678);
      expect(saved.lastStatementAt, DateTime(2026, 10, 12));
      expect(saved.minimumDueMinor, 118000);
      expect(saved.statementFromSmsAt, received);
      expect(saved.dueDay, 1);
      expect(saved.statementDay, 12);
      expect(await liveEntries(), hasLength(1), reason: 'a statement is never an entry');
      expect((await smsLog.getById(SmsLogRepository.idFor('VM-HDFCBK-S', _statement, received)))!.status, SmsLogStatus.added);
    });

    test('creates the card when it is new', () async {
      await ingest(_statement, at: DateTime(2026, 10, 13, 10));
      final saved = await card();
      expect(saved!.type, 'card');
      expect(saved.lastStatementMinor, 2345678);
    });

    test('an older statement does not replace a newer one', () async {
      await ingest(_statement, at: DateTime(2026, 10, 13, 10));
      await ingest(
        'Statement for HDFC Bank Credit Card XX4521 dated 12-09-26: Total Amt Due Rs 9,000.00, Min Amt Due Rs 450.00, Due Date 01-10-26.',
        at: DateTime(2026, 9, 13, 10),
      );
      expect((await card())!.lastStatementMinor, 2345678);
    });

    test('a statement in another currency is not read', () async {
      final status = await ingest('HDFC Bank Credit Card XX4521 statement: Total Amt Due USD 230.00, Due Date 01-11-26.');
      expect(status, IngestStatus.foreignCurrency);
      expect(await card(), isNull);
    });
  });

  group('card bill payment', () {
    test('bank debit first: the expense becomes the transfer to the card', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9));
      expect(await ingest(_bankDebit, at: DateTime(2026, 10, 21, 11)), IngestStatus.added);
      final added = <SmsAutoAdded>[];
      final subscription = service.autoAdded.listen(added.add);

      expect(await ingest(_cardPayment, at: DateTime(2026, 10, 21, 12)), IngestStatus.added);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      final payments = [for (final entry in await liveEntries()) if (entry.amountMinor == 1200000) entry];
      expect(payments, hasLength(1), reason: 'counted once');
      expect(payments.single.kind, 'transfer');
      expect(payments.single.accountId, (await accounts.findBySmsKey('HDFC Bank:ac:7781'))!.id);
      expect(payments.single.toAccountId, (await card())!.id);
      expect(payments.single.categoryId, isNull);
      expect(added, isEmpty, reason: 'nothing new was added, so nothing to announce');
    });

    test('card SMS first: a transfer from the default bank, completed by the bank debit', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9));
      final savings = await bank();
      final other = await accounts.create(name: 'SBI', type: 'bank', color: 0);
      defaultAccountId = other.id;
      final added = <SmsAutoAdded>[];
      final subscription = service.autoAdded.listen(added.add);

      expect(await ingest(_cardPayment, at: DateTime(2026, 10, 21, 10)), IngestStatus.added);
      var payments = [for (final entry in await liveEntries()) if (entry.amountMinor == 1200000) entry];
      expect(payments.single.kind, 'transfer');
      expect(payments.single.accountId, other.id, reason: 'the default bank until the bank SMS says otherwise');

      expect(await ingest(_bankDebit, at: DateTime(2026, 10, 21, 11)), IngestStatus.added);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      payments = [for (final entry in await liveEntries()) if (entry.amountMinor == 1200000) entry];
      expect(payments, hasLength(1), reason: 'counted once');
      expect(payments.single.accountId, savings.id);
      expect(payments.single.toAccountId, (await card())!.id);
      expect(added, hasLength(1), reason: 'only the transfer was announced');
      expect((await accounts.getById(savings.id))!.balanceMinor, 3000000, reason: 'the bank SMS balance still lands');
    });

    test('a second card payment does not take a bank debit already linked', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9));
      await bank();
      await ingest(_cardPayment, at: DateTime(2026, 10, 21, 10));
      await ingest(_bankDebit, at: DateTime(2026, 10, 21, 11));
      await ingest('Rs 12,000.00 debited from HDFC Bank A/c XX7781 on 22-10-26 towards HDFC Credit Card bill. Avl Bal Rs 18,000.00', at: DateTime(2026, 10, 22, 9));
      final payments = [for (final entry in await liveEntries()) if (entry.amountMinor == 1200000) entry];
      expect(payments.map((entry) => entry.kind), unorderedEquals(['transfer', 'expense']));
    });

    test('with no bank to take it from, it waits for review and approves into a transfer', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9));
      expect(await ingest(_cardPayment), IngestStatus.pending);
      final row = (await smsLog.watchPending().first).single;
      expect(await service.approvePending(row), isNull, reason: 'the user picks the bank in the editor');

      final savings = await bank();
      final entryId = await service.approvePending(row);
      final entry = (await liveEntries()).singleWhere((entry) => entry.id == entryId);
      expect(entry.kind, 'transfer');
      expect(entry.accountId, savings.id);
      expect(entry.toAccountId, (await card())!.id);
    });

    test('with auto-add off it waits for review', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9), autoAdd: false);
      await bank();
      expect(await ingest(_cardPayment, autoAdd: false), IngestStatus.pending);
      expect(await liveEntries(), isEmpty);
    });

    test('the same payment pasted again is a duplicate', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9));
      await bank();
      await ingest(_cardPayment, at: DateTime(2026, 10, 21, 10));
      final again = await service.ingest(RawSms(sender: RawSms.pastedSender, body: _cardPayment, receivedAt: DateTime(2026, 10, 21, 18)), autoAdd: true, force: true);
      expect(again, IngestStatus.duplicate);
      expect([for (final entry in await liveEntries()) if (entry.amountMinor == 1200000) entry], hasLength(1));
    });

    test('a payment in another currency is not read', () async {
      await bank();
      final status = await ingest('Payment of USD 100.00 received on your HDFC Bank Credit Card ending 4521 on 21-10-2026.');
      expect(status, IngestStatus.foreignCurrency);
      expect(await liveEntries(), isEmpty);
    });

    test('a bank debit read with auto-add off still completes the card transfer', () async {
      await ingest(_cardSpend, at: DateTime(2026, 10, 20, 9));
      final other = await accounts.create(name: 'SBI', type: 'bank', color: 0);
      defaultAccountId = other.id;
      await ingest(_cardPayment, at: DateTime(2026, 10, 21, 10));
      await ingest(_bankDebit, at: DateTime(2026, 10, 21, 11), autoAdd: false);
      // Linking needs no approval, so the bank SMS is never pending.
      expect(await smsLog.watchPending().first, isEmpty);
      final payments = [for (final entry in await liveEntries()) if (entry.amountMinor == 1200000) entry];
      expect(payments.single.accountId, (await accounts.findBySmsKey('HDFC Bank:ac:7781'))!.id);
    });
  });
}
