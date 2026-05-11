import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_builder.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';

/// Provides wizard session persistence operations.
final cookingFlowWizardSessionControllerProvider =
    Provider<CookingFlowWizardSessionController>((ref) {
      return CookingFlowWizardSessionController(
        ref.read(cookingFlowSessionCoordinatorProvider),
      );
    });

/// Handles cookflow wizard session persistence and mapping.
class CookingFlowWizardSessionController {
  /// Creates wizard session controller.
  const CookingFlowWizardSessionController(this._sessionCoordinator);

  final CookingFlowSessionCoordinator _sessionCoordinator;

  /// Restores saved session for [templateId].
  Future<CookingFlowSession?> restoreSession(String templateId) async {
    final storedSession = await _sessionCoordinator.load();
    if (storedSession == null || storedSession.templateId != templateId) {
      return null;
    }
    return storedSession;
  }

  /// Maps saved session into wizard state.
  CookingFlowWizardState stateFromStoredSession({
    required CookingFlowWizardState currentState,
    required CookingFlowSession storedSession,
  }) {
    return currentState.copyWith(
      adjustments: storedSession.adjustments,
      summaryIngredients: _summaryIngredientsFromSession(storedSession),
      summarySourceSignature: buildCookingFlowSummarySourceSignature(
        storedSession.introDraft,
        targetPortions: _restoredTargetRecipePortions(
          storedSession.portionCount,
        ),
      ),
      splitIntoPortions: storedSession.splitIntoPortions,
      portionCount: storedSession.portionCount,
      finalPortionCount:
          storedSession.finalPortionCount ?? storedSession.portionCount,
      didInitializePortionsFromTemplate: true,
      step: _pageStep(storedSession.step),
      introDraft: storedSession.introDraft,
      introShoppingHandled: storedSession.introShoppingHandled,
      introShoppingBaselineInventoryItemIds:
          storedSession.introShoppingBaselineInventoryItemIds,
      ingredientContainerAssignments:
          storedSession.ingredientContainerAssignments,
      savedPreparedMealId: null,
      savedPreparedMealName: null,
      savedContainerCount: 0,
      isRestoringSession: false,
    );
  }

  /// Clears persisted session.
  Future<bool> clearSession() {
    return _sessionCoordinator.clear();
  }

  /// Saves current session.
  Future<bool> saveSession({
    required CookingFlowWizardState state,
    required CookingFlowWizardSessionInput input,
  }) {
    if (state.isRestoringSession) {
      return Future<bool>.value(false);
    }
    return _sessionCoordinator.save(
      _sessionSnapshot(state: state, input: input),
    );
  }

  /// Persists session without waiting.
  void persistSessionSilently({
    required CookingFlowWizardState state,
    required CookingFlowWizardSessionInput input,
  }) {
    if (state.isRestoringSession) {
      return;
    }
    unawaited(
      _sessionCoordinator.save(_sessionSnapshot(state: state, input: input)),
    );
  }

  CookingFlowSession _sessionSnapshot({
    required CookingFlowWizardState state,
    required CookingFlowWizardSessionInput input,
  }) {
    return CookingFlowSession(
      templateId: input.templateId,
      step: _sessionStep(state.step),
      taraText: input.taraText,
      taraUtensilId: input.taraUtensilId,
      adjustmentInputText: input.adjustmentInputText,
      adjustments: List<String>.from(state.adjustments, growable: false),
      summaryIngredients: state.summaryIngredients
          .map(
            (ingredient) => CookingFlowSummaryIngredientSessionDraft(
              key: ingredient.key,
              name: ingredient.name,
              amount: ingredient.amount,
              unitCode: ingredient.unitCode,
              inventoryItemIds: ingredient.inventoryItemIds,
              kind: ingredient.kind,
              sourceIngredient: ingredient.sourceIngredient,
            ),
          )
          .toList(growable: false),
      grossWeightText: input.grossWeightText,
      splitIntoPortions: state.splitIntoPortions,
      portionCount: state.portionCount,
      finalPortionCount: state.finalPortionCount,
      introDraft: state.introDraft ?? const CookingFlowIntroDraft(),
      introShoppingHandled: state.introShoppingHandled,
      introShoppingBaselineInventoryItemIds:
          state.introShoppingBaselineInventoryItemIds,
      storageContainers: input.storageContainers
          .map(
            (container) => CookingFlowStorageContainerSessionDraft(
              id: container.id,
              label: container.label,
              taraText: container.taraText,
              taraUtensilId: container.taraUtensilId,
              grossWeightText: container.grossWeightText,
              portionCount: container.portionCount,
            ),
          )
          .toList(growable: false),
      ingredientContainerAssignments: input.ingredientContainerAssignments,
    );
  }

  List<CookingFlowSummaryIngredientDraft> _summaryIngredientsFromSession(
    CookingFlowSession storedSession,
  ) {
    return storedSession.summaryIngredients
        .map(
          (ingredient) => CookingFlowSummaryIngredientDraft(
            key: ingredient.key,
            name: ingredient.name,
            amount: ingredient.amount,
            unitCode: ingredient.unitCode,
            inventoryItemIds: ingredient.inventoryItemIds,
            kind: ingredient.kind,
            sourceIngredient: ingredient.sourceIngredient,
          ),
        )
        .toList(growable: false);
  }
}

int _restoredTargetRecipePortions(double portionCount) {
  final roundedPortions = portionCount.round();
  return roundedPortions < 1 ? 1 : roundedPortions;
}

CookingFlowStep _pageStep(CookingFlowSessionStep step) {
  return switch (step) {
    CookingFlowSessionStep.start => CookingFlowStep.start,
    CookingFlowSessionStep.preparation => CookingFlowStep.preparation,
    CookingFlowSessionStep.cooking => CookingFlowStep.cooking,
    CookingFlowSessionStep.summary => CookingFlowStep.summary,
    CookingFlowSessionStep.finalize => CookingFlowStep.finalize,
  };
}

CookingFlowSessionStep _sessionStep(CookingFlowStep step) {
  return switch (step) {
    CookingFlowStep.start => CookingFlowSessionStep.start,
    CookingFlowStep.preparation => CookingFlowSessionStep.preparation,
    CookingFlowStep.cooking => CookingFlowSessionStep.cooking,
    CookingFlowStep.summary => CookingFlowSessionStep.summary,
    CookingFlowStep.finalize => CookingFlowSessionStep.finalize,
    CookingFlowStep.success => CookingFlowSessionStep.finalize,
  };
}
