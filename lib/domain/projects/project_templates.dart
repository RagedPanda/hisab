/// Project templates: a starting point for a kind of project. Each template
/// names a category pack (added only when the user opts in), an icon and
/// colour, and the default fields its entries can record. Names live in the
/// ARB files keyed by [ProjectTemplate.key]. Pure, no Flutter imports.
library;

import '../categories/category_packs.dart';

/// How a project field's value is entered and stored.
enum ProjectFieldType { number, text, date, choice, unit }

/// Whether a field is filled once for the project or on each entry.
enum ProjectFieldScope { project, entry }

class TemplateField {
  const TemplateField(
    this.key,
    this.type, {
    this.scope = ProjectFieldScope.entry,
    this.unit,
    this.choices = const [],
  });

  /// Stable key, used for labels and for metric maths.
  final String key;
  final ProjectFieldType type;
  final ProjectFieldScope scope;

  /// Fixed unit for number fields (e.g. `km`, `L`, `sq ft`).
  final String? unit;

  /// Option keys for [ProjectFieldType.choice], or unit options for
  /// [ProjectFieldType.unit].
  final List<String> choices;
}

class ProjectTemplate {
  const ProjectTemplate({
    required this.key,
    required this.icon,
    required this.color,
    required this.packKey,
    required this.fields,
  });

  final String key;
  final String icon;

  /// ARGB colour; one of the theme palette (kPaletteColors) so the form shows it selected.
  final int color;
  final String packKey;
  final List<TemplateField> fields;

  CategoryPack get pack => packByKey(packKey)!;
}

const constructionStages = [
  'foundation',
  'plinth',
  'structure',
  'brickwork',
  'roof_slab',
  'plaster',
  'electrical_plumbing',
  'flooring',
  'doors_windows',
  'painting',
  'finishing',
];

const renovationRooms = ['kitchen', 'bathroom', 'bedroom', 'living_room', 'dining', 'balcony', 'whole_house'];

const weddingEvents = ['roka', 'engagement', 'haldi', 'mehndi', 'sangeet', 'wedding', 'reception'];

const constructionQuantityUnits = ['bag', 'kg', 'ton', 'cft', 'sq ft', 'nos', 'truck'];

const List<ProjectTemplate> projectTemplates = [
  ProjectTemplate(key: 'vehicle', icon: 'directions_car', color: 0xFF2196F3, packKey: 'vehicle', fields: [
    TemplateField('odometer', ProjectFieldType.number, unit: 'km'),
    TemplateField('litres', ProjectFieldType.number, unit: 'L'),
  ]),
  ProjectTemplate(key: 'construction', icon: 'construction', color: 0xFF795548, packKey: 'construction', fields: [
    TemplateField('built_up_area', ProjectFieldType.number, scope: ProjectFieldScope.project, unit: 'sq ft'),
    TemplateField('stage', ProjectFieldType.choice, choices: constructionStages),
    TemplateField('quantity', ProjectFieldType.unit, choices: constructionQuantityUnits),
  ]),
  ProjectTemplate(key: 'renovation', icon: 'format_paint', color: 0xFFFF7043, packKey: 'renovation', fields: [
    TemplateField('built_up_area', ProjectFieldType.number, scope: ProjectFieldScope.project, unit: 'sq ft'),
    TemplateField('room', ProjectFieldType.choice, choices: renovationRooms),
  ]),
  ProjectTemplate(key: 'trip', icon: 'luggage', color: 0xFF03A9F4, packKey: 'trip', fields: [
    TemplateField('travellers', ProjectFieldType.number, scope: ProjectFieldScope.project),
  ]),
  ProjectTemplate(key: 'wedding', icon: 'favorite', color: 0xFFE91E63, packKey: 'wedding', fields: [
    TemplateField('event', ProjectFieldType.choice, choices: weddingEvents),
    TemplateField('vendor', ProjectFieldType.text),
  ]),
];

ProjectTemplate? templateByKey(String? key) {
  for (final template in projectTemplates) {
    if (template.key == key) return template;
  }
  return null;
}
