import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/budgets_repository.dart';

void main() {
  late AppDatabase db;
  late BudgetsRepository budgets;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    budgets = BudgetsRepository(db);
  });

  tearDown(() => db.close());

  test('a saved budget is listed and saving the same id updates it', () async {
    await budgets.save(id: 'overall', period: 'monthly', amountMinor: 3000000);
    await budgets.save(id: 'overall', period: 'monthly', amountMinor: 4000000);
    await budgets.save(categoryId: 'food', period: 'weekly', amountMinor: 500000);

    final listed = await budgets.watchAll().first;
    expect(listed, hasLength(2));
    expect(listed.firstWhere((budget) => budget.id == 'overall').amountMinor, 4000000);
    expect(listed.firstWhere((budget) => budget.id != 'overall').categoryId, 'food');
  });

  test('a deleted budget drops out until it is restored', () async {
    await budgets.save(id: 'overall', period: 'monthly', amountMinor: 3000000);

    await budgets.delete('overall');
    expect(await budgets.watchAll().first, isEmpty);

    await budgets.restore('overall');
    expect((await budgets.watchAll().first).single.amountMinor, 3000000);
  });
}
