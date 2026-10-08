import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/application/diary_home_widget_summary.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';

part 'diary_home_widget_summary_provider.g.dart';

/// Watches today's diary dashboard and exposes a flat summary for the
/// home-screen widget feature. Uses the same daily metrics as the Diary
/// balance card, so the widget shows the same numbers. `null` while today's
/// dashboard has not loaded yet.
///
/// Lives in `presentation/` because it derives from the dashboard
/// controller's state.
@riverpod
DiaryHomeWidgetSummary? diaryHomeWidgetSummary(Ref ref) {
  final today = ref.watch(diaryTodayProvider);
  final dashboardState = ref.watch(diaryDayDashboardControllerProvider(today));
  final data = dashboardState.data;
  if (data == null) {
    return null;
  }
  final daily = ref
      .watch(diaryBalanceCardProvider(today))
      ?.loadedMetrics
      ?.daily;
  final selectedDayOverview = data.weekOverview.days.last;
  return DiaryHomeWidgetSummary(
    eatenKcal: daily?.eatenKcal ?? selectedDayOverview.totalKcal,
    targetKcal: daily?.targetKcal ?? selectedDayOverview.goalKcal,
    macros: data.nutritionBars,
  );
}
