import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'diary_quick_eat_inventory_provider.g.dart';

/// Inventory foods available to the diary quick-eat flow.
@immutable
class DiaryQuickEatInventoryData {
  /// Creates quick-eat inventory data.
  const new({required this.items, required this.meals});

  /// Inventory items that can be eaten from the diary.
  final List<InventoryItem> items;

  /// Prepared meals that can be eaten from the diary.
  final List<PreparedMeal> meals;
}

/// Provides selectable inventory foods for the diary quick-eat picker.
@riverpod
Future<DiaryQuickEatInventoryData> diaryQuickEatInventory(Ref ref) async {
  final inventory = await ref.watch(inventoryQuickEatInventoryProvider.future);
  return _filterDiaryQuickEatInventory(inventory);
}

DiaryQuickEatInventoryData _filterDiaryQuickEatInventory(
  InventoryQuickEatInventoryData inventory,
) {
  return DiaryQuickEatInventoryData(
    items: inventory.items
        .where(canDiaryQuickEatInventoryItem)
        .toList(growable: false),
    meals: inventory.meals
        .where((meal) => !meal.isDepleted)
        .toList(growable: false),
  );
}

/// Whether an inventory item can be selected for diary quick eat.
@visibleForTesting
bool canDiaryQuickEatInventoryItem(InventoryItem item) {
  return consumableInventoryAmount(item) != null;
}
