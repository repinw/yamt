import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_amount_labels.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_stock_lead.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One ingredient of the recipe page: the photo of the Vorrat item that
/// supplies it, or an empty square when the Vorrat lacks it, the amount, the
/// food, and how much the Vorrat has left. An ignored ingredient is struck
/// through. A tap picks another Vorrat item when [onTap] is set.
class RecipeIngredientTile extends StatelessWidget {
  /// Creates the tile for [line].
  const new({required this.line, this.onTap, super.key});

  /// Key of the tile for the ingredient at [index].
  static ValueKey<String> tileKey(int index) =>
      ValueKey<String>('recipe-ingredient-$index');

  /// The ingredient.
  final RecipeIngredientLine line;

  /// Opens the Vorrat picker.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final row = line.row;
    final amount = ingredientAmountLabel(l10n, row.requirement);
    final stock = row.stockAmount;
    final item = row.stockItem;
    final textStyle = textTheme.bodyLarge?.copyWith(
      color: line.isIgnored ? colors.muted : colors.ink,
      decoration: line.isIgnored ? TextDecoration.lineThrough : null,
    );

    return AppInkWell(
      onTap: line.isIgnored ? null : onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.rule)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppGraphit.buttonHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                RecipeStockLead(item: item, isIgnored: line.isIgnored),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (amount != null)
                          TextSpan(
                            text: '$amount ',
                            style: textStyle?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        TextSpan(text: row.foodName),
                      ],
                    ),
                    style: textStyle,
                  ),
                ),
                if (!line.isIgnored)
                  Text(
                    stock == null
                        ? l10n.freeCookingMissing
                        : l10n.freeCookingStockLeft(
                            ingredientStockLabel(
                              l10n,
                              stock.amount,
                              stock.unit,
                            ),
                          ),
                    style: textTheme.labelMedium?.copyWith(
                      color: stock == null ? colors.low : colors.muted,
                      fontWeight: stock == null ? FontWeight.w700 : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
