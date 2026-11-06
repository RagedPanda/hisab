import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/settings/backup_actions.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

/// Opens the passphrase dialog ([confirm]: the new-backup one) at text x2 on
/// a 360dp screen in [locale].
Future<AppLocalizations> _openDialog(WidgetTester tester, {required bool confirm, required Locale locale}) async {
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.binding.setSurfaceSize(const Size(360, 780));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late AppLocalizations l10n;
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (context) {
      l10n = AppLocalizations.of(context);
      return Scaffold(body: BackupPassphraseDialog(confirm: confirm));
    }),
  ));
  await tester.pumpAndSettle();
  return l10n;
}

/// Expects [text] to be shown in full inside the dialog: not cut short by a
/// line limit and not drawn past the dialog's edges.
void _expectShownInFull(WidgetTester tester, String text) {
  final shown = find.descendant(of: find.byType(AlertDialog), matching: find.text(text));
  expect(shown, findsOneWidget, reason: '"$text" is shown');
  expect(tester.renderObject<RenderParagraph>(shown).didExceedMaxLines, isFalse, reason: '"$text" is not cut short');
  final dialog = tester.getRect(find.byType(AlertDialog));
  final rect = tester.getRect(shown);
  expect(dialog.intersect(rect).size, rect.size, reason: '"$text" stays inside the dialog');
}

void main() {
  for (final locale in const [Locale('en'), Locale('hi')]) {
    testWidgets('the new-passphrase guidance is shown in full at text x2 (${locale.languageCode})', (tester) async {
      final l10n = await _openDialog(tester, confirm: true, locale: locale);
      _expectShownInFull(tester, l10n.backupPassphraseHelp);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the restore guidance is shown in full at text x2 (${locale.languageCode})', (tester) async {
      final l10n = await _openDialog(tester, confirm: false, locale: locale);
      _expectShownInFull(tester, l10n.restorePassphraseHint);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a too-short passphrase is explained in place of the guidance', (tester) async {
    final l10n = await _openDialog(tester, confirm: true, locale: const Locale('en'));
    await tester.enterText(find.byKey(const Key('backupPassphraseField')), 'short');
    await tester.enterText(find.byKey(const Key('backupPassphraseConfirmField')), 'short');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    _expectShownInFull(tester, l10n.passphraseTooShort);
    expect(find.text(l10n.backupPassphraseHelp), findsNothing);
  });
}
