import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/group_net.dart';

void main() {
  test('group nets split into owed-to-me and I-owe totals', () {
    expect(groupNetTotals([1380, -600, 0, 20]), (owedToMe: 1400, iOwe: 600));
    expect(groupNetTotals(const []), (owedToMe: 0, iOwe: 0));
  });
}
