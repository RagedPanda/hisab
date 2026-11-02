import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/features/settings/backup_actions.dart';
import 'package:hisab/features/udhaar/udhaar_providers.dart';

import '../../core/fake_notification_gateway.dart';
import '../../support/app_harness.dart' show createContainer;

void main() {
  testWidgets('a restore brings the backed-up UPI ID into reminders without a restart', (tester) async {
    final container = await createContainer(overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
    expect(container.read(myUpiIdProvider), isNull, reason: 'a fresh install has not been asked yet');

    // The udhaar backup section writes the UPI ID straight to prefs.
    await container.read(sharedPreferencesProvider).setString(kMyUpiIdPref, 'ankur@okhdfc');
    await tester.runAsync(() => applyRestoredSettings(container, const BackupRestoreResult(written: 1, currencyCode: null)));

    expect(container.read(myUpiIdProvider), 'ankur@okhdfc', reason: 'the first reminder must not ask again');
  });
}
