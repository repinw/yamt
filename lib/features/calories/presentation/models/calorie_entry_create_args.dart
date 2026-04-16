import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

/// Defines calorie inventory create context.
class CalorieInventoryCreateContext {
  /// The calorie inventory create context.
  const CalorieInventoryCreateContext({
    required this.inventoryItemId,
    required this.foodFingerprint,
    required this.globalFoodItemId,
    required this.pendingConsumptionId,
    required this.inventoryAmountToRestore,
    required this.itemName,
    required this.itemBrand,
    required this.consumedAmount,
    required this.consumedUnit,
  });

  /// The inventory item id.
  final String inventoryItemId;

  /// The food fingerprint.
  final String foodFingerprint;

  /// The global food item id.
  final String globalFoodItemId;

  /// The pending consumption id.
  final String pendingConsumptionId;

  /// The inventory amount to restore.
  final int inventoryAmountToRestore;

  /// The item name.
  final String itemName;

  /// The item brand.
  final String? itemBrand;

  /// The consumed amount.
  final double consumedAmount;

  /// The consumed unit.
  final ConsumedUnit consumedUnit;
}

/// Defines calorie entry create args.
class CalorieEntryCreateArgs {
  /// The calorie entry create args.
  const CalorieEntryCreateArgs({
    required this.prefilledProfile,
    this.scannedSourceRef,
    this.inventoryContext,
    this.preselectedMealType,
    this.preselectedLoggedAt,
  });

  /// The prefilled profile.
  final CalorieProductProfile? prefilledProfile;

  /// The scanned source ref.
  final CalorieScannedSourceRef? scannedSourceRef;

  /// The inventory context.
  final CalorieInventoryCreateContext? inventoryContext;

  /// The preselected meal type.
  final MealType? preselectedMealType;

  /// The preselected logged at.
  final DateTime? preselectedLoggedAt;
}

/// Defines calorie barcode scan args.
class CalorieBarcodeScanArgs {
  /// The calorie barcode scan args.
  const CalorieBarcodeScanArgs({this.inventoryContext});

  /// The inventory context.
  final CalorieInventoryCreateContext? inventoryContext;
}
