import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Resolved nutrition preview for finalize step.
class CookingFlowNutritionPreview {
  /// Creates preview.
  const CookingFlowNutritionPreview({
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  /// Empty preview.
  const CookingFlowNutritionPreview.zero()
    : kcal = 0,
      carbs = 0,
      protein = 0,
      fat = 0;

  /// Kcal value.
  final double kcal;

  /// Carbs value.
  final double carbs;

  /// Protein value.
  final double protein;

  /// Fat value.
  final double fat;
}

/// Pure storage container input for save/validation.
class CookingFlowFinalizeStorageContainerInput {
  /// Creates container input.
  const CookingFlowFinalizeStorageContainerInput({
    required this.id,
    required this.label,
    required this.taraText,
    required this.grossWeightText,
    required this.taraWeight,
    required this.grossWeight,
    required this.finalNetWeight,
    required this.totalPortions,
  });

  /// Stable container id.
  final String id;

  /// Display label used for split meal names.
  final String label;

  /// Raw tara text.
  final String taraText;

  /// Raw gross text.
  final String grossWeightText;

  /// Tara weight in grams.
  final int taraWeight;

  /// Gross weight in grams.
  final int grossWeight;

  /// Net food weight in grams.
  final int finalNetWeight;

  /// Portion count for this saved meal.
  final int totalPortions;
}

/// Finalize validation failure.
enum CookingFlowFinalizeValidationFailure {
  /// No storage container exists.
  missingWeight,

  /// Gross weight is missing.
  missingGrossWeight,

  /// Gross weight is not valid.
  invalidWeight,

  /// Gross weight must exceed tara.
  grossMustExceedTara,

  /// Ingredient row has no container.
  ingredientContainerMissing,

  /// Container has no assigned ingredient.
  containerMissingIngredients,
}

/// Save failure reason for final cookflow step.
enum CookingFlowFinalizeSaveFailure {
  /// Template disappeared.
  templateNotFound,

  /// Validation failed.
  invalidInput,

  /// No inventory item assignment exists.
  missingAssignments,

  /// At least one container has no ingredients.
  containerMissingIngredients,

  /// Prepared meal save failed.
  saveFailed,
}

/// Save result from controller.
class CookingFlowFinalizeSaveResult {
  /// Creates success.
  const CookingFlowFinalizeSaveResult.success({
    required this.preparedMealId,
    required this.containerCount,
  }) : failure = null;

  /// Creates failure.
  const CookingFlowFinalizeSaveResult.failure(this.failure)
    : preparedMealId = null,
      containerCount = 0;

  /// Failure reason, null on success.
  final CookingFlowFinalizeSaveFailure? failure;

  /// First prepared meal id.
  final String? preparedMealId;

  /// Number of saved containers/meals.
  final int containerCount;

  /// Whether save succeeded.
  bool get isSuccess => failure == null;
}

/// Resolved save plan before storage split.
class CookingFlowFinalizeMealSavePlan {
  /// Creates save plan.
  const CookingFlowFinalizeMealSavePlan({
    required this.template,
    required this.recipeIngredientAssignments,
    required this.recipeIngredientAmountConversions,
    required this.additionalItems,
    required this.sourceKeysByIngredient,
    required this.totalInputCount,
  });

  /// Template copy used for create workflow.
  final PreparedMeal template;

  /// Recipe ingredient to inventory item ids.
  final Map<String, List<String>> recipeIngredientAssignments;

  /// Ingredient conversion metadata.
  final Map<String, RecipeIngredientAmountConversion>
  recipeIngredientAmountConversions;

  /// Extra non-template inputs.
  final List<PreparedMealItemInput> additionalItems;

  /// Ingredient label to stable source row key.
  final Map<String, String> sourceKeysByIngredient;

  /// Total inventory input count.
  final int totalInputCount;
}
