import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/settle_up_links.dart';
import 'package:hisab/features/groups/settle_up_messages.dart';
import 'package:hisab/l10n/generated/app_localizations_en.dart';
import 'package:hisab/l10n/generated/app_localizations_hi.dart';

void main() {
  final l10n = AppLocalizationsEn();
  const transfer = (from: 'Rahul', to: 'Ankur', amount: '₹300');

  test('remind asks the debtor by name and ends with a short footer', () {
    expect(
      settleUpMessage(l10n, role: SettleRole.remind, transfer: transfer, groupName: 'Goa trip'),
      'Hi Rahul, a quick reminder: you owe me ₹300 for Goa trip.\n\nShared from Hisab',
    );
  });

  test('pay greets the person I owe', () {
    expect(settleUpMessage(l10n, role: SettleRole.pay, transfer: (from: 'Ankur', to: 'Priya', amount: '₹50'), groupName: 'Flat'), startsWith('Hi Priya, I owe you ₹50 for Flat.'));
  });

  test('a transfer between two others stays neutral', () {
    expect(settleUpMessage(l10n, role: SettleRole.others, transfer: transfer, groupName: 'Goa trip'), startsWith('Rahul owes Ankur ₹300 for Goa trip.'));
  });

  test('remind everyone lists one line per transfer', () {
    final message = remindEveryoneMessage(l10n, transfers: [transfer, (from: 'Priya', to: 'Ankur', amount: '₹120')], groupName: 'Goa trip');
    expect(message.split('\n'), ['Settling up Goa trip:', 'Rahul owes Ankur ₹300', 'Priya owes Ankur ₹120', '', 'Shared from Hisab']);
  });

  test('Hindi wording carries every value', () {
    final message = settleUpMessage(AppLocalizationsHi(), role: SettleRole.remind, transfer: transfer, groupName: 'Goa trip');
    for (final value in ['Rahul', '₹300', 'Goa trip']) {
      expect(message, contains(value));
    }
  });
}
