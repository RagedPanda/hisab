import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/udhaar/udhaar.dart';
import 'package:hisab/features/udhaar/udhaar_card.dart';
import 'package:hisab/features/udhaar/udhaar_form_screen.dart';
import 'package:hisab/features/udhaar/udhaar_providers.dart';

import '../../support/app_harness.dart' show createContainer, enter, openedLocation, pumpScreen, settle;
import '../../support/group_harness.dart' show FakeOutsideWorld;
import '../../support/screen_harness.dart';

/// Rahul (with a phone) on the People list, and [amountMinor] lent to him on
/// 12 Oct from Cash when given. Returns his id.
Future<String> seedRahul(WidgetTester tester, ProviderContainer container, {int? amountMinor, String? phone = '9876543210'}) async =>
    (await tester.runAsync(() async {
      final rahulId = await container.read(peopleRepositoryProvider).addPerson(name: 'Rahul', phone: phone);
      if (amountMinor != null) {
        final cashId = (await container.read(accountsRepositoryProvider).getAll()).single.id;
        await container.read(udhaarRepositoryProvider).save((
          personId: rahulId,
          personName: 'Rahul',
          kind: UdhaarKind.lent,
          amountMinor: amountMinor,
          occurredAt: DateTime(2026, 10, 12, 9),
          accountId: cashId,
          note: 'Rent share',
        ));
      }
      return rahulId;
    }))!;

Future<int> cashBalance(WidgetTester tester, ProviderContainer container) async =>
    (await tester.runAsync(() => container.read(accountsRepositoryProvider).getAll()))!.single.balanceMinor;

String balanceText(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('udhaar.balance'))).data!;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('the person page shows what they owe and each entry with the balance after it', (tester) async {
    final container = await createContainer();
    final rahulId = await seedRahul(tester, container, amountMinor: 250000);
    await pumpAt(tester, container, '/udhaar/person/$rahulId');

    expect(balanceText(tester), 'Rahul owes you ₹2,500');
    expect(find.text('Lent to Rahul'), findsOneWidget);
    expect(find.textContaining('Rent share'), findsOneWidget);
    expect(find.byKey(const Key('udhaar.remind')), findsOneWidget);
    expect(find.byKey(const Key('udhaar.addRepayment')), findsOneWidget);
  });

  testWidgets('lending from the person page moves Cash and is not spending', (tester) async {
    final container = await createContainer();
    final rahulId = await seedRahul(tester, container);
    await pumpAt(tester, container, '/udhaar/person/$rahulId');
    expect(balanceText(tester), 'All settled with Rahul');
    expect(find.byKey(const Key('udhaar.remind')), findsNothing);

    await tapAndSettle(tester, find.byKey(const Key('udhaar.addLent')));
    expect(find.byType(UdhaarFormScreen), findsOneWidget);
    expect(find.text('Rahul'), findsOneWidget, reason: 'the person is filled in');
    await enter(tester, find.byKey(const Key('udhaar.amount')), '2500');
    await tapAndSettle(tester, find.byKey(const Key('udhaar.save')));
    await settle(tester);

    expect(find.byType(UdhaarFormScreen), findsNothing);
    expect(balanceText(tester), 'Rahul owes you ₹2,500');
    expect(await cashBalance(tester, container), -250000);
    final now = DateTime.now();
    final month = DateRange(DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
    final totals = await tester.runAsync(() => container.read(entriesRepositoryProvider).watchTotals(month).first);
    expect(totals, (expense: 0, income: 0));
  });

  testWidgets('a repayment is prefilled with the balance and settles it', (tester) async {
    final container = await createContainer();
    final rahulId = await seedRahul(tester, container, amountMinor: 80000);
    await pumpAt(tester, container, '/udhaar/person/$rahulId');

    await tapAndSettle(tester, find.byKey(const Key('udhaar.addRepayment')));
    final chip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('udhaar.kind.repaid_to_me')));
    expect(chip.selected, isTrue);
    expect(tester.widget<TextField>(find.byKey(const Key('udhaar.amount'))).controller!.text, '800');
    await tapAndSettle(tester, find.byKey(const Key('udhaar.save')));
    await settle(tester);

    expect(balanceText(tester), 'All settled with Rahul');
    expect(await cashBalance(tester, container), 0);
  });

  testWidgets('deleting an entry from its form can be undone', (tester) async {
    final container = await createContainer();
    final rahulId = await seedRahul(tester, container, amountMinor: 50000);
    await pumpAt(tester, container, '/udhaar/person/$rahulId');

    await tapAndSettle(tester, find.text('Lent to Rahul'));
    await tapAndSettle(tester, find.byKey(const Key('udhaar.delete')));
    await settle(tester);
    expect(balanceText(tester), 'All settled with Rahul');
    expect(await cashBalance(tester, container), 0);

    await tapAndSettle(tester, find.text('Undo'));
    await settle(tester);
    expect(balanceText(tester), 'Rahul owes you ₹500');
    expect(await cashBalance(tester, container), -50000);
  });

  testWidgets('the first reminder asks for my UPI ID, then opens WhatsApp with a pay link', (tester) async {
    final world = FakeOutsideWorld();
    final container = await createContainer(preferences: {'myName': 'Ankur Dubey'}, overrides: world.overrides);
    final rahulId = await seedRahul(tester, container, amountMinor: 250000);
    await pumpAt(tester, container, '/udhaar/person/$rahulId');

    await tapAndSettle(tester, find.byKey(const Key('udhaar.remind')));
    await enter(tester, find.byKey(const Key('udhaar.myUpiId')), ' Ankur@OKAxis ');
    await tapAndSettle(tester, find.byKey(const Key('udhaar.myUpiIdSave')));

    expect(container.read(myUpiIdProvider), 'ankur@okaxis');
    final chat = world.launchedUris.single;
    expect(chat.host, 'wa.me');
    expect(chat.path, '/919876543210');
    expect(
      chat.queryParameters['text'],
      'Hi Rahul, a reminder about ₹2,500 from 12 Oct. Pay via UPI: upi://pay?pa=ankur@okaxis&pn=Ankur%20Dubey&am=2500&cu=INR&tn=Hisab',
    );

    await tapAndSettle(tester, find.byKey(const Key('udhaar.remind')));
    expect(find.byKey(const Key('udhaar.myUpiId')), findsNothing, reason: 'asked only once');
    expect(world.launchedUris, hasLength(2));
  });

  testWidgets('without a phone or UPI ID the reminder goes to the share sheet without a link', (tester) async {
    final world = FakeOutsideWorld();
    final container = await createContainer(preferences: {kMyUpiIdPref: ''}, overrides: world.overrides);
    final rahulId = await seedRahul(tester, container, amountMinor: 250050, phone: null);
    await pumpAt(tester, container, '/udhaar/person/$rahulId');

    await tapAndSettle(tester, find.byKey(const Key('udhaar.remind')));
    expect(world.launchedUris, isEmpty);
    expect(world.sharedTexts.single, 'Hi Rahul, a reminder about ₹2,500.50 from 12 Oct.');
  });

  testWidgets('the Home card is hidden while every udhaar is settled', (tester) async {
    final container = await createContainer();
    await seedRahul(tester, container);
    await pumpScreen(tester, container, const Scaffold(body: SingleChildScrollView(child: UdhaarCard())));
    expect(find.byKey(const Key('dashboard.udhaarCard')), findsNothing);
  });

  testWidgets('the Home card lists who owes and whom I owe', (tester) async {
    final container = await createContainer();
    final rahulId = await seedRahul(tester, container, amountMinor: 250000);
    await pumpScreen(tester, container, const Scaffold(body: SingleChildScrollView(child: UdhaarCard())));
    expect(find.byKey(const Key('dashboard.udhaarCard')), findsOneWidget);
    expect(find.text('You get ₹2,500'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(ValueKey('udhaar.person.$rahulId')));
    expect(find.text(openedLocation('/udhaar/person/$rahulId')), findsOneWidget);
  });

  testWidgets('the Home card opens the People & udhaar list even with one person', (tester) async {
    final container = await createContainer();
    await seedRahul(tester, container, amountMinor: 250000);
    await pumpScreen(tester, container, const Scaffold(body: SingleChildScrollView(child: UdhaarCard())));
    await tapAndSettle(tester, find.byKey(const Key('dashboard.udhaarSeeAll')));
    expect(find.text(openedLocation('/udhaar')), findsOneWidget);
  });

  testWidgets('the People & udhaar list adds a person and opens their page', (tester) async {
    final container = await createContainer();
    final rahulId = await seedRahul(tester, container, amountMinor: 1000);
    await pumpAt(tester, container, '/udhaar');
    expect(find.byKey(ValueKey('udhaar.person.$rahulId')), findsOneWidget);
    expect(find.text('You get ₹10'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('udhaar.addPerson')));
    await enter(tester, find.byKey(const Key('udhaar.personName')), 'Priya');
    await tapAndSettle(tester, find.byKey(const Key('udhaar.personSave')));
    await settle(tester);
    expect(balanceText(tester), 'All settled with Priya');
  });

  testWidgets('opening an udhaar entry in the general editor goes to the udhaar form', (tester) async {
    final container = await createContainer();
    final rahulId = await seedRahul(tester, container, amountMinor: 1000);
    final entryId = (await tester.runAsync(() => container.read(udhaarRepositoryProvider).watchPersonEntries(rahulId).first))!.single.id;
    await pumpAt(tester, container, '/entry?id=$entryId');
    await settle(tester);

    expect(find.byType(UdhaarFormScreen), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('udhaar.amount'))).controller!.text, '10');
    expect(find.byKey(const Key('udhaar.delete')), findsOneWidget);
  });
}
