import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'cook_recipe_source.g.dart';

/// The Kochbuch recipe `recipeId` as stored today, read only, or `null`
/// when it is gone or a Vorlage. Until the recipes move to their own
/// collection, the Kochmodus reads them from the cookbook templates.
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
