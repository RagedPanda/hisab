import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../l10n/l10n.dart';
import '../groups/member_display.dart';
import '../reminders/reminders_settings_tile.dart';
import '../shell/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
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
                title: Text(l10n.currencySymbol),
                trailing: SettingValue(settings.currencySymbol),
                visualDensity: VisualDensity.compact,
                onTap: () async {
                  final symbol = await promptText(context, title: l10n.currencySymbol, initial: settings.currencySymbol, hint: '₹, \$, €');
                  if (symbol != null && symbol.isNotEmpty) await notifier.update((s) => s.copyWith(currencySymbol: symbol));
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
              ListTile(leading: const Icon(Icons.account_balance_outlined), title: Text(l10n.accounts), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/accounts')),
              ListTile(leading: const Icon(Icons.category_outlined), title: Text(l10n.categories), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/categories')),
              ListTile(leading: const Icon(Icons.savings_outlined), title: Text(l10n.budgets), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/budgets')),
              ListTile(leading: const Icon(Icons.folder_outlined), title: Text(l10n.projects), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/projects')),
              ListTile(leading: const Icon(Icons.repeat), title: Text(l10n.recurringTitle), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/recurring')),
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
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: Text(l10n.cloudSync),
                subtitle: Text(l10n.cloudSyncHelp),
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

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final passphrase = await promptText(context, title: l10n.backupPassphrase, hint: l10n.backupPassphraseHelp);
    if (passphrase == null) return;
    if (passphrase.length < 8) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passphraseTooShort)));
      return;
    }
    final bytes = await ref.read(backupServiceProvider).exportEncrypted(passphrase);
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
    final passphrase = await promptText(context, title: l10n.backupPassphrase);
    if (passphrase == null || !context.mounted) return;
    try {
      final written = await ref.read(backupServiceProvider).importEncrypted(data, passphrase);
      await ref.read(reminderSchedulerProvider).rescheduleAll();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.restoredRecords(written))));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.restoreFailed('$error'))));
    }
  }
}
