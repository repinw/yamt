import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_names_service.dart';

part 'ingredient_check_save_service.g.dart';

/// Why saving the ingredient check stopped: before the recipe was saved,
/// so nothing changed, or after it, at the shopping list.
class IngredientCheckSaveFailure implements Exception {
  /// Creates the failure; [recipeSaved] when only the list failed.
  const new({required this.recipeSaved, this.cause});

  /// Whether the recipe holds the choices already.
  final bool recipeSaved;

  /// The error that stopped it.
  final Object? cause;

  @override
  String toString() =>
      'IngredientCheckSaveFailure(recipeSaved: $recipeSaved, $cause)';
}

/// Saves what the ingredient check decided: the Vorrat items and ignored
/// ingredients on the recipe, then what it lacks on the shopping list.
class IngredientCheckSaveService {
  /// Creates the workflow on the cookbook's templates and the shopping list.
  const new({
    required this._templates,
    required this._shopping,
    required this._clock,
  });

  final PreparedMealTemplateRepository _templates;
  final ShoppingListNamesService _shopping;
  final DateTime Function() _clock;

  /// Saves [recipe] with [assignments] and [ignored], calls [onRecipeSaved],
  /// then puts [onList] on the shopping list. Throws an
  /// [IngredientCheckSaveFailure] that says how far it got.
  Future<void> save({
    required PreparedMeal recipe,
    required Map<String, List<String>> assignments,
    required List<String> ignored,
    required List<String> onList,
    required void Function() onRecipeSaved,
  }) async {
    final bool saved;
    try {
      saved = await _templates.save(
        recipe.copyWith(
          recipeIngredientAssignments: assignments,
          ignoredRecipeIngredients: ignored,
          updatedAt: _clock(),
        ),
      );
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        IngredientCheckSaveFailure(recipeSaved: false, cause: error),
        stackTrace,
      );
    }
    if (!saved) {
      throw const IngredientCheckSaveFailure(recipeSaved: false);
    }
    onRecipeSaved();
    if (onList.isEmpty) {
      return;
    }
    try {
      await _shopping.addMissing(onList);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        IngredientCheckSaveFailure(recipeSaved: true, cause: error),
        stackTrace,
      );
    }
  }
}

/// The workflow on the household's cookbook and shopping list.
@riverpod
IngredientCheckSaveService ingredientCheckSaveService(Ref ref) =>
    IngredientCheckSaveService(
      templates: ref.watch(preparedMealTemplateRepositoryProvider),
      shopping: ref.watch(shoppingListNamesServiceProvider),
      clock: ref.watch(clockProvider),
    );
