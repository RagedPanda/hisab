import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/core/salary_settings.dart';
import 'package:hisab/data/salary/salary_service.dart';
import 'package:hisab/domain/salary/salary_schedule.dart';
import 'package:hisab/features/salary/salary_providers.dart';
import 'package:hisab/features/salary/salary_reminder_watcher.dart';

import '../core/fake_notification_gateway.dart';
import '../support/app_harness.dart';

/// Holds every reconcile until [release], like a slow database.
class _GatedSalaryService extends SalaryService {
  _GatedSalaryService(super.db);
  final gate = Completer<void>();
  bool started = false;

  void release() => gate.complete();

  @override
  Future<SalaryStatus?> reconcile(SalarySettings settings, {required DateTime now, int monthStartDay = 1}) async {
    started = true;
    await gate.future;
    return null;
  }
}

void main() {
  testWidgets('a sync still running when the watcher is removed finishes without touching its ref', (tester) async {
    late _GatedSalaryService service;
    final container = await tester.runAsync(() => createContainer(overrides: [
          notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
          salaryServiceProvider.overrideWith((ref) => service = _GatedSalaryService(ref.watch(databaseProvider))),
        ]));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container!,
      child: const SalaryReminderWatcher(child: SizedBox()),
    ));
    await tester.pump();
    expect(service.started, isTrue, reason: 'the launch sync is waiting on reconcile');

    // Erase all data sends the app to onboarding, which drops the watcher
    // while its sync is still in flight.
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SizedBox()));
    service.release();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
