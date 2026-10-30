import 'package:drift/drift.dart';

import '../../core/ids.dart';
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

  /// One person, live or removed, as it changes; null when there is no such row.
  Stream<Person?> watchPerson(String id) => (db.select(db.people)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Adds someone the user lends to or borrows from, who may have no email:
  /// such a person gets a generated id and an empty email. Returns the id.
  Future<String> addPerson({required String name, String? phone}) async {
    final id = newId();
    await db.into(db.people).insert(PeopleCompanion.insert(id: id, name: name.trim(), email: '', phone: Value(_blankToNull(phone))));
    return id;
  }

  /// Changes a person's name and phone.
  Future<void> updatePerson(String id, {required String name, String? phone}) =>
      (db.update(db.people)..where((t) => t.id.equals(id))).write(PeopleCompanion(
        name: Value(name.trim()),
        phone: Value(_blankToNull(phone)),
        updatedAt: Value(DateTime.now()),
      ));
}

String? _blankToNull(String? text) => text == null || text.trim().isEmpty ? null : text.trim();

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
