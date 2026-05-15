import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/provider/calorie_health_trend_provider.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';

part 'calorie_weight_state_refresh.g.dart';

/// Refreshes calorie-owned state that depends on weight changes.
@riverpod
CalorieWeightStateRefresh calorieWeightStateRefresh(
  Ref ref,
) {
  return () {
    if (!ref.mounted) {
      return;
    }
    ref
      ..invalidate(calorieHealthTrendSnapshotProvider)
      ..invalidate(calorieWeeklyCheckInViewModelProvider);
  };
}

/// Refresh callback for calorie-owned weight dependents.
typedef CalorieWeightStateRefresh = void Function();
