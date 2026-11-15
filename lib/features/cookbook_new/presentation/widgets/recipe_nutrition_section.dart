import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_line_nutrition_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The nutrition under a recipe's ingredients: the food label of one
/// estimated portion, whatever portions the cook chooses, and under it
/// "Nährwerte je Zutat" when the estimate has values per line. Nothing
/// without an estimate. The label brings its own title, so the section has
/// no header.
class RecipeNutritionSection extends StatelessWidget {
  /// Creates the section of [view].
  const new({required this.view, super.key});

  /// Key of the food label.
  static const labelKey = ValueKey<String>('recipe-nutrition-label');

  /// The recipe.
  final RecipeView view;

  @override
  Widget build(BuildContext context) {
    final facts = view.portionFacts;
    if (facts == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          EatLabelTable(
            key: labelKey,
            rows: nutritionFactsRows(context, eaten: facts),
            eatenHeader: AppLocalizations.of(context)!
                .recipeNutritionPortionEstimated,
          ),
          if (view.lineNutrition case final rows?)
            RecipeLineNutritionSection(rows: rows, portions: view.portions),
        ],
      ),
    );
  }
}
