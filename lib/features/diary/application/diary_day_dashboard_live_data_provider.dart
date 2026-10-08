import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/burn_week_run_controller.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'diary_day_dashboard_live_data_provider.g.dart';

/// Live provider data needed to refresh a cached diary dashboard.
class DiaryDayDashboardLiveData {
  /// Creates live dashboard data.
  const new({
    required this.weekOverview,
    required this.selectedDayEntries,
    required this.plannedEntries,
    required this.runState,
  });

  /// Week overview for the visible diary window.
  final CalorieWeekOverview weekOverview;

  /// Entries logged on the selected day.
  final List<CalorieEntry> selectedDayEntries;

  /// Plans for the selected day.
  final List<CalorieEntry> plannedEntries;

  /// Current Burn Week run state.
  final BurnWeekRunState runState;

  /// Overview for the selected day.
  CalorieWeekDayOverview get selectedDayOverview => weekOverview.days.last;
}

/// Loads live dashboard inputs through Diary's application boundary.
@riverpod
Future<DiaryDayDashboardLiveData> diaryDayDashboardLiveData(
  Ref ref,
  DateTime selectedDay,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    final normalizedDay = normalizeDiaryDay(selectedDay);
    final weekOverviewFuture = ref.watch(
      calorieWeekOverviewForWindowProvider(normalizedDay).future,
    );
    final runStateFuture = ref.watch(burnWeekRunControllerProvider.future);
    final entriesFuture = ref
        .watch(calorieLogRepositoryProvider)
        .readEntriesForDay(normalizedDay);
    // Awaited below; ignore() only keeps an early failure from being
    // reported as unhandled while the other inputs still load.
    final plannedEntriesFuture =
        ref
            .watch(plannedEntryRepositoryProvider)
            .loadPlannedEntriesForDay(normalizedDay)
          ..ignore();

    final weekOverview = await weekOverviewFuture;
    final runState = await runStateFuture;
    final selectedDayEntries = await entriesFuture;
    final plannedEntries = await plannedEntriesFuture;

    return DiaryDayDashboardLiveData(
      weekOverview: weekOverview,
      selectedDayEntries: selectedDayEntries,
      plannedEntries: plannedEntries,
      runState: runState,
    );
  } finally {
    keepAliveLink.close();
  }
}
