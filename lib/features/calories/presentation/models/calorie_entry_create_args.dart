import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

class CalorieInventoryCreateContext {
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

  final String inventoryItemId;
  final String foodFingerprint;
  final String globalFoodItemId;
  final String pendingConsumptionId;
  final int inventoryAmountToRestore;
  final String itemName;
  final String? itemBrand;
  final double consumedAmount;
  final ConsumedUnit consumedUnit;
}

class CalorieEntryCreateArgs {
  const CalorieEntryCreateArgs({
    required this.prefilledProfile,
    this.scannedSourceRef,
    this.inventoryContext,
    this.preselectedMealType,
    this.preselectedLoggedAt,
  });

  final CalorieProductProfile? prefilledProfile;
  final CalorieScannedSourceRef? scannedSourceRef;
  final CalorieInventoryCreateContext? inventoryContext;
  final MealType? preselectedMealType;
  final DateTime? preselectedLoggedAt;
}

class CalorieBarcodeScanArgs {
  const CalorieBarcodeScanArgs({this.inventoryContext});

  final CalorieInventoryCreateContext? inventoryContext;
}
