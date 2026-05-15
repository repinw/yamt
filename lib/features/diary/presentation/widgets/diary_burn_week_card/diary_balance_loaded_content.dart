import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_weekly_balance_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Loaded Burn Week balance UI after metrics have been resolved.
class DiaryBalanceLoadedContent extends StatelessWidget {
  /// Creates loaded Burn Week balance UI.
  const DiaryBalanceLoadedContent({
    required this.resolvedMetrics,
    required this.onUnmarkHeartDay,
    super.key,
  });

  /// Derived metrics for the loaded card.
  final DiaryBalanceLoadedMetrics resolvedMetrics;

  /// Reverts a heart day.
  final ValueChanged<DateTime> onUnmarkHeartDay;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final dailyData = DiaryDailyBalanceData.from(
      selectedDay: resolvedMetrics.selectedDay,
      metrics: resolvedMetrics.daily,
      isHeartDay: resolvedMetrics.state.isHeartDay,
      canRevertHeartDay: resolvedMetrics.state.canRevertHeartDay,
      numberFormat: numberFormat,
      l10n: l10n,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiaryDailyBalanceCard(
          data: dailyData,
          onUnmarkHeartDay: onUnmarkHeartDay,
        ),
        const SizedBox(height: AppSpacing.xl),
        DiaryWeeklyBalanceCard(
          weeklyMetrics: resolvedMetrics.weekly,
          runWeekNumber: resolvedMetrics.state.runWeekNumber,
          numberFormat: numberFormat,
        ),
      ],
    );
  }
}
