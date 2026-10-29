import 'package:drift/drift.dart';

import '../../domain/people/people.dart';
import '../db/database.dart';

/// The user's People list (see `domain/people/people.dart`).
class PeopleRepository {
  PeopleRepository(this.db);
  final AppDatabase db;

  /// Everyone on the list, by name.
  Stream<List<Person>> watchAll() =>
      (db.select(db.people)..where((t) => t.deletedAt.isNull())..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// Saves [name] under [email], replacing an older name (or a removed row).
  /// Does nothing when [email] is not an email.
  Future<void> remember({required String name, required String? email}) => rememberPerson(db, name: name, email: email);
}

/// Saves [name] under [email] in the People list, for [PeopleRepository] and
/// for writes that add a member inside their own transaction.
Future<void> rememberPerson(AppDatabase db, {required String name, required String? email}) async {
  final id = normaliseEmail(email);
  if (id == null || name.trim().isEmpty) return;
  await db.into(db.people).insertOnConflictUpdate(PeopleCompanion.insert(
        id: id,
        name: name.trim(),
        email: id,
        updatedAt: Value(DateTime.now()),
        deletedAt: const Value(null),
      ));
}
