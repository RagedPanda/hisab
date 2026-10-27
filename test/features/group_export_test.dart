import 'dart:ui' show Locale;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/group_export.dart';
import 'package:hisab/features/groups/group_export.dart';
import 'package:hisab/l10n/generated/app_localizations_en.dart';
import 'package:hisab/l10n/generated/app_localizations_hi.dart';
import 'package:hisab/core/money.dart';

void main() {
  final english = AppLocalizationsEn();
  const names = {'me': 'You', 'rahul': 'Rahul', 'asha': 'आशा'};
  String nameOf(String id) => names[id]!;

  group('groupSummaryText', () {
    test('lists who pays whom from my point of view, then where everyone stands', () {
      final text = groupSummaryText(
        english,
        groupName: 'Goa trip',
        transfers: const [Transfer('me', 'rahul', 150000), Transfer('asha', 'rahul', 50000), Transfer('asha', 'me', 2550)],
        net: const {'me': -147450, 'rahul': 200000, 'asha': -52550},
        totals: (totalMinor: 300000, paidByMember: const {'rahul': 300000}, shareByMember: const {'me': 147450, 'rahul': 100000, 'asha': 52550}),
        memberOrder: const ['me', 'rahul', 'asha'],
        myMemberId: 'me',
        nameOf: nameOf,
        moneyFormat: MoneyFormat.inr,
      );
      expect(
        text,
        '*Goa trip — balances*\n'
        'Group total: ₹3,000\n'
        'Your share: ₹1,474.50\n'
        'Rahul\'s share: ₹1,000\n'
        'आशा\'s share: ₹525.50\n'
        '\n'
        '*Who pays whom*\n'
        '• You owe Rahul ₹1,500\n'
        '• आशा owes Rahul ₹500\n'
        '• आशा owes you ₹25.50\n'
        '\n'
        '*Where everyone stands*\n'
        '• You owe ₹1,474.50 in total\n'
        '• Rahul gets back ₹2,000\n'
        '• आशा owes ₹525.50 in total\n'
        '\n'
        'Shared from Hisab',
      );
    });

    test('says all settled up when nobody owes anything', () {
      final text = groupSummaryText(english, groupName: 'Flat', transfers: const [], net: const {'me': 0}, totals: _noSpend, memberOrder: const ['me'], myMemberId: 'me', nameOf: nameOf, moneyFormat: MoneyFormat.inr);
      expect(text, '*Flat — balances*\nAll settled up.\n\nShared from Hisab');
    });

    test('shows the group total and my smaller share when I skipped some expenses, even once settled', () {
      final text = groupSummaryText(
        english,
        groupName: 'Goa trip',
        transfers: const [],
        net: const {'me': 0, 'rahul': 0},
        totals: (totalMinor: 30000000, paidByMember: const {'rahul': 30000000}, shareByMember: const {'me': 5000000, 'rahul': 25000000}),
        memberOrder: const ['me', 'rahul'],
        myMemberId: 'me',
        nameOf: nameOf,
        moneyFormat: MoneyFormat.inr,
      );
      expect(text, '*Goa trip — balances*\nGroup total: ₹3,00,000\nYour share: ₹50,000\nRahul\'s share: ₹2,50,000\n\nAll settled up.\n\nShared from Hisab');
    });

    test('reads in Hindi', () {
      final text = groupSummaryText(
        AppLocalizationsHi(),
        groupName: 'गोवा',
        transfers: const [Transfer('rahul', 'me', 10000)],
        net: const {'me': 10000, 'rahul': -10000},
        totals: (totalMinor: 20000, paidByMember: const {'me': 20000}, shareByMember: const {'me': 10000, 'rahul': 10000}),
        memberOrder: const ['me', 'rahul'],
        myMemberId: 'me',
        nameOf: (id) => id == 'me' ? 'आप' : 'राहुल',
        moneyFormat: MoneyFormat.inr,
      );
      expect(text, contains('राहुल को आपको ₹100 देने हैं'));
      expect(text, contains('आपको ₹100 वापस मिलेंगे'));
      expect(text, contains('ग्रुप का कुल खर्च: ₹200'));
      expect(text, contains('आपका हिस्सा: ₹100'));
      expect(text, contains('राहुल का हिस्सा: ₹100'));
      expect(text, endsWith('हिसाब ऐप से शेयर किया गया'));
    });
  });

  group('groupCsv from a stored group', () {
    late AppDatabase db;
    late GroupsRepository groups;
    late EntriesRepository entries;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      groups = GroupsRepository(db);
      entries = EntriesRepository(db);
    });
    tearDown(() => db.close());

    test('has an expense with two payers and a payment, in date order with running balances', () async {
      final groupId = await groups.createGroup(name: 'Goa', icon: 'beach', myName: 'Ankur', otherMembers: ['Rahul', 'प्रिया']);
      final members = await groups.getMembers(groupId);
      final me = members.firstWhere((member) => member.isMe).id;
      final rahul = members.firstWhere((member) => member.name == 'Rahul').id;
      final priya = members.firstWhere((member) => member.name == 'प्रिया').id;
      await groups.addSettlement(groupId: groupId, fromMemberId: priya, toMemberId: rahul, amountMinor: 30000, occurredAt: DateTime(2026, 10, 3), note: 'UPI, thanks');
      await entries.saveEntry(
        EntriesRepository.newExpense(id: 'hotel', amountMinor: 90000, occurredAt: DateTime(2026, 10, 2), groupId: groupId, paidByMemberId: rahul, splitMethod: 'equal', note: 'Hotel, "sea view"'),
        splits: [for (final member in [me, rahul, priya]) SplitsCompanion.insert(id: 'hotel-$member', entryId: 'hotel', memberId: member, amountMinor: 30000)],
        payers: [
          EntryPayersCompanion.insert(id: 'hotel-paid-rahul', entryId: 'hotel', memberId: rahul, amountMinor: 60000),
          EntryPayersCompanion.insert(id: 'hotel-paid-me', entryId: 'hotel', memberId: me, amountMinor: 30000),
        ],
      );

      final detail = (await groups.getGroupDetail(groupId))!;
      final csv = groupCsv(english, detail, categoryById: const {}, locale: const Locale('en'));
      final lines = csv.split('\r\n');

      expect(lines[0], 'Date,Description,Category,Cost,Paid by,Ankur (you) paid,Rahul paid,प्रिया paid,Ankur (you) share,Rahul share,प्रिया share,Ankur (you) balance,Rahul balance,प्रिया balance');
      expect(lines[1], startsWith('2026-10-02,"Hotel, ""sea view""",,900.00,'));
      expect(lines[1], contains('Rahul 600.00; Ankur (you) 300.00'));
      expect(lines[2], startsWith('2026-10-03,"प्रिया paid Rahul · UPI, thanks",Payment,300.00,'));
      // After the payment everyone is square.
      expect(lines[2], endsWith(',0.00,0.00,0.00'));
      // The payment is not spending: the total is the hotel bill alone.
      expect(lines[3], ',Total,,900.00,,300.00,600.00,0.00,300.00,300.00,300.00,0.00,0.00,0.00');

      final summary = groupSummaryFor(english, detail, moneyFormat: MoneyFormat.inr);
      expect(summary, contains('Group total: ₹900\nYour share: ₹300\nRahul\'s share: ₹300\nप्रिया\'s share: ₹300'));
    });
  });
}

const ExpenseTotals _noSpend = (totalMinor: 0, paidByMember: {}, shareByMember: {});
