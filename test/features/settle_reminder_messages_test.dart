import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/settle_reminder.dart';
import 'package:hisab/features/groups/settle_up_messages.dart';
import 'package:hisab/l10n/generated/app_localizations_en.dart';
import 'package:hisab/l10n/generated/app_localizations_hi.dart';

void main() {
  final l10n = AppLocalizationsEn();
  const names = {'me': 'Ankur', 'ravi': 'Ravi', 'priya': 'Priya', 'amit': 'Amit'};
  String nameOf(String id) => names[id]!;
  String formatAmount(int minor) => '₹${minor ~/ 100}';

  ({String title, String body})? notify(SettleReminderFacts facts, {String? withMemberId}) => settleReminderNotification(
        l10n,
        facts: facts,
        groupName: 'Flat 302',
        nameOf: nameOf,
        formatAmount: formatAmount,
        withMemberId: withMemberId,
      );

  group('settleReminderNotification', () {
    test('names the member a reminder is about', () {
      final facts = settleReminderFacts(const [Transfer('ravi', 'me', 120000)], myMemberId: 'me', withMemberId: 'ravi');
      final text = notify(facts, withMemberId: 'ravi')!;
      expect(text.title, 'Settle up: Flat 302');
      expect(text.body, 'Ravi owes you ₹1200');
    });

    test('says what I owe the member', () {
      final facts = settleReminderFacts(const [Transfer('me', 'ravi', 50000)], myMemberId: 'me', withMemberId: 'ravi');
      expect(notify(facts, withMemberId: 'ravi')!.body, 'You owe Ravi ₹500');
    });

    test('sums the whole group when no member is named', () {
      final facts = settleReminderFacts(const [Transfer('ravi', 'me', 120000), Transfer('priya', 'me', 30000), Transfer('me', 'amit', 5000)], myMemberId: 'me');
      expect(notify(facts)!.body, '2 people owe you ₹1500 · You owe Amit ₹50');
    });

    test('is null once everything is settled', () {
      expect(notify(const SettleReminderFacts(owedToMe: [], iOwe: [])), isNull);
    });

    test('Hindi wording carries every value', () {
      final facts = settleReminderFacts(const [Transfer('ravi', 'me', 120000)], myMemberId: 'me');
      final text = settleReminderNotification(AppLocalizationsHi(), facts: facts, groupName: 'Flat 302', nameOf: nameOf, formatAmount: formatAmount)!;
      expect(text.title, contains('Flat 302'));
      expect(text.body, allOf(contains('Ravi'), contains('₹1200')));
    });
  });

  group('settleReminderNudge', () {
    String? nudge(SettleReminderFacts facts) =>
        settleReminderNudge(l10n, facts: facts, myMemberId: 'me', groupName: 'Flat 302', nameOf: nameOf, formatAmount: formatAmount);

    test('one transfer reuses the personal reminder message', () {
      final facts = settleReminderFacts(const [Transfer('ravi', 'me', 120000)], myMemberId: 'me');
      expect(nudge(facts), 'Hi Ravi, a quick reminder: you owe me ₹1200 for Flat 302.\n\nShared from Hisab');
    });

    test('several transfers list one line each', () {
      final facts = settleReminderFacts(const [Transfer('ravi', 'me', 120000), Transfer('me', 'amit', 5000)], myMemberId: 'me');
      expect(nudge(facts)!.split('\n'), ['Settling up Flat 302:', 'Ravi owes Ankur ₹1200', 'Ankur owes Amit ₹50', '', 'Shared from Hisab']);
    });

    test('nothing to nudge once settled', () {
      expect(nudge(const SettleReminderFacts(owedToMe: [], iOwe: [])), isNull);
    });
  });
}
