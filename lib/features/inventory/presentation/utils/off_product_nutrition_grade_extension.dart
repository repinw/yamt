import 'package:yamt/features/inventory/data/off_product_search_result_quality.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Localized labels for OFF nutrition grades.
extension OffProductNutritionGradeL10n on OffProductNutritionGrade {
  /// Returns localized user-facing label.
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      OffProductNutritionGrade.missing =>
        l10n.inventoryManualAddNutritionMissing,
      OffProductNutritionGrade.missingCalories =>
        l10n.inventoryManualAddNutritionMissingCalories,
      OffProductNutritionGrade.incomplete =>
        l10n.inventoryManualAddNutritionIncomplete,
      OffProductNutritionGrade.complete =>
        l10n.inventoryManualAddNutritionComplete,
      OffProductNutritionGrade.verified =>
        l10n.inventoryManualAddNutritionVerified,
    };
  }
}
