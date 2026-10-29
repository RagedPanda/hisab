import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/repositories/entries_repository.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../categories/category_picker.dart';
import '../shell/widgets/common.dart';

/// The entry an SMS added, live; empty once it is deleted or undone.
final _smsEntryProvider = StreamProvider.autoDispose.family<EntryDetails?, String>(
  (ref, entryId) => ref.watch(entriesRepositoryProvider).watchEntriesById(entryId).map((found) => found.where((details) => details.entry.deletedAt == null).firstOrNull),
);

/// Opened by "Change category" on an "added from SMS" notification: shows the
/// entry and opens the category picker straight away. The pick is saved on
/// the entry and remembered for the SMS payee.
class SmsEntryCategoryScreen extends ConsumerStatefulWidget {
  const SmsEntryCategoryScreen({super.key, required this.entryId, required this.smsId});
  final String entryId;
  final String smsId;

  @override
  ConsumerState<SmsEntryCategoryScreen> createState() => _SmsEntryCategoryScreenState();
}

class _SmsEntryCategoryScreenState extends ConsumerState<SmsEntryCategoryScreen> {
  bool _pickerOpened = false;

  Future<void> _pick(EntryDetails details) async {
    final picked = await showCategoryPicker(context, kind: details.entry.kind, selectedId: details.category?.id);
    if (picked == null || !mounted) return;
    final l10n = context.l10n;
    final name = picked.displayName(context);
    final payee = details.entry.payee;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await ref.read(smsIngestServiceProvider).changeSmsEntryCategory(smsId: widget.smsId, entryId: widget.entryId, categoryId: picked.id);
    if (!saved || !mounted) return;
    showTimedSnackBar(messenger, payee == null || payee.isEmpty ? l10n.smsEntryCategoryChanged(name) : l10n.smsPayeeRemembered(name, payee));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(kHomeLocation);
    }
  }

  void _openPickerOnce(EntryDetails details) {
    if (_pickerOpened) return;
    _pickerOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pick(details);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = ref.watch(_smsEntryProvider(widget.entryId));
    final details = entry.value;
    if (details != null) _openPickerOnce(details);
    return HomeFallbackPop(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.smsEntryChangeCategory)),
        body: switch (entry) {
          AsyncData(value: null) => EmptyState(icon: Icons.undo, title: l10n.smsEntryGoneTitle, message: l10n.smsEntryGoneBody),
          AsyncData(value: final EntryDetails found) => _EntrySummary(details: found, onChange: () => _pick(found)),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _EntrySummary extends ConsumerWidget {
  const _EntrySummary({required this.details, required this.onChange});
  final EntryDetails details;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final category = details.category;
    final payee = details.entry.payee;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(formatMinor(details.entry.amountMinor, format: moneyFormat), style: theme.textTheme.headlineSmall),
        if (payee != null && payee.isNotEmpty) Text(payee, style: theme.textTheme.titleMedium),
        if (details.account != null) Text(details.account!.name, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: category == null ? const Icon(Icons.label_off_outlined) : IconBadge(icon: category.icon, color: category.color),
            title: Text(l10n.category),
            subtitle: Text(category?.displayName(context) ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: onChange,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onChange, icon: const Icon(Icons.category_outlined), label: Text(l10n.smsEntryChangeCategory)),
      ],
    );
  }
}
