import '../domain/salary/salary_schedule.dart';
import 'generated/app_localizations.dart';

/// A recurring rule's stored [name] as shown to the user. Names the app
/// writes itself are stored untranslated and translated here; anything the
/// user typed is shown as typed.
String localizedRuleName(AppLocalizations l10n, String name) => name == kSalaryRuleName ? l10n.salaryRuleName : name;
