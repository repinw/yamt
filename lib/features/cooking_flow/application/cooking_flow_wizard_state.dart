import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';

const Object _keepWizardValue = Object();

/// Local flow steps shown inside cookflow shell.
enum CookingFlowStep {
  /// Start intro screen.
  start,

  /// Phase 1 screen.
  preparation,

  /// Phase 2 screen.
  cooking,

  /// Phase 3 screen.
  summary,

  /// Phase 4 screen.
  finalize,

  /// Save success screen.
  success,
}

/// Intro selection state used by the fixed CTA.
class CookingFlowIntroSelectionState {
  /// Creates intro selection state.
  const CookingFlowIntroSelectionState({
    required this.allItemsSelected,
    required this.hasShoppingSelections,
    required this.hasUnresolvedConflicts,
    required this.shoppingListLabels,
    required this.draft,
  });

  /// Whether every row has a chosen action.
  final bool allItemsSelected;

  /// Whether at least one row uses shopping-cart action.
  final bool hasShoppingSelections;

  /// Whether at least one inventory shortage still needs a decision.
  final bool hasUnresolvedConflicts;

  /// Labels that should be added to shopping list.
  final List<String> shoppingListLabels;

  /// Full intro draft used for session restore.
  final CookingFlowIntroDraft draft;
}

/// Storage input from page-owned text controllers.
class CookingFlowWizardStorageDraftInput {
  /// Creates storage input.
  const CookingFlowWizardStorageDraftInput({
    required this.id,
    required this.label,
    required this.taraText,
    required this.taraUtensilId,
    required this.grossWeightText,
    required this.portionCount,
  });

  /// Stable container id.
  final String id;

  /// User/display label.
  final String label;

  /// Tara text.
  final String taraText;

  /// Selected utensil id.
  final String? taraUtensilId;

  /// Gross weight text.
  final String grossWeightText;

  /// Stored portion count.
  final double portionCount;
}

/// Page-owned transient input needed to persist session.
class CookingFlowWizardSessionInput {
  /// Creates session input.
  const CookingFlowWizardSessionInput({
    required this.templateId,
    required this.taraText,
    required this.taraUtensilId,
    required this.adjustmentInputText,
    required this.grossWeightText,
    required this.storageContainers,
    required this.ingredientContainerAssignments,
  });

  /// Selected template id.
  final String templateId;

  /// Primary tara text.
  final String taraText;

  /// Primary selected utensil id.
  final String? taraUtensilId;

  /// Current adjustment input text.
  final String adjustmentInputText;

  /// Primary gross weight text.
  final String grossWeightText;

  /// Storage containers from UI controllers.
  final List<CookingFlowWizardStorageDraftInput> storageContainers;

  /// Effective ingredient row assignments.
  final Map<String, String> ingredientContainerAssignments;
}

/// Result of adding intro shopping items.
enum CookingFlowShoppingListActionResult {
  /// Items added and state updated.
  success,

  /// Shopping list save failed.
  failed,

  /// Controller disposed while saving.
  disposed,
}

/// Wizard state for cookflow shell.
class CookingFlowWizardState {
  /// Creates state.
  const CookingFlowWizardState({
    required this.step,
    required this.isRestoringSession,
    required this.didInitializePortionsFromTemplate,
    required this.adjustments,
    required this.summaryIngredients,
    required this.summarySourceSignature,
    required this.ingredientContainerAssignments,
    required this.introAllItemsSelected,
    required this.introHasShoppingSelections,
    required this.introHasUnresolvedConflicts,
    required this.introShoppingHandled,
    required this.introShoppingRedirectInProgress,
    required this.introShoppingBaselineInventoryItemIds,
    required this.introShoppingListLabels,
    required this.introResetSignal,
    required this.splitIntoPortions,
    required this.portionCount,
    required this.finalPortionCount,
    required this.savedContainerCount,
    this.introDraft,
    this.savedPreparedMealId,
    this.savedPreparedMealName,
  });

  /// Default state.
  const CookingFlowWizardState.initial()
    : step = CookingFlowStep.start,
      isRestoringSession = true,
      didInitializePortionsFromTemplate = false,
      adjustments = const <String>[],
      summaryIngredients = const <CookingFlowSummaryIngredientDraft>[],
      summarySourceSignature = '',
      ingredientContainerAssignments = const <String, String>{},
      introAllItemsSelected = false,
      introHasShoppingSelections = false,
      introHasUnresolvedConflicts = false,
      introShoppingHandled = false,
      introShoppingRedirectInProgress = false,
      introShoppingBaselineInventoryItemIds = const <String>[],
      introShoppingListLabels = const <String>[],
      introResetSignal = 0,
      splitIntoPortions = false,
      portionCount = 3,
      finalPortionCount = 3,
      savedContainerCount = 0,
      introDraft = null,
      savedPreparedMealId = null,
      savedPreparedMealName = null;

  /// Current step.
  final CookingFlowStep step;

  /// Whether local session restore is pending.
  final bool isRestoringSession;

  /// Whether template portions were copied into wizard state.
  final bool didInitializePortionsFromTemplate;

  /// On-the-fly cooking notes.
  final List<String> adjustments;

  /// Editable summary ingredients.
  final List<CookingFlowSummaryIngredientDraft> summaryIngredients;

  /// Signature used to detect summary source changes.
  final String summarySourceSignature;

  /// Ingredient row key to container id.
  final Map<String, String> ingredientContainerAssignments;

  /// Whether all intro rows have an action.
  final bool introAllItemsSelected;

  /// Whether intro rows include shopping list items.
  final bool introHasShoppingSelections;

  /// Whether intro has unresolved conflicts.
  final bool introHasUnresolvedConflicts;

  /// Whether shopping list detour was completed.
  final bool introShoppingHandled;

  /// Whether shopping list add is running.
  final bool introShoppingRedirectInProgress;

  /// Inventory ids before shopping detour.
  final List<String> introShoppingBaselineInventoryItemIds;

  /// Shopping list labels from intro.
  final List<String> introShoppingListLabels;

  /// Reset signal for intro page.
  final int introResetSignal;

  /// Whether final output is split into portions.
  final bool splitIntoPortions;

  /// Base recipe portions for this flow.
  final double portionCount;

  /// User-selected final portion count.
  final double finalPortionCount;

  /// Restored/current intro draft.
  final CookingFlowIntroDraft? introDraft;

  /// Saved prepared meal id.
  final String? savedPreparedMealId;

  /// Saved prepared meal name.
  final String? savedPreparedMealName;

  /// Number of saved containers/meals.
  final int savedContainerCount;

  /// Resolved base recipe portions.
  int get targetRecipePortions {
    final roundedPortions = portionCount.round();
    return roundedPortions < 1 ? 1 : roundedPortions;
  }

  /// Copy state.
  CookingFlowWizardState copyWith({
    CookingFlowStep? step,
    bool? isRestoringSession,
    bool? didInitializePortionsFromTemplate,
    List<String>? adjustments,
    List<CookingFlowSummaryIngredientDraft>? summaryIngredients,
    String? summarySourceSignature,
    Map<String, String>? ingredientContainerAssignments,
    bool? introAllItemsSelected,
    bool? introHasShoppingSelections,
    bool? introHasUnresolvedConflicts,
    bool? introShoppingHandled,
    bool? introShoppingRedirectInProgress,
    List<String>? introShoppingBaselineInventoryItemIds,
    List<String>? introShoppingListLabels,
    int? introResetSignal,
    bool? splitIntoPortions,
    double? portionCount,
    double? finalPortionCount,
    Object? introDraft = _keepWizardValue,
    Object? savedPreparedMealId = _keepWizardValue,
    Object? savedPreparedMealName = _keepWizardValue,
    int? savedContainerCount,
  }) {
    return CookingFlowWizardState(
      step: step ?? this.step,
      isRestoringSession: isRestoringSession ?? this.isRestoringSession,
      didInitializePortionsFromTemplate:
          didInitializePortionsFromTemplate ??
          this.didInitializePortionsFromTemplate,
      adjustments: adjustments ?? this.adjustments,
      summaryIngredients: summaryIngredients ?? this.summaryIngredients,
      summarySourceSignature:
          summarySourceSignature ?? this.summarySourceSignature,
      ingredientContainerAssignments:
          ingredientContainerAssignments ?? this.ingredientContainerAssignments,
      introAllItemsSelected:
          introAllItemsSelected ?? this.introAllItemsSelected,
      introHasShoppingSelections:
          introHasShoppingSelections ?? this.introHasShoppingSelections,
      introHasUnresolvedConflicts:
          introHasUnresolvedConflicts ?? this.introHasUnresolvedConflicts,
      introShoppingHandled: introShoppingHandled ?? this.introShoppingHandled,
      introShoppingRedirectInProgress:
          introShoppingRedirectInProgress ??
          this.introShoppingRedirectInProgress,
      introShoppingBaselineInventoryItemIds:
          introShoppingBaselineInventoryItemIds ??
          this.introShoppingBaselineInventoryItemIds,
      introShoppingListLabels:
          introShoppingListLabels ?? this.introShoppingListLabels,
      introResetSignal: introResetSignal ?? this.introResetSignal,
      splitIntoPortions: splitIntoPortions ?? this.splitIntoPortions,
      portionCount: portionCount ?? this.portionCount,
      finalPortionCount: finalPortionCount ?? this.finalPortionCount,
      introDraft: introDraft == _keepWizardValue
          ? this.introDraft
          : introDraft as CookingFlowIntroDraft?,
      savedPreparedMealId: savedPreparedMealId == _keepWizardValue
          ? this.savedPreparedMealId
          : savedPreparedMealId as String?,
      savedPreparedMealName: savedPreparedMealName == _keepWizardValue
          ? this.savedPreparedMealName
          : savedPreparedMealName as String?,
      savedContainerCount: savedContainerCount ?? this.savedContainerCount,
    );
  }
}
