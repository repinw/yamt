import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/diary/application/diary_activity_weight_service.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';

/// Provides real activity and weight data for the selected diary day.
final FutureProviderFamily<DiaryActivityWeightData, DateTime>
diaryActivityWeightDataProvider = FutureProvider.autoDispose
    .family<DiaryActivityWeightData, DateTime>((
      ref,
      day,
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
      final manualEntries = await manualEntriesFuture;

      return service.load(
        day: selectedDay,
        goalSettings: goalState.asData?.value,
        healthStatus: status,
        manualEntries: manualEntries,
        diaryHealthService: diaryHealthService,
        healthWeightService: healthWeightService,
      );
    });
