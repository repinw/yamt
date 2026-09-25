import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_details_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loading.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_scheduled_restart_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_balance_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Calorie balance card for the diary page.
class DiaryBalanceCard extends ConsumerWidget {
  /// Creates the diary balance card.
  const new({
    required this.selectedDay,
    this.kcalBarKey,
    this.macroBarsKey,
    super.key,
  });

  /// The selected diary day.
  final DateTime selectedDay;

  /// Key of the daily kcal progress bar.
  final Key? kcalBarKey;

  /// Key of the daily macro bars.
  final Key? macroBarsKey;

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
      final now = ref.watch(clockProvider)();
      final data = DiaryBalanceSource.fromDashboardData(dashboardData)
          .resolve(now: now);

      final scheduledRestartDate = data.scheduledRestartDate;
      if (scheduledRestartDate != null) {
        return DiaryBalanceScheduledRestartCard(
          scheduledRestartDate: scheduledRestartDate,
        );
      }

      final numberFormat = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag(),
      );
      final l10n = AppLocalizations.of(context)!;
      final practiceDay = data.practiceDay;
      final dailyData = practiceDay != null
          ? DiaryDailyBalanceData.from(
              selectedDay: day,
              metrics: practiceDay.daily,
              isPauseDay: false,
              numberFormat: numberFormat,
              l10n: l10n,
              now: now,
            )
          : DiaryDailyBalanceData.from(
              selectedDay: data.loadedMetrics!.selectedDay,
              metrics: data.loadedMetrics!.daily,
              isPauseDay: data.loadedMetrics!.state.isPauseDay,
              numberFormat: numberFormat,
              l10n: l10n,
              now: now,
              budgetDetails: data.loadedMetrics!.budgetDetails,
            );

      return DiaryDailyBalanceCard(
        data: dailyData,
        showDetails: ref.watch(diaryBalanceDetailsControllerProvider),
        onToggleDetails: () => unawaited(
          ref.read(diaryBalanceDetailsControllerProvider.notifier).toggle(),
        ),
        kcalBarKey: kcalBarKey,
        macroBarsKey: macroBarsKey,
        practiceStartDate: practiceDay?.startDate,
      );
    }

    if (showError) {
      final l10n = AppLocalizations.of(context)!;
      return DiaryBalanceShell(
        framed: false,
        child: MetricErrorRetryContent(
          message: l10n.diaryBalanceLoadFailed,
          retryLabel: l10n.caloriesRetryAction,
          retryButtonKey: DiaryBalanceCardKeys.retryButton,
          onRetry: () => unawaited(
            ref.read(diaryDayDashboardControllerProvider(day).notifier).retry(),
          ),
        ),
      );
    }

    return const DiaryBalanceLoading();
  }
}
