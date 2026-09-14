import 'dart:async';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_delete_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_creation_coordinator.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_edit_coordinator.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_activity_timeline/inventory_activity_timeline.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_error_view.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_loading_view.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_view_toggle_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _InventoryPageView { stock, history }

/// Defines inventory page.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  InventoryItemsController,
  PreparedMealsController,
  preparedMealImagePicker,
  manualProductRecentItemsService,
  inventoryActivityEvents,
  inventoryBackedCalorieEntrySaveFlow,
])
class InventoryPage extends ConsumerStatefulWidget {
  /// The inventory page.
  const InventoryPage({
    super.key,
    this.expandedPreparedMealId,
    this.includeHomeShellChrome = false,
    this.emptyStateActionButton,
  });

  /// The expanded prepared meal id.
  final String? expandedPreparedMealId;

  /// Whether to render the shared home shell app bar as a sliver.
  final bool includeHomeShellChrome;

  /// Optional action button rendered by the embedding shell.
  final Widget? emptyStateActionButton;

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final _mealEditCoordinator = InventoryPreparedMealEditCoordinator();
  _InventoryPageView _selectedView = _InventoryPageView.stock;

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
    final topChromeActions = [
      InventoryViewToggleButton(
        isShowingStock: _selectedView == _InventoryPageView.stock,
        onToggle: _toggleView,
      ),
    ];

    if (_selectedView == _InventoryPageView.history) {
      return InventoryActivityTimeline(
        includeHomeShellChrome: widget.includeHomeShellChrome,
        topChromeActions: topChromeActions,
      );
    }

    final controller = ref.read(inventoryItemsControllerProvider.notifier);
    final itemsAsync = ref.watch(inventoryItemsControllerProvider);
    final mealsController = ref.read(preparedMealsControllerProvider.notifier);
    final mealsAsync = ref.watch(preparedMealsControllerProvider);
    final selectionState = ref.watch(preparedMealSelectionControllerProvider);

    if (itemsAsync.isLoading || mealsAsync.isLoading) {
      return InventoryLoadingView(
        includeHomeShellChrome: widget.includeHomeShellChrome,
        topChromeActions: topChromeActions,
      );
    }

    final itemsError = itemsAsync.asError;
    final mealsError = mealsAsync.asError;
    if (itemsError != null || mealsError != null) {
      return InventoryErrorView(
        onRetry: () async {
          await controller.refresh();
          await mealsController.refresh();
        },
        message: l10n.inventoryLoadFailed,
        retryLabel: l10n.inventoryRetryAction,
        includeHomeShellChrome: widget.includeHomeShellChrome,
        topChromeActions: topChromeActions,
      );
    }

    final items = itemsAsync.value ?? const <InventoryItem>[];
    final meals = mealsAsync.value ?? const <PreparedMeal>[];

    return InventoryList(
      items: items,
      preparedMeals: meals,
      expandedPreparedMealId: widget.expandedPreparedMealId,
      includeHomeShellChrome: widget.includeHomeShellChrome,
      inventorySelectionFocusToken:
          _mealEditCoordinator.inventorySelectionFocusToken,
      topChromeActions: topChromeActions,
      emptyStateActionButton: widget.emptyStateActionButton,
      onDeleteItem: (itemId) => InventoryItemDeleteFlow.deleteWithUndo(
        context: context,
        ref: ref,
        itemId: itemId,
      ),
      onEatItem: (itemId, request) => _eatItemWithCalorieBridge(
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
          }) => mealsController.consumePreparedMeal(
            mealId: mealId,
            consumedPortions: portions,
            mealType: mealType,
            loggedDay: loggedDay,
          ),
      onThrowAwayPreparedMeal: (mealId, portions, reason) =>
          mealsController.throwAwayPreparedMeal(
            mealId: mealId,
            discardedPortions: portions,
            reason: reason,
          ),
      onFillPendingPreparedMealIngredient:
          (mealId, ingredient, itemIds) =>
              mealsController.fillPreparedMealPendingIngredient(
                mealId: mealId,
                ingredient: ingredient,
                inventoryItemIds: itemIds,
              ),
      onIgnorePendingPreparedMealIngredient: (mealId, ingredient) =>
          mealsController.ignorePreparedMealPendingIngredient(
            mealId: mealId,
            ingredient: ingredient,
          ),
      onUnbundlePreparedMeal: mealsController.unbundlePreparedMeal,
      onEditPreparedMeal: (mealId, result) => _mealEditCoordinator
          .updatePreparedMeal(
            context: context,
            ref: ref,
            mealId: mealId,
            result: result,
          ),
      onSelectPreparedMealEditIngredients: (mealId, result) async =>
          _mealEditCoordinator.startSelection(
            ref: ref,
            mealId: mealId,
            result: result,
            onFocusRequested: () => setState(() {}),
          ),
      onSavePreparedMealTemplate: (meal) => _mealEditCoordinator.saveTemplate(
        context: context,
        ref: ref,
        meal: meal,
      ),
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

  void _toggleView() {
    setState(() {
      _selectedView = _selectedView == _InventoryPageView.stock
          ? _InventoryPageView.history
          : _InventoryPageView.stock;
    });
  }

  Future<void> _onSelectionConfirmed(int? previous, int next) async {
    if (previous == next || next < 1) {
      return;
    }
    final selectionState = ref.read(preparedMealSelectionControllerProvider);
    if (selectionState.isAddingIngredientsToMeal) {
      await _mealEditCoordinator.continueWithSelectedIngredients(
        context: context,
        ref: ref,
        selectionState: selectionState,
      );
      return;
    }
    await runPreparedMealCreationFlow(context: context, ref: ref);
  }

  void _logLoadErrorOnce(
    AsyncValue<List<InventoryItem>>? previous,
    AsyncValue<List<InventoryItem>> next,
  ) {
    final nextError = next.asError;
    final prevError = previous?.asError;
    if (nextError == null ||
        (identical(prevError?.error, nextError.error) &&
            prevError?.stackTrace == nextError.stackTrace)) {
      return;
    }

    developer.log(
      'Failed to load inventory items.',
      name: 'InventoryPage',
      error: nextError.error,
      stackTrace: nextError.stackTrace,
    );
  }

  Future<bool> _eatItemWithCalorieBridge({
    required String itemId,
    required InventoryItemEatRequest request,
    required List<InventoryItem> itemsSnapshot,
  }) async {
    final selectedItem = itemsSnapshot.firstWhereOrNull(
      (item) => item.id == itemId,
    );
    if (selectedItem == null) {
      return false;
    }

    return InventoryItemEatFlow.stageAndComplete(
      context: context,
      container: ref.container,
      item: selectedItem,
      request: request,
    );
  }
}
