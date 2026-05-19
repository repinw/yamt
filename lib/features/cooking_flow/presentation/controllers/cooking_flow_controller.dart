import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_logic.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';

part 'cooking_flow_controller.g.dart';

/// UI-facing cookflow controller state.
class CookingFlowControllerState {
  /// Creates state.
  const CookingFlowControllerState({
    this.isFinalizingMeal = false,
  });

  /// Whether final save is running.
  final bool isFinalizingMeal;

  /// Returns updated state.
  CookingFlowControllerState copyWith({
    bool? isFinalizingMeal,
  }) {
    return CookingFlowControllerState(
      isFinalizingMeal: isFinalizingMeal ?? this.isFinalizingMeal,
    );
  }
}

/// Controls cookflow business actions.
@Riverpod(
  dependencies: [
    inventoryItemRepository,
    PreparedMealsController,
  ],
)
class CookingFlowController extends _$CookingFlowController {
  @override
  CookingFlowControllerState build() {
    return const CookingFlowControllerState();
  }

  /// Saves current cookflow as one or more prepared meals.
  Future<CookingFlowFinalizeSaveResult> finalizeMeal({
    required PreparedMeal template,
    required List<CookingFlowSummaryIngredientDraft> summaryIngredients,
    required CookingFlowIntroDraft? introDraft,
    required int targetPortions,
    required int finalPortions,
    required List<CookingFlowFinalizeStorageContainerInput> containers,
    required Map<String, String> ingredientContainerAssignments,
  }) async {
    if (state.isFinalizingMeal) {
      return const CookingFlowFinalizeSaveResult.failure(
        CookingFlowFinalizeSaveFailure.saveFailed,
      );
    }

    final validationFailure = validateCookingFlowFinalize(
      containers: containers,
      summaryIngredients: summaryIngredients,
      assignments: ingredientContainerAssignments,
    );
    if (validationFailure != null) {
      return const CookingFlowFinalizeSaveResult.failure(
        CookingFlowFinalizeSaveFailure.invalidInput,
      );
    }

    state = state.copyWith(isFinalizingMeal: true);
    try {
      final inventoryItems = await ref
          .read(inventoryItemRepositoryProvider)
          .readAll();
      if (!ref.mounted) {
        return const CookingFlowFinalizeSaveResult.failure(
          CookingFlowFinalizeSaveFailure.saveFailed,
        );
      }

      final savePlan = buildCookingFlowFinalizeSavePlan(
        template: template,
        inventoryItems: inventoryItems,
        summaryIngredients: summaryIngredients,
        introDraft: introDraft,
        targetPortions: targetPortions,
        finalPortions: finalPortions,
      );
      if (savePlan.totalInputCount < 1) {
        return const CookingFlowFinalizeSaveResult.failure(
          CookingFlowFinalizeSaveFailure.missingAssignments,
        );
      }

      final effectiveAssignments =
          effectiveCookingFlowIngredientContainerAssignments(
            containers: containers,
            summaryIngredients: summaryIngredients,
            assignments: ingredientContainerAssignments,
          );
      final preparedMealContainers = buildCookingFlowPreparedMealContainers(
        savePlan: savePlan,
        containers: containers,
        ingredientContainerAssignments: effectiveAssignments,
      );
      if (preparedMealContainers.isEmpty) {
        return const CookingFlowFinalizeSaveResult.failure(
          CookingFlowFinalizeSaveFailure.containerMissingIngredients,
        );
      }

      final result = await ref
          .read(preparedMealsControllerProvider.notifier)
          .createPreparedMealsFromTemplateContainers(
            template: savePlan.template,
            totalPortions: savePlan.template.totalPortions,
            recipeIngredientAssignments: savePlan.recipeIngredientAssignments,
            recipeIngredientAmountConversions:
                savePlan.recipeIngredientAmountConversions,
            additionalItems: savePlan.additionalItems,
            containers: preparedMealContainers,
            sourceKeysByIngredient: savePlan.sourceKeysByIngredient,
          );
      if (!ref.mounted) {
        return const CookingFlowFinalizeSaveResult.failure(
          CookingFlowFinalizeSaveFailure.saveFailed,
        );
      }

      if (!result.isSuccess || result.preparedMealIds.isEmpty) {
        return const CookingFlowFinalizeSaveResult.failure(
          CookingFlowFinalizeSaveFailure.saveFailed,
        );
      }

      await ref.read(cookingFlowSessionCoordinatorProvider).clear();
      if (!ref.mounted) {
        return const CookingFlowFinalizeSaveResult.failure(
          CookingFlowFinalizeSaveFailure.saveFailed,
        );
      }
      return CookingFlowFinalizeSaveResult.success(
        preparedMealId: result.preparedMealIds.first,
        containerCount: preparedMealContainers.length,
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to finalize cookflow meal.',
        name: 'CookingFlowController',
        error: error,
        stackTrace: stackTrace,
      );
      return const CookingFlowFinalizeSaveResult.failure(
        CookingFlowFinalizeSaveFailure.saveFailed,
      );
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isFinalizingMeal: false);
      }
    }
  }
}
