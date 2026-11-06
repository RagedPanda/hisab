import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

final _when = DateTime(2026, 10, 21, 11);

Entry _transfer({String? payee, String note = ''}) => Entry(
      updatedAt: _when,
      id: 'e1',
      kind: 'transfer',
      amountMinor: 800000,
      currency: 'INR',
      occurredAt: _when,
      payee: payee,
      note: note,
      source: 'sms',
      tags: '',
      createdAt: _when,
    );

Account _account(String name, String type) => Account(
      updatedAt: _when,
      id: name,
      name: name,
      type: type,
      balanceMinor: 0,
      includeInTotal: true,
      color: 0,
      sortOrder: 0,
    );

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final hindi = lookupAppLocalizations(const Locale('hi'));
  final bank = _account('HDFC Bank ••7781', 'bank');
  final card = _account('HDFC Bank Card ••4521', 'card');
  EntryDetails billPayment({String? payee, String note = ''}) =>
      EntryDetails(entry: _transfer(payee: payee, note: note), items: const [], account: bank, toAccount: card);

  test('a payment into a card with nothing else to go by is titled as the card bill', () {
    expect(entryTileTitle(english, billPayment(), categoryName: 'Credit Card Payment'), 'Card bill · HDFC Bank Card ••4521');
    expect(entryTileTitle(hindi, billPayment(), categoryName: 'Credit Card Payment'), 'कार्ड बिल · HDFC Bank Card ••4521');
  });

  test('a payee or note the entry has still comes first', () {
    expect(entryTileTitle(english, billPayment(payee: 'CRED Club'), categoryName: null), 'CRED Club');
    expect(entryTileTitle(english, billPayment(note: 'October bill'), categoryName: null), 'October bill');
  });

  test('a transfer between bank accounts keeps the category, else Transfer', () {
    final details = EntryDetails(entry: _transfer(), items: const [], account: card, toAccount: bank);
    expect(entryTileTitle(english, details, categoryName: 'Savings'), 'Savings');
    expect(entryTileTitle(english, details, categoryName: null), 'Transfer');
  });
}
