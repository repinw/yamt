import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_times_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';

part 'diary_pace_notice_day_provider.g.dart';

/// What today's pace notices need; no value while they are off, the pace
/// marker is off, nobody is signed in, or today is a pause day; loading
/// while the data key or today's balance loads; an error when the data key
/// failed to load.
@riverpod
AsyncValue<DiaryPaceDay?> diaryPaceNoticeDay(Ref ref) {
  if (!ref.watch(diaryPaceNotificationControllerProvider) ||
      !ref.watch(diaryPaceMarkerControllerProvider)) {
    return const AsyncData(null);
  }
  // Without the data key today's balance never loads.
  if (ref.watch(userDataCipherProvider) == null) {
    final session = ref.watch(userDataKeySessionProvider);
    if (session.isLoading) return const AsyncLoading();
    final error = session.error;
    return error == null
        ? const AsyncData(null)
        : AsyncError(error, session.stackTrace ?? StackTrace.current);
  }
  final today = ref.watch(diaryTodayProvider);
  final card = ref.watch(diaryBalanceCardProvider(today));
  if (card == null) return const AsyncLoading();
  final daily = _dailyBalance(card);
  if (daily == null) return const AsyncData(null);
  final nutrition = ref.watch(
    diaryDayDashboardControllerProvider(today)
        .select((s) => s.data?.nutritionBars),
  );
  return AsyncData((
    day: today,
    targetKcal: daily.targetKcal,
    eatenKcal: daily.eatenKcal,
    times: ref.watch(diaryMealTimesControllerProvider),
    shares: ref.watch(diaryMealSharesControllerProvider),
    macro: nutrition == null
        ? null
        : diaryPaceMacro(
            eaten: (
              protein: nutrition.protein,
              carbs: nutrition.carbs,
              fat: nutrition.fat,
            ),
            targets: (
              protein: nutrition.goals.protein,
              carbs: nutrition.goals.carbs,
              fat: nutrition.goals.fat,
            ),
          ),
  ));
}

/// What tomorrow's day-start notice needs: the day, its kcal budget (null
/// on a pause day or while the notices are off), and the meal times and
/// shares that decide when and how much. The times and shares are part of the
/// value so a change of them syncs again, also while today is a pause day.
typedef DiaryPaceTomorrow = ({
  DateTime day,
  double? targetKcal,
  DiaryMealTimes times,
  DiaryMealShares shares,
});

/// Tomorrow's notice data, with the budget from the same week overview the
/// budget card shows when the user opens tomorrow: carryover (#911), training
/// days, and pause day. Loading while the data key or the budget loads, an
/// error when either failed to load; no budget when nobody is signed in.
@riverpod
AsyncValue<DiaryPaceTomorrow> diaryPaceTomorrowTarget(Ref ref) {
  final day = nextLocalDay(ref.watch(diaryTodayProvider));
  final times = ref.watch(diaryMealTimesControllerProvider);
  final shares = ref.watch(diaryMealSharesControllerProvider);
  DiaryPaceTomorrow tomorrow(double? targetKcal) =>
      (day: day, targetKcal: targetKcal, times: times, shares: shares);
  if (!ref.watch(diaryPaceNotificationControllerProvider) ||
      !ref.watch(diaryPaceMarkerControllerProvider)) {
    return AsyncData(tomorrow(null));
  }
  if (ref.watch(userDataCipherProvider) == null) {
    final session = ref.watch(userDataKeySessionProvider);
    if (session.isLoading) return const AsyncLoading();
    final error = session.error;
    return error == null
        ? AsyncData(tomorrow(null))
        : AsyncError(error, session.stackTrace ?? StackTrace.current);
  }
  final budget = ref.watch(diaryDayBudgetKcalProvider(day));
  if (budget.hasValue) return AsyncData(tomorrow(budget.value));
  final error = budget.error;
  return error == null
      ? const AsyncLoading()
      : AsyncError(error, budget.stackTrace ?? StackTrace.current);
}

/// The daily numbers of a day's balance card; null while it loads or on a
/// pause day. Practice days and the days before a restart show the marker
/// too.
DiaryDailyBalanceMetrics? _dailyBalance(DiaryBalanceCardData? card) {
  if (card == null || (card.loadedMetrics?.state.isPauseDay ?? false)) {
    return null;
  }
  return card.loadedMetrics?.daily ??
      card.practiceDay?.daily ??
      card.scheduledRestart!.daily;
}
