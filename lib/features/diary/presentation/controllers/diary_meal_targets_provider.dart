import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';

part 'diary_meal_targets_provider.g.dart';

/// Each meal's part of [day]'s kcal target, split by the user's parts of
/// the day, for the meal headings. Null while the pace marker is off, while
/// the day loads, and on a pause day, which has no target; a meal set to 0
/// has no part.
@riverpod
Map<MealType, double>? diaryMealTargets(Ref ref, DateTime day) {
  if (!ref.watch(diaryPaceMarkerControllerProvider)) return null;
  final card = ref.watch(diaryBalanceCardProvider(day));
  if (card == null || (card.loadedMetrics?.state.isPauseDay ?? false)) {
    return null;
  }
  final daily =
      card.loadedMetrics?.daily ??
      card.practiceDay?.daily ??
      card.scheduledRestart!.daily;
  final shares = ref.watch(diaryMealSharesControllerProvider);
  final parts = shares.splitKcal(daily.targetKcal);
  return {
    for (final (i, meal) in MealType.sectionOrder.indexed)
      if (shares.of(meal) > 0) meal: parts[i].toDouble(),
  };
}
