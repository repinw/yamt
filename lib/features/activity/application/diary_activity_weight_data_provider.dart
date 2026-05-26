import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_service.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';
import 'package:yamt/features/health/presentation/controllers/'
    'manual_health_weight_entries_controller.dart';

part 'diary_activity_weight_data_provider.g.dart';

/// Provides real activity and weight data for the selected diary day.
@riverpod
Future<DiaryActivityWeightData> diaryActivityWeightData(
  Ref ref,
  DateTime day,
) async {
  final selectedDay = normalizeDiaryDay(day);
  final goalState = ref.watch(calorieGoalControllerProvider);
  final statusFuture = ref.watch(healthConnectionControllerProvider.future);
  final manualEntriesFuture = ref.watch(
    manualHealthWeightEntriesControllerProvider.future,
  );
  final service = ref.watch(diaryActivityWeightServiceProvider);
  final diaryHealthService = ref.watch(diaryHealthServiceProvider);
  final healthWeightService = ref.watch(healthWeightServiceProvider);
  final status = await statusFuture;
  if (!ref.mounted) {
    throw StateError('Diary activity weight provider disposed.');
  }
  final manualEntries = await manualEntriesFuture;
  if (!ref.mounted) {
    throw StateError('Diary activity weight provider disposed.');
  }
  final calculatorProfile = goalState.value?.calculatorProfile;

  return service.load(
    day: selectedDay,
    profile: calculatorProfile == null
        ? null
        : DiaryActivityWeightProfile(
            weightKg: calculatorProfile.weightKg,
            heightCm: calculatorProfile.heightCm,
          ),
    healthStatus: status,
    manualEntries: manualEntries,
    diaryHealthService: diaryHealthService,
    healthWeightService: healthWeightService,
    isCancelled: () => !ref.mounted,
  );
}
