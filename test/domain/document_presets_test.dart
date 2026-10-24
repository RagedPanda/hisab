import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/reminders/document_presets.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/reminders/reminder_schedule.dart';

void main() {
  group('documentPresets', () {
    test('covers every document and renewal the roadmap lists', () {
      expect(documentPresets.map((preset) => preset.key), [
        'vehicle_insurance',
        'puc',
        'rc_renewal',
        'driving_licence',
        'passport',
        'health_insurance',
        'life_insurance',
        'warranty',
        'amc',
        'fd_maturity',
        'property_tax',
        'rent_agreement',
      ]);
    });

    test('keys are unique', () {
      final keys = documentPresets.map((preset) => preset.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('lead times are already in stored form and always alert on the day', () {
      for (final preset in documentPresets) {
        final leads = preset.remindDaysBefore;
        expect(formatRemindDaysBefore(leads), leads.join(','), reason: preset.key);
        expect(leads.last, 0, reason: preset.key);
        expect(leads.length, greaterThan(1), reason: preset.key);
      }
    });

    test('every preset offers at least one repeat and no repeat twice', () {
      for (final preset in documentPresets) {
        expect(preset.repeatChoices, isNotEmpty, reason: preset.key);
        expect(preset.repeatChoices.toSet().length, preset.repeatChoices.length, reason: preset.key);
      }
    });

    test('PUC is yearly by default and six-monthly for older vehicles', () {
      final puc = documentPresetByKey('puc')!;
      expect(puc.defaultRepeat, ReminderRepeat.yearly);
      expect(puc.repeatChoices, contains(ReminderRepeat.halfYearly));
    });

    test('vehicle documents suggest a vehicle project, personal ones do not', () {
      for (final key in ['vehicle_insurance', 'puc', 'rc_renewal']) {
        expect(documentPresetByKey(key)!.projectTemplateKey, 'vehicle', reason: key);
      }
      for (final key in ['passport', 'driving_licence', 'health_insurance']) {
        expect(documentPresetByKey(key)!.projectTemplateKey, isNull, reason: key);
      }
    });

    test('one-off presets default to no repeat', () {
      for (final key in ['warranty', 'fd_maturity']) {
        expect(documentPresetByKey(key)!.defaultRepeat, ReminderRepeat.once, reason: key);
      }
    });

    test('long-lived documents renew on their real cycle', () {
      expect(documentPresetByKey('rent_agreement')!.defaultRepeat, ReminderRepeat.everyElevenMonths);
      expect(documentPresetByKey('passport')!.defaultRepeat, ReminderRepeat.everyTenYears);
      expect(documentPresetByKey('rc_renewal')!.defaultRepeat, ReminderRepeat.everyFiveYears);
    });

    test('premiums are insurance and taxes are bills, so paying them adds an expense', () {
      for (final key in ['vehicle_insurance', 'health_insurance', 'life_insurance', 'property_tax', 'amc']) {
        final preset = documentPresetByKey(key)!;
        expect(preset.kind.isMoney, isTrue, reason: key);
        expect(preset.tracksAmount, isTrue, reason: key);
      }
      expect(documentPresetByKey('passport')!.kind, ReminderKind.document);
    });

    test('unknown keys find nothing', () {
      expect(documentPresetByKey('nope'), isNull);
      expect(documentPresetByKey(null), isNull);
    });
  });

  group('renewal repeats on the shared schedule', () {
    test('every 6 months, 11 months, 5 and 10 years', () {
      expect(nextDueDate(DateTime(2026, 11, 10), ReminderRepeat.halfYearly), DateTime(2027, 5, 10));
      expect(nextDueDate(DateTime(2026, 1, 5), ReminderRepeat.everyElevenMonths), DateTime(2026, 12, 5));
      expect(nextDueDate(DateTime(2026, 3, 15), ReminderRepeat.everyFiveYears), DateTime(2031, 3, 15));
      expect(nextDueDate(DateTime(2026, 3, 15), ReminderRepeat.everyTenYears), DateTime(2036, 3, 15));
    });

    test('a renewal on 31 Aug keeps month ends', () {
      expect(nextDueDate(DateTime(2026, 8, 31), ReminderRepeat.halfYearly, anchorDay: 31), DateTime(2027, 2, 28));
      expect(nextDueDate(DateTime(2028, 2, 29), ReminderRepeat.everyFiveYears, anchorDay: 29), DateTime(2033, 2, 28));
    });

    test('stored keys round-trip', () {
      for (final repeat in ReminderRepeat.values) {
        expect(ReminderRepeat.fromKey(repeat.key), repeat);
      }
    });
  });

  group('draftFromPreset', () {
    test('prefills kind, title, repeat, lead times and project', () {
      final today = DateTime(2026, 10, 22);
      final draft = draftFromPreset(documentPresetByKey('puc')!, title: 'PUC', today: today, projectId: 'scotty');
      expect(draft.kind, ReminderKind.document);
      expect(draft.title, 'PUC');
      expect(draft.dueAt, today);
      expect(draft.repeat, ReminderRepeat.yearly);
      expect(draft.remindDaysBefore, [15, 7, 1, 0]);
      expect(draft.presetKey, 'puc');
      expect(draft.projectId, 'scotty');
      expect(draft.documentNumber, '');
      expect(draft.id, isNull);
    });
  });

  group('editor options', () {
    const everyday = [ReminderRepeat.once, ReminderRepeat.monthly, ReminderRepeat.quarterly, ReminderRepeat.yearly];

    test('repeat options add the preset cycles to the everyday ones, in enum order', () {
      final options = repeatOptionsFor(common: everyday, preset: documentPresetByKey('rent_agreement'));
      expect(options, [...everyday, ReminderRepeat.everyElevenMonths]);
      expect(repeatOptionsFor(common: everyday, preset: documentPresetByKey('puc')),
          [ReminderRepeat.once, ReminderRepeat.monthly, ReminderRepeat.quarterly, ReminderRepeat.halfYearly, ReminderRepeat.yearly]);
    });

    test('without a preset only the everyday repeats show', () {
      expect(repeatOptionsFor(common: everyday), everyday);
    });

    test('an edited reminder keeps its unusual repeat on offer', () {
      expect(repeatOptionsFor(common: everyday, current: ReminderRepeat.everyTenYears), contains(ReminderRepeat.everyTenYears));
    });

    test('days-before options merge everyday, preset and current lead times, nearest first', () {
      expect(remindDaysOptionsFor(common: const [0, 1, 3, 7], preset: documentPresetByKey('puc'), current: const [45]), [0, 1, 3, 7, 15, 45]);
    });
  });

  group('suggestedPresetProjectId', () {
    final projects = [(id: 'scotty', template: 'vehicle'), (id: 'goa', template: 'trip')];
    String idOf(({String id, String? template}) project) => project.id;
    String? templateOf(({String id, String? template}) project) => project.template;

    test('links a vehicle document to the only vehicle project', () {
      expect(suggestedPresetProjectId(documentPresetByKey('puc')!, projects, idOf: idOf, templateKeyOf: templateOf), 'scotty');
    });

    test('suggests nothing when several vehicle projects exist', () {
      final twoVehicles = [...projects, (id: 'car', template: 'vehicle')];
      expect(suggestedPresetProjectId(documentPresetByKey('puc')!, twoVehicles, idOf: idOf, templateKeyOf: templateOf), isNull);
    });

    test('suggests nothing for presets without a project template', () {
      expect(suggestedPresetProjectId(documentPresetByKey('passport')!, projects, idOf: idOf, templateKeyOf: templateOf), isNull);
    });

    test('suggests nothing without a matching project', () {
      expect(suggestedPresetProjectId(documentPresetByKey('rc_renewal')!, [projects.last], idOf: idOf, templateKeyOf: templateOf), isNull);
    });
  });
}
