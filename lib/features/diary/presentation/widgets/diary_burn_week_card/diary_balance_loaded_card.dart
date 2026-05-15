import 'package:flutter/material.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_content.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_practice_day_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_scheduled_restart_card.dart';

/// Loaded Burn Week balance card content.
class DiaryBalanceLoadedCard extends StatelessWidget {
  /// Creates loaded Burn Week balance content.
  const DiaryBalanceLoadedCard({
    required this.data,
    required this.onUnmarkHeartDay,
    super.key,
  });

  /// Resolved card data.
  final DiaryBalanceCardData data;

  /// Reverts a heart day.
  final ValueChanged<DateTime> onUnmarkHeartDay;

  @override
  Widget build(BuildContext context) {
    final scheduledRestartDate = data.scheduledRestartDate;
    if (scheduledRestartDate != null) {
      return DiaryBalanceScheduledRestartCard(
        scheduledRestartDate: scheduledRestartDate,
      );
    }
    final practiceDay = data.practiceDay;
    if (practiceDay != null) {
      return DiaryBalancePracticeDayCard(
        startDate: practiceDay.startDate,
        futureGoalKcal: practiceDay.futureGoalKcal,
      );
    }

    return DiaryBalanceLoadedContent(
      resolvedMetrics: data.loadedMetrics!,
      onUnmarkHeartDay: onUnmarkHeartDay,
    );
  }
}
