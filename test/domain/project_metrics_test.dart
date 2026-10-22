import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/projects/project_fields.dart';
import 'package:hisab/domain/projects/project_metrics.dart';
import 'package:hisab/domain/projects/project_templates.dart';

MetricEntry spend(int amount, DateTime at, {Map<String, FieldReading> values = const {}, String kind = 'expense'}) =>
    MetricEntry(kind: kind, amountMinor: amount, occurredAt: at, values: values);

FieldReading number(double value) => FieldReading(number: value);
FieldReading option(String value) => FieldReading(text: value);

void main() {
  final vehicle = templateByKey('vehicle')!;
  final construction = templateByKey('construction')!;

  group('distanceCost', () {
    test('costs from the first reading to the last, leaving out the first fill', () {
      final entries = [
        spend(200000, DateTime(2026, 10, 1), values: {odometerFieldKey: number(10000), litresFieldKey: number(20)}),
        spend(300000, DateTime(2026, 10, 5)),
        spend(200000, DateTime(2026, 10, 10), values: {odometerFieldKey: number(11000), litresFieldKey: number(20)}),
        spend(50000, DateTime(2026, 10, 12)),
      ];
      final cost = distanceCost(entries)!;
      expect(cost.distance, 1000);
      expect(cost.costMinor, 500000);
      expect(cost.perKmMinor, 500);
    });

    test('needs two readings that span a distance', () {
      expect(distanceCost([spend(100, DateTime(2026, 10, 1), values: {odometerFieldKey: number(10)})]), isNull);
      expect(
        distanceCost([
          spend(100, DateTime(2026, 10, 1), values: {odometerFieldKey: number(10)}),
          spend(100, DateTime(2026, 10, 2), values: {odometerFieldKey: number(10)}),
        ]),
        isNull,
      );
    });

    test('orders readings by the odometer, not by entry order', () {
      final cost = distanceCost([
        spend(100, DateTime(2026, 10, 3), values: {odometerFieldKey: number(1500)}),
        spend(100, DateTime(2026, 10, 1), values: {odometerFieldKey: number(1000)}),
      ])!;
      expect(cost.distance, 500);
      expect(cost.costMinor, 100);
    });

    test('ignores income such as a resale', () {
      final cost = distanceCost([
        spend(100, DateTime(2026, 10, 1), values: {odometerFieldKey: number(0)}),
        spend(9999, DateTime(2026, 10, 2), kind: 'income'),
        spend(100, DateTime(2026, 10, 3), values: {odometerFieldKey: number(100)}),
      ])!;
      expect(cost.costMinor, 100);
    });
  });

  test('fuelSummary adds litres and prices them over the fills that recorded litres', () {
    final fuel = fuelSummary([
      spend(200000, DateTime(2026, 10, 1), values: {litresFieldKey: number(20)}),
      spend(105000, DateTime(2026, 10, 9), values: {litresFieldKey: number(10)}),
      spend(300000, DateTime(2026, 10, 5)),
    ])!;
    expect(fuel.litres, 30);
    expect(fuel.costMinor, 305000);
    expect(fuel.perLitreMinor, closeTo(10166.67, 0.01));
    expect(fuelSummary([spend(100, DateTime(2026, 10, 1))]), isNull);
  });

  test('choiceBreakdown follows the option order and keeps unknown and unassigned spend apart', () {
    final stage = construction.fields.firstWhere((field) => field.key == 'stage');
    final breakdown = choiceBreakdown(stage, [
      spend(500, DateTime(2026, 10, 2), values: {'stage': option('plaster')}),
      spend(300, DateTime(2026, 10, 1), values: {'stage': option('foundation')}),
      spend(200, DateTime(2026, 10, 3), values: {'stage': option('foundation')}),
      spend(70, DateTime(2026, 10, 3), values: {'stage': option('garden')}),
      spend(40, DateTime(2026, 10, 4)),
    ]);
    expect(breakdown.byOption.keys, ['foundation', 'plaster', 'garden']);
    expect(breakdown.byOption['foundation'], 500);
    expect(breakdown.unassignedMinor, 40);
  });

  group('projectMetrics', () {
    test('cost per sq ft uses the project-level area', () {
      final metrics = projectMetrics(fields: construction.fields, projectValues: {builtUpAreaFieldKey: 1200}, entries: [spend(240000000, DateTime(2026, 10, 1))], spentMinor: 240000000);
      expect(metrics.perAreaMinor, 200000);
      expect(metrics.area, 1200);
      expect(metrics.distance, isNull);
      expect(metrics.breakdowns, isEmpty, reason: 'no entry picked a stage');
    });

    test('per-traveller cost and nothing without the values to compute from', () {
      final trip = templateByKey('trip')!;
      expect(projectMetrics(fields: trip.fields, projectValues: {travellersFieldKey: 4}, entries: const [], spentMinor: 4000).perTravellerMinor, 1000);
      expect(projectMetrics(fields: trip.fields, projectValues: const {}, entries: const [], spentMinor: 4000).isEmpty, isTrue);
    });

    test('only computes metrics for fields the project has', () {
      final entries = [
        spend(100, DateTime(2026, 10, 1), values: {odometerFieldKey: number(0), litresFieldKey: number(1)}),
        spend(100, DateTime(2026, 10, 2), values: {odometerFieldKey: number(10), litresFieldKey: number(1)}),
      ];
      expect(projectMetrics(fields: vehicle.fields, projectValues: const {}, entries: entries, spentMinor: 200).distance?.distance, 10);
      expect(projectMetrics(fields: const [], projectValues: const {}, entries: entries, spentMinor: 200).isEmpty, isTrue);
    });
  });

  test('choices round-trip through JSON and typed lists', () {
    expect(decodeChoices(encodeChoices([' a ', '', 'b'])), ['a', 'b']);
    expect(decodeChoices('not json'), isEmpty);
    expect(decodeChoices('{"a":1}'), isEmpty);
    expect(parseChoiceList('Hall, Kitchen ,,Hall\nRoof'), ['Hall', 'Kitchen', 'Roof']);
  });

  test('FieldReading.isEmpty treats blank text as empty', () {
    expect(const FieldReading(text: '  ').isEmpty, isTrue);
    expect(const FieldReading(number: 0).isEmpty, isFalse);
  });

  test('parseFieldNumber reads decimals with a point or a comma', () {
    expect(parseFieldNumber(' 12.5 '), 12.5);
    expect(parseFieldNumber('12,5'), 12.5);
    expect(parseFieldNumber(''), isNull);
    expect(parseFieldNumber('abc'), isNull);
  });

  test('validateNewField needs a name, and options for choice and unit fields', () {
    expect(validateNewField(label: ' ', type: ProjectFieldType.text, choices: const []), NewFieldError.missingName);
    expect(validateNewField(label: 'Floor', type: ProjectFieldType.choice, choices: const []), NewFieldError.missingOptions);
    expect(validateNewField(label: 'Floor', type: ProjectFieldType.choice, choices: const ['Ground']), isNull);
    expect(validateNewField(label: 'Tip', type: ProjectFieldType.number, choices: const []), isNull);
  });
}
