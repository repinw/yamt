import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CaloriesBalanceSummaryView extends StatelessWidget {
  const CaloriesBalanceSummaryView({
    super.key,
    required this.data,
    required this.numberFormat,
    required this.kcalUnit,
  });

  final CalorieBalanceSummaryData data;
  final NumberFormat numberFormat;
  final String kcalUnit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final statusColor = _accentColor(colors);
    final carryoverColor = _carryoverColor(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _BalanceInfoChip(
                label: l10n.caloriesBalanceCarryoverLabel,
                value: _formatSignedKcal(data.carryoverKcal.round()),
                accentColor: carryoverColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _BalanceInfoChip(
                label: l10n.caloriesBalanceFlexGoalLabel,
                value:
                    '${numberFormat.format(data.flexibleGoalKcal.round())} '
                    '$kcalUnit',
                accentColor: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _BalanceBar(data: data, semanticLabel: _statusMessage(l10n)),
        const SizedBox(height: AppSpacing.md),
        _BalanceScaleLabels(
          leftLabel: l10n.caloriesBalanceScaleBufferLabel,
          middleLabel: l10n.caloriesBalanceScaleOnTrackLabel,
          rightLabel: l10n.caloriesBalanceScaleOverLabel,
          leftValue:
              '-${numberFormat.format(data.rangeKcal.round())} $kcalUnit',
          rightValue:
              '+${numberFormat.format(data.rangeKcal.round())} $kcalUnit',
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppInventoryEditorialSurfaces.ghostBorder(colors),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              _statusMessage(l10n),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _accentColor(ColorScheme colors) {
    return _colorForScore(resolveCalorieBalanceScore(data), colors: colors);
  }

  Color _carryoverColor(ColorScheme colors) {
    if (data.carryoverKcal > 0) {
      return AppInventoryEditorial.primary;
    }
    if (data.carryoverKcal < 0) {
      return AppInventoryEditorial.warning;
    }
    return colors.onSurfaceVariant;
  }

  Color _colorForScore(double score, {required ColorScheme colors}) {
    return Color.lerp(
          colors.error,
          AppInventoryEditorial.primary,
          score.clamp(0.0, 1.0),
        ) ??
        colors.primary;
  }

  String _statusMessage(AppLocalizations l10n) {
    final delta = data.deltaKcal.round().abs();
    if (data.isCurrentDay) {
      if (data.isWithinDeadZone) {
        return l10n.caloriesBalanceStatusBalancedNow;
      }
      if (data.isUnderPace) {
        return l10n.caloriesBalanceStatusEatNow(delta);
      }
      return l10n.caloriesBalanceStatusWaitNow;
    }

    if (data.isWithinDeadZone) {
      return l10n.caloriesBalanceStatusFinishedOnTrack;
    }
    if (data.isUnderPace) {
      return _finishedUnderPaceMessage(l10n, delta);
    }
    return _finishedOverPaceMessage(l10n, delta);
  }

  String _finishedUnderPaceMessage(AppLocalizations l10n, int delta) {
    return switch (data.goalMode) {
      CalorieGoalMode.lose => l10n.caloriesBalanceStatusFinishedLoseUnder(
        delta,
      ),
      CalorieGoalMode.maintain => l10n.caloriesBalanceStatusFinishedBuffer(
        delta,
      ),
      CalorieGoalMode.gain => l10n.caloriesBalanceStatusFinishedGainUnder(
        delta,
      ),
    };
  }

  String _finishedOverPaceMessage(AppLocalizations l10n, int delta) {
    return switch (data.goalMode) {
      CalorieGoalMode.lose => l10n.caloriesBalanceStatusFinishedLoseOver(delta),
      CalorieGoalMode.maintain => l10n.caloriesBalanceStatusFinishedOver(delta),
      CalorieGoalMode.gain => l10n.caloriesBalanceStatusFinishedGainOver(delta),
    };
  }

  String _formatSignedKcal(int value) {
    if (value > 0) {
      return '+$value kcal';
    }
    return '$value kcal';
  }
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.data, required this.semanticLabel});

  final CalorieBalanceSummaryData data;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final markerOffset = data.isUnderPace
        ? -data.barProgress
        : data.isOverPace
        ? data.barProgress
        : 0.0;
    final centerColor = _colorForScore(
      resolveCalorieBalanceCenterScore(data),
      colors: colors,
    );
    final edgeColor = _colorForScore(
      resolveCalorieBalanceScore(data),
      colors: colors,
    );

    return Semantics(
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final halfWidth = totalWidth / 2;
          final fillWidth = halfWidth * data.barProgress;
          final markerCenterX = halfWidth + (halfWidth * markerOffset);
          final markerSize = AppSpacing.md;

          return SizedBox(
            key: CaloriesPageKeys.summaryBalanceBar,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: data.isUnderPace ? halfWidth - fillWidth : halfWidth,
                  width: data.isUnderPace || data.isOverPace ? fillWidth : 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: data.isUnderPace
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          end: data.isUnderPace
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          colors: [centerColor, edgeColor],
                        ),
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const SizedBox(width: 2, height: 32),
                ),
                Positioned(
                  left: markerCenterX - (markerSize / 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: edgeColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: colors.onSurface.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox.square(dimension: markerSize),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _colorForScore(double score, {required ColorScheme colors}) {
    return Color.lerp(
          colors.error,
          AppInventoryEditorial.primary,
          score.clamp(0.0, 1.0),
        ) ??
        colors.primary;
  }
}

class _BalanceScaleLabels extends StatelessWidget {
  const _BalanceScaleLabels({
    required this.leftLabel,
    required this.middleLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
  });

  final String leftLabel;
  final String middleLabel;
  final String rightLabel;
  final String leftValue;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.05,
    );
    final valueStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel.toUpperCase(), style: labelStyle),
              const SizedBox(height: AppSpacing.xxs),
              Text(leftValue, style: valueStyle),
            ],
          ),
        ),
        Expanded(
          child: Text(
            middleLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel.toUpperCase(), style: labelStyle),
              const SizedBox(height: AppSpacing.xxs),
              Text(rightValue, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceInfoChip extends StatelessWidget {
  const _BalanceInfoChip({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppInventoryEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.05,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
