import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_planned_nutrition.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The kcal and macros of one portion of a recipe ([RecipePortion]), the
/// macros in their colors in three columns, "≈ … · geschätzt" while an
/// estimate is in them. They stay per portion, whatever portions the cook
/// chooses.
class RecipeEstimateLine extends StatelessWidget {
  /// Creates the line for [portion].
  const new({required RecipePortion this.portion, this.palette, super.key});

  /// Creates the line while the estimate is being made: it says so, muted,
  /// and keeps the height of the numbers, so nothing moves when they come.
  const new waiting({this.palette, super.key}) : portion = null;

  /// Key of the line.
  static const lineKey = ValueKey<String>('recipe-estimate');

  /// Key of the line while the estimate is being made.
  static const waitKey = ValueKey<String>('recipe-estimate-wait');

  /// The portion; `null` while the estimate is being made.
  final RecipePortion? portion;

  /// The colors to draw with, such as the dark ones over a photo; the
  /// theme's when `null`.
  final FoodLabelColors? palette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = palette ?? FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final values = portion?.values;

    return Column(
      key: values == null ? waitKey : lineKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        if (values == null)
          Text(
            l10n.recipeEstimating,
            style: textTheme.bodyMedium?.copyWith(color: colors.muted),
          )
        else
          Text(
            portion!.estimated
                ? l10n.recipeEstimateKcal(values.kcal.round())
                : l10n.recipePlannedKcal(values.kcal.round()),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        // Hidden while waiting, but taking its place.
        Visibility(
          visible: values != null,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: MacroGrams.columns(
            protein: values?.protein ?? 0,
            carbs: values?.carbs ?? 0,
            fat: values?.fat ?? 0,
            palette: colors,
          ),
        ),
      ],
    );
  }
}
