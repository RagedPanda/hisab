import '../../domain/split/settle_up_links.dart';
import '../../l10n/generated/app_localizations.dart';

/// One transfer as the names and formatted amount a message mentions.
typedef TransferWords = ({String from, String to, String amount});

/// The prewritten message for one transfer, from my point of view, with a
/// short footer. [role] decides the wording: you owe me, I owe you, or a
/// neutral line about two other people.
String settleUpMessage(AppLocalizations l10n, {required SettleRole role, required TransferWords transfer, required String groupName}) {
  final body = switch (role) {
    SettleRole.remind => l10n.reminderOwesMe(transfer.from, transfer.amount, groupName),
    SettleRole.pay => l10n.reminderIOwe(transfer.to, transfer.amount, groupName),
    SettleRole.others => l10n.reminderOwes(transfer.from, transfer.to, transfer.amount, groupName),
  };
  return '$body\n\n${l10n.sharedFromHisab}';
}

/// One message listing every transfer, for "Remind everyone who owes you".
String remindEveryoneMessage(AppLocalizations l10n, {required List<TransferWords> transfers, required String groupName}) {
  final lines = [for (final transfer in transfers) l10n.owesLine(transfer.from, transfer.to, transfer.amount)];
  return '${l10n.reminderEveryone(groupName)}\n${lines.join('\n')}\n\n${l10n.sharedFromHisab}';
}
