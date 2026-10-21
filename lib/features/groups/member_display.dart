import 'package:flutter/material.dart';

import '../../core/settings.dart';
import '../../data/db/database.dart';
import '../../l10n/l10n.dart';

/// Resolves the label shown for a member: the "me" member reads as "You" (or
/// "Name (you)" when a custom name is set); everyone else shows their name.
String memberDisplayName(AppLocalizations l10n, Member member) {
  if (!member.isMe) return member.name;
  final name = member.name.trim();
  if (name.isEmpty || name == l10n.you) return l10n.you;
  return l10n.youSuffix(name);
}

/// The name used for the user in new groups: Settings value, else "You".
String resolvedMyName(AppLocalizations l10n, AppSettings settings) => settings.myName.trim().isEmpty ? l10n.you : settings.myName.trim();

/// Short label used in balance lines: "You" for the me member, else the name.
String memberShortName(AppLocalizations l10n, Member member) => member.isMe ? l10n.you : member.name;

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
