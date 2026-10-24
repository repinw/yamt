import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_amount_labels.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// How much the Vorrat has left of an ingredient's item, such as
/// "noch 200 g", or "fehlt" when no item supplies it.
class IngredientStockText extends StatelessWidget {
  /// Creates the text for [stock].
  const new({required this.stock, super.key});

  /// The amount left, or `null` when no item supplies the ingredient.
  final ({int amount, InventoryAmountUnit unit})? stock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final stock = this.stock;
    return Text(
      stock == null
          ? l10n.freeCookingMissing
          : l10n.freeCookingStockLeft(
              ingredientStockLabel(l10n, stock.amount, stock.unit),
            ),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: stock == null ? colors.low : colors.muted,
        fontWeight: stock == null ? FontWeight.w700 : null,
      ),
    );
  }
}
