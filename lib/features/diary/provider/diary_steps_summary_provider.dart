import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';

/// Provides real step data for one diary day.
final FutureProviderFamily<DiaryActivitySummary, DateTime>
diaryStepsSummaryProvider = FutureProvider.autoDispose
    .family<DiaryActivitySummary, DateTime>((
      ref,
      day,
    ) async {
      final normalizedDay = normalizeDiaryDay(day);
      final userHeightCm = ref
          .watch(calorieGoalControllerProvider)
          .value
          ?.calculatorProfile
          ?.heightCm;
      final statusFuture = ref.watch(healthConnectionControllerProvider.future);
      final diaryHealthService = ref.watch(diaryHealthServiceProvider);
      final status = await statusFuture;
      if (status.accessState != HealthDataAccessState.ready) {
        return DiaryActivitySummary.locked(
          day: normalizedDay,
          accessState: status.accessState,
        );
      }

      final dayData = await diaryHealthService.loadDayData(
        day: normalizedDay,
        userHeightCm: userHeightCm,
      );
      return buildDiaryActivitySummary(day: normalizedDay, dayData: dayData);
    });
