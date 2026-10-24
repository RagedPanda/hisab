import 'package:flutter/material.dart';

import '../../domain/reminders/document_presets.dart';
import '../../l10n/l10n.dart';

/// Localised name of a document preset; also the title it prefills.
String documentPresetName(AppLocalizations l10n, DocumentPreset preset) => switch (preset.key) {
  'vehicle_insurance' => l10n.documentPresetVehicleInsurance,
  'puc' => l10n.documentPresetPuc,
  'rc_renewal' => l10n.documentPresetRcRenewal,
  'driving_licence' => l10n.documentPresetDrivingLicence,
  'passport' => l10n.documentPresetPassport,
  'health_insurance' => l10n.documentPresetHealthInsurance,
  'life_insurance' => l10n.documentPresetLifeInsurance,
  'warranty' => l10n.documentPresetWarranty,
  'amc' => l10n.documentPresetAmc,
  'fd_maturity' => l10n.documentPresetFdMaturity,
  'property_tax' => l10n.documentPresetPropertyTax,
  'rent_agreement' => l10n.documentPresetRentAgreement,
  _ => preset.key,
};

/// Icon for a document preset.
IconData documentPresetIcon(DocumentPreset preset) => switch (preset.icon) {
  'directions_car' => Icons.directions_car_outlined,
  'eco' => Icons.eco_outlined,
  'badge' => Icons.badge_outlined,
  'credit_card' => Icons.credit_card,
  'flight' => Icons.flight_outlined,
  'health_and_safety' => Icons.health_and_safety_outlined,
  'shield' => Icons.shield_outlined,
  'verified' => Icons.verified_outlined,
  'build' => Icons.build_outlined,
  'savings' => Icons.savings_outlined,
  'home' => Icons.home_outlined,
  'description' => Icons.description_outlined,
  _ => Icons.event_note_outlined,
};
