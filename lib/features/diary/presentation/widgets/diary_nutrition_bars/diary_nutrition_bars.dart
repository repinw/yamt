import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_food_log_feedback_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars_content.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars_skeleton.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Stable keys for diary nutrition bar tests.
abstract final class DiaryNutritionBarsKeys {
  /// Retry button key.
  static const retryButton = ValueKey<String>(
    'diary-nutrition-bars-retry-button',
  );
}

/// Macro nutrition bars for the diary page.
class DiaryNutritionBars extends ConsumerWidget {
  /// Creates standalone diary nutrition bars.
  const DiaryNutritionBars({
    required this.selectedDay,
    super.key,
  }) : _framed = true,
       _showTitle = true;

  /// Creates embedded diary nutrition bars without a standalone card frame.
  const DiaryNutritionBars.embedded({
    required this.selectedDay,
    super.key,
  }) : _framed = false,
       _showTitle = false;

  /// The selected diary day.
  final DateTime selectedDay;

  /// Whether to draw the standalone card shell.
  final bool _framed;

  /// Whether to show the macro section title.
  final bool _showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedDay = normalizeDiaryDay(selectedDay);
    final dashboardState = ref.watch(
      diaryDayDashboardControllerProvider(normalizedDay),
    );
    final activeFeedback = ref
        .watch(diaryFoodLogFeedbackControllerProvider)
        .firstOrNull;
    final data = dashboardState.data?.nutritionBars;
    final l10n = AppLocalizations.of(context)!;
    final showError = data == null && dashboardState.showError;

    final content = IconTheme.merge(
      data: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      child: showError
          ? MetricErrorRetryContent(
              message: l10n.diaryNutritionLoadFailed,
              retryLabel: l10n.caloriesRetryAction,
              retryButtonKey: DiaryNutritionBarsKeys.retryButton,
              onRetry: () => _retryNutritionBars(ref, normalizedDay),
            )
          : data == null
          ? DiaryNutritionBarsSkeleton(showTitle: _showTitle)
          : DiaryNutritionBarsContent(
              data: data,
              feedback:
                  activeFeedback?.day == normalizedDay &&
                      activeFeedback?.after?.protein == data.protein &&
                      activeFeedback?.after?.carbs == data.carbs &&
                      activeFeedback?.after?.fat == data.fat &&
                      activeFeedback?.after?.goals == data.goals
                  ? activeFeedback
                  : null,
              showTitle: _showTitle,
            ),
    );

    if (!_framed) {
      return content;
    }

    return MetricDetailCardShell(child: content);
  }

  void _retryNutritionBars(WidgetRef ref, DateTime normalizedDay) {
    unawaited(
      ref
          .read(diaryDayDashboardControllerProvider(normalizedDay).notifier)
          .retry(),
    );
  }
}
