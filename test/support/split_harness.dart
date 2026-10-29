import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

/// A group member for widget tests that never touch the database.
Member testMember(String id, String name, {bool isMe = false, double weight = 1}) =>
    Member(updatedAt: DateTime(2026, 10, 1), id: id, groupId: 'g1', name: name, isMe: isMe, weight: weight);

/// Pumps [child] in a scrolling, localised page and lets it settle.
Future<void> pumpLocalized(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
  ));
  await tester.pumpAndSettle();
}
