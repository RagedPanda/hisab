import 'package:flutter/material.dart';

import '../../core/settings.dart';
import '../../data/db/database.dart';
import '../../l10n/l10n.dart';

/// Groups created before the self member defaulted to an empty name stored
/// this literal; it is shown as "You" rather than "Me (you)".
const String kLegacyDefaultMyName = 'Me';

/// Resolves the label shown for a member: the "me" member reads as "You" (or
/// "Name (you)" when a custom name is set); everyone else shows their name.
String memberDisplayName(AppLocalizations l10n, Member member) {
  if (!member.isMe) return member.name;
  final name = member.name.trim();
  if (name.isEmpty || name == l10n.you || name == kLegacyDefaultMyName) return l10n.you;
  return l10n.youSuffix(name);
}

/// The name used for the user in new groups: Settings value, else "You".
String resolvedMyName(AppLocalizations l10n, AppSettings settings) => settings.myName.trim().isEmpty ? l10n.you : settings.myName.trim();

/// Short label used in balance lines: "You" for the me member, else the name.
String memberShortName(AppLocalizations l10n, Member member) => member.isMe ? l10n.you : member.name;

/// Joins names as "A", "A and B" or "A, B and C", using the locale's [and].
String joinNames(List<String> names, String Function(String first, String last) and) =>
    names.length < 2 ? names.join() : and(names.sublist(0, names.length - 1).join(', '), names.last);

/// Who paid an expense, for its list line: one payer reads as their name;
/// several read as "Rahul and you", with me last and in lower case.
String payerNamesLine(AppLocalizations l10n, List<String> payerIds, {required String? myMemberId, required String Function(String memberId) nameOf}) {
  if (payerIds.length < 2) return payerIds.map(nameOf).join();
  final includesMe = payerIds.contains(myMemberId);
  return joinNames([
    for (final id in payerIds)
      if (id != myMemberId) nameOf(id),
    if (includesMe) l10n.youInList,
  ], l10n.namesAnd);
}

String memberInitial(Member member) {
  final name = member.name.trim();
  return name.isEmpty ? '?' : name[0].toUpperCase();
}

/// Avatar for a member row: a filled person glyph for the me member, otherwise
/// the first letter of the name.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (member.isMe) {
      return CircleAvatar(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, child: const Icon(Icons.person));
    }
    return CircleAvatar(child: Text(memberInitial(member)));
  }
}
