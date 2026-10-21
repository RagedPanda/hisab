import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.someKey` instead of `AppLocalizations.of(context).someKey`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Human-readable name of a supported locale, in that language.
String localeDisplayName(Locale locale) => switch (locale.languageCode) {
      'en' => 'English',
      'hi' => 'हिन्दी',
      'es' => 'Español',
      _ => locale.toLanguageTag(),
    };
