import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';

/// Discards [portions] of a meal. Returns whether it worked.
typedef PreparedMealDiscardCallback = Future<bool> Function(
  String mealId,
  num portions,
  InventoryDiscardReason reason,
);

/// Fills a missing recipe ingredient from Vorrat foods.
typedef PreparedMealIngredientFillCallback = Future<bool> Function(
  String mealId,
  String ingredient,
  List<String> inventoryItemIds,
);

/// Ignores a missing recipe ingredient.
typedef PreparedMealIngredientIgnoreCallback = Future<bool> Function(
  String mealId,
  String ingredient,
);

/// Changes one meal by id, such as unbundling it.
typedef PreparedMealIdCallback = Future<bool> Function(String mealId);

/// Saves an edit of a meal, or starts picking more ingredients for it.
typedef PreparedMealEditCallback = Future<bool> Function(
  String mealId,
  PreparedMealEditSheetResult result,
);

/// Saves a meal as a recipe template.
typedef PreparedMealSaveTemplateCallback = Future<bool> Function(
  PreparedMeal meal,
);

/// What the meal detail page can do with a meal. The Vorrat page provides
/// them, because picking ingredients returns to its list.
class PreparedMealActions {
  /// Creates the actions.
  const new({
    required this.throwAway,
    required this.fillPendingIngredient,
    required this.ignorePendingIngredient,
    required this.unbundle,
    required this.edit,
    required this.selectEditIngredients,
    required this.saveTemplate,
  });

  /// Throws portions away.
  final PreparedMealDiscardCallback throwAway;

  /// Fills a missing ingredient.
  final PreparedMealIngredientFillCallback fillPendingIngredient;

  /// Ignores a missing ingredient.
  final PreparedMealIngredientIgnoreCallback ignorePendingIngredient;

  /// Puts the ingredients back into the Vorrat.
  final PreparedMealIdCallback unbundle;

  /// Saves an edit.
  final PreparedMealEditCallback edit;

  /// Starts picking more ingredients in the Vorrat list.
  final PreparedMealEditCallback selectEditIngredients;

  /// Saves the meal as a recipe.
  final PreparedMealSaveTemplateCallback saveTemplate;
}
