import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/features/shortcuts/launcher_sync.dart';
import 'package:hisab/features/shortcuts/shortcut_settings.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

import '../../support/app_harness.dart';

void main() {
  test('the Add expense notification is off until turned on, and stays on', () async {
    final container = await createContainer();
    expect(container.read(shortcutSettingsProvider).addExpenseNotification, isFalse);

    await container.read(shortcutSettingsProvider.notifier).setAddExpenseNotification(true);

    expect(container.read(shortcutSettingsProvider).addExpenseNotification, isTrue);
    expect(container.read(sharedPreferencesProvider).getBool(kAddExpenseNotificationKey), isTrue);
  });

  test('the notification speaks the app language', () {
    final english = addExpenseNotificationConfig(lookupAppLocalizations(const Locale('en')), enabled: true).toMap();
    expect(english, {'enabled': true, 'channelName': 'Add expense shortcut', 'title': 'Add expense', 'body': 'Tap to log a spend'});
    final hindi = addExpenseNotificationConfig(lookupAppLocalizations(const Locale('hi')), enabled: false).toMap();
    expect(hindi['title'], 'खर्च जोड़ें');
    expect(hindi['enabled'], isFalse);
  });
}
