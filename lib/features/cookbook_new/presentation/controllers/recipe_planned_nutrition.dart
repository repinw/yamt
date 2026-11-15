import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

part 'recipe_planned_nutrition.g.dart';

/// The energy and macros of one portion of a recipe.
typedef RecipePortionValues = ({
  double kcal,
  double protein,
  double carbs,
  double fat,
});

// What a recipe's cook run knows of one portion: `real`, the values of the
// Vorrat foods its lines take, and `unplanned`, the recipe lines by index
// that take none yet: open, or waiting on the shopping list.
typedef _RunNutrition = ({RecipePortionValues real, Set<int> unplanned});

/// One portion of a recipe as every screen shows it: its `values`, and
/// whether an estimate is in them (`estimated`, shown with "≈").
typedef RecipePortion = ({RecipePortionValues values, bool estimated});

/// One portion of the recipe [recipeId], the one place every screen reads
/// it from. Before cooking, the AI's estimate. While cooking, each line
/// planned from the Vorrat brings its real values instead of its estimate;
/// once no line is open or waits on the shopping list, the portion holds
/// only real values and is no longer `estimated`. `null` without an
/// estimate while a line still needs one.
@riverpod
RecipePortion? recipePortion(Ref ref, String recipeId) {
  final meal = ref
      .watch(cookbookTemplatesProvider)
      .value
      ?.firstWhereOrNull((template) => template.id == recipeId);
  final estimate = meal?.fittingRecipeEstimate;
  final run = meal == null || meal.recipeIngredients.isEmpty
      ? null
      : ref.watch(recipeCookRunProvider(recipeId)).value;
  final items = run == null
      ? const <String, InventoryItem>{}
      : {
          for (final item
              in ref.watch(inventoryQuickEatItemsProvider).value ??
                  const <InventoryItem>[])
            item.id: item,
        };
  final planned = run == null ? null : _runNutrition(run, items);
  if (planned != null) {
    if (_shown(planned, estimate) case final shown?) return shown;
  }
  return estimate == null
      ? null
      : (values: estimateValues(estimate), estimated: true);
}

/// The values of one portion of [estimate].
RecipePortionValues estimateValues(RecipeEstimate estimate) => (
  kcal: estimate.kcal,
  protein: estimate.protein,
  carbs: estimate.carbs,
  fat: estimate.fat,
);

// What [run] knows of one portion; `null` when a planned food has no energy
// or macros, or a line the cooking added is not planned.
_RunNutrition? _runNutrition(CookRun run, Map<String, InventoryItem> items) {
  var (kcal, protein, carbs, fat) = (0.0, 0.0, 0.0, 0.0);
  final unplanned = <int>{};
  for (final line in run.lines) {
    switch (line.settlement) {
      case LineOpen() || LineShopping():
        // A line the cooking added has no estimate: its value is unknown.
        final index = _recipeLineIndex(line.id);
        if (index == null) return null;
        unplanned.add(index);
      case LineIgnored():
        break;
      case LineAssigned(:final takes):
        for (final take in takes) {
          if (take.amount <= 0) continue;
          final item = items[take.itemId];
          final nutrition = item?.nutrition;
          if (item == null || !hasCompleteNutrition(nutrition)) return null;
          final facts = buildPreparedMealComponent(
            item: item,
            usedAmount: take.amount,
            usedUnit: resolveUsedUnit(item),
            nutrition: nutrition!,
          ).nutritionFacts;
          kcal += facts.kcal ?? 0;
          protein += facts.protein ?? 0;
          carbs += facts.carbs ?? 0;
          fat += facts.fat ?? 0;
        }
    }
  }
  final portions = run.portions < 1 ? 1 : run.portions;
  return (
    real: (
      kcal: kcal / portions,
      protein: protein / portions,
      carbs: carbs / portions,
      fat: fat / portions,
    ),
    unplanned: unplanned,
  );
}

// The real values of the planned lines plus the [estimate] of each
// unplanned line, estimated while one is left; `null` when the estimate has
// no values per line for them.
RecipePortion? _shown(_RunNutrition run, RecipeEstimate? estimate) {
  if (run.unplanned.isEmpty) return (values: run.real, estimated: false);
  final lines = estimate?.lines;
  if (estimate == null ||
      lines == null ||
      run.unplanned.any((index) => index >= lines.length)) {
    return null;
  }
  // A line's estimate is for the whole recipe of its portions.
  final share = 1 / (estimate.portions < 1 ? 1 : estimate.portions);
  var values = run.real;
  for (final index in run.unplanned) {
    final line = lines[index].scaled(share);
    values = (
      kcal: values.kcal + line.kcal,
      protein: values.protein + line.protein,
      carbs: values.carbs + line.carbs,
      fat: values.fat + line.fat,
    );
  }
  return (values: values, estimated: true);
}

// A cook run names the recipe's lines "line-<index>".
int? _recipeLineIndex(String lineId) =>
    lineId.startsWith('line-') ? int.tryParse(lineId.substring(5)) : null;
