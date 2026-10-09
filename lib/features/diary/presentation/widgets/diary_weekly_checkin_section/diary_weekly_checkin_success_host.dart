import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_weekly_checkin_success_dismissal_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_success_card/diary_weekly_checkin_success_card.dart';

/// Shows the success card of a weekly check-in applied today, only on
/// today's diary page and until the user closes it.
class DiaryWeeklyCheckInSuccessHost extends ConsumerWidget {
  /// Creates diary weekly check-in success host.
  const new({required this.selectedDay, required this.onRedo, super.key});

  /// Selected diary day.
  final DateTime selectedDay;

  /// Opens the check-in of the applied window again for a new decision.
  final Future<void> Function(PendingCalorieGoalWeeklyCheckIn checkIn) onRedo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clockProvider)();
    final goalSettings = ref.watch(diaryCalorieGoalSettingsProvider).value;
    final latestEntry = _latestGoalHistoryEntry(goalSettings);
    final effectiveDate = latestEntry?.effectiveDate;
    final dismissedDayKey = ref.watch(
      diaryWeeklyCheckInSuccessDismissalControllerProvider,
    );
    if (latestEntry?.isWeeklyCheckIn != true ||
        effectiveDate == null ||
        !DateUtils.isSameDay(effectiveDate, today) ||
        !DateUtils.isSameDay(selectedDay, today) ||
        dismissedDayKey == diaryDayKey(effectiveDate)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        DiaryWeeklyCheckInSuccessCard(
          goalKcal:
              latestEntry?.dailyKcalGoal ?? goalSettings?.dailyKcalGoal ?? 0,
          // A window with changed inputs is already open again.
          onRedo: switch (latestEntry!.weeklyCheckInSnapshot) {
            final snapshot? when !snapshot.isInputDirty => () => onRedo(
              snapshot.reopenedCheckIn,
            ),
            _ => null,
          },
          onDismiss: () => ref
              .read(
                diaryWeeklyCheckInSuccessDismissalControllerProvider.notifier,
              )
              .dismiss(diaryDayKey(effectiveDate)),
        ),
      ],
    );
  }

  CalorieGoalHistoryEntry? _latestGoalHistoryEntry(
    CalorieGoalSettings? settings,
  ) {
    final history = settings?.sortedGoalHistory;
    if (history == null || history.isEmpty) {
      return null;
    }
    for (final entry in history.reversed) {
      if (entry.hasGoal) {
        return entry;
      }
    }
    return null;
  }
}
