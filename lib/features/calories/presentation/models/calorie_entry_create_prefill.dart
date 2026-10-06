import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

/// Defines calorie entry create prefill.
class CalorieEntryCreatePrefill {
  /// The calorie entry create prefill.
  const new({
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
  factory fromArgs({
    required CalorieProductProfile? prefilledProfile,
    required double? prefilledAmount,
    required ConsumedUnit? prefilledUnit,
    required MealType? preselectedMealType,
    required DateTime? preselectedLoggedAt,
  }) {
    final consumedAmount = prefilledAmount ?? 100;
    final consumedUnit = prefilledUnit ?? ConsumedUnit.grams;
    final loggedAt = preselectedLoggedAt ?? DateTime.now();
    final mealType =
        preselectedMealType ?? MealType.defaultForDateTime(loggedAt);

    return CalorieEntryCreatePrefill(
      initializationKey: _buildInitializationKey(
        prefilledProfile: prefilledProfile,
        consumedAmount: consumedAmount,
        consumedUnit: consumedUnit,
        mealType: mealType,
        loggedAt: loggedAt,
      ),
      name: prefilledProfile?.name ?? '',
      brand: prefilledProfile?.brand ?? '',
      consumedAmount: consumedAmount,
      per100Kcal: prefilledProfile?.per100Kcal ?? 0,
      per100Protein: prefilledProfile?.per100Protein ?? 0,
      per100Carbs: prefilledProfile?.per100Carbs ?? 0,
      per100Fat: prefilledProfile?.per100Fat ?? 0,
      mealType: mealType,
      consumedUnit: consumedUnit,
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
    required double consumedAmount,
    required ConsumedUnit consumedUnit,
    required MealType mealType,
    required DateTime loggedAt,
  }) {
    return '__new_entry__'
        '${prefilledProfile?.barcode ?? ''}_'
        '${prefilledProfile?.source.jsonValue ?? 'none'}_'
        '$consumedAmount'
        '${consumedUnit.jsonValue}'
        '${mealType.jsonValue}'
        '${loggedAt.toIso8601String()}';
  }
}
