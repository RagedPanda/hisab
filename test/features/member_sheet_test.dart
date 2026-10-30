import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/groups/member_sheet.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

Person _person(String name, String email) => Person(id: email, name: name, email: email, updatedAt: DateTime(2026, 10, 1));

final _people = [_person('Amit', 'amit@gmail.com'), _person('Riya', 'riya@example.com')];

/// Udhaar people: generated ids, no email, maybe a phone.
final _udhaarPeople = [
  Person(id: 'p-rahul', name: 'Rahul', email: '', phone: '9876543210', updatedAt: DateTime(2026, 10, 1)),
  Person(id: 'p-ravi', name: 'Ravi', email: '', updatedAt: DateTime(2026, 10, 1)),
];

/// Opens the add-member sheet over a button; [onResult] gets what it returned.
Future<void> _openSheet(WidgetTester tester, {Set<String> groupEmails = const {}, List<Person>? people, required void Function(MemberDetails?) onResult}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [peopleProvider.overrideWith((ref) => Stream.value(people ?? _people))],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onResult(await showMemberSheet(context, groupEmails: groupEmails)),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextField, label);

void main() {
  testWidgets('typing a name suggests a saved person and picking fills the email', (tester) async {
    MemberDetails? result;
    await _openSheet(tester, onResult: (details) => result = details);
    await tester.enterText(_field('Member name'), 'ami');
    await tester.pump();
    expect(find.byKey(const ValueKey('member.suggestion.amit@gmail.com')), findsOneWidget);
    expect(find.byKey(const ValueKey('member.suggestion.riya@example.com')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('member.suggestion.amit@gmail.com')));
    await tester.pump();
    expect(find.byKey(const ValueKey('member.suggestion.amit@gmail.com')), findsNothing, reason: 'a picked person is no longer suggested');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((result?.name, result?.email), ('Amit', 'amit@gmail.com'));
  });

  testWidgets('people without an email are suggested side by side and picking fills their phone', (tester) async {
    MemberDetails? result;
    await _openSheet(tester, people: [..._people, ..._udhaarPeople], onResult: (details) => result = details);
    await tester.enterText(_field('Member name'), 'ra');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('member.suggestion.p-rahul')), findsOneWidget);
    expect(find.byKey(const ValueKey('member.suggestion.p-ravi')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('member.suggestion.p-rahul')));
    await tester.pump();
    expect(find.byKey(const ValueKey('member.suggestion.p-rahul')), findsNothing, reason: 'a picked person is no longer suggested');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((result?.name, result?.email, result?.phone), ('Rahul', null, '9876543210'));
  });

  testWidgets('typing an email suggests by email and skips people already in the group', (tester) async {
    await _openSheet(tester, groupEmails: {'amit@gmail.com'}, onResult: (_) {});
    await tester.enterText(_field('Email (optional)'), 'example');
    await tester.pump();
    expect(find.byKey(const ValueKey('member.suggestion.riya@example.com')), findsOneWidget);
    await tester.enterText(_field('Email (optional)'), 'amit');
    await tester.pump();
    expect(find.byKey(const ValueKey('member.suggestion.amit@gmail.com')), findsNothing);
  });

  testWidgets('a malformed email blocks saving until it is fixed', (tester) async {
    MemberDetails? result;
    await _openSheet(tester, onResult: (details) => result = details);
    await tester.enterText(_field('Member name'), 'Kabir');
    await tester.enterText(_field('Email (optional)'), 'kabir@gmail');
    await tester.pump();
    expect(find.text('Enter an email like name@example.com'), findsOneWidget);
    await tester.enterText(_field('Email (optional)'), ' Kabir@Gmail.com ');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result?.email, 'kabir@gmail.com');
  });
}
