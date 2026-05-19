import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';

/// Defines inventory calorie bridge flow.
@Dependencies([inventoryBackedCalorieEntrySaveFlow])
class InventoryCalorieBridgeFlow {
  const InventoryCalorieBridgeFlow._();

  static const _uuid = Uuid();

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

  /// Save direct entry.
  static Future<bool> saveDirectEntry({
    required ProviderContainer container,
    required CalorieProductProfile profile,
    required CalorieInventoryCreateContext inventoryContext,
    required CalorieScannedSourceRef? scannedSourceRef,
    required DateTime loggedAt,
    required MealType mealType,
  }) async {
    final user = container.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      return false;
    }

    final now = DateTime.now();
    final entry = CalorieEntry.create(
      id: _uuid.v4(),
      userId: user.uid,
      name: profile.name,
      brand: profile.brand,
      imageUrl: profile.imageUrl,
      mealType: mealType,
      consumedAmount: inventoryContext.consumedAmount,
      consumedUnit: inventoryContext.consumedUnit,
      per100Kcal: profile.per100Kcal,
      per100Protein: profile.per100Protein,
      per100Carbs: profile.per100Carbs,
      per100Fat: profile.per100Fat,
      sourceInventoryItemId: inventoryContext.inventoryItemId,
      sourceInventoryAmountToRestore: inventoryContext.inventoryAmountToRestore,
      loggedAt: loggedAt,
      createdAt: now,
      updatedAt: now,
    );

    return container
        .read(calorieEntriesControllerProvider.notifier)
        .saveEntry(
          entry,
          inventoryContext: inventoryContext,
          scannedSourceRef: scannedSourceRef,
          persistEntry: (entry) {
            return container
                .read(inventoryBackedCalorieEntrySaveFlowProvider)
                .saveEntry(
                  entry: entry,
                  pendingConsumptionId: inventoryContext.pendingConsumptionId,
                );
          },
        );
  }
}
