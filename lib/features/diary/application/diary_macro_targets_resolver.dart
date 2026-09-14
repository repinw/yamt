import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

/// Resolves daily macro targets using user preferences and calorie goal.
///
/// Delegates to [dailyNutritionTargetResolverProvider] for decoupled
/// computation.
DiaryMacroTargets resolveDiaryMacroTargets(
  Ref ref, {
  required double goalKcal,
  double carryoverKcal = 0,
}) {
  final resolver = ref.read(dailyNutritionTargetResolverProvider);
  final target = resolver.resolveTarget(
    day: DateTime.now(),
    goalKcal: goalKcal,
    carryoverKcal: carryoverKcal,
  );
  return DiaryMacroTargets(
    carbs: target.carbsGrams,
    protein: target.proteinGrams,
    fat: target.fatGrams,
  );
}
