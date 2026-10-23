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

const _upiDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';
const _atmDebit = 'Rs.4,000.00 withdrawn from A/c XX1234 at ATM on 21-10-26. Avl bal Rs.11,541.00';

void main() {
  late AppDatabase db;
  late AccountsRepository accounts;
  late SmsLogRepository smsLog;
  late SmsIngestService service;
  late FakeSmsSource source;
  late SmsSyncCursor cursor;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    accounts = AccountsRepository(db);
    smsLog = SmsLogRepository(db);
    source = FakeSmsSource();
    cursor = SmsSyncCursor(await SharedPreferences.getInstance());
    service = SmsIngestService(smsLog: smsLog, accounts: accounts, categories: CategoriesRepository(db), entries: EntriesRepository(db), cursor: cursor, source: source, homeCurrencyCode: () => 'INR');
  });

  tearDown(() => db.close());

  Future<List<String>> accountNames() async => (await accounts.getAll()).map((a) => a.name).toList();

  test('IOS-04: a pending SMS creates no account until it is approved', () async {
    final received = DateTime(2026, 10, 21, 10, 0);
    final status = await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: false);
    expect(status, IngestStatus.pending);
    expect(await accountNames(), ['Cash'], reason: 'only the seeded Cash account exists');

    final row = (await smsLog.watchPending().first).single;
    await smsLog.setStatus(row.id, 'ignored');
    expect(await accountNames(), ['Cash']);
  });

  test('approving a pending SMS creates the account with the reported balance', () async {
    final received = DateTime(2026, 10, 21, 10, 0);
    await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: false);
    final row = (await smsLog.watchPending().first).single;
    final entryId = await service.approvePending(row);
    expect(entryId, isNotNull);
    final created = (await accounts.getAll()).firstWhere((a) => a.name != 'Cash');
    expect(created.name, 'HDFC Bank ••1234');
    expect(created.balanceMinor, 1554100);
  });

  test('AND-10: the same message received a minute later is a duplicate and cannot roll the balance back', () async {
    final first = DateTime(2026, 10, 21, 10, 0);
    await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: first), autoAdd: true);
    await service.ingest(RawSms(sender: 'HDFCBK', body: _atmDebit, receivedAt: first.add(const Duration(seconds: 30))), autoAdd: true);
    final account = (await accounts.getAll()).firstWhere((a) => a.name != 'Cash');
    expect(account.balanceMinor, 1154100);

    final again = await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: first.add(const Duration(minutes: 1))), autoAdd: true);
    expect(again, IngestStatus.duplicate);
    expect((await accounts.getAll()).firstWhere((a) => a.name != 'Cash').balanceMinor, 1154100);
  });

  test('idFor buckets by calendar day, not by minute', () {
    final morning = DateTime(2026, 10, 21, 9, 0);
    expect(SmsLogRepository.idFor('HDFCBK', _upiDebit, morning), SmsLogRepository.idFor('HDFCBK', _upiDebit, morning.add(const Duration(hours: 5))));
    expect(SmsLogRepository.idFor('HDFCBK', _upiDebit, morning), isNot(SmsLogRepository.idFor('HDFCBK', _upiDebit, morning.add(const Duration(days: 1)))));
  });

  group('sync', () {
    final now = DateTime(2026, 10, 22, 12);
    final morning = DateTime(2026, 10, 22, 9);

    test('ingests messages queued while the app was closed', () async {
      source.queue.add(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: morning));
      final result = await service.sync(autoAdd: false, now: now);
      expect(result.scanned, 1);
      expect(result.pending, 1);
      expect(source.queue, isEmpty, reason: 'draining empties the native queue');
    });

    test('#40: a debit-like SMS from a phone number in the inbox is ignored', () async {
      source.inbox.add(RawSms(sender: '+19876500011', body: 'Rs.500 debited from A/c XX1234 - send me the money bro', receivedAt: morning));
      final result = await service.sync(autoAdd: false, now: now);
      expect(result.pending, 0);
      expect(await db.select(db.smsLog).get(), isEmpty);
    });

    test('a message both queued and in the inbox is ingested once', () async {
      final sms = RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: morning);
      source.queue.add(sms);
      source.inbox.add(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: morning.add(const Duration(seconds: 2))));
      final result = await service.sync(autoAdd: true, now: now);
      expect(result.scanned, 2);
      expect(result.added, 1);
      expect((await db.select(db.entries).get()).length, 1);
    });

    test('the inbox scan starts at the stored cursor and advances it', () async {
      final older = DateTime(2026, 10, 20, 9);
      await cursor.write(older);
      source.inbox.add(RawSms(sender: 'HDFCBK', body: _atmDebit, receivedAt: morning));
      await service.sync(autoAdd: false, now: now);
      expect(source.lastSince, older.subtract(const Duration(minutes: 1)));
      expect(cursor.read(), morning);
    });

    test('a first sync looks back the full window', () async {
      await service.sync(autoAdd: false, now: now, lookback: const Duration(days: 90));
      expect(source.lastSince, now.subtract(const Duration(days: 90, minutes: 1)));
      expect(cursor.read(), isNull, reason: 'nothing seen, nothing to remember');
    });

    test('overlapping calls run one after the other', () async {
      source.queue.add(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: morning));
      final results = await Future.wait([service.sync(autoAdd: true, now: now), service.sync(autoAdd: true, now: now)]);
      expect(results.map((r) => r.added).toList(), [1, 0]);
    });
  });

  group('auto-add', () {
    final received = DateTime(2026, 10, 21, 10, 0);

    test('a confident bank SMS is added straight away and announced', () async {
      final announced = <SmsAutoAdded>[];
      final subscription = service.autoAdded.listen(announced.add);
      final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(status, IngestStatus.added);
      expect(announced, hasLength(1));
      expect(announced.single.amountMinor, 45900);
      expect(announced.single.isDebit, isTrue);
      final entry = await EntriesRepository(db).getEntry(announced.single.entryId);
      expect(entry!.entry.source, 'sms', reason: 'the entry carries the Added from SMS marker');
      expect(await smsLog.watchPending().first, isEmpty);
    });

    test('a parse without bank or account waits for review even with auto-add on', () async {
      final status = await service.ingest(RawSms(sender: 'PASTED', body: 'Paid Rs 250 to Ramesh', receivedAt: received), autoAdd: true, force: true);
      expect(status, IngestStatus.pending);
      final row = (await smsLog.watchPending().first).single;
      expect(row.parsedJson, isNotNull);
    });

    test('a bank SMS that names an amount but cannot be read goes to the review queue', () async {
      const unread = 'A/c XX1234: transaction of INR 1,200.00 on 21-10-26. Ref 998877';
      final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: unread, receivedAt: received), autoAdd: true);
      expect(status, IngestStatus.pending);
      final row = (await smsLog.watchPending().first).single;
      expect(row.parsedJson, isNull);
      expect(await service.approvePending(row), isNull, reason: 'nothing to add without an amount; the card offers Add manually');
    });

    test('an OTP from a bank is logged as skipped, not queued', () async {
      final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: 'Your OTP for txn of Rs 500 is 123456. Do not share.', receivedAt: received), autoAdd: true);
      expect(status, IngestStatus.unparsed);
      expect(await smsLog.watchPending().first, isEmpty);
    });

    test('Undo deletes the entry and marks the SMS ignored, not back in the review queue', () async {
      final announced = <SmsAutoAdded>[];
      final subscription = service.autoAdded.listen(announced.add);
      await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      await service.undoAutoAdd(announced.single);
      final entry = await EntriesRepository(db).getEntry(announced.single.entryId);
      expect(entry == null || entry.entry.deletedAt != null, isTrue);
      expect(await smsLog.watchPending().first, isEmpty);
      final row = await smsLog.getById(announced.single.smsId);
      expect(row!.status, 'ignored');
      expect(row.entryId, isNull);
      final again = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      expect(again, IngestStatus.duplicate, reason: 'a rescan must not add the undone SMS again');
    });
  });
  group('foreign currency', () {
    final received = DateTime(2026, 10, 21, 10, 0);
    const foreign = {
      'USD': 'USD 25.00 spent on your HDFC Bank Credit Card XX1234 at AMAZON US on 21-10-26.',
      'EUR': 'EUR 40.00 spent on your HDFC Bank Credit Card XX1234 at ZARA PARIS on 21-10-26.',
      'AED': 'AED 120.50 spent on your HDFC Bank Credit Card XX1234 at DUBAI MALL on 21-10-26.',
    };
    const home = {
      'INR': 'INR 459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl.',
      'Rs': 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl.',
      '₹': '₹459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl.',
      'no marker': 'A/c XX1234 debited by 459.00 on 21-10-26 to swiggy@ybl.',
    };

    for (final MapEntry(key: code, value: body) in foreign.entries) {
      test('a $code SMS is ignored: not added and not queued for review', () async {
        final announced = <SmsAutoAdded>[];
        final subscription = service.autoAdded.listen(announced.add);
        final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: body, receivedAt: received), autoAdd: true);
        await Future<void>.delayed(Duration.zero);
        await subscription.cancel();

        expect(status, IngestStatus.foreignCurrency);
        expect(announced, isEmpty);
        expect(await smsLog.watchPending().first, isEmpty);
        expect(await EntriesRepository(db).watchHasAnyEntries().first, isFalse);
        final again = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: body, receivedAt: received), autoAdd: true);
        expect(again, IngestStatus.duplicate, reason: 'a rescan must not read it again');
      });
    }

    test('a foreign SMS is ignored with auto-add off too', () async {
      final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: foreign['USD']!, receivedAt: received), autoAdd: false);
      expect(status, IngestStatus.foreignCurrency);
      expect(await smsLog.watchPending().first, isEmpty);
    });

    for (final MapEntry(key: marker, value: body) in home.entries) {
      test('an SMS with $marker is processed', () async {
        final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: body, receivedAt: received), autoAdd: true);
        expect(status, IngestStatus.added);
      });
    }
  });

  group('SMS history', () {
    final received = DateTime(2026, 10, 21, 10, 0);
    Future<List<SmsHistoryRow>> history() => smsLog.watchHistory().first;

    test('a non-bank message from a business sender is logged as not a bank message', () async {
      final status = await service.ingest(RawSms(sender: 'AMAZON', body: 'Your order has shipped', receivedAt: received), autoAdd: true);
      expect(status, IngestStatus.notBank);
      final row = (await history()).single.log;
      expect(row.status, SmsLogStatus.notBank);
      expect(row.sender, 'AMAZON');
      expect(row.receivedAt, received);
      expect(row.body, isEmpty, reason: 'the text of OTPs and promotions is never stored');
    });

    test('a not-bank message is still recognised without its text and its re-delivery is not logged', () async {
      const otp = 'Your OTP for login is 482913. Do not share it.';
      await service.ingest(RawSms(sender: 'AMAZON', body: otp, receivedAt: received), autoAdd: true);
      final again = await service.ingest(RawSms(sender: 'AMAZON', body: otp, receivedAt: received.add(const Duration(hours: 2))), autoAdd: true);
      expect(again, IngestStatus.duplicate);
      final rows = await history();
      expect(rows.single.log.status, SmsLogStatus.notBank);
      expect(rows.single.log.body, isEmpty);
    });

    test('not-bank text stored by an earlier build is wiped when the database opens', () async {
      await db.into(db.smsLog).insert(SmsLogCompanion.insert(id: 'old', sender: 'AMAZON', body: 'Your OTP is 123456', receivedAt: received, status: SmsLogStatus.notBank));
      await db.into(db.smsLog).insert(SmsLogCompanion.insert(id: 'bank', sender: 'HDFCBK', body: _upiDebit, receivedAt: received, status: SmsLogStatus.skipped));
      await db.wipeUnkeptSmsText();
      expect((await smsLog.getById('old'))!.body, isEmpty);
      expect((await smsLog.getById('bank'))!.body, _upiDebit, reason: 'bank messages keep their text');
    });

    test('an OTP from a DLT business header (AX-AMAZON) is ignored with no text and no duplicate', () async {
      const otp = 'Your OTP for login is 482913. Do not share it.';
      final status = await service.ingest(RawSms(sender: 'AX-AMAZON', body: otp, receivedAt: received), autoAdd: true);
      expect(status, IngestStatus.notBank);
      await service.ingest(RawSms(sender: 'AX-AMAZON', body: otp, receivedAt: received.add(const Duration(hours: 2))), autoAdd: true);
      final row = (await history()).single.log;
      expect(row.sender, 'AX-AMAZON');
      expect(row.status, SmsLogStatus.notBank);
      expect(row.body, isEmpty);
    });

    // #74: promotions from 6-character business headers ended as Unreadable
    // with their full text.
    const businessPromos = {
      'VM-SWIGGY': 'Craving biryani? Get 60% OFF up to Rs.120 on your next order. Use code TRYNEW. Order now: swgy.in/a1b2 T&C apply',
      'JM-MYNTRA': 'END OF REASON SALE is LIVE! Flat 50-80% off on 1 lakh+ styles. Shop now: myntr.it/x9Yz',
      'AD-ZOMATO': 'Rs.100 cashback credited? Not yet! Use code ZOMSAVE for 40% off your next 3 orders. Hurry, limited time!',
      'BZ-FLPKRT': 'Big Billion Days: extra 10% off with SBI cards. Buy now before stocks run out!',
    };
    for (final MapEntry(key: sender, value: body) in businessPromos.entries) {
      test('a promotion from $sender is ignored and its text discarded', () async {
        final status = await service.ingest(RawSms(sender: sender, body: body, receivedAt: received), autoAdd: true);
        expect(status, IngestStatus.notBank);
        final row = (await history()).single.log;
        expect(row.status, SmsLogStatus.notBank);
        expect(smsOutcomeFor(row.status), SmsOutcome.ignored);
        expect(row.body, isEmpty);
      });
    }

    test('a business message without a transaction or promotion is ignored and its text discarded', () async {
      final status = await service.ingest(
          RawSms(sender: 'VM-SWIGGY', body: 'Your order from Meghana Foods has been delivered. Enjoy your meal!', receivedAt: received),
          autoAdd: true);
      expect(status, IngestStatus.notBank);
      expect((await history()).single.log.body, isEmpty);
    });

    test('a transaction from a bank header not on the known list is still read', () async {
      final status = await service.ingest(
          RawSms(sender: 'VM-CANBNK', body: 'Rs.1,200.00 debited from A/c XX4321 on 21-10-26 to amazon@apl. UPI Ref 512345678901. -Canara Bank', receivedAt: received),
          autoAdd: true);
      expect(status, IngestStatus.added);
    });

    test('an unreadable text with a transaction signal from an unknown header stays re-processable', () async {
      const body = 'Your A/c XX4321 has been linked to UPI ID ravi@cnrb.';
      final status = await service.ingest(RawSms(sender: 'VM-CANBNK', body: body, receivedAt: received), autoAdd: true);
      expect(status, IngestStatus.unparsed);
      final row = (await history()).single.log;
      expect(row.status, SmsLogStatus.skipped);
      expect(row.body, body);
    });

    test('an OTP from a real bank header keeps no text and logs no duplicate', () async {
      const otp = 'OTP for txn of Rs.2,500.00 at AMAZON on HDFC Bank card XX1234 is 739201. Do not share it with anyone.';
      final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: otp, receivedAt: received), autoAdd: true);
      expect(status, IngestStatus.unparsed);
      await service.ingest(RawSms(sender: 'VM-HDFCBK', body: otp, receivedAt: received.add(const Duration(hours: 2))), autoAdd: true);
      final row = (await history()).single.log;
      expect(row.status, SmsLogStatus.skipped);
      expect(row.body, isEmpty);
    });

    test('OTP text stored under a bank sender by an earlier build is wiped when the database opens', () async {
      await db.into(db.smsLog).insert(SmsLogCompanion.insert(id: 'otp', sender: 'AX-AMAZON', body: 'Your OTP is 123456', receivedAt: received, status: SmsLogStatus.skipped));
      await db.into(db.smsLog).insert(SmsLogCompanion.insert(id: 'statement', sender: 'HDFCBK', body: 'Your statement is ready', receivedAt: received, status: SmsLogStatus.skipped));
      await db.wipeUnkeptSmsText();
      expect((await smsLog.getById('otp'))!.body, isEmpty);
      expect((await smsLog.getById('statement'))!.body, 'Your statement is ready');
    });

    test('a message from a person is never kept', () async {
      await service.ingest(RawSms(sender: '+919810000000', body: 'See you at 6', receivedAt: received), autoAdd: true);
      expect(await history(), isEmpty);
    });

    test('a bank re-delivery gets its own duplicate row linked to the original entry', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      final again = await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received.add(const Duration(minutes: 20))), autoAdd: true);
      expect(again, IngestStatus.duplicate);
      final rows = await history();
      expect(rows.map((row) => row.log.status), [SmsLogStatus.duplicate, SmsLogStatus.added]);
      expect(rows.first.log.entryId, rows.last.log.entryId);
      expect(rows.first.hasEntry, isTrue);

      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received.add(const Duration(minutes: 20))), autoAdd: true);
      expect(await history(), hasLength(2), reason: 'reading the re-delivery again adds nothing');
    });

    test('reading the same delivery again (live then inbox) is not a duplicate', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received.add(const Duration(seconds: 4))), autoAdd: true);
      expect((await history()).single.log.status, SmsLogStatus.added);
    });

    test('a deleted entry no longer counts as linked', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      final row = (await history()).single;
      await EntriesRepository(db).deleteEntry(row.log.entryId!);
      expect((await history()).single.hasEntry, isFalse);
    });

    test('re-processing a dismissed message puts it back up for review', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: false);
      final pending = (await history()).single.log;
      await smsLog.setStatus(pending.id, SmsLogStatus.ignored);

      final status = await service.reprocess((await smsLog.getById(pending.id))!, autoAdd: false);
      expect(status, IngestStatus.pending);
      final row = (await history()).single.log;
      expect(row.id, pending.id);
      expect(row.status, SmsLogStatus.pending);
    });

    test('re-processing an unreadable bank message forces it through the parser again', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: 'Your statement is ready on NetBanking.', receivedAt: received), autoAdd: true);
      final row = (await history()).single.log;
      expect(row.status, SmsLogStatus.skipped);
      final status = await service.reprocess(row, autoAdd: true);
      expect(status, IngestStatus.unparsed);
      expect((await history()).single.log.status, SmsLogStatus.skipped);
    });

    test('clearing hides processed messages, keeps pending ones and still blocks re-import', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      await service.ingest(RawSms(sender: 'HDFCBK', body: _atmDebit, receivedAt: received.add(const Duration(minutes: 5))), autoAdd: false);
      final cleared = await smsLog.clearHistory(now: received.add(const Duration(days: 1)));
      expect(cleared, 1);

      final rows = await history();
      expect(rows.single.log.status, SmsLogStatus.pending);
      final again = await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      expect(again, IngestStatus.duplicate);
      final entries = await db.select(db.entries).get();
      expect(entries, hasLength(1), reason: 'the cleared message is not added a second time');
      final wiped = await smsLog.getById(SmsLogRepository.idFor('HDFCBK', _upiDebit, received));
      expect(wiped!.body, isEmpty);
    });
  });
}

class FakeSmsSource implements SmsSource {
  final queue = <RawSms>[];
  final inbox = <RawSms>[];
  DateTime? lastSince;

  @override
  Future<List<RawSms>> drainQueue() async {
    final drained = List<RawSms>.of(queue);
    queue.clear();
    return drained;
  }

  @override
  Future<List<RawSms>> readInbox({required DateTime since}) async {
    lastSince = since;
    return inbox.where((sms) => sms.receivedAt.isAfter(since)).toList();
  }
}
