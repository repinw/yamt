import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/application/inventory_calorie_nutrient_details.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

/// Defines inventory calorie bridge flow.
class InventoryCalorieBridgeFlow {
  const new _();

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
      nutrientDetails: calorieNutrientDetailsFrom(nutrition),
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
  ///
  /// [stagedAmount] is what the stock actually gave, which may be less than
  /// the request when the stock ran low; deleting the entry returns that.
  static CalorieInventoryCreateContext buildInventoryContext({
    required InventoryItem item,
    required InventoryItemEatRequest request,
    int? stagedAmount,
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
      inventoryAmountToRestore: stagedAmount ?? request.inventoryAmount,
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

  /// Builds the diary entry for [request] from [profile] and
  /// [inventoryContext].
  ///
  /// A plan sets [takesStock] to false, so a delete gives nothing back. A
  /// food that is not in the Vorrat sets [inVorrat] to false and names no
  /// Vorrat item.
  static CalorieEntry buildCalorieEntry({
    required String id,
    required String userId,
    required CalorieProductProfile profile,
    required CalorieInventoryCreateContext inventoryContext,
    required InventoryItemEatRequest request,
    required DateTime now,
    bool takesStock = true,
    bool inVorrat = true,
  }) {
    return CalorieEntry.create(
      id: id,
      userId: userId,
      name: profile.name,
      brand: profile.brand,
      imageUrl: profile.imageUrl,
      mealType: request.mealType,
      consumedAmount: inventoryContext.consumedAmount,
      consumedUnit: inventoryContext.consumedUnit,
      per100Kcal: profile.per100Kcal,
      per100Protein: profile.per100Protein,
      per100Carbs: profile.per100Carbs,
      per100Fat: profile.per100Fat,
      sourceInventoryItemId: inVorrat ? inventoryContext.inventoryItemId : null,
      sourceInventoryAmountToRestore: takesStock
          ? inventoryContext.inventoryAmountToRestore
          : null,
      nutrientDetails: profile.nutrientDetails,
      loggedAt: request.loggedAt,
      createdAt: now,
      updatedAt: now,
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
