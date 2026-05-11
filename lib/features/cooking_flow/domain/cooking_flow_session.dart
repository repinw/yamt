import 'package:json_annotation/json_annotation.dart';

part 'cooking_flow_session.g.dart';

/// Persisted step for a cookflow session.
enum CookingFlowSessionStep {
  /// Intro step.
  start,

  /// Preparation step.
  preparation,

  /// Cooking step.
  cooking,

  /// Summary step.
  summary,

  /// Finalize step.
  finalize,
}

/// Persisted intro action choice for one ingredient row.
enum CookingFlowIntroRowAction {
  /// Assigned to inventory.
  assigned,

  /// Sent to shopping list.
  shoppingCart,

  /// Ignored by user.
  ignored,
}

/// Persisted resolution for an inventory conflict.
enum CookingFlowIntroConflictResolution {
  /// Buy missing rest.
  buyRemaining,

  /// Adjust recipe to available amount.
  adjustTemplate,

  /// Weigh converted amount later in the current cooking flow.
  weighLater,
}

/// Persisted summary row kind.
enum CookingFlowSummaryIngredientKind {
  /// Base recipe ingredient.
  template,

  /// Extra inventory item.
  additional,
}

/// Persisted inventory assignment selection.
@JsonSerializable(fieldRename: FieldRename.snake)
class CookingFlowIntroSelectionDraft {
  /// Creates selection draft.
  const CookingFlowIntroSelectionDraft({
    required this.itemId,
    this.isAdditionalIngredient = false,
  });

  /// Restores selection draft from json.
  factory CookingFlowIntroSelectionDraft.fromJson(
    Map<String, dynamic> json,
  ) => _$CookingFlowIntroSelectionDraftFromJson(json);

  /// Selected inventory item id.
  final String itemId;

  /// Whether entry was added via "Zutat hinzufuegen".
  final bool isAdditionalIngredient;

  /// Serializes draft.
  Map<String, dynamic> toJson() => _$CookingFlowIntroSelectionDraftToJson(this);
}

/// Persisted state for one intro ingredient row.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CookingFlowIntroRowDraft {
  /// Creates row draft.
  const CookingFlowIntroRowDraft({
    required this.rawIngredient,
    this.action,
    this.selections = const <CookingFlowIntroSelectionDraft>[],
    this.conflictResolution,
    this.editedName,
    this.editedAmountLabel,
  });

  /// Restores row draft from json.
  factory CookingFlowIntroRowDraft.fromJson(Map<String, dynamic> json) =>
      _$CookingFlowIntroRowDraftFromJson(json);

  /// Source ingredient label.
  final String rawIngredient;

  /// Selected row action.
  final CookingFlowIntroRowAction? action;

  /// Selected inventory items.
  final List<CookingFlowIntroSelectionDraft> selections;

  /// Selected conflict resolution.
  final CookingFlowIntroConflictResolution? conflictResolution;

  /// Flow-local edited ingredient name.
  final String? editedName;

  /// Flow-local edited ingredient amount label.
  final String? editedAmountLabel;

  /// Serializes row draft.
  Map<String, dynamic> toJson() => _$CookingFlowIntroRowDraftToJson(this);
}

/// Persisted intro draft state.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CookingFlowIntroDraft {
  /// Creates intro draft.
  const CookingFlowIntroDraft({
    this.rowStates = const <CookingFlowIntroRowDraft>[],
  });

  /// Restores intro draft from json.
  factory CookingFlowIntroDraft.fromJson(Map<String, dynamic> json) =>
      _$CookingFlowIntroDraftFromJson(json);

  /// Persisted row states.
  final List<CookingFlowIntroRowDraft> rowStates;

  /// Serializes intro draft.
  Map<String, dynamic> toJson() => _$CookingFlowIntroDraftToJson(this);
}

/// Persisted summary ingredient draft.
@JsonSerializable(fieldRename: FieldRename.snake)
class CookingFlowSummaryIngredientSessionDraft {
  /// Creates summary ingredient draft.
  const CookingFlowSummaryIngredientSessionDraft({
    required this.key,
    required this.name,
    required this.amount,
    required this.unitCode,
    required this.inventoryItemIds,
    required this.kind,
    this.sourceIngredient,
  });

  /// Restores draft from json.
  factory CookingFlowSummaryIngredientSessionDraft.fromJson(
    Map<String, dynamic> json,
  ) => _$CookingFlowSummaryIngredientSessionDraftFromJson(json);

  /// Stable row key.
  final String key;

  /// Ingredient name.
  final String name;

  /// Saved amount text.
  final String amount;

  /// Saved unit label.
  final String unitCode;

  /// Bound inventory item ids.
  final List<String> inventoryItemIds;

  /// Saved row kind.
  final CookingFlowSummaryIngredientKind kind;

  /// Original template ingredient text for template rows.
  final String? sourceIngredient;

  /// Serializes draft.
  Map<String, dynamic> toJson() =>
      _$CookingFlowSummaryIngredientSessionDraftToJson(this);
}

/// Persisted final storage container draft.
@JsonSerializable(fieldRename: FieldRename.snake)
class CookingFlowStorageContainerSessionDraft {
  /// Creates storage container draft.
  const CookingFlowStorageContainerSessionDraft({
    required this.id,
    required this.label,
    required this.taraText,
    required this.grossWeightText,
    required this.portionCount,
    this.taraUtensilId,
  });

  /// Restores draft from json.
  factory CookingFlowStorageContainerSessionDraft.fromJson(
    Map<String, dynamic> json,
  ) => _$CookingFlowStorageContainerSessionDraftFromJson(json);

  /// Stable container id.
  final String id;

  /// User-visible label.
  final String label;

  /// Saved tara input.
  final String taraText;

  /// Saved kitchen utensil id used as tare.
  final String? taraUtensilId;

  /// Saved gross weight input.
  final String grossWeightText;

  /// Saved portion count for this saved meal.
  final double portionCount;

  /// Serializes draft.
  Map<String, dynamic> toJson() =>
      _$CookingFlowStorageContainerSessionDraftToJson(this);
}

/// Persisted cookflow session snapshot.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CookingFlowSession {
  /// Creates session.
  const CookingFlowSession({
    required this.templateId,
    required this.step,
    required this.taraText,
    required this.adjustmentInputText,
    required this.adjustments,
    required this.summaryIngredients,
    required this.grossWeightText,
    required this.splitIntoPortions,
    required this.portionCount,
    required this.introDraft,
    required this.introShoppingHandled,
    required this.introShoppingBaselineInventoryItemIds,
    this.finalPortionCount,
    this.storageContainers = const <CookingFlowStorageContainerSessionDraft>[],
    this.ingredientContainerAssignments = const <String, String>{},
    this.taraUtensilId,
  });

  /// Restores session from json.
  factory CookingFlowSession.fromJson(Map<String, dynamic> json) =>
      _$CookingFlowSessionFromJson(json);

  /// Current template id.
  final String templateId;

  /// Saved cookflow step.
  final CookingFlowSessionStep step;

  /// Saved tara input.
  final String taraText;

  /// Saved kitchen utensil id used as tare.
  final String? taraUtensilId;

  /// Saved on-the-fly input text.
  final String adjustmentInputText;

  /// Saved on-the-fly notes.
  final List<String> adjustments;

  /// Saved summary ingredient edits.
  final List<CookingFlowSummaryIngredientSessionDraft> summaryIngredients;

  /// Saved gross weight input.
  final String grossWeightText;

  /// Saved portion split toggle.
  final bool splitIntoPortions;

  /// Saved portion slider value.
  final double portionCount;

  /// Saved final serving portion slider value.
  final double? finalPortionCount;

  /// Saved intro row state.
  final CookingFlowIntroDraft introDraft;

  /// Whether shopping list detour already happened.
  final bool introShoppingHandled;

  /// Inventory item ids present before shopping detour started.
  final List<String> introShoppingBaselineInventoryItemIds;

  /// Saved final storage containers.
  final List<CookingFlowStorageContainerSessionDraft> storageContainers;

  /// Summary ingredient row key to storage container id.
  final Map<String, String> ingredientContainerAssignments;

  /// Serializes session.
  Map<String, dynamic> toJson() => _$CookingFlowSessionToJson(this);
}
