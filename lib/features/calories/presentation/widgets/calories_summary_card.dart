import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

class CaloriesSummaryCard extends StatelessWidget {
  const CaloriesSummaryCard({
    super.key,
    required this.consumedKcal,
    required this.goalKcal,
    required this.remainingKcal,
    required this.progress,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.onSetGoal,
    required this.setGoalLabel,
    required this.consumedLabel,
    required this.goalLabel,
    required this.remainingLabel,
    required this.proteinLabel,
    required this.carbsLabel,
    required this.fatLabel,
  });

  final double consumedKcal;
  final double goalKcal;
  final double remainingKcal;
  final double progress;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final VoidCallback onSetGoal;
  final String setGoalLabel;
  final String consumedLabel;
  final String goalLabel;
  final String remainingLabel;
  final String proteinLabel;
  final String carbsLabel;
  final String fatLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      key: CaloriesPageKeys.summaryCard,
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${consumedKcal.toStringAsFixed(0)} kcal',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                TextButton.icon(
                  key: CaloriesPageKeys.setGoalButton,
                  onPressed: onSetGoal,
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(setGoalLabel),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: progress,
              minHeight: AppSpacing.sm,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                _StatChip(
                  label: consumedLabel,
                  value: '${consumedKcal.toStringAsFixed(0)} kcal',
                ),
                _StatChip(
                  label: goalLabel,
                  value: '${goalKcal.toStringAsFixed(0)} kcal',
                ),
                _StatChip(
                  label: remainingLabel,
                  value: '${remainingKcal.toStringAsFixed(0)} kcal',
                  valueColor: remainingKcal < 0
                      ? colorScheme.error
                      : colorScheme.onSurface,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MacroTile(label: proteinLabel, grams: totalProtein),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MacroTile(label: carbsLabel, grams: totalCarbs),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MacroTile(label: fatLabel, grams: totalFat),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({required this.label, required this.grams});

  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text('${grams.toStringAsFixed(1)} g'),
          ],
        ),
      ),
    );
  }
}
