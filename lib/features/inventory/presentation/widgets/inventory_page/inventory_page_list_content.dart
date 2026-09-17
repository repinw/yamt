import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_prepared_meals_section.dart';

/// Renders the stock list with the callbacks coordinated by the page.
class InventoryPageListContent extends StatelessWidget {
  /// Creates inventory page list content.
  const new({
    required this.items,
    required this.preparedMeals,
    required this.emptyStateActionButton,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
    required this.onEatPreparedMeal,
    required this.onThrowAwayPreparedMeal,
    required this.onFillPendingPreparedMealIngredient,
    required this.onIgnorePendingPreparedMealIngredient,
    required this.onUnbundlePreparedMeal,
    required this.onEditPreparedMeal,
    required this.onSelectPreparedMealEditIngredients,
    required this.onSavePreparedMealTemplate,
    required this.isSelectionMode,
    required this.selectedItemIds,
    required this.onItemLongPress,
    required this.onSelectionToggle,
    this.expandedPreparedMealId,
    this.includeHomeShellChrome = false,
    this.inventorySelectionFocusToken = 0,
    this.topChromeActions = const <Widget>[],
    super.key,
  });

  /// Inventory items to render.
  final List<InventoryItem> items;

  /// Prepared meals to render.
  final List<PreparedMeal> preparedMeals;

  /// Expanded prepared meal id.
  final String? expandedPreparedMealId;

  /// Whether to render home-shell chrome.
  final bool includeHomeShellChrome;

  /// Selection focus token.
  final int inventorySelectionFocusToken;

  /// Home-shell actions.
  final List<Widget> topChromeActions;

  /// Empty-state action.
  final Widget? emptyStateActionButton;

  /// Item delete callback.
  final Future<bool> Function(String itemId) onDeleteItem;

  /// Item eat callback.
  final Future<bool> Function(String itemId, InventoryItemEatRequest request)
  onEatItem;

  /// Item discard callback.
  final Future<InventoryItemDiscardResult?> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )
  onThrowAwayItem;

  /// Prepared meal eat callback.
  final PreparedMealEatCallback onEatPreparedMeal;

  /// Prepared meal discard callback.
  final PreparedMealDiscardCallback onThrowAwayPreparedMeal;

  /// Fills an ingredient from selected inventory items.
  final PreparedMealIngredientFillCallback onFillPendingPreparedMealIngredient;

  /// Ignores a pending prepared meal ingredient.
  final PreparedMealIngredientIgnoreCallback
  onIgnorePendingPreparedMealIngredient;

  /// Unbundles a prepared meal.
  final PreparedMealIdCallback onUnbundlePreparedMeal;

  /// Saves a prepared meal edit.
  final PreparedMealEditCallback onEditPreparedMeal;

  /// Starts prepared meal ingredient selection.
  final PreparedMealEditIngredientSelectionCallback
  onSelectPreparedMealEditIngredients;

  /// Saves a prepared meal template.
  final PreparedMealSaveTemplateCallback onSavePreparedMealTemplate;

  /// Whether item selection mode is active.
  final bool isSelectionMode;

  /// Selected inventory item ids.
  final Set<String> selectedItemIds;

  /// Long-press callback.
  final ValueChanged<String> onItemLongPress;

  /// Selection toggle callback.
  final ValueChanged<String> onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    return InventoryList(
      items: items,
      preparedMeals: preparedMeals,
      expandedPreparedMealId: expandedPreparedMealId,
      includeHomeShellChrome: includeHomeShellChrome,
      inventorySelectionFocusToken: inventorySelectionFocusToken,
      topChromeActions: topChromeActions,
      emptyStateActionButton: emptyStateActionButton,
      onDeleteItem: onDeleteItem,
      onEatItem: onEatItem,
      onThrowAwayItem: onThrowAwayItem,
      onEatPreparedMeal: onEatPreparedMeal,
      onThrowAwayPreparedMeal: onThrowAwayPreparedMeal,
      onFillPendingPreparedMealIngredient: onFillPendingPreparedMealIngredient,
      onIgnorePendingPreparedMealIngredient:
          onIgnorePendingPreparedMealIngredient,
      onUnbundlePreparedMeal: onUnbundlePreparedMeal,
      onEditPreparedMeal: onEditPreparedMeal,
      onSelectPreparedMealEditIngredients: onSelectPreparedMealEditIngredients,
      onSavePreparedMealTemplate: onSavePreparedMealTemplate,
      isSelectionMode: isSelectionMode,
      selectedItemIds: selectedItemIds,
      onItemLongPress: onItemLongPress,
      onSelectionToggle: onSelectionToggle,
    );
  }
}
