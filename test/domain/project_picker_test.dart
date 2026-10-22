import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/projects/project_math.dart';
import 'package:hisab/domain/projects/project_picker.dart';

void main() {
  group('initialEntryProjectId', () {
    test('the project the editor was opened for wins', () {
      expect(initialEntryProjectId(explicitId: 'p2', lastUsedId: 'p1', activeIds: {'p1'}), 'p2');
    });

    test('falls back to the last project used this session while it is active', () {
      expect(initialEntryProjectId(lastUsedId: 'p1', activeIds: {'p1', 'p3'}), 'p1');
    });

    test('a last project that is no longer active is not reused', () {
      expect(initialEntryProjectId(lastUsedId: 'p1', activeIds: {'p3'}), isNull);
    });

    test('nothing remembered means no project', () {
      expect(initialEntryProjectId(activeIds: {'p1'}), isNull);
    });

    test('group entries do not inherit the last project', () {
      expect(initialEntryProjectId(lastUsedId: 'p1', activeIds: {'p1'}, isGroup: true), isNull);
    });
  });

  group('pickableProjects', () {
    final projects = [
      (id: 'a', status: ProjectStatus.active),
      (id: 'c', status: ProjectStatus.completed),
      (id: 'x', status: ProjectStatus.archived),
      (id: 'b', status: ProjectStatus.active),
    ];
    List<String> ids({String? currentId, bool includeCompleted = false}) => pickableProjects(
          projects,
          idOf: (project) => project.id,
          statusOf: (project) => project.status,
          currentId: currentId,
          includeCompleted: includeCompleted,
        ).map((project) => project.id).toList();

    test('offers active projects in order', () => expect(ids(), ['a', 'b']));
    test('keeps the current project even when finished', () => expect(ids(currentId: 'x'), ['a', 'x', 'b']));
    test('can include completed projects', () => expect(ids(includeCompleted: true), ['a', 'c', 'b']));
  });

  test('keepFieldValues drops readings of fields the new project lacks', () {
    expect(keepFieldValues({'odometer': 1, 'floor': 2}, ['odometer', 'stage']), {'odometer': 1});
    expect(keepFieldValues({'odometer': 1}, const []), isEmpty);
  });
}
