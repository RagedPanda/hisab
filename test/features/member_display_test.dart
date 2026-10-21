import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/groups/member_display.dart';
import 'package:hisab/l10n/generated/app_localizations_en.dart';

Member _member(String name, {required bool isMe}) => Member(
      updatedAt: DateTime(2026, 1, 1),
      id: 'm-$name',
      groupId: 'g1',
      name: name,
      isMe: isMe,
      weight: 1,
    );

void main() {
  final l10n = AppLocalizationsEn();

  test('the self member reads as You when no name is set', () {
    expect(memberDisplayName(l10n, _member('', isMe: true)), 'You');
    expect(memberDisplayName(l10n, _member('You', isMe: true)), 'You');
  });

  test('the legacy default name Me also reads as You', () {
    expect(memberDisplayName(l10n, _member(kLegacyDefaultMyName, isMe: true)), 'You');
    expect(memberShortName(l10n, _member(kLegacyDefaultMyName, isMe: true)), 'You');
  });

  test('a custom self name is suffixed and other members keep their name', () {
    expect(memberDisplayName(l10n, _member('Ankur', isMe: true)), 'Ankur (you)');
    expect(memberDisplayName(l10n, _member('Rahul', isMe: false)), 'Rahul');
    expect(memberInitial(_member('rahul', isMe: false)), 'R');
  });
}
