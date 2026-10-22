import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/app_icons.dart';
import 'package:hisab/domain/categories/category_catalog.dart';
import 'package:hisab/domain/categories/category_packs.dart';
import 'package:hisab/domain/projects/project_templates.dart';

void main() {
  group('category packs', () {
    test('pack keys are unique and every pack has a root', () {
      final keys = categoryPacks.map((pack) => pack.key).toList();
      expect(keys.toSet().length, keys.length);
      expect(categoryPacks.every((pack) => pack.roots.isNotEmpty), isTrue);
    });

    test('a seed key means the same category everywhere it appears', () {
      final catalog = {for (final seed in flattenCatalog()) seed.key: seed};
      final seen = <String, CategorySeed>{};
      for (final pack in categoryPacks) {
        for (final seed in flattenCatalog(pack.roots)) {
          final reference = catalog[seed.key] ?? seen[seed.key];
          if (reference != null) {
            expect(seed.name, reference.name, reason: seed.key);
            expect(seed.kind, reference.kind, reason: seed.key);
          }
          seen[seed.key] = seed;
        }
      }
    });

    test('no seed appears twice inside one pack', () {
      for (final pack in categoryPacks) {
        final keys = flattenCatalog(pack.roots).map((seed) => seed.key).toList();
        expect(keys.toSet().length, keys.length, reason: pack.key);
      }
    });

    test('vehicle pack reuses the catalog fuel and service categories', () {
      final keys = flattenCatalog(vehiclePack.roots).map((seed) => seed.key).toSet();
      expect(keys, containsAll(['fuel', 'vehicle_service', 'parking_tolls', 'ev_charging']));
      expect(packOnlySeeds().map((seed) => seed.key), isNot(contains('fuel')));
    });

    test('planPack flags what the user already has, parents first', () {
      final plan = planPack(tripPack, {'travel', 'flights', 'hotels'});
      expect(plan.first.seed.key, 'travel');
      expect(plan.first.parentKey, isNull);
      expect(plan.first.exists, isTrue);
      expect(plan.where((item) => item.seed.key == 'flights').single.exists, isTrue);
      final sightseeing = plan.where((item) => item.seed.key == 'trip_sightseeing').single;
      expect(sightseeing.exists, isFalse);
      expect(sightseeing.parentKey, 'travel');
    });

    test('missingPackItems is empty once everything exists', () {
      final everything = flattenCatalog(weddingPack.roots).map((seed) => seed.key).toSet();
      expect(missingPackItems(weddingPack, everything), isEmpty);
      expect(missingPackItems(weddingPack, const {}).length, everything.length);
    });

    test('renovation shares construction seeds instead of copying them', () {
      final renovationKeys = flattenCatalog(renovationPack.roots).map((seed) => seed.key).toSet();
      final constructionKeys = flattenCatalog(constructionPack.roots).map((seed) => seed.key).toSet();
      expect(renovationKeys.intersection(constructionKeys), containsAll(['build_cement', 'build_contractor', 'build_waste']));
      expect(packOnlySeeds().where((seed) => seed.key == 'build_cement').length, 1);
    });

    test('isPackAdded looks for the pack key on any category', () {
      expect(isPackAdded('vehicle', [null, 'trip', 'vehicle']), isTrue);
      expect(isPackAdded('vehicle', [null, 'trip']), isFalse);
    });
  });

  group('project templates', () {
    test('the roadmap packs are all registered and every pack icon exists', () {
      expect(categoryPacks.map((pack) => pack.key), containsAll(['baby', 'pet', 'farming', 'shop', 'medical', 'education', 'festival', 'event']));
      for (final pack in categoryPacks) {
        expect(appIcons, contains(pack.icon), reason: pack.key);
        for (final seed in flattenCatalog(pack.roots)) {
          expect(appIcons, contains(seed.icon), reason: '${pack.key}/${seed.key}');
        }
      }
    });

    test('packs nest under reused roots only, never under a catalog child', () {
      final catalogChildKeys = {for (final root in categoryCatalog) for (final child in root.children) child.key};
      for (final pack in categoryPacks) {
        for (final root in pack.roots.where((root) => root.children.isNotEmpty)) {
          expect(catalogChildKeys, isNot(contains(root.key)), reason: '${pack.key}/${root.key}');
        }
      }
    });

    test('the five R1 templates each point at an existing pack', () {
      expect(projectTemplates.map((template) => template.key), ['vehicle', 'construction', 'renovation', 'trip', 'wedding']);
      for (final template in projectTemplates) {
        expect(packByKey(template.packKey), isNotNull, reason: template.key);
        expect(template.fields, isNotEmpty, reason: template.key);
      }
    });

    test('choice fields carry their options and field keys are unique per template', () {
      for (final template in projectTemplates) {
        final keys = template.fields.map((field) => field.key).toList();
        expect(keys.toSet().length, keys.length, reason: template.key);
        for (final field in template.fields) {
          if (field.type == ProjectFieldType.choice || field.type == ProjectFieldType.unit) {
            expect(field.choices, isNotEmpty, reason: '${template.key}.${field.key}');
          }
        }
      }
    });

    test('templateByKey finds a template and returns null for blank', () {
      expect(templateByKey('vehicle')!.pack, same(vehiclePack));
      expect(templateByKey(null), isNull);
      expect(templateByKey('blank'), isNull);
    });
  });
}
