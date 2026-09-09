import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_transition.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_segmented_progress_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One macro row in the food logging feedback card.
class DiaryFoodLogFeedbackMacroRow extends StatelessWidget {
  /// Creates a feedback macro row.
  const DiaryFoodLogFeedbackMacroRow({
    required this.label,
    required this.added,
    required this.color,
    required this.numberFormat,
    required this.unit,
    this.current,
    this.previous,
    this.startedAt,
    this.target,
    super.key,
  });

  /// Macro name label.
  final String label;

  /// Amount added by confirmed entries.
  final double added;

  /// Current day total intake.
  final double? current;

  /// Previous day total intake before addition.
  final double? previous;

  /// Animation synchronization timestamp.
  final DateTime? startedAt;

  /// Day macro target.
  final double? target;

  /// Macro accent color.
  final Color color;

  /// Number format.
  final NumberFormat numberFormat;

  /// Unit string.
  final String unit;

  @override
  Widget build(BuildContext context) => DiaryMacroTransition(
    current: current ?? added,
    previous: previous,
    startedAt: startedAt,
    builder: _buildRow,
  );

  Widget _buildRow(BuildContext context, double value, double highlight) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final hasTarget = target != null && target!.isFinite && target! > 0;
    final progress = hasTarget ? (value / target!).clamp(0.0, 1.0) : 0.0;
    final remaining = hasTarget ? target! - value : 0.0;
    final amount = numberFormat.format(remaining.abs().round());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (hasTarget)
                Text(
                  l10n.diaryMacroCurrentTarget(
                    numberFormat.format(value.round()),
                    numberFormat.format(target!.round()),
                    unit,
                  ),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: AppSpacing.xs),
            DiarySegmentedProgressBar(
              progress: progress,
              highlightStart: previous == null
                  ? null
                  : (previous! / target!).clamp(0.0, 1.0),
              highlightOpacity: highlight,
              color: color,
              trackColor: colors.surfaceContainerHighest,
              isDark: colors.brightness == Brightness.dark,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xxs,
              children: [
                Text(
                  '+${numberFormat.format(added.round())} $unit',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                  ),
                ),
                Text(
                  remaining < -0.5
                      ? l10n.diaryMacroOverTarget(amount, unit)
                      : l10n.diaryMacroRemaining(amount, unit),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              '+${numberFormat.format(added.round())} $unit',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
