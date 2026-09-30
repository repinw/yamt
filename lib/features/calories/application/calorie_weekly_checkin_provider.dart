import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_data_builder.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';

part 'calorie_weekly_checkin_provider.g.dart';

/// Calorie weekly check in data.
@riverpod
Future<CalorieWeeklyCheckInData> calorieWeeklyCheckInData(Ref ref) {
  return buildCalorieWeeklyCheckInData(ref);
}

/// Weekly check-in data of the latest completed window, decided or not, or
/// demo data when the goal has no completed window yet.
///
/// Only for the debug preview of the check-in sheet.
@riverpod
Future<CalorieWeeklyCheckInData> calorieWeeklyCheckInPreviewData(
  Ref ref,
) async {
  final today = ref.watch(clockProvider)();
  final data = await buildCalorieWeeklyCheckInData(
    ref,
    previewLatestWindow: true,
  );
  return data.pendingWeeklyCheckIn == null
      ? calorieWeeklyCheckInDemoData(today: today)
      : data;
}

/// Invalidates all calorie weekly check-in data providers.
void invalidateCalorieWeeklyCheckInData(Ref ref) {
  ref.invalidate(calorieWeeklyCheckInDataProvider);
}
