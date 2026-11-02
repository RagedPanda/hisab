import '../../data/app_lock/device_authenticator.dart';
import '../../l10n/l10n.dart';

/// The system unlock prompt in the app's language, with [reason] as the
/// line saying why it is up.
AuthPromptText appLockPrompt(AppLocalizations l10n, String reason) => AuthPromptText(
      reason: reason,
      title: l10n.appLockPromptTitle,
      hint: l10n.appLockPromptHint,
      cancel: l10n.cancel,
      fallback: l10n.appLockPromptFallback,
    );
