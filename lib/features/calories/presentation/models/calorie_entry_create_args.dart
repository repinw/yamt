import 'package:yamt/features/calories/domain/calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

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
