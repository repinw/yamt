import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_delete_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_prepared_meal_edit_coordinator.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_activity_timeline/inventory_activity_timeline.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_error_view.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_loading_view.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_page_lifecycle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_page_list_content.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_page/'
    'inventory_view_toggle_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Builds the inventory page content and coordinates its UI controllers.
class InventoryPageContent extends ConsumerWidget {
  /// Creates inventory page content.
  const new({
    required this.isShowingHistory,
    required this.onToggleView,
    required this.mealEditCoordinator,
    required this.onFocusRequested,
    this.expandedPreparedMealId,
    this.includeHomeShellChrome = false,
    this.emptyStateActionButton,
    super.key,
  });

  /// Whether the activity history is visible.
  final bool isShowingHistory;

  /// Toggles between stock and history.
  final VoidCallback onToggleView;

  /// Coordinator retained by the page state.
  final InventoryPreparedMealEditCoordinator mealEditCoordinator;

  /// Rebuilds the page when ingredient selection requests focus.
  final VoidCallback onFocusRequested;

  /// Optional prepared meal to expand.
  final String? expandedPreparedMealId;

  /// Whether to render home-shell chrome.
  final bool includeHomeShellChrome;

  /// Optional empty-state action.
  final Widget? emptyStateActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..listen(inventoryItemsControllerProvider, logInventoryPageLoadError)
      ..listen(
        preparedMealSelectionControllerProvider.select(
          (state) => state.bindRequestToken,
        ),
        (previous, next) => handleInventoryPageSelectionConfirmed(
          context: context,
          ref: ref,
          mealEditCoordinator: mealEditCoordinator,
          previous: previous,
          next: next,
        ),
      );

    final l10n = AppLocalizations.of(context)!;
    final topChromeActions = [
      InventoryViewToggleButton(
        isShowingStock: !isShowingHistory,
        onToggle: onToggleView,
      ),
    ];

    if (isShowingHistory) {
      return InventoryActivityTimeline(
        includeHomeShellChrome: includeHomeShellChrome,
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
        includeHomeShellChrome: includeHomeShellChrome,
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
        includeHomeShellChrome: includeHomeShellChrome,
        topChromeActions: topChromeActions,
      );
    }

    final items = itemsAsync.value ?? const <InventoryItem>[];
    final meals = mealsAsync.value ?? const <PreparedMeal>[];

    return InventoryPageListContent(
      items: items,
      preparedMeals: meals,
      expandedPreparedMealId: expandedPreparedMealId,
      includeHomeShellChrome: includeHomeShellChrome,
      inventorySelectionFocusToken:
          mealEditCoordinator.inventorySelectionFocusToken,
      topChromeActions: topChromeActions,
      emptyStateActionButton: emptyStateActionButton,
      onDeleteItem: (itemId) => InventoryItemDeleteFlow.deleteWithUndo(
        context: context,
        ref: ref,
        itemId: itemId,
      ),
      onEatItem: (itemId, request) => eatInventoryPageItem(
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
      onFillPendingPreparedMealIngredient: (mealId, ingredient, itemIds) =>
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
      onEditPreparedMeal: (mealId, result) =>
          mealEditCoordinator.updatePreparedMeal(
            context: context,
            ref: ref,
            mealId: mealId,
            result: result,
          ),
      onSelectPreparedMealEditIngredients: (mealId, result) async =>
          mealEditCoordinator.startSelection(
            ref: ref,
            mealId: mealId,
            result: result,
            onFocusRequested: onFocusRequested,
          ),
      onSavePreparedMealTemplate: (meal) => mealEditCoordinator.saveTemplate(
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
}
