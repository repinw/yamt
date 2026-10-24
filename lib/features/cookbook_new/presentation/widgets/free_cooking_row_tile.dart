import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'ingredient_amount_labels.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_stock_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One ingredient row: a square that is filled when the Vorrat holds the
/// food, the amount in bold, the food, and how much the Vorrat has left.
/// When the Vorrat has items for the food, the name of the one that supplies
/// it, or "Wählen", stands under the food and a tap picks another one.
class FreeCookingRowTile extends StatelessWidget {
  /// Creates the tile for [row].
  const new({required this.row, this.isPending = false, this.onTap, super.key});

  /// The ingredient row.
  final FreeCookingRow row;

  /// Whether speech recognition is still writing the row; it shows no stock.
  final bool isPending;

  /// Opens the Vorrat picker.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final amount = ingredientAmountLabel(l10n, row.requirement);
    final stock = row.stockAmount;
    final pickStyle = textTheme.labelMedium?.copyWith(color: colors.muted);

    return AppInkWell(
      onTap: onTap,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
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
                      if (!isPending && row.candidates.isNotEmpty)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                row.stockItem?.name ??
                                    l10n.freeCookingPickStock,
                                overflow: TextOverflow.ellipsis,
                                style: pickStyle,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: pickStyle?.fontSize,
                              color: colors.muted,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (!isPending) IngredientStockText(stock: stock),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
