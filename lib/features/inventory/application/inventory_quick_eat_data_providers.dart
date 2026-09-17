import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'inventory_quick_eat_data_providers.g.dart';

/// Inventory data exposed to application-level quick-eat adapters.
@immutable
class InventoryQuickEatInventoryData {
  /// Creates quick-eat inventory data.
  const new({required this.items, required this.meals});

  /// All inventory items available to the caller.
  final List<InventoryItem> items;

  /// All prepared meals available to the caller.
  final List<PreparedMeal> meals;
}

/// Watches all inventory items for quick-eat consumers.
@riverpod
Stream<List<InventoryItem>> inventoryQuickEatItems(Ref ref) {
  return ref.watch(inventoryItemRepositoryProvider).watchAll();
}

/// Watches all prepared meals for quick-eat consumers.
@riverpod
Stream<List<PreparedMeal>> inventoryQuickEatMeals(Ref ref) {
  return ref.watch(preparedMealRepositoryProvider).watchAll();
}

/// Loads live inventory data for quick-eat pickers.
@riverpod
Future<InventoryQuickEatInventoryData> inventoryQuickEatInventory(
  Ref ref,
) async {
  final items = await _readQuickEatItems(ref);
  final meals = await _readQuickEatMeals(ref);
  return InventoryQuickEatInventoryData(items: items, meals: meals);
}

Future<List<InventoryItem>> _readQuickEatItems(Ref ref) async {
  final state = ref.watch(inventoryQuickEatItemsProvider);
  return state.asData?.value ??
      await ref.watch(inventoryQuickEatItemsProvider.future) ??
      const <InventoryItem>[];
}

Future<List<PreparedMeal>> _readQuickEatMeals(Ref ref) async {
  final state = ref.watch(inventoryQuickEatMealsProvider);
  return state.asData?.value ??
      await ref.watch(inventoryQuickEatMealsProvider.future) ??
      const <PreparedMeal>[];
}
