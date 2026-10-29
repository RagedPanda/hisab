import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/core/settings.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/money/money_format.dart';
import 'package:hisab/features/salary/salary_reminder.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:share_plus/share_plus.dart' show XFile;

import '../core/fake_notification_gateway.dart';
import '../support/app_harness.dart' show pumpApp, settle;

const _pathProvider = MethodChannel('plugins.flutter.io/path_provider');
const _shareSheet = MethodChannel('dev.fluttercommunity.plus/share');

final class _PickedFile extends PlatformFile {
  _PickedFile(this.file);
  final File file;

  @override
  String get name => file.uri.pathSegments.last;

  @override
  Uri get uri => file.uri;

  @override
  XFile get xFile => XFile(file.path);

  @override
  int? lengthSync() => file.lengthSync();

  @override
  Future<int?> length() => file.length();

  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() => file.openRead().map(Uint8List.fromList);
}

/// File picker that hands back [picked], or nothing when the user backs out.
class _FakeFilePicker extends FilePickerPlatform {
  List<PlatformFile> picked = const [];

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => picked;
}

Future<ProviderContainer> _pumpSettings(WidgetTester tester) async {
  final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
  appRouter.push('/settings');
  await settle(tester);
  return container;
}

/// Scrolls Settings (a lazy list) until [finder] is built and on screen, then taps it.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await settle(tester, 3);
  await tester.tap(finder);
  await settle(tester);
}

/// Types [text] into the open prompt and confirms it.
Future<void> _answerPrompt(WidgetTester tester, String text) async {
  await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), text);
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await settle(tester);
}

/// Lets real work (encryption, file IO) finish between frames until [done].
Future<void> _waitFor(WidgetTester tester, bool Function() done) async {
  for (var attempt = 0; attempt < 100 && !done(); attempt++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

AppSettings _settings(ProviderContainer container) => container.read(settingsProvider);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('number format, month start, default account and group name are saved', (tester) async {
    final container = await _pumpSettings(tester);
    final db = container.read(databaseProvider);
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'cash', name: 'Cash', type: 'cash', color: 0xFF0D9488, balanceMinor: const Value(0)));
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'hdfc', name: 'HDFC Savings', type: 'bank', color: 0xFF1E88E5, balanceMinor: const Value(0)));
    await settle(tester);

    await _tapVisible(tester, find.text('Number format'));
    await tester.tap(find.byType(RadioListTile<NumberFormatChoice>).at(1));
    await settle(tester);
    expect(_settings(container).numberFormat, NumberFormatChoice.values[1]);

    await _tapVisible(tester, find.text('Month starts on'));
    await _answerPrompt(tester, '40');
    expect(_settings(container).monthStartDay, 1, reason: 'days past 28 are refused');
    await _tapVisible(tester, find.text('Month starts on'));
    await _answerPrompt(tester, '5');
    expect(_settings(container).monthStartDay, 5);

    await _tapVisible(tester, find.text('Default account'));
    await tester.tap(find.widgetWithText(RadioListTile<String>, 'HDFC Savings'));
    await settle(tester);
    expect(_settings(container).defaultAccountId, 'hdfc');

    await _tapVisible(tester, find.text('Your name in groups'));
    await _answerPrompt(tester, '   ');
    await _tapVisible(tester, find.text('Your name in groups'));
    await _answerPrompt(tester, 'Ankur');
    expect(_settings(container).myName, 'Ankur');
  });

  testWidgets('salary and bank SMS rows open their screens', (tester) async {
    await _pumpSettings(tester);

    await _tapVisible(tester, find.byKey(const Key('settingsSalary')));
    expect(appRouter.state.uri.toString(), kSalaryLocation);
    appRouter.pop();
    await settle(tester);

    await _tapVisible(tester, find.text('Bank SMS'));
    expect(appRouter.state.uri.toString(), '/sms');
  });

  testWidgets('choosing a language switches the app to it', (tester) async {
    final container = await _pumpSettings(tester);

    await _tapVisible(tester, find.text('Language'));
    await tester.tap(find.byType(RadioListTile<String>).last);
    await settle(tester);

    expect(_settings(container).localeCode, isNotEmpty);
    expect(find.text('Language'), findsNothing);
  });

  testWidgets('an exported backup restores with its passphrase and refuses a wrong one', (tester) async {
    final temp = Directory.systemTemp.createTempSync('hisab-settings-test');
    addTearDown(() => temp.deleteSync(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_pathProvider, (call) async => temp.path);
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_pathProvider, null));
    final sharedPaths = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_shareSheet, (call) async {
      sharedPaths.addAll(((call.arguments as Map)['paths'] as List).cast<String>());
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_shareSheet, null));
    final picker = _FakeFilePicker();
    final originalPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = originalPicker);
    await _pumpSettings(tester);

    await _tapVisible(tester, find.text('Export encrypted backup'));
    await _answerPrompt(tester, 'short');
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(sharedPaths, isEmpty);

    await _tapVisible(tester, find.text('Export encrypted backup'));
    await _answerPrompt(tester, 'correct horse');
    await _waitFor(tester, () => sharedPaths.isNotEmpty);
    final backupPath = sharedPaths.single;
    expect(backupPath, endsWith('.hisab'));

    await _tapVisible(tester, find.text('Restore from backup'));
    expect(find.byType(AlertDialog), findsNothing, reason: 'nothing picked, nothing asked');

    picker.picked = [_PickedFile(File(backupPath))];
    await _tapVisible(tester, find.text('Restore from backup'));
    await _waitFor(tester, () => find.byType(AlertDialog).evaluate().isNotEmpty);
    await _answerPrompt(tester, 'wrong passphrase');
    await _waitFor(tester, () => find.textContaining('Restore failed').evaluate().isNotEmpty);
    expect(find.textContaining('Restore failed'), findsOneWidget);

    await _tapVisible(tester, find.text('Restore from backup'));
    await _waitFor(tester, () => find.byType(AlertDialog).evaluate().isNotEmpty);
    await _answerPrompt(tester, 'correct horse');
    await _waitFor(tester, () => find.textContaining('Restored ').evaluate().isNotEmpty);
    expect(find.textContaining('Restored '), findsOneWidget);
  });
}
