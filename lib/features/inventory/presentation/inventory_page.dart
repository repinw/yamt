import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_creation_coordinator.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_edit_sheet.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _deleteUndoSnackBarDuration = Duration(seconds: 5);
const _preparedMealImageAssetUuid = Uuid();

/// Defines inventory page.
@Dependencies([
  inventoryItemRepository,
  InventoryItemsController,
  PreparedMealsController,
  preparedMealImagePicker,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
  inventoryBackedCalorieEntrySaveFlow,
])
class InventoryPage extends ConsumerStatefulWidget {
  /// The inventory page.
  const InventoryPage({super.key, this.expandedPreparedMealId});

  /// The expanded prepared meal id.
  final String? expandedPreparedMealId;

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  _PendingPreparedMealEditSelection? _pendingEditSelection;
  var _inventorySelectionFocusToken = 0;

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(inventoryItemsControllerProvider, _logLoadErrorOnce)
      ..listen(
        preparedMealSelectionControllerProvider.select(
          (state) => state.bindRequestToken,
        ),
        _onSelectionConfirmed,
      );

    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final itemsAsync = ref.watch(inventoryItemsControllerProvider);
    final mealsController = ref.read(preparedMealsControllerProvider.notifier);
    final mealsAsync = ref.watch(preparedMealsControllerProvider);
    final selectionState = ref.watch(preparedMealSelectionControllerProvider);

    if (itemsAsync.isLoading || mealsAsync.isLoading) {
      return const _InventoryLoadingView();
    }

    final itemsError = itemsAsync.asError;
    final mealsError = mealsAsync.asError;
    if (itemsError != null || mealsError != null) {
      return _InventoryErrorView(
        onRetry: () async {
          await controller.refresh();
          await mealsController.refresh();
        },
        message: l10n.inventoryLoadFailed,
        retryLabel: l10n.inventoryRetryAction,
      );
    }

    final items = itemsAsync.value ?? const <InventoryItem>[];
    final meals = mealsAsync.value ?? const <PreparedMeal>[];

    return InventoryList(
      items: items,
      preparedMeals: meals,
      expandedPreparedMealId: widget.expandedPreparedMealId,
      inventorySelectionFocusToken: _inventorySelectionFocusToken,
      emptyStateActionButton: const InventoryActionFab.embedded(),
      onDeleteItem: (itemId) =>
          _deleteItemWithUndo(context: context, ref: ref, itemId: itemId),
      onEatItem: (itemId, request) => _eatItemWithCalorieBridge(
        context: context,
        ref: ref,
        itemId: itemId,
        request: request,
        itemsSnapshot: items,
      ),
      onThrowAwayItem: controller.throwAwayItemDetailed,
      onEatPreparedMeal:
          ({
            required mealId,
            required portions,
            required mealType,
            required loggedDay,
          }) => ref
              .read(preparedMealsControllerProvider.notifier)
              .consumePreparedMeal(
                mealId: mealId,
                consumedPortions: portions,
                mealType: mealType,
                loggedDay: loggedDay,
              ),
      onThrowAwayPreparedMeal: (mealId, portions, reason) => ref
          .read(preparedMealsControllerProvider.notifier)
          .throwAwayPreparedMeal(
            mealId: mealId,
            discardedPortions: portions,
            reason: reason,
          ),
      onFillPendingPreparedMealIngredient: (mealId, ingredient, itemIds) => ref
          .read(preparedMealsControllerProvider.notifier)
          .fillPreparedMealPendingIngredient(
            mealId: mealId,
            ingredient: ingredient,
            inventoryItemIds: itemIds,
          ),
      onIgnorePendingPreparedMealIngredient: (mealId, ingredient) => ref
          .read(preparedMealsControllerProvider.notifier)
          .ignorePreparedMealPendingIngredient(
            mealId: mealId,
            ingredient: ingredient,
          ),
      onUnbundlePreparedMeal: ref
          .read(preparedMealsControllerProvider.notifier)
          .unbundlePreparedMeal,
      onEditPreparedMeal: (mealId, result) => _updatePreparedMeal(
        context: context,
        ref: ref,
        mealId: mealId,
        result: result,
      ),
      onSelectPreparedMealEditIngredients: (mealId, result) =>
          _startPreparedMealEditIngredientSelection(
            mealId: mealId,
            result: result,
          ),
      onSavePreparedMealTemplate: (meal) =>
          _savePreparedMealTemplate(context: context, ref: ref, meal: meal),
      isSelectionMode: selectionState.isSelectionMode,
      selectedItemIds: selectionState.selectedItemIds,
      onItemLongPress: (itemId) {
        ref
            .read(preparedMealSelectionControllerProvider.notifier)
            .enterSelection(itemId);
      },
      onSelectionToggle: (itemId) {
        ref
            .read(preparedMealSelectionControllerProvider.notifier)
            .toggleSelection(itemId);
      },
    );
  }

  Future<void> _onSelectionConfirmed(int? previous, int next) async {
    if (previous == next || next < 1) {
      return;
    }
    final selectionState = ref.read(preparedMealSelectionControllerProvider);
    if (selectionState.isAddingIngredientsToMeal) {
      await _continuePreparedMealEditWithSelectedIngredients(selectionState);
      return;
    }
    await runPreparedMealCreationFlow(context: context, ref: ref);
  }

  Future<bool> _startPreparedMealEditIngredientSelection({
    required String mealId,
    required PreparedMealEditSheetResult result,
  }) async {
    _pendingEditSelection = _PendingPreparedMealEditSelection(
      mealId: mealId,
      result: result.copyWith(requestIngredientSelection: false),
    );
    ref
        .read(preparedMealSelectionControllerProvider.notifier)
        .startAddIngredientsToMealSelection();
    setState(() {
      _inventorySelectionFocusToken += 1;
    });
    return true;
  }

  Future<void> _continuePreparedMealEditWithSelectedIngredients(
    PreparedMealSelectionState selectionState,
  ) async {
    final pendingSelection = _pendingEditSelection;
    if (pendingSelection == null || selectionState.selectedItemIds.isEmpty) {
      return;
    }

    final items = ref.read(inventoryItemsControllerProvider).asData?.value;
    final meals = ref.read(preparedMealsControllerProvider).asData?.value;
    if (items == null || meals == null || !context.mounted) {
      return;
    }

    final meal = _findPreparedMeal(meals, pendingSelection.mealId);
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

    final editResult = await showPreparedMealEditSheet(
      context: context,
      meal: meal,
      inventoryItems: items,
      initialValue: nextResult,
    );
    if (!mounted || editResult == null) {
      return;
    }
    if (editResult.requestIngredientSelection) {
      await _startPreparedMealEditIngredientSelection(
        mealId: meal.id,
        result: editResult,
      );
      return;
    }
    await _updatePreparedMeal(
      context: context,
      ref: ref,
      mealId: meal.id,
      result: editResult,
    );
  }

  PreparedMealEditSheetResult _addSelectedItemsToEditResult({
    required PreparedMealEditSheetResult result,
    required List<InventoryItem> inventoryItems,
    required Set<String> selectedItemIds,
  }) {
    final existingItemIds = result.items.map((item) => item.itemId).toSet();
    final addedInputs = inventoryItems
        .where((item) => selectedItemIds.contains(item.id))
        .where((item) => !existingItemIds.contains(item.id))
        .where((item) => _defaultInventoryItemAmount(item) > 0)
        .map((item) {
          return PreparedMealItemInput(
            itemId: item.id,
            usedAmount: _defaultInventoryItemAmount(item),
          );
        })
        .toList(growable: false);

    return result.copyWith(
      items: <PreparedMealItemInput>[...result.items, ...addedInputs],
      requestIngredientSelection: false,
    );
  }

  Future<bool> _savePreparedMealTemplate({
    required BuildContext context,
    required WidgetRef ref,
    required PreparedMeal meal,
  }) async {
    final result = await ref
        .read(preparedMealTemplatesControllerProvider.notifier)
        .saveTemplateFromMeal(meal);
    if (!result.isSuccess || !context.mounted) {
      return result.isSuccess;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.preparedMealTemplateSavedMessage,
          ),
        ),
      );
    return true;
  }

  Future<bool> _updatePreparedMeal({
    required BuildContext context,
    required WidgetRef ref,
    required String mealId,
    required PreparedMealEditSheetResult result,
  }) async {
    String? imageAssetId;
    if (result.imageChanged && result.imageBytes != null) {
      imageAssetId = _preparedMealImageAssetUuid.v4();
      final imageRef = localImageAssetRef(imageAssetId);
      await ref
          .read(localImageStoreProvider)
          .saveBytes(imageRef: imageRef, bytes: result.imageBytes!);
      ref.invalidate(localImageBytesProvider(imageRef));
    }
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.preparedMealUpdatedMessage,
          ),
        ),
      );
    return true;
  }

  Future<bool> _deleteItemWithUndo({
    required BuildContext context,
    required WidgetRef ref,
    required String itemId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final deleted = await controller.deleteItem(itemId);
    if (!deleted || !context.mounted) {
      return deleted;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: _deleteUndoSnackBarDuration,
          persist: false,
          content: Text(l10n.inventoryItemDeletedMessage),
          action: SnackBarAction(
            label: l10n.commonUndoAction,
            onPressed: () {
              unawaited(_undoDelete(context: context, ref: ref));
            },
          ),
        ),
      );
    return true;
  }

  void _logLoadErrorOnce(
    AsyncValue<List<InventoryItem>>? previous,
    AsyncValue<List<InventoryItem>> next,
  ) {
    final nextError = next.asError;
    if (nextError == null) {
      return;
    }

    final previousError = previous?.asError;
    final unchangedError = identical(previousError?.error, nextError.error);
    final unchangedStack = previousError?.stackTrace == nextError.stackTrace;
    if (unchangedError && unchangedStack) {
      return;
    }

    developer.log(
      'Failed to load inventory items.',
      name: 'InventoryPage',
      error: nextError.error,
      stackTrace: nextError.stackTrace,
    );
  }

  Future<void> _undoDelete({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final restored = await ref
        .read(inventoryItemsControllerProvider.notifier)
        .undoLastDeletedItem();
    if (!context.mounted) {
      return;
    }
    if (restored) {
      messenger.hideCurrentSnackBar();
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.inventoryItemActionFailed)),
      );
  }

  Future<bool> _eatItemWithCalorieBridge({
    required BuildContext context,
    required WidgetRef ref,
    required String itemId,
    required InventoryItemEatRequest request,
    required List<InventoryItem> itemsSnapshot,
  }) async {
    final inventoryController = ref.read(
      inventoryItemsControllerProvider.notifier,
    );

    InventoryItem? selectedItem;
    for (final item in itemsSnapshot) {
      if (item.id == itemId) {
        selectedItem = item;
        break;
      }
    }
    if (selectedItem == null) {
      return false;
    }

    final pendingConsumption = await inventoryController
        .stagePendingConsumption(itemId, request.inventoryAmount);
    if (pendingConsumption == null) {
      return false;
    }

    if (!context.mounted) {
      await inventoryController.discardPendingConsumption(
        pendingConsumption.id,
      );
      return false;
    }

    if (InventoryItemEatFlow.shouldAwaitCompletion(selectedItem, request)) {
      await InventoryItemEatFlow.complete(
        context: context,
        ref: ref,
        itemBeforeMutation: selectedItem,
        request: request,
        pendingConsumptionId: pendingConsumption.id,
      );
      return true;
    }

    unawaited(
      InventoryItemEatFlow.complete(
        context: context,
        ref: ref,
        itemBeforeMutation: selectedItem,
        request: request,
        pendingConsumptionId: pendingConsumption.id,
      ),
    );
    return true;
  }
}

class _PendingPreparedMealEditSelection {
  const _PendingPreparedMealEditSelection({
    required this.mealId,
    required this.result,
  });

  final String mealId;
  final PreparedMealEditSheetResult result;
}

PreparedMeal? _findPreparedMeal(List<PreparedMeal> meals, String mealId) {
  for (final meal in meals) {
    if (meal.id == mealId) {
      return meal;
    }
  }
  return null;
}

int _defaultInventoryItemAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.currentAmount;
  }
  return item.quantity;
}

class _InventoryLoadingView extends StatelessWidget {
  const _InventoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: AppSizes.inlineProgressIndicator,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.progressStrokeWidth,
        ),
      ),
    );
  }
}

class _InventoryErrorView extends StatelessWidget {
  const _InventoryErrorView({
    required this.onRetry,
    required this.message,
    required this.retryLabel,
  });

  final Future<void> Function() onRetry;
  final String message;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardRadius = BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return Center(
      child: Padding(
        padding: AppInsets.pageLarge,
        child: DecoratedBox(
          decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: cardRadius,
          ),
          child: Padding(
            padding: AppInsets.card,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_tethering_error_rounded,
                  color: colors.error,
                  size: AppSizes.welcomeIcon * 0.45,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
