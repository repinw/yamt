import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';

/// Builds loaded dashboard state for Diary widget tests.
DiaryDayDashboardState diaryDashboardLoadedStateForTest({
  required DateTime selectedDay,
  CalorieWeekOverview? weekOverview,
  List<CalorieEntry> selectedDayEntries = const <CalorieEntry>[],
  BurnWeekRunState runState = const BurnWeekRunState.initial(),
  List<DiaryMealSection> mealSections = const <DiaryMealSection>[],
  DiaryNutritionBarsData nutritionBars = const DiaryNutritionBarsData(
    carbs: 0,
    protein: 0,
    fat: 0,
    goals: DiaryMacroTargets(carbs: 0, protein: 0, fat: 0),
  ),
  bool isFromCache = false,
  bool isRefreshing = false,
}) {
  final normalizedDay = normalizeDiaryDay(selectedDay);
  return DiaryDayDashboardState(
    data: DiaryDayDashboardData(
      selectedDay: normalizedDay,
      refreshedAt: DateTime(2026),
      weekOverview:
          weekOverview ?? diaryWeekOverviewForTest(selectedDay: normalizedDay),
      selectedDayEntries: selectedDayEntries,
      runState: runState,
      mealSections: mealSections,
      nutritionBars: nutritionBars,
    ),
    isFromCache: isFromCache,
    isRefreshing: isRefreshing,
    error: null,
  );
}

/// Builds failed dashboard state for Diary widget tests.
DiaryDayDashboardState diaryDashboardErrorStateForTest(Object error) {
  return DiaryDayDashboardState(
    data: null,
    isFromCache: false,
    isRefreshing: false,
    error: error,
  );
}

/// Builds simple 7-day week overview ending at [selectedDay].
CalorieWeekOverview diaryWeekOverviewForTest({
  required DateTime selectedDay,
  List<double> dayTotals = const <double>[0, 0, 0, 0, 0, 0, 0],
  double goalKcal = 2000,
}) {
  final normalizedDay = normalizeDiaryDay(selectedDay);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: normalizedDay.subtract(Duration(days: offset)),
        totalKcal: dayTotals[6 - offset],
        goalKcal: goalKcal,
        entryCount: dayTotals[6 - offset] > 0 ? 1 : 0,
      ),
  ];
  final totalConsumedKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.totalKcal,
  );
  final totalGoalKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.goalKcal,
  );
  return CalorieWeekOverview(
    days: days,
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: totalGoalKcal - totalConsumedKcal,
    balanceStartDate: normalizedDay.subtract(const Duration(days: 6)),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: goalKcal,
    nextGoalStartDate: null,
    futureGoalKcal: null,
    goalStartsInFuture: false,
  );
}

/// Fake dashboard controller with optional retry transition.
class FakeDiaryDayDashboardController extends DiaryDayDashboardController {
  /// Creates fake controller.
  FakeDiaryDayDashboardController(
    this.initialState, {
    this.onRetry,
  });

  /// Initial state returned from build.
  final DiaryDayDashboardState initialState;

  /// Optional state builder called when retry is invoked.
  final DiaryDayDashboardState? Function(int retryCount)? onRetry;

  int _retryCount = 0;

  @override
  DiaryDayDashboardState build(DateTime selectedDay) {
    return initialState;
  }

  @override
  Future<void> retry() async {
    _retryCount += 1;
    final nextState = onRetry?.call(_retryCount);
    if (nextState != null) {
      state = nextState;
    }
  }

  @override
  void refreshAfterMutation() {
    _retryCount += 1;
    final nextState = onRetry?.call(_retryCount);
    if (nextState != null) {
      state = nextState;
    }
  }

  // Test fake must mutate inherited Notifier state without exposing a setter.
  // ignore: use_setters_to_change_properties
  void _replaceState(DiaryDayDashboardState nextState) {
    state = nextState;
  }
}

/// Emits a state from a fake dashboard controller in widget tests.
void replaceFakeDiaryDashboardState(
  FakeDiaryDayDashboardController controller,
  DiaryDayDashboardState nextState,
) {
  controller._replaceState(nextState);
}
