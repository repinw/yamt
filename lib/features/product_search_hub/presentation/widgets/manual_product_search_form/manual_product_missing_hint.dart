import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_missing_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Line above the save button that lists what is still missing, such as
/// "Still missing: Name, Salt", or null when nothing is.
String? manualProductMissingHint(
  AppLocalizations l10n,
  List<ManualProductMissingField> missing,
) {
  if (missing.isEmpty) {
    return null;
  }
  // More than two missing values read as one count, so the line stays
  // short on an empty form.
  final values = missing.where(_isValue).toList();
  final labels = [
    for (final field in missing)
      if (!_isValue(field)) _label(l10n, field),
    if (values.length > 2)
      l10n.productEditorMissingValues(values.length)
    else
      for (final field in values) _label(l10n, field),
  ];
  return l10n.productEditorMissing(labels.join(', '));
}

bool _isValue(ManualProductMissingField field) {
  return switch (field) {
    ManualProductMissingField.name ||
    ManualProductMissingField.packageSize ||
    ManualProductMissingField.barcode => false,
    _ => true,
  };
}

String _label(AppLocalizations l10n, ManualProductMissingField field) {
  return switch (field) {
    ManualProductMissingField.name => l10n.inventoryReceiptReviewFieldName,
    ManualProductMissingField.packageSize =>
      l10n.inventoryManualAddPackageSizeLabel,
    ManualProductMissingField.barcode => l10n.productEditorMissingBarcode,
    ManualProductMissingField.energy => l10n.caloriesNutritionTableEnergy,
    ManualProductMissingField.fat => l10n.caloriesFatLabel,
    ManualProductMissingField.saturatedFat =>
      l10n.caloriesNutritionTableSaturatedFat,
    ManualProductMissingField.carbs => l10n.caloriesCarbsLabel,
    ManualProductMissingField.sugar => l10n.caloriesNutritionTableSugar,
    ManualProductMissingField.protein => l10n.caloriesProteinLabel,
    ManualProductMissingField.salt => l10n.caloriesNutritionTableSalt,
  };
}
