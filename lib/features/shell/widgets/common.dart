import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_icons.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../data/repositories/entries_repository.dart';
import '../../../l10n/category_names.dart';
import '../../../l10n/l10n.dart';

/// Rounded tile with a coloured icon, used for categories, accounts and groups.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 40});
  final String? icon;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = Color(color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: base.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(iconFor(icon), color: base, size: size * 0.55),
    );
  }
}

/// Amount text coloured by direction.
class AmountText extends StatelessWidget {
  const AmountText(this.minor, {super.key, required this.kind, this.style, this.signed = true});
  final int minor;
  final String kind;
  final TextStyle? style;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final symbol = ProviderScope.containerOf(context).read(settingsProvider).currencySymbol;
    final color = switch (kind) {
      'income' => const Color(0xFF2E9E6B),
      'expense' => const Color(0xFFD9534F),
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final prefix = !signed ? '' : switch (kind) { 'income' => '+', 'expense' => '-', _ => '' };
    return Text(
      '$prefix${formatMinor(minor, symbol: symbol)}',
      style: (style ?? Theme.of(context).textTheme.bodyLarge)?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}

/// One row in a transactions list.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.details, this.onTap, this.showDate = false});
  final EntryDetails details;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = details.entry;
    final category = details.category;
    final categoryName = category?.displayName(context);
    final title = entry.payee?.isNotEmpty == true
        ? entry.payee!
        : entry.note.isNotEmpty
            ? entry.note
            : categoryName ?? (entry.kind == 'transfer' ? l10n.kindTransfer : l10n.uncategorised);
    final subtitleParts = <String>[
      if (categoryName != null && title != categoryName) categoryName,
      if (details.items.isNotEmpty) l10n.itemCount(details.items.length),
      if (details.account != null) details.account!.name,
      if (entry.source == 'sms') l10n.sourceSms,
      if (showDate) formatShortDate(entry.occurredAt, locale: Localizations.localeOf(context).toString()),
    ];
    return ListTile(
      onTap: onTap,
      leading: IconBadge(
        icon: entry.kind == 'transfer' ? 'swap_horiz' : category?.icon,
        color: category?.color ?? 0xFF607D8B,
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: AmountText(entry.amountMinor, kind: entry.kind),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.outline),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Month switcher used by dashboard and transactions.
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(selectedRangeProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: () => ref.read(selectedMonthProvider.notifier).shift(-1), icon: const Icon(Icons.chevron_left)),
        GestureDetector(
          onTap: () => ref.read(selectedMonthProvider.notifier).reset(),
          child: Text(formatMonthLabel(range, locale: Localizations.localeOf(context).toString()), style: Theme.of(context).textTheme.titleSmall),
        ),
        IconButton(onPressed: () => ref.read(selectedMonthProvider.notifier).shift(1), icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

Future<bool> confirmDialog(BuildContext context, {required String title, String? message, String? confirmLabel}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel ?? context.l10n.delete)),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> promptText(BuildContext context, {required String title, String? initial, String? hint, TextInputType? keyboardType}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: hint), keyboardType: keyboardType),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(context.l10n.save)),
      ],
    ),
  );
}
