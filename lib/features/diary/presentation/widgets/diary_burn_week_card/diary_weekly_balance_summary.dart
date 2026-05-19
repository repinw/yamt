import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_now_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_weekly_balance_card.dart';

/// Compact weekly Burn Week summary for fused diary metric cards.
class DiaryWeeklyBalanceSummary extends ConsumerStatefulWidget {
  /// Creates a weekly balance summary.
  const DiaryWeeklyBalanceSummary({required this.selectedDay, super.key});

  /// Selected diary day.
  final DateTime selectedDay;

  @override
  ConsumerState<DiaryWeeklyBalanceSummary> createState() {
    return _DiaryWeeklyBalanceSummaryState();
  }
}

class _DiaryWeeklyBalanceSummaryState
    extends ConsumerState<DiaryWeeklyBalanceSummary> {
  DiaryBalanceSource? _lastSource;

  @override
  Widget build(BuildContext context) {
    final normalizedDay = normalizeDiaryDay(widget.selectedDay);
    final sourceState = ref.watch(diaryBalanceSourceProvider(normalizedDay));
    final source = sourceState.value;
    if (source != null) {
      _lastSource = source;
    }

    final effectiveSource = source ?? _lastSource;
    if (effectiveSource == null) {
      if (sourceState.hasError) {
        return const SizedBox.shrink();
      }
      return const _WeeklyBalanceSummarySkeleton();
    }

    final data = effectiveSource.resolve(
      now: ref.watch(calorieBalanceNowProvider)(),
    );
    final loadedMetrics = data.loadedMetrics;
    if (loadedMetrics == null) {
      return const SizedBox.shrink();
    }

    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return DiaryWeeklyBalanceCard(
      weeklyMetrics: loadedMetrics.weekly,
      runWeekNumber: loadedMetrics.state.runWeekNumber,
      numberFormat: numberFormat,
      framed: false,
    );
  }
}

class _WeeklyBalanceSummarySkeleton extends StatelessWidget {
  const _WeeklyBalanceSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activity = MetricAccentColors.of(context).activityFor(
      colors.brightness,
    );
    final skeletonColor = AppEditorialSurfaces.section(colors);

    return Row(
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          color: activity,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  MetricSkeletonBlock(
                    width: 66,
                    height: 12,
                    color: skeletonColor,
                  ),
                  const Spacer(),
                  MetricSkeletonBlock(
                    width: 116,
                    height: 12,
                    color: skeletonColor,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              MetricSkeletonBlock(height: 6, color: skeletonColor),
            ],
          ),
        ),
      ],
    );
  }
}
