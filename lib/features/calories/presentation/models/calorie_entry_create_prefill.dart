import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';

/// Defines calorie entry create prefill.
class CalorieEntryCreatePrefill {
  /// The calorie entry create prefill.
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

  /// Creates a [CalorieEntryCreatePrefill] for from args.
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

  /// The initialization key.
  final String initializationKey;

  /// The name.
  final String name;

  /// The brand.
  final String? brand;

  /// The consumed amount.
  final double consumedAmount;

  /// The per100 kcal.
  final double per100Kcal;

  /// The per100 protein.
  final double per100Protein;

  /// The per100 carbs.
  final double per100Carbs;

  /// The per100 fat.
  final double per100Fat;

  /// The meal type.
  final MealType mealType;

  /// The consumed unit.
  final ConsumedUnit consumedUnit;

  /// The logged at.
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
