import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// A saved Vorlage or recipe with the stock state of each of its foods.
@immutable
class CookbookEntry {
  /// Creates the entry for [meal] with one stock flag per food.
  const new({required this.meal, required this.inStock});

  /// The saved template.
  final PreparedMeal meal;

  /// Whether the Vorrat holds each food, in the order of the foods.
  final List<bool> inStock;

  /// Number of foods that the Vorrat does not hold.
  int get missingCount => inStock.where((isInStock) => !isInStock).length;
}

/// Everything the Kochbuch shows: meals still in the pot, Vorlagen combined
/// from the Vorrat, and recipes.
@immutable
class CookbookOverview {
  /// Creates the overview.
  const new({
    required this.openMeals,
    required this.templates,
    required this.recipes,
  });

  /// Sorts saved [savedTemplates] into Vorlagen and recipes and picks the
  /// meals in [meals] that are still in the pot or have open rows.
  ///
  /// A template with recipe ingredients is a recipe; one without is a Vorlage
  /// combined from Vorrat foods. [isInStock] tells whether the Vorrat holds a
  /// food with the given name.
  factory fromMeals({
    required List<PreparedMeal> savedTemplates,
    required List<PreparedMeal> meals,
    required bool Function(String food) isInStock,
  }) {
    final templates = <CookbookEntry>[];
    final recipes = <CookbookEntry>[];
    for (final template in savedTemplates) {
      if (template.recipeIngredients.isEmpty) {
        templates.add(
          CookbookEntry(
            meal: template,
            inStock: [
              for (final component in template.components)
                isInStock(component.name),
            ],
          ),
        );
      } else {
        recipes.add(
          CookbookEntry(
            meal: template,
            inStock: [
              for (final ingredient in template.recipeIngredients)
                if (!template.ignoredRecipeIngredients.contains(ingredient))
                  isInStock(ingredient),
            ],
          ),
        );
      }
    }
    final openMeals =
        meals
            .where(
              (meal) =>
                  (meal.isInPot || meal.pendingRecipeIngredients.isNotEmpty) &&
                  meal.remainingPortions > 0,
            )
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return CookbookOverview(
      openMeals: List.unmodifiable(openMeals),
      templates: List.unmodifiable(templates),
      recipes: List.unmodifiable(recipes),
    );
  }

  /// Meals in the Vorrat that are still in the pot or have open rows, newest
  /// first.
  final List<PreparedMeal> openMeals;

  /// Vorlagen combined from Vorrat foods.
  final List<CookbookEntry> templates;

  /// Recipes from a link, a photo, or the AI.
  final List<CookbookEntry> recipes;
}
