import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cooking/domain/cook_recipe.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'cook_recipe_source.g.dart';

/// The Kochbuch recipe `recipeId` as stored today, read only, or `null`
/// when it is gone or a Vorlage. Until the recipes move to their own
/// collection, cooking reads them from the cookbook templates.
@riverpod
Stream<PreparedMeal?> cookRecipeTemplate(Ref ref, String recipeId) {
  return ref
      .watch(preparedMealTemplateRepositoryProvider)
      .watchAll()
      .map(
        (templates) => templates.firstWhereOrNull(
          (template) =>
              template.id == recipeId && template.recipeIngredients.isNotEmpty,
        ),
      );
}

/// The recipe [template] as cooking sees it, without the ingredients the
/// recipe leaves out. Its lines take their index as id, which stays fixed
/// while the recipe is read only.
CookRecipe cookRecipeOfTemplate(PreparedMeal template) => CookRecipe(
  id: template.id,
  name: template.name,
  portions: max(1, template.totalPortions),
  lines: [
    for (final (index, text) in template.recipeIngredients.indexed)
      if (!template.ignoredRecipeIngredients.contains(text))
        (id: 'line-$index', text: text),
  ],
  imageAssetId: template.imageAssetId,
  imageUrl: template.imageUrl,
);
