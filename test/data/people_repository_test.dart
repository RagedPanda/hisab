import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/data/repositories/people_repository.dart';

void main() {
  late AppDatabase db;
  late GroupsRepository groups;
  late PeopleRepository people;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    groups = GroupsRepository(db);
    people = PeopleRepository(db);
  });

  tearDown(() => db.close());

  List<(String, String)> namesAndEmails(List<Person> rows) => [for (final person in rows) (person.name, person.email)];

  test('adding a member with an email puts them on the People list', () async {
    final groupId = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'Me');
    await groups.addMember(groupId, ' Amit ', email: 'Amit@Gmail.com');
    await groups.addMember(groupId, 'Riya');
    expect(namesAndEmails(await people.watchAll().first), [('Amit', 'amit@gmail.com')]);
  });

  test('the same email in another group is one person with the latest name', () async {
    final goa = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'Me');
    final flat = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me');
    await groups.addMember(goa, 'Amit', email: 'amit@gmail.com');
    await groups.addMember(flat, 'Amit Kumar', email: 'AMIT@gmail.com');
    expect(namesAndEmails(await people.watchAll().first), [('Amit Kumar', 'amit@gmail.com')]);
  });

  test('editing a member to add an email remembers them', () async {
    final groupId = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'Me');
    final riya = await groups.addMember(groupId, 'Riya');
    await groups.editMember(riya, name: 'Riya S', email: 'riya@example.com');
    final member = (await groups.getMembers(groupId)).firstWhere((member) => member.id == riya);
    expect((member.name, member.email), ('Riya S', 'riya@example.com'));
    expect(namesAndEmails(await people.watchAll().first), [('Riya S', 'riya@example.com')]);
  });

  test('the People list comes back with a backup on a new device', () async {
    await people.remember(name: 'Amit', email: 'amit@gmail.com');
    final restored = AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    await BackupService(restored).importSnapshot(await BackupService(db).snapshot());
    expect(namesAndEmails(await PeopleRepository(restored).watchAll().first), [('Amit', 'amit@gmail.com')]);
  });
}
