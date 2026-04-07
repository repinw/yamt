import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';

class CalorieEntryCreatePrefill {
  const CalorieEntryCreatePrefill({
    required this.initializationKey,
    required this.name,
    required this.brand,
    required this.consumedAmount,
    required this.per100Kcal,
    required this.per100Protein,
    required this.per100Carbs,
    required this.per100Fat,
    required this.mealType,
    required this.consumedUnit,
    required this.loggedAt,
  });

  factory CalorieEntryCreatePrefill.fromArgs({
    required CalorieProductProfile? prefilledProfile,
    required CalorieInventoryCreateContext? inventoryContext,
    required MealType? preselectedMealType,
    required DateTime? preselectedLoggedAt,
  }) {
    final loggedAt = preselectedLoggedAt ?? DateTime.now();
    final mealType =
        preselectedMealType ?? MealType.defaultForDateTime(loggedAt);

    return CalorieEntryCreatePrefill(
      initializationKey: _buildInitializationKey(
        prefilledProfile: prefilledProfile,
        inventoryContext: inventoryContext,
        mealType: mealType,
        loggedAt: loggedAt,
      ),
      name: prefilledProfile?.name ?? '',
      brand: prefilledProfile?.brand ?? '',
      consumedAmount: inventoryContext?.consumedAmount ?? 100,
      per100Kcal: prefilledProfile?.per100Kcal ?? 0,
      per100Protein: prefilledProfile?.per100Protein ?? 0,
      per100Carbs: prefilledProfile?.per100Carbs ?? 0,
      per100Fat: prefilledProfile?.per100Fat ?? 0,
      mealType: mealType,
      consumedUnit: inventoryContext?.consumedUnit ?? ConsumedUnit.grams,
      loggedAt: loggedAt,
    );
  }

  final String initializationKey;
  final String name;
  final String? brand;
  final double consumedAmount;
  final double per100Kcal;
  final double per100Protein;
  final double per100Carbs;
  final double per100Fat;
  final MealType mealType;
  final ConsumedUnit consumedUnit;
  final DateTime loggedAt;

  static String _buildInitializationKey({
    required CalorieProductProfile? prefilledProfile,
    required CalorieInventoryCreateContext? inventoryContext,
    required MealType mealType,
    required DateTime loggedAt,
  }) {
    return '__new_entry__'
        '${prefilledProfile?.barcode ?? ''}_'
        '${prefilledProfile?.source.jsonValue ?? 'none'}_'
        '${inventoryContext?.inventoryItemId ?? ''}'
        '${inventoryContext?.pendingConsumptionId ?? ''}'
        '${inventoryContext?.consumedAmount ?? 100}'
        '${inventoryContext?.consumedUnit.jsonValue ?? 'g'}'
        '${mealType.jsonValue}'
        '${loggedAt.toIso8601String()}';
  }
}
