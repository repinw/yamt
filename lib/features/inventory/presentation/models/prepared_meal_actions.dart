import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_edit_draft.dart';

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

/// Fills a missing recipe ingredient with an amount of one Vorrat item.
typedef PreparedMealIngredientItemFillCallback = Future<bool> Function(
  String mealId,
  String ingredient,
  String itemId,
  int usedAmount,
);

/// Ignores a missing recipe ingredient, or opens an ignored one again.
typedef PreparedMealIngredientIgnoreCallback = Future<bool> Function(
  String mealId,
  String ingredient,
);

/// Takes a food out of a meal again, so its row is open.
typedef PreparedMealUnassignCallback = Future<bool> Function(
  String mealId,
  PreparedMealComponent component,
);

/// Changes one meal by id, such as unbundling it.
typedef PreparedMealIdCallback = Future<bool> Function(String mealId);

/// Saves an edit of a meal and shows the outcome on [messenger].
typedef PreparedMealEditCallback = Future<bool> Function(
  String mealId,
  PreparedMealEditResult result,
  ScaffoldMessengerState messenger,
);

/// Saves a meal as a recipe template and shows the outcome on [messenger].
typedef PreparedMealSaveTemplateCallback = Future<bool> Function(
  PreparedMeal meal,
  ScaffoldMessengerState messenger,
);

/// What the meal detail page can do with a meal, provided by
/// `PreparedMealDetailFlow`. Edit and template messages show on the messenger
/// the detail page passes, because the page has its own messenger and covers
/// the page below.
class PreparedMealActions {
  /// Creates the actions.
  const new({
    required this.throwAway,
    required this.fillPendingIngredient,
    required this.fillPendingIngredientWithItem,
    required this.ignorePendingIngredient,
    required this.unignorePendingIngredient,
    required this.unassign,
    required this.unbundle,
    required this.edit,
    required this.saveTemplate,
  });

  /// Throws portions away.
  final PreparedMealDiscardCallback throwAway;

  /// Fills a missing ingredient.
  final PreparedMealIngredientFillCallback fillPendingIngredient;

  /// Fills a missing ingredient with a chosen amount of one item.
  final PreparedMealIngredientItemFillCallback fillPendingIngredientWithItem;

  /// Ignores a missing ingredient.
  final PreparedMealIngredientIgnoreCallback ignorePendingIngredient;

  /// Opens an ignored ingredient again.
  final PreparedMealIngredientIgnoreCallback unignorePendingIngredient;

  /// Takes a food out of the meal again; its row opens and its stock goes
  /// back to the Vorrat.
  final PreparedMealUnassignCallback unassign;

  /// Puts the ingredients back into the Vorrat.
  final PreparedMealIdCallback unbundle;

  /// Saves an edit.
  final PreparedMealEditCallback edit;

  /// Saves the meal as a recipe.
  final PreparedMealSaveTemplateCallback saveTemplate;
}
