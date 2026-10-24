import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../domain/upcoming/upcoming_items.dart';
import '../../../l10n/category_names.dart';
import '../../../l10n/l10n.dart';
import '../../shell/widgets/common.dart';

IconData upcomingSourceIcon(UpcomingSource source) => switch (source) {
  UpcomingSource.recurring => Icons.repeat,
  UpcomingSource.reminder => Icons.notifications_none_outlined,
  UpcomingSource.cardDue => Icons.credit_card_outlined,
};

/// "Overdue by 3 days", "Due today", "Due tomorrow" or "In 5 days · 27 Oct".
String upcomingDueLabel(BuildContext context, UpcomingItem item) {
  final l10n = context.l10n;
  return switch (item.daysAway) {
    < 0 => l10n.upcomingOverdueBy(-item.daysAway),
    0 => l10n.upcomingDueToday,
    1 => l10n.upcomingDueTomorrow,
    _ => l10n.upcomingDueInDays(item.daysAway, formatRowDate(item.dueAt, locale: Localizations.localeOf(context).toString())),
  };
}

/// One due item: source icon, title, due label (red when overdue) and amount.
/// Shared by the dashboard card and the due calendar.
class UpcomingItemTile extends ConsumerWidget {
  const UpcomingItemTile({super.key, required this.item, this.onTap});
  final UpcomingItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = item.title.isEmpty && item.categoryId != null
        ? ref.watch(allCategoriesProvider).value?.where((category) => category.id == item.categoryId).firstOrNull
        : null;
    final title = category == null ? item.title : categoryDisplayName(category, Localizations.localeOf(context));
    final scheme = theme.colorScheme;
    final dueColor = item.isOverdue ? scheme.error : scheme.onSurfaceVariant;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: item.isOverdue ? scheme.errorContainer : scheme.surfaceContainerHigh,
        foregroundColor: item.isOverdue ? scheme.onErrorContainer : scheme.onSurfaceVariant,
        child: Icon(upcomingSourceIcon(item.source), size: 20),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        upcomingDueLabel(context, item),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(color: dueColor, fontWeight: item.isOverdue ? FontWeight.w600 : null),
      ),
      trailing: item.amountMinor == null ? null : AmountText(item.amountMinor!, kind: item.isIncome ? 'income' : 'expense', signed: false),
    );
  }
}
