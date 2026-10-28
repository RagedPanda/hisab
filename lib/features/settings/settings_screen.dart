import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../data/db/database.dart';
import '../../domain/accounts/default_account.dart';
import '../../domain/currency/currency_lookup.dart';
import '../currency/currency_picker.dart';
import '../../l10n/l10n.dart';
import '../groups/member_display.dart';
import '../reminders/reminders_settings_tile.dart';
import '../salary/salary_providers.dart';
import '../salary/salary_reminder.dart';
import '../shell/widgets/common.dart';
import 'backup_actions.dart';
import 'made_with_love.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final salary = ref.watch(salarySettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          SectionHeader(l10n.appearance),
          Card(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
                    visualDensity: VisualDensity.standard,
                  ),
                  segments: [
                    compactSegment(context, value: ThemeMode.system, label: l10n.themeSystem, icon: Icons.brightness_auto),
                    compactSegment(context, value: ThemeMode.light, label: l10n.themeLight, icon: Icons.light_mode_outlined),
                    compactSegment(context, value: ThemeMode.dark, label: l10n.themeDark, icon: Icons.dark_mode_outlined),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (set) => notifier.update((s) => s.copyWith(themeMode: set.first)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.language),
                trailing: Text(_languageLabel(l10n, settings.localeCode)),
                onTap: () async {
                  final code = await _pickLanguage(context, settings.localeCode);
                  if (code != null) await notifier.update((s) => s.copyWith(localeCode: code));
                },
              ),
            ]),
          ),
          SectionHeader(l10n.money),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.currency_rupee),
                title: Text(l10n.currency),
                trailing: SettingValue(currencyShortLabel(settings.currencyCode)),
                visualDensity: VisualDensity.compact,
                onTap: () async {
                  final code = await showCurrencyPicker(context, selectedCode: settings.currencyCode);
                  if (code != null) await notifier.update((s) => s.copyWith(currencyCode: code, currencyConfirmed: true));
                },
              ),
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: Text(l10n.numberFormatTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: SettingValue(numberFormatSample(ref.watch(homeMoneyFormatProvider))),
                visualDensity: VisualDensity.compact,
                onTap: () async {
                  final choice = await _pickNumberFormat(context, settings, ref.read(deviceLocaleProvider));
                  if (choice != null) await notifier.update((s) => s.copyWith(numberFormat: choice));
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(l10n.monthStartsOn),
                subtitle: Text(l10n.monthStartsOnHelp, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: SettingValue(l10n.dayNumber(settings.monthStartDay)),
                visualDensity: VisualDensity.compact,
                onTap: () async {
                  final text = await promptText(context, title: l10n.monthStartPrompt, hint: l10n.monthStartsOnExplain, initial: '${settings.monthStartDay}', keyboardType: TextInputType.number);
                  final day = int.tryParse(text ?? '');
                  if (day != null && day >= 1 && day <= 28) await notifier.update((s) => s.copyWith(monthStartDay: day));
                },
              ),
              ListTile(
                key: const Key('settingsSalary'),
                leading: const Icon(Icons.payments_outlined),
                title: Text(salary.isSetUp ? l10n.salaryTitle : l10n.salarySetUp),
                subtitle: salary.isSetUp
                    ? Text(l10n.salarySummary(formatMinor(salary.amountMinor, format: ref.watch(homeMoneyFormatProvider)), salary.salaryDay), maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
                onTap: () => context.push(kSalaryLocation),
              ),
              ListTile(leading: const Icon(Icons.account_balance_outlined), title: Text(l10n.accounts), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/accounts')),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(l10n.defaultAccount),
                subtitle: Text(l10n.defaultAccountHelp, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: SettingValue(_defaultAccountLabel(ref, settings.defaultAccountId)),
                visualDensity: VisualDensity.compact,
                onTap: () async {
                  final id = await _pickDefaultAccount(context, ref, settings.defaultAccountId);
                  if (id != null) await notifier.update((s) => s.copyWith(defaultAccountId: id));
                },
              ),
              ListTile(leading: const Icon(Icons.category_outlined), title: Text(l10n.categories), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/categories')),
              ListTile(leading: const Icon(Icons.savings_outlined), title: Text(l10n.budgets), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/budgets')),
              ListTile(leading: const Icon(Icons.folder_outlined), title: Text(l10n.projects), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/projects')),
              ListTile(leading: const Icon(Icons.repeat), title: Text(l10n.recurringTitle), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/recurring')),
              ListTile(leading: const Icon(Icons.autorenew), title: Text(l10n.subscriptions), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/subscriptions')),
            ]),
          ),
          SectionHeader(l10n.automation),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sms_outlined),
              title: Text(l10n.bankSms),
              subtitle: Text(settings.smsEnabled ? l10n.bankSmsOn : l10n.off),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/sms'),
            ),
          ),
          const Card(child: RemindersSettingsTile()),
          SectionHeader(l10n.groups),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.yourNameInGroups),
              trailing: SettingValue(resolvedMyName(l10n, settings)),
              visualDensity: VisualDensity.compact,
              onTap: () async {
                final name = await promptText(context, title: l10n.yourName, initial: resolvedMyName(l10n, settings));
                if (name == null || name.trim().isEmpty) return;
                await notifier.update((s) => s.copyWith(myName: name.trim()));
                await ref.read(groupsRepositoryProvider).renameMyMembers(name.trim());
              },
            ),
          ),
          SectionHeader(l10n.backupAndSync),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.exportBackup),
                subtitle: Text(l10n.exportBackupHelp),
                onTap: () => _export(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: Text(l10n.restoreBackup),
                subtitle: Text(l10n.restoreBackupHelp),
                onTap: () => _import(context, ref),
              ),
            ]),
          ),
          SectionHeader(l10n.about),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.appName),
              subtitle: Text(l10n.aboutBody),
            ),
          ),
          const MadeWithLove(),
        ],
      ),
    );
  }

  static String _languageLabel(AppLocalizations l10n, String code) => code.isEmpty ? l10n.languageSystem : localeDisplayName(Locale(code));

  /// Returns the chosen locale code ('' = follow the device) or null if dismissed.
  Future<String?> _pickLanguage(BuildContext context, String current) {
    final l10n = context.l10n;
    final options = <String>['', for (final locale in AppLocalizations.supportedLocales) locale.languageCode];
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(dialogContext, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final code in options) RadioListTile<String>(value: code, title: Text(_languageLabel(l10n, code))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Name of the account new entries currently default to (the pinned one, or
  /// the auto-resolved cash account), or a dash when there are no accounts.
  String _defaultAccountLabel(WidgetRef ref, String configuredId) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final id = defaultEntryAccountId(accounts, configuredId: configuredId);
    for (final account in accounts) {
      if (account.id == id) return account.name;
    }
    return '—';
  }

  /// Lets the user pin which account new entries start on. Returns the chosen
  /// account id, or null if dismissed.
  Future<String?> _pickDefaultAccount(BuildContext context, WidgetRef ref, String configuredId) {
    final l10n = context.l10n;
    final accounts = ref.read(accountsProvider).value ?? const <Account>[];
    final current = defaultEntryAccountId(accounts, configuredId: configuredId);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.defaultAccount),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(dialogContext, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final account in accounts) RadioListTile<String>(value: account.id, title: Text(account.name)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the chosen number format, or null if dismissed. Each option is
  /// shown as a sample of how the home currency looks with it.
  Future<NumberFormatChoice?> _pickNumberFormat(BuildContext context, AppSettings settings, Locale deviceLocale) {
    final l10n = context.l10n;
    String sampleFor(NumberFormatChoice choice) => numberFormatSample(homeMoneyFormatFor(settings.copyWith(numberFormat: choice), deviceLocale));
    return showDialog<NumberFormatChoice>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.numberFormatTitle),
        children: [
          RadioGroup<NumberFormatChoice>(
            groupValue: settings.numberFormat,
            onChanged: (value) => Navigator.pop(dialogContext, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final choice in NumberFormatChoice.values)
                  RadioListTile<NumberFormatChoice>(
                    value: choice,
                    title: Text(choice == NumberFormatChoice.automatic ? l10n.numberFormatAutomatic : sampleFor(choice)),
                    subtitle: choice == NumberFormatChoice.automatic
                        ? Text('${sampleFor(choice)} · ${l10n.numberFormatAutomaticHelp}', maxLines: 2, overflow: TextOverflow.ellipsis)
                        : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final passphrase = await promptNewBackupPassphrase(context);
    if (passphrase == null) return;
    final bytes = await ref.read(backupServiceProvider).exportEncrypted(
      passphrase,
      currencyCode: ref.read(settingsProvider).currencyCode,
      numberFormat: ref.read(settingsProvider).numberFormat,
    );
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/hisab-backup-$stamp.hisab');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: l10n.backupShareSubject));
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    final data = await picked.first.readAsBytes();
    if (!context.mounted) return;
    final passphrase = await promptRestorePassphrase(context);
    if (passphrase == null || !context.mounted) return;
    try {
      final restored = await ref.read(backupServiceProvider).importEncrypted(data, passphrase);
      await applyRestoredSettings(ref, restored);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.restoredRecords(restored.written))));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.restoreFailed('$error'))));
    }
  }
}
