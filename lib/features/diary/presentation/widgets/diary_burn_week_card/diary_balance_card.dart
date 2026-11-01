import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_after_plan_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_details_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_eaten_view_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_provider.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loading.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Daily budget card of the diary page, with its loading and error states.
class DiaryBalanceCard extends ConsumerWidget {
  /// Creates the diary balance card.
  const new({required this.selectedDay, super.key});

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = normalizeLocalDay(selectedDay);
    final data = ref.watch(diaryBalanceCardProvider(day));
    final showError = ref.watch(
      diaryDayDashboardControllerProvider(day).select((s) => s.showError),
    );

    if (data != null) {
      return DiaryBudgetCard(
        data: DiaryBudgetCardData.from(
          card: data,
          today: ref.watch(diaryTodayProvider),
          nutrition: ref.watch(
            diaryDayDashboardControllerProvider(day)
                .select((s) => s.data?.nutritionBars),
          ),
          openPlans: ref.watch(diaryOpenPlansProvider(day)),
          paceShare: ref.watch(diaryPaceShareProvider(day)),
        ),
        showDetails: ref.watch(diaryBalanceDetailsControllerProvider),
        showEaten: ref.watch(diaryBudgetEatenViewControllerProvider),
        today: ref.watch(diaryTodayProvider),
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
