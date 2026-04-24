import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

PreparedMeal preparedMealTestData({
  String id = 'meal-1',
  String name = 'Rice bowl',
  String? imageAssetId,
  int totalPortions = 3,
  int remainingPortions = 2,
}) {
  final sourceItem = InventoryItem.create(
    id: 'item-1',
    name: 'Rice',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 200,
    currentAmount: 200,
    amountUnit: InventoryAmountUnit.gram,
  );

  return PreparedMeal(
    id: id,
    name: name,
    imageAssetId: imageAssetId,
    totalPortions: totalPortions,
    remainingPortions: remainingPortions,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 8,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: [
      PreparedMealComponent(
        inventoryItemId: sourceItem.id,
        name: sourceItem.name,
        brand: sourceItem.brand,
        imageUrl: sourceItem.imageUrl,
        usedAmount: 100,
        usedUnit: InventoryAmountUnit.gram,
        totalKcal: 400,
        totalProtein: 20,
        totalCarbs: 40,
        totalFat: 8,
        sourceItemSnapshot: sourceItem,
      ),
    ],
  );
}
