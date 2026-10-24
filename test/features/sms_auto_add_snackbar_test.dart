import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/features/shell/app_shell.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/features/sms/sms_auto_add_snackbar.dart';
import 'package:hisab/features/sms/sms_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _upiDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';

/// Starts the real app at [location] on an in-memory database.
Future<ProviderContainer> _pumpAppAt(WidgetTester tester, String location) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR', 'smsEnabled': true});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
  ]);
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(430, 932));
  appRouter.go(location);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await _frames(tester);
  return container;
}

Future<void> _frames(WidgetTester tester, [int count = 12]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _autoAddOne(WidgetTester tester, ProviderContainer container) async {
  // Not awaited: the database work finishes while frames are pumped, which
  // also lets Home's watched queries settle under the fake clock.
  unawaited(container
      .read(smsIngestServiceProvider)
      .ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: DateTime(2026, 10, 21, 9)), autoAdd: true));
  await _frames(tester, 4);
  // Past the batch window, so the snackbar is announced.
  await tester.pump(kSmsAutoAddBatchWindow + const Duration(milliseconds: 100));
  await _frames(tester, 4);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Undo is offered when Bank SMS is opened from the hisab://sms link', (tester) async {
    final container = await _pumpAppAt(tester, 'hisab://sms');
    expect(find.byType(SmsScreen), findsOneWidget);
    // The deep link makes Bank SMS the only route; the tab shell is not built.
    expect(find.byType(AppShell), findsNothing);

    await _autoAddOne(tester, container);

    expect(find.widgetWithText(SnackBar, 'Undo'), findsOneWidget);
  });

  testWidgets('Undo is offered when Bank SMS is opened from Settings', (tester) async {
    final container = await _pumpAppAt(tester, '/home');
    appRouter.push('/sms');
    await _frames(tester);
    expect(find.byType(SmsScreen), findsOneWidget);

    await _autoAddOne(tester, container);

    expect(find.widgetWithText(SnackBar, 'Undo'), findsOneWidget);
  });
}
