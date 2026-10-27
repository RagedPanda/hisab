import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../data/db/database.dart';
import '../../../domain/accounts/account_label.dart';
import '../../../l10n/l10n.dart';
import '../../accounts/accounts_screen.dart';
import '../../shell/widgets/common.dart';
import '../dashboard_keys.dart';
import '../dashboard_providers.dart';
import 'dashboard_card.dart';

const double kAccountCardWidth = 148;
const double kAccountStripHeight = 112;

/// Balance per account in a horizontal strip, with the headline total.
class AccountsCard extends ConsumerWidget {
  const AccountsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(accountsOverviewProvider);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final l10n = context.l10n;
    void openAccounts() => context.push('/accounts');
    return AsyncCard(
      value: overview,
      skeletonHeight: kAccountStripHeight,
      builder: (data) => DashboardSection(
        title: l10n.accounts,
        trailing: SectionAction(label: formatMinor(data.totalMinor, format: moneyFormat, showDecimals: false), onPressed: openAccounts),
        child: SizedBox(
          key: kAccountsCardKey,
          height: kAccountStripHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: data.accounts.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => index == data.accounts.length
                ? _AddAccountCard(onTap: openAccounts)
                : _AccountCard(account: data.accounts[index], moneyFormat: moneyFormat),
          ),
        ),
      ),
    );
  }
}

/// One balance card: name, the ••mask on its own line, credit cards as
/// "Due", and a prompt to set an opening balance when cash goes negative.
class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account, required this.moneyFormat});
  final Account account;
  final MoneyFormat moneyFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final label = splitAccountLabel(account.name);
    final isCard = account.type == 'card';
    final needsOpeningBalance = account.type == 'cash' && account.balanceMinor < 0;
    final balanceText = isCard
        ? l10n.cardDue(formatMinor(account.balanceMinor.abs(), format: moneyFormat, showDecimals: false))
        : formatMinor(account.balanceMinor, format: moneyFormat, showDecimals: false);
    final balanceColor = isCard || needsOpeningBalance ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;
    return SizedBox(
      width: kAccountCardWidth,
      child: DashboardCard(
        padding: const EdgeInsets.all(12),
        onTap: () => needsOpeningBalance
            ? showAccountForm(context, ref, existing: account, focusBalance: true)
            : isCard
                ? openCardAccount(context, account.id)
                : context.go(Uri(path: '/transactions', queryParameters: {'account': account.id}).toString()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconBadge(icon: accountIconFor(account.type), color: account.color, size: 28),
              const SizedBox(width: 8),
              Expanded(child: Text(label.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge)),
            ]),
            Text(label.mask ?? '', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
            Text(balanceText, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: balanceColor).tabular),
            if (needsOpeningBalance)
              Text(l10n.setOpeningBalance, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 96,
        decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: scheme.primary),
            const SizedBox(height: 4),
            Text(context.l10n.account, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary)),
          ],
        ),
      ),
    );
  }
}
