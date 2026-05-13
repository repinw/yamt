import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_callbacks.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_content.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_practice_day_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_scheduled_restart_card.dart';

/// Loaded Burn Week balance card content.
class DiaryBalanceLoadedCard extends StatelessWidget {
  /// Creates loaded Burn Week balance content.
  const DiaryBalanceLoadedCard({
    required this.weekOverview,
    required this.selectedDayOverview,
    required this.selectedDayEntries,
    required this.selectedDayEntriesLoaded,
    required this.runState,
    required this.isLiveDay,
    required this.hasAutoOpeningWeeklyCheckIn,
    required this.onQueueZoneDialog,
    required this.onShowUseHeartDialog,
    required this.onUnmarkHeartDay,
    super.key,
  });

  /// Weekly calorie overview.
  final CalorieWeekOverview weekOverview;

  /// Selected day overview.
  final CalorieWeekDayOverview selectedDayOverview;

  /// Entries for the selected live day.
  final List<CalorieEntry> selectedDayEntries;

  /// Whether live selected-day entries finished loading.
  final bool selectedDayEntriesLoaded;

  /// Current Burn Week run state.
  final BurnWeekRunState runState;

  /// Whether the selected day is today.
  final bool isLiveDay;

  /// Whether weekly check-in is about to open and should own dialogs.
  final bool hasAutoOpeningWeeklyCheckIn;

  /// Queues zone dialogs when the loaded live card is out of zone.
  final DiaryBalanceZoneDialogQueue onQueueZoneDialog;

  /// Opens the use-heart dialog.
  final DiaryBalanceUseHeartDialog onShowUseHeartDialog;

  /// Reverts a heart day.
  final ValueChanged<DateTime> onUnmarkHeartDay;

  @override
  Widget build(BuildContext context) {
    final scheduledRestartDate = resolveDiaryBalanceScheduledRestartDate(
      runState: runState,
      today: selectedDayOverview.date,
      isLiveDay: isLiveDay,
    );
    if (scheduledRestartDate != null) {
      return DiaryBalanceScheduledRestartCard(
        scheduledRestartDate: scheduledRestartDate,
      );
    }
    if (shouldShowDiaryBalancePracticeDayCard(
      weekOverview: weekOverview,
      selectedDay: selectedDayOverview.date,
    )) {
      return DiaryBalancePracticeDayCard(
        startDate: weekOverview.nextGoalStartDate!,
        futureGoalKcal: weekOverview.futureGoalKcal,
      );
    }

    final resolvedMetrics = resolveDiaryBalanceLoadedMetrics(
      weekOverview: weekOverview,
      selectedDayOverview: selectedDayOverview,
      selectedDayEntries: selectedDayEntries,
      runState: runState,
      isLiveDay: isLiveDay,
    );
    if (resolvedMetrics.showGameControls &&
        selectedDayEntriesLoaded &&
        !hasAutoOpeningWeeklyCheckIn &&
        !resolvedMetrics.isHeartDay) {
      onQueueZoneDialog(metrics: resolvedMetrics.metrics, runState: runState);
    }

    return DiaryBalanceLoadedContent(
      resolvedMetrics: resolvedMetrics,
      runState: runState,
      onShowUseHeartDialog: onShowUseHeartDialog,
      onUnmarkHeartDay: onUnmarkHeartDay,
    );
  }
}
