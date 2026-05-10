import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

/// Defines inventory calorie bridge flow.
class InventoryCalorieBridgeFlow {
  const InventoryCalorieBridgeFlow._();

  /// Build profile from inventory item.
  static CalorieProductProfile? buildProfileFromInventoryItem(
    InventoryItem item,
  ) {
    final nutrition = item.nutrition;
    if (nutrition?.hasAnyNutritionValue != true) {
      return null;
    }

    final barcode = item.normalizedBarcode ?? 'inventory-${item.id}';

    return CalorieProductProfile(
      barcode: barcode,
      name: item.name,
      brand: item.brand,
      per100Kcal: nutrition?.per100Kcal ?? 0,
      per100Protein: nutrition?.per100Protein ?? 0,
      per100Carbs: nutrition?.per100Carbs ?? 0,
      per100Fat: nutrition?.per100Fat ?? 0,
      source: CalorieProductSource.userOverride,
      offProductId: _resolveOffProductId(item.globalFoodItemId),
      imageUrl: item.imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Build scanned source ref.
  static CalorieScannedSourceRef? buildScannedSourceRef({
    required InventoryItem item,
    required CalorieProductProfile profile,
  }) {
    final barcode = item.normalizedBarcode;
    if (barcode == null) {
      return null;
    }

    return CalorieScannedSourceRef(
      barcode: barcode,
      source: profile.source,
      offProductId: profile.offProductId,
    );
  }

  /// Build inventory context.
  static CalorieInventoryCreateContext buildInventoryContext({
    required InventoryItem item,
    required String pendingConsumptionId,
    required InventoryItemEatRequest request,
  }) {
    final fixedUnit = inventoryItemConsumedUnit(item);
    if (!request.hasManualCaloriePortion && fixedUnit == null) {
      throw StateError(
        'Manual calorie portion is required for inventory item ${item.id}.',
      );
    }

    final consumedAmount = request.hasManualCaloriePortion
        ? request.calorieAmount!
        : request.inventoryAmount.toDouble();
    final consumedUnit = request.hasManualCaloriePortion
        ? request.calorieUnit!
        : fixedUnit!;

    return CalorieInventoryCreateContext(
      inventoryItemId: item.id,
      foodFingerprint: item.resolvedFoodFingerprint,
      globalFoodItemId: item.globalFoodItemId,
      pendingConsumptionId: pendingConsumptionId,
      inventoryAmountToRestore: request.inventoryAmount,
      itemName: item.name,
      itemBrand: item.brand,
      consumedAmount: consumedAmount,
      consumedUnit: consumedUnit,
      portionBaseAmount: request.portionBaseAmount,
      portionBaseUnit: request.portionBaseUnit,
      portionCount: request.portionCount,
      portionLabel: request.portionLabel,
    );
  }

  static String? _resolveOffProductId(String? globalFoodItemId) {
    final normalizedId = globalFoodItemId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) {
      return null;
    }
    if (normalizedId.startsWith('off-')) {
      return normalizedId;
    }
    return null;
  }
}
