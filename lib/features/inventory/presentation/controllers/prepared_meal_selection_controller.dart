import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/inventory_combined_eat_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_meal_food_pick.dart';

part 'prepared_meal_selection_controller.g.dart';

/// Defines prepared meal selection state.
@immutable
class PreparedMealSelectionState {
  /// The prepared meal selection state.
  const new({
    this.selectedItemIds = const <String>{},
    this.bindRequestToken = 0,
    this.anchorItemId,
    this.catalogFoods = const <InventoryMealFoodPick>[],
  });

  /// The selected item ids.
  final Set<String> selectedItemIds;

  /// The bind request token.
  final int bindRequestToken;

  /// The item whose eat page started the selection; it stays the main food
  /// of the meal while it is selected (#654).
  final String? anchorItemId;

  /// Foods found in the catalog that join the meal next to the selected
  /// stock items.
  final List<InventoryMealFoodPick> catalogFoods;

  /// Whether selection mode.
  bool get isSelectionMode =>
      selectedItemIds.isNotEmpty || catalogFoods.isNotEmpty;

  /// The selected count, catalog foods included.
  int get selectedCount => selectedItemIds.length + catalogFoods.length;

  /// Whether the selection can become a meal: two foods or more, one of
  /// them from the stock.
  bool get canConfirm => selectedItemIds.isNotEmpty && selectedCount >= 2;

  /// Copy with.
  PreparedMealSelectionState copyWith({
    Set<String>? selectedItemIds,
    int? bindRequestToken,
    List<InventoryMealFoodPick>? catalogFoods,
  }) {
    return PreparedMealSelectionState(
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      bindRequestToken: bindRequestToken ?? this.bindRequestToken,
      anchorItemId: anchorItemId,
      catalogFoods: catalogFoods ?? this.catalogFoods,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PreparedMealSelectionState &&
            const SetEquality<String>().equals(
              other.selectedItemIds,
              selectedItemIds,
            ) &&
            other.bindRequestToken == bindRequestToken &&
            other.anchorItemId == anchorItemId &&
            const ListEquality<InventoryMealFoodPick>().equals(
              other.catalogFoods,
              catalogFoods,
            );
  }

  @override
  int get hashCode {
    return Object.hash(
      const SetEquality<String>().hash(selectedItemIds),
      bindRequestToken,
      anchorItemId,
      const ListEquality<InventoryMealFoodPick>().hash(catalogFoods),
    );
  }
}

/// Defines prepared meal selection controller.
@riverpod
class PreparedMealSelectionController
    extends _$PreparedMealSelectionController {
  @override
  PreparedMealSelectionState build() {
    return const PreparedMealSelectionState();
  }

  /// Enter selection.
  void enterSelection(String itemId) {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return;
    }
    state = PreparedMealSelectionState(
      selectedItemIds: <String>{trimmedItemId},
      bindRequestToken: state.bindRequestToken,
    );
  }

  /// Starts the selection from the eat page of [anchorItemId] with the foods
  /// of its meal: the stock items [itemIds] and the [catalogFoods] (#654).
  void startFrom({
    required String anchorItemId,
    required Set<String> itemIds,
    List<InventoryMealFoodPick> catalogFoods = const <InventoryMealFoodPick>[],
  }) {
    state = PreparedMealSelectionState(
      selectedItemIds: itemIds,
      bindRequestToken: state.bindRequestToken,
      anchorItemId: anchorItemId,
      catalogFoods: catalogFoods,
    );
  }

  /// Adds a food found in the catalog to the selection. Returns false, and
  /// leaves the selection as it is, when the food has no nutrition values to
  /// add up or its amount cannot be logged as it is.
  bool addCatalogFood(InventoryMealFoodPick food) {
    final item = food.result.item;
    if (!InventoryCombinedEatService.canCombine(item) ||
        !canDirectlySaveInventoryItemEatRequest(item, food.request)) {
      return false;
    }
    state = state.copyWith(catalogFoods: [...state.catalogFoods, food]);
    return true;
  }

  /// Removes [food], which its row shows at [index]. When the list changed
  /// since that row was built, for example by a second tap on the same row,
  /// [index] no longer holds [food] and nothing is removed.
  void removeCatalogFoodAt(int index, InventoryMealFoodPick food) {
    if (index < 0 ||
        index >= state.catalogFoods.length ||
        state.catalogFoods[index] != food) {
      return;
    }
    state = state.copyWith(
      catalogFoods: [...state.catalogFoods]..removeAt(index),
    );
  }

  /// Toggle selection.
  void toggleSelection(String itemId) {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return;
    }
    final nextSelection = Set<String>.from(state.selectedItemIds);
    if (!nextSelection.add(trimmedItemId)) {
      nextSelection.remove(trimmedItemId);
    }
    state = state.copyWith(selectedItemIds: nextSelection);
  }

  /// Clear selection.
  void clearSelection() {
    if (!state.isSelectionMode) {
      return;
    }
    state = PreparedMealSelectionState(
      bindRequestToken: state.bindRequestToken,
    );
  }

  /// Request the active selection action.
  void confirmSelection() {
    state = state.copyWith(bindRequestToken: state.bindRequestToken + 1);
  }
}
