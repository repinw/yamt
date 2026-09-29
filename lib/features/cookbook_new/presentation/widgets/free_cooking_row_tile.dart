import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One ingredient row: a square that is filled when the Vorrat holds the
/// food, the amount in bold, the food, and how much the Vorrat has left.
class FreeCookingRowTile extends StatelessWidget {
  /// Creates the tile for [row].
  const new({required this.row, this.isPending = false, super.key});

  /// The ingredient row.
  final FreeCookingRow row;

  /// Whether speech recognition is still writing the row; it shows no stock.
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final amount = _amountLabel(l10n, row.requirement);
    final stock = row.stockAmount;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppGraphit.buttonHeight),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            SizedBox.square(
              dimension: AppGraphit.stockSquare,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: row.isInStock ? colors.ink : Colors.transparent,
                  border: row.isInStock
                      ? null
                      : Border.all(
                          color: colors.low,
                          width: AppFoodLabel.chipOutline,
                        ),
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (amount != null)
                      TextSpan(
                        text: '$amount ',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    TextSpan(text: row.foodName),
                  ],
                ),
                style: textTheme.bodyLarge?.copyWith(color: colors.ink),
              ),
            ),
            if (!isPending)
              Text(
                stock == null
                    ? l10n.freeCookingMissing
                    : l10n.freeCookingStockLeft(
                        _stockLabel(l10n, stock.amount, stock.unit),
                      ),
                style: textTheme.labelMedium?.copyWith(
                  color: stock == null ? colors.low : colors.muted,
                  fontWeight: stock == null ? FontWeight.w700 : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String? _amountLabel(
  AppLocalizations l10n,
  TemplateIngredientRequirement? requirement,
) {
  if (requirement == null) {
    return null;
  }
  final unit = switch (requirement.unit) {
    TemplateIngredientUnit.gram => l10n.inventoryUnitGram,
    TemplateIngredientUnit.milliliter => l10n.inventoryUnitMilliliter,
    TemplateIngredientUnit.piece => requirement.countMeasureLabel,
  };
  return unit == null
      ? '${requirement.amount}'
      : l10n.freeCookingAmountWithUnit(requirement.amount, unit);
}

String _stockLabel(
  AppLocalizations l10n,
  int amount,
  InventoryAmountUnit unit,
) {
  return switch (unit) {
    InventoryAmountUnit.gram => l10n.freeCookingAmountWithUnit(
      amount,
      l10n.inventoryUnitGram,
    ),
    InventoryAmountUnit.milliliter => l10n.freeCookingAmountWithUnit(
      amount,
      l10n.inventoryUnitMilliliter,
    ),
    InventoryAmountUnit.piece => l10n.freeCookingPieces(amount),
  };
}
