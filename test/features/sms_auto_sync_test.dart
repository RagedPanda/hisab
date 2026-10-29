import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/features/sms/sms_auto_sync.dart';

import '../support/app_harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Off Android there is no SMS channel, so resuming with Bank SMS on must
  // read nothing and leave the history empty.
  testWidgets('resuming the app off Android does not try to read SMS', (tester) async {
    final container = await createContainer(preferences: {'smsEnabled': true});
    await pumpScreen(tester, container, const SmsAutoSync(child: Scaffold(body: Text('Home'))));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpWithDatabase(tester);

    expect(find.text('Home'), findsOneWidget);
    final database = container.read(databaseProvider);
    expect(await tester.runAsync(() => database.select(database.smsLog).get()), isEmpty);
  });
}
