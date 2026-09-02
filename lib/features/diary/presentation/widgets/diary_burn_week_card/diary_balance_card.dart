import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loading.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_practice_day_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_scheduled_restart_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_balance_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Calorie balance card for the diary page.
class DiaryBalanceCard extends ConsumerWidget {
  /// Creates the diary balance card.
  const DiaryBalanceCard({
    required this.selectedDay,
    super.key,
  });

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = normalizeDiaryDay(selectedDay);
    final dashboardData = ref.watch(
      diaryDayDashboardControllerProvider(day).select((s) => s.data),
    );
    final showError = ref.watch(
      diaryDayDashboardControllerProvider(day).select((s) => s.showError),
    );

    if (dashboardData != null) {
      final data = DiaryBalanceSource.fromDashboardData(dashboardData).resolve(
        now: DateTime.now(),
      );

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

      final numberFormat = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag(),
      );
      final l10n = AppLocalizations.of(context)!;
      final dailyData = DiaryDailyBalanceData.from(
        selectedDay: data.loadedMetrics!.selectedDay,
        metrics: data.loadedMetrics!.daily,
        isHeartDay: data.loadedMetrics!.state.isHeartDay,
        canRevertHeartDay: data.loadedMetrics!.state.canRevertHeartDay,
        numberFormat: numberFormat,
        l10n: l10n,
      );

      return DiaryDailyBalanceCard(
        data: dailyData,
        onUnmarkHeartDay: (d) => unawaited(
          ref.read(diaryBalanceActionsProvider).unmarkHeartDay(d),
        ),
      );
    }

    if (showError) {
      final l10n = AppLocalizations.of(context)!;
      return DiaryBalanceShell(
        child: MetricErrorRetryContent(
          message: l10n.diaryBalanceLoadFailed,
          retryLabel: l10n.caloriesRetryAction,
          retryButtonKey: DiaryBalanceCardKeys.retryButton,
          onRetry: () => unawaited(
            ref
                .read(diaryDayDashboardControllerProvider(day).notifier)
                .retry(),
          ),
        ),
      );
    }

    return const DiaryBalanceLoading();
  }
}
