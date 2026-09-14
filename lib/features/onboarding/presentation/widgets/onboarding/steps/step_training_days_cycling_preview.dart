import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Previews training day and rest day calorie targets with cycling offset.
class StepTrainingDaysCyclingPreview extends StatelessWidget {
  /// Creates a cycling preview card.
  const StepTrainingDaysCyclingPreview({
    required this.baseGoalKcal,
    required this.trainingDaysCount,
    required this.offsetKcal,
    super.key,
  });

  /// Base daily calorie budget.
  final double baseGoalKcal;

  /// Count of selected training days per week.
  final int trainingDaysCount;

  /// Extra kcal allocated to training days.
  final double offsetKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final restDaysCount = 7 - trainingDaysCount;
    final restOffset = (trainingDaysCount * offsetKcal) / restDaysCount;
    final trainingGoal = (baseGoalKcal + offsetKcal).round();
    final restGoal = (baseGoalKcal - restOffset).round().clamp(1200, 10000);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _ResultRow(
            label: l10n.onboardingTrainingDaysTrainingResult(trainingDaysCount),
            value: '$trainingGoal kcal',
            textTheme: textTheme,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ResultRow(
            label: l10n.onboardingTrainingDaysRestResult(restDaysCount),
            value: '$restGoal kcal',
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
