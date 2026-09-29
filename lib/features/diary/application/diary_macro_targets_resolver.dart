import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

/// Resolves the macro targets of [day] from user preferences and calorie goal.
///
/// Delegates to [dailyNutritionTargetResolverProvider] for decoupled
/// computation.
DiaryMacroTargets resolveDiaryMacroTargets(
  Ref ref, {
  required DateTime day,
  required double goalKcal,
  double carryoverKcal = 0,
}) {
  final resolver = ref.read(dailyNutritionTargetResolverProvider);
  final target = resolver.resolveTarget(
    day: day,
    goalKcal: goalKcal,
    carryoverKcal: carryoverKcal,
  );
  return DiaryMacroTargets(
    carbs: target.carbsGrams,
    protein: target.proteinGrams,
    fat: target.fatGrams,
  );
}

/// Resolves how much [carryoverKcal] changes the macro targets of [day]: the
/// targets with the carryover minus the targets without it.
DiaryMacroTargets resolveDiaryCarryoverMacroDelta(
  Ref ref, {
  required DateTime day,
  required double goalKcal,
  required double carryoverKcal,
}) {
  final resolver = ref.read(dailyNutritionTargetResolverProvider);
  final withCarryover = resolver.resolveTarget(
    day: day,
    goalKcal: goalKcal,
    carryoverKcal: carryoverKcal,
  );
  final base = resolver.resolveBaseTarget(day: day, goalKcal: goalKcal);
  return DiaryMacroTargets(
    carbs: withCarryover.carbsGrams - base.carbsGrams,
    protein: withCarryover.proteinGrams - base.proteinGrams,
    fat: withCarryover.fatGrams - base.fatGrams,
  );
}
