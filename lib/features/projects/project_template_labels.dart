import '../../domain/projects/project_templates.dart';
import '../../l10n/l10n.dart';

/// Localised name of a project template.
String templateName(AppLocalizations l10n, ProjectTemplate template) => switch (template.key) {
      'vehicle' => l10n.templateVehicle,
      'construction' => l10n.templateConstruction,
      'renovation' => l10n.templateRenovation,
      'trip' => l10n.templateTrip,
      'wedding' => l10n.templateWedding,
      _ => template.key,
    };

/// One-line description of what a template tracks.
String templateHint(AppLocalizations l10n, ProjectTemplate template) => switch (template.key) {
      'vehicle' => l10n.templateVehicleHint,
      'construction' => l10n.templateConstructionHint,
      'renovation' => l10n.templateRenovationHint,
      'trip' => l10n.templateTripHint,
      'wedding' => l10n.templateWeddingHint,
      _ => '',
    };
