import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Defines prepared meal creation failure reason.
enum PreparedMealCreationFailureReason {
  /// Documented member.
  invalidInput,

  /// Documented member.
  itemUnavailable,

  /// Documented member.
  insufficientAmount,

  /// Documented member.
  missingNutrition,

  /// Documented member.
  inventorySaveFailed,

  /// Documented member.
  mealSaveFailed,
}

/// Defines prepared meal creation result.
class PreparedMealCreationResult {
  const PreparedMealCreationResult._({
    required this.isSuccess,
    this.preparedMealId,
    this.failureReason,
  });

  /// Creates a [PreparedMealCreationResult] for success.
  const PreparedMealCreationResult.success(String preparedMealId)
    : this._(isSuccess: true, preparedMealId: preparedMealId);

  /// Creates a [PreparedMealCreationResult] for failure.
  const PreparedMealCreationResult.failure(
    PreparedMealCreationFailureReason reason,
  ) : this._(isSuccess: false, failureReason: reason);

  /// Whether success.
  final bool isSuccess;

  /// The prepared meal id.
  final String? preparedMealId;

  /// The failure reason.
  final PreparedMealCreationFailureReason? failureReason;
}

/// Defines prepared meal item input.
class PreparedMealItemInput {
  /// The prepared meal item input.
  const PreparedMealItemInput({
    required this.itemId,
    required this.usedAmount,
    this.manualNutrition,
  });

  /// The item id.
  final String itemId;

  /// The used amount.
  final int usedAmount;

  /// The manual nutrition.
  final GlobalFoodNutrition? manualNutrition;
}

/// Carries built inventory and meal changes before persistence.
class PreparedMealBuildResult {
  /// Creates a prepared meal build result.
  const PreparedMealBuildResult({
    required this.nextItems,
    required this.preparedMeal,
  });

  /// Updated inventory items after consumption.
  final List<InventoryItem> nextItems;

  /// Prepared meal snapshot ready to save.
  final PreparedMeal preparedMeal;
}

/// Signals validation failure while building a prepared meal draft.
class PreparedMealBuildException implements Exception {
  /// Creates a build exception.
  const PreparedMealBuildException(this.reason);

  /// The reason the build failed.
  final PreparedMealCreationFailureReason reason;
}

/// Carries pending-ingredient fill changes before persistence.
class PreparedMealPendingIngredientFillResult {
  /// Creates a pending ingredient fill result.
  const PreparedMealPendingIngredientFillResult({
    required this.nextItems,
    required this.components,
    this.remainingIngredient,
  });

  /// Updated inventory items after consumption.
  final List<InventoryItem> nextItems;

  /// Components added to the prepared meal.
  final List<PreparedMealComponent> components;

  /// Remaining ingredient label when only part could be filled.
  final String? remainingIngredient;
}

/// Sums macro totals from prepared meal components.
extension PreparedMealComponentNutritionTotals
    on Iterable<PreparedMealComponent> {
  /// Combined nutrition totals across all components.
  ({double totalCarbs, double totalFat, double totalKcal, double totalProtein})
  get nutritionTotals {
    return fold(
      (totalCarbs: 0.0, totalFat: 0.0, totalKcal: 0.0, totalProtein: 0.0),
      (totals, component) => (
        totalCarbs: totals.totalCarbs + component.totalCarbs,
        totalFat: totals.totalFat + component.totalFat,
        totalKcal: totals.totalKcal + component.totalKcal,
        totalProtein: totals.totalProtein + component.totalProtein,
      ),
    );
  }
}
