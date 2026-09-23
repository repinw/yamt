import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_templates_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/prepared_meal_edit_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _preparedMealImageAssetUuid = Uuid();

class _PendingPreparedMealEditSelection {
  const new({required this.mealId, required this.result});

  final String mealId;
  final PreparedMealEditSheetResult result;
}

/// Coordinates prepared meal edit and ingredient selection flows.
class InventoryPreparedMealEditCoordinator {
  _PendingPreparedMealEditSelection? _pendingEditSelection;
  VoidCallback? _onFocusRequested;

  /// Incremented whenever ingredient selection is triggered to focus list.
  int inventorySelectionFocusToken = 0;

  /// Starts ingredient selection from inventory for a meal edit draft.
  bool startSelection({
    required WidgetRef ref,
    required String mealId,
    required PreparedMealEditSheetResult result,
    VoidCallback? onFocusRequested,
  }) {
    _onFocusRequested = onFocusRequested;
    _pendingEditSelection = _PendingPreparedMealEditSelection(
      mealId: mealId,
      result: result.copyWith(requestIngredientSelection: false),
    );
    ref
        .read(preparedMealSelectionControllerProvider.notifier)
        .startAddIngredientsToMealSelection();
    inventorySelectionFocusToken += 1;
    _onFocusRequested?.call();
    return true;
  }

  /// Continues meal edit flow after ingredients are selected in inventory.
  Future<void> continueWithSelectedIngredients({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMealSelectionState selectionState,
  }) async {
    final pendingSelection = _pendingEditSelection;
    if (pendingSelection == null || selectionState.selectedItemIds.isEmpty) {
      return;
    }

    final items = ref.read(inventoryItemsControllerProvider).asData?.value;
    final meals = ref.read(preparedMealsControllerProvider).asData?.value;
    if (items == null || meals == null || !context.mounted) {
      return;
    }

    final meal = meals.firstWhereOrNull((m) => m.id == pendingSelection.mealId);
    if (meal == null) {
      _pendingEditSelection = null;
      ref
          .read(preparedMealSelectionControllerProvider.notifier)
          .clearSelection();
      return;
    }

    final nextResult = _addSelectedItemsToEditResult(
      result: pendingSelection.result,
      inventoryItems: items,
      selectedItemIds: selectionState.selectedItemIds,
    );
    _pendingEditSelection = null;
    ref.read(preparedMealSelectionControllerProvider.notifier).clearSelection();

    await _openSheetAndHandleResult(
      context: context,
      ref: ref,
      meal: meal,
      items: items,
      initialValue: nextResult,
    );
  }

  Future<void> _openSheetAndHandleResult({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
    required List<InventoryItem> items,
    required PreparedMealEditSheetResult initialValue,
  }) async {
    final editResult = await showPreparedMealEditSheet(
      context: context,
      meal: meal,
      inventoryItems: items,
      initialValue: initialValue,
    );
    if (!context.mounted || editResult == null) {
      return;
    }
    if (editResult.requestIngredientSelection) {
      startSelection(
        ref: ref,
        mealId: meal.id,
        result: editResult,
        onFocusRequested: _onFocusRequested,
      );
      return;
    }
    await updatePreparedMeal(
      context: context,
      ref: ref,
      mealId: meal.id,
      result: editResult,
    );
  }

  /// Updates prepared meal details, including persisting changed images.
  Future<bool> updatePreparedMeal({
    required BuildContext context,
    required WidgetRef ref,
    required String mealId,
    required PreparedMealEditSheetResult result,
  }) async {
    final previous = ref
        .read(preparedMealsControllerProvider)
        .asData
        ?.value
        .firstWhereOrNull((meal) => meal.id == mealId);
    final imageAssetId = await _saveImageBytesIfChanged(ref, result);
    final saved = await ref
        .read(preparedMealsControllerProvider.notifier)
        .updatePreparedMealDetails(
          mealId: mealId,
          name: result.name,
          imageChanged: result.imageChanged,
          imageAssetId: imageAssetId,
          totalPortions: result.totalPortions,
          items: result.items,
        );
    if (!saved || !context.mounted) {
      return saved;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.preparedMealUpdatedMessage,
      onUndo: previous == null
          ? null
          : () => container
                .read(preparedMealsControllerProvider.notifier)
                .updatePreparedMealDetails(
                  mealId: previous.id,
                  name: previous.name,
                  imageChanged: result.imageChanged,
                  imageAssetId: previous.imageAssetId,
                  totalPortions: previous.totalPortions,
                  items: [
                    for (final component in previous.components)
                      PreparedMealItemInput(
                        itemId: component.inventoryItemId,
                        usedAmount: component.usedAmount,
                      ),
                  ],
                ),
    );
    return true;
  }

  Future<String?> _saveImageBytesIfChanged(
    WidgetRef ref,
    PreparedMealEditSheetResult result,
  ) async {
    if (!result.imageChanged || result.imageBytes == null) {
      return null;
    }
    final imageAssetId = _preparedMealImageAssetUuid.v4();
    final imageRef = localImageAssetRef(imageAssetId);
    await ref
        .read(localImageStoreProvider)
        .saveBytes(imageRef: imageRef, bytes: result.imageBytes!);
    ref.invalidate(localImageBytesProvider(imageRef));
    return imageAssetId;
  }

  /// Saves a meal as a reusable prepared meal template.
  Future<bool> saveTemplate({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
  }) async {
    final templatesController = ref.read(
      preparedMealTemplatesControllerProvider.notifier,
    );
    final result = await templatesController.saveTemplateFromMeal(meal);
    final templateId = result.templateId;
    if (!result.isSuccess || templateId == null || !context.mounted) {
      return result.isSuccess;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    ScaffoldMessenger.of(context).showAppSnackBar(
      AppLocalizations.of(context)!.preparedMealTemplateSavedMessage,
      onUndo: () => container
          .read(preparedMealTemplatesControllerProvider.notifier)
          .deleteTemplate(templateId),
    );
    return true;
  }

  PreparedMealEditSheetResult _addSelectedItemsToEditResult({
    required PreparedMealEditSheetResult result,
    required List<InventoryItem> inventoryItems,
    required Set<String> selectedItemIds,
  }) {
    final existingItemIds = result.items.map((item) => item.itemId).toSet();
    final addedInputs = [
      for (final item in inventoryItems)
        if (selectedItemIds.contains(item.id) &&
            !existingItemIds.contains(item.id) &&
            _defaultInventoryItemAmount(item) > 0)
          PreparedMealItemInput(
            itemId: item.id,
            usedAmount: _defaultInventoryItemAmount(item),
          ),
    ];

    return result.copyWith(
      items: <PreparedMealItemInput>[...result.items, ...addedInputs],
      requestIngredientSelection: false,
    );
  }

  int _defaultInventoryItemAmount(InventoryItem item) =>
      item.usesAmountProgress ? item.currentAmount : item.quantity;
}
