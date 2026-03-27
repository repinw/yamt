import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

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
  final String consumedLabel;
  final String goalLabel;
  final String remainingLabel;
  final String proteinLabel;
  final String carbsLabel;
  final String fatLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final kcalUnit = l10n.caloriesUnitKcal;
    final gramUnit = l10n.caloriesUnitGram;
    final ringColor = remainingKcal < 0
        ? colorScheme.error
        : AppInventoryEditorial.primary;
    final macroGoals = _MacroGoals.fromGoalKcal(goalKcal);

    return DecoratedBox(
      key: CaloriesPageKeys.summaryCard,
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colorScheme,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: _SummaryHalo(
                remainingKcal: remainingKcal,
                progress: progress,
                color: ringColor,
                label: remainingLabel,
                numberFormat: numberFormat,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _MacroProgressRow(
              label: carbsLabel,
              current: totalCarbs,
              target: macroGoals.carbs,
              color: const Color(0xFF3B82F6),
              unitLabel: gramUnit,
              numberFormat: numberFormat,
            ),
            const SizedBox(height: AppSpacing.md),
            _MacroProgressRow(
              label: proteinLabel,
              current: totalProtein,
              target: macroGoals.protein,
              color: const Color(0xFFF97316),
              unitLabel: gramUnit,
              numberFormat: numberFormat,
            ),
            const SizedBox(height: AppSpacing.md),
            _MacroProgressRow(
              label: fatLabel,
              current: totalFat,
              target: macroGoals.fat,
              color: const Color(0xFFEAB308),
              unitLabel: gramUnit,
              numberFormat: numberFormat,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: consumedLabel,
                    value:
                        '${numberFormat.format(consumedKcal.round())} $kcalUnit',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryStat(
                    label: goalLabel,
                    value: '${numberFormat.format(goalKcal.round())} $kcalUnit',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHalo extends StatelessWidget {
  const _SummaryHalo({
    required this.remainingKcal,
    required this.progress,
    required this.color,
    required this.label,
    required this.numberFormat,
  });

  final double remainingKcal;
  final double progress;
  final Color color;
  final String label;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayedValue = numberFormat.format(remainingKcal.round());

    return SizedBox.square(
      dimension: 196,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 168,
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                backgroundColor: colorScheme.surfaceContainerHigh,
                color: color,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayedValue,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroProgressRow extends StatelessWidget {
  const _MacroProgressRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unitLabel,
    required this.numberFormat,
  });

  final String label;
  final double current;
  final double target;
  final Color color;
  final String unitLabel;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = target <= 0
        ? 0.0
        : (current / target).clamp(0.0, 1.0).toDouble();
    final currentText = numberFormat.format(current.round());
    final targetText = numberFormat.format(target.round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.05,
                ),
              ),
            ),
            Text(
              '$currentText$unitLabel / $targetText$unitLabel',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.05,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MacroGoals {
  const _MacroGoals({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final double carbs;
  final double protein;
  final double fat;

  factory _MacroGoals.fromGoalKcal(double goalKcal) {
    return _MacroGoals(
      carbs: goalKcal * 0.45 / 4,
      protein: goalKcal * 0.25 / 4,
      fat: goalKcal * 0.30 / 9,
    );
  }
}
