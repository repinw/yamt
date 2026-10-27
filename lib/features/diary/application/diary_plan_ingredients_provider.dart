import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/template_plan_ingredients.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'diary_plan_ingredients_provider.g.dart';

/// A recipe and its ingredient lines with the Vorrat items they count with.
typedef DiaryPlanIngredients = ({
  PreparedMeal recipe,
  List<TemplatePlanIngredient> lines,
});

/// The Kochbuch recipe [templateId] of a plan with its ingredient lines as
/// a plan counts them from the Vorrat now, or null when it is no recipe or
/// gone.
@riverpod
Future<DiaryPlanIngredients?> diaryPlanIngredients(
  Ref ref,
  String templateId,
) async {
  // Start both loads before awaiting one, so they run side by side.
  final items = ref.watch(inventoryQuickEatItemsProvider.future)..ignore();
  final templates = ref.watch(planTemplatesProvider.future)..ignore();
  final parser = ref.watch(templateIngredientParserProvider);
  final recipe = (await templates).firstWhereOrNull(
    (template) => template.id == templateId,
  );
  if (recipe == null || recipe.recipeIngredients.isEmpty) {
    return null;
  }
  return (
    recipe: recipe,
    lines: templatePlanIngredients(recipe, await items, parser: parser),
  );
}

/// A recipe line of a plan with what the plan takes for it: its Vorrat
/// items as "name · brand", null when it has none, and the amount and kcal
/// of its foods, null when it has none or is a reminder.
typedef DiaryPlanIngredientLine = ({
  TemplatePlanIngredient ingredient,
  String? items,
  String? amount,
  double? kcal,
});

/// The ingredients of a plan: its recipe `lines` and, as `others`, the
/// plan's foods that no line takes now, with their amount and kcal (null
/// for a reminder).
typedef DiaryPlanIngredientRows = ({
  List<DiaryPlanIngredientLine> lines,
  List<({String name, String amount, double? kcal})> others,
});

/// Pairs each of [lines] with the foods of [plan] it takes. Plan foods keep
/// no item id, so name and brand tell which item they are; they come in the
/// order of the lines, so each food belongs to one line, even when two
/// lines take one item. A food whose item a line no longer takes, for
/// example one used up since the plan was counted, stays in `others`, so
/// the rows show all the plan counts.
DiaryPlanIngredientRows diaryPlanIngredientLines(
  CalorieEntry plan,
  List<TemplatePlanIngredient> lines,
) {
  final all = plan.bundleComponents;
  final used = <int>{};
  DiaryPlanIngredientLine take(TemplatePlanIngredient line) {
    final foods = <CalorieEntryBundleComponent>[];
    for (final item in line.items) {
      final match = all.indexed.firstWhereOrNull(
        (food) =>
            !used.contains(food.$1) &&
            food.$2.name == item.name &&
            food.$2.brand == item.brand,
      );
      if (match != null) {
        used.add(match.$1);
        foods.add(match.$2);
      }
    }
    // A reminder has no kcal yet.
    final counts = foods.isNotEmpty && !plan.nutritionPending;
    return (
      ingredient: line,
      items: line.items.isEmpty ? null : line.items.map(_itemName).join(', '),
      amount: counts ? foods.map((food) => food.amountLabel).join(' + ') : null,
      kcal: counts
          ? foods.fold<double>(0, (sum, food) => sum + food.totalKcal)
          : null,
    );
  }

  final paired = [for (final line in lines) take(line)];
  return (
    lines: paired,
    others: [
      for (final (index, food) in all.indexed)
        if (!used.contains(index))
          (
            name: food.name,
            amount: food.amountLabel,
            kcal: plan.nutritionPending ? null : food.totalKcal,
          ),
    ],
  );
}

String _itemName(InventoryItem item) => switch (item.brand?.trim()) {
  final brand? when brand.isNotEmpty => '${item.name} · $brand',
  _ => item.name,
};
