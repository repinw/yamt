import 'package:yamt/features/calories/domain/daily_nutrition_target.dart';

/// Decoupled feature contract for resolving daily nutrition goals
/// (calories & macros).
abstract interface class DailyNutritionTargetResolver {
  /// Resolves the complete daily nutrition target for [day].
  DailyNutritionTarget resolveTarget({
    required DateTime day,
    required double goalKcal,
    double carryoverKcal = 0.0,
  });

  /// Resolves the base nutrition target for [day] without carryover.
  DailyNutritionTarget resolveBaseTarget({
    required DateTime day,
    required double goalKcal,
  });
}
