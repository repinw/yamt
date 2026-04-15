import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';

part 'diary_activity_summary_provider.g.dart';

@riverpod
Future<DiaryActivitySummary> diaryActivitySummary(Ref ref) async {
  final selectedDay = ref.watch(calorieDayControllerProvider);
  final status = await ref.watch(healthConnectionControllerProvider.future);
  if (status.accessState != HealthDataAccessState.ready) {
    return DiaryActivitySummary.locked(
      day: selectedDay,
      accessState: status.accessState,
    );
  }

  final dayData = await ref
      .watch(diaryHealthServiceProvider)
      .loadDayData(day: selectedDay);
  return buildDiaryActivitySummary(day: selectedDay, dayData: dayData);
}
