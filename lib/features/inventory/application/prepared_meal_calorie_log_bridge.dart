import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart'
    show InventoryAmountUnit, InventoryAmountUnitCode;
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'prepared_meal_calorie_log_bridge.g.dart';

const _bridgeLogName = 'PreparedMealCalorieLogBridge';

/// Bridges prepared-meal consumption into the calorie diary domain.
abstract interface class PreparedMealCalorieLogBridge {
  Future<bool> logConsumedPreparedMeal({
    required PreparedMeal meal,
    required int consumedPortions,
    required MealType mealType,
  });
}

@riverpod
PreparedMealCalorieLogBridge preparedMealCalorieLogBridge(Ref ref) {
  return _RepositoryPreparedMealCalorieLogBridge(
    calorieLogRepository: ref.read(calorieLogRepositoryProvider),
    now: DateTime.now,
  );
}

class _RepositoryPreparedMealCalorieLogBridge
    implements PreparedMealCalorieLogBridge {
  _RepositoryPreparedMealCalorieLogBridge({
    required CalorieLogRepositoryContract calorieLogRepository,
    required DateTime Function() now,
  }) : _calorieLogRepository = calorieLogRepository,
       _now = now;

  static const _uuid = Uuid();

  final CalorieLogRepositoryContract _calorieLogRepository;
  final DateTime Function() _now;

  @override
  Future<bool> logConsumedPreparedMeal({
    required PreparedMeal meal,
    required int consumedPortions,
    required MealType mealType,
  }) {
    if (meal.totalPortions < 1 || consumedPortions < 1) {
      return Future<bool>.value(false);
    }

    final now = _now();
    final portionRatio = consumedPortions / meal.totalPortions;
    final entry = CalorieEntry.bundle(
      id: _uuid.v4(),
      userId: '',
      name: meal.name,
      imageBase64: meal.imageBase64,
      mealType: mealType,
      totalKcal: meal.totalKcal * portionRatio,
      totalProtein: meal.totalProtein * portionRatio,
      totalCarbs: meal.totalCarbs * portionRatio,
      totalFat: meal.totalFat * portionRatio,
      bundleSourcePreparedMealId: meal.id,
      bundleConsumedPortions: consumedPortions,
      bundleTotalPortions: meal.totalPortions,
      bundleComponents: _buildBundleComponents(
        meal: meal,
        portionRatio: portionRatio,
      ),
      loggedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    log(
      'Writing prepared meal bundle mealId=${meal.id} '
      'consumedPortions=$consumedPortions '
      'portionRatio=${portionRatio.toStringAsFixed(4)} '
      'components=${entry.bundleComponents.length}.',
      name: _bridgeLogName,
    );
    return _calorieLogRepository.saveEntry(entry);
  }
}

List<CalorieEntryBundleComponent> _buildBundleComponents({
  required PreparedMeal meal,
  required double portionRatio,
}) {
  return meal.components
      .map(
        (component) => CalorieEntryBundleComponent(
          name: component.name,
          brand: component.brand,
          imageUrl: component.imageUrl,
          amountLabel: _formatMealComponentAmountLabel(
            amount: (component.usedAmount * portionRatio).toStringAsFixed(1),
            unit: component.usedUnit,
          ),
          totalKcal: component.totalKcal * portionRatio,
          totalProtein: component.totalProtein * portionRatio,
          totalCarbs: component.totalCarbs * portionRatio,
          totalFat: component.totalFat * portionRatio,
        ),
      )
      .toList(growable: false);
}

String _formatMealComponentAmountLabel({
  required String amount,
  required InventoryAmountUnit unit,
}) {
  final normalizedAmount = amount.endsWith('.0')
      ? amount.substring(0, amount.length - 2)
      : amount;
  return '$normalizedAmount ${unit.code}';
}
