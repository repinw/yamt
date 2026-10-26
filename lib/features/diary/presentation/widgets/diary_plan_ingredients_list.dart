import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/application/diary_plan_ingredients_provider.dart';
import 'package:yamt/features/inventory/application/template_plan_ingredients.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_components_list.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The ingredients of the plan [plan]: for a recipe each line over the
/// Vorrat item it counts with ([lines]), and below them the plan's foods no
/// line takes; else, and while the recipe loads, the plan's foods.
class DiaryPlanIngredientsList extends StatelessWidget {
  /// Creates the list for [plan].
  const new({
    required this.plan,
    required this.lines,
    required this.onPick,
    super.key,
  });

  /// The plan as the page shows it.
  final CalorieEntry plan;

  /// The recipe lines of [plan], null when it comes from no recipe.
  final AsyncValue<DiaryPlanIngredientRows?> lines;

  /// Called on a tap on a line that could take another Vorrat item.
  final ValueChanged<TemplatePlanIngredient> onPick;

  @override
  Widget build(BuildContext context) => lines.when(
    // Each change of the plan's amount reloads the lines; the old ones stay
    // meanwhile.
    skipLoadingOnReload: true,
    // The plan's foods stand in while the recipe loads.
    loading: _foods,
    error: (_, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _foods(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            AppLocalizations.of(context)!.diaryPlanIngredientsLoadFailed,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: FoodLabelColors.of(context).low),
          ),
        ),
      ],
    ),
    data: (rows) => rows == null
        ? _foods()
        : EatComponentsList.recipe(
            initiallyExpanded: true,
            components: rows.others,
            recipeLines: [
              for (final line in rows.lines)
                (
                  line: line.ingredient.ingredient.trim(),
                  items: line.items,
                  amount: line.amount,
                  kcal: line.kcal,
                  onTap: line.ingredient.candidates.isEmpty
                      ? null
                      : () => onPick(line.ingredient),
                ),
            ],
          ),
  );

  Widget _foods() {
    // A reminder has no foods to show while its recipe loads.
    if (plan.bundleComponents.isEmpty) {
      return const SizedBox.shrink();
    }
    return EatComponentsList(
      initiallyExpanded: true,
      components: [
        for (final food in plan.bundleComponents)
          (name: food.name, amount: food.amountLabel, kcal: food.totalKcal),
      ],
    );
  }
}
