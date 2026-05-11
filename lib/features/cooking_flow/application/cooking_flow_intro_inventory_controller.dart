import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'cooking_flow_intro_inventory_controller.g.dart';

/// Input used to initialize the intro inventory controller.
class CookingFlowIntroInventoryInput {
  /// Creates intro inventory input.
  const CookingFlowIntroInventoryInput({
    required this.template,
    required this.targetPortions,
    required this.localeCode,
    required this.initialDraft,
  });

  /// Current recipe template.
  final PreparedMeal template;

  /// Selected target portions.
  final int targetPortions;

  /// Active language code.
  final String localeCode;

  /// Persisted/restored draft.
  final CookingFlowIntroDraft? initialDraft;
}

/// State for intro inventory assignment rows.
class CookingFlowIntroInventoryState {
  /// Creates intro inventory state.
  const CookingFlowIntroInventoryState({
    this.rows = const <CookingFlowInventoryCheckRowData>[],
    this.selectedActions = const <CookingFlowInventoryRowAction?>[],
    this.selectedInventorySelections =
        const <List<CookingFlowInventoryAssignmentSelection>>[],
    this.conflictResolutions =
        const <CookingFlowInventoryConflictResolution?>[],
    this.localeCode = '',
  });

  /// Ingredient rows.
  final List<CookingFlowInventoryCheckRowData> rows;

  /// Selected action by row.
  final List<CookingFlowInventoryRowAction?> selectedActions;

  /// Inventory selections by row.
  final List<List<CookingFlowInventoryAssignmentSelection>>
  selectedInventorySelections;

  /// Conflict resolutions by row.
  final List<CookingFlowInventoryConflictResolution?> conflictResolutions;

  /// Active language code.
  final String localeCode;

  /// Whether any row has a selected action.
  bool get hasAnySelections {
    return selectedActions.any((action) => action != null);
  }
}

/// Controls intro inventory assignment state.
@riverpod
class CookingFlowIntroInventoryController
    extends _$CookingFlowIntroInventoryController {
  @override
  CookingFlowIntroInventoryState build() {
    return const CookingFlowIntroInventoryState();
  }

  /// Initializes rows and applies draft.
  void sync(
    CookingFlowIntroInventoryInput input, {
    CookingFlowIntroDraft? draft,
  }) {
    final rows = _buildRows(input);
    final nextState = _stateWithRows(
      rows: rows,
      localeCode: input.localeCode,
      draft: draft ?? input.initialDraft,
    );
    state = nextState;
  }

  /// Selects row action.
  void selectAction(int index, CookingFlowInventoryRowAction action) {
    if (!_hasRow(index)) {
      return;
    }
    final actions = List<CookingFlowInventoryRowAction?>.from(
      state.selectedActions,
    );
    final selections = _selectionMatrixCopy();
    final resolutions = List<CookingFlowInventoryConflictResolution?>.from(
      state.conflictResolutions,
    );
    actions[index] = action;
    resolutions[index] = null;
    if (action != CookingFlowInventoryRowAction.assigned) {
      selections[index] = const <CookingFlowInventoryAssignmentSelection>[];
    }
    _updateState(
      selectedActions: actions,
      selectedInventorySelections: selections,
      conflictResolutions: resolutions,
    );
  }

  /// Replaces row inventory selections.
  void setInventorySelections({
    required int index,
    required List<CookingFlowInventoryAssignmentSelection> selections,
  }) {
    if (!_hasRow(index)) {
      return;
    }
    final actions = List<CookingFlowInventoryRowAction?>.from(
      state.selectedActions,
    );
    final nextSelections = _selectionMatrixCopy();
    final resolutions = List<CookingFlowInventoryConflictResolution?>.from(
      state.conflictResolutions,
    );
    actions[index] = selections.isEmpty
        ? null
        : CookingFlowInventoryRowAction.assigned;
    nextSelections[index] = List.unmodifiable(selections);
    resolutions[index] = null;
    _updateState(
      selectedActions: actions,
      selectedInventorySelections: nextSelections,
      conflictResolutions: resolutions,
    );
  }

  /// Adds suggested inventory item to row.
  void applySuggestedInventoryItem({
    required int index,
    required String itemId,
  }) {
    if (!_hasRow(index)) {
      return;
    }
    final action = state.selectedActions[index];
    final selections = switch (action) {
      CookingFlowInventoryRowAction.assigned =>
        <CookingFlowInventoryAssignmentSelection>[
          ...state.selectedInventorySelections[index],
          CookingFlowInventoryAssignmentSelection(itemId: itemId),
        ],
      _ => <CookingFlowInventoryAssignmentSelection>[
        CookingFlowInventoryAssignmentSelection(itemId: itemId),
      ],
    };
    setInventorySelections(index: index, selections: selections);
  }

  /// Applies edited row.
  void editRow({
    required int index,
    required CookingFlowInventoryCheckRowData row,
  }) {
    if (!_hasRow(index)) {
      return;
    }
    final rows = List<CookingFlowInventoryCheckRowData>.from(state.rows);
    final resolutions = List<CookingFlowInventoryConflictResolution?>.from(
      state.conflictResolutions,
    );
    rows[index] = row;
    resolutions[index] = null;
    _updateState(rows: rows, conflictResolutions: resolutions);
  }

  /// Converts piece requirement to selected amount unit.
  void convertUnitConflict({
    required int index,
    required double amountPerPiece,
    required List<InventoryItem> inventoryItems,
  }) {
    if (!_hasRow(index)) {
      return;
    }
    final row = state.rows[index];
    final requirement = cookingFlowParseInventoryRequirement(
      row.amountLabel,
      localeCode: state.localeCode,
    );
    if (requirement == null) {
      return;
    }
    final selectedItems = selectedInventoryItems(
      index: index,
      inventoryItems: inventoryItems,
    );
    final unitCode = cookingFlowSelectedUnitConflictCode(
      selectedItems: selectedItems,
      requirement: requirement,
    );
    if (unitCode == null) {
      return;
    }
    final convertedAmount = requirement.amount * amountPerPiece;
    editRow(
      index: index,
      row: row.copyWith(
        amountLabel: '${formatCookingFlowDecimal(convertedAmount)} $unitCode',
        isEdited: true,
      ),
    );
  }

  /// Marks row to be weighed later.
  void weighUnitConflictLater({
    required int index,
    required List<InventoryItem> inventoryItems,
  }) {
    if (!_hasRow(index)) {
      return;
    }
    final row = state.rows[index];
    final requirement = cookingFlowParseInventoryRequirement(
      row.amountLabel,
      localeCode: state.localeCode,
    );
    if (requirement == null) {
      return;
    }
    final selectedItems = selectedInventoryItems(
      index: index,
      inventoryItems: inventoryItems,
    );
    final unitCode = cookingFlowSelectedUnitConflictCode(
      selectedItems: selectedItems,
      requirement: requirement,
    );
    if (unitCode == null) {
      return;
    }
    final rows = List<CookingFlowInventoryCheckRowData>.from(state.rows);
    final resolutions = List<CookingFlowInventoryConflictResolution?>.from(
      state.conflictResolutions,
    );
    rows[index] = row.copyWith(amountLabel: '0 $unitCode', isEdited: true);
    resolutions[index] = CookingFlowInventoryConflictResolution.weighLater;
    _updateState(rows: rows, conflictResolutions: resolutions);
  }

  /// Sets conflict resolution for a row.
  void setConflictResolution({
    required int index,
    required CookingFlowInventoryConflictResolution resolution,
  }) {
    if (!_hasRow(index)) {
      return;
    }
    final resolutions = List<CookingFlowInventoryConflictResolution?>.from(
      state.conflictResolutions,
    );
    resolutions[index] = resolution;
    _updateState(conflictResolutions: resolutions);
  }

  /// Returns selected inventory items for row.
  List<InventoryItem> selectedInventoryItems({
    required int index,
    required List<InventoryItem> inventoryItems,
  }) {
    if (!_hasRow(index)) {
      return const <InventoryItem>[];
    }
    return cookingFlowResolveSelectedInventoryItems(
      selectedSelections: state.selectedInventorySelections[index],
      inventoryItems: inventoryItems,
    );
  }

  /// Finds suggested inventory item for row.
  InventoryItem? suggestedInventoryItem({
    required int index,
    required List<String> baselineInventoryItemIds,
    required List<InventoryItem> inventoryItems,
  }) {
    if (!_hasRow(index)) {
      return null;
    }
    final baselineIds = baselineInventoryItemIds.toSet();
    if (baselineIds.isEmpty) {
      return null;
    }

    final action = state.selectedActions[index];
    final resolution = state.conflictResolutions[index];
    final needsSuggestion =
        action == CookingFlowInventoryRowAction.shoppingCart ||
        (action == CookingFlowInventoryRowAction.assigned &&
            resolution == CookingFlowInventoryConflictResolution.buyRemaining);
    if (!needsSuggestion) {
      return null;
    }

    final selectedItemIds = state.selectedInventorySelections[index]
        .map((selection) => selection.itemId)
        .toSet();
    final rankedItems = matchInventoryItemsForIngredient(
      ingredient: state.rows[index].name,
      inventoryItems: inventoryItems,
      localeCode: state.localeCode,
    );
    for (final item in rankedItems) {
      if (baselineIds.contains(item.id)) {
        continue;
      }
      if (selectedItemIds.contains(item.id)) {
        continue;
      }
      return item;
    }
    return null;
  }

  /// Returns shopping labels resolved by a new assignment.
  List<String> shoppingLabelsResolvedByAssignment({
    required int index,
    required List<CookingFlowInventoryAssignmentSelection> nextSelections,
    required List<InventoryItem> inventoryItems,
  }) {
    final previousLabel = shoppingListLabelForIndex(index, inventoryItems);
    if (previousLabel == null || nextSelections.isEmpty) {
      return const <String>[];
    }

    final previousAction = state.selectedActions[index];
    final previousConflictResolution = state.conflictResolutions[index];
    final wasShoppingRelated =
        previousAction == CookingFlowInventoryRowAction.shoppingCart ||
        (previousAction == CookingFlowInventoryRowAction.assigned &&
            previousConflictResolution ==
                CookingFlowInventoryConflictResolution.buyRemaining);
    if (!wasShoppingRelated) {
      return const <String>[];
    }

    final nextConflict = cookingFlowInventoryConflictForRow(
      row: state.rows[index],
      selectedSelections: nextSelections,
      inventoryItems: inventoryItems,
      localeCode: state.localeCode,
    );
    if (nextConflict != null) {
      return const <String>[];
    }
    return <String>[previousLabel];
  }

  /// Builds current selection state.
  CookingFlowIntroSelectionState selectionState(List<InventoryItem> items) {
    return CookingFlowIntroSelectionState(
      allItemsSelected: state.selectedActions.every((action) => action != null),
      hasShoppingSelections: currentShoppingListLabels(items).isNotEmpty,
      hasUnresolvedConflicts: hasUnresolvedConflicts(items),
      shoppingListLabels: currentShoppingListLabels(items),
      draft: currentDraft(),
    );
  }

  /// Builds current intro draft.
  CookingFlowIntroDraft currentDraft() {
    return CookingFlowIntroDraft(
      rowStates: List<CookingFlowIntroRowDraft>.generate(
        state.rows.length,
        (index) => CookingFlowIntroRowDraft(
          rawIngredient: state.rows[index].rawIngredient,
          action: cookingFlowSessionIntroRowAction(
            state.selectedActions[index],
          ),
          selections: state.selectedInventorySelections[index]
              .map(cookingFlowSessionIntroSelectionDraft)
              .toList(growable: false),
          conflictResolution: cookingFlowSessionConflictResolution(
            state.conflictResolutions[index],
          ),
          editedName: state.rows[index].isEdited
              ? state.rows[index].name
              : null,
          editedAmountLabel: state.rows[index].isEdited
              ? state.rows[index].amountLabel
              : null,
        ),
      ),
    );
  }

  /// Returns current shopping-list labels.
  List<String> currentShoppingListLabels(List<InventoryItem> inventoryItems) {
    return List<String>.unmodifiable(
      List<int>.generate(state.rows.length, (index) => index)
          .map((index) => shoppingListLabelForIndex(index, inventoryItems))
          .whereType<String>()
          .toList(growable: false),
    );
  }

  /// Whether current rows have unresolved conflicts.
  bool hasUnresolvedConflicts(List<InventoryItem> inventoryItems) {
    return List<int>.generate(state.rows.length, (index) => index).any((index) {
      return conflictForIndex(index, inventoryItems) != null &&
          state.conflictResolutions[index] == null;
    });
  }

  /// Returns shopping-list label for row.
  String? shoppingListLabelForIndex(
    int index,
    List<InventoryItem> inventoryItems,
  ) {
    if (!_hasRow(index)) {
      return null;
    }
    final row = state.rows[index];
    final action = state.selectedActions[index];
    if (action == CookingFlowInventoryRowAction.shoppingCart) {
      return cookingFlowShoppingListLabelForRow(row);
    }
    if (action != CookingFlowInventoryRowAction.assigned ||
        state.conflictResolutions[index] !=
            CookingFlowInventoryConflictResolution.buyRemaining) {
      return null;
    }

    final conflict = conflictForIndex(index, inventoryItems);
    if (conflict == null) {
      return null;
    }
    return '${conflict.missingAmountLabel} ${row.name}';
  }

  /// Returns conflict for row.
  CookingFlowInventoryCheckConflict? conflictForIndex(
    int index,
    List<InventoryItem> inventoryItems,
  ) {
    if (!_hasRow(index) ||
        state.selectedActions[index] !=
            CookingFlowInventoryRowAction.assigned) {
      return null;
    }
    return cookingFlowInventoryConflictForRow(
      row: state.rows[index],
      selectedSelections: state.selectedInventorySelections[index],
      inventoryItems: inventoryItems,
      localeCode: state.localeCode,
    );
  }

  CookingFlowIntroInventoryState _stateWithRows({
    required List<CookingFlowInventoryCheckRowData> rows,
    required String localeCode,
    required CookingFlowIntroDraft? draft,
  }) {
    final nextState = CookingFlowIntroInventoryState(
      rows: List.unmodifiable(rows),
      selectedActions: List<CookingFlowInventoryRowAction?>.filled(
        rows.length,
        null,
      ),
      selectedInventorySelections:
          List<List<CookingFlowInventoryAssignmentSelection>>.generate(
            rows.length,
            (_) => const <CookingFlowInventoryAssignmentSelection>[],
          ),
      conflictResolutions: List<CookingFlowInventoryConflictResolution?>.filled(
        rows.length,
        null,
      ),
      localeCode: localeCode,
    );
    state = nextState;
    _applyInitialDraft(draft);
    return state;
  }

  List<CookingFlowInventoryCheckRowData> _buildRows(
    CookingFlowIntroInventoryInput input,
  ) {
    if (input.template.components.isNotEmpty) {
      return input.template.components
          .map(
            (component) => CookingFlowInventoryCheckRowData(
              rawIngredient:
                  '${component.usedAmount}${component.usedUnit.code} '
                  '${component.name}',
              name: component.name,
              amountLabel: _scaledComponentAmountLabel(component, input),
              imageUrl:
                  component.imageUrl ?? component.sourceItemSnapshot.imageUrl,
            ),
          )
          .toList();
    }
    return input.template.recipeIngredients
        .map((ingredient) => _rowFromRecipeIngredient(ingredient, input))
        .toList();
  }

  CookingFlowInventoryCheckRowData _rowFromRecipeIngredient(
    String ingredient,
    CookingFlowIntroInventoryInput input,
  ) {
    final trimmed = ingredient.trim();
    final requirement = const TemplateIngredientParser().parseRequirement(
      ingredient: ingredient,
      selectedPortions: input.targetPortions,
      basePortions: input.template.totalPortions,
    );
    if (requirement != null) {
      final fractionalPieceAmount = requirement.unit.code == 'pc'
          ? _fractionalPieceAmountLabel(ingredient, input)
          : null;
      return CookingFlowInventoryCheckRowData(
        rawIngredient: ingredient,
        name: requirement.name,
        amountLabel:
            fractionalPieceAmount ??
            _cookflowIntroRequirementAmountLabel(requirement),
      );
    }

    final unitPattern = cookingFlowKnownAmountUnitsPatternForLocale(
      input.localeCode,
    );
    final amountWithUnitMatch = RegExp(
      '^('
      r'\d+(?:[.,]\d+)?'
      '(?:\\s?(?:$unitPattern))'
      r')\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (amountWithUnitMatch != null) {
      return CookingFlowInventoryCheckRowData(
        rawIngredient: ingredient,
        name: amountWithUnitMatch.group(2)!.trim(),
        amountLabel: amountWithUnitMatch.group(1)!.trim(),
      );
    }

    final amountOnlyMatch = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s+(.+)$',
    ).firstMatch(trimmed);
    if (amountOnlyMatch != null) {
      return CookingFlowInventoryCheckRowData(
        rawIngredient: ingredient,
        name: amountOnlyMatch.group(2)!.trim(),
        amountLabel: amountOnlyMatch.group(1)!.trim(),
      );
    }

    return CookingFlowInventoryCheckRowData(
      rawIngredient: ingredient,
      name: trimmed,
      amountLabel: '',
    );
  }

  String? _fractionalPieceAmountLabel(
    String ingredient,
    CookingFlowIntroInventoryInput input,
  ) {
    final match = RegExp(
      r'^(\d+(?:[.,]\d+)?|\d+/\d+|\d+\s+\d+/\d+)\s+',
    ).firstMatch(ingredient.trim());
    final rawAmount = match?.group(1);
    if (rawAmount == null) {
      return null;
    }
    final parsedAmount = parseCookingFlowQuantity(rawAmount);
    if (parsedAmount == null || input.template.totalPortions < 1) {
      return null;
    }
    final scaledAmount =
        parsedAmount * input.targetPortions / input.template.totalPortions;
    if (scaledAmount == scaledAmount.roundToDouble()) {
      return null;
    }
    return formatCookingFlowDecimal(scaledAmount);
  }

  String _scaledComponentAmountLabel(
    PreparedMealComponent component,
    CookingFlowIntroInventoryInput input,
  ) {
    final basePortions = input.template.totalPortions;
    final selectedPortions = input.targetPortions;
    if (basePortions < 1 || selectedPortions < 1) {
      return '${component.usedAmount}${component.usedUnit.code}';
    }
    final scaledAmount =
        (component.usedAmount * selectedPortions / basePortions).round();
    return '$scaledAmount${component.usedUnit.code}';
  }

  String _cookflowIntroRequirementAmountLabel(
    TemplateIngredientRequirement requirement,
  ) {
    final packageCountLabel = requirement.packageCountLabel?.trim();
    if (packageCountLabel?.isNotEmpty == true &&
        requirement.unit.code != 'pc') {
      return '$packageCountLabel ${requirement.amount}${requirement.unit.code}';
    }
    final countMeasureLabel = requirement.countMeasureLabel?.trim();
    if (countMeasureLabel?.isNotEmpty == true) {
      return '${requirement.amount} $countMeasureLabel';
    }
    if (requirement.unit.code == 'pc') {
      return requirement.amount.toString();
    }
    return '${requirement.amount} ${requirement.unit.code}';
  }

  void _applyInitialDraft(CookingFlowIntroDraft? draft) {
    if (draft == null || draft.rowStates.isEmpty) {
      return;
    }
    final rows = List<CookingFlowInventoryCheckRowData>.from(state.rows);
    final actions = List<CookingFlowInventoryRowAction?>.from(
      state.selectedActions,
    );
    final selections = _selectionMatrixCopy();
    final resolutions = List<CookingFlowInventoryConflictResolution?>.from(
      state.conflictResolutions,
    );

    final draftByIngredient = <String, CookingFlowIntroRowDraft>{
      for (final rowState in draft.rowStates) rowState.rawIngredient: rowState,
    };
    for (var index = 0; index < rows.length; index++) {
      final rowDraft = draftByIngredient[rows[index].rawIngredient];
      if (rowDraft == null) {
        continue;
      }
      actions[index] = cookingFlowInventoryRowAction(rowDraft.action);
      if (rowDraft.editedName?.isNotEmpty == true ||
          rowDraft.editedAmountLabel?.isNotEmpty == true) {
        rows[index] = rows[index].copyWith(
          name: rowDraft.editedName?.isNotEmpty == true
              ? rowDraft.editedName
              : null,
          amountLabel: rowDraft.editedAmountLabel?.isNotEmpty == true
              ? rowDraft.editedAmountLabel
              : null,
          isEdited: true,
        );
      }
      selections[index] = rowDraft.selections
          .map(cookingFlowInventoryAssignmentSelection)
          .toList(growable: false);
      resolutions[index] = cookingFlowInventoryConflictResolution(
        rowDraft.conflictResolution,
      );
    }
    _updateState(
      rows: rows,
      selectedActions: actions,
      selectedInventorySelections: selections,
      conflictResolutions: resolutions,
    );
  }

  bool _hasRow(int index) {
    return index >= 0 && index < state.rows.length;
  }

  List<List<CookingFlowInventoryAssignmentSelection>> _selectionMatrixCopy() {
    return state.selectedInventorySelections
        .map(List<CookingFlowInventoryAssignmentSelection>.from)
        .toList(growable: false);
  }

  void _updateState({
    List<CookingFlowInventoryCheckRowData>? rows,
    List<CookingFlowInventoryRowAction?>? selectedActions,
    List<List<CookingFlowInventoryAssignmentSelection>>?
    selectedInventorySelections,
    List<CookingFlowInventoryConflictResolution?>? conflictResolutions,
  }) {
    state = CookingFlowIntroInventoryState(
      rows: List.unmodifiable(rows ?? state.rows),
      selectedActions: List.unmodifiable(
        selectedActions ?? state.selectedActions,
      ),
      selectedInventorySelections: List.unmodifiable(
        selectedInventorySelections ?? state.selectedInventorySelections,
      ),
      conflictResolutions: List.unmodifiable(
        conflictResolutions ?? state.conflictResolutions,
      ),
      localeCode: state.localeCode,
    );
  }
}
