import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/product_missing_values.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_text_link.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Quiet line that names what a product lacks, such as "Missing: Package
/// size, Salt – add". Tapping it opens the editor. It never blocks.
class EatMissingValuesHint extends StatelessWidget {
  /// Creates the line for [missing], which must not be empty.
  const new({required this.missing, required this.onPressed, super.key});

  /// Key of the line's button.
  static const buttonKey = Key('eat_missing_values_hint');

  /// The values the product lacks.
  final List<ProductMissingValue> missing;

  /// Opens the editor.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EatTextLink(
      buttonKey: buttonKey,
      label: l10n.productMissingValuesHint(
        productMissingValuesText(l10n, missing),
      ),
      onPressed: onPressed,
      isMuted: true,
    );
  }
}

/// The names of [missing], joined. More than two nutrition values read as
/// one count, so the line stays short.
String productMissingValuesText(
  AppLocalizations l10n,
  List<ProductMissingValue> missing,
) {
  final nutrients = missing.where(_isNutrient).toList();
  return [
    for (final value in missing)
      if (!_isNutrient(value)) _label(l10n, value),
    if (nutrients.length > 2)
      l10n.productEditorMissingValues(nutrients.length)
    else
      for (final value in nutrients) _label(l10n, value),
  ].join(', ');
}

bool _isNutrient(ProductMissingValue value) {
  return value != ProductMissingValue.packageSize &&
      value != ProductMissingValue.pieceWeight;
}

String _label(AppLocalizations l10n, ProductMissingValue value) {
  return switch (value) {
    ProductMissingValue.packageSize => l10n.inventoryManualAddPackageSizeLabel,
    ProductMissingValue.pieceWeight => l10n.productPieceWeightLabel,
    ProductMissingValue.energy => l10n.caloriesNutritionTableEnergy,
    ProductMissingValue.fat => l10n.caloriesFatLabel,
    ProductMissingValue.saturatedFat => l10n.caloriesNutritionTableSaturatedFat,
    ProductMissingValue.carbs => l10n.caloriesCarbsLabel,
    ProductMissingValue.sugar => l10n.caloriesNutritionTableSugar,
    ProductMissingValue.protein => l10n.caloriesProteinLabel,
    ProductMissingValue.salt => l10n.caloriesNutritionTableSalt,
  };
}
