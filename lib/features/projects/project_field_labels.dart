import '../../data/db/database.dart';
import '../../domain/projects/project_templates.dart';
import '../../l10n/l10n.dart';

/// Label of a template field by key; null for custom fields.
String? templateFieldLabel(AppLocalizations l10n, String key) => switch (key) {
      'odometer' => l10n.fieldOdometer,
      'litres' => l10n.fieldLitres,
      'built_up_area' => l10n.fieldBuiltUpArea,
      'stage' => l10n.fieldStage,
      'quantity' => l10n.fieldQuantity,
      'room' => l10n.fieldRoom,
      'travellers' => l10n.fieldTravellers,
      'event' => l10n.fieldEvent,
      'vendor' => l10n.fieldVendor,
      _ => null,
    };

/// What the user sees for a stored field: the translated template label, or
/// the label they typed for a custom field.
String projectFieldLabel(AppLocalizations l10n, ProjectField field) => templateFieldLabel(l10n, field.key) ?? (field.label.isEmpty ? field.key : field.label);

/// A choice option: template options are translated, custom ones shown as typed.
String choiceLabel(AppLocalizations l10n, String option) => switch (option) {
      'foundation' => l10n.stageFoundation,
      'plinth' => l10n.stagePlinth,
      'structure' => l10n.stageStructure,
      'brickwork' => l10n.stageBrickwork,
      'roof_slab' => l10n.stageRoofSlab,
      'plaster' => l10n.stagePlaster,
      'electrical_plumbing' => l10n.stageElectricalPlumbing,
      'flooring' => l10n.stageFlooring,
      'doors_windows' => l10n.stageDoorsWindows,
      'painting' => l10n.stagePainting,
      'finishing' => l10n.stageFinishing,
      'kitchen' => l10n.roomKitchen,
      'bathroom' => l10n.roomBathroom,
      'bedroom' => l10n.roomBedroom,
      'living_room' => l10n.roomLivingRoom,
      'dining' => l10n.roomDining,
      'balcony' => l10n.roomBalcony,
      'whole_house' => l10n.roomWholeHouse,
      'roka' => l10n.eventRoka,
      'engagement' => l10n.eventEngagement,
      'haldi' => l10n.eventHaldi,
      'mehndi' => l10n.eventMehndi,
      'sangeet' => l10n.eventSangeet,
      'wedding' => l10n.eventWedding,
      'reception' => l10n.eventReception,
      _ => option,
    };

String fieldTypeLabel(AppLocalizations l10n, ProjectFieldType type) => switch (type) {
      ProjectFieldType.number => l10n.fieldTypeNumber,
      ProjectFieldType.text => l10n.fieldTypeText,
      ProjectFieldType.date => l10n.fieldTypeDate,
      ProjectFieldType.choice => l10n.fieldTypeChoice,
      ProjectFieldType.unit => l10n.fieldTypeUnit,
    };
