import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/split/split_calculator.dart';
import 'package:hisab/features/split/split_editor.dart';

Member member(String id, {double weight = 1}) =>
    Member(updatedAt: DateTime(2026, 10, 22), id: id, groupId: 'g1', name: id, isMe: false, weight: weight);

void main() {
  final members = [member('asha', weight: 2), member('ravi'), member('meena', weight: 0)];

  test('shares start from each member weight, treating a zero weight as one', () {
    final inputs = defaultSplitInputs(members, SplitMethod.shares);
    expect(inputs.map((input) => input.weight), [2, 1, 1]);
    final outcome = computeSplit(totalMinor: 4000, method: SplitMethod.shares, inputs: inputs);
    expect(outcome.shares.map((share) => share.amountMinor), [2000, 1000, 1000]);
  });

  test('percent splits evenly and equal ignores weights', () {
    expect(defaultSplitInputs(members, SplitMethod.percent).map((input) => input.weight), everyElement(closeTo(100 / 3, 0.001)));
    expect(defaultSplitInputs(members, SplitMethod.equal).every((input) => input.included && input.weight == 0), isTrue);
  });
}
