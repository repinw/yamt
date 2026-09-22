import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_intro_inventory_controller.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_assignment.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_widgets.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Coordinates inventory checking interactions and mutations during intro step.
class CookingFlowInventoryCheckCoordinator {
  /// Creates a coordinator for inventory check actions.
  const new({
    required this.context,
    required this.ref,
    required this.inventoryItems,
    required this.localeCode,
    required this.shoppingBaselineInventoryItemIds,
    required this.rowKeys,
    required this.onShoppingLabelsResolved,
    required this.onSelectionStateChanged,
  });

  /// Build context used for bottom sheets and scrolling.
  final BuildContext context;

  /// Riverpod ref used to read controllers.
  final WidgetRef ref;

  /// Available inventory items.
  final List<InventoryItem> inventoryItems;

  /// Active locale code for formatting.
  final String localeCode;

  /// Baseline item IDs for shopping list resolution.
  final List<String> shoppingBaselineInventoryItemIds;

  /// Keys associated with inventory rows for auto-scrolling.
  final List<GlobalKey> rowKeys;

  /// Callback when shopping labels are resolved.
  final Future<void> Function(List<String> labels) onShoppingLabelsResolved;

  /// Callback when the overall selection state changes.
  final ValueChanged<CookingFlowIntroSelectionState> onSelectionStateChanged;

  /// Builds a [CookingFlowInventoryCheckRow] for the specified index.
  Widget buildRow({
    required int index,
    required Key key,
    required CookingFlowIntroInventoryState inventoryState,
  }) {
    final suggestedItem = suggestedInventoryItemForIndex(index);
    return CookingFlowInventoryCheckRow(
      key: key,
      row: inventoryState.rows[index],
      selectedAction: inventoryState.selectedActions[index],
      selectedSelections: inventoryState.selectedInventorySelections[index],
      inventoryItems: inventoryItems,
      localeCode: localeCode,
      conflict: conflictForIndex(index),
      conflictResolution: inventoryState.conflictResolutions[index],
      suggestedItem: suggestedItem,
      onAssignPressed: () => selectInventoryItem(index),
      onEditPressed: () => editIngredient(index),
      onShoppingPressed: () => selectAction(
        index,
        CookingFlowInventoryRowAction.shoppingCart,
      ),
      onIgnorePressed: () =>
          selectAction(index, CookingFlowInventoryRowAction.ignored),
      onBuyRemainingPressed: () => setConflictResolution(
        index,
        CookingFlowInventoryConflictResolution.buyRemaining,
      ),
      onAdjustTemplatePressed: () => setConflictResolution(
        index,
        CookingFlowInventoryConflictResolution.adjustTemplate,
      ),
      onConvertUnitPressed: (amountPerPiece) =>
          convertUnitConflict(index, amountPerPiece),
      onWeighLaterPressed: () => weighUnitConflictLater(index),
      onApplySuggestedItem: suggestedItem == null
          ? null
          : () => applySuggestedInventoryItem(
              index: index,
              itemId: suggestedItem.id,
            ),
    );
  }

  /// Selects a row action (e.g. shopping cart, ignored).
  void selectAction(int index, CookingFlowInventoryRowAction action) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .selectAction(index, action);
    notifySelectionState();
    scrollToNextRow(index);
  }

  /// Opens the assignment bottom sheet and applies chosen inventory items.
  Future<void> selectInventoryItem(int index) async {
    final state = ref.read(cookingFlowIntroInventoryControllerProvider);
    final selections = await showCookingFlowInventoryAssignmentSheet(
      context: context,
      ingredient: state.rows[index].name,
      inventoryItems: inventoryItems,
      localeCode: localeCode,
      initialSelections: state.selectedInventorySelections[index],
    );
    if (!context.mounted || selections == null) {
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = container.read(
      cookingFlowIntroInventoryControllerProvider.notifier,
    );
    final resolvedShoppingLabels = notifier.shoppingLabelsResolvedByAssignment(
      index: index,
      nextSelections: selections,
      inventoryItems: inventoryItems,
    );
    notifier.setInventorySelections(index: index, selections: selections);
    notifySelectionState();
    if (resolvedShoppingLabels.isNotEmpty) {
      unawaited(onShoppingLabelsResolved(resolvedShoppingLabels));
    }
    if (selections.isNotEmpty) {
      scrollToNextRow(index);
    }
  }

  /// Returns a suggested item for the row at [index], if one exists.
  InventoryItem? suggestedInventoryItemForIndex(int index) {
    return ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .suggestedInventoryItem(
          index: index,
          baselineInventoryItemIds: shoppingBaselineInventoryItemIds,
          inventoryItems: inventoryItems,
        );
  }

  /// Applies the suggested inventory item to the row at [index].
  void applySuggestedInventoryItem({
    required int index,
    required String itemId,
  }) {
    final state = ref.read(cookingFlowIntroInventoryControllerProvider);
    final action = state.selectedActions[index];
    final nextSelections = <CookingFlowInventoryAssignmentSelection>[
      if (action == CookingFlowInventoryRowAction.assigned)
        ...state.selectedInventorySelections[index],
      CookingFlowInventoryAssignmentSelection(itemId: itemId),
    ];
    final notifier = ref.read(
      cookingFlowIntroInventoryControllerProvider.notifier,
    );
    final resolvedShoppingLabels = notifier.shoppingLabelsResolvedByAssignment(
      index: index,
      nextSelections: nextSelections,
      inventoryItems: inventoryItems,
    );
    notifier.applySuggestedInventoryItem(index: index, itemId: itemId);
    notifySelectionState();
    if (resolvedShoppingLabels.isNotEmpty) {
      unawaited(onShoppingLabelsResolved(resolvedShoppingLabels));
    }
    scrollToNextRow(index);
  }

  /// Opens the ingredient edit sheet and updates the row upon confirmation.
  Future<void> editIngredient(int index) async {
    final state = ref.read(cookingFlowIntroInventoryControllerProvider);
    final editedRow = await showCookingFlowIngredientEditSheet(
      context: context,
      row: state.rows[index],
    );
    if (!context.mounted || editedRow == null) {
      return;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    container
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .editRow(index: index, row: editedRow);
    notifySelectionState();
  }

  /// Converts a unit conflict with a piece amount.
  void convertUnitConflict(int index, double amountPerPiece) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .convertUnitConflict(
          index: index,
          amountPerPiece: amountPerPiece,
          inventoryItems: inventoryItems,
        );
    notifySelectionState();
  }

  /// Defers unit conflict weighing until later in the flow.
  void weighUnitConflictLater(int index) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .weighUnitConflictLater(index: index, inventoryItems: inventoryItems);
    notifySelectionState();
  }

  /// Sets the conflict resolution for row at [index].
  void setConflictResolution(
    int index,
    CookingFlowInventoryConflictResolution resolution,
  ) {
    ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .setConflictResolution(index: index, resolution: resolution);
    notifySelectionState();
  }

  /// Resolves the conflict for the row at [index], if one exists.
  CookingFlowInventoryCheckConflict? conflictForIndex(int index) {
    return ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .conflictForIndex(index, inventoryItems);
  }

  /// Emits the updated selection state to [onSelectionStateChanged].
  void notifySelectionState() {
    notifySelectionStateWith(
      ref: ref,
      inventoryItems: inventoryItems,
      onSelectionStateChanged: onSelectionStateChanged,
    );
  }

  /// Static helper to notify selection state when coordinator is not in scope.
  static void notifySelectionStateWith({
    required WidgetRef ref,
    required List<InventoryItem> inventoryItems,
    required ValueChanged<CookingFlowIntroSelectionState>
        onSelectionStateChanged,
  }) {
    final selectionState = ref
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .selectionState(inventoryItems);
    onSelectionStateChanged(selectionState);
  }

  /// Scrolls to ensure the next row is visible.
  void scrollToNextRow(int index) {
    final nextIndex = index + 1;
    if (nextIndex >= rowKeys.length) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      final nextContext = rowKeys[nextIndex].currentContext;
      if (nextContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        nextContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
      );
    });
  }
}
