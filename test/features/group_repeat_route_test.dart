import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/groups/group_detail_screen.dart';

void main() {
  test('+ in an empty group opens a blank expense', () {
    expect(newGroupExpenseRoute('g1', null), '/entry?group=g1');
  });

  test('+ in a group with expenses copies the latest one', () {
    expect(newGroupExpenseRoute('g1', 'e9'), '/entry?group=g1&copy=e9');
  });
}
