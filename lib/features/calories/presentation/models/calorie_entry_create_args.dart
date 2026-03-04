import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

class CalorieInventoryCreateContext {
  const CalorieInventoryCreateContext({
    required this.inventoryItemId,
    required this.foodFingerprint,
    required this.itemName,
    required this.itemBrand,
    required this.consumedAmount,
    required this.consumedUnit,
  });

  final String inventoryItemId;
  final String foodFingerprint;
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
  });

  final CalorieProductProfile? prefilledProfile;
  final CalorieScannedSourceRef? scannedSourceRef;
  final CalorieInventoryCreateContext? inventoryContext;
}

class CalorieBarcodeScanArgs {
  const CalorieBarcodeScanArgs({this.inventoryContext});

  final CalorieInventoryCreateContext? inventoryContext;
}
