import 'package:yamt/features/inventory/domain/product_missing_values.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_missing_values_hint.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_missing_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Line above the save button that lists what is still missing, such as
/// "Still missing: Name, Salt", or null when nothing is.
///
/// Package size and nutrition values read as in every missing-values hint
/// ([productMissingValuesText]); only the name and the barcode are the
/// editor's own.
String? manualProductMissingHint(
  AppLocalizations l10n,
  List<ManualProductMissingField> missing,
) {
  if (missing.isEmpty) {
    return null;
  }
  final values = [for (final field in missing) ?_productValue(field)];
  final labels = [
    if (missing.contains(ManualProductMissingField.name))
      l10n.inventoryReceiptReviewFieldName,
    if (missing.contains(ManualProductMissingField.barcode))
      l10n.productEditorMissingBarcode,
    if (values.isNotEmpty) productMissingValuesText(l10n, values),
  ];
  return l10n.productEditorMissing(labels.join(', '));
}

ProductMissingValue? _productValue(ManualProductMissingField field) {
  return switch (field) {
    ManualProductMissingField.name || ManualProductMissingField.barcode => null,
    ManualProductMissingField.packageSize => ProductMissingValue.packageSize,
    ManualProductMissingField.energy => ProductMissingValue.energy,
    ManualProductMissingField.fat => ProductMissingValue.fat,
    ManualProductMissingField.saturatedFat => ProductMissingValue.saturatedFat,
    ManualProductMissingField.carbs => ProductMissingValue.carbs,
    ManualProductMissingField.sugar => ProductMissingValue.sugar,
    ManualProductMissingField.protein => ProductMissingValue.protein,
    ManualProductMissingField.salt => ProductMissingValue.salt,
  };
}
