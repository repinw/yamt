import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_view_model_builder.dart';

part 'calorie_weekly_checkin_provider.g.dart';

/// Calorie weekly check in view model.
@riverpod
Future<CalorieWeeklyCheckInViewModel> calorieWeeklyCheckInViewModel(
  Ref ref,
) {
  return buildCalorieWeeklyCheckInViewModel(ref);
}
