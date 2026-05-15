import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_success_card/diary_weekly_checkin_success_card.dart';

/// Shows today's applied weekly check-in success card.
class DiaryWeeklyCheckInSuccessHost extends ConsumerWidget {
  /// Creates diary weekly check-in success host.
  const DiaryWeeklyCheckInSuccessHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalSettings = ref.watch(diaryCalorieGoalSettingsProvider).value;
    final latestEntry = _latestGoalHistoryEntry(goalSettings);
    if (latestEntry?.isWeeklyCheckIn != true ||
        !DateUtils.isSameDay(latestEntry?.effectiveDate, DateTime.now())) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        DiaryWeeklyCheckInSuccessCard(
          goalKcal:
              latestEntry?.dailyKcalGoal ?? goalSettings?.dailyKcalGoal ?? 0,
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
