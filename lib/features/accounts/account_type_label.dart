import '../../l10n/l10n.dart';

/// Localized name of an account type; unknown types read as cash.
String accountTypeLabel(AppLocalizations l10n, String type) => switch (type) {
      'bank' => l10n.accountTypeBank,
      'card' => l10n.accountTypeCard,
      'wallet' => l10n.accountTypeWallet,
      _ => l10n.accountTypeCash,
    };
