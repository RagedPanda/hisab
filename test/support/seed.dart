import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';

/// The id of the seeded category with catalog key [seedKey] (e.g. `food`).
Future<String> seededCategoryId(ProviderContainer container, String seedKey) async =>
    (await container.read(categoriesRepositoryProvider).findBySeedKey(seedKey))!.id;

/// The id of the Cash account every fresh database starts with.
Future<String> cashAccountId(ProviderContainer container) async => (await container.read(accountsRepositoryProvider).getAll()).single.id;

/// Saves one personal entry named by its [payee], so list rows can be found by that text.
Future<void> seedEntry(
  ProviderContainer container, {
  required String id,
  required String payee,
  required int amountMinor,
  DateTime? occurredAt,
  String kind = 'expense',
  String note = '',
  String? categoryId,
  String? accountId,
  String? projectId,
  String tags = '',
}) =>
    container.read(entriesRepositoryProvider).saveEntry(EntriesRepository.newExpense(
          id: id,
          kind: kind,
          amountMinor: amountMinor,
          occurredAt: occurredAt ?? DateTime.now(),
          payee: payee,
          note: note,
          categoryId: categoryId,
          accountId: accountId,
          projectId: projectId,
        ).copyWith(tags: Value(tags)));

/// Every entry that is not deleted.
Future<List<Entry>> liveEntries(ProviderContainer container) {
  final db = container.read(databaseProvider);
  return (db.select(db.entries)..where((entry) => entry.deletedAt.isNull())).get();
}
