import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';

part 'recipe_check_status.g.dart';

/// How many ingredients of a recipe still need the cook.
typedef RecipeCheckStatus = ({int missing, int partial});

/// The ingredients of the recipe [recipeId] that are missing or only partly
/// there and whose shopping text is not on the shopping list yet.
@riverpod
RecipeCheckStatus recipeCheckStatus(
  Ref ref,
  String recipeId,
  String localeCode,
) {
  final view = ref.watch(recipeViewProvider(recipeId, localeCode)).value;
  final listed = ref.watch(activeShoppingListItemKeysProvider);
  final open = [
    for (final line in view?.activeLines ?? const <RecipeIngredientLine>[])
      if ((line.isMissing || line.isPartial) &&
          !isSourceItemInActiveShoppingList(
            item: (
              name: line.shoppingLabel,
              brand: null,
              initialQuantity: 1,
              unitPrice: 0,
            ),
            activeItemKeys: listed,
          ))
        line,
  ];
  final missing = open.where((line) => line.isMissing).length;
  return (missing: missing, partial: open.length - missing);
}
