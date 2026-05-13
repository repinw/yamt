import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_buffer_badge.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_game_header.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_callbacks.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_labels.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_scale_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_stats_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Loaded Burn Week balance UI after metrics have been resolved.
class DiaryBalanceLoadedContent extends StatelessWidget {
  /// Creates loaded Burn Week balance UI.
  const DiaryBalanceLoadedContent({
    required this.resolvedMetrics,
    required this.runState,
    required this.onShowUseHeartDialog,
    required this.onUnmarkHeartDay,
    super.key,
  });

  /// Derived metrics for the loaded card.
  final DiaryBalanceLoadedMetrics resolvedMetrics;

  /// Current Burn Week run state.
  final BurnWeekRunState runState;

  /// Opens the use-heart dialog.
  final DiaryBalanceUseHeartDialog onShowUseHeartDialog;

  /// Reverts a heart day.
  final ValueChanged<DateTime> onUnmarkHeartDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = DiaryBalanceLoadedLabels.from(
      context: context,
      resolvedMetrics: resolvedMetrics,
    );

    return DiaryBalanceShell(
      framed: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DiaryBalanceGameHeader(
            label: labels.weekDayLabel,
            starCount: resolvedMetrics.showGameControls
                ? runState.starCount
                : null,
            heartCount: resolvedMetrics.showGameControls
                ? runState.heartCount
                : null,
            onHeartTap:
                resolvedMetrics.showGameControls &&
                    runState.heartCount > 0 &&
                    !resolvedMetrics.isHeartDay
                ? () => onShowUseHeartDialog(
                    dailyGoalKcal: resolvedMetrics.metrics.dailyGoalKcal,
                    runState: runState,
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          DiaryBalanceProgressBar(metrics: resolvedMetrics.metrics),
          const SizedBox(height: AppSpacing.md),
          DiaryBalanceScaleRow(
            startLabel: labels.scaleStartLabel,
            endLabel: labels.scaleEndLabel,
          ),
          if (labels.bufferAdjustmentLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            DiaryBalanceBufferBadge(
              label: labels.bufferAdjustmentLabel!,
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          DiaryBalanceStatsRow(
            eatenValue: labels.eatenValue,
            eatenSubtitle: labels.eatenSubtitle,
            leftValue: labels.leftValue,
            leftSubtitle: labels.leftSubtitle,
          ),
          if (resolvedMetrics.canRevertHeartDay) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onUnmarkHeartDay(resolvedMetrics.selectedDay),
                icon: const Icon(Icons.undo_rounded),
                label: Text(l10n.diaryBalanceRevertHeartDayAction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
