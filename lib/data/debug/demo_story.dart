/// Debug-only hand-written demo rows that the README screenshots show: a
/// multi-item dairy bill, a Goa trip with three payers and a settle-up, bank
/// SMS waiting for review and three subscriptions. Called by `seedDemoData`
/// after the generated entries, so it runs once per database.
library;

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/sms/sms_parser.dart';
import '../db/database.dart';
import '../repositories/entries_repository.dart';
import '../repositories/groups_repository.dart';
import '../repositories/recurring_repository.dart';
import '../repositories/sms_log_repository.dart';
import '../sms/sms_ingest_service.dart';

/// One trip bill split equally between every member.
class DemoTripExpense {
  const DemoTripExpense({required this.payee, required this.categoryKey, required this.amountMinor, required this.daysAgo, required this.paidBy});
  final String payee;
  final String categoryKey;
  final int amountMinor;
  final int daysAgo;

  /// Member name of the payer; empty means me.
  final String paidBy;
}

const List<DemoTripExpense> kDemoTripExpenses = [
  DemoTripExpense(payee: 'Scooter rental', categoryKey: 'cab_auto', amountMinor: 210000, daysAgo: 2, paidBy: 'Rahul'),
  DemoTripExpense(payee: "Fisherman's Wharf", categoryKey: 'restaurants', amountMinor: 486000, daysAgo: 2, paidBy: 'Priya'),
  DemoTripExpense(payee: 'Beach shack drinks', categoryKey: 'restaurants', amountMinor: 132000, daysAgo: 1, paidBy: ''),
];

/// Bank messages left in the review queue, newest first.
const List<(String sender, String body)> kDemoReviewSms = [
  ('VM-HDFCBK', 'Sent Rs.450.00 from HDFC Bank A/C *4421 to SWIGGY on 24-10-26. Ref 629400001234. Not You? Call 18002586161'),
  ('AX-AXISBK', 'INR 2,199.00 spent on Axis Bank Card XX8812 at AMAZON on 23-10-26. Avl Lmt INR 1,45,300.00. Not you? SMS BLOCK 8812'),
  ('VM-HDFCBK', 'Update! INR 85,000.00 deposited in HDFC Bank A/c XX4421 on 22-10-26 for NEFT Cr-ACME PVT LTD SALARY. Avl bal INR 1,12,450.00'),
];

/// Monthly subscriptions: name, amount and day of month.
const List<(String name, String categoryKey, int amountMinor, int dayOfMonth)> kDemoSubscriptions = [
  ('Netflix', 'ott', 64900, 12),
  ('Jio recharge', 'mobile_recharge', 34900, 3),
  ('Spotify', 'music', 11900, 20),
];

/// Splits [amountMinor] equally [memberCount] ways; the first members take the
/// leftover paise so the shares always add up to the bill.
List<int> equalShares(int amountMinor, int memberCount) => [
      for (var index = 0; index < memberCount; index++) amountMinor ~/ memberCount + (index < amountMinor % memberCount ? 1 : 0),
    ];

/// The next date on or after [now]'s day that falls on [dayOfMonth].
DateTime nextDayOfMonth(DateTime now, int dayOfMonth) {
  final thisMonth = DateTime(now.year, now.month, dayOfMonth);
  return thisMonth.isBefore(DateTime(now.year, now.month, now.day)) ? DateTime(now.year, now.month + 1, dayOfMonth) : thisMonth;
}

Future<void> seedDemoStory(
  AppDatabase db, {
  required DateTime now,
  required String groupId,
  required List<String> accountIds,
  required Map<String, String> categoryIdByKey,
  required String source,
}) async {
  await _seedDairyBill(db, now: now, accountId: accountIds.last, categoryId: categoryIdByKey['milk_dairy'], source: source);
  await _seedTrip(db, now: now, groupId: groupId, accountId: accountIds[1], categoryIdByKey: categoryIdByKey, source: source);
  await _seedReviewSms(db, now: now);
  await _seedSubscriptions(db, now: now, accountId: accountIds[1], categoryIdByKey: categoryIdByKey);
}

Future<void> _seedDairyBill(AppDatabase db, {required DateTime now, required String accountId, String? categoryId, required String source}) async {
  final entryId = newId();
  EntryItemsCompanion item(String name, double quantity, String unit, int unitPriceMinor, int sortOrder) => EntryItemsCompanion.insert(
        id: newId(),
        entryId: entryId,
        name: name,
        quantity: Value(quantity),
        unit: Value(unit),
        unitPriceMinor: unitPriceMinor,
        amountMinor: (quantity * unitPriceMinor).round(),
        sortOrder: Value(sortOrder),
      );
  final items = [item('Buffalo milk', 2, 'L', 7200, 0), item('Paneer', 0.2, 'kg', 21000, 1)];
  await EntriesRepository(db).saveEntry(
    EntriesRepository.newExpense(
      id: entryId,
      amountMinor: items.fold(0, (total, row) => total + row.amountMinor.value),
      occurredAt: now.subtract(const Duration(minutes: 30)),
      categoryId: categoryId,
      accountId: accountId,
      payee: 'Gwala Ji',
      source: source,
    ),
    items: items,
  );
}

Future<void> _seedTrip(
  AppDatabase db, {
  required DateTime now,
  required String groupId,
  required String accountId,
  required Map<String, String> categoryIdByKey,
  required String source,
}) async {
  final groups = GroupsRepository(db);
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((member) => member.isMe);
  String memberIdNamed(String name) => name.isEmpty ? me.id : members.firstWhere((member) => member.name == name).id;

  for (final expense in kDemoTripExpenses) {
    final entryId = newId();
    final paidBy = memberIdNamed(expense.paidBy);
    final shares = equalShares(expense.amountMinor, members.length);
    await EntriesRepository(db).saveEntry(
      EntriesRepository.newExpense(
        id: entryId,
        amountMinor: expense.amountMinor,
        occurredAt: now.subtract(Duration(days: expense.daysAgo, hours: 2)),
        categoryId: categoryIdByKey[expense.categoryKey],
        accountId: paidBy == me.id ? accountId : null,
        payee: expense.payee,
        source: source,
        groupId: groupId,
        paidByMemberId: paidBy,
        splitMethod: 'equal',
      ),
      splits: [
        for (final (index, member) in members.indexed)
          SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: member.id, amountMinor: shares[index], shareValue: const Value(1)),
      ],
    );
  }
  await groups.addSettlement(
    groupId: groupId,
    fromMemberId: memberIdNamed('Rahul'),
    toMemberId: me.id,
    amountMinor: 100000,
    occurredAt: now.subtract(const Duration(hours: 5)),
    method: 'upi',
  );
}

Future<void> _seedReviewSms(AppDatabase db, {required DateTime now}) async {
  final smsLog = SmsLogRepository(db);
  for (final (index, (sender, body)) in kDemoReviewSms.indexed) {
    final receivedAt = now.subtract(Duration(days: 5 + index));
    final parsed = parseBankSms(sender: sender, body: body, receivedAt: receivedAt);
    await smsLog.record(
      id: 'demo-sms-$index',
      sender: sender,
      body: body,
      receivedAt: receivedAt,
      status: 'pending',
      parsed: parsed == null ? null : smsLogPayload(parsed),
    );
  }
}

Future<void> _seedSubscriptions(AppDatabase db, {required DateTime now, required String accountId, required Map<String, String> categoryIdByKey}) async {
  final recurring = RecurringRepository(db);
  for (final (name, categoryKey, amountMinor, dayOfMonth) in kDemoSubscriptions) {
    await recurring.saveRule(
      RecurringRepository.newRule(
        name: name,
        kind: 'expense',
        amountMinor: amountMinor,
        categoryId: categoryIdByKey[categoryKey],
        accountId: accountId,
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: dayOfMonth,
        startDate: nextDayOfMonth(now, dayOfMonth),
        autoPost: false,
        isSubscription: true,
      ),
    );
  }
}
