import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_line_states.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_amount_labels.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_stock_text.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One ingredient of the recipe page: the amount and the food, and, while
/// the recipe has a cook run, where the line stands in it: a check and how
/// much its Vorrat food holds, a cart and "im Einkauf", a minus and
/// "weggelassen" (muted) or "zählt nicht mit", or a hollow dot and "offen".
/// The amount is what the run takes when the cook changed it. Without a
/// cook run, [inStock] marks an ingredient that the Vorrat holds with the
/// same check.
class RecipeIngredientTile extends StatelessWidget {
  /// Creates the tile for [line] with its cook session [state].
  const new({required this.line, this.state, this.inStock, super.key});

  /// Key of the tile for the ingredient at [index].
  static ValueKey<String> tileKey(int index) =>
      ValueKey<String>('recipe-ingredient-$index');

  /// The ingredient.
  final RecipeIngredientLine line;

  /// Where the line stands in the cook run; `null` without one, or when the
  /// run took another line at this place.
  final RecipeLineState? state;

  /// Whether the Vorrat holds the ingredient, shown while there is no
  /// [state]: a check, else an empty place for one, so the lines stay
  /// aligned; `null` shows neither.
  final bool? inStock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final row = line.row;
    final amount = ingredientAmountLabel(
      l10n,
      _withOwn(row.requirement, state?.own),
    );
    // A line that does not count is still added, so it is not muted.
    final isIgnored =
        line.isIgnored ||
        switch (state) {
          RecipeLineIgnored(notCounted: false) => true,
          _ => false,
        };
    final textStyle = textTheme.bodyLarge?.copyWith(
      color: isIgnored ? colors.muted : colors.ink,
    );
    final stateStyle = textTheme.labelMedium?.copyWith(
      color: colors.muted,
      fontWeight: FontWeight.w600,
    );

    return DecoratedBox(
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
              if (state case final state?)
                _Lead(state: state)
              else if (inStock case final inStock?)
                SizedBox(
                  width: AppGraphit.rowTile,
                  child: inStock
                      ? Icon(
                          Icons.check_rounded,
                          size: AppGraphit.toolIcon,
                          color: colors.ink,
                        )
                      : null,
                ),
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
              switch (state) {
                null => const SizedBox.shrink(),
                RecipeLineAssigned(:final stock?, :final rest?) => Text(
                  l10n.recipeLineStockAndRest(
                    ingredientStockLabel(l10n, stock.amount, stock.unit),
                    ingredientStockLabel(l10n, rest.amount, rest.unit),
                  ),
                  style: stateStyle,
                ),
                RecipeLineAssigned(:final stock?) => IngredientStockText(
                  stock: stock,
                ),
                RecipeLineAssigned() => const SizedBox.shrink(),
                RecipeLineShopping() => Text(
                  l10n.recipeLineShopping,
                  style: stateStyle,
                ),
                RecipeLineOpen() => Text(
                  l10n.recipeLineOpen,
                  style: stateStyle,
                ),
                RecipeLineIgnored(:final notCounted) => Text(
                  notCounted
                      ? l10n.recipeLineNotCounted
                      : l10n.recipeLineIgnored,
                  style: stateStyle,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

// [requirement] with the run's own amount [own] instead of the recipe's;
// a line whose text names no amount takes the unit the cook typed it in.
TemplateIngredientRequirement? _withOwn(
  TemplateIngredientRequirement? requirement,
  RecipeLineOwnAmount? own,
) {
  if (own == null) return requirement;
  final unit = requirement?.unit ?? own.unit;
  if (unit == null) return requirement;
  return TemplateIngredientRequirement(
    amount: own.amount,
    unit: unit,
    name: requirement?.name ?? '',
    countMeasureLabel: requirement?.countMeasureLabel,
  );
}

/// The mark before a line in a cook run, never a box to tick: a check for
/// "bereit", a cart for "im Einkauf", a minus for "weggelassen", a hollow
/// dot for "offen".
class _Lead extends StatelessWidget {
  const new({required this.state});

  final RecipeLineState state;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final (icon, color) = switch (state) {
      RecipeLineAssigned(rest: _?) => (
        Icons.shopping_cart_outlined,
        colors.ink,
      ),
      RecipeLineAssigned() => (Icons.check_rounded, colors.ink),
      RecipeLineShopping() => (Icons.shopping_cart_outlined, colors.ink),
      RecipeLineIgnored() => (Icons.remove_rounded, colors.muted),
      RecipeLineOpen() => (Icons.circle_outlined, colors.muted),
    };
    return SizedBox(
      width: AppGraphit.rowTile,
      child: Center(
        child: Icon(icon, size: AppGraphit.toolIcon, color: color),
      ),
    );
  }
}
