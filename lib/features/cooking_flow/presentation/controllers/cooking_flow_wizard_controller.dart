import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_logic.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_builder.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_session_service.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_controller.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_shopping_controller.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'cooking_flow_wizard_controller.g.dart';

const _textListEquality = ListEquality<String>();

/// Controls cookflow wizard state and session persistence.
@Riverpod(
  dependencies: [
    CookingFlowController,
  ],
)
class CookingFlowWizardController extends _$CookingFlowWizardController {
  @override
  CookingFlowWizardState build() {
    return const CookingFlowWizardState.initial();
  }

  /// Restores saved session for [templateId].
  Future<CookingFlowSession?> restoreSession(String templateId) async {
    final sessionController = ref.read(
      cookingFlowWizardSessionServiceProvider,
    );
    final storedSession = await sessionController.restoreSession(templateId);
    if (!ref.mounted) {
      return null;
    }
    if (storedSession == null) {
      state = state.copyWith(isRestoringSession: false);
      return null;
    }

    state = sessionController.stateFromStoredSession(
      currentState: state,
      storedSession: storedSession,
    );
    return storedSession;
  }

  /// Initializes base portions from template once.
  bool initializePortionsFromTemplate(PreparedMeal template) {
    if (state.didInitializePortionsFromTemplate) {
      return false;
    }
    final portions = template.totalPortions < 1
        ? 1.0
        : template.totalPortions.toDouble();
    state = state.copyWith(
      didInitializePortionsFromTemplate: true,
      portionCount: portions,
      finalPortionCount: portions,
    );
    return true;
  }

  /// Updates intro CTA/session state.
  void updateIntroSelectionState(CookingFlowIntroSelectionState selection) {
    final shoppingLabelsChanged = !_textListEquality.equals(
      state.introShoppingListLabels,
      selection.shoppingListLabels,
    );
    final nextSignature = buildCookingFlowSummarySourceSignature(
      selection.draft,
      targetPortions: state.targetRecipePortions,
    );
    final shouldResetSummary =
        !state.isRestoringSession &&
        state.summarySourceSignature.isNotEmpty &&
        state.summarySourceSignature != nextSignature;
    state = state.copyWith(
      introDraft: selection.draft,
      introAllItemsSelected: selection.allItemsSelected,
      introHasShoppingSelections: selection.hasShoppingSelections,
      introHasUnresolvedConflicts: selection.hasUnresolvedConflicts,
      introShoppingListLabels: selection.shoppingListLabels,
      summaryIngredients: shouldResetSummary
          ? const <CookingFlowSummaryIngredientDraft>[]
          : state.summaryIngredients,
      introShoppingHandled:
          state.introShoppingHandled &&
          selection.hasShoppingSelections &&
          !shoppingLabelsChanged,
      introShoppingBaselineInventoryItemIds: !selection.hasShoppingSelections
          ? const <String>[]
          : state.introShoppingBaselineInventoryItemIds,
    );
  }

  /// Adds shopping labels from intro to shopping list.
  Future<CookingFlowShoppingListActionResult> addIntroShoppingItems({
    required List<InventoryItem> inventoryItems,
  }) async {
    final labels = List<String>.from(state.introShoppingListLabels);
    final baselineInventoryItemIds = inventoryItems
        .map((item) => item.id)
        .toList(growable: false);
    state = state.copyWith(introShoppingRedirectInProgress: true);

    final result = await ref
        .read(cookingFlowShoppingControllerProvider.notifier)
        .addLabels(labels);
    if (!ref.mounted ||
        result == CookingFlowShoppingListActionResult.disposed) {
      return CookingFlowShoppingListActionResult.disposed;
    }
    if (result == CookingFlowShoppingListActionResult.failed) {
      state = state.copyWith(introShoppingRedirectInProgress: false);
      return result;
    }

    state = state.copyWith(
      introShoppingHandled: true,
      introShoppingRedirectInProgress: false,
      introShoppingBaselineInventoryItemIds: baselineInventoryItemIds,
    );
    return CookingFlowShoppingListActionResult.success;
  }

  /// Resolves matching shopping-list labels.
  Future<void> resolveShoppingListLabels(List<String> labels) async {
    await ref
        .read(cookingFlowShoppingControllerProvider.notifier)
        .resolveLabels(labels);
  }

  /// Opens phase 1.
  void openPreparationStep() {
    state = state.copyWith(step: CookingFlowStep.preparation);
  }

  /// Opens phase 2.
  void openCookingStep() {
    state = state.copyWith(step: CookingFlowStep.cooking);
  }

  /// Opens phase 3 and prepares summary rows.
  void openSummaryStep({
    required PreparedMeal? template,
    required List<InventoryItem> inventoryItems,
    required List<String> containerIds,
  }) {
    final nextSignature = buildCookingFlowSummarySourceSignature(
      state.introDraft,
      targetPortions: state.targetRecipePortions,
    );
    final nextSummaryIngredients = template == null
        ? state.summaryIngredients
        : prepareCookingFlowSummaryIngredients(
            template: template,
            inventoryItems: inventoryItems,
            introDraft: state.introDraft,
            targetPortions: state.targetRecipePortions,
            currentSummaryIngredients: state.summaryIngredients,
          );
    state = state.copyWith(
      summaryIngredients: nextSummaryIngredients,
      summarySourceSignature: nextSignature,
      ingredientContainerAssignments: _normalizedAssignments(
        summaryIngredients: nextSummaryIngredients,
        containerIds: containerIds,
      ),
      step: CookingFlowStep.summary,
    );
  }

  /// Opens phase 4.
  void openFinalizeStep(List<String> containerIds) {
    state = state.copyWith(
      ingredientContainerAssignments: _normalizedAssignments(
        summaryIngredients: state.summaryIngredients,
        containerIds: containerIds,
      ),
      step: CookingFlowStep.finalize,
    );
  }

  /// Goes back one wizard step.
  void goBackOneStep() {
    state = state.copyWith(
      step: switch (state.step) {
        CookingFlowStep.start => CookingFlowStep.start,
        CookingFlowStep.preparation => CookingFlowStep.start,
        CookingFlowStep.cooking => CookingFlowStep.preparation,
        CookingFlowStep.summary => CookingFlowStep.cooking,
        CookingFlowStep.finalize => CookingFlowStep.summary,
        CookingFlowStep.success => CookingFlowStep.success,
      },
    );
  }

  /// Adds cooking adjustment.
  void addAdjustment(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return;
    }
    state = state.copyWith(
      adjustments: <String>[...state.adjustments, trimmedValue],
    );
  }

  /// Removes cooking adjustment.
  void removeAdjustment(int index) {
    if (index < 0 || index >= state.adjustments.length) {
      return;
    }
    final next = List<String>.from(state.adjustments)..removeAt(index);
    state = state.copyWith(adjustments: next);
  }

  /// Updates summary amount.
  void updateSummaryIngredientAmount({
    required int index,
    required String value,
    required List<String> containerIds,
  }) {
    final next = List<CookingFlowSummaryIngredientDraft>.from(
      state.summaryIngredients,
    );
    next[index] = next[index].copyWith(amount: value);
    state = state.copyWith(
      summaryIngredients: next,
      ingredientContainerAssignments: _normalizedAssignments(
        summaryIngredients: next,
        containerIds: containerIds,
      ),
    );
  }

  /// Removes summary ingredient.
  void removeSummaryIngredient({
    required int index,
    required List<String> containerIds,
  }) {
    final next = List<CookingFlowSummaryIngredientDraft>.from(
      state.summaryIngredients,
    )..removeAt(index);
    state = state.copyWith(
      summaryIngredients: next,
      ingredientContainerAssignments: _normalizedAssignments(
        summaryIngredients: next,
        containerIds: containerIds,
      ),
    );
  }

  /// Adds summary ingredient.
  void addSummaryIngredient({
    required CookingFlowSummaryIngredientDraft ingredient,
    required int? adjustmentIndex,
    required List<String> containerIds,
  }) {
    final adjustments = List<String>.from(state.adjustments);
    if (adjustmentIndex != null &&
        adjustmentIndex >= 0 &&
        adjustmentIndex < adjustments.length) {
      adjustments.removeAt(adjustmentIndex);
    }
    final nextIngredients = <CookingFlowSummaryIngredientDraft>[
      ...state.summaryIngredients,
      ingredient,
    ];
    state = state.copyWith(
      adjustments: adjustments,
      summaryIngredients: nextIngredients,
      ingredientContainerAssignments: _normalizedAssignments(
        summaryIngredients: nextIngredients,
        containerIds: containerIds,
      ),
    );
  }

  /// Updates split option.
  void updateSplitIntoPortions({required bool value}) {
    state = state.copyWith(splitIntoPortions: value);
  }

  /// Updates final portion count.
  void updateFinalizePortionCount(double value) {
    state = state.copyWith(finalPortionCount: value.roundToDouble());
  }

  /// Updates base recipe portion count.
  void updatePortionCount(double value) {
    state = state.copyWith(
      portionCount: value.roundToDouble(),
      finalPortionCount: value.roundToDouble(),
      summaryIngredients: const <CookingFlowSummaryIngredientDraft>[],
      summarySourceSignature: '',
      ingredientContainerAssignments: const <String, String>{},
    );
  }

  /// Normalizes ingredient assignments for containers.
  void normalizeIngredientContainerAssignments(List<String> containerIds) {
    state = state.copyWith(
      ingredientContainerAssignments: _normalizedAssignments(
        summaryIngredients: state.summaryIngredients,
        containerIds: containerIds,
      ),
    );
  }

  /// Updates one ingredient-container assignment.
  void updateIngredientContainerAssignment({
    required String rowKey,
    required String containerId,
    required List<String> containerIds,
  }) {
    state = state.copyWith(
      ingredientContainerAssignments: _normalizedAssignments(
        summaryIngredients: state.summaryIngredients,
        containerIds: containerIds,
        baseAssignments: <String, String>{
          ...state.ingredientContainerAssignments,
          rowKey: containerId,
        },
      ),
    );
  }

  Map<String, String> _normalizedAssignments({
    required List<CookingFlowSummaryIngredientDraft> summaryIngredients,
    required List<String> containerIds,
    Map<String, String>? baseAssignments,
  }) {
    if (containerIds.isEmpty) {
      return const <String, String>{};
    }
    final assignments = baseAssignments ?? state.ingredientContainerAssignments;
    final firstContainerId = containerIds.first;
    final containerIdSet = containerIds.toSet();
    final nextAssignments = <String, String>{};
    for (final row in assignableCookingFlowFinalizeRows(summaryIngredients)) {
      final assignedContainerId = assignments[row.key];
      nextAssignments[row.key] =
          assignedContainerId != null &&
              containerIdSet.contains(assignedContainerId)
          ? assignedContainerId
          : firstContainerId;
    }
    return nextAssignments;
  }

  /// Saves final meal and moves wizard to success on success.
  Future<CookingFlowFinalizeSaveResult> finalizeMeal({
    required PreparedMeal template,
    required int finalPortions,
    required List<CookingFlowFinalizeStorageContainerInput> containers,
  }) async {
    final result = await ref
        .read(cookingFlowControllerProvider.notifier)
        .finalizeMeal(
          template: template,
          summaryIngredients: state.summaryIngredients,
          introDraft: state.introDraft,
          targetPortions: state.targetRecipePortions,
          finalPortions: finalPortions,
          containers: containers,
          ingredientContainerAssignments: state.ingredientContainerAssignments,
        );
    if (!ref.mounted || !result.isSuccess) {
      return result;
    }
    state = state.copyWith(
      savedPreparedMealId: result.preparedMealId,
      savedPreparedMealName: result.containerCount <= 1 ? template.name : null,
      savedContainerCount: result.containerCount,
      step: CookingFlowStep.success,
    );
    return result;
  }

  /// Clears session and resets wizard state.
  Future<void> restartSession() async {
    await ref.read(cookingFlowWizardSessionServiceProvider).clearSession();
    if (!ref.mounted) {
      return;
    }
    state = const CookingFlowWizardState.initial().copyWith(
      isRestoringSession: false,
      introResetSignal: state.introResetSignal + 1,
    );
  }

  /// Saves current session.
  Future<bool> saveSession(CookingFlowWizardSessionInput input) async {
    return ref
        .read(cookingFlowWizardSessionServiceProvider)
        .saveSession(state: state, input: input);
  }

  /// Persists session without surfacing errors.
  void persistSessionSilently(CookingFlowWizardSessionInput input) {
    ref
        .read(cookingFlowWizardSessionServiceProvider)
        .persistSessionSilently(
          state: state,
          input: input,
        );
  }
}
