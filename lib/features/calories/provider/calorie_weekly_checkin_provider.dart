import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_data_builder.dart';

part 'calorie_weekly_checkin_provider.g.dart';

/// Calorie weekly check in data.
@riverpod
Future<CalorieWeeklyCheckInData> calorieWeeklyCheckInData(
  Ref ref,
) {
  return buildCalorieWeeklyCheckInData(ref);
}

/// Invalidates all calorie weekly check-in data providers.
void invalidateCalorieWeeklyCheckInData(Ref ref) {
  ref.invalidate(calorieWeeklyCheckInDataProvider);
}
