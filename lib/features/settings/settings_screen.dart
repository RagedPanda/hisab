import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../shell/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const SectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (set) => notifier.update((s) => s.copyWith(themeMode: set.first)),
              ),
            ),
          ),
          const SectionHeader('Money'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.currency_rupee),
                title: const Text('Currency symbol'),
                trailing: Text(settings.currencySymbol, style: Theme.of(context).textTheme.titleMedium),
                onTap: () async {
                  final symbol = await promptText(context, title: 'Currency symbol', initial: settings.currencySymbol, hint: '₹, \$, €');
                  if (symbol != null && symbol.isNotEmpty) await notifier.update((s) => s.copyWith(currencySymbol: symbol));
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Month starts on'),
                subtitle: const Text('Use your salary date so budgets follow your pay cycle'),
                trailing: Text('Day ${settings.monthStartDay}'),
                onTap: () async {
                  final text = await promptText(context, title: 'Month starts on day (1–28)', initial: '${settings.monthStartDay}', keyboardType: TextInputType.number);
                  final day = int.tryParse(text ?? '');
                  if (day != null && day >= 1 && day <= 28) await notifier.update((s) => s.copyWith(monthStartDay: day));
                },
              ),
              ListTile(leading: const Icon(Icons.account_balance_outlined), title: const Text('Accounts'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/accounts')),
              ListTile(leading: const Icon(Icons.category_outlined), title: const Text('Categories'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/categories')),
              ListTile(leading: const Icon(Icons.savings_outlined), title: const Text('Budgets'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/budgets')),
            ]),
          ),
          const SectionHeader('Automation'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sms_outlined),
              title: const Text('Bank SMS'),
              subtitle: Text(settings.smsEnabled ? 'On · reading bank SMS on this device' : 'Off'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/sms'),
            ),
          ),
          const SectionHeader('Groups'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Your name in groups'),
              trailing: Text(settings.myName),
              onTap: () async {
                final name = await promptText(context, title: 'Your name', initial: settings.myName);
                if (name != null && name.isNotEmpty) await notifier.update((s) => s.copyWith(myName: name));
              },
            ),
          ),
          const SectionHeader('Backup & sync'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Export encrypted backup'),
                subtitle: const Text('AES-256, protected by a passphrase you choose'),
                onTap: () => _export(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore from backup'),
                subtitle: const Text('Merges; newer local edits are kept'),
                onTap: () => _import(context, ref),
              ),
              const ListTile(
                leading: Icon(Icons.cloud_outlined),
                title: Text('Cloud sync'),
                subtitle: Text('Coming next: Google Drive on Android, iCloud on iOS, end-to-end encrypted with the same format as backups.'),
              ),
            ]),
          ),
          const SectionHeader('About'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Hisab'),
              subtitle: Text('Free, open source, no ads, no account needed. Your data stays on your device.'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final passphrase = await promptText(context, title: 'Backup passphrase', hint: 'At least 8 characters; you need it to restore');
    if (passphrase == null) return;
    if (passphrase.length < 8) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use at least 8 characters')));
      return;
    }
    final bytes = await ref.read(backupServiceProvider).exportEncrypted(passphrase);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/hisab-backup-$stamp.hisab');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Hisab encrypted backup'));
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    final data = await picked.first.readAsBytes();
    if (!context.mounted) return;
    final passphrase = await promptText(context, title: 'Backup passphrase');
    if (passphrase == null || !context.mounted) return;
    try {
      final written = await ref.read(backupServiceProvider).importEncrypted(data, passphrase);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restored $written records')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $error')));
    }
  }
}
